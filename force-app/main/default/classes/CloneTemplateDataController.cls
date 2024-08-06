public with sharing class CloneTemplateDataController {
    @AuraEnabled
    public static newTempleatData cloneTempData(String templateId, String templateName, String templateDescription, String jsonData){

        Map<String, String> dataMap = (Map<String, String>) JSON.deserialize(jsonData, Map<String, String>.class);

        String templateType = dataMap.get('templateType');
        String templateBody;
        String watermark;
        String header;
        String pageConfiguration;
        String footer;

        String selectedFields;
        String fieldsFilters;
        String fieldOrderBy;
        String fieldLimit;
        String testtest = 'this is test';

        newTempleatData field = new newTempleatData();
        try {
            List<Template__c> newList = new List<Template__c>();
            newList = [SELECT Id, Object_API_Name__c, Template_Type__c, Header_Text__c, Template_Name__c,Template_Status__c FROM Template__c WHERE Id =: templateId];

            List<Template_Data__c> cloneTemplateData;
            cloneTemplateData = [SELECT Id, Name, CSV_Fields__c, CSV_Filter__c, CSV_Query__c, Template__c, Template_Page__c, Google_Doc_Template_Id__c, Google_Doc_WebViewLink__c, Order_No_Simple__c, Template_Value_Simple__c, Value_Type__c ,CSV_Orders__c,CSV_Limit__c FROM Template_Data__c WHERE Template__c =: templateId];

            Template__c cloneTemp = new Template__c();
                String test = newList[0].Object_API_Name__c;
                cloneTemp.Object_API_Name__c = test;
                cloneTemp.Header_Text__c = newList[0].Header_Text__c;
                cloneTemp.Template_Name__c = templateName;
                cloneTemp.Description__c = templateDescription;
                cloneTemp.Template_Status__c = newList[0].Template_Status__c;
                cloneTemp.Template_Type__c = newList[0].Template_Type__c;
            insert cloneTemp;


            if (templateType == 'Simple Template') {
                templateBody = dataMap.get('templateBody');
                watermark = dataMap.get('watermark');
                header = dataMap.get('header');
                pageConfiguration = dataMap.get('pageConfiguration');
                footer = dataMap.get('footer');
                List<Template_Data__c> newTempDataSimpel = new List<Template_Data__c>();
                for (Template_Data__c tempDataSimpel : cloneTemplateData) {
                    Template_Data__c cloneTempData = new Template_Data__c();
                    if (templateBody == 'true') {
                        cloneTempData.CSV_Fields__c = tempDataSimpel.CSV_Fields__c;
                    }
                    if (watermark == 'true') {
                        cloneTempData.CSV_Filter__c = tempDataSimpel.CSV_Filter__c;
                    }
                    if(header == 'true'){
                        cloneTempData.CSV_Orders__c = tempDataSimpel.CSV_Orders__c;
                    }
                    if(pageConfiguration == 'true'){
                        cloneTempData.CSV_Limit__c = tempDataSimpel.CSV_Limit__c; 
                    }
                    if(footer == 'true'){
                        cloneTempData.CSV_Limit__c = tempDataSimpel.CSV_Limit__c; 
                    }
                    cloneTempData.CSV_Query__c = tempDataSimpel.CSV_Query__c;
                    cloneTempData.Template__c = cloneTemp.Id;
                    // cloneTempData.Google_Doc_Template_Id__c = tempDataSimpel.Google_Doc_Template_Id__c;
                    // cloneTempData.Google_Doc_WebViewLink__c = tempDataSimpel.Google_Doc_WebViewLink__c;
                    cloneTempData.Order_No_Simple__c = tempDataSimpel.Order_No_Simple__c;
                    cloneTempData.Template_Value_Simple__c = tempDataSimpel.Template_Value_Simple__c;
                    cloneTempData.Value_Type__c = tempDataSimpel.Value_Type__c;
                    newTempDataSimpel.add(cloneTempData);
                }
                insert newTempDataSimpel;
            }
            else if(templateType == 'CSV Template'){
                selectedFields = dataMap.get('newSelectedFields');
                fieldsFilters = dataMap.get('newFieldsFilters');
                fieldOrderBy = dataMap.get('newFieldOrderBy');
                fieldLimit = dataMap.get('newFieldLimit');
                List<Template_Data__c> newTempData = new List<Template_Data__c>();
                for (Template_Data__c tempData : cloneTemplateData) {
                    Template_Data__c cloneTempData = new Template_Data__c();
                    if (selectedFields == 'true') {
                        cloneTempData.CSV_Fields__c = tempData.CSV_Fields__c;
                    }
                    if (fieldsFilters == 'true') {
                        cloneTempData.CSV_Filter__c = tempData.CSV_Filter__c;
                    }
                    if(fieldOrderBy == 'true'){
                        cloneTempData.CSV_Orders__c = tempData.CSV_Orders__c;
                    }
                    if(fieldLimit == 'true'){
                        cloneTempData.CSV_Limit__c = tempData.CSV_Limit__c; 
                    }
                    cloneTempData.CSV_Query__c = tempData.CSV_Query__c;
                    cloneTempData.Template__c = cloneTemp.Id;
                    // cloneTempData.Google_Doc_Template_Id__c = tempData.Google_Doc_Template_Id__c;
                    // cloneTempData.Google_Doc_WebViewLink__c = tempData.Google_Doc_WebViewLink__c;
                    cloneTempData.Order_No_Simple__c = tempData.Order_No_Simple__c;
                    cloneTempData.Template_Value_Simple__c = tempData.Template_Value_Simple__c;
                    cloneTempData.Value_Type__c = tempData.Value_Type__c;
                    newTempData.add(cloneTempData);
                }
                insert newTempData;
            }
            System.debug('cloneTemp.Id'+cloneTemp.Id);
             
            field.tempId = cloneTemp.Id;
            field.tempObj = cloneTemp.Object_API_Name__c;

        } catch (Exception e) {
            System.debug('Exception'+e);
            System.debug('Exception occurred at line: ' + e.getLineNumber());
            System.debug('Exception Type: ' + e.getTypeName());
        }
        return field;
    }

    public class newTempleatData{
        @AuraEnabled public String tempId{get; set;}
        @AuraEnabled public String tempObj{get; set;}
    }

}