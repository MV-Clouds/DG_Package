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

/*
*********************************************************
@description     : wrapper containing data of all parameters required to create signature create button objects
@param           : contentType {String} - Contains string value for contentType to create signature
@param           : formatedDateString {String} - Contains string value for formatedDateString to create signature
@param           : methodName {String} - Contains string value for methodName to create signature
@param           : bucketName {String} - Contains string value for bucketName to create signature
@param           : awsKey {String} - Contains string value for awsKey to create signature
@param           : awsSecret {String} - Contains string value for awsSecret to create signature
********************************************************
*/
    public class AuthHeaderParams {
        @AuraEnabled public String contentType { get; set; }
        @AuraEnabled public String formatedDateString { get; set; }
        @AuraEnabled public String methodName { get; set; }
        @AuraEnabled public String bucketName { get; set; }
        @AuraEnabled public String awsKey { get; set; }
        @AuraEnabled public String awsSecret { get; set; }    
    }

/*
*********************************************************
@description     : Method is used to make a checking if aws integration is active or not
@param           : none
@return          : {Map<String,String>} - details of aws integration
********************************************************
*/
    @AuraEnabled
    public static Map<String, Object> checkawsauth(){
        try{
            Aws_Credentials__c settings = [SELECT Id,BucketName__c,ClientId__c,ClientSecret__c,LinkedDate__c,WorkingStatus__c,NickName__c,NamedCredential__c FROM Aws_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED];

            Map<String, Object> result = new Map<String, Object>();
            if (settings != null  && (settings.BucketName__c != '' && settings.LinkedDate__c != '' && settings.NickName__c != '') || (settings.NamedCredential__c != '' || settings.NamedCredential__c != null)) {
                Boolean working = verifyAuth();
                settings = [SELECT BucketName__c,ClientId__c,ClientSecret__c,LinkedDate__c,WorkingStatus__c,NickName__c,NamedCredential__c FROM Aws_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
                if(working){
                    result.put('bucket', settings.BucketName__c);
                    result.put('linkdate', settings.LinkedDate__c);
                    result.put('active', settings.WorkingStatus__c);
                    result.put('name', settings.NickName__c);
                    return result;
                }
            }
            result.put('error', 'Error obtaining details: ');
            return result;
        }catch(Exception e){
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'checkawsauth');
            return null;
        }
    }

/*
*********************************************************
@description     : Method is used to delete details stored in custom setting
@param           : none
@return          : {Boolean} - success or not
********************************************************
*/
    @AuraEnabled
    public static Boolean unauthorize(){
        try {
            List<Aws_Credentials__c> settingsList = [SELECT Id,BucketName__c,ClientId__c,ClientSecret__c,LinkedDate__c,WorkingStatus__c,NickName__c,NamedCredential__c FROM Aws_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
            Aws_Credentials__c settings;
            if(!settingsList.isEmpty()){
                settings = settingsList[0];
                if(settings != null){
                    settings.BucketName__c = '';
                    settings.ClientId__c = '';
                    settings.ClientSecret__c = '';
                    settings.LinkedDate__c = '';
                    settings.WorkingStatus__c = false;
                    settings.NickName__c = '';
                    settings.NamedCredential__c = '';
                    upsert as user settings;
                    return true;
                }
            }
            
            return false;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'unauthorize');
            return null;
        }
    }


/*
*********************************************************
@description     : Method is used to make a checking if aws integration is active or not It checks for both named credential and signature
@param           : none
@return          : {Boolean} - TRUE if success
********************************************************
*/
    @AuraEnabled
    public static Boolean verifyAuth(){
        try {
            List<Aws_Credentials__c> settingsList = [SELECT BucketName__c,ClientId__c,ClientSecret__c,LinkedDate__c,WorkingStatus__c,NickName__c,NamedCredential__c FROM Aws_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
            Aws_Credentials__c settings;
            if(!settingsList.isEmpty()){
                settings = settingsList[0];
            }
            else{
                settings = new Aws_Credentials__c();
            }
            if(String.isBlank(settings.NamedCredential__c) && String.isNotBlank(settings.BucketName__c) && String.isNotBlank(settings.ClientId__c) && String.isNotBlank(settings.ClientSecret__c)){
                if(testCallout(settings.BucketName__c, settings.ClientId__c, settings.ClientSecret__c)){
                    settings.WorkingStatus__c = true;
                    update as user settings;
                    return true;
                }      
                settings.WorkingStatus__c = false;
                update as user settings;
                return false;
            }else if(string.isNotBlank(settings.NamedCredential__c)){
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:'+settings.NamedCredential__c);
                req.setMethod('GET');
                Http http = new http();
                HttpResponse res = http.send(req);
                if(res.getStatusCode() == 200){
                    settings.WorkingStatus__c = true;
                    update as user settings;
                    return true;
                }
                else{
                    settings.WorkingStatus__c = false;
                    update as user settings;
                    Response_Handler.store_Callout_Response(res, 'AwsAuthorizationController', 'verifyAuth');
                    return false;
                }
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'verifyAuth');
        }
        return false;
    }

/*
*********************************************************
@description     : Method is used to integrate with named credential
@param           : none
@return          : {String} - 'Success' if everything works
********************************************************
*/
    @AuraEnabled
    public static String authorizeNamed(String named){
        try{
            if(named != null){
                Integer checkNamed = [SELECT Count() FROM NamedCredential WHERE DeveloperName = :named WITH SECURITY_ENFORCED LIMIT 1];
                if(Test.isRunningTest()){
                    checkNamed = 1;
                }
                if(checkNamed == 1){
                    Aws_Credentials__c settings = [SELECT WorkingStatus__c,NamedCredential__c,NickName__c,BucketName__c,LinkedDate__c FROM Aws_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
                    if (settings == null) {
                        settings = new Aws_Credentials__c();
                    }
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint('callout:'+named);
                    req.setMethod('GET');
                    Http http = new http();
                    HttpResponse res = http.send(req);
                    if(res.getStatusCode() == 200){
                        settings.WorkingStatus__c = true;
                    }
                    else {
                        return 'Failure';
                    }
                    
                    settings.NamedCredential__c = named;
                    settings.NickName__c = named;
                    settings.BucketName__c = 'Unknown';
                    Date todaysDate = Date.today();
                    Datetime datetimeToday = Datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day(), 0, 0, 0);
                    String formattedDate = datetimeToday.format('dd/MM/yyyy');
                    settings.LinkedDate__c = formattedDate;
                    settings.WorkingStatus__c = true;
                    upsert as user settings;
                    return 'Success';
                }
            }
            return 'Failure';
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'authorizeNamed');
            return null;
        }
    }

