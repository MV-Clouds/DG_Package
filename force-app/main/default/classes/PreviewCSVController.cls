/*
*********************************************************
Apex Class Name    : PreviewCSVController
@description       : This class is used for handling various processes of the preview CSV Component, to fetch preview records and the template data
@author            : Kevin Suvagiya
@last Modified     : Kevin Suvagiya - 17 Sep, 2024
*********************************************************
*/
public with sharing class PreviewCSVController {
    
/*
*********************************************************
@description     : Method is used to fetch preview data for the CSV template
@param           : templateId {String} - Id of the template, to be previewed
@return          : PreviewDataWrapper - including all the preview data and the template data for the template
********************************************************
*/
    @AuraEnabled
    public static PreviewDataWrapper fetchPreviewData(String templateId){
        PreviewDataWrapper listOfPDW = new PreviewDataWrapper();
        try {
            List<sObject> previewRecords = new List<sObject>();
            List<MVDG__Template_Data__c> queryData = new List<MVDG__Template_Data__c>();
            if(templateId != null){
                queryData = [SELECT Id, MVDG__CSV_Query__c, MVDG__CSV_Fields__c, MVDG__Template__r.MVDG__Template_Name__c, MVDG__Template__r.MVDG__Template_Status__c, MVDG__Template__r.MVDG__Description__c, MVDG__Template__r.MVDG__Object_API_Name__c FROM MVDG__Template_Data__c WHERE MVDG__Template__c =:templateId WITH SECURITY_ENFORCED ORDER BY MVDG__Order_No_Simple__c asc NULLS Last];
            }
            if(queryData.size() > 0){
                String query = queryData[0].MVDG__CSV_Query__c.replaceAll('CURRENT_USER', UserInfo.getUserId());
                if(Integer.valueOf(query.substringAfterLast('LIMIT ')) > 25){
                    query = query.substringBeforeLast('LIMIT') + ' LIMIT 25';
                }
                previewRecords = Database.query(query, AccessLevel.USER_MODE);
                listOfPDW.records = previewRecords;
                listOfPDW.templateData = queryData[0];
            }
        } catch (Exception e) {
            listOfPDW.errorMessage = e.getMessage();
            log_Handler.store_Exception(e, 'PreviewCSVController', 'fetchPreviewData');
        }
        return listOfPDW;
    }


/*
*********************************************************
@description     : Wrapper class to contain the required preview data to return to the LWC
@param           : templateData {MVDG__Template_Data__c} - required data of the template
@param          : List<sObject> - including all the preview data for the template
********************************************************
*/
    public class PreviewDataWrapper{
        @AuraEnabled public List<sObject> records;
        @AuraEnabled public MVDG__Template_Data__c templateData;
        @AuraEnabled public String errorMessage;
    }

}