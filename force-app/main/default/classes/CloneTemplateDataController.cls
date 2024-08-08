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
            List<MVDG__Template__c> newList = new List<MVDG__Template__c>();
            newList = [SELECT Id, MVDG__Object_API_Name__c, MVDG__Template_Type__c, MVDG__Header_Text__c, MVDG__Template_Name__c,MVDG__Template_Status__c FROM MVDG__Template__c WHERE Id =: templateId];

            List<MVDG__Template_Data__c> cloneTemplateData;
            cloneTemplateData = [SELECT Id, Name, MVDG__CSV_Fields__c, MVDG__CSV_Filter__c, MVDG__CSV_Query__c, MVDG__Template__c, MVDG__Template_Page__c, MVDG__Google_Doc_Template_Id__c, MVDG__Google_Doc_WebViewLink__c, MVDG__Order_No_Simple__c, MVDG__Template_Value_Simple__c, MVDG__Value_Type__c ,MVDG__CSV_Orders__c,MVDG__CSV_Limit__c FROM MVDG__Template_Data__c WHERE MVDG__Template__c =: templateId];

            MVDG__Template__c cloneTemp = new MVDG__Template__c();
                String test = newList[0].MVDG__Object_API_Name__c;
                cloneTemp.MVDG__Object_API_Name__c = test;
                cloneTemp.MVDG__Header_Text__c = newList[0].MVDG__Header_Text__c;
                cloneTemp.MVDG__Template_Name__c = templateName;
                cloneTemp.MVDG__Description__c = templateDescription;
                cloneTemp.MVDG__Template_Status__c = newList[0].MVDG__Template_Status__c;
                cloneTemp.MVDG__Template_Type__c = newList[0].MVDG__Template_Type__c;
            insert cloneTemp;


            if (templateType == 'Simple Template') {
                templateBody = dataMap.get('templateBody');
                watermark = dataMap.get('watermark');
                header = dataMap.get('header');
                pageConfiguration = dataMap.get('pageConfiguration');
                footer = dataMap.get('footer');
                List<MVDG__Template_Data__c> newTempDataSimpel = new List<MVDG__Template_Data__c>();
                for (MVDG__Template_Data__c tempDataSimpel : cloneTemplateData) {
                    MVDG__Template_Data__c cloneTempData = new MVDG__Template_Data__c();
                    if (templateBody == 'true') {
                        cloneTempData.MVDG__CSV_Fields__c = tempDataSimpel.MVDG__CSV_Fields__c;
                    }
                    if (watermark == 'true') {
                        cloneTempData.MVDG__CSV_Filter__c = tempDataSimpel.MVDG__CSV_Filter__c;
                    }
                    if(header == 'true'){
                        cloneTempData.MVDG__CSV_Orders__c = tempDataSimpel.MVDG__CSV_Orders__c;
                    }
                    if(pageConfiguration == 'true'){
                        cloneTempData.MVDG__CSV_Limit__c = tempDataSimpel.MVDG__CSV_Limit__c; 
                    }
                    if(footer == 'true'){
                        cloneTempData.MVDG__CSV_Limit__c = tempDataSimpel.MVDG__CSV_Limit__c; 
                    }
                    cloneTempData.MVDG__CSV_Query__c = tempDataSimpel.MVDG__CSV_Query__c;
                    cloneTempData.MVDG__Template__c = cloneTemp.Id;
                    // cloneTempData.MVDG__Google_Doc_Template_Id__c = tempDataSimpel.MVDG__Google_Doc_Template_Id__c;
                    // cloneTempData.MVDG__Google_Doc_WebViewLink__c = tempDataSimpel.MVDG__Google_Doc_WebViewLink__c;
                    cloneTempData.MVDG__Order_No_Simple__c = tempDataSimpel.MVDG__Order_No_Simple__c;
                    cloneTempData.MVDG__Template_Value_Simple__c = tempDataSimpel.MVDG__Template_Value_Simple__c;
                    cloneTempData.MVDG__Value_Type__c = tempDataSimpel.MVDG__Value_Type__c;
                    newTempDataSimpel.add(cloneTempData);
                }
                insert newTempDataSimpel;
            }
            else if(templateType == 'CSV Template'){
                selectedFields = dataMap.get('newSelectedFields');
                fieldsFilters = dataMap.get('newFieldsFilters');
                fieldOrderBy = dataMap.get('newFieldOrderBy');
                fieldLimit = dataMap.get('newFieldLimit');
                List<MVDG__Template_Data__c> newTempData = new List<MVDG__Template_Data__c>();
                for (MVDG__Template_Data__c tempData : cloneTemplateData) {
                    MVDG__Template_Data__c cloneTempData = new MVDG__Template_Data__c();
                    if (selectedFields == 'true') {
                        cloneTempData.MVDG__CSV_Fields__c = tempData.MVDG__CSV_Fields__c;
                    }
                    if (fieldsFilters == 'true') {
                        cloneTempData.MVDG__CSV_Filter__c = tempData.MVDG__CSV_Filter__c;
                    }
                    if(fieldOrderBy == 'true'){
                        cloneTempData.MVDG__CSV_Orders__c = tempData.MVDG__CSV_Orders__c;
                    }
                    if(fieldLimit == 'true'){
                        cloneTempData.MVDG__CSV_Limit__c = tempData.MVDG__CSV_Limit__c; 
                    }
                    cloneTempData.MVDG__CSV_Query__c = tempData.MVDG__CSV_Query__c;
                    cloneTempData.MVDG__Template__c = cloneTemp.Id;
                    // cloneTempData.MVDG__Google_Doc_Template_Id__c = tempData.MVDG__Google_Doc_Template_Id__c;
                    // cloneTempData.MVDG__Google_Doc_WebViewLink__c = tempData.MVDG__Google_Doc_WebViewLink__c;
                    cloneTempData.MVDG__Order_No_Simple__c = tempData.MVDG__Order_No_Simple__c;
                    cloneTempData.MVDG__Template_Value_Simple__c = tempData.MVDG__Template_Value_Simple__c;
                    cloneTempData.MVDG__Value_Type__c = tempData.MVDG__Value_Type__c;
                    newTempData.add(cloneTempData);
                }
                insert newTempData;
            }
            System.debug('cloneTemp.Id'+cloneTemp.Id);
             
            field.tempId = cloneTemp.Id;
            field.tempObj = cloneTemp.MVDG__Object_API_Name__c;

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