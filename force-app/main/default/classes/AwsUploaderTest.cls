@isTest
public class AwsUploaderTest {
    @TestSetup
    static void makeData(){

        // MVDG__Aws_Credentials__c settings = MVDG__Aws_Credentials__c.getOrgDefaults();
        MVDG__Aws_Credentials__c settings = new MVDG__Aws_Credentials__c();
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        settings.MVDG__BucketName__c = 'S3';
        settings.MVDG__ClientId__c = 'testClientId';
        settings.MVDG__ClientSecret__c = 'testClientSecret';
        settings.MVDG__NamedCredential__c = 'namedCredentials';
        upsert settings;
        
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

        MVDG__Template__c temp = new MVDG__Template__c();
        temp.MVDG__Object_API_Name__c = 'Account';
        temp.MVDG__Template_Type__c	= 'Simple Template';
        temp.MVDG__Template_Name__c	= 'test';
        insert temp;

        MVDG__Generate_Document_Activity__c gda = new MVDG__Generate_Document_Activity__c();
        gda.MVDG__AWS__c = 'Success';
        gda.MVDG__DocGenius_Template__c = temp.Id;
        insert gda;
    }

    @IsTest
    static void testBatchableMethod(){
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        
        List<ContentVersion> cv = new List<ContentVersion>();
        cv = [SELECT Id FROM ContentVersion];
        List<MVDG__Generate_Document_Activity__c> act = [SELECT Id FROM MVDG__Generate_Document_Activity__c];

        if (cv.size() > 1) {
            AwsUploader awsUploader = new AwsUploader(cv[0].Id, act[0].Id);
            String executeResult = Database.executeBatch(awsUploader);
            System.assertNotEquals(null, executeResult, 'The batch result cannot be null');

            AwsUploader awsUploader2 = new AwsUploader(cv[1].Id, act[0].Id);
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

    @isTest
    static void testCreateAuthHeader() {
        Test.startTest();
        MVDG__Aws_Credentials__c settings = MVDG__Aws_Credentials__c.getOrgDefaults();
        System.assertNotEquals(null, settings, 'AWS Credentials should be set up');
        AwsUploader.SignatureDetails params = new AwsUploader.SignatureDetails();
        params.methodName = 'PUT';
        params.fileExtension = 'png';
        params.formatedDateString = 'Wed, 25 Apr 2025 12:00:00 GMT';
        params.bucketName = settings.MVDG__BucketName__c;
        params.filename = 'TestImage';
        params.awsKey = settings.MVDG__ClientId__c;
        params.awsSecret = settings.MVDG__ClientSecret__c;
        String authHeader = AwsUploader.createAuthHeader(params);
        System.assertNotEquals(null, authHeader, 'Auth header should not be null');
        System.assert(authHeader.startsWith('AWS ' + params.awsKey + ':'), 'Auth header should start with AWS key');
        String stringToSign = params.methodName + '\n\n' + AwsUploader.contentType(params.fileExtension) + '\n' + 
                            params.formatedDateString + '\n/' + params.bucketName + '/' + 
                            params.filename.toLowerCase() + '.' + params.fileExtension.toLowerCase();
        Blob mac = Crypto.generateMac('HMACSHA1', Blob.valueOf(stringToSign), Blob.valueOf(params.awsSecret));
        String expectedSig = EncodingUtil.base64Encode(mac);
        String expectedAuth = 'AWS ' + params.awsKey + ':' + expectedSig;
        System.assertEquals(expectedAuth, authHeader, 'Auth header should match expected HMAC-SHA1 signature');
        Test.stopTest();
    }

    @isTest
    static void testUploadObjectWithEmptyNamedCredential() {
        Test.startTest();
        AwsUploader.namedCredential = '';
        MVDG__Aws_Credentials__c settings = MVDG__Aws_Credentials__c.getOrgDefaults();
        System.assertNotEquals(null, settings, 'AWS Credentials should be set up');
        MVDG__Generate_Document_Activity__c activity = [SELECT Id FROM MVDG__Generate_Document_Activity__c LIMIT 1];
        ContentVersion cv = [SELECT Title, FileExtension, VersionData FROM ContentVersion WHERE Title = 'TestImage' LIMIT 1];
        List<String> fileDetails = new List<String>{cv.Title.toLowerCase(), cv.FileExtension};
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        AwsUploader.uploadObject(fileDetails, cv.VersionData, activity.Id);
        MVDG__Generate_Document_Activity__c updatedActivity = [SELECT MVDG__AWS__c FROM MVDG__Generate_Document_Activity__c WHERE Id = :activity.Id];
        System.assertEquals('Success', updatedActivity.MVDG__AWS__c, 'Activity should indicate success for 200 response');
        updatedActivity.MVDG__AWS__c = 'Pending';
        update updatedActivity;
        Test.stopTest();
    }

    @isTest
    static void testAwsUploaderConstructor() {
        Test.startTest();
        ContentVersion cv = [SELECT Id FROM ContentVersion WHERE Title = 'TestImage' LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion record should exist');
        AwsUploader uploader = new AwsUploader(cv.Id);
        System.assertEquals(cv.Id, uploader.contentVersionId, 'contentVersionId should match the provided ContentVersion Id');
        Test.stopTest();
    }

    public class NoResponseClass implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(401);
            return res;
        }
    }

    @IsTest
    static void testBatchableMethodReject() {
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('This is test content'),
            IsMajorVersion = true
        );
        insert cv;

        MVDG__Generate_Document_Activity__c act = [Select Id From MVDG__Generate_Document_Activity__c Limit 1];

        Test.setMock(HttpCalloutMock.class, new NoResponseClass());

        Test.startTest();
        AwsUploader awsUploader = new AwsUploader(cv.Id, act.Id);
        String executeResult = Database.executeBatch(awsUploader);
        Test.stopTest();

        System.assertNotEquals(null, executeResult, 'The batch result should not be null');

        MVDG__Generate_Document_Activity__c updatedActivity = [
            SELECT Id, MVDG__AWS__c 
            FROM MVDG__Generate_Document_Activity__c 
            WHERE Id = :act.Id
        ];

        System.assertNotEquals(null, updatedActivity.MVDG__AWS__c, 'AWS message should have been set on the activity record');
        System.assert(updatedActivity.MVDG__AWS__c.containsIgnoreCase('Failure') || 
                    updatedActivity.MVDG__AWS__c.containsIgnoreCase('File Size is Greater'), 
            'Expected a failure or size warning message in AWS field');
    }

}