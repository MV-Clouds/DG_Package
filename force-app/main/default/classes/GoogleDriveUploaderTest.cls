@isTest
public class GoogleDriveUploaderTest {
    @TestSetup
    static void makeData(){
        MVDG__Google_Credentials__c settings = new MVDG__Google_Credentials__c();
        settings.SetupOwnerId = UserInfo.getOrganizationId();
        settings.MVDG__ClientId__c = 'dummyClientId';
        settings.MVDG__ClientSecret__c = 'dummyClientSecret';
        settings.MVDG__refresh_token__c = 'dummyAccessToken';
        insert settings;

        Account acc = new Account();
        acc.Name = 'Test Acc';
        insert acc;
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'TestImage';
        cv.PathOnClient = 'TestImage.png';
        cv.VersionData = Blob.valueOf('TestImage.png');
        cv.FirstPublishLocationId = acc.Id;
        insert cv;

        ContentVersion cv2 = new ContentVersion();
        cv2.Title = 'TestImage2';
        cv2.PathOnClient = 'TestImage2.png';
        cv2.VersionData = Blob.valueOf('a'.repeat(1000));
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
        List<ContentVersion> cv = new List<ContentVersion>();
        cv = [SELECT Id FROM ContentVersion];
        List<MVDG__Generate_Document_Activity__c> act = [SELECT Id FROM MVDG__Generate_Document_Activity__c];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        if (cv.size() > 1) {   
            GoogleDriveUploader googleDriveUploader = new GoogleDriveUploader(cv[0].Id, act[0].Id);
            String result = Database.executeBatch(googleDriveUploader);

            System.assertNotEquals(null, result, 'The result cannot be null');

            GoogleDriveUploader googleDriveUploader2 = new GoogleDriveUploader(cv[1].Id, act[0].Id);
            String result2 = Database.executeBatch(googleDriveUploader2);

            System.assertNotEquals(null, result2, 'The result cannot be null');
        }

        Test.stopTest();
    }

    @IsTest
    static void TestmailMessage(){
        
        Test.startTest();
        
        GoogleDriveUploader.mailMessage(400);
        GoogleDriveUploader.mailMessage(401);
        GoogleDriveUploader.mailMessage(403);
        GoogleDriveUploader.mailMessage(404);
        GoogleDriveUploader.mailMessage(500);

        System.assertEquals(5, Limits.getEmailInvocations(), 'The emails are not sent');

        Test.stopTest();    
    }

    @IsTest
    static void TestContentType(){
        
        Test.startTest();
        String result;
        result = GoogleDriveUploader.ContentType('docx');
        System.assertEquals('application/vnd.google-apps.file', result, 'The result is not true');

        result = GoogleDriveUploader.ContentType('csv');
        System.assertEquals('text/csv', result, 'The result is not true');
        
        result = GoogleDriveUploader.ContentType('png');
        System.assertEquals('image/png', result, 'The result is not true');
        
        result = GoogleDriveUploader.ContentType('pdf');
        System.assertEquals('application/pdf', result, 'The result is not true');

        result = GoogleDriveUploader.ContentType('txt');
        System.assertEquals('text/plain', result, 'The result is not true');
        
        result = GoogleDriveUploader.ContentType('ppt');
        System.assertEquals('application/vnd.google-apps.presentation', result, 'The result is not true');

        result = GoogleDriveUploader.ContentType('xls');
        System.assertEquals('application/vnd.ms-excel', result, 'The result is not true');
        
        result = GoogleDriveUploader.ContentType('');
        System.assertEquals('image/jpeg', result, 'The result is not true');

        Test.stopTest();
        
    }

    public class MockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setHeader('Location', 'Success');
            res.setBody('{"example": "test", "access_token": "dummyaccess_token"}');
            res.setStatusCode(200);
            return res;
        }
    }
}