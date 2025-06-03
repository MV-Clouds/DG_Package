/*
*********************************************************
Apex Class Name    : GenerateDocumentController
@description       : This class is used for handling various processes of generating documents of different templates
@author            : Kevin Suvagiya
@last Modified     : Kevin Suvagiya - 22 Oct, 2024
*********************************************************
*/
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
            List<EmailTemplate> emailTemplates = new List<EmailTemplate>();
            emailTemplates = [SELECT Id, Name, Subject, Body, HtmlValue FROM EmailTemplate WHERE IsActive = true WITH SECURITY_ENFORCED];
            combinedData.emailTemplates = emailTemplates;
            combinedData.folderWrapper = getFolders();
            combinedData.integrationWrapper = getIntegrationStatus();
            combinedData.templates = fetchTemplates(objName);
            Integer countOfPermission = [SELECT Count() FROM PermissionSetAssignment WHERE PermissionSet.Name IN ('DocGenius_Standard_Permissions', 'DocGenius_Admin_Permissions') AND AssigneeId =:userInfo.getUserId() WITH SECURITY_ENFORCED];
            combinedData.isEditorAccess = countOfPermission > 0 ? true : false;
            combinedData.isSuccess = combinedData.folderWrapper != null && combinedData.integrationWrapper != null && combinedData.templates != null && combinedData.isEditorAccess != null ? true : false;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'fetchCombinedData');
        }
        return combinedData;
    }

/*
*********************************************************
@description     : Method is used to fetch all the templates
@param           : objName {String} - Name of the object, from where the quick action is started
@return          : List<MVDG__Template__c> - including all the templates fetched from org
********************************************************
*/
    @AuraEnabled
    public static List<MVDG__Template__c> fetchTemplates(String objName){
        try {
            List<MVDG__Template__c> templates = new List<MVDG__Template__c>();
            if(objName != null){
                templates = [ SELECT Id, Name, MVDG__Object_API_Name__c, MVDG__Template_Name__c, MVDG__Template_Type__c, MVDG__Template_Status__c, MVDG__Description__c, LastModifiedDate, MVDG__Button_Api_Name__c FROM MVDG__Template__c WHERE MVDG__Object_API_Name__c=:objName WITH SECURITY_ENFORCED];
            }
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
            IntegrationWrapper listOfStatus = new IntegrationWrapper();
            listOfStatus.isGoogleDriveIntegrated = MVDG__Google_Credentials__c.getOrgDefaults().MVDG__WorkingStatus__c;
            listOfStatus.isAWSIntegrated = MVDG__Aws_Credentials__c.getOrgDefaults().MVDG__WorkingStatus__c;
            listOfStatus.isDropBoxIntegrated = MVDG__Dropbox_Credentials__c.getOrgDefaults().MVDG__WorkingStatus__c;
            listOfStatus.isOneDriveIntegrated = MVDG__OneDrive_Credential__c.getOrgDefaults().MVDG__WorkingStatus__c;

            List<MVDG__Google_Credentials__c> googleDriveSetting = [SELECT MVDG__WorkingStatus__c FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getUserId() WITH SECURITY_ENFORCED];
            if(googleDriveSetting.size() > 0){
                listOfStatus.isUserWideAccessible = googleDriveSetting[0].MVDG__WorkingStatus__c;
            } 
            return listOfStatus;
        } catch (Exception e) {
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
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getFolders');
            return null;
        }
    }



/*
*********************************************************
@description     : Method is used to save the document in the files
@param           : combinedData {Map<String, String>} - map of all needeed data like, content version id, recod id, document generation activity id
@return          :String - status of complition
********************************************************
*/
    @AuraEnabled
    public static String storeInFiles(Map<String, String> combinedData){
        try {
            String contentVersionId = combinedData.get('contentVersionId');
            String recordId = combinedData.get('recordId');

            ContentDocumentLink cdl = new ContentDocumentLink();
            if(contentVersionId != null){
                cdl.ContentDocumentId = [Select Id, ContentDocumentId from ContentVersion WHERE Id=:contentVersionId WITH SECURITY_ENFORCED LIMIT 1].ContentDocumentId;
            }
            cdl.LinkedEntityId = recordId;
            cdl.Sharetype = 'V';
            insert as User cdl;
            return 'success';
        }catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'storeInFiles', combinedData.get('activityId'));
            return e.getMessage();
        }
    }

