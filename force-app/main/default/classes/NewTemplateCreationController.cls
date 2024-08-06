public with sharing class NewTemplateCreationController {
    
    @AuraEnabled
    public static List<ObjectInfo> getObjects() {
        List<ObjectInfo> objectsInfo = new List<ObjectInfo>();
        try {
            for ( Schema.SObjectType o : Schema.getGlobalDescribe().values() )
            {
                Schema.DescribeSObjectResult objResult = o.getDescribe();
                ObjectInfo info = new ObjectInfo();
                info.name = objResult.getLabel();
                info.apiName = objResult.getName();
                if(!info.apiName.containsignorecase('history') && !info.apiName.containsignorecase('tag') &&
                !info.apiName.containsignorecase('share') && !info.apiName.containsignorecase('feed') && 
                !info.apiName.containsignorecase('group') && !info.apiName.containsignorecase('public') &&
                !objResult.isCustomSetting() && objResult.isCreateable() &&
                objResult.getRecordTypeInfos().size() > 0){
                    
                    objectsInfo.add(info);
                }
            }
    
            System.debug('All objects size:: ' + objectsInfo.size());
            System.debug('All objects :: ' + objectsInfo);
        } catch (Exception e) {
            System.debug('Error in getObjects =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'NewTemplateCreationController', 'getObjects');
        }
        return objectsInfo;
    }

    @AuraEnabled
    public static List<String> getTemplateTypes() {
        List<String> picklistValues = new List<String>();
        try {
            Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get('MVDG__Template__c').getDescribe().fields.getMap().get('MVDG__Template_Type__c').getDescribe();
            if(fieldResult.getType() == Schema.DisplayType.Picklist) {
                List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
                for(Schema.PicklistEntry entry : picklistEntries) {
                    picklistValues.add(entry.getLabel());
                }
            }
        } catch (Exception e) {
            System.debug('Error in getTemplateTypes =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'NewTemplateCreationController', 'getTemplateTypes');
        }
        return picklistValues;
    }

    @AuraEnabled
    public static Boolean isGoogleIntegrated(){
        Boolean isIntegrated = false;
        try {
            List<AuthProviderSettings__c> googleDriveSetting = [SELECT WorkingStatus__c FROM AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId()];
            if(googleDriveSetting.size() > 0){
                isIntegrated = googleDriveSetting[0].WorkingStatus__c;
            }
        } catch (Exception e) {
            System.debug('Error in isGoogleIntegrated =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'NewTemplateCreationController', 'isGoogleIntegrated');
        }
        return isIntegrated;
    }

    @AuraEnabled
    public static String saveTemplate(TemplateData templateData){
        String templateId;
        try {
            Template__c template = new Template__c();
            template.Template_Name__c = templateData.templateName;
            template.Description__c = templateData.templateDescription;
            template.Object_API_Name__c = templateData.sourceObject;
            template.Template_Type__c = templateData.templateType;
            template.Template_Status__c = true;
    
            if(Schema.sObjectType.MVDG__Template__c.isCreateable()){
                insert template;
            }
            templateId = template.Id;

            if(templateData.templateType == 'Simple Template' && Schema.sObjectType.MVDG__Template_Page__c.isCreateable()){
                Template_Page__c page = new Template_Page__c();
                page.Template__c = templateId;
                page.Page_Number__c = 1;
                page.Page_Margin__c = '1;1;1;1';        // [top;bottom;left;right]
                page.Page_Orientation__c = 'portrait';
                page.Page_Size__c = 'a4';
                page.Unit_of_Page_Configs__c = 'in';
                page.Show_Header__c = true;
                page.Header_margin_top__c = 0.10;          // px to inch
                page.Show_Footer__c = true;
                page.Footer_margin_bottom__c = 0.10;       // px to inch
                // page.Show_Watermark__c = true;       
                insert page;
            }

        } catch (Exception e) {
            System.debug('Error in saving Template =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'NewTemplateCreationController', 'saveTemplate');
            throw new AuraHandledException('error saving template.');
        }
        return templateId;
    }
    
    public class ObjectInfo {
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String apiName {get; set;}
    }

    public class TemplateData{
        @AuraEnabled public String templateName { get; set; }
        @AuraEnabled public String templateDescription { get; set; }
        @AuraEnabled public String sourceObject { get; set; }
        @AuraEnabled public String templateType { get; set; }
    }
    
}