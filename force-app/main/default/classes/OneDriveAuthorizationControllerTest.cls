/*******************************************************
* Name          : OneDriveAuthorizationControllerTest
* Author        : Tirth
* Create Date   : 26/06/2024 
* UsedBy        : OneDriveAuthorizationController
* Description   : Test Class 
* Company       : MV Clouds
*******************************************************/
@isTest
public class OneDriveAuthorizationControllerTest {

    @TestSetup
    static void setup(){
        MVDG__OneDrive_Credential__c settings = new MVDG__OneDrive_Credential__c(
            MVDG__refresh_token__c = 'dummy_refresh_token',
            MVDG__access_token__c = 'dummy_access_token',
            MVDG__email__c = 'test@example.com',
            MVDG__LinkedDate__c = ''+Date.today(),
            MVDG__WorkingStatus__c = true,
            MVDG__username__c = 'testuser',
            MVDG__ClientId__c = 'MockClientId',
            MVDG__ClientSecret__c = 'MockClientSecret'
        );
        insert settings;
    }

    private class OnedriveCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('https://login.microsoftonline.com/common/oauth2/v2.0/token')) {
                res.setStatusCode(200);
                res.setBody('{"token_type":"Bearer","scope":"Files.ReadWrite.All User.Read","expires_in":3600,"ext_expires_in":3600,"access_token":"EwBoA8l6BAAUbDba3x2OMJElkF7gJ4z/VbCPEz0AAfyM9TZgvBBytObO9RQ//AoKrpp77Yhm2RPebj08chxFR6tqNsqjd+LMhzAYAviSaIbRmSfM839VO/IdiyIRuSvZX/+YRbhg9pR8nO8IJZrI+TzPa1i4v8VJvYJxtSxI6KtqICQj1jj1SIDShnkeQS09iPYnigxgDJM5524Eh/vRvBFDBjTyaEJkjJfsCn1frKQRzL7hNNuekY6UwoRrVGDXmVl20VR2b6OIetag4Otvp6e04ECVel+WoI13EDNGTPBFbU4ZaaBRXfj8bRW4qSXvlvMwptJoK3GxwONu7Q5S2LHeJSdyPLTUuNn1qDNBE5rDhIw1XpGxpp98tO7r4YsDZgAACGmGWZ/BZugCOAJehhANm0GG4tNYHGr/MH1DJl9P9PkO0bQ6IPK2RE1bEO0bUzgO8HwF84mdVK0hK8qI448GxgrSFgbFo2y1S1IXkaOJPBJczKpYoRMD4PYBNQ73zVMG0gD4hZRjUW/WmsgTfk+DqHstHojQH1qxjtglAQ47HH/V1nZzzHbOlsqPU/45yvAMFKuHBsHlAbiox/rCa/kYqDxoAD0uEO+qw8IcMUxfB3bPoeEDQjtaZ6XIeIwAK8XFG0rEqIWxyxCBvzCP/LUlgzG5t8vVJMne/i28aaNkWyhzeYdDWCphW98lf+XU4M+4upvt8oNFoYLJTI1i82VP/Krm2ya93iunIwLhVlGCB7n6qjuJHwS402BJKmC7E6y+SzdvCUvnvx/PICENSj1g+mmCFSzvReWmd5kx9LkNwL3VvTbTQW9McOpdvCviIs37GrSD4kncd6zQm+gT39qvMrdoROCGePgXO/EpeCkLzRbfJebLGzNA+Zild3OJluPb5ZHU1HHGBTUOVElvYoy82xocMLyiWwDhy7GrMtwO7SdP89amDL8MDQcVOSN8eNAbYhdIShm+KIaiBx25VjO1zPgmUDDLvmMiMK1hsMe21SaL1KGEy7rYzyuMMcAB+GtLc11DLljcLA94lJmJizefo/9v0cRi2j8fId6VB1oqfDzzynQcJxnJyUAXY3492I5poD+tt4ggeoQYvIDlZ4MvWtff9HaNV97htEiC/LNZ9rxP8m27Aeo7Vh81H18gNScCHtTmdQI=","refresh_token":"M.C510_SN1.0.U.-CggRoJcfhpiDcPK7gxR2K5hu32Dy8SfNEoKWHPfrTdXrLC4CoPBwvmvt1NpAozlbh*riYOxOgPJqNx4ox9QaDtPV8101KvWmPAGsJP79U3lxZxk68Q9NxOy5PftQe6fBAbt9OL*2FdtmewVizF*6L3YtkozOB5qIwwB7!EvKyjHLsJQIqz!x*fQBmA9YEi5Hhz*zleTPdnrbNMULZNl4*PL58GDKtr*pbRT6OeMtJlyX!SYJQr74d1X4C9UExQ3gkk1jU3R4Eu8tiVM6RsXRHLJCkCVmlrNVSmWfmd1yMPZVnL1DUOVzzCafWUFSjw6Uuw2DkGkyNsM!DOHOIFbkeX*vV4anI4s!*zSOUqIuEOsGFatoNaPJinxub4xh4RJzhEURulO6!AU7Vhhp7N7F1V3$"}');
            }else {
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
        MVDG__OneDrive_Credential__c settings = MVDG__OneDrive_Credential__c.getInstance();
        System.assertEquals(client_id, settings.MVDG__ClientId__c);
        System.assertEquals(client_secret, settings.MVDG__ClientSecret__c);
    }

    @isTest
    static void testcheckonedriveauth(){
        Test.setMock(HttpCalloutMock.class, new OnedriveCalloutMock());
        Test.startTest();
        Map<String, Object> mappedResult = OneDriveAuthorizationController.checkonedriveauth();
        Test.stopTest();
        System.assertNotEquals(null, mappedResult);
        System.assertNotEquals('Error obtaining details: ', mappedResult.get('error'), 'Not getting error');

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