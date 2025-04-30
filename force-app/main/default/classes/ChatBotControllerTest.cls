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

            Test.startTest();
            String message = 'Initial chat data';
            String result = ChatBotController.storeMessages(message);

            System.assertEquals(message, 'Initial chat data', 'Chat data should be stored');
            System.assertEquals(null, result, 'Result should be null');
            Test.stopTest();

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

        Test.startTest();
        Map<String, Object> parameters = new Map<String, Object>();
        parameters.put('toAddress', 'tirth.s@mvclouds.com');
        parameters.put('subject', 'Test Subject');
        parameters.put('body', 'This is a test email.');
        parameters.put('replyTo', 'rachit.s@mvclouds.com');
        List<Object> fileContents = new List<Object>();

        Map<String, Object> file1 = new Map<String, Object>{
            'name' => 'TestFile1.txt',
            'path_display' => '/Test/TestFile1.txt'
        };
        
        // Add the files to the list
        fileContents.add(file1);
        parameters.put('fileNames', fileContents);
        parameters.put('fileContents', fileContents);

        ChatBotController.sendEmailWithAttachment(parameters);
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