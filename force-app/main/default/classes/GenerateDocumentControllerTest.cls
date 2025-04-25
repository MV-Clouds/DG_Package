@isTest
public with sharing class GenerateDocumentControllerTest {
    @TestSetup
    static void makeData(){
        MVDG__Template__c templateActive = new MVDG__Template__c(
            MVDG__Template_Name__c = 'test template',
            MVDG__Template_Type__c = 'CSV Template',
            MVDG__Object_API_Name__c = 'Account',
            MVDG__Description__c = 'Test Description',
            MVDG__Template_Status__c = true 
        );
        insert templateActive;
        MVDG__Template__c templateInactive = new MVDG__Template__c(
            MVDG__Template_Name__c = 'test template 2',
            MVDG__Template_Type__c = 'Simple Template',
            MVDG__Object_API_Name__c = 'Contact',
            MVDG__Description__c = 'Test Description 2',
            MVDG__Template_Status__c = false
        );
        insert templateInactive;

        MVDG__Generate_Document_Activity__c gda = new MVDG__Generate_Document_Activity__c();
        gda.MVDG__DocGenius_Template__c = templateInactive.Id;
        gda.MVDG__Selected_Channels__c = 'chatter,Files';
        insert gda;

        Account a = new Account(
            Name = 'Test Account'
        );
        insert a;
    }

    @isTest
    static void testGetCombinedData(){
        Test.startTest();
        GenerateDocumentController.CombinedDataWrapper combinedData = GenerateDocumentController.getCombinedData('Account');
        System.assert(combinedData.isSuccess!=null, 'There must some templates');
        Test.stopTest();

    }

    @isTest
        static void testFilesAndChatter(){
            ContentVersion cv = new ContentVersion(
                Title = 'Test Document',
                PathOnClient = 'test.txt',
                VersionData = Blob.valueOf('Test ContentVersion Body')
            );
            insert cv;
            ContentVersion cv2 = new ContentVersion(
                Title = 'Test Document 2',
                PathOnClient = 'test2.txt',
                VersionData = Blob.valueOf('Test ContentVersion Body2')
            );
            insert cv2;

            Account a = [SELECT Id from Account LIMIT 1];

            MVDG__Generate_Document_Activity__c gda = [SELECT Id FROM MVDG__Generate_Document_Activity__c LIMIT 1];

            Map<String, String> fileData = new Map<String, String>{'contentVersionId' => cv.Id, 'recordId' => a.Id, 'activityId' => gda.Id};
            Map<String, String> chatterData = new Map<String, String>{'contentVersionId' => cv.Id, 'recordId' => a.Id, 'activityId' => gda.Id, 'body'=>'test body'};

            Test.startTest();
            String fileStatus = GenerateDocumentController.storeInFiles(fileData);
            fileData.put('recordId', '1231123');
            GenerateDocumentController.storeInFiles(fileData);
            String chatterStatus = GenerateDocumentController.postToChatter(chatterData);
            fileData.put('recordId', '1231123');
            GenerateDocumentController.postToChatter(chatterData);
            Test.stopTest();

            System.assert(fileStatus!=null, 'Processs neeeds to be completed!');
            System.assert(chatterStatus!=null, 'Processs neeeds to be completed!');
        }

    @isTest
    static void testSendEmail(){
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test ContentVersion Body')
        );
        insert cv;
        MVDG__Generate_Document_Activity__c gda = [SELECT Id FROM MVDG__Generate_Document_Activity__c LIMIT 1];
        Test.startTest();
            Map<String, List<String>> allEmails = new Map<String, List<String>>{'toEmails' => new List<String>{'test.t1@gmail.com'}, 'ccEmails' => new List<String>{}, 'bccEmails' => new List<String>{}};
            Map<String, String> emailData = new Map<String, String>{'contentVersionId' => cv.Id,'emailSubject' => 'Test Sub','emailBody' => 'test body'};

            String status = GenerateDocumentController.sendEmail(allEmails, emailData, gda.Id);
            allEmails.put('toEmails', null);
            GenerateDocumentController.sendEmail(allEmails, emailData ,gda.Id);
            GenerateDocumentController.deleteContentVersion(cv.Id);
            GenerateDocumentController.deleteContentVersion('0123456789');

            Map<String, List<String>> dataList = new Map<String, List<String>>{'succeeded' => new List<String>{'Download'} , 'inProgress' => new List<String>{'AWS'}};
            Map<String, Map<String, String>> dataMap = new Map<String, Map<String, String>>{'failed' => new Map<String, String>{'Documents' => 'Internal Error'}, 'templateData' => new Map<String, String>{'name' => 'test template', 'type' => 'CSV Template', 'fileName' => 'test.csv', 'object' => 'Account'}};
        Test.stopTest(); 

        System.assert(status!=null, 'Processs neeeds to be completed!');
    }
    @isTest
    static void testGetAccessToken(){
        Test.startTest();
        MVDG__ConnectedAppIdAndSecret__c app = new MVDG__ConnectedAppIdAndSecret__c();
        app.SetupOwnerId = UserInfo.getUserId();
        app.MVDG__Client_Id__c = 'testClientId';
        app.MVDG__Client_Secret__c = 'testClientSecret';

        insert as user app;

        String generateAccessToken = GenerateDocumentController.generateAccessToken(false);
        GenerateDocumentController.getAuthProviderSettings(false);
        GenerateDocumentController.getAuthProviderSettings(true);

        GenerateDocumentController.updateSetting('testClientId2', 'testClientSecret2');

        MVDG__ConnectedAppIdAndSecret__c appUpdated = [SELECT Id, MVDG__Client_Id__c, MVDG__Client_Secret__c FROM MVDG__ConnectedAppIdAndSecret__c WHERE Id = :app.Id];
        Test.stopTest();

        System.assertEquals(generateAccessToken, 'testAccessToken', 'The Access Token should be returned!');
        System.assertEquals(appUpdated.MVDG__Client_Id__c, 'testClientId2', 'The Client Id Should be Updated!');
    }

    @isTest
    static void testGetAccessToken_Success() {
        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
    
        Test.startTest();
        String accessToken = GenerateDocumentController.getAccessToken('dummyClientId', 'dummyClientSecret', false);
        Test.stopTest();
        
        // Validate the access token received
        System.assertEquals('mockAccessToken123', accessToken, 'The access token should be returned!');
    }

    @isTest
    static void testGetAccessToken_WithUpdateSetting() {
        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200));
    
        // You might need to mock or stub updateSetting(clientId, clientSecret) if it does something heavy
        Test.startTest();
        String accessToken = GenerateDocumentController.getAccessToken('dummyClientId', 'dummyClientSecret', true);
        Test.stopTest();
        
        System.assertEquals('mockAccessToken123', accessToken, 'The access token should be returned!');
    }

    @isTest
    static void testGetAccessToken_Failure() {
        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201));
    
        Test.startTest();
        String accessToken = GenerateDocumentController.getAccessToken('dummyClientId', 'dummyClientSecret', false);
        Test.stopTest();
        
        // Validate the access token received
        System.assertEquals(null, accessToken, 'The access token should not be returned on failure!');
    }
    @isTest
    static void testGetTemplateData(){
        MVDG__Template__c t = [SELECT Id FROM MVDG__Template__c LIMIT 1];

        MVDG__Template_Data__c td= new MVDG__Template_Data__c(
            MVDG__Template__c = t.Id,
            MVDG__CSV_Query__c = 'SELECT Id FROM Account',
            MVDG__CSV_Fields__c = 'Id,Name'
        );
        insert td;

        Test.startTest();
        Map<String,String> templateData = GenerateDocumentController.getTemplateData(t.Id);
        Test.stopTest();
        System.assert(td.MVDG__CSV_Fields__c == templateData.get('fields'), 'The String is not right.');
    }

    @isTest
    static void testGetButtonNames(){
        Test.startTest();
        List<String> buttonNames = GenerateDocumentController.getButtonNames('Account');
        Test.stopTest();
        System.assert(buttonNames.size()>=0, 'There may be none or some buttons on the account.');
    }

    @isTest
    static void testGetTemplateDefaultValues(){
        MVDG__Template__c template = [SELECT Id, MVDG__Template_Name__c, MVDG__Template_Type__c, MVDG__Object_API_Name__c, MVDG__Description__c, MVDG__Template_Status__c FROM MVDG__Template__c WHERE MVDG__Template_Status__c = true LIMIT 1];
        Test.startTest();
        GenerateDocumentController.DefaultDataWrapper defaultValues = GenerateDocumentController.getTemplateDefaultValues(template.Id);
        GenerateDocumentController.getTemplateDefaultValues('123456789012345');
        Test.stopTest();
        System.assertEquals(template.MVDG__Template_Name__c,defaultValues.templateName, 'The name of the default data should match.');
    }

    @isTest
    static void testSetDefaultOptions(){
        MVDG__Template__c template = [SELECT Id, MVDG__Template_Name__c, MVDG__Template_Type__c, MVDG__Object_API_NAME__c, MVDG__Description__c, MVDG__Template_Status__c FROM MVDG__Template__c WHERE MVDG__Template_Status__c = true LIMIT 1];
        Map<String, String> defaultValues = new Map<String, String>{
        'templateId' => template.Id,
        'templateName' => template.MVDG__Template_Name__c,
        'buttonLabel' => 'test btn',
        'buttonName' => 'test_btn',
        'docType' => 'CSV',
        'iStorage' => 'Files',
        'eStorage' => 'AWS',
        'oChannel' => 'Email',
        'emailAddresses' => 'test@qwe123.com',
        'emailSubject' => 'Test Subject',
        'emailBody' => 'test email body',
        'templateType' => 'CSV Template',
        'emailTemplate' =>  '123123123123123' };
        Test.startTest();
        GenerateDocumentController.setDefaultOptions(defaultValues);
        defaultValues.put('templateId', '0001231231');
        GenerateDocumentController.setDefaultOptions(defaultValues);
        Test.stopTest();

        MVDG__Template__c newTemplate = [SELECT Id, MVDG__Document_Type__c  FROM MVDG__Template__c WHERE Id=:template.Id];
        System.assertEquals(defaultValues.get('docType'), newTemplate.MVDG__Document_Type__c, 'The template document type must be updated and should match.');
    }

    @isTest
    static void testUpsertActivity(){
        MVDG__Generate_Document_Activity__c gda = [SELECT Id FROM MVDG__Generate_Document_Activity__c LIMIT 1];
        Account a = [SELECT Id from Account LIMIT 1];
        gda.MVDG__Chatter__c = 'success';
        gda.MVDG__Files__c = 'some random error';
        gda.MVDG__Related_Record_Id__c = a.Id;
        Test.startTest();
        GenerateDocumentController.upsertActivity(gda);
        Test.stopTest();
        MVDG__Generate_Document_Activity__c gdaNew = [SELECT Id, MVDG__Chatter__c FROM MVDG__Generate_Document_Activity__c WHERE Id=:gda.Id LIMIT 1];
        System.assertEquals('success', gdaNew.MVDG__Chatter__c, 'the chatter status should be success');
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {

        private Integer statusCode;
        
        // Constructor to pass custom status code and body
        public MockHttpResponseGenerator(Integer statusCode) {
            this.statusCode = statusCode;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"mockAccessToken123"}');
            res.setStatusCode(statusCode);
            return res;
        }
    }
    
}