/*
*********************************************************
@description     : Method is used to integrate without named credential
@param           : none
@return          : {String} - 'Success' if everything works
********************************************************
*/
    @AuraEnabled
    public static String authorize(String clientId, String clientSecret, String bucket, String awsNickname) {
        try {
            if (String.isBlank(clientId) || String.isBlank(clientSecret) || String.isBlank(bucket) || String.isBlank(awsNickname)) {
                return 'All Details are compulsory';
            }
            List<Aws_Credentials__c> settingsList = [SELECT Id,BucketName__c,ClientId__c,ClientSecret__c,LinkedDate__c,WorkingStatus__c,NickName__c,NamedCredential__c FROM Aws_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];

            Aws_Credentials__c settings;
            if (!settingsList.isEmpty()) {
                settings = settingsList[0];
            }
            else{
                settings = new Aws_Credentials__c();
            }
            settings.ClientId__c = clientId;
            settings.ClientSecret__c = clientSecret;
            settings.BucketName__c = bucket;
            settings.NickName__c = awsNickname;
            Date todaysDate = Date.today();
            Datetime datetimeToday = Datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day(), 0, 0, 0);
            String formattedDate = datetimeToday.format('dd/MM/yyyy');
            settings.LinkedDate__c = formattedDate;
            settings.WorkingStatus__c = true;
            Boolean status = testCallout(bucket, clientId, clientSecret);
            if(status)
            {
                upsert as user settings;
                return 'Success';
            }
            else{
                return 'Failure';
            } 
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'authorize');
            return null;
        }
    }

/*
*********************************************************
@description     : Method is used to create signature to make callout
@param           : AuthHeaderParams (Wrapper Class)
@return          : {String} - return's signature
********************************************************
*/
    public static string createSimpleAuthHeader(AuthHeaderParams params){
    try{
        String stringToSign = params.methodName + '\n\n' + params.contentType + '\n' + params.formatedDateString + '\n/' + params.bucketName + '/';
        Blob mac = Crypto.generateMac('HMACSHA1', Blob.valueOf(stringToSign), Blob.valueOf(params.awsSecret));
        String sig = EncodingUtil.base64Encode(mac);
        String auth = 'AWS ' + params.awsKey + ':' + sig;
        return auth;
    } catch (Exception e) {
        Log_Handler.store_Exception(e, 'AwsAuthorizationController', 'createSimpleAuthHeader');
        return null;
    }  
}

/*
*********************************************************
@description     : Method is used to create signature to make callout
@param           : Bucket {String} - name of bucket
@param           : clientId {String} - value of clientId
@param           : clientSecret {String} - value of clientSecret
@return          : {String} - return's signature
********************************************************
*/
    public static Boolean testCallout(String Bucket, String clientId, String clientSecret){
        AuthHeaderParams params = new AuthHeaderParams();
        params.methodName = 'GET';
        params.bucketName = Bucket;
        params.awsKey = clientId;
        params.awsSecret = clientSecret;
        params.contentType = '';
        params.formatedDateString = Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss \'GMT\'');
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://'+Bucket+ '.s3.amazonaws.com');
        req.setMethod('GET');
        req.setHeader('Content-Type', '');
        req.setHeader('authorization', createSimpleAuthHeader(params));
        req.setHeader('Host', Bucket + '.s3.amazonaws.com');
        req.setHeader('Date', Datetime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss \'GMT\''));
        req.setHeader('Connection', 'keep-alive');
        req.setHeader('accept', '*/*');
        Http http = new Http();
        HttpResponse res = http.send(req);
        if(res.getStatusCode() == 200){
            return true;
        }
        else{
            Response_Handler.store_Callout_Response(res, 'AwsAuthorizationController', 'verifyAuth');
            return false;
        }
    }

}