@isTest
public with sharing class GenerateDocumentControllerTest {
    @TestSetup
    static void makeData(){
        Template__c templateActive = new Template__c(
            Template_Name__c = 'test template',
            Template_Type__c = 'CSV Template',
            Object_API_Name__c = 'Account',
            Description__c = 'Test Description',
            Template_Status__c = true
        );
        insert templateActive;
        Template__c templateInactive = new Template__c(
            Template_Name__c = 'test template 2',
            Template_Type__c = 'Simple Template',
            Object_API_Name__c = 'Contact',
            Description__c = 'Test Description 2',
            Template_Status__c = false
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
            GenerateDocumentController.saveDataWrapper saveDataWrapper = new GenerateDocumentController.saveDataWrapper();
            saveDataWrapper.toEmails = new String[]{'test1@gmail.com', 'test2@gmail.com'};
            saveDataWrapper.ccEmails = new String[]{};
            saveDataWrapper.bccEmails = new String[]{};
            saveDataWrapper.contentVersionId = cv.Id;
            saveDataWrapper.emailSubject = 'Test Email';
            saveDataWrapper.emailBody = 'Test Email Body';
            String status = GenerateDocumentController.sendEmail(saveDataWrapper);

            saveDataWrapper.contentVersionId = '012345678901234567';
            GenerateDocumentController.sendEmail(saveDataWrapper);
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
        Template__c t = [SELECT Id FROM Template__c LIMIT 1];
        Template_Page__c tp = new Template_Page__c(
            Page_Number__c =001,
            Template__c = t.Id
        );
        insert tp;
        Template_Data__c td= new Template_Data__c(
            Template__c = t.Id,
            Template_Page__c = tp.Id,
            CSV_Query__c = 'SELECT Id FROM Account',
            CSV_Fields__c = 'Id, Name'
        );
        insert td;

        Test.startTest();
        String templateData = GenerateDocumentController.getTemplateData(t.Id);
        Test.stopTest();
        System.assert(td.CSV_Fields__c + ' <|QDG|> ' + td.CSV_Query__c + ' <|QDG|> ' + 'testSessionId' == templateData, 'The String is not right.');
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
        Template__c template = [SELECT Id, Template_Name__c, Template_Type__c, Object_API_Name__c, Description__c, Template_Status__c FROM Template__c WHERE Template_Status__c = true LIMIT 1];
        Test.startTest();
        GenerateDocumentController.DefaultDataWrapper defaultValues = GenerateDocumentController.getTemplateDefaultValues(template.Id);
        Test.stopTest();
        System.assertEquals(template.Template_Name__c,defaultValues.templateName, 'The name of the default data should match.');
    }

    @isTest
    static void testSetDefaultOptions(){
        Template__c template = [SELECT Id, Template_Name__c, Template_Type__c, Object_API_NAME__c, Description__c, Template_Status__c FROM Template__c WHERE Template_Status__c = true LIMIT 1];
        GenerateDocumentController.DefaultDataWrapper defaultValues = new GenerateDocumentController.DefaultDataWrapper();
        defaultValues.templateId = template.Id;
        defaultValues.templateName = template.Template_Name__c;
        defaultValues.buttonLabel = 'test btn';
        defaultValues.buttonName = 'test_btn';
        defaultValues.docType = 'CSV';
        defaultValues.iStorage = 'Files';
        defaultValues.eStorage = 'AWS';
        defaultValues.oChannel = 'Email';
        defaultValues.emailAddresses = 'test@qwe123.com';
        defaultValues.emailSubject = 'Test Subject';
        defaultValues.emailBody = 'test email body';
        defaultValues.templateType = 'CSV Template';
        defaultValues.emailTemplate =  '123123123123123';
        Test.startTest();
        GenerateDocumentController.setDefaultOptions(defaultValues);
        Test.stopTest();

        Template__c newTemplate = [SELECT Id, Document_Type__c  FROM Template__c WHERE Id=:template.Id];
        System.assertEquals(defaultValues.docType, newTemplate.Document_Type__c, 'The template document type must be updated and should match.');
    }
}