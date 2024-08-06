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

            List<Template__c> tempList = [  SELECT Id, IsDeleted, Name, Object_API_Name__c, Template_Name__c, Template_Type__c, Template_Status__c, Description__c, CreatedDate, CreatedBy.Name,LastModifiedDate
                                            FROM Template__c WITH SECURITY_ENFORCED
                                            ORDER BY LastModifiedDate DESC, Template_Name__c ASC, Object_API_Name__c ASC];

            if (tempList.size() > 0) {
                // Store Object API Name of create Templates...
                Set<String> objectListSet = new Set<String>();  
                for(Template__c temp : tempList){
                    objectListSet.add(temp.Object_API_Name__c);
                }
    
                // Create List Of Object of create Templates with API and Label...
                List<TempObject> objectList = new List<TempObject>();
                for(String objectApi : objectListSet){
                    TempObject tempObj = new TempObject();
                    tempObj.value = objectApi;
                    tempObj.label = (String)Schema.getGlobalDescribe().get(objectApi).getDescribe().getLabel();
                    objectList.add(tempObj);
                }
    
                // Create List of Only Date Field form Templare Object...
                List<TempDateFields> tempDateFields = createTempFieldInstance('Template__c');

                // 
                // returnValue.isGoogleDocEnable = AuthProviderSettings__c.getOrgDefaults().WorkingStatus__c || AuthProviderSettings__c.getInstance().WorkingStatus__c;
                returnValue.isGoogleDocEnable = AuthProviderSettings__c.getInstance().WorkingStatus__c;
                
                // Assign Values to returnValue Object...
                returnValue.isSuccess = true;
                returnValue.objectList = objectList;
                returnValue.dateFields = tempDateFields;
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

    public static List<TempDateFields> createTempFieldInstance(String objectAPINAme){
        List<TempDateFields> tempDateFields = new List<TempDateFields>();
        try {
            Map<String, Schema.SObjectField> mapofAllField = Schema.getGlobalDescribe().get(objectAPINAme).getDescribe().fields.getMap();
                for(String fieldName : mapofAllField.keySet()){
                    Schema.SObjectField field = mapofAllField.get(fieldName);
                    Schema.DescribeFieldResult fd = field.getDescribe();
                    if( (String.valueOf(fd.getType()) == 'DATETIME' || String.valueOf(fd.getType()) == 'DATE') && 
                        (String.valueOf(fd.getName()) != 'LastReferencedDate' &&  String.valueOf(fd.getName()) != 'System Modstamp' && String.valueOf(fd.getName()) != 'SystemModstamp' && String.valueOf(fd.getName()) != 'LastViewedDate')){
                        TempDateFields dateField = new TempDateFields();
                        dateField.label = String.valueOf(fd.getLabel());
                        dateField.value = String.valueOf(fd.getName());
                        tempDateFields.add(dateField);
                    }
                }
            return tempDateFields;
        } catch (Exception e) {
            system.debug('exception in createTempFieldInstance : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return tempDateFields;
        }
    }

    @AuraEnabled
    public static string updateTemplate(String templateId, Boolean isActive){
        // Try and catch block not used... beacuase here is no changes to fall this method in chatch block....
        List<Template__c> tempToUpdate = [SELECT ID, Name, Template_Status__c  FROM Template__c WHERE ID = : templateId WITH SECURITY_ENFORCED LIMIT 1];
        if(tempToUpdate.size() > 0){
            // if (Schema.sObjectType.Template__c.fields.Template_Status__c.isUpdateable()) {
                tempToUpdate[0].Template_Status__c = isActive;
                update tempToUpdate[0];
            // }
            return 'updated';
        }

        return 'no Template Found';
    }

    @AuraEnabled
    public static boolean deleteTemplate(String templateId){
        // Try and catch block not used... beacuase here is no changes to fall this method in chatch block....
        List<Template__c> tempToDelete = [SELECT ID, Name  FROM Template__c WHERE ID =:templateId WITH SECURITY_ENFORCED LIMIT 1];
        if(tempToDelete.size() > 0){
            delete tempToDelete[0];
            return true;
        }
            return false;
    }

    public class ReturnValues{
        @AuraEnabled public list<Template__c> templateList;
        @AuraEnabled public list<TempObject> objectList;
        @AuraEnabled public list<TempDateFields> dateFields;
        @AuraEnabled public boolean isSuccess;
        @AuraEnabled public String returnMessage;
        @AuraEnabled public boolean isGoogleDocEnable;
    }

    public class TempObject{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    public class TempDateFields{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

}