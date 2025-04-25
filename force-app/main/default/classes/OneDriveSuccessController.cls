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
            List<MVDG__OneDrive_Credentials__mdt> settings = [SELECT Id, DeveloperName, MasterLabel, MVDG__ClientId__c, MVDG__ClientSecret__c 
                                                         FROM MVDG__OneDrive_Credentials__mdt 
                                                         WITH SECURITY_ENFORCED 
                                                         LIMIT 1];
          
           if (settings != null) {
            String clientId = settings.isEmpty() ? '' : settings[0].MVDG__ClientId__c;
            String clientSecret = settings.isEmpty() ? '' : settings[0].MVDG__ClientSecret__c;
            String developerName = settings.isEmpty() ? 'Default_Credential' : settings[0].DeveloperName;
            String masterLabel = settings.isEmpty() ? 'Default Credential' : settings[0].MasterLabel;

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
                String accessToken;
                if(tokens?.get('access_token') != null){
                 accessToken = tokens.get('access_token');
                }
               
               String userdetails = fetchUserDetails(accessToken);
               Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(userdetails);
               String emailAddress = (String) parsedResponse.get('mail');
               String displayName = (String) parsedResponse.get('displayName');
               Date todaysDate = Date.today();
               Datetime datetimeToday = Datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day(), 0, 0, 0);
               String formattedDate = datetimeToday.format('dd/MM/yyyy');
   
               // Create Metadata Container
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                Metadata.CustomMetadata metadataRec = new Metadata.CustomMetadata();
                metadataRec.fullName = 'MVDG__OneDrive_Credentials__mdt.' + developerName;
                metadataRec.label = masterLabel;

                // Add field values to Custom Metadata
                Metadata.CustomMetadataValue clientIdField = new Metadata.CustomMetadataValue();
                clientIdField.field = 'MVDG__ClientId__c';
                clientIdField.value = clientId;
                metadataRec.values.add(clientIdField);

                Metadata.CustomMetadataValue clientSecretField = new Metadata.CustomMetadataValue();
                clientSecretField.field = 'MVDG__ClientSecret__c';
                clientSecretField.value = clientSecret;
                metadataRec.values.add(clientSecretField);

                Metadata.CustomMetadataValue refreshTokenField = new Metadata.CustomMetadataValue();
                refreshTokenField.field = 'MVDG__refresh_token__c';
                refreshTokenField.value = refreshToken;
                metadataRec.values.add(refreshTokenField);

                Metadata.CustomMetadataValue accessTokenField = new Metadata.CustomMetadataValue();
                accessTokenField.field = 'MVDG__access_token__c';
                accessTokenField.value = accessToken;
                metadataRec.values.add(accessTokenField);

                Metadata.CustomMetadataValue usernameField = new Metadata.CustomMetadataValue();
                usernameField.field = 'MVDG__username__c';
                usernameField.value = displayName;
                metadataRec.values.add(usernameField);

                Metadata.CustomMetadataValue emailField = new Metadata.CustomMetadataValue();
                emailField.field = 'MVDG__email__c';
                emailField.value = emailAddress;
                metadataRec.values.add(emailField);

                Metadata.CustomMetadataValue linkedDateField = new Metadata.CustomMetadataValue();
                linkedDateField.field = 'MVDG__LinkedDate__c';
                linkedDateField.value = formattedDate;
                metadataRec.values.add(linkedDateField);

                Metadata.CustomMetadataValue workingStatusField = new Metadata.CustomMetadataValue();
                workingStatusField.field = 'MVDG__WorkingStatus__c';
                workingStatusField.value = true;
                metadataRec.values.add(workingStatusField);

                // Add metadata record to container
                mdContainer.addMetadata(metadataRec);
                Metadata.Operations.enqueueDeployment(mdContainer, null);

                return 'Success';
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
           Log_Handler.store_Exception(e, 'OneDriveSuccessController', 'referenceUrl');
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