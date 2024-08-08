/* **************************************************************************
*
* Controller Class: HomePageController
* Created by : Nirbhay Navik
*
*   Used For : 
* - Fetch All Template To Display on preview
* - Update Temnplate Status from Home Page
* - Delete Template from Home Page

************************************************************************** */
public with sharing class HomePageController {

    /*
     * @Author : Nirbhay Navik
     * @Name : getTemplateList
     * @ReturnType : ReturnValues (Class)
     * @param : none
     * @Description : Get Template records list to preview on home page
    */
    @AuraEnabled
    public static ReturnValues getTemplateList(){
        ReturnValues returnValue = new ReturnValues();
        try {

            List<MVDG__Template__c> tempList = [  SELECT Id, IsDeleted, Name, MVDG__Object_API_Name__c, MVDG__Template_Name__c, MVDG__Template_Type__c, MVDG__Template_Status__c, MVDG__Description__c, CreatedDate, CreatedBy.Name,LastModifiedDate
                                            FROM MVDG__Template__c WITH SECURITY_ENFORCED
                                            ORDER BY LastModifiedDate DESC, MVDG__Template_Name__c ASC, MVDG__Object_API_Name__c ASC];

            if (tempList.size() > 0) {
                // Store Object API Name of create Templates...
                Set<String> objectListSet = new Set<String>();  
                for(MVDG__Template__c temp : tempList){
                    objectListSet.add(temp.MVDG__Object_API_Name__c);
                }
    
                // Create List Of Object of create Templates with API and Label...
                List<TempObject> objectList = new List<TempObject>();
                for(String objectApi : objectListSet){
                    TempObject tempObj = new TempObject();
                    tempObj.value = objectApi;
                    tempObj.label = (String)Schema.getGlobalDescribe().get(objectApi).getDescribe().getLabel();
                    objectList.add(tempObj);
                }

                // Get all Templaet Tyeps...
                returnValue.templateTypes = getAllTemplateTypes();
    
                // Create List of Only Date Field form Templare Object...
                returnValue.dateFields = createTempFieldInstance('MVDG__Template__c');

                // returnValue.isGoogleDocEnable = MVDG__AuthProviderSettings__c.getOrgDefaults().MVDG__WorkingStatus__c || MVDG__AuthProviderSettings__c.getInstance().MVDG__WorkingStatus__c;
                // returnValue.isGoogleDocEnable = MVDG__AuthProviderSettings__c.getInstance().MVDG__WorkingStatus__c;
                returnValue.isGoogleDocEnable = [SELECT Id, MVDG__WorkingStatus__c FROM MVDG__AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1]?.MVDG__WorkingStatus__c;
                
                // Assign Values to returnValue Object...
                returnValue.isSuccess = true;
                returnValue.objectList = objectList;
                returnValue.returnMessage = 'Success';
                returnValue.templateList = tempList;
            }
            else {
                returnValue.isSuccess = true;
                returnValue.returnMessage = 'No Template Found';
            }

            return returnValue;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'docGeniusHomePageController', 'getTempalaterecords');
            system.debug('exception in getTempalaterecords : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            // Set False in case of Exception
            returnValue.isSuccess = false;          
            returnValue.returnMessage = 'Error in getTempalaterecords : ' + e.getMessage();
            return returnValue;
        }
    }

    public static List<TemFieldInstance> getAllTemplateTypes(){
        List<TemFieldInstance> templateTypes = new List<TemFieldInstance>();
        try {
            
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get('MVDG__Template__c').getDescribe();
            for (Schema.SObjectField field : objectDescribe.fields.getMap().values()) {
                if (field.getDescribe().getName() == 'MVDG__Template_Type__c') {
                    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                    List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
                    for (Schema.PicklistEntry picklistEntry : picklistEntries) {
                        TemFieldInstance picklistValue = new TemFieldInstance();
                        picklistValue.label = picklistEntry.getLabel();
                        picklistValue.value = picklistEntry.getValue();
                        templateTypes.add(picklistValue);
                    }
                }
            }

            return templateTypes;

        } catch (Exception e) {
            system.debug('exception in createTempFieldInstance : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return templateTypes;
        }
    }

    public static List<TemFieldInstance> createTempFieldInstance(String objectAPINAme){
        List<TemFieldInstance> templateField = new List<TemFieldInstance>();
        try {
            Map<String, Schema.SObjectField> mapofAllField = Schema.getGlobalDescribe().get(objectAPINAme).getDescribe().fields.getMap();
                for(String fieldName : mapofAllField.keySet()){
                    Schema.SObjectField field = mapofAllField.get(fieldName);
                    Schema.DescribeFieldResult fd = field.getDescribe();
                    if( (String.valueOf(fd.getType()) == 'DATETIME' || String.valueOf(fd.getType()) == 'DATE') && 
                        (String.valueOf(fd.getName()) != 'LastReferencedDate' &&  String.valueOf(fd.getName()) != 'System Modstamp' && String.valueOf(fd.getName()) != 'SystemModstamp' && String.valueOf(fd.getName()) != 'LastViewedDate')){
                        TemFieldInstance dateField = new TemFieldInstance();
                        dateField.label = String.valueOf(fd.getLabel());
                        dateField.value = String.valueOf(fd.getName());
                        templateField.add(dateField);
                    }
                }
            return templateField;
        } catch (Exception e) {
            system.debug('exception in createTempFieldInstance : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return templateField;
        }
    }

    @AuraEnabled
    public static string updateTemplate(String templateId, Boolean isActive){
        // Try and catch block not used... beacuase here is no changes to fall this method in chatch block....
        List<MVDG__Template__c> tempToUpdate = [SELECT ID, Name, MVDG__Template_Name__c  FROM MVDG__Template__c WHERE ID = : templateId WITH SECURITY_ENFORCED LIMIT 1];
        if(tempToUpdate.size() > 0){
            // if (Schema.sObjectType.MVDG__Template__c.fields.MVDG__Template_Name__c.isUpdateable()) {
                tempToUpdate[0].MVDG__Template_Status__c = isActive;
                update tempToUpdate[0];
            // }
            return 'updated';
        }

        return 'no Template Found';
    }

    @AuraEnabled
    public static boolean deleteTemplate(String templateId){
        // Try and catch block not used... beacuase here is no changes to fall this method in chatch block....
        List<MVDG__Template__c> tempToDelete = [SELECT ID, Name  FROM MVDG__Template__c WHERE ID =:templateId WITH SECURITY_ENFORCED LIMIT 1];
        if(tempToDelete.size() > 0){
            delete tempToDelete[0];
            return true;
        }
            return false;
    }

    public class ReturnValues{
        @AuraEnabled public list<MVDG__Template__c> templateList;
        @AuraEnabled public list<TempObject> objectList;
        @AuraEnabled public list<TemFieldInstance> dateFields;
        @AuraEnabled public boolean isSuccess;
        @AuraEnabled public String returnMessage;
        @AuraEnabled public boolean isGoogleDocEnable;
        @AuraEnabled public list<TemFieldInstance> templateTypes;
    }

    public class TempObject{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    public class TemFieldInstance{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

}