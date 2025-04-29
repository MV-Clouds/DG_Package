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

        Aws_Credentials__c settings = Aws_Credentials__c.getOrgDefaults();
            settings.ClientId__c = 'mockClientId';
            settings.ClientSecret__c = 'mockClientSecret';
            settings.BucketName__c = 'mockBucketName';
            settings.LinkedDate__c = Datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('dd/MM/yyyy');
            settings.WorkingStatus__c = true;
            settings.NickName__c = 'mockNickName';
            insert settings;
        
        Test.startTest();
        Map<String, Object> result = AwsAuthorizationController.checkawsauth();
        Test.stopTest();
        
        System.assertEquals('mockBucketName', result.get('bucket'), 'Result should be same');
        
    }

    @IsTest
    static void testifverifyAuth(){

        Test.setMock(HttpCalloutMock.class, new AwsCalloutMock());


        Aws_Credentials__c settings = Aws_Credentials__c.getOrgDefaults();
        settings.NamedCredential__c = '';
        insert settings;
        Test.startTest();
        Boolean result = AwsAuthorizationController.verifyAuth();
        Test.stopTest();
        System.assertEquals(False, result, 'Result should be false');
    }

    @IsTest
    static void testelseverifyAuth(){

        Test.setMock(HttpCalloutMock.class, new AwsCalloutMock());

        Aws_Credentials__c settings = Aws_Credentials__c.getOrgDefaults();
        settings.NamedCredential__c = 'AWS';
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
        Aws_Credentials__c settings2 = [SELECT ClientId__c, ClientSecret__c, BucketName__c, NickName__c, LinkedDate__c, WorkingStatus__c FROM Aws_Credentials__c LIMIT 1];
        System.assertEquals('Success', result, 'Result should be Success');
        
    }

    @IsTest
    static void testUnauthorize() {
        Aws_Credentials__c settings = Aws_Credentials__c.getOrgDefaults();
        settings.NamedCredential__c = 'AWS';
        insert settings;
        System.assertNotEquals(null, settings, 'Settings should not be null');
        Test.startTest();
        Boolean result = AwsAuthorizationController.unauthorize();
        Test.stopTest();
    }

    @IsTest
    static void testauthorizeNamed(){
        Aws_Credentials__c settings = Aws_Credentials__c.getOrgDefaults();
        settings.NamedCredential__c = 'AWS';
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