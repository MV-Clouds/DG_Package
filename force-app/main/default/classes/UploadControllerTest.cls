@IsTest
public class UploadControllerTest {

    @TestSetup
    static void makeData(){

        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'TestImage';
        cv1.PathOnClient = 'TestImage.png';
        cv1.VersionData = Blob.valueOf('TestImage.png');
        cv1.FirstPublishLocationId = acc.Id;
        insert cv1;
    }

    @IsTest
    public static void testUploadToGoogleDrive() {
        Test.startTest();
        ContentVersion cv1 = new ContentVersion();
        cv1 = [SELECT Id FROM ContentVersion];
        Test.setMock(HttpCalloutMock.class, new MockResponseClass());
        UploadController.uploadToGoogleDrive(cv1.Id);
        Test.stopTest();
    }
    
    @IsTest
    public static void testUploadToAWS() {
        Test.startTest();
        ContentVersion cv1 = new ContentVersion();
        cv1 = [SELECT Id FROM ContentVersion];
        Test.setMock(HttpCalloutMock.class, new MockResponseClass());
        UploadController.uploadToAWS(cv1.Id);
        Test.stopTest();
    }
    
    @IsTest
    public static void testUploadToDropBox() {
        Test.startTest();
        ContentVersion cv1 = new ContentVersion();
        cv1 = [SELECT Id FROM ContentVersion];
        Test.setMock(HttpCalloutMock.class, new MockResponseClass());
        UploadController.uploadToDropBox(cv1.Id);
        Test.stopTest();
    }
    
    @IsTest
    public static void testUploadToOneDrive() {
        Test.startTest();
        ContentVersion cv1 = new ContentVersion();
        cv1 = [SELECT Id FROM ContentVersion];
        Test.setMock(HttpCalloutMock.class, new MockResponseClass());
        UploadController.uploadToOneDrive(cv1.Id);
        Test.stopTest();
    }

    public class MockResponseClass implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example": "test"}');
            res.setStatusCode(200);
            return res;
        }
    }
}