/*******************************************************
* Name          : DropboxAuthorizationController
* Author        : Tirth
* Create Date   : 18/04/2024 
* UsedBy        : integrationDashBoard Component
* Test Class    : DropboxAuthorizationControllerTest
* Description   : Apex Class used for managing integration of Dropbox simply by taking client id and secret of user.
* Company       : MV Clouds
*******************************************************/

public with sharing class DropBoxAuthorizationController {

    @AuraEnabled
    public static Map<String, Object> checkdropboxauth(){
        try{
            DropBoxAuthProviderSettings__c settings = DropBoxAuthProviderSettings__c.getOrgDefaults();
            Map<String, Object> result = new Map<String, Object>();
            if (settings != null && settings.refresh_token__c != null && settings.access_token__c != null && settings.LinkedDate__c != null) {
                Boolean working = verifyAuth();
                settings = DropBoxAuthProviderSettings__c.getOrgDefaults();
                result.put('name', settings.username__c);
                result.put('email', settings.email__c);
                result.put('linkdate', settings.LinkedDate__c);
                result.put('active', settings.WorkingStatus__c);
                return result;
            }
            result.put('error', 'Error obtaining details: ');
            return result;
        }catch(Exception e){
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'checkdropboxauth');
            System.debug('Exception of checkdropboxauth got invoked');
            return null;
        }
    }

    @AuraEnabled
    public static Boolean verifyAuth(){
        try {
        DropBoxAuthProviderSettings__c settings = DropBoxAuthProviderSettings__c.getOrgDefaults();
        String refresh = settings.refresh_token__c;
        String clientid = settings.ClientId__c;
        String clientsecret = settings.ClientSecret__c;
        String body =
            'grant_type=refresh_token' +
            '&refresh_token=' +
            EncodingUtil.urlEncode(refresh, 'UTF-8') +
            '&client_id=' +
            EncodingUtil.urlEncode(clientid, 'UTF-8') +
            '&client_secret=' +
            EncodingUtil.urlEncode(clientsecret, 'UTF-8');

        Http h = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://api.dropbox.com/oauth2/token');

        req.setHeader('Content-length', String.valueOf(body.length()));
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        req.setMethod('POST');

        req.setBody(body);
        HttpResponse res = h.send(req);
        // System.debug(res.getBody());
        if(res.getStatusCode() == 200){
            Map < String, String > jsonvalues = new Map < String, String > ();
            jsonvalues = parseJSONToMap(res.getBody());
            settings.access_token__c = jsonvalues.get('access_token');
            settings.WorkingStatus__c = true;
            Update settings;
            return true;
        }
        else{
            Response_Handler.store_Callout_Response(res, 'DropBoxAuthorizationController', 'verifyAuth');
            settings.WorkingStatus__c = false;
            Update settings;
            return false;
        }
    }
    catch (Exception e) {
            System.debug('Error in dropbox verify auth');
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
    public static Boolean unauthorize(){
        try {
            DropBoxAuthProviderSettings__c settings = DropBoxAuthProviderSettings__c.getOrgDefaults();
            if(settings != null){
                System.debug(settings);
                System.debug('I am not null');
                settings.ClientId__c = '';
                settings.ClientSecret__c = '';
                settings.username__c = '';
                settings.LinkedDate__c = '';
                settings.email__c = '';
                settings.refresh_token__c = '';
                settings.access_token__c = '';
                settings.WorkingStatus__c = false;
                upsert settings;
                return true;
            }
            return false;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'unauthorize');
            System.debug('Exception of unauthorize got invoked');
            return null;
        }
    }

    @AuraEnabled
    public static String authorize(String clientId, String clientSecret) {
        try{
            if (String.isBlank(clientId) || String.isBlank(clientSecret)) {
                System.debug('looks fishy');
                return 'Both Client ID and Client Secret are required.';
            }
            DropBoxAuthProviderSettings__c settings = DropBoxAuthProviderSettings__c.getOrgDefaults();
            if (settings == null) {
                settings = new DropBoxAuthProviderSettings__c();
            }
            settings.ClientId__c = clientId;
            settings.ClientSecret__c = clientSecret;
            String durl = authcode(clientId, clientSecret);
            System.debug('before upsert');
            upsert settings;
            System.debug(durl);
            return durl;
        }catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'authorize');
            System.debug('Exception of authorize got invoked');
            return null;
        }
    }

    @AuraEnabled
    public static String redirectUrl(){
        try {
            String url = ''+System.Url.getOrgDomainUrl();
            String REDIRECT_URI = redirect(url);
            return REDIRECT_URI;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'redirectUrl');
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
            REDIRECT_URI = baseUrl + '--c.develop.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }else if(url.contains('sandbox.my.salesforce.com')){
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                REDIRECT_URI = baseUrl + '--c.sandbox.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }else if(url.contains('scratch.my.salesforce.com')){
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                REDIRECT_URI = baseUrl + '--c.scratch.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }else {
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                REDIRECT_URI = baseUrl + '--c.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }
            return REDIRECT_URI;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'redirect');
            System.debug('Exception of redirect got invoked');
            return null;
        }
    }


    @AuraEnabled
    public static string authcode(String clientId, String clientSecret){
        try{
        String REDIRECT_URI = redirecturl(); 
        System.debug('redirect uri -->'+REDIRECT_URI);
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
            System.debug('Exception of authcode got invoked');
            return null;
        }
    }
}