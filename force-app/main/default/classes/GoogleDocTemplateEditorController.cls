/**
* Class Name: GoogleDocTemplateEditorController
* Test Class: GoogleDocTemplateEditorControllerTest
* @description: Controller for the GoogleDocTemplateEditor LWC component 
* Date: 14/08/2024
* Created By: Dhairya Koshti
*/
public with sharing class GoogleDocTemplateEditorController {
    public static Map<String, HttpResponse> responseList = new Map<String, HttpResponse>();    
    public static List<Google_Credentials__c> authProvider = new List<Google_Credentials__c>();

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
            

        } catch (Exception e) {
            
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
            List<Google_Credentials__c> authProvider = new List<Google_Credentials__c>();
            authProvider = [SELECT Id, SetupOwnerId, access_token__c, refresh_token__c, ClientId__c, ClientSecret__c FROM Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getUserId() AND WorkingStatus__c = TRUE WITH SECURITY_ENFORCED];
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
            request.setHeader('Authorization', 'Bearer ' + authProvider[0].access_token__c);

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                return JSON.serialize(responseMap.get('files'));
            } else if (response.getStatusCode() == 401) {
                
                response = refreshAccessToken(authProvider[0], request);
                if (response.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    return JSON.serialize(responseMap.get('files'));
                }
            }
            return null;
        } catch (Exception e) {
            
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
            List<Google_Credentials__c> authProvider = new List<Google_Credentials__c>();
            authProvider = [SELECT Id, SetupOwnerId, access_token__c, refresh_token__c, ClientId__c, ClientSecret__c FROM Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getUserId() AND WorkingStatus__c = TRUE WITH SECURITY_ENFORCED];
            if (authProvider.size() == 0) {
                return 'error';   
            }

            String endpoint = 'https://docs.googleapis.com/v1/documents';
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + authProvider[0].access_token__c);
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
    public static HttpResponse refreshAccessToken(Google_Credentials__c settings, HttpRequest requestPending) {
        try {
            
            
            List<AuthProviderSetup__mdt> mdata = AuthProviderSetup__mdt.getAll().values();
            // List<AuthProviderSetup__mdt> mdata = AuthProviderSetup__mdt.getAll().values();
            String endpoint = 'https://oauth2.googleapis.com/token';
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setBody('refresh_token=' + settings.refresh_token__c + '&client_id=' + mdata[0].CID__c + '&client_secret=' + mdata[0].CSEC__c + '&grant_type=refresh_token');
            // request.setBody('refresh_token=' + settings.refresh_token__c + '&client_id=' + mdata[0].CID__c + '&client_secret=' + mdata[0].CSEC__c + '&grant_type=refresh_token');
            Http http = new Http();
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String newToken = (String) jsonResponse.get('access_token');
                if (newToken != null) {
                    settings.access_token__c = newToken;
                    requestPending.setHeader('Authorization', 'Bearer ' + newToken);
                    Http httpPending = new Http();
                    HttpResponse responsePending = httpPending.send(requestPending);
                    upsert as user settings;
                    return responsePending;
                }
            }
            
            
            
        } catch (Exception e) {
            
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
            // templateData.MVDG__Google_Doc_WebViewLink__c += '&access_token='+ Google_Credentials__c.getInstance().access_token__c;
            if (templateData.size() > 0) {
                return JSON.serialize(templateData[0]);
            }
        } catch (Exception e) {
            
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
            template = [SELECT Id, MVDG__Template_Name__c, MVDG__Description__c, MVDG__Template_Status__c, MVDG__Object_API_Name__c, MVDG__Template_Type__c, CreatedDate, LastModifiedDate, CreatedBy.Name, LastModifiedBy.Name FROM MVDG__Template__c WHERE Id = :templateId WITH SECURITY_ENFORCED];
            if (template.size() > 0) {
                return JSON.serialize(template[0]);
            }
        } catch (Exception e) {
            
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
            Google_Credentials__c authProvider = [SELECT Id, Name, access_token__c, email__c, photolink__c, username__c FROM Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getUserId()];

            Map<String, String> profile = new Map<String, String>();
            profile.put('username', authProvider.username__c);
            profile.put('email', authProvider.email__c);
            profile.put('photolink', authProvider.photolink__c);

            return JSON.serialize(profile);
        } catch (Exception e) {
            
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
    public static Boolean editTemplate(String templateRecord) {
        try {
            Map<String,String> templateRec = (Map<String,String>) JSON.deserialize(templateRecord, Map<String,String>.class);
            MVDG__Template__c template = new MVDG__Template__c();

            if (templateRec.containsKey('templateId')) {
                template.Id = templateRec.get('templateId');
                template.MVDG__Template_Name__c = templateRec.get('templateName');
                template.MVDG__Template_Status__c = Boolean.valueOf(templateRec.get('templateStatus'));
                template.MVDG__Description__c = templateRec.get('templateDescription');
                update as user template; 
                return true;
            } 

        } catch (Exception e) {
            
            Log_Handler.store_Exception(e, 'GoogleDocTemplateEditorController', 'editTemplate');
        }
        return false;
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
            upsert as user authProvider;
        } catch (Exception e) {
            
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
            Response_Handler.store_All_Callout_Response_Map(responseList, 'GoogleDocTemplateEditorController');
        } catch (Exception e) {
            
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
