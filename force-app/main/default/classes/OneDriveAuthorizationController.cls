/*******************************************************
* Name          : OneDriveAuthorizationController
* Author        : Tirth
* Create Date   : 16/04/2024 
* UsedBy        : integrationDashBoard Component
* Test Class    : OneDriveAuthorizationControllerTest
* Description   : Apex Class used for managing integration of OneDrive simply by taking client id and secret of user.
* Company       : MV Clouds
*******************************************************/

public with sharing class OneDriveAuthorizationController {

    @AuraEnabled
    public static Map<String, Object> checkonedriveauth(){
        try {
            List<MVDG__OneDrive_Credentials__mdt> settingsList = MVDG__OneDrive_Credentials__mdt.getAll().values();

            Map<String, Object> result = new Map<String, Object>();
            if (!settingsList.isEmpty() && settingsList[0].MVDG__refresh_token__c != null && settingsList[0].MVDG__access_token__c != null && settingsList[0].MVDG__LinkedDate__c != null) {
                MVDG__OneDrive_Credentials__mdt settings = settingsList[0];
                Boolean working = getToken();
                result.put('name', settings.MVDG__username__c);
                result.put('email', settings.MVDG__email__c);
                result.put('linkdate', settings.MVDG__LinkedDate__c);
                result.put('active', working);
                return result;
            }
            result.put('error', 'Error obtaining details: ');
            return result;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveAuthorizationController', 'checkonedriveauth');
            return null;
        }
    }

    public static Boolean getToken(){
        List<MVDG__OneDrive_Credentials__mdt> settingsList = MVDG__OneDrive_Credentials__mdt.getAll().values();
        MVDG__OneDrive_Credentials__mdt settings = settingsList[0];
                                               
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://login.microsoftonline.com/common/oauth2/v2.0/token');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody('refresh_token=' + settings.MVDG__refresh_token__c +
            '&client_id=' + settings.MVDG__ClientId__c +
            '&client_secret=' + settings.MVDG__ClientSecret__c +
            '&grant_type=refresh_token');
        Http http1 = new Http();
        HttpResponse response1 = http1.send(request);
        Map < String, String > result1 = new Map < String, String > ();
        if (response1.getStatusCode() == 200) {
            Map < String, Object > jsonResponse = (Map < String, Object > ) JSON.deserializeUntyped(response1.getBody());
            String newAccessToken = (String) jsonResponse.get('access_token');
            if (newAccessToken != null) {
                // Update Custom Metadata with new access token
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                Metadata.CustomMetadata metadataRec = new Metadata.CustomMetadata();
                metadataRec.fullName = 'MVDG__OneDrive_Credentials__mdt.MVDG__' + settings.DeveloperName;
                metadataRec.label = settings.MasterLabel;

                Metadata.CustomMetadataValue accessTokenField = new Metadata.CustomMetadataValue();
                accessTokenField.field = 'MVDG__access_token__c';
                accessTokenField.value = newAccessToken;
                metadataRec.values.add(accessTokenField);

                Metadata.CustomMetadataValue workingStatusField = new Metadata.CustomMetadataValue();
                workingStatusField.field = 'MVDG__WorkingStatus__c';
                workingStatusField.value = true;
                metadataRec.values.add(workingStatusField);

                mdContainer.addMetadata(metadataRec);
                if(!Test.isRunningTest()){Metadata.Operations.enqueueDeployment(mdContainer, null);}
                return true;
            }
            return false;
        }
        else {
            Response_Handler.store_Callout_Response(response1, 'OneDriveAuthorizationController', 'getToken');
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                Metadata.CustomMetadata metadataRec = new Metadata.CustomMetadata();
                metadataRec.fullName = 'MVDG__OneDrive_Credentials__mdt.MVDG__' + settings.DeveloperName;
                metadataRec.label = settings.MasterLabel;

                Metadata.CustomMetadataValue workingStatusField = new Metadata.CustomMetadataValue();
                workingStatusField.field = 'MVDG__WorkingStatus__c';
                workingStatusField.value = false;
                metadataRec.values.add(workingStatusField);

                mdContainer.addMetadata(metadataRec);
                if(!Test.isRunningTest()){Metadata.Operations.enqueueDeployment(mdContainer, null);}
            return false;
        }
    }


    @AuraEnabled
    public static Boolean unauthorize(){
        try {
            List<MVDG__OneDrive_Credentials__mdt> settingsList = MVDG__OneDrive_Credentials__mdt.getAll().values();

            if (!settingsList.isEmpty()) {
                MVDG__OneDrive_Credentials__mdt settings = settingsList[0];
                // Clear credentials using Metadata API
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                Metadata.CustomMetadata metadataRec = new Metadata.CustomMetadata();
                metadataRec.fullName = 'MVDG__OneDrive_Credentials__mdt.MVDG__' + settings.DeveloperName;
                metadataRec.label = settings.MasterLabel;

                Metadata.CustomMetadataValue clientIdField = new Metadata.CustomMetadataValue();
                clientIdField.field = 'MVDG__ClientId__c';
                clientIdField.value = '';
                metadataRec.values.add(clientIdField);

                Metadata.CustomMetadataValue clientSecretField = new Metadata.CustomMetadataValue();
                clientSecretField.field = 'MVDG__ClientSecret__c';
                clientSecretField.value = '';
                metadataRec.values.add(clientSecretField);

                Metadata.CustomMetadataValue usernameField = new Metadata.CustomMetadataValue();
                usernameField.field = 'MVDG__username__c';
                usernameField.value = '';
                metadataRec.values.add(usernameField);

                Metadata.CustomMetadataValue linkedDateField = new Metadata.CustomMetadataValue();
                linkedDateField.field = 'MVDG__LinkedDate__c';
                linkedDateField.value = '';
                metadataRec.values.add(linkedDateField);

                Metadata.CustomMetadataValue emailField = new Metadata.CustomMetadataValue();
                emailField.field = 'MVDG__email__c';
                emailField.value = '';
                metadataRec.values.add(emailField);

                Metadata.CustomMetadataValue refreshTokenField = new Metadata.CustomMetadataValue();
                refreshTokenField.field = 'MVDG__refresh_token__c';
                refreshTokenField.value = '';
                metadataRec.values.add(refreshTokenField);

                Metadata.CustomMetadataValue accessTokenField = new Metadata.CustomMetadataValue();
                accessTokenField.field = 'MVDG__access_token__c';
                accessTokenField.value = '';
                metadataRec.values.add(accessTokenField);

                Metadata.CustomMetadataValue workingStatusField = new Metadata.CustomMetadataValue();
                workingStatusField.field = 'MVDG__WorkingStatus__c';
                workingStatusField.value = false;
                metadataRec.values.add(workingStatusField);

                mdContainer.addMetadata(metadataRec);
                if(!Test.isRunningTest()){Metadata.Operations.enqueueDeployment(mdContainer, null);}
                return true;
            }
            return false;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveAuthorizationController', 'unauthorize');
            return null;
        }
    }


    @AuraEnabled
    public static String redirectUrl(){
        try {
            String url = ''+System.URL.getOrgDomainUrl().toExternalForm();
            String REDIRECT_URI = redirect(url);
            return REDIRECT_URI;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveAuthorizationController', 'redirectUrl');
            return null;
        }      
    }


    public static string redirect(String url){
        try{
            String REDIRECT_URI = '';
            if(url.contains('develop.my.salesforce.com')) {
            String baseUrl = url.substringBeforeLast('.develop.my.salesforce.com');
            REDIRECT_URI = baseUrl + '--c.develop.vf.force.com/apex/MVDG__oneDriveSuccessPage';
            }else if(url.contains('sandbox.my.salesforce.com')){
                String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
                REDIRECT_URI = baseUrl + '--c.sandbox.vf.force.com/apex/MVDG__oneDriveSuccessPage';
            }else if(url.contains('scratch.my.salesforce.com')){
                String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
                REDIRECT_URI = baseUrl + '--c.scratch.vf.force.com/apex/MVDG__oneDriveSuccessPage';
            }else {
                String baseUrl = url.substringBeforeLast('.my.salesforce.com');
                REDIRECT_URI = baseUrl + '--c.vf.force.com/apex/MVDG__oneDriveSuccessPage';
            }
            return REDIRECT_URI;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveAuthorizationController', 'redirect');
            return null;
        }   
    }


    @AuraEnabled
    public static String authorize(String clientId, String clientSecret) {
        try{
            if (String.isBlank(clientId) || String.isBlank(clientSecret) ) {
                return 'Both Client ID and Client Secret are required.';
            }
            List<MVDG__OneDrive_Credentials__mdt> settingsList = MVDG__OneDrive_Credentials__mdt.getAll().values();


            if (settingsList.isEmpty()) {
                throw new HandledException('No Onedrive credential settings found.');
            }
            MVDG__OneDrive_Credentials__mdt settings = settingsList[0];
            // Update Custom Metadata with client ID and secret
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            Metadata.CustomMetadata metadataRec = new Metadata.CustomMetadata();
            metadataRec.fullName = 'MVDG__OneDrive_Credentials__mdt.MVDG__' + settings.DeveloperName;
            metadataRec.label = settings.MasterLabel;

            Metadata.CustomMetadataValue clientIdField = new Metadata.CustomMetadataValue();
            clientIdField.field = 'MVDG__ClientId__c';
            clientIdField.value = clientId;
            metadataRec.values.add(clientIdField);

            Metadata.CustomMetadataValue clientSecretField = new Metadata.CustomMetadataValue();
            clientSecretField.field = 'MVDG__ClientSecret__c';
            clientSecretField.value = clientSecret;
            metadataRec.values.add(clientSecretField);

            mdContainer.addMetadata(metadataRec);
            if(!Test.isRunningTest()){Metadata.Operations.enqueueDeployment(mdContainer, null);}

            String durl = authcode(clientId, clientSecret);
            return durl;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveAuthorizationController', 'authorize');
            return null;
        }   
    }


    public static String authcode(String clientId, String clientSecret){
        try{
            String REDIRECT_URI = redirectUrl();
            String AUTH_URL = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
            String ONE_DRIVE_SCOPES = 'files.readwrite.All offline_access User.Read';
            String authUrl = AUTH_URL + '?response_type=code' +
                            '&client_id=' + clientId +
                            '&redirect_uri=' + REDIRECT_URI +
                            '&access_type=offline' +
                            '&state=state_parameter_passthrough_value' +
                            '&scope=' + ONE_DRIVE_SCOPES +
                            '&response_mode=query' +
                            '&prompt=login';
            return authUrl;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveAuthorizationController', 'authcode');
            return null;
        }   
    }

}