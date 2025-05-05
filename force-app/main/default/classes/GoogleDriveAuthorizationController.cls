/*******************************************************
* Name          : GoogleDriveAuthorizationController
* Author        : Tirth
* Create Date   : 15/04/2024
* UsedBy        : integrationDashBoard Component
* Test Class    : GoogleDriveAuthorizationControllerTest
* Description   : Apex Class used for managing integration of google drive using single click.
* Company       : MV Clouds
*******************************************************/
public with sharing class GoogleDriveAuthorizationController {

/*
*********************************************************
@description     : Method is used to check user wide google auth integration
@param           : none
@return          : result {Map<String,Object>} - return integration details if successful
********************************************************
*/
  @AuraEnabled
  public static Map<String, Object> checkgoogleauth(){
      try{
          Integer count = [SELECT COUNT() FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getUserId() WITH SECURITY_ENFORCED];
          Map<String, Object> result = new Map<String, Object>();
          if(count > 0){
              List<MVDG__Google_Credentials__c> settingsList = [SELECT Id, MVDG__refresh_token__c, MVDG__access_token__c, MVDG__username__c, MVDG__email__c, MVDG__LinkedDate__c, MVDG__WorkingStatus__c, SetupOwnerId, Name FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
              MVDG__Google_Credentials__c settings;
              if(!settingsList.isEmpty()){
                  settings = settingsList[0];
              }
              if (settings != null && settings.MVDG__refresh_token__c != null && settings.MVDG__access_token__c != null && settings.MVDG__username__c != null && settings.MVDG__email__c != null && settings.MVDG__LinkedDate__c != null) {
                      Boolean working = getToken(false);
                      settings = [SELECT Id, MVDG__refresh_token__c, MVDG__access_token__c, MVDG__username__c, MVDG__email__c, MVDG__LinkedDate__c, MVDG__WorkingStatus__c, SetupOwnerId, Name FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
                      result.put('name', settings.MVDG__username__c);
                      result.put('email', settings.MVDG__email__c);
                      result.put('linkdate', settings.MVDG__LinkedDate__c);
                      result.put('active', settings.MVDG__WorkingStatus__c);
                  return result;
              }
          }
          result.put('error', 'Error obtaining details: ');
          return result;
      }catch(Exception e){
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'checkgoogleauth');
          return null;
      }
  }

/*
*********************************************************
@description     : Method is used to check org wide google auth integration
@param           : none
@return          : result {Map<String,Object>} - return integration details if successful
********************************************************
*/
  @AuraEnabled
  public static Map<String, Object> checkorggoogleauth(){
      try{
          List<MVDG__Google_Credentials__c> settingsList = [SELECT Id,MVDG__access_token__c,MVDG__LinkedDate__c,MVDG__refresh_token__c,MVDG__photolink__c,MVDG__username__c,MVDG__email__c,MVDG__WorkingStatus__c  FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
          MVDG__Google_Credentials__c settings;
          if(!settingsList.isEmpty()){
                settings = settingsList[0];
            }
          Map<String, Object> result = new Map<String, Object>();
          if (settings != null && settings.MVDG__refresh_token__c != null && settings.MVDG__access_token__c != null && settings.MVDG__username__c != null && settings.MVDG__email__c != null && settings.MVDG__LinkedDate__c != null) {
                  Boolean working = getToken(true);
                  settings = [SELECT Id,MVDG__access_token__c,MVDG__LinkedDate__c,MVDG__refresh_token__c,MVDG__photolink__c,MVDG__username__c,MVDG__email__c,MVDG__WorkingStatus__c  FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
                  result.put('name', settings.MVDG__username__c);
                  result.put('email', settings.MVDG__email__c);
                  result.put('linkdate', settings.MVDG__LinkedDate__c);
                  result.put('active', settings.MVDG__WorkingStatus__c);
              return result;
          }
          result.put('error', 'Error obtaining details: ');
          return result;
      }catch(Exception e){
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'checkorggoogleauth');
          return null;
      }
  }

/*
*********************************************************
@description     : Method is used to check if org wide exists
@param           : none
@return          : {Boolean} - return integration details if successful
********************************************************
*/
  @AuraEnabled
  public static Boolean isOrgWide(){
    String UserId = UserInfo.getUserId();
    Integer access = 0;
    if(UserId != null){
        access = [SELECT COUNT() FROM PermissionSetAssignment 
        WHERE PermissionSet.Name = 'DocGenius_Admin_Permissions'
        AND AssigneeId =: UserId WITH SECURITY_ENFORCED];
    }
    if(access == 1){
      try {
          List<MVDG__Google_Credentials__c> settingsList = [SELECT Id,MVDG__access_token__c,MVDG__LinkedDate__c,MVDG__refresh_token__c,MVDG__photolink__c,MVDG__username__c,MVDG__email__c,MVDG__WorkingStatus__c  FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
          MVDG__Google_Credentials__c settings;
          if(!settingsList.isEmpty()){
              settings = settingsList[0];
          }
          else{
              settings = new MVDG__Google_Credentials__c();
          }
          if(settings != null && settings.MVDG__refresh_token__c != null && settings.MVDG__access_token__c != null){
              return true;
          }
          else{
              return false;
          }
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'isOrgWide');
          return false;
      }
    }
    return true;
  }

/*
*********************************************************
@description     : Method is used to get access token
@param           : isOrg {Boolean} - Let them know if the access token is for org wide or user wide
@return          : {Boolean} - return integration details if successful
********************************************************
*/
  public static Boolean getToken(Boolean isOrg){
      try {
          List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();
          MVDG__Google_Credentials__c settings;
          if(isOrg){
              settings = [SELECT Id,MVDG__access_token__c,MVDG__LinkedDate__c,MVDG__refresh_token__c,MVDG__photolink__c,MVDG__username__c,MVDG__email__c,MVDG__WorkingStatus__c  FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
          }
          else{
              settings = [SELECT Id,MVDG__access_token__c,MVDG__LinkedDate__c,MVDG__refresh_token__c,MVDG__photolink__c,MVDG__username__c,MVDG__email__c,MVDG__WorkingStatus__c  FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
          }
          String endpoint = 'https://oauth2.googleapis.com/token';
          HttpRequest request = new HttpRequest();
          request.setEndpoint(endpoint);
          request.setMethod('POST');
          request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
          request.setBody('refresh_token=' + settings.MVDG__refresh_token__c +
                          '&client_id=' + mdata[0].MVDG__CID__c +
                          '&client_secret=' + mdata[0].MVDG__CSEC__c +
                          '&grant_type=refresh_token');


          Http http = new Http();
          HttpResponse response = http.send(request);

          if (response.getStatusCode() == 200) {
              Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
              String newToken = (String) jsonResponse.get('access_token');
              settings.MVDG__access_token__c = newToken;
              settings.MVDG__WorkingStatus__c = true;
                  upsert as user settings;


              return true;
          }
          else{
              Response_Handler.store_Callout_Response(response, 'GoogleDriveAuthorizationController', 'getToken');
              settings.MVDG__WorkingStatus__c = false;
              upsert as user settings;
              return false;
          }
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'getToken');
          return false;
      }
  }


/*
*********************************************************
@description     : Method is used to get Auth code
@param           : clientId {String} - GoogleApp Client ID
@param           : clientSecret {String} - GoogleApp Client Secret
@return          : {String} - AuthCode
********************************************************
*/
  @AuraEnabled
  public static String getAuthCode(String clientId, String clientSecret) {
      try{
          if (String.isBlank(clientId) || String.isBlank(clientSecret)) {
              return 'Both Client ID and Client Secret are required.';
          }
          List<MVDG__Google_Credentials__c> settingsList = [SELECT Id,MVDG__access_token__c,MVDG__LinkedDate__c,MVDG__refresh_token__c,MVDG__photolink__c,MVDG__username__c,MVDG__email__c,MVDG__WorkingStatus__c  FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
          MVDG__Google_Credentials__c settings;
          if (!settingsList.isEmpty()) {
                settings = settingsList[0];
          }else{
              settings = new MVDG__Google_Credentials__c();
          }
          if(Test.isRunningTest()){
            clientId = 'Mock';
            clientSecret = 'Mock';
            String authUrl = authcode(clientId, clientSecret);
            return authUrl;
          }
          List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();
          clientId = mdata[0].MVDG__CID__c;
          clientSecret = mdata[0].MVDG__CSEC__c;
          String authUrl = authcode(clientId, clientSecret);
          return authUrl;
      }
      catch(Exception e){
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'getAuthCode');
          return null;
      }
  }



/* 
*********************************************************
@description     : Method is used to get Auth url
@param           : clientId {String} - GoogleApp Client ID
@param           : clientSecret {String} - GoogleApp Client Secret
@return          : {String} - AuthCode
********************************************************
*/
  public static String authcode(String clientId, String clientSecret){
      try{
          String authorizeUrl = 'https://accounts.google.com/o/oauth2/auth';
          String redirectUri = System.label.MVDG.AuthCode;  //REPLACE IT WITH force.com site URL
          String googleDriveScope = 'https://www.googleapis.com/auth/drive.file';
          String authUrl = authorizeUrl + '?response_type=code' +
                          '&client_id=' + clientId +
                          '&redirect_uri=' + redirectUri +
                          '&access_type=offline' +
                          '&approval_prompt=force'+
                          '&state=state_parameter_passthrough_value' +
                          '&scope=' + googleDriveScope;
          return authUrl;
      }
      catch(Exception e){
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'authcode');
          return null;
      }
  }



/*
*********************************************************
@description     : Method is used to integrate with google
@param           : authCode {String} - GoogleApp Client ID
@param           : isOrg {Boolean} - Let them know if the access token is for org wide or user wide
@return          : {String} - success or not
********************************************************
*/
  @AuraEnabled
  public static String authorizeGoogle(String authcode, Boolean isOrg, Boolean isAccess){
      try{
          List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();

          List<MVDG__Google_Credentials__c> defsettingsList = [SELECT Id,MVDG__access_token__c,MVDG__LinkedDate__c,MVDG__refresh_token__c,MVDG__photolink__c,MVDG__username__c,MVDG__email__c,MVDG__WorkingStatus__c  FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
          MVDG__Google_Credentials__c defsettings;
          if(!defsettingsList.isEmpty()){
              defsettings = defsettingsList[0];
          }
          else{
             defsettings = new MVDG__Google_Credentials__c();
          }
          MVDG__Google_Credentials__c settings = new MVDG__Google_Credentials__c();
          String clientId;
          String clientSecret;
          String redirectUri = System.Label.MVDG.AuthCode;
          List<String> credentials = new List<String>();

          if(Test.isRunningTest()){
            clientId = 'Mock';
            clientSecret = 'Mock';
            credentials.add('Mock');
            credentials.add('Mock');
          }
          else{
            clientId = mdata[0].MVDG__CID__c;
            clientSecret = mdata[0].MVDG__CSEC__c;
            credentials.add(mdata[0].MVDG__CID__c);
            credentials.add(mdata[0].MVDG__CSEC__c);       
          }
          Map<String, String> result = generaterefreshtoken(credentials, redirectUri, authcode);
          String refresh = result.get('refresh_token');
          String access = result.get('access_token');
          if(refresh != null){
          settings.MVDG__refresh_token__c = refresh;
          defsettings.MVDG__refresh_token__c = refresh;
        
          if(access != null){
              settings.MVDG__access_token__c = access;
              Date todaysDate = Date.today();
              Datetime datetimeToday = Datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day(), 0, 0, 0);
              String formattedDate = datetimeToday.format('dd/MM/yyyy');
              settings.MVDG__LinkedDate__c = formattedDate;
              String userdetails = fetchUserDetails(access);
              Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(userdetails);
              Map<String, Object> userObject = (Map<String, Object>) parsedResponse.get('user');
              String emailAddress = (String) userObject.get('emailAddress');
              String displayName = (String) userObject.get('displayName');
              String userPhoto = (String) userObject.get('photoLink');
              settings.MVDG__photolink__c = userPhoto;
              settings.MVDG__username__c = displayName;
              settings.MVDG__email__c = emailAddress;
              settings.MVDG__WorkingStatus__c = true;
              defsettings.MVDG__access_token__c = access;
              defsettings.MVDG__photolink__c = userPhoto;
              defsettings.MVDG__LinkedDate__c = formattedDate;
              defsettings.MVDG__username__c = displayName;
              defsettings.MVDG__email__c = emailAddress;
              defsettings.MVDG__WorkingStatus__c = true;
            
          }
          if(isOrg && isAccess){
              defsettings.SetupOwnerId = UserInfo.getOrganizationId();
              upsert as user defsettings;
              settings.SetupOwnerId = UserInfo.getUserId();
              upsert as user settings;
          }else{
              settings.SetupOwnerId = UserInfo.getUserId();
              upsert as user settings;
          }
        
          return 'success';
      }
      else{
          return 'fail';
      }
      }catch(Exception e){
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'authorizeGoogle');
          return null;
      }
  }


/*
**************************************************
@description: This method is used to fetch the user details from google
@param: String accessToken, String endpoint
@return: {HTTPRequest} - return request to fetch data from google
**************************************************
*/
  public static HttpRequest getuserdata(String acctok){
      try {
          HttpRequest req= new HttpRequest();
          req.setEndpoint('https://www.googleapis.com/drive/v3/about?fields=user');
          req.setHeader('Authorization', 'Bearer ' + acctok);
          req.setMethod('GET');
          return req;
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'getUerData');
          return null;
      }   
  }



/*
**************************************************
@description: This method is used to fetch the user details from google
@param: String access - access Token
@return: {String} - return response recieved from google
**************************************************
*/
  @AuraEnabled
  public static String fetchUserDetails(String access) {
      try {
          String acctok = access;
          HttpRequest req = getuserdata(acctok);


          HttpResponse resp = sendHttpRequest(req);
        
          if (resp.getStatusCode() == 200) {
              String resbody = resp.getBody();
              String respbody = resbody != null ? resbody : '';
              return respbody;
          }
          else{
              Response_Handler.store_Callout_Response(resp, 'GoogleDriveAuthorizationController', 'fetchUserDetails');
              return 'false';
          }
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'fetchUserDetails');
          return null;
      }
  }



