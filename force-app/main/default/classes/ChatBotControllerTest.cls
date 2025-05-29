@isTest
public class ChatBotControllerTest {

    @testSetup
    static void setupTestData() {
        MVDG__ChatBotData__c chatBotData = new MVDG__ChatBotData__c(MVDG__Chats__c = 'Initial chat data');
        insert chatBotData;
    }

    @isTest
    static void testStoreMessages() {
        Test.startTest();
        String message = 'Test chat message';
        String result = ChatBotController.storeMessages(message);
        Test.stopTest();

        MVDG__ChatBotData__c storedData = [SELECT MVDG__Chats__c FROM MVDG__ChatBotData__c WHERE CreatedById = :UserInfo.getUserId()];
        System.assertEquals(message, storedData.MVDG__Chats__c, 'Stored message should match input message');
        System.assertEquals(null, result, 'Result should be null');
    }

    @isTest
    static void testCheckOldChats() {
        Test.startTest();
        String oldChats = ChatBotController.checkOldChats();
        Test.stopTest();

        System.assertNotEquals(null, oldChats, 'Old chats should not be null');
        System.assertEquals('Initial chat data', oldChats, 'Old chats should match initial data');
    }

    @isTest
    static void testStoreMessagesElsePart() {
        delete [SELECT Id FROM MVDG__ChatBotData__c WHERE CreatedById = :UserInfo.getUserId()];

        Test.startTest();
        String message = 'New chat data';
        String result = ChatBotController.storeMessages(message);
        Test.stopTest();

        MVDG__ChatBotData__c storedData = [SELECT MVDG__Chats__c FROM MVDG__ChatBotData__c WHERE CreatedById = :UserInfo.getUserId()];
        System.assertEquals(message, storedData.MVDG__Chats__c, 'Stored message should match new chat data');
        System.assertEquals(null, result, 'Result should be null');
    }

    @isTest
    static void testDeleteOldChats() {
        Test.startTest();
        ChatBotController.deleteOldChats();
        Test.stopTest();

        List<MVDG__ChatBotData__c> chatData = [SELECT Id FROM MVDG__ChatBotData__c WHERE CreatedById = :UserInfo.getUserId()];
        System.assertEquals(0, chatData.size(), 'Chat data should be deleted');
    }

    @isTest
    static void testGetJsonFaqs() {
        Test.startTest();
        String faqs = ChatBotController.getJsonFaqs();
        Test.stopTest();

        System.assertNotEquals(null, faqs, 'FAQ JSON should not be null');
        System.assert(faqs.contains('"question": "Integration"'), 'FAQ JSON should contain Integration question');
    }

    @isTest
    static void testGetProfileUrl() {
        Test.startTest();
        String profileUrl = ChatBotController.getProfileUrl();
        Test.stopTest();

        System.assertNotEquals('null', profileUrl, 'Profile URL should not be null string');
    }

    @isTest
    static void testGetProfileUrlNoPhoto() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;

        System.runAs(testUser) {
            Test.startTest();
            String profileUrl = ChatBotController.getProfileUrl();
            Test.stopTest();

            System.assertNotEquals('null', profileUrl, 'Profile URL should not be null string for user with no photo');
        }
    }

    @isTest
    static void testSendEmailWithAttachment() {
        Test.startTest();
        Map<String, Object> parameters = new Map<String, Object>();
        parameters.put('toAddress', 'tirth.s@mvclouds.com');
        parameters.put('subject', 'Test Subject');
        parameters.put('body', 'This is a test email.');
        parameters.put('replyTo', 'rachit.s@mvclouds.com');
        List<String> fileNames = new List<String>{'TestFile1.txt'};
        List<String> fileContents = new List<String>{EncodingUtil.base64Encode(Blob.valueOf('Test content'))};

        parameters.put('fileNames', fileNames);
        parameters.put('fileContents', fileContents);

        ChatBotController.sendEmailWithAttachment(parameters);
        System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
        Test.stopTest();
    }

    @isTest
    static void testSendEmailWithAttachmentInvalidEmail() {
        Test.startTest();
        Map<String, Object> parameters = new Map<String, Object>();
        parameters.put('toAddress', 'invalid-email');
        parameters.put('subject', 'Test Subject');
        parameters.put('body', 'This is a test email.');
        parameters.put('replyTo', 'rachit.s@mvclouds.com');
        parameters.put('fileNames', new List<String>{'TestFile1.txt'});
        parameters.put('fileContents', new List<String>{EncodingUtil.base64Encode(Blob.valueOf('Test content'))});

        try {
            ChatBotController.sendEmailWithAttachment(parameters);
            System.assert(false, 'Expected AuraHandledException for invalid email');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Exception message should not be null'); 
        }
        Test.stopTest();
    }

    @isTest
    static void testSendFeedbackEmail() {
        String toAddress = 'test@example.com';
        String key = '5';
        String feedback = 'Great chatbot!';
        String chats = '[{"text":"What seems to be causing you trouble?","isQuestion":true,"time":"03 Oct 2024, 12:40 PM"},{"text":"Template","isAnswer":true,"time":"03 Oct 2024, 12:40 PM"},{"text":"What seems to be causing you trouble?","isQuestion":true,"time":"03 Oct 2024, 12:40 PM"},{"text":"Template Status","isAnswer":true,"time":"03 Oct 2024, 12:40 PM"},{"text":"Template\'s which you are not going to use you can keep them as inactive and that won\'t appear in generate template selection page.","isSolution":true,"time":"03 Oct 2024, 12:40 PM"}]';

        Test.startTest();
        ChatBotController.sendFeedbackEmail(toAddress, key, feedback, chats);
        System.assertEquals(1, Limits.getEmailInvocations(), 'One feedback email should be sent');
        Test.stopTest();
    }
}