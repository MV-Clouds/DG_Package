@IsTest
private class AwsAuthorizationControllerTest {

    private class AwsCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('s3.amazonaws.com')) {
                res.setStatusCode(200);
                res.setBody('{"message": "Success"}');
            } else if( req.getEndpoint().contains('callout:')) {
                res.setStatusCode(200);
                res.setBody('{"meesage": "Success"}');
            }
            else {
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

        MVDG__AwsAuthProviderSettings__c settings = MVDG__AwsAuthProviderSettings__c.getOrgDefaults();
            settings.MVDG__ClientId__c = 'mockClientId';
            settings.MVDG__ClientSecret__c = 'mockClientSecret';
            settings.MVDG__BucketName__c = 'mockBucketName';
            settings.MVDG__LinkedDate__c = Datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('dd/MM/yyyy');
            settings.MVDG__WorkingStatus__c = true;
            settings.MVDG__NickName__c = 'mockNickName';
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
        MVDG__AwsAuthProviderSettings__c settings = MVDG__AwsAuthProviderSettings__c.getOrgDefaults();
        settings.MVDG__NamedCredential__c = '';
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
        MVDG__AwsAuthProviderSettings__c settings2 = [SELECT MVDG__ClientId__c, MVDG__ClientSecret__c, MVDG__BucketName__c, MVDG__NickName__c, MVDG__LinkedDate__c, MVDG__WorkingStatus__c FROM MVDG__AwsAuthProviderSettings__c LIMIT 1];
        System.assertEquals('Success', result);
        
    }

    @IsTest
    static void testUnauthorize() {
        MVDG__AwsAuthProviderSettings__c settings = MVDG__AwsAuthProviderSettings__c.getInstance();
        System.assertNotEquals(null, settings);
        Test.startTest();
        Boolean result = AwsAuthorizationController.unauthorize();
        MVDG__AwsAuthProviderSettings__c settings1 = [SELECT MVDG__ClientId__c, MVDG__ClientSecret__c, MVDG__BucketName__c,MVDG__NickName__c, MVDG__LinkedDate__c, MVDG__WorkingStatus__c FROM MVDG__AwsAuthProviderSettings__c LIMIT 1];
        Test.stopTest();
        System.assertEquals(true, result);
    }

    @IsTest
    static void testauthorizeNamed(){
        Test.setMock(HttpCalloutMock.class, new AwsCalloutMock());
        Test.startTest();
        String result = AwsAuthorizationController.authorizeNamed('AWS');
        Test.stopTest();
        System.assertEquals('Success', result);
    }
}