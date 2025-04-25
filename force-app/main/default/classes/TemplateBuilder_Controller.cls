public with sharing class TemplateBuilder_Controller {

    public static List<MVDG__Template_Data__c> recordToInsert_global = new List<MVDG__Template_Data__c>();
    public static List<MVDG__Template_Data__c> recordToUpdate_global = new List<MVDG__Template_Data__c>();
    public static List<MVDG__Template_Data__c> recordToDelete_global = new List<MVDG__Template_Data__c>();

    /**
     * @param {String} templateId, Id of template going to edit.
     * @return retrunWrapper,
     * @description : Method to get template record, template data, template pages, field mappings and the latest object API name from template data.
     */
    @AuraEnabled
    public static retrunWrapper getTemplateData(String templateId){
        RetrunWrapper retrunWrapper = new RetrunWrapper();
        try {
            List<MVDG__Template__c> temp = [SELECT Id, Name, MVDG__Object_API_Name__c, MVDG__Template_Name__c, MVDG__Template_Type__c, MVDG__Template_Status__c, MVDG__Description__c, CreatedDate, LastModifiedDate, createdBy.Name, lastModifiedBy.Name,
                                        (SELECT Id, Name, MVDG__Template__c, MVDG__Template_Value_Simple__c, MVDG__Order_No_Simple__c, MVDG__Value_Type__c FROM MVDG__Template_Data__r WHERE MVDG__Value_Type__c != null ORDER BY MVDG__Order_No_Simple__c ASC )
                                        FROM MVDG__Template__c WHERE Id =: templateId WITH SECURITY_ENFORCED LIMIT 1];

            if(temp.size() > 0){
                if(temp[0].MVDG__Template_Type__c == 'Simple Template'){

                    retrunWrapper.isSuccess = true;

                    List<MVDG__Template_Page__c> pageConfigs = [SELECT Id, Name, MVDG__Template__c, MVDG__Page_Margin__c, MVDG__Page_Orientation__c, MVDG__Page_Size__c, MVDG__Unit_of_Page_Configs__c, MVDG__Show_Header__c, MVDG__Show_Footer__c, MVDG__Show_Watermark__c, MVDG__Header_margin_top__c, MVDG__Footer_margin_bottom__c 
                                                            FROM MVDG__Template_Page__c 
                                                            WHERE MVDG__Template__c =: temp[0].Id WITH SECURITY_ENFORCED ORDER BY MVDG__Page_Number__c ASC  LIMIT 1];

                    if(pageConfigs.size() == 0 && Schema.sObjectType.MVDG__Template_Page__c.isCreateable()){
                        MVDG__Template_Page__c page = new MVDG__Template_Page__c();
                        page.MVDG__Template__c = temp[0].Id;
                        page.MVDG__Page_Number__c = 1;
                        page.MVDG__Page_Margin__c = '1;1;1;1';        // [top;bottom;left;right]
                        page.MVDG__Page_Orientation__c = 'portrait';
                        page.MVDG__Page_Size__c = 'a4';
                        page.MVDG__Unit_of_Page_Configs__c = 'in';
                        page.MVDG__Show_Header__c = true;
                        page.MVDG__Header_margin_top__c = 0.10;          // px to inch
                        page.MVDG__Show_Footer__c = true;
                        page.MVDG__Footer_margin_bottom__c = 0.10;       // px to inch
                        page.MVDG__Show_Watermark__c = true;       
                        insert as user page;
                        pageConfigs = [SELECT Id, Name, MVDG__Template__c, MVDG__Page_Margin__c, MVDG__Page_Orientation__c, MVDG__Page_Size__c, MVDG__Unit_of_Page_Configs__c, MVDG__Show_Header__c, MVDG__Show_Footer__c, MVDG__Show_Watermark__c, MVDG__Header_margin_top__c, MVDG__Footer_margin_bottom__c 
                                        FROM MVDG__Template_Page__c WHERE Id =: page.Id WITH SECURITY_ENFORCED ORDER BY MVDG__Page_Number__c ASC LIMIT 1];
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
            // System.debug('exception in getTemplateData : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());

            retrunWrapper.isSuccess = false;
            retrunWrapper.returnMessage = e.getMessage();
            return retrunWrapper;
        }
    }

    /**
     * @param {String} objectApiName - API Name of the object to get fields for.
     * @return Obj_Label_API,
     * @description : Method to get Object Label, Object Name field and its type from Its Object API Name
     */
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

    /**
     * @param {MVDG__Template__c} templateRecord, template record with basic field values,
     * @param {Map<String, List<String>>}, templateValues, Tempalce data with value as per value type,
     * @param {MVDG__Template_Page__c}, pageConfigs, page config recor dwith field values,
     * @return {String} , update status
     * @description : Method to Save the Template data, page configs and field mappings.
     *               1. Update the Template record.
     *               2. Update the Page Configs record.
     *               3. Update the Template data with header, footer, mapping key data and body(if batch save is not rerequired).
     */
    @AuraEnabled
    public static string saveTemplateApex(MVDG__Template__c templateRecord, Map<String, List<String>> templateValues, MVDG__Template_Page__c pageConfigs){
        try {

            List<MVDG__Template__c> temp = [SELECT Id, Name, MVDG__Object_API_Name__c, MVDG__Template_Name__c, MVDG__Template_Type__c, MVDG__Template_Status__c, MVDG__Description__c, CreatedDate, LastModifiedDate,
                                                (SELECT Id, Name, MVDG__Template__c, MVDG__Template_Value_Simple__c, MVDG__Order_No_Simple__c, MVDG__Value_Type__c FROM MVDG__Template_Data__r ORDER BY MVDG__Order_No_Simple__c),
                                                (SELECT Id FROM MVDG__Template_Pages__r)
                                                FROM MVDG__Template__c WHERE Id =: templateRecord.Id WITH SECURITY_ENFORCED LIMIT 1];

            // System.debug('templateValues : '+ templateValues);

            if(temp.size() > 0 && Schema.sObjectType.MVDG__Template__c.isUpdateable() && Schema.sObjectType.MVDG__Template_Page__c.isUpdateable()){
                MVDG__Template__c templateToUpdate = temp[0];
                templateToUpdate.MVDG__Template_Name__c = templateRecord.MVDG__Template_Name__c;
                templateToUpdate.MVDG__Template_Status__c = templateRecord.MVDG__Template_Status__c;
                templateToUpdate.MVDG__Description__c = templateRecord.MVDG__Description__c;



                if(templateValues != null && templateValues.keySet().size() > 0){
                    for(String valueType : templateValues.keySet()){
                        Map<String ,String> templateValuesMap = new Map<String ,String>();
                        if(templateValues?.get(valueType)?.size() > 0){
                            for(Integer i = 1; i <= templateValues.get(valueType).size(); i++){
                                templateValuesMap.put(String.valueOf(i), templateValues.get(valueType)[i-1]);
                            }
                        }
                        else{
                            templateValuesMap.put('1', '');
                        }
                        saveTempDataRecords_forValueTypes( templateValuesMap , new Map<String, String>{temp[0].Id => valueType}, true);
                    }

                    // Map<String ,String> bodyValuesMap = new Map<String ,String>();
                    //     if(templateValues?.get('Body Value')?.size() > 0){
                    //         for(Integer i = 1; i <= templateValues.get('Body Value').size(); i++){
                    //             bodyValuesMap.put(String.valueOf(i), templateValues.get('Body Value')[i-1]);
                    //         }
                    //     }
                    //     else{
                    //         bodyValuesMap.put('1', '');
                    //     }
                    // saveTempDataRecords_forValueTypes( bodyValuesMap , new Map<String, String>{temp[0].Id => 'Body Value'}, true);

                    // Map<String ,String> headerValuesMap = new Map<String ,String>();
                    //     if(templateValues?.get('Header Value')?.size() > 0){
                    //         for(Integer i = 1; i <= templateValues.get('Header Value').size(); i++){
                    //             headerValuesMap.put(String.valueOf(i), templateValues.get('Header Value')[i-1]);
                    //         }
                    //     }
                    //     else{
                    //         headerValuesMap.put('1', '');
                    //     }
                    // saveTempDataRecords_forValueTypes( headerValuesMap , new Map<String, String>{temp[0].Id => 'Header Value'}, true);

                    // Map<String ,String> footerValuesMap = new Map<String ,String>();
                    //     if(templateValues?.get('Footer Value')?.size() > 0){
                    //         for(Integer i = 1; i <= templateValues.get('Footer Value').size(); i++){
                    //             footerValuesMap.put(String.valueOf(i), templateValues.get('Footer Value')[i-1]);
                    //         }
                    //     }
                    //     else{
                    //         footerValuesMap.put('1', '');
                    //     }
                    // saveTempDataRecords_forValueTypes( footerValuesMap , new Map<String, String>{temp[0].Id => 'Footer Value'}, true);

                    // Map<String ,String> watermarkValuesMap = new Map<String ,String>();
                    //     if(templateValues?.get('Watermark Value')?.size() > 0){
                    //         for(Integer i = 1; i <= templateValues.get('Watermark Value').size(); i++){
                    //             watermarkValuesMap.put(String.valueOf(i), templateValues.get('Watermark Value')[i-1]);
                    //         }
                    //     }
                    //     else{
                    //         watermarkValuesMap.put('1', '');
                    //     }
                    // saveTempDataRecords_forValueTypes( watermarkValuesMap , new Map<String, String>{temp[0].Id => 'Watermark Value'}, true);
                    
                    // Map<String ,String> extractedKeyMap = new Map<String ,String>();
                    //     if(templateValues?.get('Extracted Mapping Keys')?.size() > 0){
                    //         for(Integer i = 1; i <= templateValues.get('Extracted Mapping Keys').size(); i++){
                    //             extractedKeyMap.put(String.valueOf(i), templateValues.get('Extracted Mapping Keys')[i-1]);
                    //         }
                    //     }
                    //     else{
                    //         extractedKeyMap.put('1', '');
                    //     }
                    // saveTempDataRecords_forValueTypes( extractedKeyMap , new Map<String, String>{temp[0].Id => 'Extracted Mapping Keys'}, true);

                    if(recordToUpdate_global.size() < 10000) {
                        update as user recordToUpdate_global;
                    }
                    if(recordToInsert_global.size() < 10000) {
                        insert as user recordToInsert_global;
                    }
                    if(recordToDelete_global.size() < 10000) {
                        delete as user recordToDelete_global;
                    }
                    
                }
                
                update as user templateToUpdate;

                update as user pageConfigs;

                return 'Temlpate Updated Successfully Success';
            }
            else{
                return 'Template Not Found';
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'TemplateBuilderController', 'saveTemplateApex');
            // System.debug('exception in saveTemplateApex : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());

            return null;
        }
    }

    /**
     * @param {Map<String, string>}, templateDataList, Map of batchOrderNumver vs template Data
     * @param {Map<String, String>}, tempIdVsValueType, Map of tempate Id vs template Value,
     * @param {boolean}, isLastBatch, to indentify last batch,
     * @description : Method Save body content data into template data object for multiple value type (i.e., Body, header, footer, mappingKeys).
     * Here, We are using global list to update template Data record to avoid DML in loop....
     */
    @AuraEnabled
    public static String saveTempDataRecords_forValueTypes(Map<String, string> templateDataList ,Map<String, String> tempIdVsValueType, boolean isLastBatch){
        try {
            
            Map<String, List<MVDG__Template_Data__c>> dataToUpdate = setupTemplateDataForUpdate(templateDataList, tempIdVsValueType, isLastBatch);

            List<MVDG__Template_Data__c> recordToInsert = dataToUpdate?.get('recordToInsert');
            List<MVDG__Template_Data__c> recordToUpdate = dataToUpdate?.get('recordToUpdate');
            List<MVDG__Template_Data__c> recordToDelete = dataToUpdate?.get('recordToDelete');

            if(recordToInsert != null && recordToInsert.size() > 0) recordToInsert_global.addAll(recordToInsert);
            if(recordToUpdate != null && recordToUpdate.size() > 0) recordToUpdate_global.addAll(recordToUpdate);
            if(recordToDelete != null && recordToDelete.size() > 0) recordToDelete_global.addAll(recordToDelete);

            return isLastBatch ? 'last batch update succesfully' : 'batch update succesfully';
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'TemplateBuilderController', 'saveTempDataRecordsInBatch');
            // System.debug('exception in saveTempDataRecordsInBatch : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }

    /**
     * @param {Map<String, string>}, templateDataList, Map of batchOrderNumver vs template Data
     * @param {Map<String, String>}, tempIdVsValueType, Map of tempate Id vs template Value,
     * @param {boolean}, isLastBatch, to indentify last batch,
     * @description : Method Save body content data into template data object in multiple batch to handle large size.
     */
    @AuraEnabled
    public static String saveTempDataRecordsInBatch(Map<String, string> templateDataList ,Map<String, String> tempIdVsValueType, boolean isLastBatch){
        try {

            Map<String, List<MVDG__Template_Data__c>> dataToUpdate = setupTemplateDataForUpdate(templateDataList, tempIdVsValueType, isLastBatch);

            List<MVDG__Template_Data__c> recordToInsert = dataToUpdate?.get('recordToInsert');
            List<MVDG__Template_Data__c> recordToUpdate = dataToUpdate?.get('recordToUpdate');
            List<MVDG__Template_Data__c> recordToDelete = dataToUpdate?.get('recordToDelete');

            if(recordToUpdate.size() < 1000) {
                update as user recordToUpdate;
            }
            if(recordToInsert.size() < 1000) {
                insert as user recordToInsert;
            }
            if(recordToDelete.size() < 1000) {
                delete as user recordToDelete;
            }

            return isLastBatch ? 'last batch update succesfully' : 'batch update succesfully';
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'TemplateBuilderController', 'saveTempDataRecordsInBatch');
            // System.debug('exception in saveTempDataRecordsInBatch : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }

    /**
     * @param {Map<String, string>}, templateDataList, Map of batchOrderNumver vs template Data
     * @param {Map<String, String>}, tempIdVsValueType, Map of tempate Id vs template Value,
     * @param {boolean}, isLastBatch, to indentify last batch,
     * @description : Method Setup List of Tempalte Data from Insert, Update and Delete as per contnet going to save...
     */
    public static Map<String, List<MVDG__Template_Data__c>> setupTemplateDataForUpdate(Map<String, string> templateDataList ,Map<String, String> tempIdVsValueType, boolean isLastBatch){
        try {
            List<String> batchOrderNumber = new List<String>(templateDataList.keySet());
            Integer startOrderNumber = batchOrderNumber.size() > 0 ? Integer.valueOf(batchOrderNumber[0]) : 0;
            Integer endOrderNumber = batchOrderNumber.size() > 0 ? Integer.valueOf(batchOrderNumber[batchOrderNumber.size() - 1]) : 0;
            
            String tempId = new List<String>(tempIdVsValueType.keySet())[0];
            String valueType = tempIdVsValueType.get(tempId);
            
            // System.debug('isLastBatch : '+ isLastBatch);
            // System.debug('startOrderNumber : '+ startOrderNumber);
            // System.debug('endOrderNumber : '+ endOrderNumber);

            List<MVDG__Template_Data__c> storedTempDataRecords = [SELECT Id, MVDG__Order_No_Simple__c, MVDG__Template_Value_Simple__c, MVDG__Value_Type__c
                                                                FROM MVDG__Template_Data__c
                                                                WHERE MVDG__Template__c = : tempId
                                                                AND MVDG__Order_No_Simple__c >= :startOrderNumber
                                                                AND MVDG__Order_No_Simple__c <= :endOrderNumber
                                                                AND MVDG__Value_Type__c =: valueType WITH SECURITY_ENFORCED
                                                                ORDER BY MVDG__Order_No_Simple__c ASC];
            
            Integer batchedStoredRecords =  storedTempDataRecords.size();
                                                                
            List<MVDG__Template_Data__c> recordToInsert = new List<MVDG__Template_Data__c>();
            List<MVDG__Template_Data__c> recordToUpdate = new List<MVDG__Template_Data__c>();
            List<MVDG__Template_Data__c> recordToDelete = new List<MVDG__Template_Data__c>();

            if(batchedStoredRecords > 0 && Schema.sObjectType.MVDG__Template_Data__c.isCreateable() && Schema.sObjectType.MVDG__Template_Data__c.isUpdateable()){
                
                for(Integer i = startOrderNumber; i <= endOrderNumber; i++){
                    // System.debug('i : '+ i);
                    // System.debug('(batchedStoredRecords + startOrderNumber) : '+ (batchedStoredRecords + startOrderNumber - 1));
                    // If recieved data records  is lesser than or equal to total stored record...
                    // Update All Record as per order number....
                    if(i <= (batchedStoredRecords + startOrderNumber - 1)){
                        MVDG__Template_Data__c dt = storedTempDataRecords[i - startOrderNumber];
                        dt.MVDG__Template_Value_Simple__c = templateDataList.get(String.valueOf(i));
                        recordToUpdate.add(dt);
                    }
                    // If revied data records  is lesser than stored record...
                    // Update All Record as per order number....
                    else if(i > (batchedStoredRecords + startOrderNumber - 1)){
                        MVDG__Template_Data__c dt = new MVDG__Template_Data__c();
                        dt.MVDG__Template__c = tempId;
                        dt.MVDG__Template_Value_Simple__c = templateDataList.get(String.valueOf(i));
                        dt.MVDG__Order_No_Simple__c = (i);
                        dt.MVDG__Value_Type__c = ValueType;
                        recordToInsert.add(dt);
                    }
                }
            }
            else if(Schema.sObjectType.MVDG__Template_Data__c.isCreateable()){
                for(integer i = startOrderNumber; i <= endOrderNumber; i++){
                    MVDG__Template_Data__c dt = new MVDG__Template_Data__c();
                    dt.MVDG__Template__c = tempId;
                    dt.MVDG__Template_Value_Simple__c = templateDataList.get(String.valueOf(i));
                    dt.MVDG__Order_No_Simple__c = (i);
                    dt.MVDG__Value_Type__c = ValueType;
                    recordToInsert.add(dt);
                }
            }

            Integer totalStoredDataRecords = Database.countQuery('SELECT Count() FROM MVDG__Template_Data__c WHERE MVDG__Template__c =: tempId AND MVDG__Value_Type__c =: valueType');
            // System.debug('totalStoredDataRecords : '+ totalStoredDataRecords);

            if(isLastBatch && endOrderNumber < totalStoredDataRecords && Schema.sObjectType.MVDG__Template_Data__c.isDeletable()){
                // if it is last batch and endOrderNumber is lesser than totalStoredDataRecords...
                // Delete additon template data record....
                List<MVDG__Template_Data__c> templateDataToDelete = [SELECT Id, MVDG__Order_No_Simple__c, MVDG__Template_Value_Simple__c, MVDG__Value_Type__c
                                                                        FROM MVDG__Template_Data__c
                                                                        WHERE MVDG__Template__c = : tempId
                                                                        AND MVDG__Order_No_Simple__c >= :endOrderNumber + 1
                                                                        AND MVDG__Order_No_Simple__c <= :totalStoredDataRecords
                                                                        AND MVDG__Value_Type__c =: valueType WITH SECURITY_ENFORCED
                                                                        ORDER BY MVDG__Order_No_Simple__c ASC LIMIT 50000];
                
                recordToDelete.addAll(templateDataToDelete);
            }
            

            return new Map<String, List<MVDG__Template_Data__c>>{
                'recordToInsert' => recordToInsert,
                'recordToUpdate' => recordToUpdate,
                'recordToDelete' => recordToDelete
            };
        } catch(Exception e) {
            Log_Handler.store_Exception(e, 'TemplateBuilderController', 'setupTemplateDataForUpdate');
            // System.debug('exception in saveTempDataRecordsInBatch : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }

    /**
     * @description : Wrapper class used to return values to lwc component.
     * It is generic class that used by mupltiple methods.
     */
    public class RetrunWrapper{
        @AuraEnabled public boolean isSuccess;
        @AuraEnabled public String returnMessage;
        @AuraEnabled public Obj_Label_API objectLabelAPI;
        @auraEnabled public MVDG__Template__c template;
        @auraEnabled public MVDG__Template_Page__c pageConfigs;
    }

    /**
     * @description : Wrapper class used to Store sorce object information.
     */
    public class Obj_Label_API{
        @AuraEnabled public String label;
        @AuraEnabled public String name;
        @AuraEnabled public String nameField;
        @AuraEnabled public String nameFieldType;

    }
}