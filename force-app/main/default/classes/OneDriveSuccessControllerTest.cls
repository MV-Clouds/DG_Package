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

    // Test method for redirect handling for 'develop' environment
    @isTest
    static void testRedirectDevelop() {
        Test.startTest();
        String result = OneDriveSuccessController.redirect('https://test.develop.my.salesforce.com');
        Test.stopTest();
        System.assertEquals('https://test--c.develop.vf.force.com/apex/MVDG__oneDriveSuccessPage', result);
    }

    // Test method for redirect handling for 'scratch' environment
    @isTest
    static void testRedirectScratch() {
        Test.startTest();
        String result = OneDriveSuccessController.redirect('https://test.scratch.my.salesforce.com');
        Test.stopTest();
        System.assertEquals('https://test--c.scratch.vf.force.com/apex/MVDG__oneDriveSuccessPage', result);
    }

    // Test method for redirect handling for 'sandbox' environment
    @isTest
    static void testRedirectSandbox() {
        Test.startTest();
        String result = OneDriveSuccessController.redirect('https://test.sandbox.my.salesforce.com');
        Test.stopTest();
        System.assertEquals('https://test--c.sandbox.vf.force.com/apex/MVDG__oneDriveSuccessPage', result);
    }

    // Test method for redirect handling for 'production' environment
    @isTest
    static void testRedirectProduction() {
        Test.startTest();
        String result = OneDriveSuccessController.redirect('https://test.my.salesforce.com');
        Test.stopTest();
        System.assertEquals('https://test--c.vf.force.com/apex/MVDG__oneDriveSuccessPage', result);
    }
    
    // Test method for token generation and storage validation
    @isTest
    static void testGetToken() {

        // Set up mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Test.startTest();
        String result = OneDriveSuccessController.gettoken('https://login.microsoftonline.com/common/oauth2/v2.0/token?code=mock_auth_code');
        Test.stopTest();

        // Validate results
        System.assertEquals('Success', result);
    }

    // Test method for Salesforce page redirection
    @isTest
    static void testRedirectToSalesforcePage() {
        Test.startTest();
        PageReference result = OneDriveSuccessController.redirectToSalesforcePage();
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assert(result.getUrl().contains('lightning/n/MVDG__User_Configuration'), 'URL should contain the User_Configuration page');
    }

    // Test method for extracting the 'code' parameter from a URL
    @isTest
    static void testExtractCodeParameter() {
        String url = 'https://example.com?code=mock_auth_code';
        String code = OneDriveSuccessController.extractCodeParameter(url);
        System.assertEquals('mock_auth_code', code, 'The extracted code should be "mock_auth_code"');
    }

    // Test method for fetching user details from OneDrive
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
        System.assertEquals('https://develop.my.salesforce.com.develop.lightning.force.com/lightning/n/MVDG__User_Configuration', referenceUrl);
    }
    
    @isTest
    static void testReferenceUrlSandbox() {
        // Test case for 'sandbox.my.salesforce.com' URL
        String testUrl = 'https://sandbox.my.salesforce.com';
        Test.startTest();
        String referenceUrl = OneDriveSuccessController.referenceUrl(testUrl);
        Test.stopTest();
        System.assertEquals('https://sandbox.my.salesforce.com.sandbox.lightning.force.com/lightning/n/MVDG__User_Configuration', referenceUrl);
    }
    
    @isTest
    static void testReferenceUrlScratch() {
        // Test case for 'scratch.my.salesforce.com' URL
        String testUrl = 'https://scratch.my.salesforce.com';
        Test.startTest();
        String referenceUrl = OneDriveSuccessController.referenceUrl(testUrl);
        Test.stopTest();
        System.assertEquals('https://scratch.my.salesforce.com.scratch.lightning.force.com/lightning/n/MVDG__User_Configuration', referenceUrl);
    }
    
    @isTest
    static void testReferenceUrlProduction() {
        // Test case for 'my.salesforce.com' URL (Production)
        String testUrl = 'https://my.salesforce.com';
        Test.startTest();
        String referenceUrl = OneDriveSuccessController.referenceUrl(testUrl);
        Test.stopTest();
        System.assertEquals('https://my.salesforce.com.force.com/lightning/n/MVDG__User_Configuration', referenceUrl);
    }
}