/*
*********************************************************
@description     : Method is used to post document to chatter
@param           : combinedData {Map<String, String>} - map of all needeed data like, content version id, recod id, document generation activity id and body of chatter
@return          :String - status of complition
********************************************************
*/
    @AuraEnabled
    public static String postToChatter(Map<String, String> combinedData){
        try {
            String contentVersionId = combinedData.get('contentVersionId');
            String recordId = combinedData.get('recordId');
            String body = combinedData.get('body');
            FeedItem feed = new FeedItem();
            if(recordId == null || recordId == ''){
                feed.ParentId = UserInfo.getUserId();
            }else{
                feed.ParentId =  recordId;
            }
            feed.RelatedRecordId = contentVersionId;
            feed.Body = body;
            insert as User feed;
            return 'success';
        }catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'postToChatter', combinedData.get('activityId'));
            return e.getMessage();
        }
    }

/*
*********************************************************
@description     : Method is used to send the email with newly generated document
@param           : allEmails {Map<String, List<String>>} - Map containing to, cc and bcc email addresses
@param           : emaildata {Map<String,String>} - Map containing other data like CV Id, subject and body
@param           : activityId {String} - Id of the document generation activity record for this generation
@return          : String - status of complition
********************************************************
*/
    @AuraEnabled
    public static String sendEmail(Map<String, List<String>> allEmails, Map<String,String> emailData, String activityId){
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] attachments =  new String[] {};
            attachments.add(emailData.get('contentVersionId'));
            mail.setToAddresses(allEmails.get('toEmails'));
            mail.setCcAddresses(allEmails.get('ccEmails'));
            mail.setBccAddresses(allEmails.get('bccEmails'));
            mail.setSubject(emailData.get('emailSubject'));
            mail.setHtmlBody(emailData.get('emailBody'));
            mail.setEntityAttachments(attachments);

            Messaging.SendEmailResult[] result = Messaging.sendEmail(
                new Messaging.SingleEmailMessage[] { mail });
            if (!result[0].isSuccess() && !Test.isRunningTest()){
                throw new AuraHandledException('Email send was unsuccessfull');
            }
            return 'success';
        }catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'sendEmail', activityId);
            return e.getMessage();
        }
    }

/*
*********************************************************
@description      : Method is used to fetch the Client Id & Client Secret from the Custom Settings record.
@param            : None
@return           : {String} - Access Token
********************************************************
*/
@AuraEnabled
public static String generateAccessToken() {
    String accessToken = null;
    try {
        List<MVDG__ConnectedAppIdAndSecret__c> aps = new List<MVDG__ConnectedAppIdAndSecret__c>();
        aps = [SELECT Id, MVDG__Client_Id__c, MVDG__Client_Secret__c FROM MVDG__ConnectedAppIdAndSecret__c WHERE MVDG__Client_Id__c != null AND MVDG__Client_Secret__c != null WITH SECURITY_ENFORCED ];
        if (aps.size() > 0) {
            String endPointURL = URL.getOrgDomainUrl().toExternalForm() + '/services/oauth2/token';
            String requestBody = 'grant_type=client_credentials&client_id={0}&client_secret={1}';
    
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPointURL);
            req.setMethod('POST');
            req.setBody(String.format(requestBody ,new string[]{aps[0].MVDG__Client_Id__c,aps[0].MVDG__Client_Secret__c}));
            req.setTimeout(60000);
            Http http = new Http();
            HttpResponse res = http.send(req);
            if(res.getStatusCode() == 200){
                accessToken = res.getBody().substringBetween('access_token":"', '"');
            }
        }
    } catch (Exception e) {
        Log_Handler.store_Exception(e, 'GenerateDocumentController', 'generateAccessToken');
    }
    return accessToken;
}

