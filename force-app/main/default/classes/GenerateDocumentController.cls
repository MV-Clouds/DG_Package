public with sharing class GenerateDocumentController {
    
/*
*********************************************************
@description     : Method is used to fetch the combined data to reduce apex callouts
@param           : objName {String} - Name of the object, from where the quick action is started
@return          : CombinedDataWrapper - including all templates, folders, integration status and isSuccess boolean
********************************************************
    */
    @AuraEnabled
    public static CombinedDataWrapper getCombinedData(String objName){
        CombinedDataWrapper combinedData = new CombinedDataWrapper();
        try {
            combinedData.folderWrapper = getFolders();
            combinedData.integrationWrapper = getIntegrationStatus();
            combinedData.templates = fetchTemplates(objName);
            combinedData.isSuccess = combinedData.folderWrapper != null && combinedData.integrationWrapper != null && combinedData.templates != null ? true : false;
            System.debug('Combined Data::'+ combinedData);
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'fetchCombinedData');
        }
        return combinedData;
    }

/*
*********************************************************
@description     : Method is used to fetch all the templates
@param           : objName {String} - Name of the object, from where the quick action is started
@return          : List<Template__c> - including all the templates fetched from org
********************************************************
*/
    @AuraEnabled
    public static List<Template__c> fetchTemplates(String objName){
        try {
            List<Template__c> templates = new List<Template__c>();
            templates = [ SELECT Id, Name, Object_API_Name__c, Template_Name__c, Template_Type__c, Template_Status__c, Description__c, LastModifiedDate, Button_Api_Name__c FROM Template__c WHERE Object_API_Name__c=:objName WITH SECURITY_ENFORCED];
            return templates;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'fetchTemplates');
            return null;
        }
    }

/*
*********************************************************
@description     : Method is used to fetch integration status
@param           : none
@return          : IntegrationWrapper - Wrapper containing all integration status
********************************************************
*/
    @AuraEnabled
    public static IntegrationWrapper getIntegrationStatus(){
        try {
            IntegrationWrapper listOfIW = new IntegrationWrapper();
            listOfIW.isGoogleDriveIntegrated = AuthProviderSettings__c.getOrgDefaults().WorkingStatus__c;
            listOfIW.isAWSIntegrated = AwsAuthProviderSettings__c.getOrgDefaults().WorkingStatus__c;
            listOfIW.isDropBoxIntegrated = DropBoxAuthProviderSettings__c.getOrgDefaults().WorkingStatus__c;
            listOfIW.isOneDriveIntegrated = OneDriveAuthProviderSettings__c.getOrgDefaults().WorkingStatus__c;
            return listOfIW;
        } catch (Exception e) {
            System.debug('Error in getIntegrationStatus =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getIntegrationStatus');
            return null;
        }
    }


/*
*********************************************************
@description     : Method is used to fetch all the folders
@param           : none
@return          : List<FolderWrapper> - List of wrapper containing folder name and url
********************************************************
*/
    @AuraEnabled
    public static List<FolderWrapper> getFolders(){
        try {
            List<FolderWrapper> listOfFW = new List<FolderWrapper>();
            List<Folder> folders = [SELECT Id, Name From folder WHERE Type ='Document' WITH SECURITY_ENFORCED];
            FolderWrapper myFolder = new FolderWrapper();
            myFolder.label = 'My Personal Documents';
            myFolder.value = UserInfo.getUserId();
            listOfFW.add(myFolder);
            for(Folder f : folders){
                FolderWrapper fWrapper = new FolderWrapper();
                fWrapper.label = f.Name;
                fWrapper.value = f.Id;
                listOfFW.add(fWrapper);
            }
            return listOfFW;
        } catch (Exception e) {
            System.debug('Error in getFolders =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getFolders');
            return null;
        }
    }

/*
*********************************************************
@description      : Method is used to fetch the Query and count of records from the query
@param {none}
@return           : {String} - current session Id
********************************************************
*/
    @AuraEnabled
    public static List<EmailTemplate> getAllEmailTemplates(){
        List<EmailTemplate> emailTemplates = new List<EmailTemplate>();
        try{
            emailTemplates = [SELECT Id, Name, Subject, HtmlValue FROM EmailTemplate WITH SECURITY_ENFORCED];
        }catch(Exception e){
            System.debug('Error in getAllEmailTemplates =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getAllEmailTemplates');
        }
        return emailTemplates;
    }



