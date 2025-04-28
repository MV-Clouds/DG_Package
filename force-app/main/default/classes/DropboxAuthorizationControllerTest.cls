/*******************************************************
* Name          : DropboxAuthorizationControllerTest
* Author        : Tirth
* Create Date   : 26/06/2024 
* UsedBy        : DropboxAuthorizationController
* Description   : TestClass
* Company       : MV Clouds
*******************************************************/

@isTest
public with sharing class DropboxAuthorizationControllerTest {

    private class DropboxCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('https://api.dropbox.com/oauth2/token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"mock_access_token","token_type":"bearer","expires_in":14400,"refresh_token":"mock_refresh_token","scope":"files.content.read files.content.write account_info.read","uid":"12345","account_id":"dbid:ABC123"}');
            } else {
                res.setStatusCode(404);
                res.setBody('{"error": "Not Found"}');
            }
            
            return res;
        }
    }

    @isTest
    static void testCheckDropboxAuth() {
        Test.setMock(HttpCalloutMock.class, new DropboxCalloutMock());

        Test.startTest();
        Map<String, Object> result = DropBoxAuthorizationController.checkdropboxauth();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
    }

    @isTest
    static void testVerifyAuth() {
        Test.setMock(HttpCalloutMock.class, new DropboxCalloutMock());

        Test.startTest();
        Boolean isValid = DropBoxAuthorizationController.verifyAuth();
        Test.stopTest();

        System.assertEquals(true, isValid, 'Authentication should be valid with mock 200 response');
    }

    @isTest
    static void testUnauthorize() {
        Test.startTest();
        Boolean result = DropBoxAuthorizationController.unauthorize();
        Test.stopTest();

        System.assertEquals(true, result, 'Unauthorize should return true when settings exist');
    }

    @isTest
    static void testAuthorize() {
        String clientId = 'MockClientId';
        String clientSecret = 'MockClientSecret';

        Test.startTest();
        String result = DropBoxAuthorizationController.authorize(clientId, clientSecret);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Authorization URL should not be null');
        System.assert(result.contains('https://www.dropbox.com/oauth2/authorize'), 'Result should be a Dropbox auth URL');
    }

    @isTest
    static void testAuthorize_MissingParams() {
        Test.startTest();
        String result = DropBoxAuthorizationController.authorize('', '');
        Test.stopTest();

        System.assertEquals('Both Client ID and Client Secret are required.', result, 'Should return error for missing parameters');
    }

    @isTest
    static void testRedirectUrl() {
        Test.startTest();
        String redirectUrl = DropBoxAuthorizationController.redirectUrl();
        Test.stopTest();

        System.assertNotEquals(null, redirectUrl, 'Redirect URL should not be null');
        System.assert(redirectUrl.contains('vf.force.com/apex/MVDG__dropboxSuccessPage'), 'Redirect URL should point to dropboxSuccessPage');
    }

    @isTest
    static void testRedirect_DevelopOrg() {
        Test.startTest();
        String redirectUrl = DropBoxAuthorizationController.redirect('https://testorg.develop.my.salesforce.com');
        Test.stopTest();

        System.assertEquals('https://testorg--c.develop.vf.force.com/apex/MVDG__dropboxSuccessPage', redirectUrl, 'Redirect URL should match develop org format');
    }

    @isTest
    static void testRedirect_SandboxOrg() {
        Test.startTest();
        String redirectUrl = DropBoxAuthorizationController.redirect('https://testorg.sandbox.my.salesforce.com');
        Test.stopTest();

        System.assertEquals('https://testorg--c.sandbox.vf.force.com/apex/MVDG__dropboxSuccessPage', redirectUrl, 'Redirect URL should match sandbox org format');
    }

    @isTest
    static void testRedirect_ScratchOrg() {
        Test.startTest();
        String redirectUrl = DropBoxAuthorizationController.redirect('https://testorg.scratch.my.salesforce.com');
        Test.stopTest();

        System.assertEquals('https://testorg--c.scratch.vf.force.com/apex/MVDG__dropboxSuccessPage', redirectUrl, 'Redirect URL should match scratch org format');
    }

    @isTest
    static void testRedirect_ProductionOrg() {
        Test.startTest();
        String redirectUrl = DropBoxAuthorizationController.redirect('https://testorg.my.salesforce.com');
        Test.stopTest();

        System.assertEquals('https://testorg--c.vf.force.com/apex/MVDG__dropboxSuccessPage', redirectUrl, 'Redirect URL should match production org format');
    }

    @isTest
    static void testAuthcode() {
        String clientId = 'MockClientId';
        String clientSecret = 'MockClientSecret';

        Test.startTest();
        String authUrl = DropBoxAuthorizationController.authcode(clientId, clientSecret);
        Test.stopTest();

        System.assertNotEquals(null, authUrl, 'Auth URL should not be null');
        System.assert(authUrl.contains('https://www.dropbox.com/oauth2/authorize'), 'Auth URL should point to Dropbox OAuth endpoint');
        System.assert(authUrl.contains('client_id=' + clientId), 'Auth URL should include clientId');
        System.assert(authUrl.contains('scope=files.content.read'), 'Auth URL should include Dropbox scopes');
    }

    @isTest
    static void testParseJSONToMap() {
        String jsonString = '{"access_token":"mock_access_token","token_type":"bearer","expires_in":14400}';

        Test.startTest();
        Map<String, String> result = DropBoxAuthorizationController.parseJSONToMap(jsonString);
        Test.stopTest();

        System.assertEquals('mock_access_token', result.get('access_token'), 'Parsed JSON should contain access_token');
        System.assertEquals('bearer', result.get('token_type'), 'Parsed JSON should contain token_type');
        System.assertEquals('14400', result.get('expires_in'), 'Parsed JSON should contain expires_in');
    }
}