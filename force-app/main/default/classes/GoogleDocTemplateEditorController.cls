/**
* Class Name: GoogleDocTemplateEditorController
* Test Class: GoogleDocTemplateEditorControllerTest
* @description: Controller for the GoogleDocTemplateEditor LWC component 
* Date: 14/08/2024
* Created By: Dhairya Koshti
*/
public with sharing class GoogleDocTemplateEditorController {
    public static Map<String, HttpResponse> responseList = new Map<String, HttpResponse>();    
    public static List<MVDG__AuthProviderSettings__c> authProvider = new List<MVDG__AuthProviderSettings__c>();

     /**
    * Method Name : getAllData
    * @description : Used to get all the data related to template and template data
    * @param templateId templateId for the template - String
    * @param objectName API name of the source object - String
    * @return All the related data in form of a - ResponseWrapper.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    @AuraEnabled
    public static ResponseWrapper getAllData(String templateId, String objectName){
        ResponseWrapper response = new ResponseWrapper();
        try {
            String docsList = getAllDocs();
            if (docsList != null && docsList.contains('error')) {
                response.error = 'Error:getAllDocs:No Google Integration Found. Please integrate with Google Drive to edit template.:-';
            } else {
                response.docList = docsList;
            }

            response.template = getTemplate(templateId);
            response.templateData = getTemplateData(templateId);
            response.profileData = getGoogleProfile();
            response.objectLabel = getLabel(objectName);
            System.debug('response==>' + response);

        } catch (Exception e) {
            System.debug('Error: '+e.getMessage());
            response.error = e.getMessage();
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'getAllData');
        }
        return response;
    }

    /**
    * Method Name : getAllDocs
    * @description : Get all the documents in the Google Drive
    * @return All the google doc template accessible by the User -String.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static String getAllDocs() {
        try {
            String endpoint = 'https://www.googleapis.com/drive/v3/files';
            List<MVDG__AuthProviderSettings__c> authProvider = new List<MVDG__AuthProviderSettings__c>();
            authProvider = [SELECT Id, SetupOwnerId, MVDG__access_token__c, MVDG__refresh_token__c, MVDG__ClientId__c, MVDG__ClientSecret__c FROM MVDG__AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId() AND MVDG__WorkingStatus__c = TRUE WITH SECURITY_ENFORCED];
            if (authProvider == null || authProvider.size() == 0) {
                return 'error';   
            }
            
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
            request.setHeader('Authorization', 'Bearer ' + authProvider[0].MVDG__access_token__c);

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                return JSON.serialize(responseMap.get('files'));
            } else if (response.getStatusCode() == 401) {
                System.debug('Here is some error 401');
                response = refreshAccessToken(authProvider[0], request);
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

    /**
    * Method Name : createNewDocument
    * @description : Used to create a new google document in the users google drive 
    * @return Return the response for the API callout - String.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    @AuraEnabled
    public static String createNewDocument() {
        try {
            List<MVDG__AuthProviderSettings__c> authProvider = new List<MVDG__AuthProviderSettings__c>();
            authProvider = [SELECT Id, SetupOwnerId, MVDG__access_token__c, MVDG__refresh_token__c, MVDG__ClientId__c, MVDG__ClientSecret__c FROM MVDG__AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId() AND MVDG__WorkingStatus__c = TRUE WITH SECURITY_ENFORCED];
            if (authProvider.size() == 0) {
                return 'error';   
            }

            String endpoint = 'https://docs.googleapis.com/v1/documents';
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + authProvider[0].MVDG__access_token__c);
            request.setBody('{"title": "New Untitled Document"}');

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                return JSON.serialize(responseMap);
            } else if (response.getStatusCode() == 401) {
                response = refreshAccessToken(authProvider[0], request);
                if (response.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    return JSON.serialize(responseMap);
                }
            }
            return null;
        } catch (Exception e) {
            System.debug('Error In createNewDocument ==> ' + e.getMessage() + e.getLineNumber());
            Log_Handler.store_exception(e, 'GoogleDocTemplateEditorController', 'createNewDocument');
            return null;
        }
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
    public static HttpResponse refreshAccessToken(MVDG__AuthProviderSettings__c settings, HttpRequest requestPending) {
        try {
            
            System.debug('Refresh Access token');
            List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();
            // List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();
            String endpoint = 'https://oauth2.googleapis.com/token';
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setBody('refresh_token=' + settings.MVDG__refresh_token__c + '&client_id=' + mdata[0].MVDG__CID__c + '&client_secret=' + mdata[0].MVDG__CSEC__c + '&grant_type=refresh_token');
            // request.setBody('refresh_token=' + settings.MVDG__refresh_token__c + '&client_id=' + mdata[0].MVDG__CID__c + '&client_secret=' + mdata[0].MVDG__CSEC__c + '&grant_type=refresh_token');
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String newToken = (String) jsonResponse.get('access_token');
                if (newToken != null) {
                    if (Schema.sObjectType.MVDG__AuthProviderSettings__c.fields.MVDG__access_token__c.isUpdateable()) {
                        settings.MVDG__access_token__c = newToken;
                    }
                    requestPending.setHeader('Authorization', 'Bearer ' + newToken);
                    Http httpPending = new Http();
                    HttpResponse responsePending = httpPending.send(requestPending);
                    if (Schema.sObjectType.MVDG__AuthProviderSettings__c.isAccessible() && Schema.sObjectType.MVDG__AuthProviderSettings__c.isUpdateable() && Schema.sObjectType.MVDG__AuthProviderSettings__c.isCreateable()) {
                        upsert settings;
                    }
                    return responsePending;
                }
            }
            
            System.debug('Token refresh failed. Status Code: ' + response.getStatusCode());
            System.debug('Response Body: ' + response.getBody());
        } catch (Exception e) {
            System.debug('Error In get refreshAccessToken ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'refreshAccessToken');
        }
        return null;
    }

    /**
    * Method Name : getTemplateData
    * @description : Used to get all the template data related to the data
    * @param templateId templateId for the template - String
    * @return returns the first template data - String.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static String getTemplateData(String templateId) {
        try {
            List<MVDG__Template_Data__c> templateData = new List<MVDG__Template_Data__c>();
            templateData = [SELECT MVDG__Google_Doc_WebViewLink__c, MVDG__Google_Doc_Template_Id__c FROM MVDG__Template_Data__c WHERE MVDG__Template__c = :templateId AND MVDG__Order_No_Simple__c = 1 WITH SECURITY_ENFORCED];
            // templateData.MVDG__Google_Doc_WebViewLink__c += '&access_token='+ MVDG__AuthProviderSettings__c.getInstance().MVDG__access_token__c;
            if (templateData.size() > 0) {
                return JSON.serialize(templateData[0]);
            }
        } catch (Exception e) {
            System.debug('Error In getTemplateData ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'getTemplateData');
        }
        return null;
    }

    /**
    * Method Name : getTemplate
    * @description : Used to get all the data template record
    * @param templateId templateId for the template - String
    * @return return the template - String.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static String getTemplate(string templateId) {
        try {
            List<MVDG__Template__c> template = new List<MVDG__Template__c>();
            template = [SELECT MVDG__Template_Name__c, MVDG__Description__c, Id, MVDG__Template_Status__c, MVDG__Object_API_Name__c, MVDG__Template_Type__c, CreatedDate, LastModifiedDate, CreatedBy.Name, LastModifiedBy.Name FROM MVDG__Template__c WHERE Id = :templateId WITH SECURITY_ENFORCED];
            if (template.size() > 0) {
                return JSON.serialize(template[0]);
            }
        } catch (Exception e) {
            System.debug('Error In getTemplate ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'getTemplate');
        }
        return null;
    }

    /**
    * Method Name : getGoogleProfile
    * @description : Get the Username and photo stored in the custom settings
    * @return returns a object for integrated user details - String.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static string getGoogleProfile() {
        try {
            MVDG__AuthProviderSettings__c authProvider = [SELECT Id, Name, MVDG__access_token__c, MVDG__email__c, MVDG__photolink__c, MVDG__username__c FROM MVDG__AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId()];

            Map<String, String> profile = new Map<String, String>();
            profile.put('username', authProvider.MVDG__username__c);
            profile.put('email', authProvider.MVDG__email__c);
            profile.put('photolink', authProvider.MVDG__photolink__c);

            return JSON.serialize(profile);
        } catch (Exception e) {
            System.debug('Error In getGoogleProfile ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'getUsernameAndEmail');
            return null;
        }
    }

    /**
    * Method Name : getLabel
    * @description : Used to get the label of the object
    * @param objectName API name of the source object - String
    * @return Returns the name of the object - String.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
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

    /**
    * Method Name : editTemplate
    * @description : Used to update the template details
    * @param templateRecord The object details in string - String.
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    @AuraEnabled
    public static void editTemplate(String templateRecord) {
        try {
            MVDG__Template__c template = (MVDG__Template__c) JSON.deserialize(templateRecord, MVDG__Template__c.class);
            if (Schema.sObjectType.MVDG__Template__c.isAccessible() && Schema.sObjectType.MVDG__Template__c.isUpdateable()) {
                update as user template;
            }
        } catch (Exception e) {
            System.debug('Error In editTemplate ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'editTemplate');
        }
    }
    
    /**
    * Method Name : saveTemplateData
    * @description : Used to create a new template data record for the template 
    * @param templateId templateId for the template - String
    * @param googleDocId the google doc id for the selected document - String
    * @param webviewLink the iframe link for the selected google document - String
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    @AuraEnabled
    public static void saveTemplateData(String templateId, String googleDocId, String webViewLink) {
        try {
            MVDG__Template_Data__c templateData = new MVDG__Template_Data__c();
            templateData.MVDG__Google_Doc_Template_Id__c = googleDocId;
            templateData.MVDG__Google_Doc_WebViewLink__c = webViewLink;
            templateData.MVDG__Template__c = templateId;
            templateData.MVDG__Order_No_Simple__c = 1;

            if (Schema.sObjectType.MVDG__Template_Data__c.isAccessible() && Schema.sObjectType.MVDG__Template_Data__c.isCreateable()) {
                insert as user templateData;
            }
        } catch (Exception e) {
            System.debug('Error In saveTemplateData ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'saveTemplateData');
        }
    }

    /**
    * Method Name : updateuthProviderSettings
    * @description : Used to update the custom settings
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static void updateAuthProviderSettings() {
        try {
            if (Schema.sObjectType.MVDG__AuthProviderSettings__c.isUpdateable() && Schema.sObjectType.MVDG__AuthProviderSettings__c.isCreateable()) {
                upsert authProvider;
            }
        } catch (Exception e) {
            System.debug('Error In updateAuthProviderSettings ==> ' + e.getMessage());
            Log_Handler.store_exception(e, 'GoogleDocTemplateEditorController', 'updateAuthProviderSettings');
        }
    }

    /**
    * Method Name : insertRestResponses
    * @description : used to insert any responses in case of API callout falures
    */ 
    /***********************************************************************
    MODIFICATION LOG* 
    * Last Update Date : 03/06/2024
    * Updated By : Developer name
    * Name of methods changed (Comma separated if more then one) : method1 
    * Change Description : 
    ***********************************************************************/
    public static void insertRestResponses() {
        try {
            for (String methodName: responseList.keySet()) {
                Response_Handler.store_Callout_Response(responseList.get(methodName), 'GoogleDocTemplateEditorController', methodName);
            }
        } catch (Exception e) {
            System.debug('Error In insertResponses ==> ' + e.getMessage());
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'insertResponses');
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
