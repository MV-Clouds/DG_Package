/*******************************************************
* Name          : DropboxSuccessController
* Author        : Tirth
* Create Date   : 19/04/2024 
* UsedBy        : integrationDashBoard Component
* Test Class    : DropboxSuccessControllerTest
* Description   : Apex Class used for managing refresh and access token of Dropbox.
* Company       : MV Clouds
*******************************************************/
public with sharing class DropboxSuccessController {

    public DropboxSuccessController(ApexPages.StandardController c) {
    }


    @RemoteAction
    public static String gettoken(String currentUrl){
        try {
            String initialurl = currentUrl;
            String authcode = extractCodeParameter(initialurl);
            DropBoxAuthProviderSettings__c settings = [SELECT Id, ClientId__c, ClientSecret__c FROM DropBoxAuthProviderSettings__c WHERE SetupOwnerId = :UserInfo.getOrganizationId() LIMIT 1];
            if (settings != null) {
                System.debug('setting: '+ settings);
                String clientid = settings.ClientId__c;
                System.debug('ClientId: ' + clientid);
                String clientsecret = settings.ClientSecret__c;
                System.debug('ClientId: ' + clientsecret);
                String url = ''+System.Url.getOrgDomainUrl();
                String REDIRECT_URI = redirect(url);        
                System.debug('redirect_uri-->'+REDIRECT_URI);
                System.debug('Lets generate refresh token');
                Map<String, String> tokens = generaterefreshtoken(clientid, clientsecret, REDIRECT_URI, authcode);
                String refreshToken = tokens.get('refresh_token');
                String accessToken = tokens.get('access_token');
                System.debug(refreshToken);
                System.debug(accessToken);
                if(refreshToken != null){
                    settings.refresh_token__c = refreshToken;
                    System.debug('ref');
                    }
                if(accessToken != null){
                    settings.access_token__c = accessToken;
                    String userdetails = fetchUserDetails(accessToken);
                    System.debug(userdetails);
                    Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(userdetails);
                    Map<String, Object> userObject = (Map<String, Object>) parsedResponse.get('name');
                    String emailAddress = (String) parsedResponse.get('email');
                    System.debug('Email Address: ' + emailAddress);
                    String displayName = (String) userObject.get('display_name');
                    System.debug('Display Name: ' + displayName);
                    System.debug('acc');
                    Date todaysDate = Date.today();
                    Datetime datetimeToday = Datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day(), 0, 0, 0);
                    String formattedDate = datetimeToday.format('dd/MM/yyyy');
                    System.debug('Today\'s Date ==>'+formattedDate);
                    settings.username__c = displayName;
                    settings.email__c = emailAddress;
                    settings.LinkedDate__c = formattedDate;
                    settings.WorkingStatus__c = true;
                    upsert settings;
                    return 'Success';
                    }
            }else{
                return 'Maybe';
            }
            return 'error';
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'gettoken');
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
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'redirect');
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
        REFRENCEURL = baseUrl + '.develop.lightning.force.com/lightning/n/MVDG__User_Configuration';
        }else if(url.contains('sandbox.my.salesforce.com')){
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            REFRENCEURL = baseUrl + '.sandbox.lightning.force.com/lightning/n/MVDG__User_Configuration';
        }
        else if(url.contains('scratch.my.salesforce.com')){
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            REFRENCEURL = baseUrl + '.scratch.lightning.force.com/lightning/n/MVDG__User_Configuration';
        }else {
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            REFRENCEURL = baseUrl + '.force.com/lightning/n/MVDG__User_Configuration';
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
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'redirectToSalesforcePage');
            System.debug('Exception of redirectToSalesforcePage got invoked');
            return null;
        }
    }
    

    public static String extractCodeParameter(String url) {
        try {
            // Replace the base URL with an empty string to get the relative path
            String relativePath = url.replace(System.Url.getSalesforceBaseUrl().toExternalForm(), '');
            // Use the PageReference class to extract query parameters
            PageReference pageRef = new PageReference(relativePath);
            String codeParameter = pageRef.getParameters().get('code');
            System.debug(codeParameter);
            return codeParameter;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'extractCodeParameter');
            System.debug('Exception of extractCodeParameter got invoked');
            return null;
        }
    }


    public static Map<String, String> generaterefreshtoken(String client_id, String client_secret, String REDIRECT_URI, String authcode){
        try {
            String SCOPE = 'files.content.read files.content.write account_info.read';
            System.debug(SCOPE);
            String ENDPOINT = 'https://api.dropbox.com/oauth2/token';
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
                Response_Handler.store_Callout_Response(response, 'DropboxSuccessController', 'generaterefreshtoken');
                result.put('error', 'Error obtaining refresh token & access token. HTTP Status Code: ' + response.getStatusCode() +
                                    ', Response Body: ' + response.getBody());
            }
            return result;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'generaterefreshtoken');
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
                System.debug(resbody);
                String respbody = resbody != null ? resbody : '';
                return respbody;
            }
            else{
                Response_Handler.store_Callout_Response(resp1, 'DropboxSuccessController', 'fetchUserDetails');
                System.debug('Error fetching user details. HTTP Status Code: ' + resp1.getStatusCode() +
                                ', Response Body: ' + resp1.getBody());
                return 'false';
            }
            
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'fetchUserDetails');
            System.debug('Exception of fetchUserDetails got invoked');
            return null;
        }    
    }


    public static HttpRequest getuserdata(String acctok){
        try {
            HttpRequest req2= new HttpRequest();
            req2.setHeader('Authorization', 'Bearer ' + acctok);
            req2.setEndpoint('https://api.dropboxapi.com/2/users/get_current_account');
            req2.setMethod('POST');
            return req2;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'getuserdata');
            System.debug('Exception of getuserdata got invoked');
            return null;
        }
    }

}