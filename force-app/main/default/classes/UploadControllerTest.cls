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

        MVDG__Template__c temp = new MVDG__Template__c();
        temp.MVDG__Object_API_Name__c = 'Account';
        temp.MVDG__Template_Type__c	= 'Simple Template';
        temp.MVDG__Template_Name__c	= 'test';
        insert temp;

        MVDG__Generate_Document_Activity__c gda = new MVDG__Generate_Document_Activity__c();
        gda.MVDG__AWS__c = 'Success';
        gda.DocGenius_Template__c = temp.Id;
        insert gda;
    }

    @IsTest
    public static void testUploadToGoogleDrive() {
        Test.startTest();
        ContentVersion cv1 = new ContentVersion();
        cv1 = [SELECT Id FROM ContentVersion];
        List<MVDG__Generate_Document_Activity__c> act = [SELECT Id FROM MVDG__Generate_Document_Activity__c];

        Test.setMock(HttpCalloutMock.class, new MockResponseClass());
        UploadController.uploadToGoogleDrive(cv1.Id, act[0].Id);
        Test.stopTest();
    }
    
    @IsTest
    public static void testUploadToAWS() {
        Test.startTest();
        ContentVersion cv1 = new ContentVersion();
        List<MVDG__Generate_Document_Activity__c> act = [SELECT Id FROM MVDG__Generate_Document_Activity__c];

        cv1 = [SELECT Id FROM ContentVersion];
        Test.setMock(HttpCalloutMock.class, new MockResponseClass());
        UploadController.uploadToAWS(cv1.Id, act[0].Id);
        Test.stopTest();
    }
    
    @IsTest
    public static void testUploadToDropBox() {
        Test.startTest();
        ContentVersion cv1 = new ContentVersion();
        cv1 = [SELECT Id FROM ContentVersion];
        List<MVDG__Generate_Document_Activity__c> act = [SELECT Id FROM MVDG__Generate_Document_Activity__c];

        Test.setMock(HttpCalloutMock.class, new MockResponseClass());
        UploadController.uploadToDropBox(cv1.Id, act[0].Id);
        Test.stopTest();
    }
    
    @IsTest
    public static void testUploadToOneDrive() {
        Test.startTest();
        ContentVersion cv1 = new ContentVersion();
        cv1 = [SELECT Id FROM ContentVersion];
        List<MVDG__Generate_Document_Activity__c> act = [SELECT Id FROM MVDG__Generate_Document_Activity__c];

        Test.setMock(HttpCalloutMock.class, new MockResponseClass());
        UploadController.uploadToOneDrive(cv1.Id, act[0].Id);
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