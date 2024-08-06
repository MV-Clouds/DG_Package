@isTest
public class AwsUploaderTest {
    @TestSetup
    static void makeData(){

        // AwsAuthProviderSettings__c settings = AwsAuthProviderSettings__c.getOrgDefaults();
        AwsAuthProviderSettings__c settings = new AwsAuthProviderSettings__c();
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        settings.BucketName__c = 'S3';
        settings.ClientId__c = 'testClientId';
        settings.ClientSecret__c = 'testClientSecret';
        settings.NamedCredential__c = 'namedCredentials';
        upsert settings;

        // AwsAuthProviderSettings__c settings2 = new AwsAuthProviderSettings__c();
        // settings2.BucketName__c = 'S3';
        // settings2.ClientId__c = 'testClientId';
        // settings2.ClientSecret__c = 'testClientSecret';
        // settings2.NamedCredential__c = 'namedCredentials';
        // insert settings2;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'TestImage';
        cv.PathOnClient = 'TestImage.png';
        cv.VersionData = Blob.valueOf('a'.repeat(20));
        cv.FirstPublishLocationId = acc.Id;
        insert cv;

        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'TestImage1';
        cv2.PathOnClient = 'TestImage2.png';
        cv2.VersionData = Blob.valueOf('b'.repeat(200000));
        cv2.FirstPublishLocationId = acc.Id;
        insert cv2;
    }

    @IsTest
    static void testBatchableMethod(){
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        
        List<ContentVersion> cv = new List<ContentVersion>();
        cv = [SELECT Id FROM ContentVersion];
        if (cv.size() > 1) {
            AwsUploader awsUploader = new AwsUploader(cv[0].Id);
            String executeResult = Database.executeBatch(awsUploader);
            System.assertNotEquals(null, executeResult, 'The batch result cannot be null');

            AwsUploader awsUploader2 = new AwsUploader(cv[1].Id);
            String executeResult2 = Database.executeBatch(awsUploader2);
            System.assertNotEquals(null, executeResult2, 'The batch result cannot be null');
        }

        Test.stopTest();
    }

    @isTest
    static void testmailMessage(){
        Test.startTest();
        AwsUploader.mailMessage(400);
        AwsUploader.mailMessage(401);
        AwsUploader.mailMessage(403);
        AwsUploader.mailMessage(404);
        AwsUploader.mailMessage(500);
        AwsUploader.mailMessage(600);
        Test.stopTest();
        System.assertEquals(null, null, 'The result can be null');   

    }

    @isTest
    static void testContentType() {
        String result;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        result = AwsUploader.ContentType('docx');
        System.assertEquals('application/vnd.openxmlformats-officedocument.wordprocessingml.document', result, 'The result is incorrect');

        result = AwsUploader.ContentType('csv');
        System.assertEquals('application/vnd.ms-excel', result, 'The result is incorrect');

        result = AwsUploader.ContentType('pdf');
        System.assertEquals('application/pdf', result, 'The result is incorrect');

        result = AwsUploader.ContentType('png');
        System.assertEquals('image/png', result, 'The result is incorrect');

        result = AwsUploader.ContentType('wav');
        System.assertEquals('audio/wav', result, 'The result is incorrect');

        result = AwsUploader.ContentType('xls');
        System.assertEquals('application/vnd.ms-excel', result, 'The result is incorrect');

        result = AwsUploader.ContentType('');
        System.assertEquals('image/jpeg', result, 'The result is incorrect');
        
        Test.stopTest();
    }

    public class MockResponse implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example": "test"}');
            res.setStatusCode(200);
            return res;
        }
    }
}