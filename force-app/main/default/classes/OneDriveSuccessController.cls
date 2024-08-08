/*******************************************************
* Name          : OneDriveSuccessController
* Author        : Tirth
* Create Date   : 17/04/2024 
* UsedBy        : OneDriveSuccessPage 
* Test Class    : OneDriveSuccessControllerTest
* Description   : Apex Class used for generating access and refresh token.
* Company       : MV Clouds
*******************************************************/
public with sharing class OneDriveSuccessController {

    public OneDriveSuccessController(ApexPages.StandardController c) {
    }


    @RemoteAction
    public static String gettoken(String currentUrl){
        try{
            String initialurl = currentUrl;
            String authcode = extractCodeParameter(initialurl);
            MVDG__OneDriveAuthProviderSettings__c settings = [SELECT Id, MVDG__ClientId__c, MVDG__ClientSecret__c FROM MVDG__OneDriveAuthProviderSettings__c WHERE SetupOwnerId = :UserInfo.getOrganizationId() LIMIT 1];
            if (settings != null) {
                System.debug('setting: '+ settings);
                String clientid = settings.MVDG__ClientId__c;
                System.debug('ClientId: ' + clientid);
                String clientsecret = settings.MVDG__ClientSecret__c;
                System.debug('ClientSecret: ' + clientsecret);
                String url = ''+System.Url.getOrgDomainUrl();
                String REDIRECT_URI = redirect(url);
                
                System.debug('redirect_uri-->'+REDIRECT_URI);
                System.debug('Lets generate refresh token');
                Map<String, String> tokens = generaterefreshtoken(clientid, clientsecret, REDIRECT_URI, authcode);
                String refreshToken = tokens.get('refresh_token');
                List<String> parts2 = new List<String>();
                Integer firstpartlength = 254;
                if (refreshToken != null && refreshToken.length() > firstpartlength) {
                    parts2.add(refreshToken.substring(0, firstpartlength));
                    parts2.add(refreshToken.substring(firstpartlength));
                } else {
                    parts2.add(refreshToken);
                }
                String refreshToken1 = parts2[0];
                String refreshToken2 = parts2[1];
                String accessToken = tokens.get('access_token');
                String userdetails = fetchUserDetails(accessToken);
                Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(userdetails);
                String emailAddress = (String) parsedResponse.get('mail');
                System.debug('Email Address: ' + emailAddress);
                String displayName = (String) parsedResponse.get('displayName');
                System.debug('Display Name: ' + displayName);
                settings.MVDG__username__c = displayName;
                settings.MVDG__email__c = emailAddress;
                List<String> parts1 = new List<String>();

                if (accessToken != null && accessToken.length() > 254) {
                    parts1.add(accessToken.substring(0, 254));
                    parts1.add(accessToken.substring(254, 508));
                    parts1.add(accessToken.substring(508, 762));
                    parts1.add(accessToken.substring(762, 1016));
                    parts1.add(accessToken.substring(1016));
                } else {
                    parts1.add(accessToken);
                }
                String accessToken1 = parts1[0];
                String accessToken2 = parts1[1];
                String accessToken3 = parts1[2];
                String accessToken4 = parts1[3];
                String accessToken5 = parts1[4];
                System.debug(refreshToken);
                System.debug(accessToken);
                if(refreshToken1 != null){
                    settings.MVDG__refresh_token__c = refreshToken1;
                    settings.MVDG__refresh_token1__c = refreshToken2;
                    System.debug('ref');
                    upsert settings;
                }
                if(accessToken1 != null){
                    settings.MVDG__access_token__c = accessToken1;
                    settings.MVDG__access_token1__c = accessToken2;
                    settings.MVDG__access_token2__c = accessToken3;
                    settings.MVDG__access_token3__c = accessToken4;
                    settings.MVDG__access_token4__c = accessToken5;
                    System.debug('ref');
                    Date todaysDate = Date.today();
                    Datetime datetimeToday = Datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day(), 0, 0, 0);
                    String formattedDate = datetimeToday.format('dd/MM/yyyy');
                    System.debug('Today\'s Date ==>'+formattedDate);
                    settings.MVDG__LinkedDate__c = formattedDate;
                    settings.MVDG__WorkingStatus__c = true;
                    upsert settings;
                    return 'Success';
                }
                else{
                    return 'Maybe';
                }
            }
            return 'error';
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'gettoken');
            System.debug('Exception of gettoken got invoked');
            return null;
        }  
    }

    public static String redirect(String url){
        try{
            String REDIRECT_URI = '';
            if(url.contains('develop.my.salesforce.com')){
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.develop.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            REDIRECT_URI = baseUrl + '--c.develop.vf.force.com/apex/oneDriveSuccessPage';
            }else if(url.contains('sandbox.my.salesforce.com')){
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                REDIRECT_URI = baseUrl + '--c.sandbox.vf.force.com/apex/oneDriveSuccessPage';
            }else if(url.contains('scratch.my.salesforce.com')){
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                REDIRECT_URI = baseUrl + '--c.scratch.vf.force.com/apex/oneDriveSuccessPage';
            }else {
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                REDIRECT_URI = baseUrl + '--c.vf.force.com/apex/oneDriveSuccessPage';
            }
            return REDIRECT_URI;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'redirect');
            System.debug('Exception of gettoken got invoked');
            return null;
        }
    }

    public static String referenceUrl(String url){
        try{
        String REFRENCEURL = '';
        if(url.contains('develop.my.salesforce.com')) {
        System.debug('System org url -->'+url);
        String baseUrl = url.substringBeforeLast('.develop.my.salesforce.com');
        baseUrl = baseUrl.substringAfter('Url:[delegate=');
        REFRENCEURL = baseUrl + '.develop.lightning.force.com/lightning/n/User_Configuration';
        }else if(url.contains('sandbox.my.salesforce.com')){
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            REFRENCEURL = baseUrl + '.sandbox.lightning.force.com/lightning/n/User_Configuration';
        }
        else if(url.contains('scratch.my.salesforce.com')){
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            REFRENCEURL = baseUrl + '.scratch.lightning.force.com/lightning/n/User_Configuration';
        }else {
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            REFRENCEURL = baseUrl + '.force.com/lightning/n/User_Configuration';
        }
        return REFRENCEURL;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'referenceUrl');
            System.debug('Exception of gettoken got invoked');
            return null;
        }
    }


    @RemoteAction
        public static PageReference redirectToSalesforcePage() {
            try {
                String url = ''+System.Url.getOrgDomainUrl();
                String REFRENCEURL = referenceUrl(url);
                System.debug(REFRENCEURL);
                PageReference pageRef = new PageReference(REFRENCEURL); // Replace 'TargetPageName' with the name of your target Visualforce page
                return pageRef;
            } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'redirectToSalesforcePage');
            System.debug('Exception of redirectToSalesforcePage got invoked');
            return null;
        }  
    }


    public static String extractCodeParameter(String url) {
        try{
            // Replace the base URL with an empty string to get the relative path
            String relativePath = url.replace(System.Url.getSalesforceBaseUrl().toExternalForm(), '');
            // Use the PageReference class to extract query parameters
            PageReference pageRef = new PageReference(relativePath);
            String codeParameter = pageRef.getParameters().get('code');
            System.debug(codeParameter);
            return codeParameter;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'extractCodeParameter');
            System.debug('Exception of extractCodeParameter got invoked');
            return null;
        }  
    }


    public static Map<String, String> generaterefreshtoken(String client_id, String client_secret, String REDIRECT_URI, String authcode){
        try{
            String SCOPE = 'files.readwrite.All offline_access User.Read';
            String ENDPOINT = 'https://login.microsoftonline.com/common/oauth2/v2.0/token';
            HttpRequest request = new HttpRequest();
            request.setEndpoint(ENDPOINT);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            System.debug(authcode);
            request.setBody('code=' + authcode +
                            '&client_id=' + client_id +
                            '&client_secret=' + client_secret +
                            '&redirect_uri=' + REDIRECT_URI +
                            '&grant_type=authorization_code');

            Http http = new Http();
            HttpResponse response = http.send(request);
            // Parse the response and extract refresh token
            Map<String, String> result = new Map<String, String>();
            System.debug(response.getStatusCode());
            System.debug(response.getBody());
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                // System.debug(jsonResponse);
                System.debug('access token : '+(String) jsonResponse.get('access_token'));
                System.debug('refresh token : '+(String) jsonResponse.get('refresh_token'));
                result.put('refresh_token', (String) jsonResponse.get('refresh_token'));
                result.put('access_token', (String) jsonResponse.get('access_token'));
            } else {
                // Handle error response
                Response_Handler.store_Callout_Response(response, 'OneDriveSuccessController', 'generaterefreshtoken');
                result.put('error', 'Error obtaining refresh token & access token. HTTP Status Code: ' + response.getStatusCode() +
                                    ', Response Body: ' + response.getBody());
            }
            return result;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'generaterefreshtoken');
            System.debug('Exception of generaterefreshtoken got invoked');
            return null;
        }
    }


    @AuraEnabled
    public static String fetchUserDetails(String access) {
        try {
            String acctok = access;
            HttpRequest req1 = getuserdata(acctok);
            Http http = new Http();
            HttpResponse resp1 = http.send(req1);            
            if (resp1.getStatusCode() == 200) {
                String resbody = resp1.getBody();
                String respbody = resbody != null ? resbody : '';
                return respbody;
            }
            else{
                Response_Handler.store_Callout_Response(resp1, 'OneDriveSuccessController', 'fetchUserDetails');
                return 'false';
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'fetchUserDetails');
            System.debug('Exception of fetchUserDetails got invoked');
            return null;
        }    
    }


    public static HttpRequest getuserdata(String acctok){
        try {
            HttpRequest req2= new HttpRequest();
            req2.setHeader('Authorization', 'Bearer ' + acctok);
            req2.setEndpoint('https://graph.microsoft.com/v1.0/me');
            req2.setHeader('accept', 'application/json');
            req2.setMethod('GET');
            return req2;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'getuserdata');
            System.debug('Exception of getuserdata got invoked');
            return null;
        }
    }

}