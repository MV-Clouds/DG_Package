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
                    '"answer": "You can find client-id(Key) and client-secret(Secret) from its dropbox developer console. You can find steps in userguide. "' +
                '},' +
                '{' +
                    '"question": "Redirect uri",' +
                    '"answer": "Redirect uri mismatch error can occur due to not entering redirect url in dropbox developer console. You can find all steps in userguide."' +
                '},' +
                '{' +
                    '"question": "Unable to Integrate",' +
                    '"answer": "Make sure all permissions were given while integrating and scopes are correct in dropbox developer console. Also the account you want to integrate should be logged in into your device in dropbox.(Ask System Admin If You Don\'t Have Permission)"' +
                '},' +
                '{' +
                    '"question": "Remove Integration",' +
                    '"answer": "Just by clicking unauthorize symbol next to the active integration you can easily remove integration and integrate again.(Ask System Admin If You Don\'t Have Permission) "' +
                '}' +
            ']' +
        '},' +
        '{' +
            '"question": "OneDrive",' +
            '"answer": "Solution Found",' +
            '"subQuestions": [' +
                '{' +
                    '"question": "Client-id & client-secret",' +
                    '"answer": "You can find client-id(Key) and client-secret(Secret) from its Azure app console. You can find steps in userguide."' +
                '},' +
                '{' +
                    '"question": "Redirect uri",' +
                    '"answer": "Redirect uri mismatch error can occur due to not entering redirect url in Azure app console. You can find all steps in userguide."' +
                '},' +
                '{' +
                    '"question": "Unable to Integrate",' +
                    '"answer": "Make sure all permissions were given while integrating and scopes are correct in Azure app console.(Ask System Admin If You Don\'t Have Permission)"' +
                '},' +
                '{' +
                    '"question": "Remove Integration",' +
                    '"answer": "Just by clicking unauthorize symbol next to the active integration you can easily remove integration and integrate again with different account.(Ask System Admin If You Don\'t Have Permission)"' +
                '}' +
            ']' +
        '},' +
        '{' +
            '"question": "GoogleDrive",' +
            '"answer": "Solution Found",' +
            '"subQuestions": [' +
                '{' +
                    '"question": "Org Wide Integration",' +
                    '"answer": "Org Wide Integration is used to store files in that particular account[Google Drive]. User Wide Integration will be used to generate template[Google Doc]."' +
                '},' +
                '{' +
                    '"question": "Redirect uri",' +
                    '"answer": "Contact DocGenius If you face this issue."' +
                '},' +
                '{' +
                    '"question": "Unable to Integrate",' +
                    '"answer": "Make sure all permissions were given while integrating.(Ask System Admin If You Don\'t Have Permission)"' +
                '},' +
                '{' +
                    '"question": "Remove Integration",' +
                    '"answer": "Just by clicking unauthorize symbol next to the active integration you can easily remove integration and integrate again with different account.(Ask System Admin If You Don\'t Have Permission)"' +
                '}' +
            ']' +
        '},' +
        '{' +
            '"question": "AWS",' +
            '"answer": "Solution Found",' +
            '"subQuestions": [' +
                '{' +
                    '"question": "Client-id & client-secret",' +
                    '"answer": "You can find client-id(Key) and client-secret(Secret) from its AWS s3 console. You can find steps in userguide."' +
                '},' +
                '{' +
                    '"question": "BucketName",' +
                    '"answer": "You need to enter exact name of s3 bucket for successfull integration."' +
                '},' +
                '{' +
                    '"question": "Unable to Integrate",' +
                    '"answer": "Make sure your details are correct and bucket is in specific region mentioned in userguide. Also make sure you added Remote site setting as per your bucket name.(Ask System Admin If You Don\'t Have Permission)"' +
                '},' +
                '{' +
                    '"question": "Remove Integration",' +
                    '"answer": "Just by clicking unauthorize symbol next to the active integration you can easily remove integration and integrate again with different account.(Ask System Admin If You Don\'t Have Permission)"' +
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
            '"answer": "Coming soon",' +
            '"subQuestions": [' +
                '{' +
                    '"question": "Watermark",' +
                    '"answer": "No, currently we don\'t have watermark feature in simple template, If you want you can use Google doc template."' +
                '},' +
                '{' +
                    '"question": "Page Configurations",' +
                    '"answer": "Yes, there are multiple options of page configuration like page size and orientation provided."' +
                '},' +
                '{' +
                    '"question": "Adding Image",' +
                    '"answer": "You can add images upto 30 MB for more details read limitations."' +
                '},' +
                '{' +
                    '"question": "Header and Footer",' +
                    '"answer": "Header and footer can take upto 40% size of the page."' +
                '}' +
            ']' +
        '},' +
        '{' +
            '"question": "CSV Template",' +
            '"answer": "You can create CSV in few seconds.",' +
            '"subQuestions": [' +
                '{' +
                    '"question": "Parent Object Records",' +
                    '"answer": "Yes, you can select the parent object from the drop-down on the left side to select field of parent object."' +
                '},' +
                '{' +
                    '"question": "Additional Info",' +
                    '"answer": "This info can be used to add template detials like object name and template name inside csv document. "' +
                '},' +
                '{' +
                    '"question": "Maximum limit of Records",' +
                    '"answer": "No, There is no max limit on records but it can take some time for too many records."' +
                '},' +
                '{' +
                    '"question": "Priority Order",' +
                    '"answer": "In order by first field will be given highest priority and last field will be given lowest priority."' +
                '}' +
            ']' +
        '},' +
        '{' +
            '"question": "Google Doc Template",' +
            '"answer": "With User Wide Integration you can use Google Doc template.",' +
            '"subQuestions": [' +
                '{' +
                    '"question": "Watermark",' +
                    '"answer": "Yes, you can add watermark in google doc."' +
                '},' +
                '{' +
                    '"question": "Clone Template",' +
                    '"answer": "No, Currently we don\'t provide clone template option for google doc."' +
                '},' +
                '{' +
                    '"question": "Docs Selection",' +
                    '"answer": "You can only select files created from our app.If you wish to use previously created template you can copy paste its content."' +
                '},' +
                '{' +
                    '"question": "Request Access",' +
                    '"answer": "Integrated account and active chrome account might not be same so you are seeing this message."' +
                '}' +
            ']' +
        '}' +
    ']' +
    '},{' +
    '"question": "Template",' +
    '"answer": "Refer Userguide",' +
    '"subQuestions": [' +
        '{' +
            '"question": "Template Status",' +
            '"answer": "Template\'s which you are not going to use you can keep them as inactive and that won\'t appear in generate template selection page."' +
        '},' +
        '{' +
            '"question": "Template Limit",' +
            '"answer": "Currently there is no limit on template you can create as many template\'s you want."' +
        '},' +
        '{' +
            '"question": "Template Preview",' +
            '"answer": "You can select record for which you want to preview the output."' +
        '},' +
        '{' +
            '"question": "Template default button",' +
            '"answer": "Template default button creates a button which does the predefined operation after generating document."' +
        '}' +
    ']' +
    '},{' +
    '"question": "Others",' +
    '"answer": "Refer Userguide",' +
    '"subQuestions": [' +
        '{' +
            '"question": "Unable to Perform Operations",' +
            '"answer": "Ask system admins for permission if you want to change integration options or create buttons."' +
        '},' +
        '{' +
            '"question": "Doc Genius",' +
            '"answer": "We provide end to end solution to all your document generation problems."' +
        '},' +
        '{' +
            '"question": "Email Us",' +
            '"answer": "Email us : support-dg@mvclouds.com"' +
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