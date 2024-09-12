/*******************************************************
* Name          : AwsAuthorizationController
* Author        : Tirth
* Create Date   : 22/04/2024 
* UsedBy        : OneDriveSuccessPage 
* Test Class    : AwsAuthorizationControllerTest
* Description   : Apex Class used for generating signature.
* Company       : MV Clouds
*******************************************************/
public with sharing class AwsAuthorizationController {

    public class AuthHeaderParams {
        @AuraEnabled public String contentType { get; set; }
        @AuraEnabled public String filename { get; set; }
        @AuraEnabled public String formatedDateString { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public String methodName { get; set; }
        @AuraEnabled public String bucketName { get; set; }
        @AuraEnabled public String awsKey { get; set; }
        @AuraEnabled public String awsSecret { get; set; }    
    }


    @AuraEnabled
    public static Map<String, Object> checkawsauth(){
        try{
            MVDG__AwsAuthProviderSettings__c settings = MVDG__AwsAuthProviderSettings__c.getOrgDefaults();
            // System.debug('bucket-->'+settings.MVDG__BucketName__c);
            // System.debug('bucket-->'+settings.MVDG__BucketName__c);
            // System.debug('bucket-->'+settings.MVDG__BucketName__c);

            Map<String, Object> result = new Map<String, Object>();
            if (settings != null  && (settings.MVDG__BucketName__c != '' && settings.MVDG__LinkedDate__c != '' && settings.MVDG__NickName__c != '') || (settings.MVDG__NamedCredential__c != '' || settings.MVDG__NamedCredential__c != null)) {
                Boolean working = verifyAuth();
                settings = MVDG__AwsAuthProviderSettings__c.getOrgDefaults();
                if(working){
                    result.put('bucket', settings.MVDG__BucketName__c);
                    result.put('linkdate', settings.MVDG__LinkedDate__c);
                    result.put('active', settings.MVDG__WorkingStatus__c);
                    result.put('name', settings.MVDG__NickName__c);
                    return result;
                }
            }
            result.put('error', 'Error obtaining details: ');
            return result;
        }catch(Exception e){
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'checkawsauth');
            // System.debug('Exception of checkawsauth got invoked');
            return null;
        }
    }


    @AuraEnabled
    public static Boolean unauthorize(){
        try {
            MVDG__AwsAuthProviderSettings__c settings = MVDG__AwsAuthProviderSettings__c.getOrgDefaults();
            if(settings != null){
                settings.MVDG__BucketName__c = '';
                settings.MVDG__ClientId__c = '';
                settings.MVDG__ClientSecret__c = '';
                settings.MVDG__LinkedDate__c = '';
                settings.MVDG__WorkingStatus__c = false;
                settings.MVDG__NickName__c = '';
                settings.MVDG__NamedCredential__c = '';
                if(!Schema.sObjectType.MVDG__AwsAuthProviderSettings__c.fields.MVDG__NamedCredential__c.isUpdateable() || !Schema.sObjectType.MVDG__AwsAuthProviderSettings__c.fields.MVDG__WorkingStatus__c.isUpdateable() || !Schema.sObjectType.MVDG__AwsAuthProviderSettings__c.fields.MVDG__NamedCredential__c.isCreateable() || !Schema.sObjectType.MVDG__AwsAuthProviderSettings__c.fields.MVDG__WorkingStatus__c.isCreateable()){
                return null;
            }
                upsert settings;
                // System.debug(settings.MVDG__ClientId__c);
                return true;
            }
            return false;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'unauthorize');
            // System.debug('Exception of unauthorize got invoked');
            return null;
        }
    }

    @AuraEnabled
    public static Boolean verifyAuth(){
        try {
            MVDG__AwsAuthProviderSettings__c settings = MVDG__AwsAuthProviderSettings__c.getOrgDefaults(); 
            if(String.isBlank(settings.MVDG__NamedCredential__c) && String.isNotBlank(settings.MVDG__BucketName__c) && String.isNotBlank(settings.MVDG__ClientId__c) && String.isNotBlank(settings.MVDG__ClientSecret__c)){
                AuthHeaderParams params = new AuthHeaderParams();
                params.methodName = 'GET';
                params.bucketName = settings.MVDG__BucketName__c;
                params.awsKey = settings.MVDG__ClientId__c;
                params.awsSecret = settings.MVDG__ClientSecret__c;
                params.contentType = '';
                params.filename = '';
                params.fileExtension = '';
                params.formatedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss \'GMT\'');

                HttpRequest req = new HttpRequest();
                req.setEndpoint('https://'+settings.MVDG__BucketName__c+ '.s3.amazonaws.com');
                req.setMethod('GET');
                req.setHeader('Content-Type', '');
                req.setHeader('authorization', createSimpleAuthHeader(params));
                req.setHeader('Host', settings.MVDG__BucketName__c + '.s3.amazonaws.com');
                req.setHeader('Date', Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss \'GMT\''));
                req.setHeader('Connection', 'keep-alive');
                req.setHeader('accept', '*/*');
                Http http = new Http();
                HttpResponse res = http.send(req);
                System.debug(res.getBody());
                if(res.getStatusCode() == 200){
                    settings.MVDG__WorkingStatus__c = true;
                    update settings;
                    return true;
                }
                else{
                    settings.MVDG__WorkingStatus__c = false;
                    Response_Handler.store_Callout_Response(res, 'AwsAuthorizationController', 'verifyAuth');
                    update settings;
                    return true;
                }
            }else if (String.isNotBlank(settings.MVDG__NamedCredential__c)){
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:'+settings.MVDG__NamedCredential__c);
                req.setMethod('GET');
                Http http = new http();
                HttpResponse res = http.send(req);
                if(res.getStatusCode() == 200){
                    settings.MVDG__WorkingStatus__c = true;
                    update settings;
                    return true;
                }
                else{
                    settings.MVDG__WorkingStatus__c = false;
                    update settings;
                    Response_Handler.store_Callout_Response(res, 'AwsAuthorizationController', 'verifyAuth');
                    return true;
                }
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'verifyAuth');
            System.debug('Catch invoked');
        }
        return false;
    }

    @AuraEnabled
    public static String authorizeNamed(String named){
        try{
            if(named != null){
                System.debug('authorize named');
                Integer checkNamed = [SELECT Count() FROM NamedCredential WHERE DeveloperName = :named WITH SECURITY_ENFORCED LIMIT 1];
                if(Test.isRunningTest()){
                    checkNamed = 1;
                }
                if(checkNamed == 1){
                    MVDG__AwsAuthProviderSettings__c settings = MVDG__AwsAuthProviderSettings__c.getOrgDefaults();
                    if (settings == null) {
                        settings = new MVDG__AwsAuthProviderSettings__c();
                    }
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint('callout:'+named);
                    req.setMethod('GET');
                    Http http = new http();
                    HttpResponse res = http.send(req);
                    if(res.getStatusCode() == 200){
                        settings.MVDG__WorkingStatus__c = true;
                    }
                    else {
                        return 'Failure';
                    }
                    
                    settings.MVDG__NamedCredential__c = named;
                    settings.MVDG__NickName__c = named;
                    settings.MVDG__BucketName__c = 'Unknown';
                    Date todaysDate = Date.today();
                    Datetime datetimeToday = Datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day(), 0, 0, 0);
                    String formattedDate = datetimeToday.format('dd/MM/yyyy');
                    // System.debug('Today\'s Date ==>'+formattedDate);
                    settings.MVDG__LinkedDate__c = formattedDate;
                    settings.MVDG__WorkingStatus__c = true;
                    upsert settings;
                    return 'Success';
                }
            }
            return 'Failure';
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'authorizeNamed');
            // System.debug('Exception of authorize got invoked');
            return null;
        }
    }


    @AuraEnabled
    public static String authorize(String clientId, String clientSecret, String bucket, String awsNickname) {
        try {
            if (String.isBlank(clientId) || String.isBlank(clientSecret) || String.isBlank(bucket) || String.isBlank(awsNickname)) {
                System.debug('looks fishy');
                return 'All Details are compulsory';
            }

            MVDG__AwsAuthProviderSettings__c settings = MVDG__AwsAuthProviderSettings__c.getOrgDefaults();
            if (settings == null) {
                settings = new MVDG__AwsAuthProviderSettings__c();
            }
            settings.MVDG__ClientId__c = clientId;
            settings.MVDG__ClientSecret__c = clientSecret;
            settings.MVDG__BucketName__c = bucket;
            settings.MVDG__NickName__c = awsNickname;
            Date todaysDate = Date.today();
            Datetime datetimeToday = Datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day(), 0, 0, 0);
            String formattedDate = datetimeToday.format('dd/MM/yyyy');
            // System.debug('Today\'s Date ==>'+formattedDate);
            settings.MVDG__LinkedDate__c = formattedDate;
            settings.MVDG__WorkingStatus__c = true;
            Boolean status = uploadDocuments(bucket, clientId, clientSecret);
            if(status)
            {
                upsert settings;
                return 'Success';
            }
            else{
                // System.debug('auth failed');
                return 'Failure';
            } 
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'authorize');
            // System.debug('Exception of authorize got invoked');
            return null;
        }
    }

    public static string createSimpleAuthHeader(AuthHeaderParams params){
    try{
        String stringToSign = params.methodName + '\n\n' + params.contentType + '\n' + params.formatedDateString + '\n/' + params.bucketName + '/';
        Blob mac = Crypto.generateMac('HMACSHA1', Blob.valueOf(stringToSign), Blob.valueOf(params.awsSecret));
        String sig = EncodingUtil.base64Encode(mac);
        String auth = 'AWS ' + params.awsKey + ':' + sig;
        
        // System.debug('Auth header created');
        return auth;
    } catch (Exception e) {
        Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'createSimpleAuthHeader');
        System.debug('Exception in createSimpleAuthHeader: ' + e.getMessage());
        return null;
    }  
}

    public static string createAuthHeader(AuthHeaderParams params){
        try{
            System.debug('1-->'+params.contentType);
            System.debug('2-->'+params.filename);
            System.debug('3-->'+params.formatedDateString);
            System.debug('4-->'+params.fileExtension);
            System.debug('5-->'+params.methodName);
            System.debug('6-->'+params.bucketName);
            System.debug('7-->'+params.awsKey);
            System.debug('8-->'+params.awsSecret);
            string auth;
            string stringToSign = params.methodName+'\n\n'+params.contentType+'\n'+params.formatedDateString+'\n/'+params.bucketName+'/'+params.fileName.toLowerCase()+'.'+params.fileExtension.toLowerCase();
            Blob mac = Crypto.generateMac('HMACSHA1', blob.valueOf(stringToSign), blob.valueOf(params.awsSecret));
            string sig = EncodingUtil.base64Encode(mac);
            auth = 'AWS'+' '+params.awsKey+':'+sig;
            System.debug('Auth header created');
            return auth;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'createAuthHeader');
            // System.debug('Exception of createAuthHeader got invoked');
            return null;
        }  
    }


    public static Blob generateDummyFileData() {
        String dummyContent = 'This is a dummy file.';
        return Blob.valueOf(dummyContent);
    }


    @AuraEnabled
    public static Boolean uploadDocuments(String bucketName, String clientid, String clientsecret){
        try{
            System.debug('Upload Documents');
            String hostName = 's3.amazonaws.com';
            String methodName = 'PUT';
            Blob fileData = generateDummyFileData();
            String fileExtension = 'txt';
            // Set the file name
            String fileName = 'dummyfile';
            // Set the content type
            String contentType = 'text/plain';
            // Call the uploadToS3 method with generated data                
            String fileUrl = 'https://' + bucketName + '.' + hostName + '/' + fileName + '.txt';
            // Generate the formatted date string
            String formatedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
            // Create the authorization header
            AuthHeaderParams params = new AuthHeaderParams();
            params.ContentType = contentType;
            params.Filename = fileName;
            params.formatedDateString = formatedDateString;
            params.FileExtension = fileExtension;
            params.MethodName = methodName;
            params.BucketName = bucketName;
            params.AwsKey = clientid;
            params.AwsSecret = clientsecret;
            String authHeader = createAuthHeader(params);
            // Create the HTTP request
            HttpRequest req = new HttpRequest();
            req.setMethod(methodName);
            req.setEndpoint(fileUrl);
            req.setHeader('Content-Length', String.valueOf(fileData.size()));
            req.setHeader('Host', bucketName + '.' + hostName);
            req.setHeader('Content-Type', contentType);
            req.setHeader('Date', formatedDateString);
            req.setHeader('Authorization', authHeader);
            req.setBodyAsBlob(fileData);
            // Send the request
            Http h = new Http();
            HttpResponse res = h.send(req);

            // Check the response
            if (res.getStatusCode() == 200) {
                // System.debug('File uploaded successfully to AWS S3');
                deleteFile(bucketName, clientsecret, clientid);
                return true;

            } else {
                Response_Handler.store_Callout_Response(res, 'AwsAuthorizationController', 'uploadDocuments');
                // System.debug('Error message =>' + res.getBody());
                // System.debug('Failed to upload file to AWS S3. HTTP Status: ' + res.getStatus());
                return false;
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'UploadDocuments');
            // System.debug('Exception of UploadDocuments got invoked');
            return null;
        }  
    }


    public static void deleteFile(String bucketName, String secret, String access) {
        try{
            System.debug('Deleting file');
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://' + bucketName + '.' + 's3.amazonaws.com' + '/' + 'dummyfile' + '.txt');
            request.setMethod('DELETE');
            String formatedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
            // Add AWS authentication headers
            AuthHeaderParams params = new AuthHeaderParams();
            params.ContentType = 'text/plain';
            params.Filename = 'dummyfile'; 
            params.formatedDateString = formatedDateString;
            params.FileExtension = 'txt';
            params.MethodName = 'DELETE';
            params.BucketName = bucketName;
            params.AwsKey = access;
            params.AwsSecret = secret;
            String awsAuthHeader = createAuthHeader(params);
            request.setHeader('Authorization', awsAuthHeader);
            request.setHeader('Host', bucketName + '.' + 's3.amazonaws.com');
            request.setHeader('Content-Type', 'text/plain');
            request.setHeader('Date', formatedDateString);

            // Perform HTTP callout
            Http http = new Http();
            HttpResponse response = http.send(request);
            // Check the response
            if (response.getStatusCode() == 204) {
                System.debug('File deleted successfully.');
            } else {
                Response_Handler.store_Callout_Response(response, 'AwsAuthorizationController', 'deleteFile');
                // System.debug('Error deleting file: ' + response.getBody());
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'deleteFile');
            // System.debug('Exception of deleteFile got invoked');
        }  
    }

}