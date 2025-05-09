@isTest
public with sharing class DropboxSuccessControllerTest {

   private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('https://api.dropbox.com/oauth2/token')) {
                // Mock response for token generation
                res.setBody('{"access_token": "mock_access_token", "refresh_token": "mock_refresh_token"}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('https://api.dropboxapi.com/2/users/get_current_account')) {
                // Mock response for user detail fetching
                res.setBody('{"email": "test@example.com", "name": {"display_name": "testuser"}}');
                res.setStatusCode(200);
            } else {
                // Mock error response
                res.setBody('{"error":"Invalid request"}');
                res.setStatusCode(400);
            }
            
            return res;
        }
    } 

    private class ErrorMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('https://api.dropbox.com/oauth2/token')) {
                // Mock response for token generation
                res.setBody('{"access_token": "mock_access_token", "refresh_token": "mock_refresh_token"}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('https://api.dropboxapi.com/2/users/get_current_account')) {
                // Mock response for user detail fetching
                res.setBody('{"error": "Invalid access token"}');
                res.setStatusCode(401);
            } else {
                // Mock error response
                res.setBody('{"error":"Invalid request"}');
                res.setStatusCode(400);
            }
            
            return res;
        }
    } 

    @isTest
    static void testgetToken(){
        MVDG__Dropbox_Credentials__c settings = new MVDG__Dropbox_Credentials__c(
            MVDG__ClientId__c = 'Mock',
            MVDG__ClientSecret__c = 'Mock'
        );
        insert settings;
        String url = 'https://www.google.com?code=\'45565465476987\'';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse()) ;
        Test.startTest();
        String result = DropboxSuccessController.gettoken(url);
        System.assertEquals(null, result, 'Result should be null');
        Test.stopTest();
            
    }

    @isTest
    static void testRedirectToSalesforcePage() {
        Test.startTest();
        PageReference result = DropboxSuccessController.redirectToSalesforcePage();
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assert(result.getUrl().contains('lightning/n/MVDG__User_Configuration'), 'URL should contain the User_Configuration page');
    }

    @isTest
    static void testredirect1(){
        Test.startTest();
        String result = DropboxSuccessController.redirect('https://test.develop.my.salesforce.com]');
        System.assertNotEquals(null, result);
        Test.stopTest();
    }

     @isTest
    static void testredirect2(){
        Test.startTest();
        String result = DropboxSuccessController.redirect('https://test.scratch.my.salesforce.com]');
        System.assertNotEquals(null, result);
        Test.stopTest();
    }

     @isTest
    static void testredirect3(){
        Test.startTest();
        String result = DropboxSuccessController.redirect('https://test.sandbox.my.salesforce.com]');
        System.assertNotEquals(null, result);
        Test.stopTest();
    }

     @isTest
    static void testredirect4(){
        Test.startTest();
        String result = DropboxSuccessController.redirect('https://test.my.salesforce.com]');
        System.assertNotEquals(null, result);
        Test.stopTest();
    }

    @isTest
    static void testReferenceUrlDevelop() {
        // Test case for 'develop.my.salesforce.com' URL
        String testUrl = 'https://develop.my.salesforce.com';
        Test.startTest();
        String referenceUrl = DropboxSuccessController.referenceUrl(testUrl);
        Test.stopTest();
        System.assertEquals('https://develop.my.salesforce.com.develop.lightning.force.com/lightning/n/MVDG__User_Configuration', referenceUrl);
    }
    
    @isTest
    static void testReferenceUrlSandbox() {
        // Test case for 'sandbox.my.salesforce.com' URL
        String testUrl = 'https://sandbox.my.salesforce.com';
        Test.startTest();
        String referenceUrl = DropboxSuccessController.referenceUrl(testUrl);
        Test.stopTest();
        System.assertEquals('https://sandbox.my.salesforce.com.sandbox.lightning.force.com/lightning/n/MVDG__User_Configuration', referenceUrl);
    }
    
    @isTest
    static void testReferenceUrlScratch() {
        // Test case for 'scratch.my.salesforce.com' URL
        String testUrl = 'https://scratch.my.salesforce.com';
        Test.startTest();
        String referenceUrl = DropboxSuccessController.referenceUrl(testUrl);
        Test.stopTest();
        System.assertEquals('https://scratch.my.salesforce.com.scratch.lightning.force.com/lightning/n/MVDG__User_Configuration', referenceUrl);
    }
    
    @isTest
    static void testReferenceUrlProduction() {
        // Test case for 'my.salesforce.com' URL (Production)
        String testUrl = 'https://my.salesforce.com';
        Test.startTest();
        String referenceUrl = DropboxSuccessController.referenceUrl(testUrl);
        Test.stopTest();
        System.assertEquals('https://my.salesforce.com.force.com/lightning/n/MVDG__User_Configuration', referenceUrl);
    }

     @isTest
    static void testFetchUserDetailsErrorResponse() {
        // Test case for error response in fetchUserDetails
        Test.startTest();
        Test.setMock(HttpCalloutMock.class,new ErrorMockHttpResponse());
        String result = DropboxSuccessController.fetchUserDetails('invalid_access_token');
        Test.stopTest();
        System.assertEquals('false', result, 'Result should be false in case of error response');
    }
    
}