/*
*********************************************************
@description      : Method is used to fetch the Client Id & Client Secret from the Custom Settings record.
@param            : none
@return           : Map<String, String> - Map of consumer details
********************************************************
*/
@AuraEnabled
public static Map<String, String> getConnectedAppConfigs() {
    Map<String, String> mapOfData = new Map<String, String>{
        'clientId' => null,
        'clientSecret' => null,
        'accessToken' => null
    };
    try {
        List<MVDG__ConnectedAppIdAndSecret__c> aps = new List<MVDG__ConnectedAppIdAndSecret__c>();
        aps = [SELECT Id, MVDG__Client_Id__c, MVDG__Client_Secret__c FROM MVDG__ConnectedAppIdAndSecret__c WHERE MVDG__Client_Id__c != null AND MVDG__Client_Secret__c != null WITH SECURITY_ENFORCED ];
        if (aps.size() > 0) {
            mapOfData.put('clientId', aps[0].MVDG__Client_Id__c);
            mapOfData.put('clientSecret', aps[0].MVDG__Client_Secret__c);
            mapOfData.put('accessToken', generateAccessToken());
        }
    } catch (Exception e) {
        Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getConnectedAppConfigs');
    }
    return mapOfData;
}

/*
*********************************************************
@description      : Method is used to update the Client Id & Client Secret in the Custom Settings record.
@param            : clientId {String} - Client Id of the connected app
@param            : clientSecret {String} - Client Secret of the connected app
@return           : none
********************************************************
*/
@AuraEnabled
public static void updateSetting(String clientId, String clientSecret) {
    try {
        
        List<MVDG__ConnectedAppIdAndSecret__c> aps = new List<MVDG__ConnectedAppIdAndSecret__c>();
        aps = [SELECT Id, MVDG__Client_Id__c, MVDG__Client_Secret__c FROM MVDG__ConnectedAppIdAndSecret__c WHERE MVDG__Client_Id__c != null AND MVDG__Client_Secret__c != null WITH SECURITY_ENFORCED ];
        MVDG__ConnectedAppIdAndSecret__c app = aps.size() > 0 ? aps[0] : new MVDG__ConnectedAppIdAndSecret__c();
        app.SetupOwnerId = UserInfo.getUserId();
        app.MVDG__Client_Id__c = clientId;
        app.MVDG__Client_Secret__c = clientSecret;
        upsert as User app;
    } catch (Exception e) {
        Log_Handler.store_Exception(e, 'GenerateDocumentController', 'updateSetting');
    }
}

