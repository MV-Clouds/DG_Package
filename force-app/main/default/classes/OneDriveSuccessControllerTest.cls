@isTest
private class OneDriveSuccessControllerTest {
    
    // Mock HTTP callout class for successful token generation and user detail fetching
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('https://login.microsoftonline.com/common/oauth2/v2.0/token')) {
                // Mock response for token generation
                res.setBody('{"token_type":"Bearer","scope":"Files.ReadWrite.All User.Read","expires_in":3600,"ext_expires_in":3600,"access_token":"EwBoA8l6BAAUbDba3x2OMJElkF7gJ4z/VbCPEz0AAfyM9TZgvBBytObO9RQ//AoKrpp77Yhm2RPebj08chxFR6tqNsqjd+LMhzAYAviSaIbRmSfM839VO/IdiyIRuSvZX/+YRbhg9pR8nO8IJZrI+TzPa1i4v8VJvYJxtSxI6KtqICQj1jj1SIDShnkeQS09iPYnigxgDJM5524Eh/vRvBFDBjTyaEJkjJfsCn1frKQRzL7hNNuekY6UwoRrVGDXmVl20VR2b6OIetag4Otvp6e04ECVel+WoI13EDNGTPBFbU4ZaaBRXfj8bRW4qSXvlvMwptJoK3GxwONu7Q5S2LHeJSdyPLTUuNn1qDNBE5rDhIw1XpGxpp98tO7r4YsDZgAACGmGWZ/BZugCOAJehhANm0GG4tNYHGr/MH1DJl9P9PkO0bQ6IPK2RE1bEO0bUzgO8HwF84mdVK0hK8qI448GxgrSFgbFo2y1S1IXkaOJPBJczKpYoRMD4PYBNQ73zVMG0gD4hZRjUW/WmsgTfk+DqHstHojQH1qxjtglAQ47HH/V1nZzzHbOlsqPU/45yvAMFKuHBsHlAbiox/rCa/kYqDxoAD0uEO+qw8IcMUxfB3bPoeEDQjtaZ6XIeIwAK8XFG0rEqIWxyxCBvzCP/LUlgzG5t8vVJMne/i28aaNkWyhzeYdDWCphW98lf+XU4M+4upvt8oNFoYLJTI1i82VP/Krm2ya93iunIwLhVlGCB7n6qjuJHwS402BJKmC7E6y+SzdvCUvnvx/PICENSj1g+mmCFSzvReWmd5kx9LkNwL3VvTbTQW9McOpdvCviIs37GrSD4kncd6zQm+gT39qvMrdoROCGePgXO/EpeCkLzRbfJebLGzNA+Zild3OJluPb5ZHU1HHGBTUOVElvYoy82xocMLyiWwDhy7GrMtwO7SdP89amDL8MDQcVOSN8eNAbYhdIShm+KIaiBx25VjO1zPgmUDDLvmMiMK1hsMe21SaL1KGEy7rYzyuMMcAB+GtLc11DLljcLA94lJmJizefo/9v0cRi2j8fId6VB1oqfDzzynQcJxnJyUAXY3492I5poD+tt4ggeoQYvIDlZ4MvWtff9HaNV97htEiC/LNZ9rxP8m27Aeo7Vh81H18gNScCHtTmdQI=","refresh_token":"M.C510_SN1.0.U.-CggRoJcfhpiDcPK7gxR2K5hu32Dy8SfNEoKWHPfrTdXrLC4CoPBwvmvt1NpAozlbh*riYOxOgPJqNx4ox9QaDtPV8101KvWmPAGsJP79U3lxZxk68Q9NxOy5PftQe6fBAbt9OL*2FdtmewVizF*6L3YtkozOB5qIwwB7!EvKyjHLsJQIqz!x*fQBmA9YEi5Hhz*zleTPdnrbNMULZNl4*PL58GDKtr*pbRT6OeMtJlyX!SYJQr74d1X4C9UExQ3gkk1jU3R4Eu8tiVM6RsXRHLJCkCVmlrNVSmWfmd1yMPZVnL1DUOVzzCafWUFSjw6Uuw2DkGkyNsM!DOHOIFbkeX*vV4anI4s!*zSOUqIuEOsGFatoNaPJinxub4xh4RJzhEURulO6!AU7Vhhp7N7F1V3$"}');
                res.setStatusCode(200);
            } else if (req.getEndpoint().contains('https://graph.microsoft.com/v1.0/me')) {
                // Mock response for user detail fetching
                res.setBody('{"mail":"mockemail@example.com","displayName":"Mock User"}');
                res.setStatusCode(200);
            } else {
                // Mock error response
                res.setBody('{"error":"Invalid request"}');
                res.setStatusCode(400);
            }
            
            return res;
        }
    }

    @isTest
    static void testredirect1(){
        Test.startTest();
        String result = OneDriveSuccessController.redirect('Url:[delegate=https://test.develop.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://test--c.develop.vf.force.com/apex/oneDriveSuccessPage', result);

    }

    @isTest
    static void testredirect2(){
        Test.startTest();
        String result = OneDriveSuccessController.redirect('Url:[delegate=https://test.scratch.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://test--c.scratch.vf.force.com/apex/oneDriveSuccessPage', result);

    }

    @isTest
    static void testredirect3(){
        Test.startTest();
        String result = OneDriveSuccessController.redirect('Url:[delegate=https://test.sandbox.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://test--c.sandbox.vf.force.com/apex/oneDriveSuccessPage', result);

    }

    @isTest
    static void testredirect4(){
        Test.startTest();
        String result = OneDriveSuccessController.redirect('Url:[delegate=https://test.my.salesforce.com]');
        Test.stopTest();
        System.assertEquals('https://test--c.vf.force.com/apex/oneDriveSuccessPage', result);
    }
    
    @isTest
    static void testGetToken() {
        // Insert mock settings
        OneDriveAuthProviderSettings__c settings = new OneDriveAuthProviderSettings__c(
            ClientId__c = 'mockClientId',
            ClientSecret__c = 'mockClientSecret'
        );
        insert settings;

        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Test.startTest();
        String result = OneDriveSuccessController.gettoken('https://login.microsoftonline.com/common/oauth2/v2.0/token?code=mock_auth_code');
        Test.stopTest();

        // Retrieve updated settings
        settings = [SELECT ClientId__c, ClientSecret__c, refresh_token__c, refresh_token1__c, 
                    access_token__c, access_token1__c, access_token2__c, access_token3__c, 
                    access_token4__c, username__c, email__c, LinkedDate__c, WorkingStatus__c 
                    FROM OneDriveAuthProviderSettings__c LIMIT 1];

        // Validate results
        System.assertEquals('Success', result);
        System.assertEquals('Mock User', settings.username__c);
        System.assertEquals('mockemail@example.com', settings.email__c);
        System.assertEquals(true, settings.WorkingStatus__c);
    }

    @isTest
    static void testRedirectToSalesforcePage() {
        Test.startTest();
        PageReference result = OneDriveSuccessController.redirectToSalesforcePage();
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assert(result.getUrl().contains('lightning/n/User_Configuration'), 'URL should contain the User_Configuration page');
    }

    @isTest
    static void testExtractCodeParameter() {
        String url = 'https://example.com?code=mock_auth_code';
        String code = OneDriveSuccessController.extractCodeParameter(url);
        System.assertEquals('mock_auth_code', code, 'The extracted code should be "mock_auth_code"');
    }

    @isTest
    static void testFetchUserDetails() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

        Test.startTest();
        String userDetails = OneDriveSuccessController.fetchUserDetails('mock_access_token');
        Test.stopTest();

        System.assertNotEquals(null, userDetails);
        System.assert(userDetails.contains('mockemail@example.com'), 'User details should contain mock email');
        System.assert(userDetails.contains('Mock User'), 'User details should contain mock display name');
    }

    @isTest
    static void testReferenceUrlDevelop() {
        // Test case for 'develop.my.salesforce.com' URL
        String testUrl = 'https://develop.my.salesforce.com';
        Test.startTest();
        String referenceUrl = OneDriveSuccessController.referenceUrl(testUrl);
        Test.stopTest();
        System.assertEquals('.develop.lightning.force.com/lightning/n/User_Configuration', referenceUrl);
    }
    
    @isTest
    static void testReferenceUrlSandbox() {
        // Test case for 'sandbox.my.salesforce.com' URL
        String testUrl = 'https://sandbox.my.salesforce.com';
        Test.startTest();
        String referenceUrl = OneDriveSuccessController.referenceUrl(testUrl);
        Test.stopTest();
        System.assertEquals('.sandbox.lightning.force.com/lightning/n/User_Configuration', referenceUrl);
    }
    
    @isTest
    static void testReferenceUrlScratch() {
        // Test case for 'scratch.my.salesforce.com' URL
        String testUrl = 'https://scratch.my.salesforce.com';
        Test.startTest();
        String referenceUrl = OneDriveSuccessController.referenceUrl(testUrl);
        Test.stopTest();
        System.assertEquals('.scratch.lightning.force.com/lightning/n/User_Configuration', referenceUrl);
    }
    
    @isTest
    static void testReferenceUrlProduction() {
        // Test case for 'my.salesforce.com' URL (Production)
        String testUrl = 'https://my.salesforce.com';
        Test.startTest();
        String referenceUrl = OneDriveSuccessController.referenceUrl(testUrl);
        Test.stopTest();
        System.assertEquals('.force.com/lightning/n/User_Configuration', referenceUrl);
    }
}