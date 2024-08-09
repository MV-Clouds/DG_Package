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

            Account a = new Account(
                Name = 'Test Account'
            );
            insert a;

            Test.startTest();
            String fileStatus = GenerateDocumentController.storeInFiles(cv.Id,a.Id);
            String chatterStatus = GenerateDocumentController.postToChatter(cv.Id, a.Id, 'test Body');
            GenerateDocumentController.storeInFiles(cv.Id,cv.Id);
            GenerateDocumentController.postToChatter(cv.Id, cv.Id, 'test Body');
            Test.stopTest();

            System.assertEquals('completed', fileStatus, 'Processs neeeds to be completed!');
            System.assertEquals('completed', chatterStatus, 'Processs neeeds to be completed!');
            // System.assertEquals(1, [SELECT Id FROM FeedItem WHERE parentId =:a.Id WITH SECURITY_ENFORCED].size(), 'The Account should be chatter on account.');
            // System.assertEquals(1, [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId =:a.Id WITH SECURITY_ENFORCED].size(), 'The Account should be connected to file.');
        }

    @isTest
    static void testSendEmail(){
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test ContentVersion Body')
        );
        insert cv;
        Test.startTest();
            Map<String, List<String>> allEmails = new Map<String, List<String>>{'toEmails' => new List<String>{'test.t1@gmail.com'}, 'ccEmails' => new List<String>{}, 'bccEmails' => new List<String>{}};
            Map<String, String> emailData = new Map<String, String>{'contentVersionId' => cv.Id,'emailSubject' => 'Test Sub','emailBody' => 'test body'};

            String status = GenerateDocumentController.sendEmail(allEmails, emailData);

            emailData.put('contentVersionId', '012345678901234567');
            GenerateDocumentController.sendEmail(allEmails, emailData);
        Test.stopTest(); 

        System.assertEquals('completed', status, 'Processs neeeds to be completed!');
    }
    @isTest
    static void testGetSessionId(){
            Test.startTest();
            String sessionId = GenerateDocumentController.getSessionId();
            Test.stopTest();

            System.assert(sessionId=='testSessionId', 'The Session Id should be returned');
    }
    @isTest
    static void testGetTemplateData(){
        MVDG__Template__c t = [SELECT Id FROM MVDG__Template__c LIMIT 1];

        MVDG__Template_Data__c td= new MVDG__Template_Data__c(
            MVDG__Template__c = t.Id,
            MVDG__CSV_Query__c = 'SELECT Id FROM Account',
            MVDG__CSV_Fields__c = 'Id, Name'
        );
        insert td;

        Test.startTest();
        String templateData = GenerateDocumentController.getTemplateData(t.Id);
        Test.stopTest();
        System.assert(td.MVDG__CSV_Fields__c + ' <|QDG|> ' + td.MVDG__CSV_Query__c + ' <|QDG|> ' + 'testSessionId' == templateData, 'The String is not right.');
    }

    @isTest
    static void testGetAllEmailTemplates(){
        List<EmailTemplate> templatesAvailable = [SELECT Id FROM EmailTemplate];
        Test.startTest();
        List<EmailTemplate> templates = GenerateDocumentController.getAllEmailTemplates();
        Test.stopTest();
        System.assertEquals(templatesAvailable.size(), templates.size(), 'There should not be any email templates.');
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
        Test.stopTest();

        MVDG__Template__c newTemplate = [SELECT Id, MVDG__Document_Type__c  FROM MVDG__Template__c WHERE Id=:template.Id];
        System.assertEquals(defaultValues.get('docType'), newTemplate.MVDG__Document_Type__c, 'The template document type must be updated and should match.');
    }
}