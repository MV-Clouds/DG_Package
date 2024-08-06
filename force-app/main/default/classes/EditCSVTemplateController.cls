public with sharing class EditCSVTemplateController {

/*
*********************************************************
@description    : Method is used to test the query generated, using executing the query once
@param query    : {String} - Generated query string based on the Selections
@return         : (Nothing will be returned)
********************************************************
*/
    @AuraEnabled
    public static Template__c getTemplateDetails(String templateId){
        Template__c template ;
        try {
            template = [SELECT Id, Template_Name__c, Description__c, List_View__c, Object_API_Name__c, CreatedDate, CreatedBy.Name, Template_Status__c, Template_Type__c, LastModifiedDate, LastModifiedBy.Name FROM Template__c WHERE Id =:templateId][0];
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'getTemplateDetails');
        }

        return template;
    }

    // -=-=- This method is used for to get the Template fields records if there are any for any template -=-=- 
/*
*********************************************************
@description     : Method is used to fetch data from the template fields records associated with template (if there are any)
@param templateId: {String} - Id of the current  template
@return          : TemplateDataWrapper - including the Selected Fields and the custom Separator Separated Filters String
********************************************************
*/
    @AuraEnabled
    public static TemplateDataWrapper getTemplateFieldsData(String templateId){
        TemplateDataWrapper allData = new TemplateDataWrapper();
        allData.fields = '';
        allData.filters = '';
        allData.listView = '';
        allData.logic = '';
        allData.orders = '';
        allData.maxLimit = 1000000;
        try {
            List<Template_Data__c> tf = [SELECT Id, CSV_Fields__c, CSV_Filter__c, Template__r.List_View__c, CSV_Logic__c, CSV_Orders__c, CSV_Query__c, CSV_Limit__c FROM Template_Data__c WHERE Template__c =:templateId WITH SECURITY_ENFORCED ORDER BY Order_No_Simple__c asc NULLS Last];
            // tf.addAll([SELECT Id, CSV_Fields__c, CSV_Filter__c, CSV_Query__c FROM Template_Data__c  WHERE Template__c =:templateId ORDER BY Order_No_Simple__c asc NULLS Last]);

            if(tf.size() >0){
                // for (Template_Data__c t : tf) {
                // }
                allData.listView = tf[0].Template__r.List_View__c;
                allData.logic = tf[0].CSV_Logic__c;
                allData.filters = tf[0].CSV_Filter__c;
                allData.orders = tf[0].CSV_Orders__c;
                allData.maxLimit = tf[0].CSV_Limit__c;
                allData.fields = tf[0].CSV_Fields__c;
            }
            System.debug('Template Fields Data Fetched: ' + allData);
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'getTemplateField');
        }
        return allData;
    }
    
/*
*********************************************************
@description    : Method is used to save all the Selected fields and the filters on the template fields associated with the selected template
@param allFields   : {String} - name of the object
@param templateId  : {String} - Id of the current template
@param query       : {String} - Generated query string based on the Selections
@param filters     : {String} - Generated Custom separator separated String, to store all sorts, filters, logic and Limit
@return         : (Nothing will be returned)
********************************************************
*/
    @AuraEnabled
    public static void saveTemplateFields(String templateId, String query, TemplateDataWrapper configData){
        try {
            List<Template_Data__c> existingData = [SELECT Id, CSV_Fields__c, CSV_Filter__c, CSV_Query__c, Template_Page__c FROM Template_Data__c WHERE Template__c =:templateId WITH SECURITY_ENFORCED ORDER BY Order_No_Simple__c asc NULLS Last];
            List<Template_Page__c> existingPage = [SELECT Id FROM Template_Page__c WHERE Template__c =:templateId WITH SECURITY_ENFORCED];
            // List<String> filterParts = new List<String>();

            System.debug('Config Data : ' + configData);
            System.debug('Template : ' + templateId);
            System.debug('Fields Count :: ' + existingData.size());
            System.debug('Pages Count :: ' + existingPage.size());

            Template__c template = new Template__c(
                Id = templateId,
                List_View__c = configData.listView
            );
            update template;

            Template_Page__c tp = new Template_Page__c();
            tp.Page_Number__c =001;
            tp.Template__c = templateId;
            if(existingPage.size() > 0){
                tp.Id = existingPage[0].Id;
            }
            if(Schema.sObjectType.MVDG__Template_Page__c.isUpdateable() && Schema.sObjectType.MVDG__Template_Page__c.isCreateable()){
                upsert tp;
            }

            Template_Data__c td = new Template_Data__c();
            td.Template__c = templateId;
            td.Template_Page__c = tp.id;
            td.CSV_Fields__c = configData.fields;
            td.CSV_Filter__c = configData.filters;
            td.CSV_Orders__c = configData.orders;
            td.CSV_Query__c = query;
            td.CSV_Logic__c = configData.logic;
            // td.CSV_List_View__c = configData.listView;
            td.CSV_Limit__c = configData.maxLimit;

            if(existingData.size() > 0){
                td.Id = existingData[0].Id;
            }

            if(Schema.sObjectType.MVDG__Template_Data__c.isUpdateable() && Schema.sObjectType.MVDG__Template_Data__c.isCreateable()){
                upsert td;
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'saveTemplateFields');
        }
    }

