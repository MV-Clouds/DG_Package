/*
*********************************************************
Apex Class Name    : CloneTemplateDataController
@description       : This class is used to clone the template
@author            : Yash Shah
@last Modified     : Kevin Suvagiya - 22 Oct, 2024
*********************************************************
*/

public with sharing class CloneTemplateDataController {

    /*
    *********************************************************
    @description        : Method is used to clone the data selected by the user for the templates
    @param templateId   : {String} - Id for the template to fetch
    @param jsonData      : {String} - the data about the user selection for cloning the data
    @return             : {NewTemplateData} - wrapper combining all the data
    ********************************************************
    */
    @AuraEnabled
    public static NewTemplateData cloneTempData(String templateId, String jsonData){

        Map<String, String> dataMap = (Map<String, String>) JSON.deserialize(jsonData, Map<String, String>.class);

        String templateType = dataMap.get('templateType');
        String templateName = dataMap.get('templateName');
        String templateDescription = dataMap.get('templateDescription');
        String templateBody;
        String header;
        String pageConfiguration;
        String footer;

        String selectedFields;
        String fieldsFilters;
        String fieldOrderBy;
        String fieldLimit;
        String testtest = 'this is test';

        NewTemplateData field = new NewTemplateData();
        try {
            List<MVDG__Template__c> newList = new List<MVDG__Template__c>();
            newList = [SELECT Id, MVDG__Object_API_Name__c, MVDG__Template_Type__c, MVDG__Header_Text__c, MVDG__Template_Name__c,MVDG__Template_Status__c, MVDG__List_View__c FROM MVDG__Template__c WHERE Id =: templateId WITH SECURITY_ENFORCED];
            MVDG__Template__c cloneTemp = new MVDG__Template__c();
            String test = newList[0].MVDG__Object_API_Name__c;
            cloneTemp.MVDG__Object_API_Name__c = test;
            cloneTemp.MVDG__Header_Text__c = newList[0].MVDG__Header_Text__c;
            cloneTemp.MVDG__Template_Name__c = templateName;
            cloneTemp.MVDG__Description__c = templateDescription;
            cloneTemp.MVDG__Template_Status__c = newList[0].MVDG__Template_Status__c;
            cloneTemp.MVDG__Template_Type__c = newList[0].MVDG__Template_Type__c;
            cloneTemp.MVDG__List_View__c = newList[0].MVDG__List_View__c;
            insert as user cloneTemp;

            if (templateType == 'Simple Template') {
                templateBody = dataMap.get('templateBody');
                header = dataMap.get('header');
                pageConfiguration = dataMap.get('pageConfiguration');
                footer = dataMap.get('footer');
                List<String> valueTypes = new List<String>();
                if (templateBody == 'true') {
                    valueTypes.add('Body Value');
                }
                if(header == 'true'){
                    valueTypes.add('Header Value');
                }
                if(footer == 'true'){
                    valueTypes.add('Footer Value');
                }
                if(valueTypes?.size() > 1 ){
                    valueTypes.add('Extracted Mapping Keys');
                } 
                MVDG__Template_Page__c cloneTemplatePageData = new MVDG__Template_Page__c();
                if(pageConfiguration == 'true'){
                    List<MVDG__Template_Page__c> cloneTemplatePage = new List<MVDG__Template_Page__c>();
                    cloneTemplatePage = [SELECT Id, Name, MVDG__Template__c, MVDG__Page_Margin__c, MVDG__Page_Orientation__c, MVDG__Page_Size__c, MVDG__Unit_of_Page_Configs__c, MVDG__Show_Header__c, MVDG__Show_Footer__c, MVDG__Show_Watermark__c, MVDG__Header_margin_top__c, MVDG__Footer_margin_bottom__c,MVDG__Page_Number__c FROM MVDG__Template_Page__c WHERE MVDG__Template__c =: templateId WITH SECURITY_ENFORCED];
                    if(cloneTemplatePage.size() > 0){
                        cloneTemplatePageData.MVDG__Template__c = cloneTemp.Id;
                        cloneTemplatePageData.MVDG__Page_Number__c = cloneTemplatePage[0].MVDG__Page_Number__c;
                        cloneTemplatePageData.MVDG__Page_Margin__c = cloneTemplatePage[0].MVDG__Page_Margin__c;
                        cloneTemplatePageData.MVDG__Page_Orientation__c = cloneTemplatePage[0].MVDG__Page_Orientation__c;
                        cloneTemplatePageData.MVDG__Page_Size__c = cloneTemplatePage[0].MVDG__Page_Size__c;
                        cloneTemplatePageData.MVDG__Unit_of_Page_Configs__c = cloneTemplatePage[0].MVDG__Unit_of_Page_Configs__c;
                        cloneTemplatePageData.MVDG__Show_Header__c = cloneTemplatePage[0].MVDG__Show_Header__c;
                        cloneTemplatePageData.MVDG__Show_Footer__c = cloneTemplatePage[0].MVDG__Show_Footer__c;
                        cloneTemplatePageData.MVDG__Show_Watermark__c = cloneTemplatePage[0].MVDG__Show_Watermark__c;
                        cloneTemplatePageData.MVDG__Header_margin_top__c = cloneTemplatePage[0].MVDG__Header_margin_top__c;
                        cloneTemplatePageData.MVDG__Footer_margin_bottom__c = cloneTemplatePage[0].MVDG__Footer_margin_bottom__c;
                        insert as user cloneTemplatePageData;
                    }
                }
                List<MVDG__Template_Data__c> cloneTemplateData = new List<MVDG__Template_Data__c>();
                cloneTemplateData = [SELECT Id, Name, MVDG__Template__c, MVDG__Template_Page__c,  MVDG__Order_No_Simple__c, MVDG__Template_Value_Simple__c, MVDG__Value_Type__c  FROM MVDG__Template_Data__c WHERE MVDG__Template__c =: templateId AND MVDG__Value_Type__c IN : valueTypes WITH SECURITY_ENFORCED];

                List<MVDG__Template_Data__c> newTempDataSimpel = new List<MVDG__Template_Data__c>();
                for (MVDG__Template_Data__c tempDataSimpel : cloneTemplateData) {
                    MVDG__Template_Data__c cloneTempData = new MVDG__Template_Data__c();
                    cloneTempData.MVDG__Template__c = cloneTemp.Id;
                    cloneTempData.MVDG__Template_Page__c = cloneTemplatePageData.Id;
                    cloneTempData.MVDG__Order_No_Simple__c = tempDataSimpel.MVDG__Order_No_Simple__c;
                    cloneTempData.MVDG__Template_Value_Simple__c = tempDataSimpel.MVDG__Template_Value_Simple__c;
                    cloneTempData.MVDG__Value_Type__c = tempDataSimpel.MVDG__Value_Type__c;
                    newTempDataSimpel.add(cloneTempData);
                }
                insert as user newTempDataSimpel;
            }
            else if(templateType == 'CSV Template'){
                List<MVDG__Template_Data__c> cloneTemplateData = new List<MVDG__Template_Data__c>();
                cloneTemplateData = [SELECT Id, Name, MVDG__CSV_Fields__c, MVDG__CSV_Filter__c, MVDG__CSV_Query__c, MVDG__Template__c, MVDG__Template_Page__c, MVDG__Order_No_Simple__c, MVDG__Value_Type__c ,MVDG__CSV_Orders__c,MVDG__CSV_Limit__c FROM MVDG__Template_Data__c WHERE MVDG__Template__c =: templateId WITH SECURITY_ENFORCED];
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
                    // cloneTempData.MVDG__CSV_Query__c = tempData.MVDG__CSV_Query__c;
                    cloneTempData.MVDG__Template__c = cloneTemp.Id;
                    cloneTempData.MVDG__Order_No_Simple__c = tempData.MVDG__Order_No_Simple__c;
                    cloneTempData.MVDG__Value_Type__c = tempData.MVDG__Value_Type__c;
                    newTempData.add(cloneTempData);
                }
                insert as user newTempData; 
            }
            field.tempId = cloneTemp.Id;
            field.tempObj = cloneTemp.MVDG__Object_API_Name__c;
            field.isSuccess = true;

        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'CloneTemplateDataController', 'cloneTempData');
            field.isSuccess = false;
        }
        return field;
    }

    public class NewTemplateData{
        @AuraEnabled public String tempId;
        @AuraEnabled public String tempObj;
        @AuraEnabled public Boolean isSuccess;
    }

}