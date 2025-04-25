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
        
        Test.setMock(HttpCalloutMock.class, new AwsCalloutMock());

        MVDG__Aws_Credentials__c settings = MVDG__Aws_Credentials__c.getOrgDefaults();
            settings.MVDG__ClientId__c = 'mockClientId';
            settings.MVDG__ClientSecret__c = 'mockClientSecret';
            settings.MVDG__BucketName__c = 'mockBucketName';
            settings.MVDG__LinkedDate__c = Datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('dd/MM/yyyy');
            settings.MVDG__WorkingStatus__c = true;
            settings.MVDG__NickName__c = 'mockNickName';
            insert settings;
        
        Test.startTest();
        Map<String, Object> result = AwsAuthorizationController.checkawsauth();
        Test.stopTest();
        
        System.assertEquals('mockBucketName', result.get('bucket'), 'Result should be same');
        
    }

    @IsTest
    static void testifverifyAuth(){

        Test.setMock(HttpCalloutMock.class, new AwsCalloutMock());


        MVDG__Aws_Credentials__c settings = MVDG__Aws_Credentials__c.getOrgDefaults();
        settings.MVDG__NamedCredential__c = '';
        insert settings;
        Test.startTest();
        Boolean result = AwsAuthorizationController.verifyAuth();
        Test.stopTest();
        System.assertEquals(False, result, 'Result should be false');
    }

    @IsTest
    static void testelseverifyAuth(){

        Test.setMock(HttpCalloutMock.class, new AwsCalloutMock());

        MVDG__Aws_Credentials__c settings = MVDG__Aws_Credentials__c.getOrgDefaults();
        settings.MVDG__NamedCredential__c = 'AWS';
        insert  settings;
        
        Test.startTest();
        Boolean result = AwsAuthorizationController.verifyAuth();
        Test.stopTest();
        System.assertEquals(True, result, 'Result should be true');
    }
    
    @IsTest
    static void testAuthorize() {
        Test.setMock(HttpCalloutMock.class, new AwsCalloutMock());
        Test.startTest();
        String result = AwsAuthorizationController.authorize('mockClientId', 'mockClientSecret', 'mockBucket', 'mockNickName');
        Test.stopTest();
        MVDG__Aws_Credentials__c settings2 = [SELECT MVDG__ClientId__c, MVDG__ClientSecret__c, MVDG__BucketName__c, MVDG__NickName__c, MVDG__LinkedDate__c, MVDG__WorkingStatus__c FROM MVDG__Aws_Credentials__c LIMIT 1];
        System.assertEquals('Success', result, 'Result should be Success');
        
    }

    @IsTest
    static void testUnauthorize() {
        MVDG__Aws_Credentials__c settings = MVDG__Aws_Credentials__c.getOrgDefaults();
        settings.MVDG__NamedCredential__c = 'AWS';
        insert settings;
        System.assertNotEquals(null, settings, 'Settings should not be null');
        Test.startTest();
        Boolean result = AwsAuthorizationController.unauthorize();
        Test.stopTest();
    }

    @IsTest
    static void testauthorizeNamed(){
        MVDG__Aws_Credentials__c settings = MVDG__Aws_Credentials__c.getOrgDefaults();
        settings.MVDG__NamedCredential__c = 'AWS';
        insert settings;
        Test.setMock(HttpCalloutMock.class, new AwsCalloutMock());
        Test.startTest();
        String result = AwsAuthorizationController.authorizeNamed('AWS');
        Test.stopTest();
        System.assertEquals('Success', result, 'Result should be Success');
    }

    @isTest
    static void testCreateSimpleAuthHeader_NullParams() {
        Test.startTest();
        
        String result = AwsAuthorizationController.createSimpleAuthHeader(null);
        
        System.assertEquals(null, result, 'Method should return null when params is null');
        
        Test.stopTest();
    }
}