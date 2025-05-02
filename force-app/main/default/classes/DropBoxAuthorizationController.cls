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
            List<MVDG__Dropbox_Credentials__c> settingsList = [SELECT Id,MVDG__ClientId__c, MVDG__ClientSecret__c,MVDG__username__c, MVDG__LinkedDate__c,MVDG__email__c,MVDG__refresh_token__c,MVDG__access_token__c,MVDG__access_token1__c,MVDG__access_token2__c,MVDG__access_token3__c,MVDG__access_token4__c,MVDG__access_token5__c,MVDG__WorkingStatus__c FROM MVDG__Dropbox_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
            Map<String, Object> result = new Map<String, Object>();
            if (!settingsList.isEmpty() && settingsList[0].MVDG__refresh_token__c != null && settingsList[0].MVDG__access_token__c != null && settingsList[0].MVDG__LinkedDate__c != null) {
                Boolean working = verifyAuth();
                MVDG__Dropbox_Credentials__c settings = [SELECT Id,MVDG__ClientId__c, MVDG__ClientSecret__c,MVDG__username__c, MVDG__LinkedDate__c,MVDG__email__c,MVDG__refresh_token__c,MVDG__access_token__c,MVDG__access_token1__c,MVDG__access_token2__c,MVDG__access_token3__c,MVDG__access_token4__c,MVDG__access_token5__c,MVDG__WorkingStatus__c FROM MVDG__Dropbox_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
                result.put('name', settings.MVDG__username__c);
                result.put('email', settings.MVDG__email__c);
                result.put('linkdate', settings.MVDG__LinkedDate__c);
                result.put('active', settings.MVDG__WorkingStatus__c);
                return result;
            }
            result.put('error', 'Error obtaining details: ');
            return result;
        }catch(Exception e){
            Log_Handler.store_Exception(e, 'DropBoxAuthorizationController', 'checkdropboxauth');
            return null;
        }
    }

    @AuraEnabled
    public static Boolean verifyAuth(){
        try {
        MVDG__Dropbox_Credentials__c settings = [SELECT Id,MVDG__ClientId__c, MVDG__ClientSecret__c,MVDG__username__c, MVDG__LinkedDate__c,MVDG__email__c,MVDG__refresh_token__c,MVDG__access_token__c,MVDG__access_token1__c,MVDG__access_token2__c,MVDG__access_token3__c,MVDG__access_token4__c,MVDG__access_token5__c,MVDG__WorkingStatus__c FROM MVDG__Dropbox_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
        String refresh = settings.MVDG__refresh_token__c;
        String clientid = settings.MVDG__ClientId__c;
        String clientsecret = settings.MVDG__ClientSecret__c;
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
        if(res.getStatusCode() == 200){
            Map < String, String > jsonvalues = new Map < String, String > ();
            jsonvalues = parseJSONToMap(res.getBody());
            String accessToken = jsonvalues.get('access_token');
            List<String> parts1 = new List<String>();
                    if (accessToken != null && accessToken.length() > 254) {
                        parts1.add(accessToken.substring(0, 254));
                        parts1.add(accessToken.substring(254, 508));
                        parts1.add(accessToken.substring(508, 762));
                        parts1.add(accessToken.substring(762, 1016));
                        parts1.add(accessToken.substring(1016, 1270));
                        parts1.add(accessToken.substring(1270));
                    } else {
                        parts1.add(accessToken);
                    }
                    String newtoken1 = parts1[0];
                    String newtoken2 = parts1[1];
                    String newtoken3 = parts1[2];
                    String newtoken4 = parts1[3];
                    String newtoken5 = parts1[4];
                    String newtoken6 = parts1[5];

                    if(newtoken1 != null){
                        settings.MVDG__access_token__c = newtoken1;
                        settings.MVDG__access_token1__c = newtoken2;
                        settings.MVDG__access_token2__c = newtoken3;
                        settings.MVDG__access_token3__c = newtoken4;
                        settings.MVDG__access_token4__c = newtoken5;
                        settings.MVDG__access_token5__c = newtoken6;
                    }
            settings.MVDG__WorkingStatus__c = true;
            Update as user settings;
            return true;
        }
        else{
            Response_Handler.store_Callout_Response(res, 'DropBoxAuthorizationController', 'verifyAuth');
            settings.MVDG__WorkingStatus__c = false;
            Update as user settings;
            return false;
        }
    }
    catch (Exception e) {
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
    public static Boolean unauthorize(){
        try {
            MVDG__Dropbox_Credentials__c settings = [SELECT Id,MVDG__ClientId__c, MVDG__ClientSecret__c,MVDG__username__c, MVDG__LinkedDate__c,MVDG__email__c,MVDG__refresh_token__c,MVDG__access_token__c,MVDG__access_token1__c,MVDG__access_token2__c,MVDG__access_token3__c,MVDG__access_token4__c,MVDG__access_token5__c,MVDG__WorkingStatus__c FROM MVDG__Dropbox_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
            if(settings != null){
                settings.MVDG__ClientId__c = '';
                settings.MVDG__ClientSecret__c = '';
                settings.MVDG__username__c = '';
                settings.MVDG__LinkedDate__c = '';
                settings.MVDG__email__c = '';
                settings.MVDG__refresh_token__c = '';
                settings.MVDG__access_token__c = '';
                settings.MVDG__access_token1__c = '';
                settings.MVDG__access_token2__c = '';
                settings.MVDG__access_token3__c = '';
                settings.MVDG__access_token4__c = '';
                settings.MVDG__access_token5__c = '';
                settings.MVDG__WorkingStatus__c = false;
                upsert as user settings;
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
        try{
            if (String.isBlank(clientId) || String.isBlank(clientSecret)) {
                return 'Both Client ID and Client Secret are required.';
            }
            List<MVDG__Dropbox_Credentials__c> settingsList = [SELECT Id,MVDG__ClientId__c, MVDG__ClientSecret__c FROM MVDG__Dropbox_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
            MVDG__Dropbox_Credentials__c settings;
            if (!settingsList.isEmpty()) {
                settings = settingsList[0];
            }else{
                settings = new MVDG__Dropbox_Credentials__c();
            }
            settings.MVDG__ClientId__c = clientId;
            settings.MVDG__ClientSecret__c = clientSecret;
            String durl = authcode(clientId, clientSecret);
            upsert as user settings;
            return durl;
        }catch (Exception e) {
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