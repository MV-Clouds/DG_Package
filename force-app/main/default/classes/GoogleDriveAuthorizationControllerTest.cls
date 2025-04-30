@isTest
public class GoogleDriveAuthorizationControllerTest {

    private class GoogleCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('https://oauth2.googleapis.com/token')) {
                res.setStatusCode(200);
                res.setBody('{"token_type":"Bearer","scope":"Files.ReadWrite.All User.Read","expires_in":3600,"ext_expires_in":3600,"access_token":"EwBoA8l6BAAUbDba3x2OMJElkF7gJ4z/VbCPEz0AAfyM9TZgvBBytObO9RQ//AoKrpp77Yhm2RPebj08chxFR6tqNsqjd+LMhzAYAviSaIbRmSfM839VO/IdiyI9pR8nO8IJZrIQI=","refresh_token":"M.C510_SN1.0.U.-OIFbkeX*vV4anI4s!*zSOUqIuEOsGFatoNaPJinxub4xh4RJzhEURulO6!AU7Vhhp7N7F1V3$"}');
            }else if(req.getEndpoint().contains('https://www.googleapis.com/drive/v3/about?fields=user')){
                res.setStatusCode(200);
                res.setBody('{"user": {"emailAddress": "test@example.com", "displayName": "testuser", "photoLink": "dummy_photo_link"}}');
            } else if (req.getEndpoint().contains('https://oauth2.googleapis.com/revoke')) {
                res.setStatusCode(200);
                res.setBody('{"user": {"emailAddress": "test@example.com", "displayName": "testuser", "photoLink": "dummy_photo_link"}}');
            }else {
                res.setStatusCode(404);
                res.setBody('{"error": "Not Found"}');
            }
            
            return res;
        }
    }

    private class ErrorGoogleCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('https://oauth2.googleapis.com/token')) {
                res.setStatusCode(400);
                res.setBody('{"token_type":"Bearer","scope":"Files.ReadWrite.All User.Read","expires_in":3600,"ext_expires_in":3600,"access_token":"EwBoA8l6BAAUbDba3x2OMJElkF7gJ4z/VbCPEz0AAfyM9TZgvBBytObO9RQ//AoKrpp77Yhm2RPebj08chxFR6tqNsqjd+LMhzAYAviSaIbRmSfM839VO/IdiyI9pR8nO8IJZrIQI=","refresh_token":"M.C510_SN1.0.U.-OIFbkeX*vV4anI4s!*zSOUqIuEOsGFatoNaPJinxub4xh4RJzhEURulO6!AU7Vhhp7N7F1V3$"}');
            }else if(req.getEndpoint().contains('https://www.googleapis.com/drive/v3/about?fields=user')){
                res.setStatusCode(400);
                res.setBody('{"user": {"emailAddress": "test@example.com", "displayName": "testuser", "photoLink": "dummy_photo_link"}}');
            }else {
                res.setStatusCode(404);
                res.setBody('{"error": "Not Found"}');
            }
            
            return res;
        }
    }
    // else if(req.getEndpoint().contains('https://login.microsoftonline.com/common/oauth2/v2.0/token')){
    //             res.setStatusCode(200);
    //             res.setBody('{"token_type":"Bearer","scope":"Files.ReadWrite.All User.Read","expires_in":3600,"ext_expires_in":3600,"access_token":"EwBoA8l6BAAUbDba3x2OMJElkF7gJ4z/VbCPEz0AAfyM9TZgvBBytObO9RQ//AoKrpp77Yhm2RPebj08chxFR6tqNsqjd+LMhzAYAviSaIbRmSfM839VO/IdiyI9pR8nO8IJZrIQI=","refresh_token":"M.C510_SN1.0.U.-OIFbkeX*vV4anI4s!*zSOUqIuEOsGFatoNaPJinxub4xh4RJzhEURulO6!AU7Vhhp7N7F1V3$"}');
    //         }

    @TestSetup
    static void setup() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert testUser;

        // Create Google_Credentials__c record
        MVDG__Google_Credentials__c settings = new MVDG__Google_Credentials__c(
            MVDG__refresh_token__c = 'dummy_refresh_token',
            MVDG__access_token__c = 'dummy_access_token',
            MVDG__email__c = 'test@example.com',
            MVDG__LinkedDate__c = String.valueOf(Date.today()),
            MVDG__WorkingStatus__c = true,
            MVDG__username__c = 'testuser',
            MVDG__ClientId__c = 'Mock',
            MVDG__ClientSecret__c = 'Mock',
            MVDG__photolink__c = 'www.google.com',
            SetupOwnerId = UserInfo.getUserId()
        );
        insert settings;

        // Create additional test user for no-permission scenario
        User noPermUser = new User(
            Alias = 'noperm',
            Email = 'nopermuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NoPerm',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'nopermuser' + DateTime.now().getTime() + '@example.com'
        );
        insert noPermUser;
    }                

    @isTest
    static void testCheckGoogleAuth() {
        Test.setMock(HttpCalloutMock.class, new GoogleCalloutMock());
        
        Test.startTest();
        Map<String, Object> result = GoogleDriveAuthorizationController.checkgoogleauth();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result cannot be null');
    }

    @isTest
    static void testcheckorggoogleauth() {
         Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1]; // Change 'Standard User' to the appropriate profile name
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
        insert testUser;

        MVDG__Google_Credentials__c settings = MVDG__Google_Credentials__c.getOrgDefaults();
        settings.MVDG__refresh_token__c = 'test';
        settings.MVDG__access_token__c = 'test';
        settings.MVDG__ClientId__c = 'test';
        settings.MVDG__ClientSecret__c = 'test';
        settings.MVDG__LinkedDate__c = '04/05/2004';
        settings.MVDG__username__c = 'test';
        settings.MVDG__email__c = 'test@gmail.com';
        insert settings;
        Test.startTest();
        System.runAs(testUser){
        Map<String, Object> result = GoogleDriveAuthorizationController.checkorggoogleauth();
        Test.stopTest();
        System.assertNotEquals(null, result,'Result not null');

        }
    }

    @isTest
    static void testisOrgWide() {
        MVDG__Google_Credentials__c settings = MVDG__Google_Credentials__c.getOrgDefaults();
        settings.MVDG__refresh_token__c = 'test';
        upsert settings;
        Test.startTest();
        Boolean result = GoogleDriveAuthorizationController.isOrgWide();
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result cannot be null');
    }

    @isTest
    static void testunauthorize() {

        Test.startTest();
        Boolean result = GoogleDriveAuthorizationController.unauthorize();
        // Google_Credentials__c settings = Google_Credentials__c.getInstance();
        Test.stopTest();
        
    }


    @isTest
    static void testgetAuthCode(){
        String client_id = 'Mock';
        String client_secret = 'Mock';
        Test.startTest();
        String result = GoogleDriveAuthorizationController.getAuthCode(client_id, client_secret);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result cannot be null');
    }

    @isTest
    static void testauthorizeGoogle(){
        String client_id = 'Mock';
        String client_secret = 'Mock';
        String authcode = '5465sf5sd6f46d5f4';
        Test.setMock(HttpCalloutMock.class, new GoogleCalloutMock());
        Test.startTest();
        String result = GoogleDriveAuthorizationController.authorizeGoogle(authcode, true, true);
        String result1 = GoogleDriveAuthorizationController.authorizeGoogle(authcode, false, true);
        Test.stopTest();
        System.assertNotEquals('fail', result, 'Result cannot be fail');
    }

    @isTest
    static void testorgunauthorize(){
        MVDG__Google_Credentials__c settings = MVDG__Google_Credentials__c.getOrgDefaults();
        settings.MVDG__refresh_token__c = 'test';
        upsert settings;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GoogleCalloutMock());
        Boolean result = GoogleDriveAuthorizationController.orgunauthorize();
        Test.stopTest();
        System.assertNotEquals(false, result, 'Result cannot be false');

    }

    @isTest
    static void testerrorauthorizegoogle(){
        Test.setMock(HttpCalloutMock.class, new ErrorGoogleCalloutMock());
        String client_id = 'Mock';
        String client_secret = 'Mock';
        String authcode = '5465sf5sd6f46d5f4';
        Test.startTest();
        String result = GoogleDriveAuthorizationController.authorizeGoogle(authcode,false, false);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result cannot be null');
    }

    @isTest
    static void testCheckAccess() {
        
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        User noPermUser = [SELECT Id FROM User WHERE Email = 'nopermuser@example.com' LIMIT 1];

        MVDG__Google_Credentials__c credentials = [SELECT Id, MVDG__refresh_token__c, MVDG__access_token__c, MVDG__email__c, SetupOwnerId 
                                            FROM MVDG__Google_Credentials__c 
                                            WHERE SetupOwnerId =: UserInfo.getUserId()
                                            LIMIT 1];
        System.assertNotEquals(null, credentials, 'Google_Credentials__c record should exist');
        System.assertEquals('dummy_refresh_token', credentials.MVDG__refresh_token__c, 'Refresh token should match');

        PermissionSet adminPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'DocGenius_Admin_Permissions' LIMIT 1];
        PermissionSet standardPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'DocGenius_Standard_Permissions' LIMIT 1];

        PermissionSetAssignment adminAssignment = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = adminPermSet.Id
        );
        PermissionSetAssignment standardAssignment = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = standardPermSet.Id
        );
        insert new List<PermissionSetAssignment>{adminAssignment, standardAssignment};

        Test.startTest();
        System.runAs(testUser) {
            String result = GoogleDriveAuthorizationController.checkAccess();
            System.assertEquals('DocGenius_Admin_Permissions', result, 'Expected DocGenius_Admin_Permissions when both permissions are assigned');
        }

        System.runAs(testUser) {
            String result = GoogleDriveAuthorizationController.checkAccess();
        }

        System.runAs(noPermUser) {
            String result = GoogleDriveAuthorizationController.checkAccess();
        }

    }
}