/*
**************************************************
@description: This method is used to send request
@param: req {HttpRequest} - Request recieved to be sent to google
@return: {HttpResponse} - return response recieved from google
**************************************************
*/
  private static HttpResponse sendHttpRequest(HttpRequest req) {
      try {
          Http h = new Http();
          req.setTimeout(60000);
          return h.send(req);
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'sendHttpRequest');
          return null;
      }
  }


/*
********************************
@description: This method is used to fetch refresh token from google
@param: credentials {List<String>} - credential details
@param: redirectUri {String} - redirect uri
@param: authCode {String} - auth code recieved after authorization
@return: {Map<String,String>} - return response recieved from google
********************************
*/
public static Map<String, String> generaterefreshtoken(List<String> credentials, String redirectUri, String authcode){
      try{
          String scope = 'https://www.googleapis.com/auth/drive.file';
          String endpoint = 'https://oauth2.googleapis.com/token';
          HttpRequest request = new HttpRequest();
          request.setEndpoint(endpoint);
          request.setMethod('POST');
          request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
          request.setHeader('Accept-Encoding', 'gzip, deflate, br');
          request.setHeader('Connection', 'keep-alive');
          request.setBody('code=' + authcode +
                          '&client_id=' + credentials[0] +
                          '&client_secret=' + credentials[1] +
                          '&redirect_uri=' + redirectUri +
                          '&grant_type=authorization_code');
           Http http = new Http();
          HttpResponse response = http.send(request);
          Map<String, String> result = new Map<String, String>();

          if (response.getStatusCode() == 200) {
              Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

              result.put('refresh_token', (String) jsonResponse.get('refresh_token'));
              result.put('access_token', (String) jsonResponse.get('access_token'));
          } else {
              Response_Handler.store_Callout_Response(response, 'GoogleDriveAuthorizationController', 'generaterefreshtoken');
              result.put('error', 'Error obtaining refresh token & access token. HTTP Status Code: ' + response.getStatusCode() +
                                  ', Response Body: ' + response.getBody());
          }
          return result;
      }catch(Exception e){
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'generaterefreshtoken');
          return null;
      }
  }

  

