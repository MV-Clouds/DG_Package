public with sharing class PreviewCSVController {
    
/*
*********************************************************
@description     : Method is used to fetch preview data for the CSV template
@param           : templateId {String} - Id of the template, to be previewed
@return          : List<sObject> - including all the preview data for the template
********************************************************
*/
    @AuraEnabled
    public static PreviewDataWrapper fetchPreviewData(String templateId){
        PreviewDataWrapper listOfPDW = new PreviewDataWrapper();
        try {
            List<sObject> previewRecords = new List<sObject>();
            List<Template_Data__c> queryData = [SELECT Id, CSV_Query__c, CSV_Fields__c, Template__r.Template_Name__c,Template__r.Description__c, Template__r.Object_API_Name__c FROM Template_Data__c WHERE Template__c =:templateId WITH SECURITY_ENFORCED ORDER BY Order_No_Simple__c asc NULLS Last];
            if(queryData.size() > 0){
                String query = queryData[0].CSV_Query__c.substringBeforeLast('LIMIT') + ' LIMIT 25';
                previewRecords = Database.query(query);
                listOfPDW.fields = queryData[0].CSV_Fields__c;
                listOfPDW.records = previewRecords;
                listOfPDW.templateName = queryData[0].Template__r.Template_Name__c;
                listOfPDW.templateObject = queryData[0].Template__r.Object_API_Name__c;
                listOfPDW.templateDescription = queryData[0].Template__r.Description__c;
            }
        } catch (Exception e) {
            log_Handler.store_Exception(e, 'PreviewCSVController', 'fetchPreviewData');
        }
        return listOfPDW;
    }


    public class PreviewDataWrapper{
        @AuraEnabled public String fields;
        @AuraEnabled public String templateName;
        @AuraEnabled public String templateDescription;
        @AuraEnabled public String templateObject;
        @AuraEnabled public List<sObject> records;
    }

}