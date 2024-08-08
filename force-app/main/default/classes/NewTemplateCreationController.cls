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
            List<MVDG__AuthProviderSettings__c> googleDriveSetting = [SELECT MVDG__WorkingStatus__c FROM MVDG__AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId()];
            if(googleDriveSetting.size() > 0){
                isIntegrated = googleDriveSetting[0].MVDG__WorkingStatus__c;
            }
        } catch (Exception e) {
            System.debug('Error in isGoogleIntegrated =>' + e.getMessage());
            Log_Handler.store_Exception(e, 'NewTemplateCreationController', 'isGoogleIntegrated');
        }
        return isIntegrated;
    }

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
    
            if(MVDG__Template__c.SObjectType.getDescribe().isCreateable() == false){
                throw new AuraHandledException('You have no permission to insert this object MVDG__Template__c');
            }
            insert template;
            templateId = template.Id;

            if(templateData.get('templateType') == 'Simple Template' && Schema.sObjectType.MVDG__Template_Page__c.isCreateable()){
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
        @AuraEnabled public String name;
        @AuraEnabled public String apiName;
    }

    public class TemplateData{
        @AuraEnabled public String templateName;
        @AuraEnabled public String templateDescription;
        @AuraEnabled public String sourceObject;
        @AuraEnabled public String templateType;
    }
    
}