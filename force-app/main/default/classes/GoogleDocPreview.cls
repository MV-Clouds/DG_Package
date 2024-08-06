public with sharing class GoogleDocPreview {
    public static AuthProviderSettings__c authProvider;
    public static List<Template_Data__c> templateData = new List<Template_Data__c>();
    public static Map<String, HttpResponse> responseList = new Map<String, HttpResponse>();
    public static String refreshToken;

    @AuraEnabled
    //main method call this method to get pdf of google doc
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
                return 'error:Get PDF error:Unable to fetch the PDF from Google Drive:-';
            }

        } catch (Exception e) {
            System.debug('Error In doPreview ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocPreview', 'doPreview');
        } finally {
            //delete cloned google doc
            Boolean googleDocDeleted = deleteGoogleDoc(GoogleDocId);
            updateAuthProvider();
            insertResponses();
        }
        return EncodingUtil.base64Encode(pdfBlob);
    }

    //get new access token using refresh token
    public static String refreshAccessToken() {
        try {
            String endpoint = 'https://oauth2.googleapis.com/token';
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setBody(
                'refresh_token=' + authProvider.refresh_token__c + '&client_id=' + authProvider.ClientId__c + '&client_secret=' + authProvider.ClientSecret__c + '&grant_type=refresh_token'
            );
            Http http = new Http();
            HttpResponse response = http.send(request);
            responseList.put('refreshAccessToken', response);
            System.debug('Response of refreshAccessToken: ' + response.getBody());
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String newToken = (String) jsonResponse.get('access_token');
                if (newToken != null) {
                    authProvider.access_token__c = newToken;
                }
                return newToken;
            }
            return 'error:Access Token Error:Error in getting access token:' + String.valueOf(response.getStatusCode());
        } catch (Exception e) {
            System.debug('Error In refreshAccessToken ==> ' + e.getMessage() + e.getLineNumber());
            Log_Handler.store_Exception(e, 'GoogleDocPreview', 'refreshAccessToken');
            return 'error:Access Token Error:Error in getting access token:' + e.getMessage();
        }
    }

    //get google doc  in json format
    @AuraEnabled
    public static String getDocument(String googleDocId, String templateId) {
        try {
            String endpoint = 'https://docs.googleapis.com/v1/documents/' + googleDocId;
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + authProvider.access_token__c);
            request.setTimeout(20000);
            Http http = new Http();
            HttpResponse response = http.send(request);
            responseList.put('getDocument', response);
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
            return 'error:Get Document Error:Error in getting document:' + String.valueOf(response.getStatusCode());
            
        } catch (Exception e) {
            System.debug('Error In getDocument ==> ' + e.getMessage() + e.getLineNumber());
            Log_Handler.store_Exception(e, 'GoogleDocPreview', 'getDocument');
            return 'error:Get Document Error:Error in getting document:' + e.getMessage();
        }
    }

    //clone google doc in users account
    @AuraEnabled
    public static ResponseDocumentWrapper copyGoogleDoc(String templateId) {
        ResponseDocumentWrapper responseWrapper = new ResponseDocumentWrapper();
        try {
            if (refreshToken == null) {
                authProvider = getAuthProviderSettings();
            }
            templateData = [SELECT Google_Doc_Template_Id__c, Template__r.Signature_Size__c FROM Template_Data__c WHERE Template__c = :templateId WITH SECURITY_ENFORCED ORDER BY Order_No_Simple__c ASC];

            if (templateData.size() == 0) {
                responseWrapper.error = 'warning:Template Error:No Google Document linked with this template.:-';
                return responseWrapper;
                
            }
            responseWrapper.width = templateData[0].Template__r.Signature_Size__c;

            // Callout
            String googleDocId = templateData[0].Google_Doc_Template_Id__c;
            String endpoint = 'https://www.googleapis.com/drive/v3/files/' + googleDocId + '/copy';
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('name', 'CopyOf' + googleDocId);
            String jsonBody = JSON.serialize(requestBody);
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + authProvider.access_token__c);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(jsonBody);
            Http http = new Http();
            HttpResponse response = http.send(request);
            responseList.put('copyGoogleDoc', response);
            System.debug('Response of copyGoogleDoc==>' + response);
            if (response.getStatusCode() == 200) {

                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String documentID = String.valueOf(responseMap.get('id'));
                responseWrapper.document = getDocument(documentID, templateId);
                return responseWrapper;

            } else if (response.getStatusCode() == 401) {
                refreshToken = refreshAccessToken();
                if (refreshToken != null) {
                    responseWrapper = copyGoogleDoc(templateId);
                    return responseWrapper;
                }
            }
            responseWrapper.error = 'error:Copy Google Doc:Error in processing the document:' + String.valueOf(response.getStatusCode());
            return responseWrapper;
        } catch (Exception e) {
            responseWrapper.error = 'error:Copy Google Doc:Error in processing the document:' + e.getMessage();
            Log_Handler.store_Exception(e, 'GoogleDocPreview', 'copyGoogleDoc');
            
            System.debug('Error In copyGoogleDoc ==> ' + e.getMessage() + e.getLineNumber());
        }
        updateAuthProvider();
        insertResponses();
        return responseWrapper;
    }

    //update google doc api callout
    public static void updateGoogleDoc(String googleDocId, List<Object> requests) {
        try {
            String endpoint = 'https://docs.googleapis.com/v1/documents/' + googleDocId + '/:batchUpdate';
            Map<Object, Object> requestBody = new Map<Object, Object>();
            requestBody.put('requests', requests);
            String jsonBody = JSON.serialize(requestBody);
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Authorization', 'Bearer ' + authProvider.access_token__c);
            request.setHeader('Content-Type', 'application/json');
            request.setBody(jsonBody);
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            responseList.put('updateGoogleDoc', response);
            System.debug('Response of UpdateGoogleDoc==>' + response.getBody());

            if (response.getStatusCode() == 401) {
                String refreshToken = refreshAccessToken();
                if (refreshToken != null) {
                    updateGoogleDoc(googleDocId, requests);
                }
            }
        } catch (Exception e) {
            System.debug('Error In updateDoc ==> ' + e.getMessage());
            Log_Handler.store_Exception(e,'GoogleDocPreview','updateGoogleDoc');
        }
    }

    //get pdf blob of updated google doc
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
            request.setHeader('Authorization', 'Bearer ' + authProvider.access_token__c);
            Http http = new Http();
            HttpResponse response = http.send(request);
            responseList.put('getPDF', response);
            if (response.getStatusCode() == 200) {
                return response.getBodyAsBlob();
            } else if (response.getStatusCode() == 401) {

                String refreshToken = refreshAccessToken();
                if (refreshToken != null) {
                    Blob returnValue = getPDF(googleDocId, format);
                    return returnValue;
                }
            }
            return null;
            // return Blob.valueOf('error: Get PDF error: Unable to fetch the PDF from Google Drive: ' + String.valueOf(response.getStatusCode()));
        } catch (Exception e) {
            System.debug('Error In updateDoc ==> ' + e.getMessage() + e.getLineNumber());
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'getPDF');
            return null;
            // return Blob.valueOf('errorL Get PDF error: Unable to fetch the PDF from Google Drive: ' + e.getMessage());
        }
    }

    //delete cloned google doc
    public static Boolean deleteGoogleDoc(String googleDocId) {
        try {
            String endpoint = 'https://www.googleapis.com/drive/v3/files/' + googleDocId;
            Map<String, String> params = new Map<String, String>();
            String paramString = '';
            for (String key : params.keySet()) {
                if (!String.isEmpty(paramString)) {
                    paramString += '&';
                }
                paramString += EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8');
            }
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint + '?' + paramString);
            request.setMethod('DELETE');
            request.setHeader('Authorization', 'Bearer ' + authProvider.access_token__c);
            Http http = new Http();
            HttpResponse response = http.send(request);
            responseList.put('deleteGoogleDoc', response);
            System.debug('ResponseBody of delete google doc=>' + response.getBody());
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
            return false;
        } catch (Exception e) {
            System.debug('Error In deleteGoogleDoc ==> ' + e.getMessage() + e.getLineNumber());
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'deleteGoogleDoc');
            return false;
        }
    }

    @AuraEnabled
    public static List<Object> mapFieldValues(String queryObject, String objectApiName, String recordId) {
        List<Object> returnList = new List<Object>();
        System.debug('templateData==>' + templateData);
        try {
            List<OriginalObjectWrapper> jsObject = new List<OriginalObjectWrapper>();
            jsObject = (List<OriginalObjectWrapper>) JSON.deserialize(queryObject, List<OriginalObjectWrapper>.class);
            String query;
            Integer tableCount = 1;
            
            for (OriginalObjectWrapper obj : jsObject) {
                if (obj.objApi == 'General Fields') {

                    Map<String, Map<String, String>> generalFieldValues = new Map<String, Map<String, String>>();
                    generalFieldValues.put('General Fields', DataMappingControllerV2.getMappingKeyVsValue(obj.fieldName, objectApiName, recordId));
                    returnList.add(generalFieldValues);

                } else if (obj.objApi == objectApiName) {

                    Map<String, Map<String, String>> objectFieldValues = new Map<String, Map<String, String>>();
                    objectFieldValues.put(objectApiName, DataMappingControllerV2.getMappingKeyVsValue(obj.fieldName, objectApiName, recordId));
                    returnList.add(objectFieldValues);
                    
                } else if (obj.objApi == 'Signature Image') {

                    Map<String,Object> signatureImage = new Map<String,Object>();
                    signatureImage = getSignatureImage(recordId);

                    returnList.add(signatureImage);

                } else if (tableCount <= 10) {
                    // query for every child
                    if (obj.fieldName.size() > 0) {
                        Set<String> mappingFields = new Set<String>();
                        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(obj.objApi).getDescribe().fields.getMap();

                        for (String fieldName : obj.fieldName) {
                            if (fieldMap.containsKey(fieldName)) {
                                mappingFields.add(fieldName);
                            }
                        }

                        String subQuery;
                        subQuery = '(SELECT ' + String.escapeSingleQuotes(String.join(mappingFields, ',')) + ' FROM ' + String.escapeSingleQuotes(obj.childRelation);

                        if (obj.filter != null) {
                            subQuery += ' WHERE ' + String.escapeSingleQuotes(obj.filter);
                        }

                        if (obj.queryLimit != null) {
                            subQuery += ' LIMIT ' + String.escapeSingleQuotes(obj.queryLimit);
                        } else {
                            subQuery += ' LIMIT 50';
                        }

                        subQuery += ')';
                        
                        query = 'SELECT ' + String.escapeSingleQuotes(subQuery) + ' FROM ' + String.escapeSingleQuotes(objectApiName) + ' WHERE Id =: recordId';
                        List<SObject> childRecords = queryChildObject(query, recordId);

                        if (childRecords.size() > 0 && childRecords[0].getPopulatedFieldsAsMap().get(obj.childRelation) != null) {
                            Map<String, List<Object>> allRecords = new Map<String, List<Object>>();
                            allRecords.put(obj.objApi + String.valueOf(tableCount), (List<Object>) childRecords[0].getPopulatedFieldsAsMap().get(obj.childRelation));
                            returnList.add(allRecords);
                        }
                    }
                    tableCount++;
                }
            }
        } catch (Exception e) {
            System.debug('Error In mapFieldValues ==> ' + e.getMessage() + e.getLineNumber());
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'mapFieldValues');
        }
        return returnList;
    }

    public static Map<String, Object> getSignatureImage(String recordId) {
        Map<String, Object> salesforceImageValues = new Map<String, Object>();
        try {    
            List<ContentDocument> signatureImage = [SELECT Id, Title, LatestPublishedVersionId, (SELECT Id, ContentDownloadUrl FROM ContentDistributions LIMIT 1) FROM ContentDocument 
            WHERE LatestPublishedVersion.FirstPublishLocationId =: recordId AND LatestPublishedVersion.Title LIKE '%Signature-%' AND LatestPublishedVersion.FileType != 'PDF' WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC];
            
            if (!signatureImage.isEmpty()) {
                List<ContentDistribution> existingDistributions = signatureImage[0].ContentDistributions;
                
                if (existingDistributions.isEmpty()) {
                    ContentDistribution cdt = new ContentDistribution();
                    cdt.Name = signatureImage[0].Title;
                    cdt.ContentVersionId = signatureImage[0].LatestPublishedVersionId;
                    cdt.PreferencesAllowViewInBrowser = true;

                    if (Schema.sObjectType.ContentDistribution.isAccessible() && Schema.sObjectType.ContentDistribution.isCreateable()) {
                        insert cdt;
                        existingDistributions = [SELECT Id, ContentDownloadUrl FROM ContentDistribution WHERE Id = :cdt.Id WITH SECURITY_ENFORCED];
                    }
                }
                
                salesforceImageValues.put('Signature Image', existingDistributions);
            }
        } catch (Exception e) {
            System.debug('Error In getSignatureImage ==> ' + e.getMessage() + e.getLineNumber());
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'getSignatureImage');
        }
        return salesforceImageValues;
    }

    public static List<SObject> queryChildObject(String query, String recordId) {
        try {
            return Database.query(String.escapeSingleQuotes(query));
        } catch (Exception e) {
            System.debug('Error In queryChildObject ==>'+ e.getMessage() + e.getLineNumber());
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'queryChildObject');
        }
        return null;
    }

    public static void mailMessage(Integer code, String fileName){
        String emailBody;
        if (code == 400) {
            emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                'We have noticed an issue while attempting to generate a preview for  ' + fileName + '.\n\n' +
                'To resolve this issue, please ensure that your credentials are correct. If the problem persists, try the following steps:\n\n' +
                '1. Remove the existing Google Drive connection.\n' +
                '2. Reconnect to Google Drive.\n\n' +
                'These steps should help resolve the issue. If you continue to experience difficulties, please feel free to contact our support team for further assistance.\n\n' +
                'Thank you for your cooperation.\n\n' +
                'Best regards,\n' +
                'DocGenius';
        }
        else if (code == 401) {
            emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                'We have noticed an issue while attempting to generate a preview for ' + fileName + ' to Google Drive.\n\n' +
                'To resolve this issue, please follow these steps to reconnect:\n\n' +
                '1. Remove the existing Google Drive connection.\n' +
                '2. Reconnect to Google Drive.\n\n' +
                'These steps should help re-establish the connection. If you continue to experience difficulties, please don\'t hesitate to reach out to our support team for further assistance.\n\n' +
                'Thank you for your cooperation.\n\n' +
                'Best regards,\n' +
                'DocGenius';
        }
        else if (code == 404){
            emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                'We have encountered a connection error (404 - File Not Found) while attempting to access your Google Drive.\n\n' +
                'This error indicates that the file or resource you are trying to access may not exist or could not be found. To resolve this issue, please try the following steps:\n\n' +
                '1. Verify that the file or resource exists in your Google Drive.\n' +
                '2. Ensure that the file\'s name and path are correct.\n' +
                '3. Check that you have the necessary permissions to access the file.\n\n' +
                'If the problem persists after following these steps, please feel free to contact our support team for further assistance.\n\n' +
                'Thank you for your cooperation.\n\n' +
                'Best regards,\n' +
                'DocGenius';
        }
        else if (code == 500){
            emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                'We have encountered a server error (500 - Internal Server Error) while attempting to upload your file to Google Drive. This error typically indicates a problem with our server or the service.\n\n' +
                'To resolve this issue, please try the following:\n\n' +
                '1. Wait for a few minutes and try previewing the file again.\n' +
                '2. If the issue persists, it may be due to temporary server problems on google\'s end.\n\n' +
                'If the problem persists after following these steps, please feel free to contact our support team for further assistance.\n\n' +
                'Thank you for your cooperation.\n\n' +
                'Best regards,\n' +
                'DocGenius';
        }
        else if (code != 200 && code != 204) {
            emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                'We have encountered error with code: '+ code + 'while attempting to preview your file' + fileName + ' from Google Drive. \n\n' +
                'To resolve this issue, please try the following:\n\n' +
                '1. Wait for a few minutes and try previewing the file again.\n' +
                '2. If the issue persists, it may be due to temporary server problems on google\'s end.\n\n' +
                'If the problem persists after following these steps, please feel free to contact our support team for further assistance.\n\n' +
                'Thank you for your cooperation.\n\n' +
                'Best regards,\n' +
                'DocGenius';
        }
        System.debug('emailBody==>' + emailBody);
    }

    public static AuthProviderSettings__c getAuthProviderSettings() {
        try {
            List<AuthProviderSettings__c> aps = new List<AuthProviderSettings__c>();
            aps = [SELECT Id, IsDeleted, Name, SetupOwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, ClientId__c, ClientSecret__c, LinkedDate__c, WorkingStatus__c, access_token__c, email__c, photolink__c, refresh_token__c, username__c FROM AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId()];
            if (aps.size() > 0) {
                return aps[0];
            }
            return AuthProviderSettings__c.getOrgDefaults();
        } catch (Exception e) {
            System.debug('Error in getAuthProviderSettings==>' + e.getMessage() + e.getLineNumber());
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'getAuthProviderSettings');
        }
        return authProvider;
    }

    public static void updateAuthProvider() {
        try {
            if(authProvider.SetupOwnerId == UserInfo.getOrganizationId()){
                authProvider.SetupOwnerId = UserInfo.getOrganizationId();
                if (Schema.sObjectType.MVDG__AuthProviderSettings__c.isCreateable() && Schema.sObjectType.MVDG__AuthProviderSettings__c.isUpdateable()) {
                    upsert authProvider;
                }
            } else {    
                if (Schema.sObjectType.MVDG__AuthProviderSettings__c.isUpdateable()) {
                    update authProvider;
                }
            }
        } catch (Exception e) {
            System.debug('Error in updateAuthProvider==>' + e.getMessage() + e.getLineNumber());
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'updateAuthProvider');
        }
    }

    public static void insertResponses() {
        try {
            for (String methodName: responseList.keySet()) {
                Response_Handler.store_Callout_Response(responseList.get(methodName), 'GoogleDocPreview', methodName);
            }
        } catch (Exception e) {
            System.debug('Error In insertResponses ==>'+ e.getMessage() + e.getLineNumber());
            Log_Handler.store_exception(e, 'GoogleDocPreview', 'insertResponses');
        }
    }

    public class OriginalObjectWrapper {
        public String objApi;
        public String childRelation;
        public String filter;
        public String queryLimit;
        public List<String> fieldName;
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