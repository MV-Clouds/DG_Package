/**
* Class Name: GoogleDocPreview
* Test Class: GoogleDocPreviewTest
* @description: Used to generate the Final Google Document after replacing the merge fields 
* Date: 14/08/2024
* Created By: Dhairya Koshti
*/
public with sharing class GoogleDocPreview {
    public static MVDG__Google_Credentials__c authProvider;
    public static List<MVDG__Template_Data__c> templateData = new List<MVDG__Template_Data__c>();
    public static Map<String, HttpResponse> responseList = new Map<String, HttpResponse>();
    public static String refreshToken;

    /**
    * Method Name : doPreview
    * @description : Call this method to get pdf of google doc.
    * @param googleDocId google Document Id - String
    * @param format file format - String
    * @param requests list of document modification requests - List<Object>
    * @return Blob of the Google Doc - String.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    @AuraEnabled
    public static String doPreview(String googleDocId, String format, List<Object> requests) {
        Blob pdfBlob;
        try {
            if (refreshToken == null) {
                authProvider = getAuthProviderSettings();
            }
            // Update the google doc
            updateGoogleDoc(googleDocId, requests);

            //get pdf blob of google doc
            pdfBlob = getPDF(googleDocId, format);
            if (pdfBlob == null) {
                return 'error:Get PDF error:Unable to fetch the PDF from Google Drive:Unable to fetch the PDF from Google Drive';
            }

        } catch (Exception e) {
            
            Log_Handler.store_Exception(e, 'GoogleDocPreview', 'doPreview');
        } finally {
            //delete cloned google doc
            Boolean googleDocDeleted = deleteGoogleDoc(GoogleDocId);
            updateAuthProvider();
            insertResponses();
        }
        return EncodingUtil.base64Encode(pdfBlob);
    }

    /**
    * Method Name : refreshAccessToken
    * @description : get new access token using refresh token.
    * @return The new access Token - String.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static String refreshAccessToken() {
        try {
            String endpoint = 'https://oauth2.googleapis.com/token';
            List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();
            // List<AuthProviderSetup__mdt> mdata = AuthProviderSetup__mdt.getAll().values();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setTimeout(120000);
            request.setBody('refresh_token=' + authProvider.MVDG__refresh_token__c + '&client_id=' + mdata[0].MVDG__CID__c + '&client_secret=' + mdata[0].MVDG__CSEC__c + '&grant_type=refresh_token');
            // request.setBody('refresh_token=' + authProvider.MVDG__refresh_token__c + '&client_id=' + mdata[0].CID__c + '&client_secret=' + mdata[0].CSEC__c + '&grant_type=refresh_token');
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String newToken = (String) jsonResponse.get('access_token');
                if (newToken != null) {
                    authProvider.MVDG__access_token__c = newToken;
                }
                return newToken;
            }
            responseList.put('refreshAccessToken', response);
            // return 'error:Access Token Error:Error in getting access token:' + String.valueOf(response.getStatusCode()) + ' - ' + response.getStatus();

        } catch (Exception e) {
            
            Log_Handler.store_Exception(e, 'GoogleDocPreview', 'refreshAccessToken');
            // return 'error:Access Token Error:Error in getting access token:' + e.getMessage();
        }
        return null;
    }

    /**
    * Method Name : getDocument
    * @description : get google doc  in json format.
    * @param googleDocId google Document Id - String
    * @param templateId Id for the MVDG__Template__c - String
    * @return JSON format for the Google Document.
    */ 
    /***********************************************************************
     MODIFICATION LOG* 
     * Last Update Date : 03/06/2024
     * Updated By : Developer name
     * Name of methods changed (Comma separated if more then one) : method1 
     * Change Description : 
     ***********************************************************************/
    public static String getDocument(String googleDocId, String templateId) {
        try {
            String endpoint = 'https://docs.googleapis.com/v1/documents/' + googleDocId;
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + authProvider.MVDG__access_token__c);
            request.setTimeout(120000);
            Http http = new Http();
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                // Schedule apex class
                Datetime now = Datetime.now();
                Datetime runTime = now.addMinutes(2);
                Integer day = runTime.day();
                Integer month = runTime.month();
                Integer year = runTime.year();
                Integer hour = runTime.hour();
                Integer minute = runTime.minute();
                
                String cronExp = String.format( '0 {0} {1} {2} {3} ? {4}', new List<String>{String.valueOf(minute), String.valueOf(hour), String.valueOf(day), String.valueOf(month), String.valueOf(year)});
                
                DeleteGoogleDocument deleteGoogleDocument = new DeleteGoogleDocument(templateId, googleDocId);
                // String scheduleId = System.schedule(String.valueOf(Math.random()) + String.valueOf(System.now()), cronExp, deleteGoogleDocument);
                String scheduleId = System.schedule(String.valueOf(System.now()), cronExp, deleteGoogleDocument);
                
                return response.getBody();
            } else if (response.getStatusCode() == 401) {
                
                String refreshToken = refreshAccessToken();
                if (refreshToken != null) {
                    String returnvalue = getDocument(googleDocId, templateId); 
                    return returnvalue;
                }
            }
            responseList.put('getDocument', response);
            return 'error:Get Document Error:Error in getting document:' + String.valueOf(response.getStatusCode()) + ' - ' + response.getStatus();
            
        } catch (Exception e) {
            
            Log_Handler.store_Exception(e, 'GoogleDocPreview', 'getDocument');
            return 'error:Get Document Error:Error in getting document:' + e.getMessage();
        }
    }
    
    /**
     * Method Name : copyGoogleDoc
     * @description : Clone google doc in users account.
     * @param templateId Id for the MVDG__Template__c - String
     * @return wrapper having the JSON Format for the document and error in case - ResponseDocumentWrapper.
     */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    @AuraEnabled
    public static ResponseDocumentWrapper copyGoogleDoc(String templateId) {
        ResponseDocumentWrapper responseWrapper = new ResponseDocumentWrapper();
        try {
            if (refreshToken == null) {
                authProvider = getAuthProviderSettings();
            }
            if (String.isBlank(authProvider.MVDG__access_token__c)) {
                responseWrapper.error = 'error:CopyGoogleDoc:No Google Integration Found.:No Google Integration Found.';
                return responseWrapper;
            }
            templateData = [SELECT MVDG__Google_Doc_Template_Id__c, MVDG__Template__r.MVDG__Signature_Size__c FROM MVDG__Template_Data__c WHERE MVDG__Template__c = :templateId WITH SECURITY_ENFORCED ORDER BY MVDG__Order_No_Simple__c ASC];

            if (templateData.size() == 0) {
                responseWrapper.error = 'warning:Template Error:No Google Document linked with this template.:No Google Document linked with this template.';
                return responseWrapper;
                
            }
            responseWrapper.width = templateData[0].MVDG__Template__r.MVDG__Signature_Size__c;

            // Callout
            String googleDocId = templateData[0].MVDG__Google_Doc_Template_Id__c;
            String endpoint = 'https://www.googleapis.com/drive/v3/files/' + googleDocId + '/copy';
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('name', 'Untitled');
            String jsonBody = JSON.serialize(requestBody);
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + authProvider.MVDG__access_token__c);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(jsonBody);
            request.setTimeout(120000);
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {

                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String documentID = String.valueOf(responseMap.get('id'));
                responseWrapper.document = getDocument(documentID, templateId);
                updateAuthProvider();
                insertResponses();
                return responseWrapper;

            } else if (response.getStatusCode() == 401) {
                refreshToken = refreshAccessToken();
                if (refreshToken != null) {
                    responseWrapper = copyGoogleDoc(templateId);
                    return responseWrapper;
                }
            } else if (response.getStatusCode() == 404 && authProvider.SetupOwnerId != null && authProvider.SetupOwnerId != UserInfo.getOrganizationId()) {
                authProvider = [SELECT SetupOwnerId, MVDG__ClientId__c, MVDG__ClientSecret__c, MVDG__access_token__c, MVDG__refresh_token__c FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() AND MVDG__WorkingStatus__c = TRUE WITH SECURITY_ENFORCED];
                refreshToken = authProvider.SetupOwnerId;
                responseWrapper = copyGoogleDoc(templateId);
                return responseWrapper;
            }
            responseList.put('copyGoogleDoc', response);
            responseWrapper.error = 'error:Copy Google Doc:Error in processing the document:' + String.valueOf(response.getStatusCode()) + ' - ' + response.getStatus();
            return responseWrapper;
        } catch (Exception e) {
            responseWrapper.error = 'error:Copy Google Doc:Error in processing the document:' + e.getMessage();
            Log_Handler.store_Exception(e, 'GoogleDocPreview', 'copyGoogleDoc');
            
            
        }
        return responseWrapper;
    }

    /**
    * Method Name : updateGoogleDoc
    * @description : update google doc api callout.
    * @param googleDocId google Document Id - String
    * @param requests list of document modification requests - List<Object>
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static void updateGoogleDoc(String googleDocId, List<Object> requests) {
        try {
            String endpoint = 'https://docs.googleapis.com/v1/documents/' + googleDocId + '/:batchUpdate';
            Map<Object, Object> requestBody = new Map<Object, Object>();
            requestBody.put('requests', requests);
            String jsonBody = JSON.serialize(requestBody);
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + authProvider.MVDG__access_token__c);
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000);
            request.setBody(jsonBody);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            

            if (response.getStatusCode() == 401) {
                String refreshToken = refreshAccessToken();
                if (refreshToken != null) {
                    updateGoogleDoc(googleDocId, requests);
                }
            } else if (response.getStatusCode() == 403 && authProvider.SetupOwnerId != null && authProvider.SetupOwnerId != UserInfo.getOrganizationId()) {
                authProvider = [SELECT SetupOwnerId, MVDG__ClientId__c, MVDG__ClientSecret__c, MVDG__access_token__c, MVDG__refresh_token__c FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() AND MVDG__WorkingStatus__c = TRUE WITH SECURITY_ENFORCED];
                refreshToken = authProvider.SetupOwnerId;
                updateGoogleDoc(googleDocId, requests);
            }
            if (response.getStatusCode() != 200 && response.getStatusCode() != 201 && response.getStatusCode() != 202 && response.getStatusCode() != 204 && response.getStatusCode() != 206) {
                responseList.put('updateGoogleDoc', response);
            }
        } catch (Exception e) {
            
            Log_Handler.store_Exception(e,'GoogleDocPreview','updateGoogleDoc');
        }
    }

    /**
    * Method Name : getPDF
    * @description : get pdf blob of updated google doc.
    * @param googleDocId google Document Id - String
    * @param format file format - String
    * @return Blob of the Google Doc - Blob.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static Blob getPDF(String googleDocId, String format) {
        try {
            String endpoint = 'https://www.googleapis.com/drive/v3/files/' + googleDocId + '/export';
            Map<String, String> params = new Map<String, String>();
            if (format == '.pdf') {
                params.put('mimeType', 'application/pdf');
            } else if (format == '.docx') {
                params.put('mimeType', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
            }
            String paramString = '';
            for (String key : params.keySet()) {
                if (!String.isEmpty(paramString)) {
                    paramString += '&';
                }
                paramString += EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8');
            }
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint + '?' + paramString);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + authProvider.MVDG__access_token__c);
            request.setTimeout(120000);
            Http http = new Http();
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                return response.getBodyAsBlob();
            } else if (response.getStatusCode() == 401) {

                String refreshToken = refreshAccessToken();
                if (refreshToken != null) {
                    Blob returnValue = getPDF(googleDocId, format);
                    return returnValue;
                }
            }
            responseList.put('getPDF', response);
            return null;
            // return Blob.valueOf('error: Get PDF error: Unable to fetch the PDF from Google Drive: ' + String.valueOf(response.getStatusCode()));
        } catch (Exception e) {
            
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'getPDF');
            return null;
            // return Blob.valueOf('errorL Get PDF error: Unable to fetch the PDF from Google Drive: ' + e.getMessage());
        }
    }

    /**
    * Method Name : deleteGoogleDoc
    * @description : Delete cloned google doc.
    * @param googleDocId google Document Id - String
    * @return Status if the document was deleted or not - Boolean.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static Boolean deleteGoogleDoc(String googleDocId) {
        try {
            String endpoint = 'https://www.googleapis.com/drive/v3/files/' + googleDocId;
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('DELETE');
            request.setHeader('Authorization', 'Bearer ' + authProvider.MVDG__access_token__c);
            request.setTimeout(120000);
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 204) {
                //document deleted
                return true;

            } else if (response.getStatusCode() == 401) {
                String refreshToken = refreshAccessToken();
                if (refreshToken != null) {
                    Boolean returnValue = deleteGoogleDoc(googleDocId);
                    return returnValue;
                }
            }
            responseList.put('deleteGoogleDoc', response);
            return false;
        } catch (Exception e) {
            
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'deleteGoogleDoc');
            return false;
        }
    }

    /**
    * Method Name : mapFieldValues
    * @description : Gets the values of all the fields present in the Google Document
    * @param queryObject WrapperClass containing the fields present in the Google Document - String
    * @param objectApiName API name of the Object - String
    * @param recordId recordId of the record - List<Object>
    * @return List of fields mapped with thier values - List<Object>.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    @AuraEnabled
    public static List<Object> mapFieldValues(String queryObject, String objectApiName, String recordId) {
        List<Object> returnList = new List<Object>();
        
        try {
            List<OriginalObjectWrapper> jsObject = new List<OriginalObjectWrapper>();
            jsObject = (List<OriginalObjectWrapper>) JSON.deserialize(queryObject, List<OriginalObjectWrapper>.class);
            Integer tableCount = 1;
            Boolean SignatureImagePresent = false;
            // Check for Custom Keys first
            Set<String> extractedKeys = new Set<String>();
            Set<String> customKeyNames = new Set<String>();
            Set<String> customKeys = new Set<String>();
            List<MVDG__Custom_Key__c> queriedCustomKeys = new List<MVDG__Custom_Key__c>();


            for (OriginalObjectWrapper obj : jsObject) {
                if (obj.objApi == 'Custom Keys') {
                    for (String key : obj.fieldName) {
                        String keyStr = String.valueOf(key);
                        customKeys.add(keyStr);
                        String keyName;

                        if (keyStr.startsWith('{{@CK:')) {
                            keyName = keyStr.substringAfter('{{@CK:').substringBefore('.');
                        } else if (keyStr.startsWith('{{@CKLIST:')) {
                            keyName = keyStr.substringAfter('{{@CKLIST:').substringBefore('.');
                        } else if (keyStr.startsWith('{{@CKTABLE:')) {
                            String temp = keyStr.substringAfter('{{@CKTABLE:').substringBefore('}}').substringBefore(';').substringBefore(':');
                            keyName = temp.contains(':') ? temp.substringBefore(':') : temp;
                        }

                        if (keyName != null) {
                            customKeyNames.add(keyName.trim());
                        }
                    }
                }
            }

            if (!customKeyNames.isEmpty()) {
                queriedCustomKeys = [
                    SELECT Id, MVDG__Custom_Key_Name__c, MVDG__Query__c, MVDG__Object_Name__c
                    FROM MVDG__Custom_Key__c
                    WHERE MVDG__Custom_Key_Name__c IN :customKeyNames
                    WITH SECURITY_ENFORCED
                ];

                Pattern pattern = Pattern.compile('\\{\\{#(.*?)\\}\\}');

                for (MVDG__Custom_Key__c key : queriedCustomKeys) {
                    String queryTemplate = key.MVDG__Query__c;
                    Matcher matcher = pattern.matcher(queryTemplate);

                    while (matcher.find()) {
                        extractedKeys.add('{{#' + matcher.group(1) + '}}');
                    }
                }
            }

            for (OriginalObjectWrapper obj : jsObject) {
                if (obj.objApi == 'General Fields') {

                    Map<String, Map<String, String>> generalFieldValues = new Map<String, Map<String, String>>();
                    generalFieldValues.put('General Fields', DataMappingControllerV2.getMappingKeyVsValue(obj.fieldName, objectApiName, recordId));
                    returnList.add(generalFieldValues);

                } else if (obj.objApi == objectApiName && obj.tableNo == null) {

                    Map<String, Object> objectFieldValues = new Map<String, Object>();
                    if(extractedKeys.size() > 0) obj.fieldName.addAll(extractedKeys);
                    Map<String,String> objMappingValues = DataMappingControllerV2.getMappingKeyVsValue(obj.fieldName, objectApiName, recordId);
                    objectFieldValues.put('Object Fields', true);
                    objMappingValues.putAll(DataMappingControllerV2.collectCustomKeys(objMappingValues, queriedCustomKeys, extractedKeys, customKeys));
                    objectFieldValues.put(objectApiName, objMappingValues);
                    returnList.add(objectFieldValues);
                    
                } else if (obj.objApi == 'Signature Image') {
                    signatureImagePresent = true;

                } else if (tableCount <= 10) {
                    // query for every child
                    if (obj.fieldName.size() > 0) {
                        Set<String> mappingFields = new Set<String>();
                        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                        if (!schemaMap.containsKey(obj.objApi)) {
                            continue;
                        }
                        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(obj.objApi).getDescribe().fields.getMap();

                        for (String fieldName : obj.fieldName) {
                            String fieldNameWithoutQuotes = fieldName.substringBetween('{{!', '}}');
                            if (fieldMap.containsKey(fieldNameWithoutQuotes)) {
                                mappingFields.add(fieldNameWithoutQuotes);
                            }
                        }

                        String subQuery;
                        subQuery = '(SELECT ' + String.escapeSingleQuotes(String.join(mappingFields, ',')) + ' FROM ' + String.escapeSingleQuotes(obj.childRelation);

                        if (obj.filter != null) {
                            subQuery += ' ' + String.escapeSingleQuotes(obj.filter);
                        }
                        if (obj.queryLimit != null && obj.queryLimit < 50 && obj.queryLimit > 0) {
                            subQuery += ' LIMIT ' + String.valueOf(obj.queryLimit);
                        } else {
                            subQuery += ' LIMIT 50';
                        }
                        subQuery += ')';
                        
                        String query;
                        query = 'SELECT ' + String.escapeSingleQuotes(subQuery) + ' FROM ' + String.escapeSingleQuotes(objectApiName) + ' WHERE Id =: recordId';
                        List<SObject> childRecords = queryChildObject(query, recordId);

                        if (childRecords.size() > 0 && childRecords[0].getPopulatedFieldsAsMap().get(obj.childRelation) != null) {
                            Map<String, List<Object>> allRecords = new Map<String, List<Object>>();
                            allRecords.put(obj.objApi + String.valueOf(obj.tableNo), (List<Object>) childRecords[0].getPopulatedFieldsAsMap().get(obj.childRelation));
                            returnList.add(allRecords);
                        }
                    }
                    tableCount++;
                }
            }
            if (SignatureImagePresent) {
                Map<String,Object> signatureImage = new Map<String,Object>();
                signatureImage = getSignatureImage(recordId);
                returnList.add(signatureImage);
            }
        } catch (Exception e) {
            
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'mapFieldValues');
            returnList.add(new Map<String,String>{'Error' => e.getMessage()});
        }
        return returnList;
    }

    /**
    * Method Name : getSignatureImage
    * @description : Call this method to get pdf of google doc.
    * @param recordId recordId for the object record - String
    * @return Map of the public URL of the signature image - Map<String, Object>.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static Map<String, Object> getSignatureImage(String recordId) {
        Map<String, Object> salesforceImageValues = new Map<String, Object>();
        try {    
            List<ContentDocument> signatureImage = [SELECT Id, Title, LatestPublishedVersionId, (SELECT Id, ContentDownloadUrl FROM ContentDistributions LIMIT 1) FROM ContentDocument 
            WHERE LatestPublishedVersion.FirstPublishLocationId =: recordId AND LatestPublishedVersion.Title LIKE '%Signature-%' AND LatestPublishedVersion.FileType != 'PDF' WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
            
            if (!signatureImage.isEmpty()) {
                List<contentDistribution> contentDistributions = new List<contentDistribution>();

                for (ContentDocument cd : signatureImage) {
                    List<ContentDistribution> existingDistributions = cd.ContentDistributions;
                    
                    if (existingDistributions.isEmpty()) {
                        ContentDistribution cdt = new ContentDistribution();
                        cdt.Name = cd.Title;
                        cdt.ContentVersionId = cd.LatestPublishedVersionId;
                        cdt.PreferencesAllowViewInBrowser = true;
                        contentDistributions.add(cdt);

                    } else {
                        salesforceImageValues.put('Signature Image', existingDistributions);
                        return salesforceImageValues;
                    }
                }
                
                if (contentDistributions.size() > 0 && Schema.sObjectType.ContentDistribution.isCreateable() && Schema.sObjectType.ContentDistribution.fields.ContentVersionId.isCreateable() && Schema.sObjectType.ContentDistribution.fields.Name.isCreateable() && Schema.sObjectType.ContentDistribution.fields.PreferencesAllowViewInBrowser.isCreateable()) {
                    Database.SaveResult[] results = Database.insert(contentDistributions, false);

                    String requiredId = '';
                    for (Integer i = 0; i < results.size(); i++) {
                        if (results[i].isSuccess()) {
                            requiredId = (String) contentDistributions[i].Id;
                            break;
                        }
                    }
                    if (String.isNotBlank(requiredId)) {
                        ContentDistribution existingDistributions = [SELECT Id, ContentDownloadUrl FROM ContentDistribution WHERE Id = :requiredId WITH SECURITY_ENFORCED];
                        salesforceImageValues.put('Signature Image', existingDistributions);
                    }
                }
            }
        } catch (Exception e) {
            
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'getSignatureImage');
        }
        return salesforceImageValues;
    }

    /**
    * Method Name : queryChildObject
    * @description : Executes the query
    * @param query The query in string formt - String
    * @param recordId recordId for the object record - String
    * @return The query results - List<SObject>.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static List<SObject> queryChildObject(String query, String recordId) {
        try {
            return Database.query(String.escapeSingleQuotes(query));
        } catch (Exception e) {
            
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'queryChildObject');
        }
        return null;
    }

    /**
    * Method Name : getAuthProviderSettings
    * @description : Gets the authProviderSettings Custom Settings record
    * @return the custom setting record - MVDG__Google_Credentials__c.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static MVDG__Google_Credentials__c getAuthProviderSettings() {
        try {
            List<MVDG__Google_Credentials__c> aps = new List<MVDG__Google_Credentials__c>();
            // User
            aps = [SELECT SetupOwnerId, MVDG__ClientId__c, MVDG__ClientSecret__c, MVDG__access_token__c, MVDG__refresh_token__c FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getUserId() AND MVDG__WorkingStatus__c = TRUE WITH SECURITY_ENFORCED];
            if (aps.size() > 0) {
                return aps[0];
            }
            aps = [SELECT SetupOwnerId, MVDG__ClientId__c, MVDG__ClientSecret__c, MVDG__access_token__c, MVDG__refresh_token__c FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() AND MVDG__WorkingStatus__c = TRUE WITH SECURITY_ENFORCED];
            if (aps.size() > 0) {
                return aps[0];
            }
        } catch (Exception e) {
            
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'getAuthProviderSettings');
        }
        return authProvider;
    }

    /**
    * Method Name : updateAuthProvider
    * @description : Updates the AuthProviderSettings after the callouts
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static void updateAuthProvider() {
        try {
            if(authProvider.SetupOwnerId == UserInfo.getOrganizationId()){
                authProvider.SetupOwnerId = UserInfo.getOrganizationId();
                upsert as user authProvider;
            } else {    
                update as user authProvider;
            }
        } catch (Exception e) {
            
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'updateAuthProvider');
        }
    }

    /**
    * Method Name : insertResponses
    * @description : Inserts the HTTP responses if the HTTP callout had failed
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static void insertResponses() {
        try {
            Response_Handler.store_All_Callout_Response_Map(responseList, 'GoogleDocPreview');
        } catch (Exception e) {
            
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'insertResponses');
        }
    }


    /** 
     * Method Name : fetchAllRecordIds 
     * @description : This method is used to fetch all the record ids of the related object
     */
    @AuraEnabled
    public static List<String> fetchAllRecordIds(String RelatedRecordId, String objectname, String relationshipName) {
        try {
            if (RelatedRecordId != null && objectname != null) {
                List<String> recordIds = new List<String>();
                String query = 'SELECT (SELECT ID FROM '+ relationshipName + ' LIMIT 20) FROM '+ objectname +' WHERE ID = \'' + RelatedRecordId + '\' WITH USER_MODE';
                List<SObject> records = Database.query(query);
                if (!records.isEmpty()) {
                    SObject parentRecord = records[0];
    
                    // Access child records dynamically via getSObjects()
                    List<SObject> children = parentRecord.getSObjects(relationshipName);
                    if (children != null) {
                        for (SObject child : children) {
                            if (child.get('Id') != null) {
                                recordIds.add((String)child.get('Id'));
                            }
                        }
                    }
                }
                return recordIds;
            }
            return null;
        } catch (Exception e) {
            System.debug('Excetpion in fetchAllRecordIds method : ' + e.getMessage() + '\n' + 'Line Number :');
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'fetchAllRecordIds');
            return null;
        }
    }


    /** 
     * Method Name : getFileNames 
     * @description : Map to get all the file names of the related object
     */
    @AuraEnabled
    public static Map<Id, String> getFileNames(List<Id> recordIds, String sObjectType, String fileName, String parentsObject) {
        Map<Id, String> resultMap = new Map<Id, String>();


        if (recordIds == null || recordIds.isEmpty() || String.isBlank(sObjectType)) {
            return resultMap;
        }

        System.debug(fileName);
        if (fileName == null || fileName == '') {
            for (Id recordId : recordIds) {
                resultMap.put(recordId, 'Untitled');
            }
            return resultMap;
        }

        Set<String> fieldNames = new Set<String>();
        Pattern fieldPattern = Pattern.compile('\\{\\{#(.*?)\\}\\}');
        Matcher matcher = fieldPattern.matcher(fileName);

        while (matcher.find()) {
            String field = matcher.group(1);
            if (field == 'currentObjName') {
                fileName = fileName.replace('{{#currentObjName}}', sObjectType);
            } else if (field == 'parentObjName') {
                fileName = fileName.replace('{{#parentObjName}}', parentsObject);
            } else {
                fieldNames.add(field);
            }
        }
        
        fieldNames.add('Id');
        Boolean shouldTrim = fieldNames.size() > 5;


        String soql = 'SELECT ' + String.join(new List<String>(fieldNames), ', ') +
                  ' FROM ' + sObjectType + ' WHERE Id IN :recordIds WITH USER_MODE';

        List<SObject> records = Database.query(soql);


        for (SObject rec : records) {
            String fileNames = fileName;
            for (String fieldName : fieldNames) {
                Object value = rec.get(fieldName);
                String strValue = value != null ? String.valueOf(value) : '';
                if (shouldTrim && strValue.length() > 3) {
                    strValue = strValue.substring(0, 3);
                }
                fileNames = fileNames.replace('{{#' + fieldName + '}}', strValue);
            }
            if(fileNames.length() > 240) {
                fileNames = fileNames.substring(0, 240);
            }
    
            resultMap.put((Id)rec.get('Id'), fileNames);
        }
    
        return resultMap;
    }

    public class OriginalObjectWrapper {
        public String objApi;
        public String childRelation;
        public String filter;
        public Integer queryLimit;
        public List<String> fieldName;
        public Integer tableNo;
    }

    public class ResponseDocumentWrapper {
        @AuraEnabled
        public String document;
        @AuraEnabled
        public Decimal width;
        @AuraEnabled
        public String error;
    } 
}