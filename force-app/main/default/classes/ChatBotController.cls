public with sharing class ChatBotController {

    private static final String FAQ_JSON_1 = '[{' +
    '"question": "Integration",' +
    '"answer": "Refer Userguide",' +
    '"subQuestions": [' +
        '{' +
            '"question": "Dropbox",' +
            '"answer": "Solution Found",' +
            '"subQuestions": [' +
                '{' +
                    '"question": "Client-id & client-secret",' +
                    '"answer": "You can find client-id[Key] and client-secret[Secret] from its dropbox developer console. You can find steps in userguide. "' +
                '},' +
                '{' +
                    '"question": "Redirect uri",' +
                    '"answer": "Redirect uri mismatch error can occur due to not entering redirect url in dropbox developer console. You can find all steps in userguide."' +
                '},' +
                '{' +
                    '"question": "Unable to Integrate",' +
                    '"answer": "Make sure all permissions were given while integrating and scopes are correct in dropbox developer console. Also the account you want to integrate should be logged in into your device in dropbox."' +
                '},' +
                '{' +
                    '"question": "Remove Integration",' +
                    '"answer": "Just by clicking unauthorize symbol next to the active integration you can easily remove integration and integrate again. "' +
                '}' +
            ']' +
        '},' +
        '{' +
            '"question": "OneDrive",' +
            '"answer": "Solution Found",' +
            '"subQuestions": [' +
                '{' +
                    '"question": "Client-id & client-secret",' +
                    '"answer": "You can find client-id[Key] and client-secret[Secret] from its Azure app console. You can find steps in userguide."' +
                '},' +
                '{' +
                    '"question": "Redirect uri",' +
                    '"answer": "Redirect uri mismatch error can occur due to not entering redirect url in Azure app console. You can find all steps in userguide."' +
                '},' +
                '{' +
                    '"question": "Unable to Integrate",' +
                    '"answer": "Make sure all permissions were given while integrating and scopes are correct in Azure app console."' +
                '},' +
                '{' +
                    '"question": "Remove Integration",' +
                    '"answer": "Just by clicking unauthorize symbol next to the active integration you can easily remove integration and integrate again with different account."' +
                '}' +
            ']' +
        '},' +
        '{' +
            '"question": "GoogleDrive",' +
            '"answer": "Solution Found",' +
            '"subQuestions": [' +
                '{' +
                    '"question": "Client-id & client-secret",' +
                    '"answer": "You can find client-id[Key] and client-secret[Secret] from its google developer console. You can find steps in userguide."' +
                '},' +
                '{' +
                    '"question": "Redirect uri",' +
                    '"answer": "Redirect uri mismatch error can occur due to not entering redirect url in google developer console. You can find all steps in userguide."' +
                '},' +
                '{' +
                    '"question": "Unable to Integrate",' +
                    '"answer": "Make sure all permissions were given while integrating and scopes are correct in google developer console."' +
                '},' +
                '{' +
                    '"question": "Remove Integration",' +
                    '"answer": "Just by clicking unauthorize symbol next to the active integration you can easily remove integration and integrate again with different account."' +
                '}' +
            ']' +
        '},' +
        '{' +
            '"question": "AWS",' +
            '"answer": "Solution Found",' +
            '"subQuestions": [' +
                '{' +
                    '"question": "Client-id & client-secret",' +
                    '"answer": "You can find client-id[Key] and client-secret[Secret] from its AWS s3 console. You can find steps in userguide."' +
                '},' +
                '{' +
                    '"question": "BucketName",' +
                    '"answer": "You need to enter exact name of s3 bucket for successfull integration."' +
                '},' +
                '{' +
                    '"question": "Unable to Integrate",' +
                    '"answer": "Make sure your details are correct and bucket is in specific region mentioned in userguide."' +
                '},' +
                '{' +
                    '"question": "Remove Integration",' +
                    '"answer": "Just by clicking unauthorize symbol next to the active integration you can easily remove integration and integrate again with different account."' +
                '}' +
            ']' +
        '}' +
    ']' +
'},{' +
    '"question": "Template Builder",' +
    '"answer": "Refer Userguide",' +
    '"subQuestions": [' +
        '{' +
            '"question": "Simple Template",' +
            '"answer": "Coming soon"' +
        '},' +
        '{' +
            '"question": "Drag and Drop Template",' +
            '"answer": "Coming soon"' +
        '},' +
        '{' +
            '"question": "CSV Template",' +
            '"answer": "Coming soon"' +
        '},' +
        '{' +
            '"question": "Advanced Template",' +
            '"answer": "Coming soon"' +
        '}' +
    ']' +
    '},{' +
    '"question": "Template",' +
    '"answer": "Refer Userguide",' +
    '"subQuestions": [' +
        '{' +
            '"question": "Template Status",' +
            '"answer": "Coming soon"' +
        '},' +
        '{' +
            '"question": "Template Limit",' +
            '"answer": "Coming soon"' +
        '},' +
        '{' +
            '"question": "Template Preview",' +
            '"answer": "Coming soon"' +
        '},' +
        '{' +
            '"question": "Template deletion",' +
            '"answer": "Coming soon"' +
        '}' +
    ']' +
    '},{' +
    '"question": "Others",' +
    '"answer": "Refer Userguide",' +
    '"subQuestions": [' +
        '{' +
            '"question": "Permission Issue",' +
            '"answer": "Coming soon"' +
        '},' +
        '{' +
            '"question": "Doc Genius",' +
            '"answer": "Coming soon"' +
        '},' +
        '{' +
            '"question": "Email Us",' +
            '"answer": "Coming soon"' +
        '}' +
    ']' +
    
'}]';


    //
    @AuraEnabled
    public static String storeMessages(String msg){
        
        List<MVDG__ChatBotData__c> checkData = [SELECT MVDG__Chats__c FROM MVDG__ChatBotData__c WHERE CreatedById = :UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        if(!checkData.isEmpty()){
            checkData[0].MVDG__Chats__c = msg;
            if(!Schema.sObjectType.MVDG__ChatBotData__c.fields.MVDG__Chats__c.isUpdateable()){
                return null;
            }
            update checkData;

        }
        else{
            MVDG__ChatBotData__c storedData = new MVDG__ChatBotData__c();
            storedData.MVDG__Chats__c = msg;
            if(!Schema.sObjectType.MVDG__ChatBotData__c.fields.MVDG__Chats__c.isCreateable()){
                return null;
            }
            insert storedData;
        }
        return null;
    }

    @AuraEnabled
    public static String checkOldChats(){
        List<MVDG__ChatBotData__c> checkData = [SELECT MVDG__Chats__c FROM MVDG__ChatBotData__c WHERE CreatedById = :UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        if(!checkData.isEmpty()){
            return checkData[0].MVDG__Chats__c;
        }
        else{
            return null;
        }

    }

    @AuraEnabled
    public static void deleteOldChats(){
        if (!Schema.sObjectType.MVDG__ChatBotData__c.isDeletable()) {
            return;
        }
        List<MVDG__ChatBotData__c> checkData = [SELECT MVDG__Chats__c FROM MVDG__ChatBotData__c WHERE CreatedById = :UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        if(!checkData.isEmpty()){
            delete checkData;
        }
    }

    @AuraEnabled
    public static String getJsonFaqs() {
        return FAQ_JSON_1;
    }


    @AuraEnabled
    public static String getProfileUrl(String cid) {
        if(cid != null){
        User cuser = [SELECT Id, FullPhotoUrl FROM User WHERE Id=:cid WITH SECURITY_ENFORCED];
        System.debug(cuser.FullPhotoUrl);
        return cuser.FullPhotoUrl;
        }
        return 'null';
    }


    public class EmailDetails {
        @AuraEnabled public String toAddress { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public String body { get; set; }
        @AuraEnabled public List<String> fileNames { get; set; }
        @AuraEnabled public List<String> fileContents { get; set; }
        @AuraEnabled public String replyTo { get; set; }
    }

    @AuraEnabled
    public static void sendEmailWithAttachment(EmailDetails parameters) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { parameters.toAddress });
        mail.setSubject(parameters.subject);
        mail.setPlainTextBody(parameters.body);

        if (parameters.replyTo != null && parameters.replyTo != '') {
            mail.setReplyTo(parameters.replyTo);
        }
        
        // Prepare attachments
        if (parameters.fileNames != null && parameters.fileContents != null && parameters.fileNames.size() == parameters.fileContents.size()) {
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            for (Integer i = 0; i < parameters.fileNames.size(); i++) {
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName(parameters.fileNames[i]);
                attachment.setBody(EncodingUtil.base64Decode(parameters.fileContents[i]));
                attachments.add(attachment);
            }
            mail.setFileAttachments(attachments);
        }
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    

    @AuraEnabled
    public static void sendFeedbackEmail(String toAddress, String key, String feedback,String chats) {
        String subject = 'Feedback for chatbot and chats';
            String body = 'User\'s rating for chatbot is ' + key + ' out of 5.\n' +
                  'Reason:- ' + feedback + '\n' +
                  'chats:- ' + chats;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { toAddress });
        mail.setSubject(subject);
        mail.setPlainTextBody(body);      
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}