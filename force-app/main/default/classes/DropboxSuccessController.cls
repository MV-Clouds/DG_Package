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

    @RemoteAction
    public static String gettoken(String currentUrl){
        try {
            String initialurl = currentUrl;
            String authcode = extractCodeParameter(initialurl);
            MVDG__DropBoxAuthProviderSettings__c settings = [SELECT Id, MVDG__ClientId__c, MVDG__ClientSecret__c FROM MVDG__DropBoxAuthProviderSettings__c WHERE SetupOwnerId = :UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
            if (settings != null) {
                String clientid = settings.MVDG__ClientId__c;
                String clientsecret = settings.MVDG__ClientSecret__c;
                String url = ''+System.Url.getOrgDomainUrl();
                String redirectUri = redirect(url);        
                Map<String, String> tokens = generaterefreshtoken(clientid, clientsecret, redirectUri, authcode);
                if (tokens == null || tokens.isEmpty()) {
                    return 'error: failed to generate tokens';
                }
                String refreshToken;
                if(tokens?.get('refresh_token') != null){
                    refreshToken = tokens.get('refresh_token');
                }
                String accessToken;
                if(tokens?.get('access_token') != null){
                    accessToken = tokens.get('access_token');
                }
                if(refreshToken != null){
                    settings.MVDG__refresh_token__c = refreshToken;
                    System.debug('ref');
                    }
                if(accessToken != null){
                    settings.MVDG__access_token__c = accessToken;
                    String userdetails = fetchUserDetails(accessToken);
                    Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(userdetails);
                    Map<String, Object> userObject = (Map<String, Object>) parsedResponse.get('name');
                    String emailAddress = (String) parsedResponse.get('email');
                    String displayName = (String) userObject.get('display_name');
                    Date todaysDate = Date.today();
                    Datetime datetimeToday = Datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day(), 0, 0, 0);
                    String formattedDate = datetimeToday.format('dd/MM/yyyy');
                    settings.MVDG__username__c = displayName;
                    settings.MVDG__email__c = emailAddress;
                    settings.MVDG__LinkedDate__c = formattedDate;
                    settings.MVDG__WorkingStatus__c = true;
                    if (Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__username__c.isUpdateable() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__email__c.isUpdateable() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__LinkedDate__c.isUpdateable() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__WorkingStatus__c.isUpdateable() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__access_token__c.isUpdateable() && 
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__refresh_token__c.isUpdateable() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__username__c.isAccessible() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__email__c.isAccessible() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__LinkedDate__c.isAccessible() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__WorkingStatus__c.isAccessible() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__access_token__c.isAccessible() && 
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__refresh_token__c.isAccessible() && 
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__username__c.isCreateable() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__email__c.isCreateable() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__LinkedDate__c.isCreateable() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__WorkingStatus__c.isCreateable() &&
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__access_token__c.isCreateable() && 
                        Schema.sObjectType.MVDG__DropBoxAuthProviderSettings__c.fields.MVDG__refresh_token__c.isCreateable()) {
                        upsert as user settings;
                    } else {
                        return 'error';
                    }
                    return 'Success';
                    }
            }else{
                return 'error';
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
            String redirectUri = '';
            if(url.contains('develop.my.salesforce.com')){
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.develop.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            redirectUri = baseUrl + '--c.develop.vf.force.com/apex/dropboxSuccessPage';
            }else if(url.contains('sandbox.my.salesforce.com')){
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                redirectUri = baseUrl + '--c.sandbox.vf.force.com/apex/dropboxSuccessPage';
            }else if(url.contains('scratch.my.salesforce.com')){
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                redirectUri = baseUrl + '--c.scratch.vf.force.com/apex/dropboxSuccessPage';
            }else {
                System.debug('System org url -->'+url);
                String baseUrl = url.substringBeforeLast('.my.salesforce.com');
                baseUrl = baseUrl.substringAfter('Url:[delegate=');
                redirectUri = baseUrl + '--c.vf.force.com/apex/dropboxSuccessPage';
            }
            return redirectUri;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'redirect');
            System.debug('Exception of gettoken got invoked');
            return null;
        }
    }


    public static String referenceUrl(String url){
        try{
        String refrenceUrl = '';
        if(url.contains('develop.my.salesforce.com')) {
        System.debug('System org url -->'+url);
        String baseUrl = url.substringBeforeLast('.develop.my.salesforce.com');
        baseUrl = baseUrl.substringAfter('Url:[delegate=');
        refrenceUrl = baseUrl + '.develop.lightning.force.com/lightning/n/MVDG__User_Configuration';
        }else if(url.contains('sandbox.my.salesforce.com')){
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            refrenceUrl = baseUrl + '.sandbox.lightning.force.com/lightning/n/MVDG__User_Configuration';
        }
        else if(url.contains('scratch.my.salesforce.com')){
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            refrenceUrl = baseUrl + '.scratch.lightning.force.com/lightning/n/MVDG__User_Configuration';
        }else {
            System.debug('System org url -->'+url);
            String baseUrl = url.substringBeforeLast('.my.salesforce.com');
            baseUrl = baseUrl.substringAfter('Url:[delegate=');
            refrenceUrl = baseUrl + '.force.com/lightning/n/MVDG__User_Configuration';
        }
        return refrenceUrl;
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
                String refrenceUrl = referenceUrl(url);
                
                System.debug(refrenceUrl);
                PageReference pageRef = new PageReference(refrenceUrl); // Replace 'TargetPageName' with the name of your target Visualforce page
                return pageRef;
            } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'redirectToSalesforcePage');
            System.debug('Exception of redirectToSalesforcePage got invoked');
            return null;
        }
    }
    

    public static String extractCodeParameter(String url) {
        try {
            // Use the PageReference class to extract query parameters
            PageReference pageRef = new PageReference(url.replace(System.Url.getOrgDomainUrl().toExternalForm(), ''));
            String codeParameter = pageRef.getParameters().get('code');
            System.debug('Tirth code parameter'+codeParameter);
            return codeParameter;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'extractCodeParameter');
            System.debug('Exception of extractCodeParameter got invoked');
            return null;
        }
    }


    public static Map<String, String> generaterefreshtoken(String clientId, String clientSecret, String redirectUri, String authcode){
        try {
            String scope = 'files.content.read files.content.write account_info.read';
            System.debug(scope);
            String endpoint = 'https://api.dropbox.com/oauth2/token';
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setBody('code=' + authcode +
                        '&client_id=' + clientId +
                        '&client_secret=' + clientSecret +
                        '&redirect_uri=' + redirectUri +
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