/*
*********************************************************
@description     : Method is used to save the document in the files
@param           : contentVersionId {String} - Id of the content version
@param           : recordId {String} - Id of the record, with which file need to be linked
@return          :String - status of complition
********************************************************
*/
    @AuraEnabled
    public static String storeInFiles(String contentVersionId, String recordId){
        try {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = [Select Id, ContentDocumentId from ContentVersion WHERE Id=:contentVersionId WITH SECURITY_ENFORCED LIMIT 1].ContentDocumentId;
            cdl.LinkedEntityId = recordId;   
            cdl.Sharetype = 'V';
            if(Schema.sObjectType.ContentDocumentLink.isCreateable()){
                insert cdl;
            }
        }catch (Exception e) {
            System.debug('Error in storeInFiles =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'storeInFiles');
            if(Test.isRunningTest() == false){
                throw new AuraHandledException(e.getMessage());
            }
        }
        return 'completed';
    }

/*
*********************************************************
@description     : Method is used to post document to chatter
@param           : contentVersionId {String} - Id of the content version
@param           : recordId {String} - Id of the record, with which file need to be linked
@param           : body {String} - body string to post with the chatter
@return          :String - status of complition
********************************************************
*/
    @AuraEnabled
    public static String postToChatter(String contentVersionId, String recordId, String body){
        try {
            FeedItem feed = new FeedItem();
            if(recordId == null || recordId == ''){
                feed.ParentId = UserInfo.getUserId();
            }else{
                feed.ParentId =  recordId;
            }
            feed.RelatedRecordId = contentVersionId;
            feed.Body = body;
            if(Schema.sObjectType.FeedItem.isCreateable()){
                insert feed;
            }
        }catch (Exception e) {
            System.debug('Error in postToChatter =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'postToChatter');
            if(Test.isRunningTest() == false){
                throw new AuraHandledException(e.getMessage());
            }
        }
        return 'completed';
    }

/*
*********************************************************
@description     : Method is used to send the email with newly generated document
@param           : SaveDataWrapper {Wrapper} - wrapper containing needed data to store the file
@return          : String - status of complition
********************************************************
*/
    @AuraEnabled
    public static String sendEmail(SaveDataWrapper saveDataWrapper){
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] attachments =  new String[] {};
            attachments.add(saveDataWrapper.contentVersionId);
            mail.setToAddresses(saveDataWrapper.toEmails);
            mail.setCcAddresses(saveDataWrapper.ccEmails);
            mail.setBccAddresses(saveDataWrapper.bccEmails);
            mail.setSubject(saveDataWrapper.emailSubject);
            mail.setHtmlBody(saveDataWrapper.emailBody);
            mail.setEntityAttachments(attachments);

            Messaging.SendEmailResult[] result = Messaging.sendEmail(
                new Messaging.SingleEmailMessage[] { mail });
            if (result[0].isSuccess()) {
                System.debug('Email sent successfully');
            }
            else {
                System.debug('The following errors occurred: ' + result[0].getErrors());  
                if(Test.isRunningTest() == false){
                    throw new AuraHandledException('Email send was unsuccessfull');     
                }
            }
        }catch (Exception e) {
            System.debug('Error in storeFilesAndSendEmail =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'sendEmail');
            if(Test.isRunningTest() == false){
                throw new AuraHandledException(e.getMessage());
            }
        }
        return 'completed';
    }

/*
*********************************************************
@description      : Method is used to fetch the Query and count of records from the query
@param {none}
@return           : {String} - current session Id
********************************************************
*/
    @AuraEnabled
    public static String getSessionId(){
        String sessionId;
        try{
            if(Test.isRunningTest()) { 
                sessionId = 'testSessionId';
            }else{
                sessionId = Page.UserSessionIdPage.getContent().toString();
            }
        }catch(Exception e){
            System.debug('Error in getSessionId =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getSessionId');
        }
        return sessionId;
    }


/*
*********************************************************
@description      : Method is used to fetch the button names already used
@param            : objName {String} - name of the object     
@param            : type {String} - type of button i.e,- quick action or list view button
@return           : List{String} - List of button api names already created
********************************************************
*/
    @AuraEnabled
    public static List<String> getButtonNames(String objName){
        List<String> buttonNames = new List<String>();
        try{
            List<WebLink> listViewButtons = [SELECT Name FROM WebLink WHERE PageOrSobjectType=:objName WITH SECURITY_ENFORCED];
            for (WebLink wl : listViewButtons) {
                buttonNames.add(wl.Name);
            }
            List<QuickAction.DescribeAvailableQuickActionResult> result1 = QuickAction.DescribeAvailableQuickActions(objName);  
            for(QuickAction.DescribeAvailableQuickActionResult action : result1){
                if(action.getType() == 'LightningWebComponent'){
                    buttonNames.add(action.getName().substringAfter(objName+'.'));
                }
            }
        }catch(Exception e){
            System.debug('Error in getButtonNames =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getButtonNames');
        }
        return buttonNames;
    }

//--------------------------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------  CSV Generation Methods --------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------------

/*
*********************************************************
@description      : Method is used to fetch the Query and count of records from the query
@param templateId : {String} - templateId of the selected template
@return           : {String} - containing fields, Query and the count of records
********************************************************
*/
    @AuraEnabled
    public static String getTemplateData(String templateId){
        String allData = '';
        try{
            List<Template_Data__c> tfList = [SELECT Id, CSV_Fields__c, CSV_Query__c FROM Template_Data__c WHERE Template__c =:templateId WITH SECURITY_ENFORCED ORDER BY Order_No_Simple__c asc NULLS Last LIMIT 1];

            if(!tfList.isEmpty()){
                String fields = tfList[0].CSV_Fields__c;
                System.debug('all the Fields here :: ' + fields);
                String query = tfList[0].CSV_Query__c;

                String sessionId = '';

                sessionId = getSessionId();
                system.debug('sessionId : '+sessionId);


                allData = fields + ' <|QDG|> ' + query + ' <|QDG|> ' + sessionId;
                System.debug('All the Data to be Sent is :: ' + allData);
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getTemplateData');
        }
        return allData;
    }

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= Used to set default generation options for the templates -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
/*
*********************************************************
@description     : Method is used to fetch the default values for the template button
@param           : templateId {String} - Id of the template to generate
@return          : DefaultDataWrapper {Wrapper} - wrapper containing with default data for the template
********************************************************
*/  
    @AuraEnabled
    public static DefaultDataWrapper getTemplateDefaultValues(String templateId){
        DefaultDataWrapper ddw = new DefaultDataWrapper();
        try {
            List<Template__c> templates = [SELECT Id, Template_Name__c,Button_Label__c, Button_Api_Name__c, Document_Type__c, Internal_Storage__c, External_Storage__c, Output_Channel__c, Email_Addresses__c,	Email_Subject__c, Email_Body__c, Template_Type__c, Email_Template__c FROM Template__c WHERE Id=:templateId WITH SECURITY_ENFORCED];
            if(templates.size() > 0){
                ddw.templateId = templates[0].Id;
                ddw.templateName = templates[0].Template_Name__c;
                ddw.buttonLabel = templates[0].Button_Label__c;
                ddw.buttonName = templates[0].Button_Api_Name__c;
                ddw.docType = templates[0].Document_Type__c;
                ddw.iStorage = templates[0].Internal_Storage__c;
                ddw.eStorage = templates[0].External_Storage__c;
                ddw.oChannel = templates[0].Output_Channel__c;
                ddw.emailAddresses = templates[0].Email_Addresses__c;
                ddw.emailSubject = templates[0].Email_Subject__c;
                ddw.emailBody = templates[0].Email_Body__c;
                ddw.templateType = templates[0].Template_Type__c;
                ddw.emailTemplate = templates[0].Email_Template__c;
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getTemplateDefaultValues');
            throw new AuraHandledException(e.getMessage());
        }
        return ddw;
    }


/*
*********************************************************
@description     : Method is used to store the default values for the generation options
@param          : DefaultDataWrapper {Wrapper} - wrapper containing with default data for the template
@return           : void - won't return anything
********************************************************
*/  
    @AuraEnabled
    public static void setDefaultOptions(DefaultDataWrapper defaultData){
        try {
            Template__c template = new Template__c(
                Id = defaultData.templateId,
                Button_Label__c = defaultData.buttonLabel,
                Button_Api_Name__c = defaultData.buttonName,
                Document_Type__c = defaultData.docType,
                Internal_Storage__c = defaultData.iStorage,
                External_Storage__c = defaultData.eStorage,
                Output_Channel__c = defaultData.oChannel,
                Email_Addresses__c = defaultData.emailAddresses,
                Email_Subject__c = defaultData.emailSubject,
                Email_Body__c = defaultData.emailBody,
                Email_Template__c = defaultData.emailTemplate
            );

            if(Schema.sObjectType.MVDG__Template__c.isUpdateable() == false){
                update template;
            }

        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'setDefaultOptions');
            system.debug('exception in setDefaultOptions : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
        }
    }

// -=-=- Wrappers -=-=-

/*
*********************************************************
@description     : wrapper containing integration status of different storage options
@param           : isGoogleDriveIntegrated Boolean - Integration Status of GoogleDrive
@param           : isAWSIntegrated Boolean - Integration Status of AWS
@param           : isOneDriveIntegrated Boolean - Integration Status of OneDrive
@param           : isDropBoxIntegrated Boolean - Integration Status of DropBox
********************************************************
*/
    public class IntegrationWrapper{
        @AuraEnabled public Boolean isGoogleDriveIntegrated;
        @AuraEnabled public Boolean isAWSIntegrated;
        @AuraEnabled public Boolean isOneDriveIntegrated;
        @AuraEnabled public Boolean isDropBoxIntegrated;
    }

/*
*********************************************************
@description     : wrapper containing label and Id of the folders for the document storing
@param           : label String - Label of the folder
@param           : value String - Id of the folder
********************************************************
*/
    public class FolderWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

/*
*********************************************************
@description     : wrapper containing needed data to store the file
@param           : contentVersionId {String} - Id of generated content version from API
@param           : toEmails {List<String>} - list of to emails
@param           : ccEmails {List<String>} - list of cc emails
@param           : bccEmails {List<String>} - list of bcc emails
@param           : emailSubject {String} - Subject of email
@param           : emailBody {String} - Subject of email
********************************************************
*/
    public class SaveDataWrapper{
        @AuraEnabled public String contentVersionId  { get; set; }
        @AuraEnabled public List<String> toEmails  { get; set; }
        @AuraEnabled public List<String> ccEmails  { get; set; }
        @AuraEnabled public List<String> bccEmails  { get; set; }
        @AuraEnabled public String emailSubject { get; set;}
        @AuraEnabled public String emailBody { get; set;}
    }

/*
*********************************************************
@description     : wrapper containing with default data for the template
@param           : templateId {String} - Id of the template to update
@param           : templateName {String} - name of the template
@param           : buttonLabel {String} - label of the Button for default creation
@param           : buttonName {String} - Api Name of the Button for default creation
@param           : docType {String} - Id of generated content version from API
@param           : iStorage {String} - comma saperated internal storages
@param           : eStorage {String} - comma saperated external storages
@param           : oChannel {String} - comma saperated output channel
@param           : emailAddresses {String} - Saperated String for  To, Cc and Bcc email addresses
@param           : emailSubject {String} - Subject of email
@param           : emailBody {String} - Subject of email
@param           : templateType {String} - Type of template
@param           : emailTemplate {String} - Id of the email template
********************************************************
*/
    public class DefaultDataWrapper{
        @AuraEnabled public String templateId  { get; set; }
        @AuraEnabled public String templateName  { get; set; }
        @AuraEnabled public String buttonLabel { get; set; }
        @AuraEnabled public String buttonName  { get; set; }
        @AuraEnabled public String docType  { get; set; }
        @AuraEnabled public String iStorage  { get; set; }
        @AuraEnabled public String eStorage  { get; set; }
        @AuraEnabled public String oChannel  { get; set; }
        @AuraEnabled public String emailAddresses  { get; set; }
        @AuraEnabled public String emailSubject { get; set;}
        @AuraEnabled public String emailBody { get; set;}
        @AuraEnabled public String templateType { get; set; }
        @AuraEnabled public String emailTemplate { get; set; }
    }


/*
*********************************************************
@description     : Wrapper combining the integration status, folders and template data
@param           : integrationWrapper {IntegrationWrapper} - wrapper containing integration status of different storage options
@param           : folderWrapper {FolderWrapper} - wrapper containing label and Id of the folders for the document storing
@param           : defaultDataWrapper {DefaultDataWrapper} - wrapper containing with default data for the template
@param           : templates {List<Template__c>} - List of the templates
********************************************************
*/

    public class CombinedDataWrapper{
        @AuraEnabled public IntegrationWrapper integrationWrapper;
        @AuraEnabled public List<FolderWrapper> folderWrapper;
        // @AuraEnabled public DefaultDataWrapper defaultDataWrapper;
        @AuraEnabled public List<Template__c> templates;
        @AuraEnabled public Boolean isSuccess;
    }
}