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
            List<MVDG__Template_Data__c> queryData = [SELECT Id, MVDG__CSV_Query__c, MVDG__CSV_Fields__c, MVDG__Template__r.MVDG__Template_Name__c,MVDG__Template__r.MVDG__Description__c, MVDG__Template__r.MVDG__Object_API_Name__c FROM MVDG__Template_Data__c WHERE MVDG__Template__c =:templateId WITH SECURITY_ENFORCED ORDER BY MVDG__Order_No_Simple__c asc NULLS Last];
            if(queryData.size() > 0){
                System.debug('Basic Query ::'+queryData[0].MVDG__CSV_Query__c);
                System.debug('User Id ::'+ UserInfo.getUserId());
                String query = queryData[0].MVDG__CSV_Query__c.replaceAll('CURRENT_USER', UserInfo.getUserId()).substringBeforeLast('LIMIT') + ' LIMIT 25';
                System.debug('Query :::' + query);
                previewRecords = Database.query(query);
                listOfPDW.fields = queryData[0].MVDG__CSV_Fields__c;
                listOfPDW.records = previewRecords;
                listOfPDW.templateName = queryData[0].MVDG__Template__r.MVDG__Template_Name__c;
                listOfPDW.templateObject = queryData[0].MVDG__Template__r.MVDG__Object_API_Name__c;
                listOfPDW.templateDescription = queryData[0].MVDG__Template__r.MVDG__Description__c;
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