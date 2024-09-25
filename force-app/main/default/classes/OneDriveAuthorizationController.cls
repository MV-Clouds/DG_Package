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
            MVDG__OneDriveAuthProviderSettings__c settings = MVDG__OneDriveAuthProviderSettings__c.getOrgDefaults();
            Map<String, Object> result = new Map<String, Object>();
            if (settings != null && settings.MVDG__refresh_token__c != null && settings.MVDG__access_token__c != null && settings.MVDG__email__c != null && settings.MVDG__LinkedDate__c != null) {
                Boolean working = getToken();
                settings = MVDG__OneDriveAuthProviderSettings__c.getOrgDefaults();
                result.put('email', settings.MVDG__email__c);
                result.put('linkdate', settings.MVDG__LinkedDate__c);
                result.put('active', settings.MVDG__WorkingStatus__c);
                result.put('name', settings.MVDG__username__c);
                return result;
            }
            result.put('error', 'Error obtaining details: ');
            return result;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveAuthorizationController', 'checkonedriveauth');
            System.debug('Exception of checkonedriveauth got invoked');
            return null;
        }
    }

    public static Boolean getToken(){
        MVDG__OneDriveAuthProviderSettings__c settings = MVDG__OneDriveAuthProviderSettings__c.getOrgDefaults();
        // System.debug('generating new token');
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://login.microsoftonline.com/common/oauth2/v2.0/token');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody('refresh_token=' + settings.MVDG__refresh_token__c + settings.MVDG__refresh_token1__c +
            '&client_id=' + settings.MVDG__ClientId__c +
            '&client_secret=' + settings.MVDG__ClientSecret__c +
            '&grant_type=refresh_token');
        Http http1 = new Http();
        HttpResponse response1 = http1.send(request);
        Map < String, String > result1 = new Map < String, String > ();
        // System.debug('api call for generating token-->' + response1.getStatusCode());
        // System.debug(response1.getBody());
        if (response1.getStatusCode() == 200) {
            Map < String, Object > jsonResponse = (Map < String, Object > ) JSON.deserializeUntyped(response1.getBody());
            String newtoken = (String) jsonResponse.get('access_token');
            List<String> parts1 = new List<String>();
                if (newtoken != null && newtoken.length() > 254) {
                    parts1.add(newtoken.substring(0, 254));
                    parts1.add(newtoken.substring(254, 508));
                    parts1.add(newtoken.substring(508, 762));
                    parts1.add(newtoken.substring(762, 1016));
                    parts1.add(newtoken.substring(1016));
                } else {
                    parts1.add(newtoken);
                }
                String newtoken1 = parts1[0];
                String newtoken2 = parts1[1];
                String newtoken3 = parts1[2];
                String newtoken4 = parts1[3];
                String newtoken5 = parts1[4];
                System.debug(newtoken);
                if(newtoken1 != null){
                    settings.MVDG__access_token__c = newtoken1;
                    settings.MVDG__access_token1__c = newtoken2;
                    settings.MVDG__access_token2__c = newtoken3;
                    settings.MVDG__access_token3__c = newtoken4;
                    settings.MVDG__access_token4__c = newtoken5;
                }
                settings.MVDG__WorkingStatus__c = true;
                update as user settings;
                return true;
        }
        else {
            Response_Handler.store_Callout_Response(response1, 'OneDriveAuthorizationController', 'getToken');
            System.debug('No token generated');
            settings.MVDG__WorkingStatus__c = false;
            update as user settings;
            return false;
        }
    }


    @AuraEnabled
    public static Boolean unauthorize(){
        try {
            MVDG__OneDriveAuthProviderSettings__c	 settings = MVDG__OneDriveAuthProviderSettings__c.getOrgDefaults();
            if(settings != null){
                settings.MVDG__access_token__c = '';
                settings.MVDG__access_token1__c = '';
                settings.MVDG__access_token2__c = '';
                settings.MVDG__access_token3__c = '';
                settings.MVDG__access_token4__c = '';
                settings.MVDG__ClientId__c = '';
                settings.MVDG__ClientSecret__c = '';
                settings.MVDG__LinkedDate__c = '';
                settings.MVDG__WorkingStatus__c = false;
                settings.MVDG__username__c = '';
                settings.MVDG__refresh_token__c = '';
                settings.MVDG__refresh_token1__c = '';
                settings.MVDG__email__c = '';
                upsert as user settings;
                return true;
            }
            return false;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveAuthorizationController', 'unauthorize');
            System.debug('Exception of unauthorize got invoked');
            return null;
        }
    }


    @AuraEnabled
    public static String redirectUrl(){
        try {
            String url = ''+System.URL.getOrgDomainUrl();
            String REDIRECT_URI = redirect(url);
            return REDIRECT_URI;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveAuthorizationController', 'redirectUrl');
            System.debug('Exception of redirecturl got invoked');
            return null;
        }      
    }


    public static string redirect(String url){
        try{
            String REDIRECT_URI = '';
            if(url.contains('develop.my.salesforce.com')) {
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.develop.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            REDIRECT_URI = baseUrl + '--c.develop.vf.force.com/apex/MVDG__oneDriveSuccessPage';
            }else if(url.contains('sandbox.my.salesforce.com')){
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                REDIRECT_URI = baseUrl + '--c.sandbox.vf.force.com/apex/MVDG__oneDriveSuccessPage';
            }else if(url.contains('scratch.my.salesforce.com')){
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                REDIRECT_URI = baseUrl + '--c.scratch.vf.force.com/apex/MVDG__oneDriveSuccessPage';
            }else {
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                REDIRECT_URI = baseUrl + '--c.vf.force.com/apex/MVDG__oneDriveSuccessPage';
            }
            return REDIRECT_URI;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveAuthorizationController', 'redirect');
            System.debug('Exception of redirect got invoked');
            return null;
        }   
    }


    @AuraEnabled
    public static String authorize(String clientId, String clientSecret) {
        try{
            if (String.isBlank(clientId) || String.isBlank(clientSecret) ) {
                return 'Both Client ID and Client Secret are required.';
            }
            MVDG__OneDriveAuthProviderSettings__c settings = MVDG__OneDriveAuthProviderSettings__c.getOrgDefaults();
            if (settings == null) {
                settings = new MVDG__OneDriveAuthProviderSettings__c();
            }
            settings.MVDG__ClientId__c = clientId;
            settings.MVDG__ClientSecret__c = clientSecret;
            String durl = authcode(clientId, clientSecret);
            upsert as user settings;
            System.debug(durl);
            return durl;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveAuthorizationController', 'authorize');
            System.debug('Exception of authorize got invoked');
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
            System.debug('Exception of authcode got invoked');
            return null;
        }   
    }

}