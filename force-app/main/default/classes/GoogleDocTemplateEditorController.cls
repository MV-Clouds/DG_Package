public with sharing class GoogleDocTemplateEditorController {

    @AuraEnabled
    public static ResponseWrapper getAllData(String templateId, String objectName){
        ResponseWrapper response = new ResponseWrapper();
        try {
            response.docList = getAllDocs();
            response.template = getTemplate(templateId);
            response.templateData = getTemplateData(templateId);
            response.profileData = getGoogleProfile();
            response.objectLabel = getLabel(objectName);
            System.debug('response==>' + response);

        } catch (Exception e) {
            System.debug('Error: '+e.getMessage());
            response.error = e.getMessage();
        }
        return response;
    }

    public static String getAllDocs() {
        try {
            String endpoint = 'https://www.googleapis.com/drive/v3/files';
            AuthProviderSettings__c authProvider = new AuthProviderSettings__c();
            authProvider = [SELECT Id, SetupOwnerId, access_token__c, refresh_token__c, ClientId__c, ClientSecret__c FROM AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId()];
            System.debug('authProvider==>' + authProvider);
            Map<String, String> params = new Map<String, String>();

            params.put('q', '(mimeType= "application/vnd.openxmlformats-officedocument.wordprocessingml.document" or mimeType= "application/vnd.google-apps.document") and (trashed=false)');
            params.put('fields', 'files(id,name,webViewLink,createdTime,modifiedTime,size)');

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

            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                return JSON.serialize(responseMap.get('files'));
            } else if (response.getStatusCode() == 401) {
                System.debug('Here is some error 401');
                response = refreshAccessToken(authProvider, request);
                if (response.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    return JSON.serialize(responseMap.get('files'));
                }
            }
            return null;
        } catch (Exception e) {
            System.debug('Error In get all Docs ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'getAllDocs');
            return null;
        }
    }

    private static HttpResponse refreshAccessToken(AuthProviderSettings__c settings, HttpRequest requestPending) {
        System.debug('Refresh Access token');
        String endpoint = 'https://oauth2.googleapis.com/token';
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody('refresh_token=' + settings.refresh_token__c + '&client_id=' + settings.ClientId__c + '&client_secret=' + settings.ClientSecret__c + '&grant_type=refresh_token');

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String newToken = (String) jsonResponse.get('access_token');
            if (newToken != null) {
                if (Schema.sObjectType.MVDG__AuthProviderSettings__c.fields.access_token__c.isUpdateable()) {
                    settings.access_token__c = newToken;
                }
                requestPending.setHeader('Authorization', 'Bearer ' + newToken);
                Http httpPending = new Http();
                HttpResponse responsePending = httpPending.send(requestPending);
                if (Schema.sObjectType.MVDG__AuthProviderSettings__c.isAccessible() && Schema.sObjectType.MVDG__AuthProviderSettings__c.isUpdateable() && Schema.sObjectType.AuthProviderSettings__c.isCreateable()) {
                    upsert settings;
                }
                return responsePending;
            }
        }

        System.debug('Token refresh failed. Status Code: ' + response.getStatusCode());
        System.debug('Response Body: ' + response.getBody());
        return null;
    }

    public static String getTemplateData(String templateId) {
        try {
            Template_Data__c templateData = new Template_Data__c();
            templateData = [SELECT Google_Doc_WebViewLink__c, Google_Doc_Template_Id__c FROM Template_Data__c WHERE Template__c = :templateId AND Order_No_Simple__c = 1 WITH SECURITY_ENFORCED];
            // templateData.Google_Doc_WebViewLink__c += '&access_token='+ AuthProviderSettings__c.getInstance().access_token__c;

            return JSON.serialize(templateData);
        } catch (Exception e) {
            System.debug('Error In getTemplateData ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'getTemplate');
            return null;
        }
    }

    public static String getTemplate(string templateId) {
        try {
            Template__c template = new Template__c();
            template = [SELECT Template_Name__c, Description__c, Id, Template_Status__c, Object_API_Name__c, Template_Type__c, CreatedDate, LastModifiedDate, CreatedBy.Name, LastModifiedBy.Name FROM Template__c WHERE Id = :templateId WITH SECURITY_ENFORCED];
            return JSON.serialize(template);
        } catch (Exception e) {
            System.debug('Error In getTemplate ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'getTemplateName');
            return null;
        }
    }

    @AuraEnabled
    public static string getGoogleProfile() {
        try {
            AuthProviderSettings__c authProvider = [SELECT Id, Name, access_token__c, email__c, photolink__c, username__c FROM AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId()];

            Map<String, String> profile = new Map<String, String>();
            profile.put('username', authProvider.username__c);
            profile.put('email', authProvider.email__c);
            profile.put('photolink', authProvider.photolink__c);

            return JSON.serialize(profile);
        } catch (Exception e) {
            System.debug('Error In getGoogleProfile ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'getUsernameAndEmail');
            return null;
        }
    }
    
    @AuraEnabled
    public static void saveTemplateData(String templateId, String googleDocId, String webViewLink, String documentName) {
        try {
            Template_Data__c templateData = new Template_Data__c();
            templateData.Google_Doc_Template_Id__c = googleDocId;
            templateData.Google_Doc_WebViewLink__c = webViewLink;
            // templateData.Google_Doc_Name__c = documentName;
            templateData.Template__c = templateId;
            templateData.Order_No_Simple__c = 1;

            if (Schema.sObjectType.MVDG__Template_Data__c.isAccessible() && Schema.sObjectType.MVDG__Template_Data__c.isCreateable()) {
                insert templateData;
            }
        } catch (Exception e) {
            System.debug('Error In saveTemplateData ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'saveTemplateData');
        }
    }

    @AuraEnabled
    public static string getLabel(String objectName) {
        try {
            Map<String, Schema.sObjectType> sObjectMap = Schema.getGlobalDescribe();
            string objLabel = sObjectMap.get(objectName).getDescribe().getLabel();
            return objLabel;
        } catch (Exception e) {
            System.debug('Error In getLabel ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'getLabel');
            return null;
        }
    }

    @AuraEnabled
    public static void editTemplate(String templateRecord) {
        try {
            Template__c template = (Template__c) JSON.deserialize(templateRecord, Template__c.class);
            if (Schema.sObjectType.MVDG__Template__c.isAccessible() && Schema.sObjectType.MVDG__Template__c.isUpdateable()) {
                update template;
            } else {
                System.debug('Error In editTemplate ==> Template__c is not accessible or updateable');
            }
        } catch (Exception e) {
            System.debug('Error In editTemplate ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'editTemplate');
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public String objectLabel;
        @AuraEnabled
        public String docList;
        @AuraEnabled
        public String template;
        @AuraEnabled
        public String templateData;
        @AuraEnabled
        public String profileData; 
        @AuraEnabled
        public String error;
    }

}