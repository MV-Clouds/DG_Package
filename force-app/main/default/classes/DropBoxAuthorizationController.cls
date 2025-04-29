/*******************************************************
* Name          : DropBoxAuthorizationController
* Author        : Tirth
* Create Date   : 18/04/2024 
* UsedBy        : integrationDashBoard Component
* Test Class    : DropboxAuthorizationControllerTest
* Description   : Apex Class used for managing integration of Dropbox using Custom Metadata for credentials.
* Company       : MV Clouds
*******************************************************/

public with sharing class DropBoxAuthorizationController {

    @AuraEnabled
    public static Map<String, Object> checkdropboxauth() {
        try {
            List<Dropbox_Credential__mdt> settingsList = [SELECT Id, DeveloperName, MasterLabel, ClientId__c, ClientSecret__c, username__c, LinkedDate__c, email__c, refresh_token__c, access_token__c, WorkingStatus__c 
                                                         FROM Dropbox_Credential__mdt 
                                                         WITH SECURITY_ENFORCED 
                                                         LIMIT 1];
            Map<String, Object> result = new Map<String, Object>();
            if (!settingsList.isEmpty() && settingsList[0].refresh_token__c != null && settingsList[0].access_token__c != null && settingsList[0].LinkedDate__c != null) {
                Dropbox_Credential__mdt settings = settingsList[0];
                Boolean working = verifyAuth();
                result.put('name', settings.username__c);
                result.put('email', settings.email__c);
                result.put('linkdate', settings.LinkedDate__c);
                result.put('active', working);
                return result;
            }
            result.put('error', 'No valid Dropbox credentials found.');
            return result;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'checkdropboxauth');
            return null;
        }
    }

    @AuraEnabled
    public static Boolean verifyAuth() {
        try {
            Dropbox_Credential__mdt settings = [SELECT Id, DeveloperName, MasterLabel, ClientId__c, ClientSecret__c, username__c, LinkedDate__c, email__c, refresh_token__c, access_token__c, WorkingStatus__c 
                                               FROM Dropbox_Credential__mdt 
                                               WITH SECURITY_ENFORCED 
                                               LIMIT 1];
            if (settings == null) {
                return false;
            }
            String refresh = settings.refresh_token__c;
            String clientid = settings.ClientId__c;
            String clientsecret = settings.ClientSecret__c;
            String body = 'grant_type=refresh_token' +
                          '&refresh_token=' + EncodingUtil.urlEncode(refresh, 'UTF-8') +
                          '&client_id=' + EncodingUtil.urlEncode(clientid, 'UTF-8') +
                          '&client_secret=' + EncodingUtil.urlEncode(clientsecret, 'UTF-8');

            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.dropbox.com/oauth2/token');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setMethod('POST');
            req.setBody(body);
            HttpResponse res = h.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, String> jsonvalues = parseJSONToMap(res.getBody());
                String newAccessToken = jsonvalues.get('access_token');
                if (newAccessToken != null) {
                    // Update Custom Metadata with new access token
                    Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                    Metadata.CustomMetadata metadataRec = new Metadata.CustomMetadata();
                    metadataRec.fullName = 'Dropbox_Credential__mdt.' + settings.DeveloperName;
                    metadataRec.label = settings.MasterLabel;

                    Metadata.CustomMetadataValue accessTokenField = new Metadata.CustomMetadataValue();
                    accessTokenField.field = 'access_token__c';
                    accessTokenField.value = newAccessToken;
                    metadataRec.values.add(accessTokenField);

                    Metadata.CustomMetadataValue workingStatusField = new Metadata.CustomMetadataValue();
                    workingStatusField.field = 'WorkingStatus__c';
                    workingStatusField.value = true;
                    metadataRec.values.add(workingStatusField);

                    mdContainer.addMetadata(metadataRec);
                    if (!Test.isRunningTest()) { Metadata.Operations.enqueueDeployment(mdContainer, null);}
                    return true;
                }
                return false;
            } else {
                Response_Handler.store_Callout_Response(res, 'DropBoxAuthorizationController', 'verifyAuth');
                // Update WorkingStatus__c to false
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                Metadata.CustomMetadata metadataRec = new Metadata.CustomMetadata();
                metadataRec.fullName = 'Dropbox_Credential__mdt.' + settings.DeveloperName;
                metadataRec.label = settings.MasterLabel;

                Metadata.CustomMetadataValue workingStatusField = new Metadata.CustomMetadataValue();
                workingStatusField.field = 'WorkingStatus__c';
                workingStatusField.value = false;
                metadataRec.values.add(workingStatusField);

                mdContainer.addMetadata(metadataRec);
                if (!Test.isRunningTest()) { Metadata.Operations.enqueueDeployment(mdContainer, null);}
                return false;
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'verifyAuth');
            return false;
        }
    }

    public static map < string, string > parseJSONToMap(string JSONValue) {
        JSONParser parser = JSON.createParser(JSONValue);
        map < string, string > jsonMap = new Map < string, string > ();
        string keyValue = '';
        string tempValue = '';
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                keyValue = parser.getText();
                parser.nextToken();
                tempValue = parser.getText();
                jsonMap.put(keyValue, tempValue);
            }
        }
        return jsonMap;
    }

    @AuraEnabled
    public static Boolean unauthorize() {
        try {
            List<Dropbox_Credential__mdt> settingsList = [SELECT Id, DeveloperName, MasterLabel, ClientId__c, ClientSecret__c, username__c, LinkedDate__c, email__c, refresh_token__c, access_token__c, WorkingStatus__c 
                                                         FROM Dropbox_Credential__mdt 
                                                         WITH SECURITY_ENFORCED 
                                                         LIMIT 1];
            if (!settingsList.isEmpty()) {
                Dropbox_Credential__mdt settings = settingsList[0];
                // Clear credentials using Metadata API
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                Metadata.CustomMetadata metadataRec = new Metadata.CustomMetadata();
                metadataRec.fullName = 'Dropbox_Credential__mdt.' + settings.DeveloperName;
                metadataRec.label = settings.MasterLabel;

                Metadata.CustomMetadataValue clientIdField = new Metadata.CustomMetadataValue();
                clientIdField.field = 'ClientId__c';
                clientIdField.value = '';
                metadataRec.values.add(clientIdField);

                Metadata.CustomMetadataValue clientSecretField = new Metadata.CustomMetadataValue();
                clientSecretField.field = 'ClientSecret__c';
                clientSecretField.value = '';
                metadataRec.values.add(clientSecretField);

                Metadata.CustomMetadataValue usernameField = new Metadata.CustomMetadataValue();
                usernameField.field = 'username__c';
                usernameField.value = '';
                metadataRec.values.add(usernameField);

                Metadata.CustomMetadataValue linkedDateField = new Metadata.CustomMetadataValue();
                linkedDateField.field = 'LinkedDate__c';
                linkedDateField.value = '';
                metadataRec.values.add(linkedDateField);

                Metadata.CustomMetadataValue emailField = new Metadata.CustomMetadataValue();
                emailField.field = 'email__c';
                emailField.value = '';
                metadataRec.values.add(emailField);

                Metadata.CustomMetadataValue refreshTokenField = new Metadata.CustomMetadataValue();
                refreshTokenField.field = 'refresh_token__c';
                refreshTokenField.value = '';
                metadataRec.values.add(refreshTokenField);

                Metadata.CustomMetadataValue accessTokenField = new Metadata.CustomMetadataValue();
                accessTokenField.field = 'access_token__c';
                accessTokenField.value = '';
                metadataRec.values.add(accessTokenField);

                Metadata.CustomMetadataValue workingStatusField = new Metadata.CustomMetadataValue();
                workingStatusField.field = 'WorkingStatus__c';
                workingStatusField.value = false;
                metadataRec.values.add(workingStatusField);

                mdContainer.addMetadata(metadataRec);
                if (!Test.isRunningTest()) { Metadata.Operations.enqueueDeployment(mdContainer, null);}
                return true;
            }
            return false;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'unauthorize');
            return null;
        }
    }

    @AuraEnabled
    public static String authorize(String clientId, String clientSecret) {
        try {
            if (String.isBlank(clientId) || String.isBlank(clientSecret)) {
                return 'Both Client ID and Client Secret are required.';
            }
            List<Dropbox_Credential__mdt> settingsList = [SELECT Id, DeveloperName, MasterLabel, ClientId__c, ClientSecret__c 
                                                         FROM Dropbox_Credential__mdt 
                                                         WITH SECURITY_ENFORCED 
                                                         LIMIT 1];
            if (settingsList.isEmpty()) {
                return null;
            }
            Dropbox_Credential__mdt settings = settingsList[0];
            // Update Custom Metadata with client ID and secret
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            Metadata.CustomMetadata metadataRec = new Metadata.CustomMetadata();
            metadataRec.fullName = 'Dropbox_Credential__mdt.' + settings.DeveloperName;
            metadataRec.label = settings.MasterLabel;

            Metadata.CustomMetadataValue clientIdField = new Metadata.CustomMetadataValue();
            clientIdField.field = 'ClientId__c';
            clientIdField.value = clientId;
            metadataRec.values.add(clientIdField);

            Metadata.CustomMetadataValue clientSecretField = new Metadata.CustomMetadataValue();
            clientSecretField.field = 'ClientSecret__c';
            clientSecretField.value = clientSecret;
            metadataRec.values.add(clientSecretField);

            mdContainer.addMetadata(metadataRec);
            if (!Test.isRunningTest()) { Metadata.Operations.enqueueDeployment(mdContainer, null);}

            String durl = authcode(clientId, clientSecret);
            return durl;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'authorize');
            return null;
        }
    }

    @AuraEnabled
    public static String redirectUrl(){
        try {
            String url = ''+System.Url.getOrgDomainUrl().toExternalForm();
            String REDIRECT_URI = redirect(url);
            return REDIRECT_URI;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'redirectUrl');
            return null;
        }
    }

    public static string redirect(String url){
        try{
            String REDIRECT_URI = '';
            if(url.contains('develop.my.salesforce.com')) {
            String baseUrl = url.substringBeforeLast('.develop.my.salesforce.com');
            REDIRECT_URI = baseUrl + '--c.develop.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }else if(url.contains('sandbox.my.salesforce.com')){
                String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
                REDIRECT_URI = baseUrl + '--c.sandbox.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }else if(url.contains('scratch.my.salesforce.com')){
                String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
                REDIRECT_URI = baseUrl + '--c.scratch.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }else {
                String baseUrl = url.substringBeforeLast('.my.salesforce.com');
                REDIRECT_URI = baseUrl + '--c.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }
            return REDIRECT_URI;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'redirect');
            return null;
        }
    }


    @AuraEnabled
    public static string authcode(String clientId, String clientSecret){
        try{
        String REDIRECT_URI = redirecturl(); 
        String AUTH_URL = 'https://www.dropbox.com/oauth2/authorize';
        String DROP_BOX_SCOPES = 'files.content.read files.content.write account_info.read';
        String authUrl = AUTH_URL + '?response_type=code' +
                        '&client_id=' + clientId +
                        '&redirect_uri=' + REDIRECT_URI +
                        '&token_access_type=offline' +
                        '&approval_prompt=force' +
                        '&state=state_parameter_passthrough_value' +
                        '&scope=' + DROP_BOX_SCOPES +
                        '&response_mode=query'+
                        '&force_reapprove=true';
        return authUrl;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'authcode');
            return null;
        }
    }
}