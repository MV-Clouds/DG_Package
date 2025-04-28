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
    public static String gettoken(String currentUrl) {
        try {
            
            String initialurl = currentUrl;
            String authcode = extractCodeParameter(initialurl);
            // Query Custom Metadata for existing settings
            List<MVDG__Dropbox_Credential__mdt> settingsList = [SELECT Id, DeveloperName, MasterLabel, MVDG__ClientId__c, MVDG__ClientSecret__c 
                                                         FROM MVDG__Dropbox_Credential__mdt 
                                                         WITH SECURITY_ENFORCED 
                                                         LIMIT 1];
            String clientId = settingsList.isEmpty() ? '' : settingsList[0].MVDG__ClientId__c;
            String clientSecret = settingsList.isEmpty() ? '' : settingsList[0].MVDG__ClientSecret__c;
            String developerName = settingsList.isEmpty() ? 'Default_Credential' : settingsList[0].DeveloperName;
            String masterLabel = settingsList.isEmpty() ? 'Default Credential' : settingsList[0].MasterLabel;

            // Use provided clientId and clientSecret
            String url = '' + System.Url.getOrgDomainUrl();
            String redirectUri = redirect(url);        
            Map<String, String> tokens = generaterefreshtoken(clientId, clientSecret, redirectUri, authcode);
            if (tokens == null || tokens.isEmpty()) {
                return 'error: failed to generate tokens';
            }
            String refreshToken = tokens.get('refresh_token');
            String accessToken = tokens.get('access_token');

            if (refreshToken == null || accessToken == null) {
                return 'error: missing tokens';
            }

            // Fetch user details
            String userdetails = fetchUserDetails(accessToken);
            Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(userdetails);
            Map<String, Object> userObject = (Map<String, Object>) parsedResponse.get('name');
            String emailAddress = (String) parsedResponse.get('email');
            String displayName = (String) userObject.get('display_name');
            Date todaysDate = Date.today();
            Datetime datetimeToday = Datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day(), 0, 0, 0);
            String formattedDate = datetimeToday.format('dd/MM/yyyy');

            // Create Metadata Container
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            Metadata.CustomMetadata metadataRec = new Metadata.CustomMetadata();
            metadataRec.fullName = 'MVDG__Dropbox_Credential__mdt.' + developerName;
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
            if(!Test.isRunningTest()){Metadata.Operations.enqueueDeployment(mdContainer, null);}

            return 'Success';
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'gettoken');
            return 'error: ' + e.getMessage();
        }
    }


    public static String redirect(String url){
        try{
            String redirectUri = '';
            if(url.contains('develop.my.salesforce.com')){
            String baseUrl = url.substringBeforeLast('.develop.my.salesforce.com');
            redirectUri = baseUrl + '--c.develop.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }else if(url.contains('sandbox.my.salesforce.com')){
                String baseUrl = url.substringBeforeLast('.sandbox.my.salesforce.com');
                redirectUri = baseUrl + '--c.sandbox.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }else if(url.contains('scratch.my.salesforce.com')){
                String baseUrl = url.substringBeforeLast('.scratch.my.salesforce.com');
                redirectUri = baseUrl + '--c.scratch.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }else {
                String baseUrl = url.substringBeforeLast('.my.salesforce.com');
                redirectUri = baseUrl + '--c.vf.force.com/apex/MVDG__dropboxSuccessPage';
            }
            return redirectUri;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'redirect');
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
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'redirectToSalesforcePage');
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
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'extractCodeParameter');
            return null;
        }
    }


    public static Map<String, String> generaterefreshtoken(String clientId, String clientSecret, String redirectUri, String authcode){
        try {
            String scope = 'files.content.read files.content.write account_info.read';
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
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
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
                Response_Handler.store_Callout_Response(resp1, 'DropboxSuccessController', 'fetchUserDetails');
                return 'false';
            }
            
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DropboxSuccessController', 'fetchUserDetails');
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
            return null;
        }
    }

}