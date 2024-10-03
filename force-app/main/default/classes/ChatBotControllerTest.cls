@isTest
public class ChatBotControllerTest {

    @testSetup
    static void setupTestData() {
        // Create necessary test data

        // Create a MVDG__ChatBotData__c record for the running user
        MVDG__ChatBotData__c chatBotData = new MVDG__ChatBotData__c(MVDG__Chats__c = 'Initial chat data');
        insert chatBotData;
    }

    @isTest
    static void testStoreMessages() {
        // Test storing messages
        Test.startTest();
        String message = 'Test chat message';
        String result = ChatBotController.storeMessages(message);
        Test.stopTest();

        MVDG__ChatBotData__c storedData = [SELECT MVDG__Chats__c FROM MVDG__ChatBotData__c WHERE CreatedById = :UserInfo.getUserId()];
        System.assertEquals(message, storedData.MVDG__Chats__c);
        System.assertEquals(null, result);
    }

    @isTest
    static void testCheckOldChats() {
        // Test retrieving old chats
        Test.startTest();
        String oldChats = ChatBotController.checkOldChats();
        Test.stopTest();

        System.assertNotEquals(null, oldChats);
        System.assertEquals('Initial chat data', oldChats);
    }

    @isTest
    static void testStoreMessagesElsePart() {
        // Test storing messages when no existing MVDG__ChatBotData__c record
        // Using System.runAs to simulate a different user
        User testUser = [SELECT Id FROM User WHERE UserName != :UserInfo.getUserName() LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            String message = 'Test new chat message';
            String result = ChatBotController.storeMessages(message);
            Test.stopTest();

            MVDG__ChatBotData__c storedData = [SELECT MVDG__Chats__c FROM MVDG__ChatBotData__c WHERE CreatedById = :testUser.Id];
            System.assertEquals(message, storedData.MVDG__Chats__c);
            System.assertEquals(null, result);
        }
    }

    @isTest
    static void testDeleteOldChats() {
        // Test deleting old chats
        Test.startTest();
        ChatBotController.deleteOldChats();
        Test.stopTest();

        List<MVDG__ChatBotData__c> chatData = [SELECT Id FROM MVDG__ChatBotData__c WHERE CreatedById = :UserInfo.getUserId()];
        System.assertEquals(0, chatData.size());
    }

    @isTest
    static void testGetJsonFaqs() {
        // Test retrieving FAQ JSON
        Test.startTest();
        String faqs = ChatBotController.getJsonFaqs();
        Test.stopTest();

        System.assertNotEquals(null, faqs);
        System.assert(faqs.contains('"question": "Integration"'));
    }

    @isTest
    static void testGetProfileUrl() {
        // Test retrieving profile URL
        User testUser = [SELECT Id FROM User LIMIT 1];
        Test.startTest();
        String profileUrl = ChatBotController.getProfileUrl(testUser.Id);
        Test.stopTest();

        System.assertNotEquals('null', profileUrl);
    }

    @isTest
    static void testSendEmailWithAttachment() {
        // Test sending email with attachment
        ChatBotController.EmailDetails emailDetails = new ChatBotController.EmailDetails();
        emailDetails.toAddress = 'test@example.com';
        emailDetails.subject = 'Test Subject';
        emailDetails.body = 'Test Body';
        emailDetails.fileNames = new List<String>{'test.txt'};
        emailDetails.fileContents = new List<String>{EncodingUtil.base64Encode(Blob.valueOf('Test Content'))};

        Test.startTest();
        ChatBotController.sendEmailWithAttachment(emailDetails);
        System.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();

        // Verify the email was sent (mocking email sending in real scenarios)
    }

    @isTest
    static void testSendFeedbackEmail() {
        // Test sending feedback email
        String toAddress = 'test@example.com';
        String key = '5';
        String feedback = 'Great chatbot!';
        String chats = '[{"text":"What seems to be causing you trouble?","isQuestion":true,"time":"03 Oct 2024, 12:40 PM"},{"text":"Template","isAnswer":true,"time":"03 Oct 2024, 12:40 PM"},{"text":"What seems to be causing you trouble?","isQuestion":true,"time":"03 Oct 2024, 12:40 PM"},{"text":"Template Status","isAnswer":true,"time":"03 Oct 2024, 12:40 PM"},{"text":"Template\'s which you are not going to use you can keep them as inactive and that won\'t appear in generate template selection page.","isSolution":true,"time":"03 Oct 2024, 12:40 PM"}]';

        Test.startTest();
        ChatBotController.sendFeedbackEmail(toAddress, key, feedback, chats);
        System.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();

        // Verify the email was sent (mocking email sending in real scenarios)
    }
}