public with sharing class TemplateBuilder_Controller {

    @AuraEnabled
    public static retrunWrapper getTemplateData(String templateId){
        RetrunWrapper retrunWrapper = new RetrunWrapper();
        try {
            List<Template__c> temp = [SELECT Id, Name, Object_API_Name__c, Template_Name__c, Template_Type__c, Template_Status__c, Description__c, CreatedDate, LastModifiedDate, createdBy.Name, lastModifiedBy.Name,
                                        (SELECT Id, Name, Template__c, Template_Value_Simple__c, Order_No_Simple__c, Value_Type__c FROM Template_Data__r WHERE Value_Type__c != null ORDER BY Order_No_Simple__c ASC )
                                        FROM Template__c WHERE Id =: templateId WITH SECURITY_ENFORCED LIMIT 1];

            if(temp.size() > 0){
                if(temp[0].Template_Type__c == 'Simple Template'){

                    retrunWrapper.isSuccess = true;

                    List<Template_Page__c> pageConfigs = [SELECT Id, Name, Template__c, Page_Margin__c, Page_Orientation__c, Page_Size__c, Unit_of_Page_Configs__c, Show_Header__c, Show_Footer__c, Show_Watermark__c, Header_margin_top__c, Footer_margin_bottom__c 
                                                            FROM Template_Page__c 
                                                            WHERE Template__c =: temp[0].Id WITH SECURITY_ENFORCED ORDER BY Page_Number__c ASC  LIMIT 1];

                    if(pageConfigs.size() == 0 && Schema.sObjectType.Template_Page__c.isCreateable()){
                        Template_Page__c page = new Template_Page__c();
                        page.Template__c = temp[0].Id;
                        page.Page_Number__c = 1;
                        page.Page_Margin__c = '1;1;1;1';        // [top;bottom;left;right]
                        page.Page_Orientation__c = 'portrait';
                        page.Page_Size__c = 'a4';
                        page.Unit_of_Page_Configs__c = 'in';
                        page.Show_Header__c = true;
                        page.Header_margin_top__c = 0.10;          // px to inch
                        page.Show_Footer__c = true;
                        page.Footer_margin_bottom__c = 0.10;       // px to inch
                        page.Show_Watermark__c = true;       
                        insert page;
                        pageConfigs = [SELECT Id, Name, Template__c, Page_Margin__c, Page_Orientation__c, Page_Size__c, Unit_of_Page_Configs__c, Show_Header__c, Show_Footer__c, Show_Watermark__c, Header_margin_top__c, Footer_margin_bottom__c 
                                        FROM Template_Page__c WHERE Id =: page.Id WITH SECURITY_ENFORCED ORDER BY Page_Number__c ASC LIMIT 1];
                    }

                    retrunWrapper.template = temp[0];
                    retrunWrapper.pageConfigs = pageConfigs[0];
                }
                else{
                    retrunWrapper.returnMessage = 'Template Type Must Be Simple Template.';
                    retrunWrapper.isSuccess = false;
                }
            }
            else{
                retrunWrapper.returnMessage = 'Template Not Found';
                retrunWrapper.isSuccess = false;
            }

            return retrunWrapper;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'TemplateBuilderController', 'getTemplateData');
            system.debug('exception in getTemplateData : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());

            retrunWrapper.isSuccess = false;
            retrunWrapper.returnMessage = e.getMessage();
            return retrunWrapper;
        }
    }

    @AuraEnabled
    public static Obj_Label_API getObjectNameField(String objectApiName){
        Obj_Label_API objInfo = new Obj_Label_API();
        Schema.SObjectType sobjType = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> mapOfFields = r.fields.getMap();

        objInfo.label = Schema.getGlobalDescribe().get(objectApiName).getDescribe().getLabel();
        
        for(Schema.SObjectField field : mapOfFields.values()){
            if(field.getDescribe().isNameField()){
                objInfo.nameField = field.getDescribe().getName();
                objInfo.nameFieldType = (String) String.valueOf(field.getDescribe().getType());
                return objInfo;
            }
        }

        objInfo.nameField = 'Id';
        return objInfo;
    }

    @AuraEnabled
    public static string saveTemplateApex(Template__c templateRecord, Map<String, List<String>> templateValues, Template_Page__c pageConfigs){
        try {

            List<Template__c> temp = [SELECT Id, Name, Object_API_Name__c, Template_Name__c, Template_Type__c, Template_Status__c, Description__c, CreatedDate, LastModifiedDate,
                                                (SELECT Id, Name, Template__c, Template_Value_Simple__c, Order_No_Simple__c, Value_Type__c FROM Template_Data__r ORDER BY Order_No_Simple__c),
                                                (SELECT Id FROM Template_Pages__r)
                                                FROM Template__c WHERE Id =: templateRecord.Id WITH SECURITY_ENFORCED LIMIT 1];

            System.debug('templateValues : '+ templateValues);

            if(temp.size() > 0 && Schema.sObjectType.Template__c.isUpdateable() && Schema.sObjectType.Template_Page__c.isUpdateable()){
                Template__c templateToUpdate = temp[0];
                templateToUpdate.Template_Name__c = templateRecord.Template_Name__c;
                templateToUpdate.Template_Status__c = templateRecord.Template_Status__c;
                templateToUpdate.Description__c = templateRecord.Description__c;

                if(templateValues != null && templateValues.keySet().size() > 0){
                   // updateTemplateDataRecords(templateToUpdate.Template_Data__r, templateValues, templateToUpdate.Id);

                   for(String valueType : templateValues.keySet()){
                    Map<String ,String> templateValuesMap = new Map<String ,String>();
                    for(Integer i = 1; i <= templateValues.get(valueType).size(); i++){
                        templateValuesMap.put(String.valueOf(i), templateValues.get(valueType)[i-1]);
                    }
                    saveTempDataRecordsInBatch( templateValuesMap , new Map<String, String>{temp[0].Id => valueType}, true);
                }
                }
                
                update templateToUpdate;

                update pageConfigs;

                return 'Temlpate Updated Successfully Success';
            }
            else{
                return 'Template Not Found';
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'TemplateBuilderController', 'saveTemplateApex');
            system.debug('exception in saveTemplateApex : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());

            return 'error';
        }
    }

    @AuraEnabled
    public static String saveTempDataRecordsInBatch(Map<String, string> templateDataList ,Map<String, String> tempIdVsValueType, boolean isLastBatch){
        try {
            List<String> batchOrderNumber = new List<String>(templateDataList.keySet());
            Integer startOrderNumber = batchOrderNumber.size() > 0 ? Integer.valueOf(batchOrderNumber[0]) : 0;
            Integer endOrderNumber = batchOrderNumber.size() > 0 ? Integer.valueOf(batchOrderNumber[batchOrderNumber.size() - 1]) : 0;
            
            String tempId = new List<String>(tempIdVsValueType.keySet())[0];
            String valueType = tempIdVsValueType.get(tempId);
            
            System.debug('isLastBatch : '+ isLastBatch);
            System.debug('startOrderNumber : '+ startOrderNumber);
            System.debug('endOrderNumber : '+ endOrderNumber);

            List<Template_Data__c> storedTempDataRecords = [SELECT Id, Order_No_Simple__c, Template_Value_Simple__c, Value_Type__c
                                                                FROM Template_Data__c
                                                                WHERE Template__c = : tempId
                                                                AND Order_No_Simple__c >= :startOrderNumber
                                                                AND Order_No_Simple__c <= :endOrderNumber
                                                                AND Value_Type__c =: valueType WITH SECURITY_ENFORCED
                                                                ORDER BY Order_No_Simple__c ASC];
            
            Integer batchedStoredRecords =  storedTempDataRecords.size();
                                                                
            List<Template_Data__c> recordToInsert = new List<Template_Data__c>();
            List<Template_Data__c> recordToUpdate = new List<Template_Data__c>();
            List<Template_Data__c> recordToDelete = new List<Template_Data__c>();

            if(batchedStoredRecords > 0 && Schema.sObjectType.Template_Data__c.isCreateable() && Schema.sObjectType.Template_Data__c.isUpdateable()){
                
                for(Integer i = startOrderNumber; i <= endOrderNumber; i++){
                    System.debug('i : '+ i);
                    System.debug('(batchedStoredRecords + startOrderNumber) : '+ (batchedStoredRecords + startOrderNumber - 1));
                    // If recieved data records  is lesser than or equal to total stored record...
                    // Update All Record as per order number....
                    if(i <= (batchedStoredRecords + startOrderNumber - 1)){
                        Template_Data__c dt = storedTempDataRecords[i - startOrderNumber];
                        dt.Template_Value_Simple__c = templateDataList.get(String.valueOf(i));
                        recordToUpdate.add(dt);
                    }
                    // If revied data records  is lesser than stored record...
                    // Update All Record as per order number....
                    else if(i > (batchedStoredRecords + startOrderNumber - 1)){
                        Template_Data__c dt = new Template_Data__c();
                        dt.Template__c = tempId;
                        dt.Template_Value_Simple__c = templateDataList.get(String.valueOf(i));
                        dt.Order_No_Simple__c = (i);
                        dt.Value_Type__c = ValueType;
                        recordToInsert.add(dt);
                    }
                }
                
                update recordToUpdate;
                insert recordToInsert;
            }
            else if(Schema.sObjectType.Template_Data__c.isCreateable()){
                for(integer i = startOrderNumber; i <= endOrderNumber; i++){
                    Template_Data__c dt = new Template_Data__c();
                    dt.Template__c = tempId;
                    dt.Template_Value_Simple__c = templateDataList.get(String.valueOf(i));
                    dt.Order_No_Simple__c = (i);
                    dt.Value_Type__c = ValueType;
                    recordToInsert.add(dt);
                }

                insert recordToInsert;
            }

            Integer totalStoredDataRecords = Database.countQuery('SELECT Count() FROM Template_Data__c WHERE Template__c =: tempId AND Value_Type__c =: valueType');
            System.debug('totalStoredDataRecords : '+ totalStoredDataRecords);

            if(isLastBatch && endOrderNumber < totalStoredDataRecords && Schema.sObjectType.Template_Data__c.isDeletable()){
                // if it is last batch and endOrderNumber is lesser than totalStoredDataRecords...
                // Delete additon template data record....
                delete [SELECT Id, Order_No_Simple__c, Template_Value_Simple__c, Value_Type__c
                            FROM Template_Data__c
                            WHERE Template__c = : tempId
                            AND Order_No_Simple__c >= :endOrderNumber + 1
                            AND Order_No_Simple__c <= :totalStoredDataRecords
                            AND Value_Type__c =: valueType WITH SECURITY_ENFORCED
                            ORDER BY Order_No_Simple__c ASC];
            }

            return isLastBatch ? 'last batch update succesfully' : 'batch update succesfully';
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'TemplateBuilderController', 'saveTempDataRecordsInBatch');
            system.debug('exception in saveTempDataRecordsInBatch : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }

    // @AuraEnabled
    // public static void tempMethod(){
    //     try {
    //         PageReference pageRef = new PageReference('apex/DocPreviewPage');
    //         pageRef.setRedirect(true);
    //         System.debug('pageRef : '  + pageRef);
    //     } catch (Exception e) {
    //         system.debug('exception in updateTemplateDataRecords : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
    //     }
    // }

    public class RetrunWrapper{
        @AuraEnabled public boolean isSuccess;
        @AuraEnabled public String returnMessage;
        @AuraEnabled public Obj_Label_API objectLabelAPI;
        @auraEnabled public Template__c template;
        @auraEnabled public Template_Page__c pageConfigs;
    }

    public class Obj_Label_API{
        @AuraEnabled public String label;
        @AuraEnabled public String name;
        @AuraEnabled public String nameField;
        @AuraEnabled public String nameFieldType;

    }
}