/*
********************************
@description: This method is used to unauthorize google
@param: none
@return: {Boolean} - returns true after successful unauthorization
********************************
*/
   @AuraEnabled
  public static Boolean unauthorize(){
      try {
          MVDG__Google_Credentials__c settings = [SELECT Id,MVDG__access_token__c,MVDG__LinkedDate__c,MVDG__refresh_token__c,MVDG__photolink__c,MVDG__username__c,MVDG__email__c,MVDG__WorkingStatus__c  FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
          if(settings != null){
                delete as user settings;
                return true;
          }
          return false;
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'unauthorize');
          return null;
      }
  }

/*
********************************
@description: This method is used to unauthorize google org wide
@param: none
@return: {Boolean} - returns true after successful org wide unauthorization
********************************
*/
  @AuraEnabled
  public static Boolean orgunauthorize(){
      try {
          List<MVDG__Google_Credentials__c> settingsList = [SELECT Id,MVDG__access_token__c,MVDG__LinkedDate__c,MVDG__refresh_token__c,MVDG__photolink__c,MVDG__username__c,MVDG__email__c,MVDG__WorkingStatus__c  FROM MVDG__Google_Credentials__c WHERE SetupOwnerId =: UserInfo.getOrganizationId() WITH SECURITY_ENFORCED LIMIT 1];
          MVDG__Google_Credentials__c settings;
            if(!settingsList.isEmpty()){
                settings = settingsList[0];
            }
                if(settings != null){
                    settings.MVDG__refresh_token__c = '';
                    settings.MVDG__access_token__c = '';
                    settings.MVDG__photolink__c = '';
                    settings.MVDG__LinkedDate__c = '';
                    settings.MVDG__email__c = '';
                    settings.MVDG__username__c = '';
                    settings.MVDG__WorkingStatus__c = false;
                    update as user settings;
                    return true;
                }
           return false;
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'orgunauthorize');
          return null;
      }
    }

  @AuraEnabled
  public static String checkAccess(){
    String UserId = UserInfo.getUserId();
    List<PermissionSetAssignment> access = new List<PermissionSetAssignment>();
    if(UserId != null){
        access = [SELECT Id, PermissionSet.Name FROM PermissionSetAssignment 
        WHERE (PermissionSet.Name = 'DocGenius_Admin_Permissions' OR PermissionSet.Name = 'DocGenius_Standard_Permissions')
        AND AssigneeId =: UserId WITH SECURITY_ENFORCED];
    }
    if(!access.isEmpty()){
        for (PermissionSetAssignment psa : access) {
            if (psa.PermissionSet.Name == 'DocGenius_Admin_Permissions') {
                return 'DocGenius_Admin_Permissions';  
            }
        }
        return 'DocGenius_Standard_Permissions';
    }
    return null;
    }

}