@IsTest
private class AwsAuthorizationControllerTest {

    private class AwsCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('s3.amazonaws.com')) {
                res.setStatusCode(200);
                res.setBody('{"message": "Success"}');
            } else {
                res.setStatusCode(404);
                res.setBody('{"error": "Not Found"}');
            }
            
            return res;
        }
    }

    @IsTest
    static void testCheckAwsAuth() {
        // Insert mock settings
        
        Test.setMock(HttpCalloutMock.class, new AwsCalloutMock());

        AwsAuthProviderSettings__c settings = AwsAuthProviderSettings__c.getOrgDefaults();
            settings.ClientId__c = 'mockClientId';
            settings.ClientSecret__c = 'mockClientSecret';
            settings.BucketName__c = 'mockBucketName';
            settings.LinkedDate__c = Datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('dd/MM/yyyy');
            settings.WorkingStatus__c = true;
            settings.NickName__c = 'mockNickName';
            insert settings;
        
        // Test checkawsauth method
        Test.startTest();
        Map<String, Object> result = AwsAuthorizationController.checkawsauth();
        Test.stopTest();
        
        // Validate results
        System.assertEquals('mockBucketName', result.get('bucket'), 'Result should be same');
        
    }

    @IsTest
    static void testelseverifyAuth(){
        AwsAuthProviderSettings__c settings = AwsAuthProviderSettings__c.getOrgDefaults();
        settings.NamedCredential__c = '';
        insert settings;
        Test.startTest();
        Boolean result = AwsAuthorizationController.verifyAuth();
        Test.stopTest();
        System.assertEquals(False, result);
    }

    @IsTest
    static void testAuthorize() {
        Test.setMock(HttpCalloutMock.class, new AwsCalloutMock());
        Test.startTest();
        String result = AwsAuthorizationController.authorize('mockClientId', 'mockClientSecret', 'mockBucket', 'mockNickName');
        Test.stopTest();
        AwsAuthProviderSettings__c settings2 = [SELECT ClientId__c, ClientSecret__c, BucketName__c, NickName__c, LinkedDate__c, WorkingStatus__c FROM AwsAuthProviderSettings__c LIMIT 1];
        System.assertEquals('Success', result);
        
    }

    @IsTest
    static void testUnauthorize() {
        AwsAuthProviderSettings__c settings = AwsAuthProviderSettings__c.getInstance();
        System.assertNotEquals(null, settings);
        Test.startTest();
        Boolean result = AwsAuthorizationController.unauthorize();
        AwsAuthProviderSettings__c settings1 = [SELECT ClientId__c, ClientSecret__c, BucketName__c, NickName__c, LinkedDate__c, WorkingStatus__c FROM AwsAuthProviderSettings__c LIMIT 1];
        Test.stopTest();
        System.assertEquals(true, result);
    }

    @IsTest
    static void testauthorizeNamed(){
        Test.startTest();
        String result = AwsAuthorizationController.authorizeNamed('AWS');
        Test.stopTest();
        System.assertEquals('Success', result);
    }
}