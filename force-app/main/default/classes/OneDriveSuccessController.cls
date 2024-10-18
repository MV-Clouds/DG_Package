/*******************************************************
* Name          : OneDriveSuccessController
* Author        : Tirth
* Create Date   : 17/04/2024
* UsedBy        : MVDG__oneDriveSuccessPage
* Test Class    : OneDriveSuccessControllerTest
* Description   : Apex Class used for generating access and refresh token.
* Company       : MV Clouds
*******************************************************/
public with sharing class OneDriveSuccessController {


   @RemoteAction
   public static String gettoken(String currentUrl){
       try{
           String initialurl = 'www.google.com?code=Error';
           if(currentUrl != null && currentUrl != ''){
                initialurl = currentUrl;
           }
            String authcode = extractCodeParameter(initialurl);
            if (authcode == null || authcode == '') {
                return 'error: invalid auth code';
            }
            MVDG__OneDriveAuthProviderSettings__c settings = [SELECT Id, MVDG__ClientId__c, MVDG__ClientSecret__c FROM MVDG__OneDriveAuthProviderSettings__c WHERE SetupOwnerId = :UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
          
           if (settings != null) {
               String clientid = settings.MVDG__ClientId__c;
               String clientsecret = settings.MVDG__ClientSecret__c;
                if (clientid == null || clientid == '' || clientsecret == null || clientsecret == '') {
                    return 'error: invalid client ID or secret';
                }
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
               List<String> parts2 = new List<String>();
               Integer firstpartlength = 254;
               if (refreshToken != null) {
                   parts2.add(refreshToken.substring(0, firstpartlength));
                   parts2.add(refreshToken.substring(firstpartlength));
               } else {
                   parts2.add(refreshToken);
               }
               String refreshToken1 = parts2[0];
               String refreshToken2 = parts2[1];
               String accessToken;
               if(tokens?.get('access_token') != null){
                accessToken = tokens.get('access_token');
               }
               String userdetails = fetchUserDetails(accessToken);
               Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(userdetails);
               String emailAddress = (String) parsedResponse.get('mail');
               String displayName = (String) parsedResponse.get('displayName');
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
               if(refreshToken1 != null){
                    settings.MVDG__refresh_token__c = refreshToken1;
                    settings.MVDG__refresh_token1__c = refreshToken2;
                   if (Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__username__c.isUpdateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__email__c.isUpdateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__refresh_token__c.isUpdateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__refresh_token1__c.isUpdateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__username__c.isAccessible() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__email__c.isAccessible() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__refresh_token__c.isAccessible() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__refresh_token1__c.isAccessible() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__username__c.isCreateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__email__c.isCreateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__refresh_token__c.isCreateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__refresh_token1__c.isCreateable()) {
                           upsert settings;
                       }
                   else{
                       return 'error';
                   }
               }
               if(accessToken1 != null){
                   settings.MVDG__access_token__c = accessToken1;
                   settings.MVDG__access_token1__c = accessToken2;
                   settings.MVDG__access_token2__c = accessToken3;
                   settings.MVDG__access_token3__c = accessToken4;
                   settings.MVDG__access_token4__c = accessToken5;
                   Date todaysDate = Date.today();
                   Datetime datetimeToday = Datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day(), 0, 0, 0);
                   String formattedDate = datetimeToday.format('dd/MM/yyyy');
                   settings.MVDG__LinkedDate__c = formattedDate;
                   settings.MVDG__WorkingStatus__c = true;
                   if (Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token__c.isUpdateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token1__c.isUpdateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token2__c.isUpdateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token3__c.isUpdateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token4__c.isUpdateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token__c.isAccessible() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token1__c.isAccessible() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token2__c.isAccessible() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token3__c.isAccessible() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token4__c.isAccessible() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token__c.isCreateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token1__c.isCreateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token2__c.isCreateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token3__c.isCreateable() &&
                       Schema.sObjectType.MVDG__OneDriveAuthProviderSettings__c.fields.MVDG__access_token4__c.isCreateable()) {
                           upsert as user settings;
                           return 'Success';
                       }
               }
               else{
                   return 'Maybe';
               }
           }
           return 'error';
       } catch (Exception e) {
           Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'gettoken');
           return null;
       } 
   }

   public static String redirect(String url){
       try{
           String redirectUri = '';
           if(url.contains('develop.my.salesforce.com')){
           String baseUrl = url.substringBeforeLast('.develop.my.salesforce.com');
           redirectUri = baseUrl + '--c.develop.vf.force.com/apex/MVDG__oneDriveSuccessPage';
           }else if(url.contains('sandbox.my.salesforce.com')){
               String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
               redirectUri = baseUrl + '--c.sandbox.vf.force.com/apex/MVDG__oneDriveSuccessPage';
           }else if(url.contains('scratch.my.salesforce.com')){
               String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
               redirectUri = baseUrl + '--c.scratch.vf.force.com/apex/MVDG__oneDriveSuccessPage';
           }else {
               String baseUrl = url.substringBeforeLast('.my.salesforce.com');
               redirectUri = baseUrl + '--c.vf.force.com/apex/MVDG__oneDriveSuccessPage';
           }
           return redirectUri;
       } catch (Exception e) {
           Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'redirect');
           return null;
       }
   }

   public static String referenceUrl(String url){
       try{
       String refrenceUrl = '';
       if(url.contains('develop.my.salesforce.com')) {
       String baseUrl = url.substringBeforeLast('.develop.my.salesforce.com');
       refrenceUrl = baseUrl + '.develop.lightning.force.com/lightning/n/MVDG__User_Configuration';
       }else if(url.contains('sandbox.my.salesforce.com')){
           String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
           refrenceUrl = baseUrl + '.sandbox.lightning.force.com/lightning/n/MVDG__User_Configuration';
       }
       else if(url.contains('scratch.my.salesforce.com')){
           String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
           refrenceUrl = baseUrl + '.scratch.lightning.force.com/lightning/n/MVDG__User_Configuration';
       }else {
           String baseUrl = url.substringBeforeLast('.my.salesforce.com');
           refrenceUrl = baseUrl + '.force.com/lightning/n/MVDG__User_Configuration';
       }
       return refrenceUrl;
       } catch (Exception e) {
           Log_Handler.store_Exception(e, 'DropboxSuccessController', 'referenceUrl');
           return null;
       }
   }


   @RemoteAction
       public static PageReference redirectToSalesforcePage() {
           try {
               String url = ''+System.Url.getOrgDomainUrl();
               String refrenceUrl = referenceUrl(url);
               PageReference pageRef = new PageReference(refrenceUrl); // Replace 'TargetPageName' with the name of your target Visualforce page
               return pageRef;
           } catch (Exception e) {
           Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'redirectToSalesforcePage');
           return null;
       } 
   }


   public static String extractCodeParameter(String url) {
       try {
            // Use the PageReference class to extract query parameters
            PageReference pageRef = new PageReference(url.replace(System.Url.getOrgDomainUrl().toExternalForm(), ''));
            String codeParameter = pageRef.getParameters().get('code');
            return codeParameter;
       } catch (Exception e) {
           Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'extractCodeParameter');
           return null;
       } 
   }


   public static Map<String, String> generaterefreshtoken(String clientId, String clientSecret, String redirectUri, String authcode){
       try{
           String scope = 'files.readwrite.All offline_access User.Read';
           String endpoint = 'https://login.microsoftonline.com/common/oauth2/v2.0/token';
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
           if (response.getStatusCode() == 200) {
               Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
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
           return null;
       }
   }

}