/*
*********************************************************
@description    : Method is used to validate the Id entered in the field of ID and the lookups
@param objName  : {String} - name of the object
@param apiName  : {String} - api name of the field
@return         : {String} - Will return the Object Id prefix
********************************************************
*/
    @AuraEnabled
    public static String validateRelatedObject(String objName, String apiName){
        String prefix = '';
        try{
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            if(apiName == 'ID'){
                prefix = Schema.getGlobalDescribe().get(objName).getDescribe().getKeyPrefix();
            }else{
                // Check if the object exists in the global describe
                if (globalDescribe.containsKey(objName)) {
                    Schema.SObjectType sObjectType = globalDescribe.get(objName);
                    Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objName).getDescribe();
                    Map<String, Schema.SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
                    
                    // Check if the field exists on the object
                    if (fieldMap.containsKey(apiName)) {
                        Schema.DescribeFieldResult fieldResult = fieldMap.get(apiName).getDescribe();
                        
                        // Check if the field is a reference field
                        if (fieldResult != null && fieldResult.getType() == Schema.DisplayType.REFERENCE) {
                            // Get the related object name
                            system.debug(fieldResult.getReferenceTo()[0].getDescribe().getName());
                            String relatedObjectName = fieldResult.getReferenceTo()[0].getDescribe().getName();
                            system.debug(Schema.getGlobalDescribe().get(relatedObjectName).getDescribe().getKeyPrefix());
                            prefix = Schema.getGlobalDescribe().get(relatedObjectName).getDescribe().getKeyPrefix();
                        }
                    }
                }
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'validateRelatedObject');
        }
        return prefix;
    }

/*
*********************************************************
@description    : Method is used to fetch all the list views of the object 
@param objName  : {String} - name of the object
@return         : {List<ListView>} - Will return the list of  Id and Name of all the list views of the object
********************************************************
*/
    @AuraEnabled
    public static List<ListView> getListViews(String objName){
        List<ListView> listViews = new List<ListView>();
        try {
            listViews = [SELECT Id,Name FROM ListView WHERE SobjectType =:objName WITH SECURITY_ENFORCED];
            System.debug(listViews);
        }catch (Exception e) {
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'getListViews');
        }
        return listViews;
    }

/*
*********************************************************
@description    : Method is used to update the basic details of the template
@param templateId  : {String} - Id of the current template
@param templateName : {String} - Name of the current template to update
@param templateDescription : {String} - Type of the current template to update
@param templateStatus  : {Boolean} - Status of the current template to update
@param listView  : {String } - List view selected on the template
@return         : (Nothing will be returned)
********************************************************
*/
    @AuraEnabled
    public static void updateTemplate(TemplateInfo templateInfo){
        try{
            Template__c updatedTemplate = new Template__c(
                Id = templateInfo.templateId,
                Template_Name__c = templateInfo.templateName,
                Description__c = templateInfo.templateDescription,
                Template_Status__c = templateInfo.templateStatus,
                List_View__c = templateInfo.listView
            );
            if(Schema.sObjectType.MVDG__Template__c.isUpdateable()){
                update updatedTemplate;
            }
        }catch(Exception e){
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'updateTemplate');
        }
    }

    // -=-=- this wrapper is used to store the fieldName, apiName and fieldType of an Object selected -=-=- 
    // -=-=-  this wrapper is used in a method getFields -=-=- 
    public class FieldInfoWrapper {
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String apiName { get; set; }
        @AuraEnabled public String fieldType { get; set; }
        @AuraEnabled public List<String> picklistValues { get; set; }
        @AuraEnabled public Boolean isSearchable { get; set; }
    }

    // -=-=- this wrapper is used to store the fields and filters strings containing data from existing template Fields for any template -=-=-
    // -=-=- this wrapper is used in a method getTemplateFieldsData -=-=-
    public class TemplateDataWrapper {
        @AuraEnabled public String fields { get; set; }
        @AuraEnabled public String filters { get; set; }
        @AuraEnabled public String listView { get; set; }
        @AuraEnabled public String logic { get; set; }
        @AuraEnabled public String orders { get; set; }
        @AuraEnabled public Decimal maxLimit { get; set; }
    }

    public class TemplateInfo{
        @AuraEnabled public String templateId { get; set; }
        @AuraEnabled public String templateName { get; set; }
        @AuraEnabled public String templateDescription { get; set; }
        @AuraEnabled public Boolean templateStatus { get; set; }
        @AuraEnabled public String listView { get; set; }
    }
}