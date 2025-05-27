public with sharing class DataMappingControllerV2 {

    /**
     * @method getMappingsKeyValues,
     * @param templateIDs, List of template Ids,
     * @param recordId, source record is,
     * @param includeMergTemKeys, if you want to get marged tempalte, key mark it true,
     * 
     * @description : Main method from where you can extract mapping key with its actual value, (for simple tempalte)...
     * this method run two time, first when we call it from docGenerateController with template on which document going to creare &
     * second when template have merge templates with list of template as parameter...
     */

    public static Set<String> fieldsInCustomKey = new Set<String>();
    public static List<MVDG__Custom_Key__c> queriedCustomKeys = new List<MVDG__Custom_Key__c>();
    public static Set<String> customKeys = new Set<String>();

    public static map<String, Map<String, String>> getMappingsKeyValues(List<String> templateIDs, String recordId, Boolean includeMergTemKeys){
        Map<String, Map<String, String>> mapingKeyVsValuesGroup = new Map<String, Map<String, String>>{
            'objectNGeneral' => new map<string, string>(),
            'childRecordTable' => new map<string, string>(),
            'margeTemplate' => new map<string, string>(),
            'salesforceImages' => new map<string, string>(),
            'signatureImage' => new map<string, string>()
        };
        try {
            List<MVDG__Template__c> temps = [SELECT Id, Name, MVDG__Object_API_Name__c, MVDG__Template_Name__c, MVDG__Template_Type__c, MVDG__Template_Status__c, MVDG__Description__c, CreatedDate, LastModifiedDate,
                                      (SELECT Id, Name, MVDG__Template_Value_Simple__c FROM MVDG__Template_Data__r WHERE MVDG__Value_Type__c = 'Extracted Mapping Keys' ORDER BY MVDG__Order_No_Simple__c ASC)
                                       FROM MVDG__Template__c  WHERE Id In :templateIDs WITH SECURITY_ENFORCED];

            for(MVDG__Template__c temp : temps){
                String extractedKeyString = '';

                // get extracted Keys stored in field...
                for(MVDG__Template_Data__c fieldData : temp.MVDG__Template_Data__r){
                    extractedKeyString +=  fieldData.MVDG__Template_Value_Simple__c;
                }

                extractedKeyString = extractedKeyString != '' ? extractedKeyString : 'null';

                String sourceObjectAPI = temp.MVDG__Object_API_Name__c;

                // Type cast extracted key field value to key mappign keys, child object info and merge tempalte keys....
                Map<String, Object> extractedKeyMap = (Map<String, Object>) JSON.deserializeUntyped(extractedKeyString);
    
                // Collect and Store mapping keys in to set of string from keys stored in field...
                Set<String> extractedKeys = collectMappingKeys(extractedKeyMap);

                // collect mapping key values for object field and general fields....
                Map<String, String> mappigKeysValue = getMappingKeyVsValue(new List<String>(extractedKeys), sourceObjectAPI, recordId);
                mapingKeyVsValuesGroup?.get('objectNGeneral')?.putAll(mappigKeysValue);

                // collect mapping key values for child object table info from keys stored in field....
                Object childRecordTables = extractedKeyMap?.get('childRecordTables') != null ? extractedKeyMap?.get('childRecordTables') : (Object) JSON.deserializeUntyped('[]');
                String childTableString = JSON.serialize(childRecordTables);
                Set<ChildTableInfo> childTables = (Set<ChildTableInfo>) JSON.deserializeStrict(childTableString, Set<ChildTableInfo>.Class);
    
                // modify child object table...
                for(ChildTableInfo tableInfo : childTables){
                    if(tableInfo.tableHTML != null && tableInfo.infoRow != null && tableInfo.tableHTML != '' && tableInfo.infoRow != ''){
                        Map<String, String> modifiedChildTable = modifyChildObjectTables(tableInfo, sourceObjectAPI, recordId);
                        mapingKeyVsValuesGroup?.get('childRecordTable')?.putAll(modifiedChildTable);
                    }
                }

                // Collect and Store Salesforce image SRC in to set ...
                Map<String, String> sfImagesSRCVsID = getSFimageVsId(extractedKeyMap);
                mapingKeyVsValuesGroup?.get('salesforceImages')?.putAll(sfImagesSRCVsID);

                // Collect signature Image contentVersion Id from source record...
                Map<String, String> signatureImageCvId = getSignatureImageCVId(extractedKeyMap, recordId);
                mapingKeyVsValuesGroup?.get('signatureImage')?.putAll(signatureImageCvId);

                
                Map<String,String> customKeys = collectCustomKeys(mapingKeyVsValuesGroup?.get('objectNGeneral'), queriedCustomKeys, fieldsInCustomKey, customKeys);
                for (String key : new List<String>(customKeys.keySet())) {
                    if (key.startsWith('{{@CKTABLE:')) {
                        String json = customKeys.get(key);

                        if (String.isNotBlank(json)) {
                            try {
                                // Correct static method call
                                Map<String, Object> tableData = (Map<String, Object>) System.JSON.deserializeUntyped(json);
                                List<Object> headers = (List<Object>) tableData.get('headers');
                                List<Object> rows = (List<Object>) tableData.get('rows');
                                String fontSize = (String) tableData.get('fontSize');

                                String tableHtml = '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;font-size:' + fontSize + 'px;">';
                                tableHtml += '<thead><tr>';
                                for (Object header : headers) {
                                    tableHtml += '<th style="background-color:#fff;">' + String.valueOf(header) + '</th>';
                                }
                                tableHtml += '</tr></thead><tbody>';

                                for (Object rowObj : rows) {
                                    Map<String, Object> row = (Map<String, Object>) rowObj;
                                    tableHtml += '<tr>';
                                    for (Object header : headers) {
                                        String col = String.valueOf(header);
                                        String val = row.containsKey(col) ? String.valueOf(row.get(col)) : '';
                                        tableHtml += '<td>' + val + '</td>';
                                    }
                                    tableHtml += '</tr>';
                                }

                                tableHtml += '</tbody></table>';

                                // Replace JSON with the rendered table HTML
                                customKeys.put(key, tableHtml);

                            } catch (Exception e) {
                                customKeys.put(key, '');
                                Log_Handler.store_Exception(e, 'DataMappingControllerV2', 'getMappingsKeyValues > Create Table Loop');
                            }
                        } else {
                            customKeys.put(key, '');
                        }
                    }
                }


                mapingKeyVsValuesGroup?.get('objectNGeneral')?.putAll(customKeys);
                

                // this varibale will be FALSE when it call from "getKeyNValueFromMergeTemps" Method...
                if(includeMergTemKeys == true){
                    // System.debug(' ---- ---- ---- Merge Template keys Starts ---- ---- '+ temp.Id);
                    // collect merge template key from keys stored in field ...
                    set<String> mergTemplateKeys = collectMergeTemplateKeys(extractedKeyMap);

                    // create map for merge template key with Values....
                    map<String, Map<String, String>> keyWithValues = getKeyNValueFromMergeTemps(new List<String>(mergTemplateKeys), sourceObjectAPI, recordId);

                    // colelct extracted key with actual value from marge template add them into exsiting map of main tempalte.
                    mapingKeyVsValuesGroup?.get('objectNGeneral')?.putAll(keyWithValues?.get('objectNGeneral'));
                    mapingKeyVsValuesGroup?.get('childRecordTable')?.putAll(keyWithValues?.get('childRecordTable'));
                    mapingKeyVsValuesGroup?.get('salesforceImages')?.putAll(keyWithValues?.get('salesforceImages'));
                    mapingKeyVsValuesGroup?.get('margeTemplate')?.putAll(keyWithValues?.get('margeTemplate'));

                    // Note : no need to add signatureImage for merge tempalte key, because signature key will be same for each template...
                }
            }
                                        
            return mapingKeyVsValuesGroup;
        } catch (Exception e) {
            // Log_Handler.store_Exception(e, 'DataMappingControllerV2', 'getMappingsKeyValues');
            // System.debug('exception in getMappingsKeyValues : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return mapingKeyVsValuesGroup;
        }
    }

    /**
     * @param extractedKeyMap, Map of keyType vs list of keys in object form,
     * @description : extract and collect all the object and general field's key from all mapping keys.
     */
    public static Set<String> collectMappingKeys(Map<String, Object> extractedKeyMap){
        Set<String> extractedKeys = new Set<String>();
        try {
            
            Object objectFields = extractedKeyMap?.get('objectFields') != null ? extractedKeyMap.get('objectFields') : (Object) JSON.deserializeUntyped('[]');
            String objectFieldString = JSON.serialize(objectFields);
            List<Object> objectFieldKeys = (List<Object>) JSON.deserializeUntyped(objectFieldString);
    
            Object generalFields = (extractedKeyMap != null && extractedKeyMap?.get('generalFields') != null) ? extractedKeyMap.get('generalFields') : (Object) JSON.deserializeUntyped('[]');
            String generalFieldString = JSON.serialize(generalFields);
            List<Object> generalFieldKeys = (List<Object>) JSON.deserializeUntyped(generalFieldString);

            Object extractedCustomKeys = extractedKeyMap?.get('customKeys') != null ? extractedKeyMap.get('customKeys') : (Object) JSON.deserializeUntyped('[]');
            String customKeyString = JSON.serialize(extractedCustomKeys);
            List<Object> customKeysList = (List<Object>) JSON.deserializeUntyped(customKeyString);
            Set<String> customKeyNames = new Set<String>();


            for(Object key : objectFieldKeys){
                extractedKeys.add((String) key);
            }
            for(Object key : generalFieldKeys){
                extractedKeys.add((String) key);
            }
            for (Object key : customKeysList) {
                String keyStr = String.valueOf(key);
                customKeys.add(keyStr);

                String keyName;

                if (keyStr.startsWith('{{@CK:')) {
                    keyName = keyStr.substringAfter('{{@CK:').substringBefore('.');
                } else if (keyStr.startsWith('{{@CKLIST:')) {
                    keyName = keyStr.substringAfter('{{@CKLIST:').substringBefore('.');
                } else if (keyStr.startsWith('{{@CKTABLE:')) {
                    String temp = keyStr.substringAfter('{{@CKTABLE:').substringBefore('}}').subStringBefore(';').subStringBefore(':');
                    keyName = temp.contains(':') ? temp.substringBefore(':') : temp;
                }

                if (keyName != null) {
                    customKeyNames.add(keyName.trim());
                }
            }
            queriedCustomKeys = [
                SELECT Id, MVDG__Custom_Key_Name__c, MVDG__Query__c, MVDG__Object_Name__c
                FROM MVDG__Custom_Key__c 
                WHERE MVDG__Custom_Key_Name__c IN :customKeyNames
            ];
            Pattern pattern = Pattern.compile('\\{\\{#(.*?)\\}\\}');

            for (MVDG__Custom_Key__c key : queriedCustomKeys) {
                String queryTemplate = key.MVDG__Query__c;
                Matcher matcher = pattern.matcher(queryTemplate);

                while (matcher.find()) {
                    fieldsInCustomKey.add('{{#' + matcher.group(1) + '}}');
                }
            }

            extractedKeys.addAll(fieldsInCustomKey);
            return extractedKeys;
        } catch (Exception e) {
            // System.debug('exception in collectMappingKeys : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return extractedKeys;
        }
    }
    /**
     * @param extractedKeyMap, Map of keyType vs list of keys in object form,
     * @description : extract and collect merge template keys.
     */
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
            // System.debug('exception in collectMergeTemplateKeys : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return mergTemplateKeys;
        }
    }
    /**
     * @param extractedKeyMap, Map of keyType vs list of keys in object form,
     * @description : extract and collect Custom Keys.
     */
    public static Map<String, String> collectCustomKeys(Map<String, Object> objectFieldValues, List<Custom_Key__c> queriedCustomKeys, Set<String> fieldsInCustomKey, Set<String> customKeys) {
        Map<String, String> resolvedCustomKeyValues = new Map<String, String>();

        try {
            List<String> finalQueries = new List<String>();
            for (MVDG__Custom_Key__c key : queriedCustomKeys) {
                String queryTemplate = key.MVDG__Query__c;
                for (String placeholder : fieldsInCustomKey) {
                    Object value = objectFieldValues.get(placeholder);
                    String replacement = (value instanceof String) ? '\'' + String.valueOf(value) + '\'': String.valueOf(value);

                    if(replacement == null){
                        Continue;
                    }
                    if (queryTemplate.contains(placeholder)) {
                        queryTemplate = queryTemplate.replace(placeholder, replacement);
                    }
                }
                if(!queryTemplate.contains('{{')){
                    finalQueries.add(queryTemplate);
                }
            }

            for (Integer i = 0; i < finalQueries.size(); i++) {
                String finalQuery = finalQueries[i];
                MVDG__Custom_Key__c currentKey = queriedCustomKeys[i];
                String keyName = currentKey.MVDG__Custom_Key_Name__c;
                String objectName = currentKey.MVDG__Object_Name__c;

                try {
                    List<SObject> queryResult = Database.query(finalQuery);

                    if (!queryResult.isEmpty()) {

                        for (String rawKey : customKeys) {
                            if (rawKey.startsWith('{{@CK:' + keyName + '.')) {
                                String fieldName = rawKey.substringBetween(keyName + '.', '}}').subStringBefore('*').trim();

                                if (fieldName != null) {
                                    Map<String, Object> mapOfRecord = queryResult[0].getPopulatedFieldsAsMap();
                                    Object fieldValue = mapOfRecord.containsKey(fieldName) ? queryResult[0].get(fieldName) : '';
                                    List<ExtractedKeys> fieldWithType = getValidKeys(new List<String>{rawKey}, objectName, '@CK:');
                                    if(!fieldWithType.isEmpty()) {
                                        String formattedValue = getFieldValue(fieldWithType[0], mapOfRecord);
                                        resolvedCustomKeyValues.put(rawKey, formattedValue);
                                    }
                                }
                            }else if (rawKey.startsWith('{{@CKLIST:' + keyName + '.')) {
                                String fieldName = rawKey.substringBetween(keyName + '.', ':');
                                String separator = rawKey.subStringAfter('{{@CKLIST:').substringBetween(':', '}}').subStringBefore('*');

                                if (fieldName != null) {
                                    List<String> collectedValues = new List<String>();

                                    for (SObject record : queryResult) {
                                        Map<String, Object> mapOfRecord = queryResult[0].getPopulatedFieldsAsMap();
                                        Object fieldValue = mapOfRecord.containsKey(fieldName) ? mapOfRecord.get(fieldName) : '';
                                        if (fieldValue != '') {
                                            collectedValues.add(formatString(String.valueOf(fieldValue), rawKey.substringBetween('*')));
                                        }
                                    }

                                    String finalValue = String.join(collectedValues, separator);
                                    resolvedCustomKeyValues.put(rawKey, finalValue);
                                }
                            } else if (rawKey.startsWith('{{@CKTABLE:' + keyName)) {
                                String fieldSection = rawKey.substringAfter('{{@CKTABLE:' + keyName);
                                Set<String> fieldNames = new Set<String>();
                                Boolean includeIndex = false;
                                Set<String> availableFields = new Set<String>();
                                String fontSize = '12';

                                if (!queryResult.isEmpty()) {
                                    availableFields = queryResult[0].getPopulatedFieldsAsMap().keySet();
                                }

                                if (fieldSection.startsWith(':')) {
                                    String fieldAndFontSection = fieldSection.substringAfter(':').replace('}}', '');

                                    // Split fields and font size by semicolon
                                    List<String> parts = fieldAndFontSection.split(';');

                                    if (!parts.isEmpty() && !String.isBlank(parts[0])) {
                                        for (String field : parts[0].split(',')) {
                                            field = field.trim();
                                            if (field.equalsIgnoreCase('INDEX')) {
                                                includeIndex = true;
                                            } else if (availableFields.contains(field)) {
                                                fieldNames.add(field);
                                            }
                                        }
                                    }

                                    // Second part = optional font size
                                    if (parts.size() > 1 && Pattern.matches('^[0-9]+$', parts[1].trim())) {
                                        fontSize = parts[1].trim();
                                    }
                                } else if (fieldSection.startsWith(';')) {
                                    fontSize = fieldSection.substringBetween(';', '}}').trim();
                                }

                                if (fieldNames.isEmpty()) {
                                    fieldNames.addAll(availableFields);
                                }

                                List<String> headers = new List<String>();
                                if (includeIndex) {
                                    headers.add('No.');
                                }
                                headers.addAll(fieldNames);

                                List<Map<String, String>> rows = new List<Map<String, String>>();
                                for (Integer idx = 0; idx < queryResult.size(); idx++) {
                                    SObject record = queryResult[idx];
                                    Map<String, String> rowMap = new Map<String, String>();
                                    if (includeIndex) {
                                        rowMap.put('No.', String.valueOf(idx + 1));
                                    }
                                    for (String col : fieldNames) {
                                        Object val = record.containsKey(col) ? record.get(col) : '';
                                        rowMap.put(col, val != null ? String.valueOf(val) : '');
                                    }
                                    rows.add(rowMap);
                                }

                                Map<String, Object> tableData = new Map<String, Object>();
                                tableData.put('headers', headers);
                                tableData.put('rows', rows);
                                tableData.put('fontSize', fontSize);
                                tableData.put('includeIndex', includeIndex);

                                String jsonTable = JSON.serialize(tableData);
                                resolvedCustomKeyValues.put(rawKey, jsonTable);
                            }

                        }
                    } else {
                        for (String rawKey : customKeys) {
                            if (!resolvedCustomKeyValues.containsKey(rawKey)) {
                                resolvedCustomKeyValues.put(rawKey, '');
                            }
                        }
                    }

                } catch (Exception e) {
                    Log_Handler.store_Exception(e, 'DataMappingControllerV2', 'collectCustomKeys');
                    // System.debug('Error executing query: ' + finalQuery + ' - ' + ex.getMessage());
                }
            }

            return resolvedCustomKeyValues;

        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DataMappingControllerV2', 'collectCustomKeys');
            return resolvedCustomKeyValues;
        }
    }


    // === === Methods to Create and Add child object's record's row in table ==== ==== ====

    /**
     * @param tableInfo, wrapper class that store inforamtion about child record table,
     * @param sourceObjectAPI, API name of source object,
     * @param recordId, Id or source record
     * 
     * @description : Method to create dynamic table with child object records,
     * It modify child object table by replacing and adding actual record with key row, 
     */
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
                // System.debug('orginal limit : ' + tableInfo.queryLimit);
                tableInfo.queryLimit = tableInfo.queryLimit.isNumeric() == true ? tableInfo.queryLimit : '50';
                // System.debug('before set 50 limit : ' + tableInfo.queryLimit);
                tableInfo.queryLimit = Integer.valueOf(tableInfo.queryLimit) > 50 ? '50' : tableInfo.queryLimit;
                // System.debug('after set 50 limit : ' + tableInfo.queryLimit);


                // ==> validate each field... and add into field's list to create query....
                List<ExtractedKeys> extractedKeys = getValidKeys(tableInfo.mappingFields, tableInfo.childObjetAPI, '!');
                Set<String> validChildObjFields = new Set<String>();
                for(ExtractedKeys ext : extractedKeys){
                    validChildObjFields.add(ext.fieldAPI);
                }

                List<map<string, Object>> childRecords = getChildRecordsAsMap(validChildObjFields, tableInfo, recordId);
                // System.debug('---- ------ child record.size() ----- ------ : ' + childRecords.size());
                // System.debug('modifiedKeyRow  before : ' + tableInfo.keyRow);
                modifiedKeyRow = createRowsWithChildRecords(childRecords, ExtractedKeys, tableInfo);
            }
            
            if(modifiedKeyRow != null){
                // System.debug('modifiedKeyRow after : ' + modifiedKeyRow);
                // System.debug('modifiedTableHTML before : ' + modifiedTableHTML);
                modifiedTableHTML = modifiedTableHTML.replace(tableInfo.keyRow, modifiedKeyRow);
                modifiedTableHTML = modifiedTableHTML.replace(infoRow, '');
                // System.debug('modifiedTableHTML after : ' + modifiedTableHTML);
            }

            return new Map<String, String>{tableInfo.tableHTML => modifiedTableHTML};
            
        } catch (Exception e) {
            // System.debug('exception in modifyChildObjectTables : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return new Map<String, String>{tableInfo.tableHTML => tableInfo.tableHTML};
        }
    }

    /**
     * @param fieldList, set of fields,
     * @param tableInfo, wrapper class that store inforamtion about child record table,
     * @param recordId, Id or source record
     * 
     * @description : Get Child record As map for easy data fetching fro further process
     */
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
                    childQuery += ' '+tableInfo.queryFilters;
                }
                if(tableInfo.queryLimit != null && tableInfo.queryLimit != ''){
                    childQuery += ' LIMIT '+tableInfo.queryLimit;
                }
                childQuery += ')';
    
                String mainRecordQuery = 'SELECT Id, '+String.escapeSingleQuotes(childQuery)+' FROM '+ String.escapeSingleQuotes(tableInfo.sourceObjectAPI) +' WHERE Id =: recordId LIMIT 1';

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
            // System.debug('exception in getChildRecordsAsMap : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return childRecordList;
        }
    }

    /**
     * @param childRecords, child record list and map of string(field api) and object(field value)
     * @param extractedKeys, list of extracted key to replace actual within it
     * @param tableInfo, wrapper class that store inforamtion about child record table,
     * 
     * @description : method create rows for child object record to add in table.. 
     * @return string as childRecordRows to replace with keyRow...
     */
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
            // System.debug('exception in createRowsWithChildRecords : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }

    /**
     * @param extractedKeyMap,  Map of keyType vs list of keys in object form,
     * @description : Methods to collect all SRC with content version id
     * @return map of string(imageSrc) and String(imageId)
     */
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
            // System.debug('exception in getSFimageVsId : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return sfImages;
        }
    }

    /**
     * @param extractedKeyMap,  Map of keyType vs list of keys in object form,
     * @param recordId, Id or source record
     * 
     * @description : Methods to copllect Content Version Id for signature image from source record 
     * @return map of string(siganture key) vs String(signature image id)
     */
    public static Map<String, String> getSignatureImageCVId(Map<String, Object> extractedKeyMap, String recordId){
        Map<String, String> signatureImage = new  Map<String,String>();
        try {

            Object signatureImageKey = extractedKeyMap?.get('signatureImage');

            List<ContentDocumentLink> linkedSignature = [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE LinkedEntityId =: recordId AND ContentDocument.Title LIke '%Signature-%' WITH SECURITY_ENFORCED ORDER BY ContentDocument.LastModifiedDate DESC LIMIT 1];
            
            if(signatureImageKey != null && linkedSignature.size() > 0){
                signatureImage.put((String)string.valueOf(signatureImageKey), linkedSignature[0].ContentDocument.LatestPublishedVersionId);
            }

            return signatureImage;
            
        } catch (Exception  e) {
            // System.debug('exception in getSFimageVsId : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return signatureImage;
        }
    }

    // === === Method to Replace value with object field's, parent object field's and General field's mapping key ==== ====
    /**
     * @param mappingKeyList, list of mapping keys,
     * @param sourceObjectAPI, API name of source object,
     * @param recordId, Id or source record,
     * 
     * @description : Method to get actual value of mapping for object field and general fiels...
     * @return map String(mapping Key) vs String(actual value)...
     * If Code find any false key or invalid key, it will return same key as its actual value...
     */
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
            // System.debug('exception in getMappingKeyVsValue : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return extractedKeyWithData;
        }
    }

    /**
     * @param fieldLists, wrapper class to store multiple type fields list,
     * @param extractedKeys, Map of keyType vs list of keys in object form,
     * @param recordIdNobjAPI, List of string with recordId at 0 index and Object Api name at 1 index,
     * 
     * @description : get key value for each object, date, user and organization field type...
     * @return map String(mapping Key) vs String(actual value)...
     */
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
            // System.debug('exception in mapKeysWithValue : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return extractedKeyWithData;
        }
    }

    /**
     * @param fieldList, List of field to retive using SOQL,
     * @param objectAPI, Sorce objcet API Name,
     * @param recordId, Id or source record,
     * 
     * @description : Retrive Object data as sObject using SOQL and Covert it into Map of string & string
     */
    public static map<String, Object> getSobjectAsMap(List<String> fieldList, String objectAPI, string recordId){
        map<String, Object> sobjectAsMap = new map<String, Object>();
        try {
            if(fieldList.size() > 0){

                Set<String> fieldsToQuery = new Set<String>(fieldList);
                fieldsToQuery.add('Id');
    
                String fieldApiString = string.join(fieldsToQuery, ',');
                String dynamicQuery = 'SELECT ' + String.escapeSingleQuotes(fieldApiString) + ' FROM '+ String.escapeSingleQuotes(objectAPI) +' WHERE Id =: recordId LIMIT 1';
    
                // userObj = Database.query(dynamicQuery, recordId);
                sObject sObj = querySObject(dynamicQuery, recordId, objectAPI);
    
                String sObjString = JSON.serialize(sObj);
                sobjectAsMap = (Map<String, Object>) JSON.deserializeUntyped(sObjString);
                return sobjectAsMap;
            }
            return sobjectAsMap;

        } catch (Exception e) {
            // System.debug('exception in getSobjectAsMap : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return sobjectAsMap;
        }
    }

    // ==== === ==== Method to collect all mapping keys with value of merge templates ==== ===== =====
    /**
     * @param margeTempKeyList, List of merger tempalte keys,
     * @param sourceObjectAPI, Sorce objcet API Name,
     * @param recordId, Id of source record,
     * 
     * @description : Extract and collect merge tempalte key from all extracted key store in field...
     */
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
            List<MVDG__Template__c> mergeTemps = [SELECT Id,
                                            (SELECT Id, Name, MVDG__Template_Value_Simple__c FROM MVDG__Template_Data__r WHERE MVDG__Value_Type__c = 'Extracted Mapping Keys' ORDER BY MVDG__Order_No_Simple__c ASC)
                                            FROM MVDG__Template__c WHERE Id IN :templateIds.values() AND MVDG__Template_Type__c = 'Simple Template' AND MVDG__Object_API_Name__c =:sourceObjectAPI AND MVDG__Template_Status__c = true WITH SECURITY_ENFORCED];
            
            List<String> validTemplateListIds = new List<String>();
            for(MVDG__Template__c temp : mergeTemps){
                validTemplateListIds.add(temp.Id);
            }

            // Get Mapping Key Values from the merge templates... Add with existing merge and value
            map<String, Map<String, String>> keyWithValues = getMappingsKeyValues(validTemplateListIds, recordId, false);
            keyWithValuesGroup?.get('objectNGeneral')?.putAll(keyWithValues.get('objectNGeneral'));
            keyWithValuesGroup?.get('childRecordTable')?.putAll(keyWithValues.get('childRecordTable'));
            keyWithValuesGroup?.get('salesforceImages')?.putAll(keyWithValues.get('salesforceImages'));

            // add marge template Keys with template Id...
            keyWithValuesGroup?.get('margeTemplate')?.putAll(templateIds);
            // keyWithValues.putAll(templateIds);

            return keyWithValuesGroup;
        } catch (Exception e) {
            // System.debug('exception in getKeyNValueFromMergeTemps : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return keyWithValuesGroup;
        }
    }

    /**
     * @param margeTempKeyList, List of merger tempalte keys,
     * @description : Extracting template Ids from tempalte keys...
     */
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
            // System.debug('exception in extractMergeTemplateIds : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber() +'message : '+ e.getMessage());
            return new Map<String, String>();
        }
    }

    // ==== ===== ====== ===== GENERERIC METHODS ======= ======== ========== =====

    /**
     * @param ext, wrapper class to store mapping key infos,
     * @param valueData, map of fieldName with value,
     * 
     * @description : generic method to getfield value as per its key type and field type with formatting...
     */
    public static string getFieldValue(ExtractedKeys ext, map<string, Object> valueData){
        try {
            String fieldValue = '';
            
            if(ext.fieldAPI.contains('.') == true){
                String relationShipName = ext.fieldAPI.substringBefore('.');
                String fieldName = ext.fieldAPI.substringAfter('.');
                switch on relationShipName{
                    when 'Date', 'User', 'Org'{
                        fieldValue = (String) String.valueOf(valueData?.get(fieldName));
                    }
                    when else{
                        // field comes in this block must me sorce object's parent object's field...
                        Map<String, Object> parentObj = (Map<String, Object>) valueData?.get(relationShipName);
                        fieldValue = (String) String.valueOf(parentObj?.get(fieldName));
                    }
                }
            }
            else{
                // field comes in this block must me sorce object field...
                fieldValue = (String) String.valueOf(valueData?.get(ext.fieldAPI));  
            }

            if(ext.formatType != null && ext.formatType != '' && fieldValue != '' && fieldValue != null){
                // field required formatting...
                switch on ext.fieldType{
                    when 'DATETIME', 'DATE', 'TIME'{
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

            ext.value = fieldValue;
            // System.debug('---- fieldValue ---- : '+fieldValue + ' ----- ext ----- '+ ext);

            return fieldValue;
        } catch (Exception e) {
            // System.debug('exception in getFieldValue : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return ext.mappingKey;
        }
    }

    /**
     * @param mappingKeyList, list mapping keys,
     * @param sourceObjectAPI, Sorce objcet API Name,
     * @param startingSymbol, symbol to identify fields...
     * 
     * @description : generic Method to verify all key and collect only valid keys...
     */
    public static List<ExtractedKeys> getValidKeys(List<string> mappingKeyList, String sourceObjectAPI, String startingSymbol){
        List<ExtractedKeys> extractedKeys = new List<ExtractedKeys>();
        try {

            List<KeyMappingController.MappingFields> objectWithFields = new List<KeyMappingController.MappingFields>();
            Map<String, String> validFields = getValidFields(startingSymbol, sourceObjectAPI);

            // // System.debug('validFields : ' + validFields);
            // for(String fieldAPI : validFields.keySet()){
            //     // System.debug('validFields : ' + fieldAPI);
            // }


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
                            fieldAPI = (startingSymbol == '@CK:') ? fieldAPI.subStringAfter('.') : fieldAPI;
                            formateType = subString.substringBetween('*').trim();
                        }
                        else{
                            fieldAPI = subString.trim();
                        }

                        // System.debug('fieldAPI : ' + fieldAPI);
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
            // System.debug('exception in getValidKeys : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return extractedKeys;
        }
    }

    /**
     * @param startingSymbol, symbol to identify fields...
     * @param sourceObjectAPI, Sorce objcet API Name,
     * 
     * @description : generic Method to get all object valid keys...
     */
    public static Map<String, String> getValidFields(String startingSymbol, String sourceObjectAPI){
        Map<String, String> validFields = new Map<String, String>();
        try {
            if(startingSymbol == 'Doc.'){
                validFields.putAll(getObjectFields('User', false, 'User'));
                validFields.putAll(getObjectFields('organization', false, 'Org'));
    
                map<string, string> dateFormats = KeyMappingController.dateFormats();
                for(string dateInfo : dateFormats.keySet()){
                    validFields.put('Date.'+dateInfo, dateFormats.get(dateInfo).split(';')[1]);
                }
            }
            else{
                validFields.putAll(getObjectFields(sourceObjectAPI, true, null));
            }
            return validFields;
        } catch (Exception e) {
            // System.debug('exception in getValidKeys : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return validFields;
        }
    }

    /**
     * @param sourceObjectAPI, Sorce objcet API Name,
     * @param getParentFields, make it true of you want to get parent object fields
     * @description : generic Method to get Source object and Its paret objects fields...
     */
    public static Map<String, String> getObjectFields(String sourceObjectAPI, Boolean getParentFields, String relationShipName){
        Map<String, String> objectFields = new Map<String, String>();
        try {
                // add base Object fields....
                objectFields.putAll(fetchObjectFields(sourceObjectAPI, 'normal', relationShipName));

                // Fetch parent Obejct(reference fields...)
                Map<String, String> parentObject = new Map<String, String>();
                if(getParentFields){
                    parentObject.putAll(fetchObjectFields(sourceObjectAPI, 'reference', null));
                }

                // get all the fields from the parent object
                for(String relation : parentObject.keyset()){
                    String parentAPI = parentObject.get(relation);
                    objectFields.putAll(fetchObjectFields(parentAPI, 'normal', relation));
                }

            return objectFields;

        } catch (Exception e) {
            // System.debug('exception in getValidKeys : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return objectFields;
        }
    }

    /**
     * @param objectAPI, Sorce objcet API Name,
     * @param fieldType, Its type of obejct field in source object, 'refrence' meanse parent object,
     * @param replationshipName, if we are getting value for field of parent object, add replationshipName with field api match mapping key
     * 
     * @description : generic Method to fetch object field using schema and modify api name as per replationshipName
     */
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
                    fields.put(field.getRelationshipName(), string.valueOf(field.getReferenceTo()[0]));
                    // fields.put(parentAPI, parentReplationshipName)
                }
                else{
                    if((String)String.valueOf(field.getType()) != 'ADDRESS' && (String)String.valueOf(field.getType()) != 'LOCATION' && fieldType == 'normal'){
                        String fieldAPI = (String) String.valueOf(field.getName());

                        if(objectAPI != 'Group' && replationshipName != 'What' && replationshipName != 'Who'){

                            fieldAPI = replationshipName == null ? fieldAPI : replationshipName +'.'+ fieldAPI;
                            fields.put(fieldAPI , (String)  String.valueOf(field.getType()));
                        }
                        else if(KeyMappingController.polymorphismObjAllowdFields.contains(fieldAPI) || field.isCustom()){
                            fieldAPI = replationshipName == null ? fieldAPI : replationshipName +'.'+ fieldAPI;
                            fields.put(fieldAPI , (String)  String.valueOf(field.getType()));
                        }
                        // fields.put(fieldAPI, fieldType)
                    }
                }
            }

            return fields;
        } catch (Exception e) {
            // System.debug('exception in fetchObjectFields : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return fields;
        }
    }
    /**
     * @param query, string query
     * @param recordId, Id of source record,
     * @param sourceObject,  Sorce objcet API Name,
     * 
     * @description : generic method to query object using Database.query
     * This is used to solve one of the PMD error...
     */
    public static sObject querySObject(String query, String recordId, String sourceObject){
        try {
            // System.debug('query :  ' + query);
            return Database.query(query);
        } catch (Exception e) {
            // System.debug('exception in querySObject : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sourceObject);
            return  sObjectType.newSObject();
        }
    }
 
    // ====== METHODS TO FORAMT FIELD VALUE =======

    /**
     * @description : formate date, time and Datetime fields.
     */
    public static string formatDateTime(string fieldValue, string formatType, String fieldType){
        String userTimeZone = (String)String.valueOf(UserInfo.getTimeZone().getID());

        Datetime dt;
        if(fieldType == 'DATETIME'){
            // If DateTime field value consist of timezone offset then convert to GMT. field required formatting...
            Datetime dt1 = (Datetime) JSON.deserialize('"' + fieldValue.replace(' ', 'T') + '"', Datetime.class);
            dt = Datetime.valueOf(dt1.format('yyyy-MM-dd HH:mm:ss'));
            // Now Format GMT time as per user timezone... with format type
            fieldValue = dt.format(formatType, userTimeZone);

        }
        else if(fieldType == 'DATE'){
            // Else do the normal DateTime conversion....
            dt = (Datetime) JSON.deserialize('"' + fieldValue + '"', Date.class);
        }
        else if(fieldType == 'TIME'){

            String TimeOnly = fieldValue?.substringBefore('.');
            String hr = TimeOnly?.split(':')[0];
            String min = TimeOnly?.split(':')[1];
            String sec = TimeOnly?.split(':')[2];

            Time timeValue = Time.newInstance(Integer.valueOf(hr), Integer.valueOf(min), Integer.valueOf(sec), 0);
            Date dateValue = Date.today(); 

            dt = Datetime.newInstance(dateValue, timeValue);
        }

        fieldValue = dt.format(formatType, userTimeZone);

        return fieldValue;
    }
    /**
     * @description : formate boolean (checkbox) fields.
     */
    public static string formatBoolean(string fieldValue, string formatType){
        fieldValue = fieldValue == 'true' ? formatType.substringBefore('/') : formatType.substringAfter('/');

        return fieldValue;
    }
    /**
     * @description : Format String (text) fields with length and case formatting.
     */
    public static String formatString(String fieldValue, String formatType) {

        if (String.isBlank(fieldValue) || String.isBlank(formatType)) {
            return fieldValue;
        }

        List<String> formats = formatType.replace('*', '').split(';');
        String result = fieldValue;

        for (String f : formats) {
            f = f.trim().toUpperCase();
            if (f.startsWithIgnoreCase('L:')) {
                Integer endIndex = Integer.valueOf(f.substringAfter('L:'));
                endIndex = Math.min(endIndex, result.length());
                result = result.substring(0, endIndex);
            }else if (f == 'UPPER') {
                result = result.toUpperCase();
            } else if (f == 'LOWER') {
                result = result.toLowerCase();
            } else if (f == 'TITLE') {
                // Capitalize first letter of each word
                List<String> words = result.toLowerCase().split(' ');
                for (Integer i = 0; i < words.size(); i++) {
                    if (!String.isEmpty(words[i])) {
                        words[i] = words[i].substring(0, 1).toUpperCase() + words[i].substring(1);
                    }
                }
                result = String.join(words, ' ');
            } else if (f == 'SENTENCE') {
                // Capitalize only first letter of the sentence
                result = result.toLowerCase();
                if (result.length() > 0) {
                    result = result.substring(0, 1).toUpperCase() + result.substring(1);
                }
            }
        }

        return result;
    }

    /**
     * @description : formate Number, Precentage and Currecy fields.
     */
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

    /**
     * @description : wrapper class to store extracted key's info.
     */
    public class ExtractedKeys{
        @AuraEnabled public String mappingKey;
        @AuraEnabled public String fieldAPI;
        @AuraEnabled public String fieldType;
        @AuraEnabled public String formatType;
        @AuraEnabled public String value;
    }

    /**
     * @description : wrapper class to store extracted child Table info.
     */
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

    /**
     * @description : wrapper class to store list of fileds for multiple key type.
     */
    public class FieldListClass{
        @AuraEnabled public List<String> objectFields = new List<String>();
        @AuraEnabled public List<String> dateFields = new List<String>();
        @AuraEnabled public List<String> orgFields = new List<String>();
        @AuraEnabled public List<String> userFields = new List<String>();
    }

}