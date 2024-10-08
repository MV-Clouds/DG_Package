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
    @TestSetup
    static void setup(){
        MVDG__DropBoxAuthProviderSettings__c settings = MVDG__DropBoxAuthProviderSettings__c.getOrgDefaults();
            settings.MVDG__refresh_token__c = 'dummy_refresh_token';
            settings.MVDG__access_token__c = 'dummy_access_token';
            settings.MVDG__email__c = 'test@example.com';
            settings.MVDG__LinkedDate__c = ''+Date.today();
            settings.MVDG__WorkingStatus__c = true;
            settings.MVDG__ClientId__c = 'Mock';
            settings.MVDG__ClientSecret__c = 'Mock';
            settings.MVDG__username__c = 'testuser';
        insert settings;
    }

    private class DropboxCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('https://api.dropbox.com/oauth2/token')) {
                res.setStatusCode(200);
                res.setBody('{"token_type":"Bearer","scope":"Files.ReadWrite.All User.Read","expires_in":3600,"ext_expires_in":3600,"access_token":"EwBoA8l6BAAUbDba3x2OMJElkF7gJ4z/VbCPEz0AAfyM9TZgvBBytObO9RQ//AoKrpp77Yhm2RPebj08chxFR6tqNsqjd+LMhzAYAviSaIbRmSfM839VO/IdiyI9pR8nO8IJZrIQI=","refresh_token":"M.C510_SN1.0.U.-OIFbkeX*vV4anI4s!*zSOUqIuEOsGFatoNaPJinxub4xh4RJzhEURulO6!AU7Vhhp7N7F1V3$"}');
            }else {
                res.setStatusCode(404);
                res.setBody('{"error": "Not Found"}');
            }
            
            return res;
        }
    }

    @isTest
    static void testAuthorize(){
        String client_id = 'Mock';
        String client_secret = 'Mock';
        Test.startTest();
        String result = DropBoxAuthorizationController.authorize(client_id, client_secret);
        MVDG__DropBoxAuthProviderSettings__c settings = MVDG__DropBoxAuthProviderSettings__c.getInstance();
        Test.stopTest();
        System.assertEquals(client_id, settings.MVDG__ClientId__c);
    }
    @isTest
    static void testRedirectUrl1() {
        // Test for develop.my.salesforce.com
        Test.startTest();
        String redirectUrl = DropBoxAuthorizationController.redirect('https://testorg.develop.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://testorg--c.develop.vf.force.com/apex/MVDG__dropboxSuccessPage', redirectUrl);

    }

    @isTest
    static void testRedirectUrl2() {
       

        // Test for sandbox.my.salesforce.com
        Test.startTest();
        String redirectUrl = DropBoxAuthorizationController.redirect('https://testorg.sandbox.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://testorg--c.sandbox.vf.force.com/apex/MVDG__dropboxSuccessPage', redirectUrl);

    }

    @isTest
    static void testRedirectUrl3() {
        
        // Test for scratch.my.salesforce.com
        Test.startTest();
        String redirectUrl = DropBoxAuthorizationController.redirect('https://testorg.scratch.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://testorg--c.scratch.vf.force.com/apex/MVDG__dropboxSuccessPage', redirectUrl);

    }

    @isTest
    static void testRedirectUrl4() {

        // Test for default case
        Test.startTest();
        String redirectUrl = DropBoxAuthorizationController.redirect('https://testorg.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://testorg--c.vf.force.com/apex/MVDG__dropboxSuccessPage', redirectUrl);
    }

     @isTest
    static void testUnauthorize(){
        Test.startTest();
        Boolean state = DropBoxAuthorizationController.unauthorize();
        Test.stopTest();
        System.assertEquals(true, state, 'status should be true');
    }

    @isTest
    static void testheckonedriveauth(){
        Test.setMock(HttpCalloutMock.class, new DropboxCalloutMock());
        Test.startTest();
        Map<String, Object> mappedResult = DropBoxAuthorizationController.checkdropboxauth();
        Test.stopTest();
        System.assertNotEquals(null, mappedResult);
        System.assertNotEquals('Error obtaining details: ', mappedResult.get('error'), 'Not getting error');

    }

}