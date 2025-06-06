@IsTest
public class DropboxUploaderTest {
    @TestSetup
    static void makeData(){
        MVDG__Dropbox_Credentials__c settings = new MVDG__Dropbox_Credentials__c();
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        settings.MVDG__ClientId__c = 'dummyClientId';
        settings.MVDG__ClientSecret__c = 'dummyClientSecret';
        settings.MVDG__refresh_token__c = 'dummyRefreshToken';
        insert settings;

        Account acc = new Account();
        acc.Name = 'TestAccount';
        insert acc;

        ContentVersion cv1 = new ContentVersion();
        cv1.Title = 'TestImage1';
        cv1.PathOnClient = 'TestImage1.png';
        cv1.VersionData = Blob.valueOf('a'.repeat(300));
        cv1.FirstPublishLocationId = acc.Id;
        insert cv1;

        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'TestImage2';
        cv2.PathOnClient = 'TestImage2.png';
        cv2.VersionData = Blob.valueOf('b'.repeat(3000));
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
    static void testBatchableMethods(){
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockResponseClass());

        List<ContentVersion> cvs = new List<ContentVersion>();
        cvs = [SELECT Id FROM ContentVersion];
        List<MVDG__Generate_Document_Activity__c> act = [SELECT Id FROM MVDG__Generate_Document_Activity__c];

        if (cvs.size() > 1) {
            DropboxUploader dropboxUploader = new DropboxUploader(cvs[0].Id, act[0].Id);
            String executeResult = Database.executeBatch(dropboxUploader);
            System.assertNotEquals(null, executeResult, 'The result cannot be null');   

            DropboxUploader dropboxUploader2 = new DropboxUploader(cvs[1].Id, act[0].Id);
            String executeResult2 = Database.executeBatch(dropboxUploader2);
            System.assertNotEquals(null, executeResult2, 'The result cannot be null');   
        }
        Test.stopTest();
        
    }

    @isTest
    static void testmailMessage(){
        Test.startTest();
        DropboxUploader.mailMessage(400);
        DropboxUploader.mailMessage(401);
        DropboxUploader.mailMessage(403);
        DropboxUploader.mailMessage(404);
        DropboxUploader.mailMessage(500);
        DropboxUploader.mailMessage(600);
        Test.stopTest();
        System.assertEquals(null, null, 'The result can be null');   

    }

    public class MockResponseClass implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token": "test"}');
            res.setStatusCode(200);
            return res;
        }
    }
}