/*
*********************************************************
Apex Class Name    : EditCSVTemplateController
@description       : This class is used for handling various processes of the CSV Template Builder(editCSVTemplate) for updating and fetchig the data of the template and template data records
@author            : Kevin Suvagiya
@last Modified     : Kevin Suvagiya - 18 Oct, 2024
*********************************************************
*/
public with sharing class EditCSVTemplateController {

    /*
    *********************************************************
    @description        : Method is used to redcuce apex callout and faster the process by combining multiple results
    @param templateId   : {String} - Id for the template to fetch
    @param objName      : {String} - name of the object
    @return             : {CombinedDataWrapper} - wrapper combining all the data
    ********************************************************
    */
    @AuraEnabled
    public static CombinedDataWrapper getCombinedData(String templateId, String objName){
        CombinedDataWrapper cdw = new CombinedDataWrapper();
        try {
            cdw.template = getTemplateDetails(templateId);
            cdw.templateData = getTemplateFieldsData(templateId);
            cdw.listViews = getListViews(objName);
            cdw.isSuccess = cdw.template != null && cdw.templateData != null && cdw.listViews != null ? true : false;
        }catch (Exception e) {
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'getCombinedData');
            cdw.isSuccess = false;
        }
        return cdw;
    }

    /*
    *********************************************************
    @description    : Method is used to test the query generated, using executing the query once
    @param templateId    : {String} - Id for the template to fetch
    @return         : (Nothing will be returned)
    ********************************************************
    */
    @AuraEnabled
    public static MVDG__Template__c getTemplateDetails(String templateId){
        try {
            List<MVDG__Template__c> templates = new List<MVDG__Template__c>();
            if(templateId != null){
                templates = [SELECT Id, MVDG__Template_Name__c, MVDG__Description__c, MVDG__List_View__c, MVDG__Object_API_Name__c, CreatedDate, CreatedBy.Name, MVDG__Template_Status__c, MVDG__Template_Type__c, LastModifiedDate, LastModifiedBy.Name FROM MVDG__Template__c WHERE Id =:templateId WITH SECURITY_ENFORCED lIMIT 1];
            }
            if(templates.size() > 0){
                return templates[0];
            }
            return null;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'getTemplateDetails');
            return null;
        }
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
            List<MVDG__Template_Data__c> tf = new List<MVDG__Template_Data__c>();
            if(templateId != null){
                tf = [SELECT Id, MVDG__CSV_Fields__c, MVDG__CSV_Filter__c, MVDG__Template__r.MVDG__List_View__c, MVDG__CSV_Logic__c, MVDG__CSV_Orders__c, MVDG__CSV_Query__c, MVDG__CSV_Limit__c FROM MVDG__Template_Data__c WHERE MVDG__Template__c =:templateId WITH SECURITY_ENFORCED ORDER BY MVDG__Order_No_Simple__c asc NULLS Last];
            }
            // tf.addAll([SELECT Id, MVDG__CSV_Fields__c, MVDG__CSV_Filter__c, MVDG__CSV_Query__c FROM MVDG__Template_Data__c  WHERE MVDG__Template__c =:templateId ORDER BY MVDG__Order_No_Simple__c asc NULLS Last]);

            if(tf.size() >0){
                allData.listView = tf[0].MVDG__Template__r.MVDG__List_View__c;
                allData.logic = tf[0].MVDG__CSV_Logic__c;
                allData.filters = tf[0].MVDG__CSV_Filter__c;
                allData.orders = tf[0].MVDG__CSV_Orders__c;
                allData.maxLimit = tf[0].MVDG__CSV_Limit__c;
                allData.fields = tf[0].MVDG__CSV_Fields__c;
            }
            return allData;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'getTemplateField');
            return null;
        }
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
        try {
            List<ListView> listViews = new List<ListView>();
            if(objName != null){
                listViews = [SELECT Id,Name FROM ListView WHERE SobjectType =:objName WITH SECURITY_ENFORCED];
            }
            return listViews;
        }catch (Exception e) {
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'getListViews');
            return null;
        }
    }


    /*
    *********************************************************
    @description    : Method is used to save all the Selected fields and the filters on the template fields associated with the selected template
    @param configData   : {Map<String,String>} - all the data that needs to be saved in the template data object
    @return         : (Nothing will be returned)
    ********************************************************
    */
    @AuraEnabled
    public static String saveTemplateFields(Map<String,String> configData){
        try {
            List<MVDG__Template_Data__c> existingData = [SELECT Id, MVDG__CSV_Fields__c, MVDG__CSV_Filter__c, MVDG__CSV_Query__c FROM MVDG__Template_Data__c WHERE MVDG__Template__c =:configData.get('templateId') WITH SECURITY_ENFORCED ORDER BY MVDG__Order_No_Simple__c asc NULLS Last];

            MVDG__Template__c template = new MVDG__Template__c(
                Id = configData.get('templateId'),
                MVDG__List_View__c = configData.get('listView')
            );
            update as User template;

            MVDG__Template_Data__c td = new MVDG__Template_Data__c();
            td.MVDG__Template__c = configData.get('templateId');
            td.MVDG__CSV_Fields__c = configData.get('fields');
            td.MVDG__CSV_Filter__c = configData.get('filters');
            td.MVDG__CSV_Orders__c = configData.get('orders');
            td.MVDG__CSV_Query__c = configData.get('query');
            td.MVDG__CSV_Logic__c = configData.get('logic');
            // td.MVDG__CSV_List_View__c = configData.get('listView');
            td.MVDG__CSV_Limit__c = Integer.valueOf(configData.get('maxLimit'));

            if(existingData.size() > 0){
                td.Id = existingData[0].Id;
            }
            upsert as User td;
            return 'success';
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'saveTemplateFields');
            return e.getMessage();
        }
    }

    /*
    *********************************************************
    @description    : Method is used to update the basic details of the template
    @param templateInfo  : {Map<String, String>} - Data Needed to update for the template
    @return         : (Nothing will be returned)
    ********************************************************
    */
    @AuraEnabled
    public static String updateTemplate(Map<String, String> templateInfo){
        try{
            MVDG__Template__c updatedTemplate = new MVDG__Template__c(
                Id = templateInfo.get('templateId'),
                MVDG__Template_Name__c = templateInfo.get('templateName'),
                MVDG__Description__c = templateInfo.get('templateDescription'),
                MVDG__Template_Status__c = Boolean.valueOf(templateInfo.get('templateStatus')),
                MVDG__List_View__c = templateInfo.get('listView')
            );
            update as User updatedTemplate;
            return 'success';
        }catch(Exception e){
            Log_Handler.store_Exception(e, 'EditCSVTemplateController', 'updateTemplate');
            return e.getMessage();
        }
    }

    /*
    *********************************************************
    @description    : Wrapper class to contain all the data about the template Data record
    @param fields  : {String} - selected column fields for the csv
    @param filters : {String} - Created filters for the csv
    @param listView : {String} - applied list view
    @param logic  : {String} - applied logic
    @param orders  : {String } - applied sort orders
    @param maxLimit  : {Integer} - Max number of records in the csv
    ********************************************************
    */
    public class TemplateDataWrapper {
        @AuraEnabled public String fields;
        @AuraEnabled public String filters;
        @AuraEnabled public String listView;
        @AuraEnabled public String logic;
        @AuraEnabled public String orders;
        @AuraEnabled public Decimal maxLimit;
    }

    /*
    *********************************************************
    @description    : Wrapper class to contain all data about the template
    @param templateId  : {String} - Id of the current template
    @param templateName : {String} - Name of the current template to update
    @param templateDescription : {String} - Type of the current template to update
    @param templateStatus  : {Boolean} - Status of the current template to update
    @param listView  : {String } - List view selected on the template
    ********************************************************
    */
    public class TemplateInfo{
        @AuraEnabled public String templateId;
        @AuraEnabled public String templateName;
        @AuraEnabled public String templateDescription;
        @AuraEnabled public Boolean templateStatus;
        @AuraEnabled public String listView;
    }

    /*
    *********************************************************
    @description         : Wrapper class to contain combined data of three other methods
    @param template      : {MVDG__Template__c} - template related data
    @param templateData  : {TemplateDataWrapper} - template data record related to template
    @param listViews     : {List<ListView>} - List of the list view on an object
    @param isSuccess     : {Boolean} - flag to determine if the process was successfull or not
    ********************************************************
    */
    public class CombinedDataWrapper{
        @AuraEnabled public MVDG__Template__c template;
        @AuraEnabled public TemplateDataWrapper templateData;
        @AuraEnabled public List<ListView> listViews;
        @AuraEnabled public Boolean isSuccess;
    }
}