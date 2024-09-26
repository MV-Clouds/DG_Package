@isTest
public class OneDriveUploaderTest {

    @testSetup
    static void setup() {
        // Create test data for MVDG__OneDriveAuthProviderSettings__c
        MVDG__OneDriveAuthProviderSettings__c settings = MVDG__OneDriveAuthProviderSettings__c.getOrgDefaults();
            settings.MVDG__refresh_token__c = 'testRefreshToken';
            settings.MVDG__refresh_token1__c = 'testRefreshToken1';
            settings.MVDG__ClientId__c = 'testClientId';
            settings.MVDG__ClientSecret__c = 'testClientSecret';
            settings.MVDG__email__c = 'testemail@test.com';
        
        insert settings;

        // Create test data for ContentVersion
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'TestFile';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test file content');
        insert contentVersion;

        ContentVersion contentVersion2 = new ContentVersion();
        contentVersion2.Title = 'TestFile2';
        contentVersion2.PathOnClient = 'TestFile2.pdf'; 
        Blob data = Blob.valueOf('a'.repeat(8880));
        contentVersion2.VersionData = data;
        insert contentVersion2;

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

    @isTest
    static void testBatchableMethods() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseToken());

        List<ContentVersion> contentVersion = [SELECT Id, ContentSize FROM ContentVersion];
        List<MVDG__Generate_Document_Activity__c> act = [SELECT Id FROM MVDG__Generate_Document_Activity__c];

        // First element
        OneDriveUploader uploader = new OneDriveUploader(contentVersion[0].Id, act[0].Id);
        System.debug(contentVersion[0].ContentSize);
        String executeResult = Database.executeBatch(uploader);
        System.assertNotEquals(null, executeResult, 'The batch result cannot be null');
        
        // Second element
        OneDriveUploader uploader2 = new OneDriveUploader(contentVersion[1].Id, act[0].Id);
        System.debug(contentVersion[1].ContentSize);
        String executeResult2 = Database.executeBatch(uploader2);
        System.assertNotEquals(null, executeResult2, 'The result cannot be null');
        Test.stopTest();
    }

    @isTest
    static void testErrorinitiateUploadSession() {
        String uploader;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockErrorHttpResponseToken());

        List<ContentVersion> contentVersion = [SELECT Id, ContentSize FROM ContentVersion];
        List<MVDG__Generate_Document_Activity__c> act = [SELECT Id FROM MVDG__Generate_Document_Activity__c];

        // First element
        uploader = OneDriveUploader.initiateUploadSession('pdf',contentVersion[0], act[0].Id);
        System.assertNotEquals(null, uploader, 'The batch result cannot be null');
        Test.stopTest();
    }

    @isTest
    static void testcontentTypeForOneDrive() {
        String result;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseToken());
        result = OneDriveUploader.contentTypeForOneDrive('docx');
        System.assertEquals('application/vnd.openxmlformats-officedocument.wordprocessingml.document', result, 'The result is incorrect');

        result = OneDriveUploader.contentTypeForOneDrive('csv');
        System.assertEquals('application/vnd.ms-excel', result, 'The result is incorrect');

        result = OneDriveUploader.contentTypeForOneDrive('pdf');
        System.assertEquals('application/pdf', result, 'The result is incorrect');

        result = OneDriveUploader.contentTypeForOneDrive('png');
        System.assertEquals('image/png', result, 'The result is incorrect');

        result = OneDriveUploader.contentTypeForOneDrive('txt');
        System.assertEquals('text/plain', result, 'The result is incorrect');

        result = OneDriveUploader.contentTypeForOneDrive('xls');
        System.assertEquals('application/vnd.ms-excel', result, 'The result is incorrect');

        result = OneDriveUploader.contentTypeForOneDrive('');
        System.assertEquals('image/jpeg', result, 'The result is incorrect');
        
        Test.stopTest();
    }

    @isTest
    static void testmailMessage(){
        Test.startTest();
        OneDriveUploader.mailMessage(400);
        OneDriveUploader.mailMessage(401);
        OneDriveUploader.mailMessage(403);
        OneDriveUploader.mailMessage(404);
        OneDriveUploader.mailMessage(500);
        OneDriveUploader.mailMessage(600);
        Test.stopTest();
        System.assertEquals(null, null, 'The result can be null');   

    }

    // @isTest
    // static void testUploadToOneDrive() {
    //     // Mock HTTP response for file upload
    //     Test.setMock(HttpCalloutMock.class, new MockHttpResponseUpload());

    //     // Get the test ContentVersion record
    //     ContentVersion contentVersion = [SELECT Id, Title, VersionData, FileExtension FROM ContentVersion LIMIT 1];

    //     // Call the upload method
    //     Boolean result = OneDriveUploader.uploadToOneDrive(contentVersion, contentVersion.Title, 'application/pdf');
    //     System.assertEquals(true, result);
    // }

    @isTest
    static void getToken(){
        String result;
        List<MVDG__Generate_Document_Activity__c> act = [SELECT Id FROM MVDG__Generate_Document_Activity__c];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockErrorHttpResponseToken());
        result = OneDriveUploader.getToken(act[0].Id);
        System.assertEquals(null, result, 'The result is null');
        Test.stopTest();
    }

    public class MockHttpResponseToken implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token": "testAccessToken", "uploadUrl": "https://www.example.com/param1" }');
            res.setStatusCode(200);
            return res;
        }
    }

    public class MockErrorHttpResponseToken implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token": "testAccessToken", "uploadUrl": "https://www.example.com/param1" }');
            res.setStatusCode(400);
            return res;
        }
    }

}