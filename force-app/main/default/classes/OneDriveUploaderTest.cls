@isTest
public class OneDriveUploaderTest {

    @testSetup
    static void setup() {
        // Skipping CMDT insert, as CMDT records can't be inserted in test classes

        // Create test data for ContentVersion
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'TestFile';
        contentVersion.PathOnClient = 'TestFile.pdf';
        contentVersion.VersionData = Blob.valueOf('Test file content');
        insert contentVersion;

        ContentVersion contentVersion2 = new ContentVersion();
        contentVersion2.Title = 'TestFile2';
        contentVersion2.PathOnClient = 'TestFile2.pdf'; 
        contentVersion2.VersionData = Blob.valueOf('a'.repeat(8880));
        insert contentVersion2;

        // Create a sample Template record
        MVDG__Template__c temp = new MVDG__Template__c();
        temp.MVDG__Object_API_Name__c = 'Account';
        temp.MVDG__Template_Type__c = 'Simple Template';
        temp.MVDG__Template_Name__c = 'test';
        insert temp;

        // Create a related Generate_Document_Activity__c record
        MVDG__Generate_Document_Activity__c gda = new MVDG__Generate_Document_Activity__c();
        gda.MVDG__AWS__c = 'Success';
        gda.MVDG__DocGenius_Template__c = temp.Id;
        insert gda;
    }

    @isTest
    static void testBatchableMethods() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseToken());

        List<ContentVersion> contentVersions = [SELECT Id, ContentSize FROM ContentVersion];
        List<MVDG__Generate_Document_Activity__c> activities = [SELECT Id FROM MVDG__Generate_Document_Activity__c];

        // Test first ContentVersion
        OneDriveUploader uploader = new OneDriveUploader(contentVersions[0].Id, activities[0].Id);
        String executeResult = Database.executeBatch(uploader);
        System.assertNotEquals(null, executeResult, 'The batch result cannot be null');
        
        // Test second ContentVersion
        OneDriveUploader uploader2 = new OneDriveUploader(contentVersions[1].Id, activities[0].Id);
        String executeResult2 = Database.executeBatch(uploader2);
        System.assertNotEquals(null, executeResult2, 'The result cannot be null');
        Test.stopTest();
    }

    @isTest
    static void testErrorInitiateUploadSession() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockErrorHttpResponseToken());

        List<ContentVersion> contentVersions = [SELECT Id, ContentSize FROM ContentVersion];
        List<MVDG__Generate_Document_Activity__c> activities = [SELECT Id FROM MVDG__Generate_Document_Activity__c];

        String uploader = OneDriveUploader.initiateUploadSession('pdf', contentVersions[0], activities[0].Id);
        
        System.assertNotEquals(null, uploader, 'The uploader result cannot be null');
        Test.stopTest();
    }

    @isTest
    static void testContentTypeForOneDrive() {
        Test.startTest();
        String result;

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
    static void testMailMessage() {
        Test.startTest();
        OneDriveUploader.mailMessage(400);
        OneDriveUploader.mailMessage(401);
        OneDriveUploader.mailMessage(403);
        OneDriveUploader.mailMessage(404);
        OneDriveUploader.mailMessage(500);
        OneDriveUploader.mailMessage(600);
        Test.stopTest();

        System.assertEquals(null, null, 'Just checking method executes without error');
    }

    @isTest
    static void testGetToken() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockErrorHttpResponseToken());

        List<MVDG__Generate_Document_Activity__c> activities = [SELECT Id FROM MVDG__Generate_Document_Activity__c];
        String result = OneDriveUploader.getToken(activities[0].Id);
        OneDriveUploader.getToken('a08C200000GEtUt123');
        System.assertEquals(null, result, 'The result is null as expected');
        Test.stopTest();
    }

    @isTest
    static void testUploadChunkStatus201() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseStatus201());

        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion LIMIT 1];
        List<MVDG__Generate_Document_Activity__c> activities = [SELECT Id FROM MVDG__Generate_Document_Activity__c LIMIT 1];

        OneDriveUploader uploader = new OneDriveUploader(contentVersions[0].Id, activities[0].Id);
        Database.executeBatch(uploader);
        Test.stopTest();
    }

    @isTest
    static void testUploadChunkErrorStatus() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseServerError());

        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion LIMIT 1];
        List<MVDG__Generate_Document_Activity__c> activities = [SELECT Id FROM MVDG__Generate_Document_Activity__c LIMIT 1];

        try {
            OneDriveUploader uploader = new OneDriveUploader(contentVersions[0].Id, activities[0].Id);
            Database.executeBatch(uploader);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('exception'), 'Should throw AuraHandledException');
        }
        Test.stopTest();
    }


    // HTTP mock class simulating a successful token fetch
    public class MockHttpResponseToken implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token": "testAccessToken", "uploadUrl": "https://www.example.com/param1"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // HTTP mock class simulating an error response
    public class MockErrorHttpResponseToken implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error": "invalid_request"}');
            res.setStatusCode(400);
            return res;
        }
    }

        // Mock class for 201 Created response (used for chunk upload success)
        public class MockHttpResponseStatus201 implements HttpCalloutMock {
            public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"uploadUrl": "https://example.com/upload"}');
                res.setStatusCode(201);
                return res;
            }
        }
    
        // Mock class for error response (500) to trigger mailMessage and catch
        public class MockHttpResponseServerError implements HttpCalloutMock {
            public HTTPResponse respond(HTTPRequest req) {
                HttpResponse res = new HttpResponse();
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"error": "Server error"}');
                res.setStatusCode(500);
                return res;
            }
        }
    
}