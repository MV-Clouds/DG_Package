/*
*********************************************************
Apex Class Name    : NewTemplateCreationController
@description       : This class is used for handling various processes of the new template creation (newTemplateCreation LWC), for fetching the template types and saving the template 
@author            : Kevin Suvagiya
@last Modified     : Kevin Suvagiya - 18 Oct, 2024
*********************************************************
*/
public with sharing class NewTemplateCreationController {

/*
*********************************************************
@description     : Method is used to fetch the combined data to reduce apex calls
@param           : none
@return          : combinedData {CombinedData} - wrapper containing google integrated status and template types 
********************************************************
*/
    @AuraEnabled
    public static CombinedData getCombinedData() {
        CombinedData combinedData = new CombinedData();
        combinedData.isGoogleIntegrated = false;
        combinedData.templateTypes = null;
        try {
            List<String> picklistValues = new List<String>();
            Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get('MVDG__Template__c').getDescribe().fields.getMap().get('MVDG__Template_Type__c').getDescribe();
            if(fieldResult.getType() == Schema.DisplayType.Picklist) {
                List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
                for(Schema.PicklistEntry entry : picklistEntries) {
                    picklistValues.add(entry.getLabel());
                }
            }
            combinedData.templateTypes = picklistValues;
            Boolean isIntegrated = false;
            List<MVDG__AuthProviderSettings__c> googleDriveSetting = [SELECT MVDG__WorkingStatus__c FROM MVDG__AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId() WITH SECURITY_ENFORCED];
            if(googleDriveSetting.size() > 0){
                isIntegrated = googleDriveSetting[0].MVDG__WorkingStatus__c;
            }
            combinedData.isGoogleIntegrated = isIntegrated;
        }catch (Exception e) {
            Log_Handler.store_Exception(e, 'NewTemplateCreationController', 'getCombinedData');
        }
        return combinedData;
    }

/*
*********************************************************
@description     : Method is used to save the template with the template data
@param           : templateData {Map<String, String>} - Map containing the template data
@return          : templateId {String} - ID of the template just got created
********************************************************
*/
    @AuraEnabled
    public static String saveTemplate(Map<String, String> templateData){
        String templateId;
        try {
            MVDG__Template__c template = new MVDG__Template__c();
            template.MVDG__Template_Name__c = templateData.get('templateName');
            template.MVDG__Description__c = templateData.get('templateDescription');
            template.MVDG__Object_API_Name__c = templateData.get('sourceObject');
            template.MVDG__Template_Type__c = templateData.get('templateType');
            template.MVDG__Template_Status__c = true;
    
            insert as User template;
            templateId = template.Id;

            if(templateData.get('templateType') == 'Simple Template'){
                MVDG__Template_Page__c page = new MVDG__Template_Page__c();
                page.MVDG__Template__c = templateId;
                page.MVDG__Page_Number__c = 1;
                page.MVDG__Page_Margin__c = '1;1;1;1';        // [top;bottom;left;right]
                page.MVDG__Page_Orientation__c = 'portrait';
                page.MVDG__Page_Size__c = 'a4';
                page.MVDG__Unit_of_Page_Configs__c = 'in';
                page.MVDG__Show_Header__c = true;
                page.MVDG__Header_margin_top__c = 0.10;          // px to inch
                page.MVDG__Show_Footer__c = true;
                page.MVDG__Footer_margin_bottom__c = 0.10;       // px to inch
                // page.MVDG__Show_Watermark__c = true;       
                insert as User page;
            }
            return templateId;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'NewTemplateCreationController', 'saveTemplate');
            return 'Error Creating Template : ' + e.getMessage();
        } 
    }

    public class CombinedData{
        @AuraEnabled public List<String> templateTypes;
        @AuraEnabled public Boolean isGoogleIntegrated;
    }
    
}