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
  @AuraEnabled
  public static Map<String, Object> checkgoogleauth(){
      try{
          Integer count = [SELECT COUNT() FROM MVDG__AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId() WITH SECURITY_ENFORCED];
          Map<String, Object> result = new Map<String, Object>();
          if(count > 0){
              MVDG__AuthProviderSettings__c settings = [SELECT Id, MVDG__refresh_token__c, MVDG__access_token__c, MVDG__username__c, MVDG__email__c, MVDG__LinkedDate__c, MVDG__WorkingStatus__c, SetupOwnerId, Name FROM MVDG__AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId() WITH SECURITY_ENFORCED];
              if (settings != null && settings.MVDG__refresh_token__c != null && settings.MVDG__access_token__c != null && settings.MVDG__username__c != null && settings.MVDG__email__c != null && settings.MVDG__LinkedDate__c != null) {
                      Boolean working = getToken(false);
                      settings = [SELECT Id, MVDG__refresh_token__c, MVDG__access_token__c, MVDG__username__c, MVDG__email__c, MVDG__LinkedDate__c, MVDG__WorkingStatus__c, SetupOwnerId, Name FROM MVDG__AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId() WITH SECURITY_ENFORCED];
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


  @AuraEnabled
  public static Map<String, Object> checkorggoogleauth(){
      try{
          MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
          Map<String, Object> result = new Map<String, Object>();
          if (settings != null && settings.MVDG__refresh_token__c != null && settings.MVDG__access_token__c != null && settings.MVDG__username__c != null && settings.MVDG__email__c != null && settings.MVDG__LinkedDate__c != null) {
                  Boolean working = getToken(true);
                  settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
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


  @AuraEnabled
  public static Boolean isOrgWide(){
      try {
          MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
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


  public static Boolean getToken(Boolean isOrg){
      try {
          List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();
          System.debug('This is client id'+mdata[0].MVDG__CID__c);
          System.debug('This is client secret'+mdata[0].MVDG__CSEC__c);
          MVDG__AuthProviderSettings__c settings;
          if(isOrg){
              settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
          }
          else{
              settings = MVDG__AuthProviderSettings__c.getInstance(UserInfo.getUserId());
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
              if(!Schema.sObjectType.MVDG__AuthProviderSettings__c.fields.MVDG__access_token__c.isUpdateable() || !Schema.sObjectType.MVDG__AuthProviderSettings__c.fields.MVDG__WorkingStatus__c.isUpdateable() || !Schema.sObjectType.MVDG__AuthProviderSettings__c.fields.MVDG__access_token__c.isCreateable() || !Schema.sObjectType.MVDG__AuthProviderSettings__c.fields.MVDG__WorkingStatus__c.isCreateable()){
                  return null;
              }
                  upsert settings;


              return true;
          }
          else{
              Response_Handler.store_Callout_Response(response, 'GoogleDriveAuthorizationController', 'getToken');
              settings.MVDG__WorkingStatus__c = false;
              upsert settings;
              return false;
          }
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'getToken');
          return false;
      }
  }


  @AuraEnabled
  public static String getAuthCode(String clientId, String clientSecret) {
      try{
          if (String.isBlank(clientId) || String.isBlank(clientSecret)) {
              return 'Both Client ID and Client Secret are required.';
          }


          MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
          if (settings == null) {
              settings = new MVDG__AuthProviderSettings__c();
          }
          List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();
          System.debug('This is client id'+mdata[0].MVDG__CID__c);
          System.debug('This is client secret'+mdata[0].MVDG__CSEC__c);


          clientId = mdata[0].MVDG__CID__c;
          clientSecret = mdata[0].MVDG__CSEC__c;


          // settings.MVDG__ClientId__c = clientId;
          // settings.MVDG__ClientSecret__c = clientSecret;


          String authUrl = authcode(clientId, clientSecret);
          return authUrl;
      }
      catch(Exception e){
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'getAuthCode');
          return null;
      }
  }




  public static String authcode(String clientId, String clientSecret){
      try{
          String authorizeUrl = 'https://accounts.google.com/o/oauth2/auth';
          String redirectUri = 'https://mvclouds28-dev-ed.develop.my.salesforce-sites.com/googleauth';  //REPLACE IT WITH VFPAGE URL
          String googleDriveScope = 'https://www.googleapis.com/auth/drive.file https://www.googleapis.com/auth/drive.readonly';
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




  @AuraEnabled
  public static String authorizeGoogle(String authcode, Boolean isOrg){
      try{
          List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();
          System.debug('This is client id'+mdata[0].MVDG__CID__c);
          System.debug('This is client secret'+mdata[0].MVDG__CSEC__c);
      MVDG__AuthProviderSettings__c defsettings = MVDG__AuthProviderSettings__c.getOrgDefaults();
      MVDG__AuthProviderSettings__c settings = new MVDG__AuthProviderSettings__c();
      string client_id = mdata[0].MVDG__CID__c;
      string client_secret = mdata[0].MVDG__CSEC__c;
      // settings.MVDG__ClientId__c = client_id;
      // settings.MVDG__ClientSecret__c = client_secret;
      // defsettings.MVDG__ClientId__c = client_id;
      // defsettings.MVDG__ClientSecret__c = clientSecret;
      // System.debug(client_id);
      // System.debug(client_secret);
      String redirectUri = 'https://mvclouds28-dev-ed.develop.my.salesforce-sites.com/googleauth';          
      Map<String, String> result = generaterefreshtoken(client_id, client_secret, redirectUri, authcode);
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
              // System.debug('Email Address: ' + emailAddress);
              String displayName = (String) userObject.get('displayName');
              // System.debug('Display Name: ' + displayName);
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
          System.debug('isOrg = '+isOrg);
          if(isOrg){
              // System.debug('isOrg = '+isOrg);
              defsettings.SetupOwnerId = UserInfo.getOrganizationId();
              upsert defsettings;
              settings.SetupOwnerId = UserInfo.getUserId();
              upsert settings;
          }else{
              settings.SetupOwnerId = UserInfo.getUserId();
              upsert settings;
          }
        
          return 'success';
      }
      else{
          return 'fail';
      }
      }catch(Exception e){
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'getuserdata');
          // system.debug('exception in GoogleDriveAuthorize : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber());
          return null;
      }
  }




  public static HttpRequest getuserdata(String acctok){
      try {
          HttpRequest req= new HttpRequest();
          req.setEndpoint('https://www.googleapis.com/drive/v3/about?fields=user');
          req.setHeader('Authorization', 'Bearer ' + acctok);
          req.setMethod('GET');
          return req;
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'getUerData');
          // System.debug('Exception of getuserdata got invoked');
          return null;
      }   
  }




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
          // System.debug('Exception of fetchUserDetails got invoked');
          return null;
      }
  }




  private static HttpResponse sendHttpRequest(HttpRequest req) {
      try {
          Http h = new Http();
          req.setTimeout(60000);
          return h.send(req);
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'sendHttpRequest');
          // System.debug('Exception of sendHttpRequest got invoked');
          return null;
      }
  }




  public static Map<String, String> generaterefreshtoken(String clientId, String clientSecret, String redirectUri, String authcode){
      try{
          System.debug(clientId);
          System.debug(clientSecret);
          System.debug(redirectUri);
          String scope = 'https://www.googleapis.com/auth/drive.file https://www.googleapis.com/auth/drive.readonly';
          String endpoint = 'https://oauth2.googleapis.com/token';
          HttpRequest request = new HttpRequest();
          request.setEndpoint(endpoint);
          request.setMethod('POST');
          request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
          request.setHeader('Accept-Encoding', 'gzip, deflate, br');
          request.setHeader('Connection', 'keep-alive');
          // System.debug(authcode);
          request.setBody('code=' + authcode +
                          '&client_id=' + clientId +
                          '&client_secret=' + clientSecret +
                          '&redirect_uri=' + redirectUri +
                          '&grant_type=authorization_code');
           Http http = new Http();
          HttpResponse response = http.send(request);
          // Parse the response and extract refresh token
          Map<String, String> result = new Map<String, String>();
          // System.debug(response.getStatusCode());
          // System.debug(response.getBody());
          if (response.getStatusCode() == 200) {
              Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
              // System.debug(jsonResponse.get('scope'));
              // System.debug(jsonResponse);
              // System.debug('access token : '+(String) jsonResponse.get('access_token'));
              // System.debug('refresh token : '+(String) jsonResponse.get('refresh_token'));
              result.put('refresh_token', (String) jsonResponse.get('refresh_token'));
              result.put('access_token', (String) jsonResponse.get('access_token'));
          } else {
              // Handle error response
              Response_Handler.store_Callout_Response(response, 'GoogleDriveAuthorizationController', 'generaterefreshtoken');
              result.put('error', 'Error obtaining refresh token & access token. HTTP Status Code: ' + response.getStatusCode() +
                                  ', Response Body: ' + response.getBody());
          }
          return result;
      }catch(Exception e){
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'generaterefreshtoken');
              // system.debug('exception in mappingFieldDataVF : ' +  e.getStackTraceString() +'\n'+ 'Line Number : ' + e.getLineNumber());
          return null;
      }
  }

  public static Boolean revokeToken(String token){
       try{
       Http http = new Http();
       HttpRequest request = new HttpRequest();
       request.setEndpoint('https://oauth2.googleapis.com/revoke');
       request.setMethod('POST');
       request.setHeader('Content-Type', 'application/x-www-form-urlencoded');


       String body = 'token=' + EncodingUtil.urlEncode(token, 'UTF-8');
       request.setBody(body);


       HttpResponse response = http.send(request);


       if(response.getStatusCode() == 200) {
           System.debug('Token revoked successfully');
           return true;
       } else {
           System.debug('Failed to revoke token. Response: ' + response.getBody());
           return false;
       }
       }catch(Exception e){
           Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'revokeToken');
           return false;
       }
  }


   @AuraEnabled
  public static Boolean unauthorize(){
      try {
          MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getInstance(UserInfo.getUserId());
          if(settings != null){
               if (!Schema.sObjectType.MVDG__AuthProviderSettings__c.isDeletable()) {
                   return false;
               }
               Boolean isRevoked = revokeToken(settings.MVDG__refresh_token__c);
               if(isRevoked){
                   delete settings;
                   return true;
               }
          }
          return false;
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'unauthorize');
          // System.debug('Exception of unauthorize got invoked');
          return null;
      }
  }


  @AuraEnabled
  public static Boolean orgunauthorize(){
      try {
          MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
          Boolean isRevoked = revokeToken(settings.MVDG__refresh_token__c);
               if(isRevoked){
                   if(settings != null){
                       settings.MVDG__refresh_token__c = '';
                       settings.MVDG__access_token__c = '';
                       settings.MVDG__photolink__c = '';
                       settings.MVDG__LinkedDate__c = '';
                       settings.MVDG__email__c = '';
                       settings.MVDG__username__c = '';
                       settings.MVDG__WorkingStatus__c = false;
                       update settings;
                       // delete settings;
                       return true;
                   }
               }
           return false;
      } catch (Exception e) {
          Log_Handler.store_Exception(e, 'GoogleDriveAuthorizationController', 'orgunauthorize');
          // System.debug('Exception of orgunauthorize got invoked');
          return null;
      }
  }
}