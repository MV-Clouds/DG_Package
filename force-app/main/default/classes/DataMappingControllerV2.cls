public with sharing class DataMappingControllerV2 {

    public static map<String, Map<String, String>> getMappingsKeyValues(List<String> templateIDs, String recordId, Boolean includeMergTemKeys){
        Map<String, Map<String, String>> mapingKeyVsValuesGroup = new Map<String, Map<String, String>>{
            'objectNGeneral' => new map<string, string>(),
            'childRecordTable' => new map<string, string>(),
            'margeTemplate' => new map<string, string>(),
            'salesforceImages' => new map<string, string>()
        };
        try {
            List<Template__c> temps = [SELECT Id, Name, Object_API_Name__c, Template_Name__c, Template_Type__c, Template_Status__c, Description__c, CreatedDate, LastModifiedDate,
                                      (SELECT Id, Name, Template_Value_Simple__c FROM Template_Data__r WHERE Value_Type__c = 'Extracted Mapping Keys' ORDER BY Order_No_Simple__c ASC)
                                       FROM Template__c  WHERE Id In :templateIDs WITH SECURITY_ENFORCED];

            for(Template__c temp : temps){
                String extractedKeyString = '';

                // get extracted Keys stored in field...
                for(Template_Data__c fieldData : temp.Template_Data__r){
                    extractedKeyString +=  fieldData.Template_Value_Simple__c;
                }

                extractedKeyString = extractedKeyString != '' ? extractedKeyString : 'null';

                String sourceObjectAPI = temp.Object_API_Name__c;

                // Type cast extracted key field value to key mappign keys, child object info and merge tempalte keys....
                Map<String, Object> extractedKeyMap = (Map<String, Object>) JSON.deserializeUntyped(extractedKeyString);
    
                // Collect and Store mapping keys in to set of string from keys stored in field...
                Set<String> extractedKeys = collectMappingKeys(extractedKeyMap);
                // collect mapping key values for object field and general fields....
                Map<String, String> mappigKeysValue = getMappingKeyVsValue(new List<String>(extractedKeys), sourceObjectAPI, recordId);
                mapingKeyVsValuesGroup.get('objectNGeneral').putAll(mappigKeysValue);
                
    
                // collect mapping key values for child object table info from keys stored in field....
                Object childRecordTables = extractedKeyMap?.get('childRecordTables') != null ? extractedKeyMap.get('childRecordTables') : (Object) JSON.deserializeUntyped('[]');
                String childTableString = JSON.serialize(childRecordTables);
                Set<ChildTableInfo> childTables = (Set<ChildTableInfo>) JSON.deserializeStrict(childTableString, Set<ChildTableInfo>.Class);
    
                // modify child object table...
                for(ChildTableInfo tableInfo : childTables){
                    Map<String, String> modifiedChildTable = modifyChildObjectTables(tableInfo, sourceObjectAPI, recordId);
                    mapingKeyVsValuesGroup.get('childRecordTable').putAll(modifiedChildTable);
                }

                // Collect and Store Salesforce image SRC in to set ...
                Map<String, String> sfImagesSRCVsID = getSFimageVsId(extractedKeyMap);
                mapingKeyVsValuesGroup.get('salesforceImages').putAll(sfImagesSRCVsID);
                
                // this varibale will be FALSE when it call from "getKeyNValueFromMergeTemps" Method...
                if(includeMergTemKeys == true){
                    System.debug(' ---- ---- ---- Merge Template keys Starts ---- ---- '+ temp.Id);
                    // collect merge template key from keys stored in field ...
                    set<String> mergTemplateKeys = collectMergeTemplateKeys(extractedKeyMap);

                    // create map for merge template key with Values....
                    map<String, Map<String, String>> keyWithValues = getKeyNValueFromMergeTemps(new List<String>(mergTemplateKeys), sourceObjectAPI, recordId);

                    mapingKeyVsValuesGroup.get('objectNGeneral').putAll(keyWithValues.get('objectNGeneral'));
                    mapingKeyVsValuesGroup.get('childRecordTable').putAll(keyWithValues.get('childRecordTable'));
                    mapingKeyVsValuesGroup.get('salesforceImages').putAll(keyWithValues.get('salesforceImages'));
                    mapingKeyVsValuesGroup.get('margeTemplate').putAll(keyWithValues.get('margeTemplate'));

                }
            }
                                        
            return mapingKeyVsValuesGroup;
        } catch (Exception e) {
            // Log_Handler.store_Exception(e, 'DataMappingControllerV2', 'getMappingsKeyValues');
            system.debug('exception in getMappingsKeyValues : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return mapingKeyVsValuesGroup;
        }
    }
    public static Set<String> collectMappingKeys(Map<String, Object> extractedKeyMap){
        Set<String> extractedKeys = new Set<String>();
        try {
            
            Object objectFields = extractedKeyMap?.get('objectFields') != null ? extractedKeyMap.get('objectFields') : (Object) JSON.deserializeUntyped('[]');
            String objectFieldString = JSON.serialize(objectFields);
            List<Object> objectFieldKeys = (List<Object>) JSON.deserializeUntyped(objectFieldString);
    
            Object generalFields = (extractedKeyMap != null && extractedKeyMap?.get('generalFields') != null) ? extractedKeyMap.get('generalFields') : (Object) JSON.deserializeUntyped('[]');
            String generalFieldString = JSON.serialize(generalFields);
            List<Object> generalFieldKeys = (List<Object>) JSON.deserializeUntyped(generalFieldString);

            for(Object key : objectFieldKeys){
                extractedKeys.add((String) key);
            }
            for(Object key : generalFieldKeys){
                extractedKeys.add((String) key);
            }

            return extractedKeys;
        } catch (Exception e) {
            system.debug('exception in collectMappingKeys : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return extractedKeys;
        }
    }
    public static Set<String> collectMergeTemplateKeys(Map<String, Object> extractedKeyMap){
        set<String> mergTemplateKeys = new set<String>();
        try {
            
            Object mergeTempKeys = extractedKeyMap?.get('mergeTempKeys') != null ? extractedKeyMap.get('mergeTempKeys') : (Object) JSON.deserializeUntyped('[]');
            String mergerTempString = JSON.serialize(mergeTempKeys);
            List<Object> mergerTempKeys = (List<Object>) JSON.deserializeUntyped(mergerTempString);

            for(Object key : mergerTempKeys){
                mergTemplateKeys.add((String) key);
            }

            return mergTemplateKeys;
        } catch (Exception e) {
            system.debug('exception in collectMergeTemplateKeys : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return mergTemplateKeys;
        }
    }

    // === === Methods to Create and Add child object's record's row in table ==== ==== ====
    public static map<String, String> modifyChildObjectTables(ChildTableInfo tableInfo, String sourceObjectAPI, String recordId){
        // ==>> Extract all table information from info Row... <<==
        try {
            String modifiedTableHTML = tableInfo.tableHTML; 
            String infoRow = tableInfo.infoRow;
            String modifiedKeyRow = null;
            if(infoRow != null && infoRow != ''){
                tableInfo.sourceObjectAPI = sourceObjectAPI;
                tableInfo.childRelationshipName = infoRow.substringBetween('$childRelation:', '$');
                tableInfo.childObjetAPI = infoRow.substringBetween('$objApi:', '$');
                tableInfo.queryFilters = infoRow.substringBetween('$filter:', '$');
                tableInfo.queryLimit = infoRow.substringBetween('$limit:', '$');
                // If user enter Invalid (Non numberic) limit string... handle it...
                tableInfo.queryLimit = tableInfo.queryLimit.isNumeric() == true ? tableInfo.queryLimit : '50';

                // ==> validate each field... and add into field's list to create query....
                List<ExtractedKeys> extractedKeys = getValidKeys(tableInfo.mappingFields, tableInfo.childObjetAPI, '!');
                Set<String> validChildObjFields = new Set<String>();
                for(ExtractedKeys ext : extractedKeys){
                    validChildObjFields.add(ext.fieldAPI);
                }

                List<map<string, Object>> childRecords = getChildRecordsAsMap(validChildObjFields, tableInfo, recordId);
                System.debug('---- ------ child record.size() ----- ------ : ' + childRecords.size());
                modifiedKeyRow = createRowsWithChildRecords(childRecords, ExtractedKeys, tableInfo);
            }

            if(modifiedKeyRow != null){
                modifiedTableHTML = modifiedTableHTML.replace(tableInfo.keyRow, modifiedKeyRow);
                modifiedTableHTML = modifiedTableHTML.replace(infoRow, '');
            }

            return new Map<String, String>{tableInfo.tableHTML => modifiedTableHTML};
            
        } catch (Exception e) {
            system.debug('exception in modifyChildObjectTables : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return new Map<String, String>{tableInfo.tableHTML => tableInfo.tableHTML};
        }
    }
    public static List<map<string, Object>> getChildRecordsAsMap(Set<String> fieldList, ChildTableInfo tableInfo, string recordId){
        List<map<string, Object>> childRecordList = new List<map<string, Object>>();
        try {
            if(fieldList.size() > 0){
                
                fieldList.add('Id');
    
                String queryFields = '';
                queryFields = String.join(fieldList, ',');
    
                // ==> Generate Query for child Records....
                String childQuery = '';
                childQuery += '(SELECT '+queryFields+' FROM '+ tableInfo.childRelationshipName;
                if(tableInfo.queryFilters != null && tableInfo.queryFilters != ''){
                    childQuery += ' WHERE '+tableInfo.queryFilters;
                }
                if(tableInfo.queryLimit != null && tableInfo.queryLimit != ''){
                    childQuery += ' LIMIT '+tableInfo.queryLimit;
                }
                childQuery += ')';
    
                String mainRecordQuery = 'SELECT Id, '+childQuery+' FROM '+ tableInfo.sourceObjectAPI +' WHERE Id =: recordId LIMIT 1';

                sObject sourceObject = querySObject(mainRecordQuery, recordId, tableInfo.sourceObjectAPI);
                Object cr = sourceObject.getPopulatedFieldsAsMap().get(tableInfo.childRelationshipName);
                
                // ==> Type Casting : Object to List of Object..(for multiple child records)
                String crString = JSON.serialize(cr);
                List<Object> childRecords = new List<Object>();
                if((List<Object>) JSON.deserializeUntyped(crString) != null){
                    childRecords = (List<Object>) JSON.deserializeUntyped(crString);
                }

                for(Object co : childRecords){
                    String cString = JSON.serialize(co);
                    childRecordList.add((map<string, Object>) JSON.deserializeUntyped(cString));
                }

                return childRecordList;
            }
            return childRecordList;
        } catch (Exception e) {
            system.debug('exception in getChildRecordsAsMap : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return childRecordList;
        }
    }
    public static string createRowsWithChildRecords(List<map<string, Object>> childRecords, List<ExtractedKeys> extractedKeys, ChildTableInfo tableInfo){
        try {
            
            List<String> childRecordRows = new List<String>();

            for(Integer i = 0; i < childRecords.size(); i++){
                String keyRowWithRecord = tableInfo.keyRow;

                for(ExtractedKeys ext : extractedKeys){
                    String fieldValue = '';

                    if(ext.fieldAPI.contains('.')){
                        string replationshipName = ext.fieldAPI.substringBefore('.');
                        string fieldName = ext.fieldAPI.substringAfter('.');
                        fieldValue = getFieldValue(ext, childRecords[i]);

                    }else{
                        fieldValue = getFieldValue(ext, childRecords[i]);
                    }

                    fieldValue = fieldValue != null ? fieldValue : '';
                    keyRowWithRecord = keyRowWithRecord.replace(ext.mappingKey, fieldValue);
                }

                if(keyRowWithRecord.contains(KeyMappingController.tableIndexKey)){              
                    // KeyMappingController.tableIndexKey = {{No.Index}};
                    keyRowWithRecord = keyRowWithRecord.replace(KeyMappingController.tableIndexKey, String.valueOf(i+1));
                }

                childRecordRows.add(keyRowWithRecord);
            }
            
            return String.join(childRecordRows, '');
        } catch (Exception e) {
            system.debug('exception in createRowsWithChildRecords : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }

    // === === Methods to collect all SRC with content version id ==== ==== ====
    public static Map<String, String> getSFimageVsId(Map<String, Object> extractedKeyMap){
        Map<String, String> sfImages = new  Map<String,String>();
        try {
            
            Object sfImageSRCs = extractedKeyMap?.get('salesforceImages') != null ? extractedKeyMap.get('salesforceImages') : (Object) JSON.deserializeUntyped('[]');
            String sfImagesSRCString = JSON.serialize(sfImageSRCs);
            List<Object> sfImgKeys = (List<Object>) JSON.deserializeUntyped(sfImagesSRCString);

            for(Object key : sfImgKeys){
                String src = (String) key;
                sfImages.put(src, src.substringBetween('&ids=', '&d='));
            }

            return sfImages;
        } catch (Exception e) {
            system.debug('exception in getSFimageVsId : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return sfImages;
        }
    }

    // === === Method to Replace value with object field's, parent object field's and General field's mapping key ==== ====
    public static Map<String, String> getMappingKeyVsValue(List<String> mappingKeyList,String sourceObjectAPI, String recordId){
        Map<String, String> extractedKeyWithData = new Map<String, String>();
        try {

            List<ExtractedKeys> extractedKeys = new List<ExtractedKeys>();

            extractedKeys.addAll(getValidKeys(mappingKeyList, sourceObjectAPI, '#'));
            extractedKeys.addAll(getValidKeys(mappingKeyList, sourceObjectAPI, 'Doc.'));

            FieldListClass fieldLists = new FieldListClass();

            for(ExtractedKeys ext : extractedKeys){
                if(ext.fieldAPI.contains('.')){
                    string replationshipName = ext.fieldAPI.substringBefore('.');
                    string fieldName = ext.fieldAPI.substringAfter('.');
                    switch on replationshipName{
                        when 'Date'{
                            fieldLists.dateFields.add(fieldName);
                        }
                        when 'User'{
                            fieldLists.userFields.add(fieldName);
                        }
                        when 'Org'{
                            fieldLists.orgFields.add(fieldName);
                        }
                        when else{
                            fieldLists.objectFields.add(ext.fieldAPI);
                        }
                    }
                }else{
                    fieldLists.objectFields.add(ext.fieldAPI);
                }
            }

            return mapKeysWithValue(fieldLists, extractedKeys, new list<String>{recordId, sourceObjectAPI});
        } catch (Exception e) {
            system.debug('exception in getMappingKeyVsValue : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return extractedKeyWithData;
        }
    }
    public static map<String, String> mapKeysWithValue(FieldListClass fieldLists, List<ExtractedKeys> extractedKeys, list<String> recordIdNobjAPI){
        Map<String, String> extractedKeyWithData = new Map<String, String>();
        try {

            String recordId = recordIdNobjAPI[0];
            String objAPI = recordIdNobjAPI[1];

            Map<String, String> dt = KeyMappingController.dateFormats();
            Map<string, string> dateVal = new Map<string, string>();
            for(string d : dt.keySet()){
                dateVal.put(d, dt.get(d).split(';')[3]);
            }
            String dateValueString = JSON.serialize(dateVal);
            Map<String, Object> dateValus = (Map<String, Object>) JSON.deserializeUntyped(dateValueString);
            
            // Converting sObject into map<String, Object> will make easy to get parent object data from it....

            String userId = UserInfo.getUserId();
            map<String, Object> userObject = getSobjectAsMap(fieldLists.userFields, 'User', userId);
            
            String orgId = UserInfo.getOrganizationId();
            map<String, Object> orgObject = getSobjectAsMap(fieldLists.orgFields, 'Organization', orgId);
            
            map<String, Object> sourceObject = getSobjectAsMap(fieldLists.objectFields, objAPI, recordId);

            for(ExtractedKeys ext : extractedKeys){
                String fieldValue = '';
                if(ext.fieldAPI.contains('.')){
                    string replationshipName = ext.fieldAPI.substringBefore('.');
                    string fieldName = ext.fieldAPI.substringAfter('.');
                    switch on replationshipName{
                        when 'Date'{
                            fieldValue = getFieldValue(ext, dateValus);
                        }
                        when 'User'{
                            fieldValue = getFieldValue(ext, userObject);
                        }
                        when 'Org'{
                            fieldValue = getFieldValue(ext, orgObject);
                        }
                        when else{
                            fieldValue = getFieldValue(ext, sourceObject);
                        }
                    }
                }else{
                    fieldValue = getFieldValue(ext, sourceObject);
                }

                fieldValue = fieldValue != null ? fieldValue : '';
                extractedKeyWithData.put(ext.mappingKey, fieldValue);
            }

            return extractedKeyWithData;
        } catch (Exception e) {
            system.debug('exception in mapKeysWithValue : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return extractedKeyWithData;
        }
    }
    public static map<String, Object> getSobjectAsMap(List<String> fieldList, String objectAPI, string recordId){
        map<String, Object> sobjectAsMap = new map<String, Object>();
        try {
            if(fieldList.size() > 0){

                Set<String> fieldsToQuery = new Set<String>(fieldList);
                fieldsToQuery.add('Id');
    
                String fieldApiString = string.join(fieldsToQuery, ',');
                String dynamicQuery = 'SELECT ' + fieldApiString + ' FROM '+ objectAPI +' WHERE Id =: recordId LIMIT 1';
    
                // userObj = Database.query(dynamicQuery, recordId);
                sObject sObj = querySObject(dynamicQuery, recordId, objectAPI);
    
                String sObjString = JSON.serialize(sObj);
                sobjectAsMap = (Map<String, Object>) JSON.deserializeUntyped(sObjString);
                return sobjectAsMap;
            }
            return sobjectAsMap;

        } catch (Exception e) {
            system.debug('exception in getSobjectAsMap : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return sobjectAsMap;
        }
    }

    // ==== === ==== Method to collect all mapping keys with value of merge templates ==== ===== =====
    public static map<String, Map<String, String>> getKeyNValueFromMergeTemps(List<String> margeTempKeyList, String sourceObjectAPI, String recordId){
        map<String, Map<String, String>> keyWithValuesGroup = new map<String, Map<String, String>>{
            'objectNGeneral' => new map<string, string>(),
            'childRecordTable' => new map<string, string>(),
            'margeTemplate' => new map<string, string>(),
            'salesforceImages' => new map<string, string>()
        };
        try {
            
            // --- ---- Extract abd collect Template Ids from merge template keys ---- ----
            Map<String, String> templateIds = extractMergeTemplateIds(margeTempKeyList);

            // --- --- Collect mapping keys from merge template records --- ---
            List<Template__c> mergeTemps = [SELECT Id,
                                            (SELECT Id, Name, Template_Value_Simple__c FROM Template_Data__r WHERE Value_Type__c = 'Extracted Mapping Keys' ORDER BY Order_No_Simple__c ASC)
                                            FROM Template__c WHERE Id IN :templateIds.values() AND Template_Type__c = 'Simple Template' AND Object_API_Name__c =:sourceObjectAPI AND Template_Status__c = true WITH SECURITY_ENFORCED];
            
            List<String> validTemplateListIds = new List<String>();
            for(Template__c temp : mergeTemps){
                validTemplateListIds.add(temp.Id);
            }

            // Get Mapping Key Values from the merge templates... Add with existing merge and value
            map<String, Map<String, String>> keyWithValues = getMappingsKeyValues(validTemplateListIds, recordId, false);
            keyWithValuesGroup.get('objectNGeneral').putAll(keyWithValues.get('objectNGeneral'));
            keyWithValuesGroup.get('childRecordTable').putAll(keyWithValues.get('childRecordTable'));
            keyWithValuesGroup.get('salesforceImages').putAll(keyWithValues.get('salesforceImages'));

            // add marge template Keys with template Id...
            keyWithValuesGroup.get('margeTemplate').putAll(templateIds);
            // keyWithValues.putAll(templateIds);

            return keyWithValuesGroup;
        } catch (Exception e) {
            system.debug('exception in getKeyNValueFromMergeTemps : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return keyWithValuesGroup;
        }
    }
    public static Map<String, String> extractMergeTemplateIds(List<String> margeTempKeyList){
        try {
            Map<String, String> templateIds = new Map<String, String>();
            for(String key : margeTempKeyList){
                String subMapping = key.substringBetween('{{','}}');
                // Used Switch instead of if/else to avoid pmd error of congantive complexity....
                Switch on String.valueOf(subMapping.startsWith('Temp.')){
                    when 'true'{
                        String subString = subMapping.substringAfter('Temp.');
                        String templateId = subString.contains('*') ? subString.substringBefore('*').trim() : subString.trim();
                        templateIds.put(key, templateId);
                    }
                }
            }

            return templateIds;
        } catch (Exception e) {
            system.debug('exception in extractMergeTemplateIds : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return new Map<String, String>();
        }
    }

    // ==== ===== ====== ===== GENERERIC METHODS ======= ======== ========== =====
    public static string getFieldValue(ExtractedKeys ext, map<string, Object> valueData){
        try {
            String fieldValue = '';
            
            if(ext.fieldAPI.contains('.') == true){
                String relationShipName = ext.fieldAPI.substringBefore('.');
                String fieldName = ext.fieldAPI.substringAfter('.');
                switch on relationShipName{
                    when 'Date', 'User', 'Org'{
                        fieldValue = (String) String.valueOf(valueData.get(fieldName));
                    }
                    when else{
                        Map<String, Object> parentObj = (Map<String, Object>) valueData.get(relationShipName);
                        fieldValue = (String) String.valueOf(parentObj.get(fieldName));
                    }
                }
            }
            else{
                fieldValue = (String) String.valueOf(valueData.get(ext.fieldAPI));  
            }

            System.debug('---- fieldValue ---- : '+fieldValue + ' ----- ext ----- '+ ext);

            if(ext.formatType != null && ext.formatType != '' && fieldValue != '' && fieldValue != null){
                // field required formatting...
                switch on ext.fieldType{
                    when 'DATETIME', 'DATE'{
                        fieldValue = formatDateTime(fieldValue, ext.formatType, ext.fieldType);
                    }
                    when 'BOOLEAN'{
                        fieldValue = formatBoolean(fieldValue, ext.formatType);
                    }
                    when 'STRING'{
                        fieldValue = formatString(fieldValue, ext.formatType);
                    }
                    when 'INTEGER', 'DOUBLE', 'CURRENCY', 'PERCENT'{
                        fieldValue = formatNumber(fieldValue, ext.formatType);
                    }
                }
            }
            else if(fieldValue != '' && fieldValue != null && ext.fieldType == 'DATETIME' && fieldValue.contains('+')){
                // If DateTime field value consist of timezone offset then convert to GMT. field required formatting...
                Datetime dt1 = (Datetime) JSON.deserialize('"' + fieldValue + '"', Datetime.class);
                fieldValue = dt1.format('yyyy-MM-dd HH:mm:ss');
            }

            return fieldValue;
        } catch (Exception e) {
            system.debug('exception in getFieldValue : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return ext.mappingKey;
        }
    }
    public static List<ExtractedKeys> getValidKeys(List<string> mappingKeyList, String sourceObjectAPI, String startingSymbol){
        List<ExtractedKeys> extractedKeys = new List<ExtractedKeys>();
        try {

            List<KeyMappingController.MappingFields> objectWithFields = new List<KeyMappingController.MappingFields>();
            Map<String, String> validFields = getValidFields(startingSymbol, sourceObjectAPI);

            for(String key : mappingKeyList){
                String subMapping = key.substringBetween('{{','}}');
                // Used Switch instead of if/else to avoid pmd error of congantive complexity....
                Switch on String.valueOf(subMapping.startsWith(startingSymbol)){
                    when 'true'{
                        String subString = subMapping.substringAfter(startingSymbol);
                        String fieldAPI = '';
                        String formateType = '';
                        if(subString.contains('*')){
                            fieldAPI = subString.substringBefore('*').trim();
                            formateType = subString.substringBetween('*').trim();
                        }
                        else{
                            fieldAPI = subString.trim();
                        }

                        if(validFields.keySet().contains(fieldAPI)){
                            ExtractedKeys ext = new ExtractedKeys();
                            ext.fieldAPI = fieldAPI;
                            ext.formatType = formateType;
                            ext.fieldType = validFields.get(fieldAPI);
                            ext.mappingKey = key;
                            extractedKeys.add(ext);
                        }
                    }
                }
            }
            return extractedKeys;
        } catch (Exception e) {
            system.debug('exception in getValidKeys : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return extractedKeys;
        }
    }
    public static Map<String, String> getValidFields(String startingSymbol, String sourceObjectAPI){
        Map<String, String> validFields = new Map<String, String>();
        try {
            if(startingSymbol == 'Doc.'){
                validFields.putAll(getObjectFields('User', false));
                validFields.putAll(getObjectFields('organization', false));
    
                map<string, string> dateFormats = KeyMappingController.dateFormats();
                for(string dateInfo : dateFormats.keySet()){
                    validFields.put('Date.'+dateInfo, dateFormats.get(dateInfo).split('; ')[1]);
                }
            }
            else{
                validFields.putAll(getObjectFields(sourceObjectAPI, true));
            }
            return validFields;
        } catch (Exception e) {
            system.debug('exception in getValidKeys : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return validFields;
        }
    }
    public static Map<String, String> getObjectFields(String sourceObjectAPI, Boolean getParentFields){
        Map<String, String> objectFields = new Map<String, String>();
        try {
                // add base Object fields....
                objectFields.putAll(fetchObjectFields(sourceObjectAPI, 'normal', null));

                // Fetch parent Obejct(reference fields...)
                Map<String, String> parentObject = new Map<String, String>();
                if(getParentFields){
                    parentObject.putAll(fetchObjectFields(sourceObjectAPI, 'reference', null));
                }

                // get all the fields from the parent object
                for(String parentAPI : parentObject.keyset()){
                    objectFields.putAll(fetchObjectFields(parentAPI, 'normal', parentObject.get(parentAPI)));
                }

            return objectFields;

        } catch (Exception e) {
            system.debug('exception in getValidKeys : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return objectFields;
        }
    }
    public static map<String, string> fetchObjectFields(String objectAPI, String fieldType, String replationshipName){
        Map<String, String> fields = new Map<String, String>();
        try {

            Schema.SObjectType sobjType = Schema.getGlobalDescribe().get(objectAPI);
            Schema.DescribeSObjectResult r = sobjType.getDescribe();
            Map<String, Schema.SObjectField> mapOfFields = r.fields.getMap();
            List<String> fieldsList = new List<String>(mapOfFields.keySet());
            fieldsList.sort();

            for(String fieldName : fieldsList){
                Schema.SObjectField f = mapOfFields.get(fieldName);
                Schema.DescribeFieldResult field = f.getDescribe();
                if(field.getType() == Schema.DisplayType.REFERENCE && fieldType == 'reference'){
                    fields.put(string.valueOf(field.getReferenceTo()[0]), field.getRelationshipName());
                    // fields.put(parentAPI, parentReplationshipName)
                }
                else{
                    if((String)String.valueOf(field.getType()) != 'ADDRESS' && (String)String.valueOf(field.getType()) != 'LOCATION' && fieldType == 'normal'){
                        String fieldAPI = (String) String.valueOf(field.getName());
                        fieldAPI = replationshipName == null ? fieldAPI : replationshipName +'.'+ fieldAPI;
                        fields.put(fieldAPI , (String)  String.valueOf(field.getType()));
                        // fields.put(fieldAPI, fieldType)
                    }
                }
            }

            return fields;
        } catch (Exception e) {
            system.debug('exception in fetchObjectFields : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return fields;
        }
    }
    // This is used to solve one of the PMD error...
    public static sObject querySObject(String query, String recordId, String sourceObject){
        try {
            return Database.query(query);
        } catch (Exception e) {
            system.debug('exception in querySObject : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sourceObject);
            return  sObjectType.newSObject();
        }
    }
 
    // ====== METHODS TO FORAMT FIELD VALUE =======
    public static string formatDateTime(string fieldValue, string formatType, String fieldType){
        String userTimeZone = (String)String.valueOf(UserInfo.getTimeZone().getID());

        Datetime dt;
        if(fieldType == 'DATETIME'){
            // If DateTime field value consist of timezone offset then convert to GMT. field required formatting...
            Datetime dt1 = (Datetime) JSON.deserialize('"' + fieldValue + '"', Datetime.class);
            dt = Datetime.valueOf(dt1.format('yyyy-MM-dd HH:mm:ss'));
        }
        else if(fieldType == 'DATE'){
            // Else do the normal DateTime conversion....
            dt = (Datetime) JSON.deserialize('"' + fieldValue + '"', Date.class);
        }

        // Now Format GMT time inti user timezone... with format type
        fieldValue = dt.format(formatType, userTimeZone);

        return fieldValue;
    }
    public static string formatBoolean(string fieldValue, string formatType){
        fieldValue = fieldValue == 'true' ? formatType.substringBefore('/') : formatType.substringAfter('/');

        return fieldValue;
    }
    public static string formatString(string fieldValue, string formatType){
        Integer endIndex = (Integer) Integer.valueOf(formatType.substringAfter('L:'));
        endIndex = endIndex > fieldValue.length() ? fieldValue.length() : endIndex;             // endIndex must be less than value string length...
        fieldValue = fieldValue.substring(0, endIndex);

        return fieldValue;
    }
    public static string formatNumber(string fieldValue, string formatType){
        Decimal val = (Decimal) Decimal.valueOf(fieldValue);
        String format = formatType.substringBetween('F:', ',');
        String decimalPlaces = formatType.substringBetween('dP:', ',');
        String roundMode = formatType.substringBetween('rM:', ',');

        if(decimalPlaces != null){
            if(roundMode != null){
                System.RoundingMode rM = System.RoundingMode.valueOf(roundMode);
                val = val.setScale(Integer.valueOf(decimalPlaces), rM);
            }
            else{
                val = val.setScale(Integer.valueOf(decimalPlaces));
            }
        }

        if(format == 'yes'){
            fieldValue = val.format();

            // Standard format() method remove decimal if user did't set any decimal places at time of field creation...
            // So, when decimalPlaces is not 0, add decimal from our end as per formatKey...
            if(decimalPlaces != null && decimalPlaces != '0'){
                string valStr = (String) String.valueOf(val);
                String decimalValue = (String) String.valueOf(valStr.substringAfter('.'));
                if(fieldValue.contains('.')){
                    // when fieldValue contains any decimals..., remove standard decimal palces and add custom decimal palces...
                    fieldValue = val.format().substringBefore('.') + '.'+ decimalValue;
                }
                else{
                    // when fieldValue not contains any decimals...
                    fieldValue = val.format() + '.'+ decimalValue;
                }
            }

        }
        else{
            fieldValue = String.valueOf(val);
        }

        return fieldValue;
    }

    // === === === WRAPPER CLASSES ==== ===== ===

    // -- wrapper class to store extracted key's info.....
    public class ExtractedKeys{
        @AuraEnabled public String mappingKey;
        @AuraEnabled public String fieldAPI;
        @AuraEnabled public String fieldType;
        @AuraEnabled public String formatType;
        @AuraEnabled public String value;
    }

    // -- wrapper class to store extracted child Table info.....
    public class ChildTableInfo{
        @auraEnabled public String tableHTML;
        @AuraEnabled public String keyRow;
        @AuraEnabled public String infoRow;
        @AuraEnabled public String modifiedTableHTML; 
        @AuraEnabled public String queryFilters;
        @AuraEnabled public String queryLimit;
        @AuraEnabled public String childObjetAPI;
        @AuraEnabled public String childRelationshipName;
        @AuraEnabled public String mainRecordQuery;
        @AuraEnabled public String sourceObjectAPI;
        @AuraEnabled public List<String> mappingFields;
        @AuraEnabled public List<String> queryFields;
    }

    public class FieldListClass{
        @AuraEnabled public List<String> objectFields = new List<String>();
        @AuraEnabled public List<String> dateFields = new List<String>();
        @AuraEnabled public List<String> orgFields = new List<String>();
        @AuraEnabled public List<String> userFields = new List<String>();
    }

}