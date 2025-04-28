/*******************************************************
* Name          : OneDriveAuthorizationControllerTest
* Author        : Tirth
* Updated Date  : 25/04/2025
* Description   : Updated Test Class after removal of Custom Setting
* Company       : MV Clouds
*******************************************************/
@isTest
public class OneDriveAuthorizationControllerTest {

    private class OnedriveCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('https://login.microsoftonline.com/common/oauth2/v2.0/token')) {
                res.setStatusCode(200);
                res.setBody('{"token_type":"Bearer","scope":"Files.ReadWrite.All User.Read","expires_in":3600,"ext_expires_in":3600,"access_token":"mock_access_token","refresh_token":"mock_refresh_token"}');
            } else {
                res.setStatusCode(404);
                res.setBody('{"error": "Not Found"}');
            }
            
            return res;
        }
    }

    
    @isTest
    static void testAuthorize(){
        String client_id = 'MockClientId';
        String client_secret = 'MockClientSecret';
        Test.startTest();
        String result = OneDriveAuthorizationController.authorize(client_id, client_secret);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Authorization result should not be null');
    }

    @isTest
    static void testcheckonedriveauth(){
        Test.setMock(HttpCalloutMock.class, new OnedriveCalloutMock());
        Test.startTest();
        Map<String, Object> mappedResult = OneDriveAuthorizationController.checkonedriveauth();
        Test.stopTest();
        System.assertNotEquals(null, mappedResult);
        System.assertNotEquals('Error obtaining details: ', mappedResult.get('error'), 'Not getting error');

        System.assertNotEquals(null, mappedResult, 'Should be null as not set');
    }

    @isTest
    static void testUnauthorize(){
        Test.startTest();
        Boolean state = OneDriveAuthorizationController.unauthorize();
        Test.stopTest();
        System.assertEquals(true, state, 'status should be true');
    }

    @isTest
    static void testAuthorize_MissingParams(){
        Test.startTest();
        String result = OneDriveAuthorizationController.authorize('', '');
        Test.stopTest();
        System.assertEquals('Both Client ID and Client Secret are required.', result);
    }

    @isTest
    static void testRedirectUrl1() {
        // Test for develop.my.salesforce.com
        Test.startTest();
        String redirectUrl = OneDriveAuthorizationController.redirect('https://testorg.develop.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://testorg--c.develop.vf.force.com/apex/MVDG__oneDriveSuccessPage', redirectUrl);

    }

    @isTest
    static void testRedirectUrl2() {
       

        // Test for sandbox.my.salesforce.com
        Test.startTest();
        String redirectUrl = OneDriveAuthorizationController.redirect('https://testorg.sandbox.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://testorg--c.sandbox.vf.force.com/apex/MVDG__oneDriveSuccessPage', redirectUrl);

    }

    @isTest
    static void testRedirectUrl3() {
        
        // Test for scratch.my.salesforce.com
        Test.startTest();
        String redirectUrl = OneDriveAuthorizationController.redirect('https://testorg.scratch.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://testorg--c.scratch.vf.force.com/apex/MVDG__oneDriveSuccessPage', redirectUrl);

    }

    @isTest
    static void testRedirectUrl4() {

        // Test for default case
        Test.startTest();
        String redirectUrl = OneDriveAuthorizationController.redirect('https://testorg.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://testorg--c.vf.force.com/apex/MVDG__oneDriveSuccessPage', redirectUrl);
    }
}