/*
*********************************************************
@description      : Method is used to create a new activity record for a template
@param {none}
@return           : activityId {String} - new activity Id
********************************************************
*/
    @AuraEnabled
    public static String upsertActivity(MVDG__Generate_Document_Activity__c activity){
        try{
            if(activity != null){
                activity.MVDG__Initiated_By__c = UserInfo.getUserId();
                upsert as User activity;
                return activity.Id;
            }
            return null;
        }catch(Exception e){
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'upsertActivity');
            return null;
        }
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
            List<WebLink> listViewButtons = new List<WebLink>();
            if(objName != null){
                listViewButtons = [SELECT Name FROM WebLink WHERE PageOrSobjectType=:objName WITH SECURITY_ENFORCED];
            }
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
    public static Map<String,String> getTemplateData(String templateId){
        Map<String,String> mapOfData = new Map<String,String>{'fields' => null, 'query' => null, 'accessToken' => null, 'count' => '1000000', 'error' => null};
        try{
            List<MVDG__Template_Data__c> tfList = new List<MVDG__Template_Data__c>();
            if(templateId != null){
                tfList = [SELECT Id, MVDG__CSV_Fields__c, MVDG__CSV_Query__c, MVDG__Template__r.MVDG__Object_API_Name__c FROM MVDG__Template_Data__c WHERE MVDG__Template__c =:templateId WITH SECURITY_ENFORCED ORDER BY MVDG__Order_No_Simple__c asc NULLS Last LIMIT 1];
            }

            if(tfList.size() < 1){ return null;}
            Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(tfList[0].MVDG__Template__r.MVDG__Object_API_Name__c).getDescribe().fields.getMap();
            List<String> inAccessibleFields = new List<String>();
            for (String fieldName : tfList[0].MVDG__CSV_Fields__c.split(',')) {
                if (!fieldName.contains('.') && (!objectFields.get(fieldName).getDescribe().isAccessible() || Test.isRunningTest())) {
                    String fieldLabel = objectFields.get(fieldName).getDescribe().getLabel();
                    inAccessibleFields.add(fieldLabel); // Add label instead of API name
                }
            }
            if (inAccessibleFields.size() > 0) {
                mapOfData.put('error', 'Insufficient Access - You do not have access to these fields: ' + String.join(inAccessibleFields, ', ') + '.');
                if(!Test.isRunningTest()) {return mapOfData;}
            }
            String fields = tfList[0].MVDG__CSV_Fields__c;
            String query = tfList[0].MVDG__CSV_Query__c.replaceAll('CURRENT_USER', UserInfo.getUserId());
            String accessToken = '';
            String countableQuery = 'SELECT count() FROM' + (query.contains('ORDER BY') ? (query.substringBeforeLast('ORDER BY').substringAfterLast('FROM') + ' LIMIT ' + query.substringAfterLast('LIMIT')) : query.substringAfterLast('FROM'));
            Integer count = database.countQuery(String.valueOf(countableQuery));
            accessToken = generateAccessToken();
            mapOfData.put('fields', fields);
            mapOfData.put('query', query);
            mapOfData.put('accessToken', accessToken);
            mapOfData.put('count', String.valueOf(count)!=null ? String.valueOf(count) : query.substringAfterLast('LIMIT'));
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getTemplateData');
            return null;
        }
        return mapOfData;
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
    public static DefaultDataWrapper getTemplateDefaultValues(String templateId, String recordId){
        try {
            DefaultDataWrapper ddw = new DefaultDataWrapper();
            List<MVDG__Template__c> templates = new List<MVDG__Template__c>();
            if (templateId != null) {
                templates = [SELECT Id, MVDG__Template_Name__c, MVDG__Object_API_Name__c, MVDG__Template_Status__c, MVDG__Button_Label__c, 
                             MVDG__Button_Api_Name__c, MVDG__Document_Type__c, MVDG__Internal_Storage__c, MVDG__Selected_Document_Folder__c, 
                             MVDG__External_Storage__c, MVDG__Output_Channel__c, MVDG__Email_Addresses__c, MVDG__Email_Subject__c, 
                             MVDG__Email_Body__c, MVDG__Template_Type__c, MVDG__Email_Template__c 
                             FROM MVDG__Template__c WHERE Id = :templateId WITH SECURITY_ENFORCED];
            }
            if(templates.size() > 0){
                ddw.templateId = templates[0].Id;
                ddw.templateName = templates[0].MVDG__Template_Name__c;
                ddw.templateStatus = templates[0].MVDG__Template_Status__c;
                ddw.buttonLabel = templates[0].MVDG__Button_Label__c;
                ddw.buttonName = templates[0].MVDG__Button_Api_Name__c;
                ddw.docType = templates[0].MVDG__Document_Type__c;
                ddw.iStorage = templates[0].MVDG__Internal_Storage__c;
                ddw.folderId = templates[0].MVDG__Selected_Document_Folder__c;
                ddw.eStorage = templates[0].MVDG__External_Storage__c;
                ddw.oChannel = templates[0].MVDG__Output_Channel__c;
                ddw.emailAddresses = templates[0].MVDG__Email_Addresses__c;
                ddw.emailSubject = templates[0].MVDG__Email_Subject__c;
                ddw.emailBody = templates[0].MVDG__Email_Body__c;
                ddw.templateType = templates[0].MVDG__Template_Type__c;
                ddw.emailTemplate = templates[0].MVDG__Email_Template__c;
                String objectName = templates[0].MVDG__Object_API_Name__c;
                
                List<String> toFields = new List<String>();
                List<String> ccFields = new List<String>();
                List<String> bccFields = new List<String>();

                List<String> fieldList = new List<String>();
                String emailType = '';
                if (String.isNotBlank(ddw.emailAddresses) && ddw.emailAddresses.contains('<|DGE|>')) {
                    String[] splitResult = ddw.emailAddresses.split('<\\|DGE\\|>');
                    Integer splitSize = splitResult.size();
                    
                    if (splitSize >= 3) {
                        if (String.isNotBlank(splitResult[splitSize - 1])) {
                            bccFields = splitResult[splitSize - 1].split(',').clone();
                            for (Integer i = 0; i < bccFields.size(); i++) {
                                bccFields[i] = bccFields[i].trim();
                            }
                        }
                        if (String.isNotBlank(splitResult[splitSize - 2])) {
                            ccFields = splitResult[splitSize - 2].split(',').clone();
                            for (Integer i = 0; i < ccFields.size(); i++) {
                                ccFields[i] = ccFields[i].trim();
                                }
                            }
                        if (String.isNotBlank(splitResult[splitSize - 3])) {
                            toFields = splitResult[splitSize - 3].split(',').clone();
                            for (Integer i = 0; i < toFields.size(); i++) {
                                toFields[i] = toFields[i].trim();
                    }
                }
                ddw.emailType = emailType;
                // System.debug('email address: ' + ddw.emailAddresses);
                // System.debug('fieldList: ' + fieldList);

                ddw.toValues = new List<String>();
                ddw.ccValues = new List<String>();
                ddw.bccValues = new List<String>();

                if (String.isNotBlank(recordId) && String.isNotBlank(objectName)) {
                    List<String> allFields = new List<String>{'Id'};
                    allFields.addAll(toFields);
                    allFields.addAll(ccFields);
                    allFields.addAll(bccFields);
                    allFields = new List<String>(new Set<String>(allFields)); 

                    try {
                        Map<String, Object> record = queryRecord(objectName, recordId, allFields);
                        ddw.toValues.add(String.valueOf(record.get('Id')));
                        for (String field : toFields) {
                            Object fieldValue = record.get(field);
                            ddw.toValues.add(fieldValue != null ? String.valueOf(fieldValue) : '');
                        }
                        for (String field : ccFields) {
                            Object fieldValue = record.get(field);
                            ddw.ccValues.add(fieldValue != null ? String.valueOf(fieldValue) : '');
                        }
                        for (String field : bccFields) {
                            Object fieldValue = record.get(field);
                            ddw.bccValues.add(fieldValue != null ? String.valueOf(fieldValue) : '');
                        }
                    } catch (QueryException qe) {
                        ddw.toValues = new List<String>();
                        ddw.ccValues = new List<String>();
                        ddw.bccValues = new List<String>();
                    }
                }
                ddw.recordValues = recordValues;
                // System.debug('Returning ddw.recordValues:');

                return ddw;
            }else{
                return null;
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getTemplateDefaultValues');
            return null;
        }
    }

    @AuraEnabled
    public static Map<String, Object> queryRecord(String objectName, String recordId, List<String> fields) {
        try {
            String query = 'SELECT ' + String.join(fields, ',') + ' FROM ' + 
                          String.escapeSingleQuotes(objectName) + ' WHERE Id = :recordId WITH SECURITY_ENFORCED';
            // System.debug('SOQL Query: ' + query);
            SObject record = Database.query(query);
            return record.getPopulatedFieldsAsMap();
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'queryRecord');
            throw new AuraHandledException('Error executing query: ' + e.getMessage());
        }
    }



/*
*********************************************************
@description     : Method is used to store the default values for the generation options
@param          : defaultData {Map<String,String>} - map containing with default data for the template
@return           : void - won't return anything
********************************************************
*/  
    @AuraEnabled
    public static void setDefaultOptions(Map<String,String> defaultData){
        try {
            MVDG__Template__c template = new MVDG__Template__c(
                Id = defaultData.get('templateId'),
                MVDG__Button_Label__c  = defaultData.get('buttonLabel'),
                MVDG__Button_Api_Name__c  = defaultData.get('buttonName'),
                MVDG__Document_Type__c  = defaultData.get('docType'),
                MVDG__Internal_Storage__c  = defaultData.get('iStorage'),
                MVDG__Selected_Document_Folder__c = defaultData.get('folderId'),
                MVDG__External_Storage__c  = defaultData.get('eStorage'),
                MVDG__Output_Channel__c  = defaultData.get('oChannel'),
                MVDG__Email_Addresses__c  = defaultData.get('emailAddresses'),
                MVDG__Email_Subject__c  = defaultData.get('emailSubject'),
                MVDG__Email_Body__c  = defaultData.get('emailBody'),
                MVDG__Email_Template__c = defaultData.get('emailTemplate'),
                MVDG__Template_Status__c = true
            );
            update as User template;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'setDefaultOptions');
        }
    }


/*
*********************************************************
@description     : Method is used to delete the content version if only the external storages are selected
@param           : cvId {String} -  Id of the Content version to delete
@return          : void - won't return anything
********************************************************
*/  
    @AuraEnabled
    public static void deleteContentVersion(String cvId){
        try {
            Datetime now = Datetime.now();
                Datetime runTime = now.addMinutes(2);
                Integer day = runTime.day();
                Integer month = runTime.month();
                Integer year = runTime.year();
                Integer hour = runTime.hour();
                Integer minute = runTime.minute();
                
                String cronExp = String.format( '0 {0} {1} {2} {3} ? {4}', new List<String>{String.valueOf(minute), String.valueOf(hour), String.valueOf(day), String.valueOf(month), String.valueOf(year)});
                DeleteContentDocumentController deleteController = new DeleteContentDocumentController(cvId);
                String scheduleId = System.schedule('delete temp Content Version - ' + String.valueOf(System.now()) + ' ' + cvId, cronExp, deleteController);

        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GenerateDocumentController', 'deleteContentVersion');
        }
    }

/*
*********************************************************
@description     : Method is used to get the content version for generated content versions
@param           : Id {List} -  Id of the Content version to get
@return          : ContentFileWrapper {Wrapper} - wrapper containing with default data for the template
********************************************************
*/ 

// @AuraEnabled(cacheable=false)
// public static List<ContentFileWrapper> getContentFiles(List<Id> contentVersionIds) {
//     try {
//         List<ContentFileWrapper> results = new List<ContentFileWrapper>();
    
//             // Query directly using ContentVersion IDs
//             List<ContentVersion> versions = [
//                 SELECT Id, Title, FileExtension, VersionData
//                 FROM ContentVersion
//                 WHERE Id IN :contentVersionIds
//                 WITH USER_MODE
//             ];
    
//             for (ContentVersion cv : versions) {
//                 if (cv != null){
//                     String fileName = cv.Title + '.' + cv.FileExtension;
//                     String base64Data = EncodingUtil.base64Encode(cv.VersionData);
//                     results.add(new ContentFileWrapper(fileName, base64Data));
//                 }
//             }
    
//             return results;
//     } catch (Exception e) {
//         Log_Handler.store_Exception(e, 'GenerateDocumentController', 'getContentFiles');
//         return null;
//     }
// }

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
        @AuraEnabled public Boolean isUserWideAccessible;
    }

/*
*********************************************************
@description     : wrapper containing fileName and base64Data of the file
@param           : fileName String - To be used as file name
@param           : base64Data String - To be used as base64 data
********************************************************
*/
    // public class ContentFileWrapper {
    //     @AuraEnabled public String fileName;
    //     @AuraEnabled public String base64Data;

    //     public ContentFileWrapper(String fileName, String base64Data) {
    //         this.fileName = fileName;
    //         this.base64Data = base64Data;
    //     }
    // }

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
@description     : wrapper containing with default data for the template
@param           : templateId {String} - Id of the template to update
@param           : templateName {String} - name of the template
@param           : templateStatus {Boolean} - Status of the template
@param           : buttonLabel {String} - label of the Button for default creation
@param           : buttonName {String} - Api Name of the Button for default creation
@param           : docType {String} - Id of generated content version from API
@param           : iStorage {String} - comma saperated internal storages
@param           : folderId {String} - Id of the folder to save the document in
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
        @AuraEnabled public String templateId;
        @AuraEnabled public String templateName;
        @AuraEnabled public Boolean templateStatus;
        @AuraEnabled public String buttonLabel;
        @AuraEnabled public String buttonName;
        @AuraEnabled public String docType;
        @AuraEnabled public String iStorage;
        @AuraEnabled public String folderId;
        @AuraEnabled public String eStorage;
        @AuraEnabled public String oChannel;
        @AuraEnabled public String emailAddresses;
        @AuraEnabled public String emailSubject;
        @AuraEnabled public String emailBody;
        @AuraEnabled public String templateType;
        @AuraEnabled public String emailTemplate;
        @AuraEnabled public List<String> toValues;
        @AuraEnabled public List<String> ccValues;
        @AuraEnabled public List<String> bccValues;
    }


/*
*********************************************************
@description     : Wrapper combining the integration status, folders and template data
@param           : integrationWrapper {IntegrationWrapper} - wrapper containing integration status of different storage options
@param           : folderWrapper {FolderWrapper} - wrapper containing label and Id of the folders for the document storing
@param           : templates {List<Template__c>} - List of the templates
@param           : isSuccess {Boolean} - Boolean to show if the process was successfull or
********************************************************
*/

    public class CombinedDataWrapper{
        @AuraEnabled public IntegrationWrapper integrationWrapper;
        @AuraEnabled public List<FolderWrapper> folderWrapper;
        @AuraEnabled public List<MVDG__Template__c> templates;
        @AuraEnabled public List<EmailTemplate> emailTemplates;
        @AuraEnabled public Boolean isEditorAccess;
        @AuraEnabled public Boolean isSuccess;
    }
}
