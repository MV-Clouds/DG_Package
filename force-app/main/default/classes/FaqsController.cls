public with sharing class FaqsController {


    @AuraEnabled
    public static List<FAQ> getAllFaqs(){
        try {
            List<FAQ> faqs = new List<FAQ>();

            // faqs.add(new FAQ('faqId','name', new List<FAQQustion>{
                // new FAQQustion(
                //     question,
                //     answer
                // )
            // ))};


            // ...Integration FAQs...
            faqs.add(new FAQ('integration','Integration', new List<FAQQustion>{
                new FAQQustion(
                        'Why can\'t I integrate GoogleDrive / OneDrive / Dropbox / AWS?',
                        'You might not have the necessary permissions. Ask your System Administrator for access and ensure you\'ve followed the steps in the user guide. For GoogleDrive, if you already have an active user-wide integration, you need to remove it first and then you can integrate as both user and org-wide.'),
                new FAQQustion(
                        'How do I change my GoogleDrive / OneDrive / Dropbox / AWS Account?',
                        'Unlink the current integration and follow the integration process again.'),
                new FAQQustion(
                        'Can I use multiple GoogleDrive / OneDrive / Dropbox / AWS accounts?',
                        'No, each user can have one Google Drive integration but you can use it for saving Google Doc templates. You cannot have multiple external storage accounts integrated to upload files.'),
                new FAQQustion(
                        'What is the difference between org-wide and user-wide Google Drive?',
                        'Files are uploaded to the org-wide Google Drive, while Google Doc templates use your personal (user-wide) Drive.')
            }));

            // ...Simple Template FAQs...
            faqs.add(new FAQ('simpleTemplate','Simple Template', new List<FAQQustion>{
                new FAQQustion(
                        'Can documents be generated in landscape mode?',
                        'Yes, you can. Go to the \'Basic Details\' tab and change the page orientation in the page configuration.'),
                new FAQQustion(
                        'Can we add a watermark in a simple template?',
                        'No, watermarks aren\'t supported in the simple template. You can use the Google Doc template for this feature, as it\'s more advanced.'),
                new FAQQustion(
                        'Can we change the page size in a simple template?',
                        'Yes, you can adjust the page size, orientation, and margins in the page configuration.')
            }));
    
            // ...CSV Template FAQs...
            faqs.add(new FAQ('csvTemplate','CSV Template', new List<FAQQustion>{
                new FAQQustion(
                        'Why can\'t I import the list view even after adding a trusted URL?',
                        'The trusted URL may take up to 15 minutes to take effect. Try logging out and back in.'),
                new FAQQustion(
                        'What is the Edit Template tab?',
                        'It lets you customize the CSV, including selecting fields, applying filters, sorting records, and setting limits.')
            }));
    
            // ...Google Doc Template FAQs...
            faqs.add(new FAQ('googleDocTemplate','Google Doc Template', new List<FAQQustion>{
                new FAQQustion(
                        'What happens if a record doesn\'t have a value for a merge field?',
                        'An empty value would be displayed.'),
                new FAQQustion(
                        'Why do I see permission issues even though I\'ve integrated from another account?',
                        'You might be logged in to a different Google account in your browser.')
            }));

            // ...Generate Button FAQs...
            faqs.add(new FAQ('buttons','Generate Button', new List<FAQQustion>{
                new FAQQustion(
                        'Why can\'t I upload a file to GoogleDrive / OneDrive / Dropbox / AWS of size 100 MB?', 
                        'Currently, we have a limitation of uploading files up to 35 MB, and 10 MB for AWS integration without named credential.'),
                new FAQQustion(
                        'Why can\'t I see my file on external storages after uploading it?', 
                        'Uploads take a few minutes. Check your email for any errors.'),
                new FAQQustion(
                        'Why am I not able to select Google Drive while generating documents?', 
                        'Make sure you have integrated GoogleDrive org-wide to upload files into GoogleDrive.'),
                new FAQQustion(
                        'Why am I getting an error while uploading a file?', 
                        'Make sure your integration is active and that the document is as small as possible.')
        
            }));
    
            // ...Key Mapping FAQs...
            faqs.add(new FAQ('keyMapping','Key Mapping', new List<FAQQustion>{
                new FAQQustion(
                        'Why are some fields not available in key mapping?',
                        'Address and geolocation type fields are not supported.'),
                new FAQQustion(
                        'How can we format date, time, numbers, strings, checkbox field\'s value?',
                        'Click on the 3 dots next to the field in the key mapping component to format.')
            }));

            // ...File Upload FAQs...
            faqs.add(new FAQ('fileUpload','File Upload', new List<FAQQustion>{
                new FAQQustion(
                        'How can I rename a button generated using the "Create Button" feature?', 
                        'Go to Setup > Object Manager > Select Object > Buttons, Links, and Actions > Select Button > Edit.'),
                new FAQQustion(
                        'Why can\'t I change the name of a custom default button?', 
                        'You can only name the button during creation. To rename it later, go to the setup and edit the button label.'),
                new FAQQustion(
                        'How can I add email addresses for To, CC, and BCC?', 
                        'Enter addresses directly into the "To" field, and click "CC" or "BCC" to add those addresses.'),
                new FAQQustion(
                        'What happens if I update data without a trusted URL?', 
                        'The data will update, but the list view won\'t import, and you\'ll receive an error if you try to update the list view.'),
                new FAQQustion(
                        'Why can\'t I deselect a document type?', 
                        'At least one document type must be selected when generating documents or creating a default button.'),
                new FAQQustion(
                        'How do I use an email template to send emails?', 
                        'After selecting email as the output channel, choose an email template from the dropdown. The subject and body will auto-fill. Deselecting the template allows you to manually enter the email body.')
            
            }));
    
            return faqs;
        } catch (Exception e) {
            system.debug('exception in getTempalaterecords : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }

    public class FAQ{
        @AuraEnabled public string faqId;
        @AuraEnabled public string name;
        @AuraEnabled public List<FAQQustion> questions;

        public FAQ(string faqId, String name, List<FAQQustion> questions) {
            this.faqId = faqId;
            this.name = name;
            this.questions = questions;
        }
    }

    public class FAQQustion{
        @AuraEnabled public string question;
        @AuraEnabled public string answer;

        public FAQQustion(String question, String answer) {
            this.question = question;
            this.answer = answer;
        }
    }

    @AuraEnabled
    public static List<Knowledge__kav> getFAQKnowledge(){
        try {
            List<Knowledge__kav> faqs = [SELECT Id, Title, UrlName, FAQ_Question_Category__c, FAQ_Question__c, FAQ_Answer__c FROM Knowledge__kav WHERE RecordType.Name = 'FAQs' LIMIT 50000];
            
            return faqs;
        } catch (Exception e) {
            system.debug('exception in getTempalaterecords : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }

    public static boolean createKnowladgeArtical(){
        try {
                List<FAQ> faqs = getAllFaqs();
                List<Recordtype> recordTypes = [SELECT Id, Name, SobjectType FROM RecordType WHERE SobjectType = 'Knowledge__kav' AND Name = 'FAQs'];

                List<Knowledge__kav> knowlagesToInset = new List<Knowledge__kav>();
                for(FAQ f : faqs){
                    for(FAQQustion fq : f.questions){
                        Knowledge__kav newArticle = new Knowledge__kav();
                        String name = f.name+'-'+fq.question;
                        newArticle.Title = name;
                        newArticle.UrlName = name.replace(' ','_').replaceAll('[^a-zA-Z0-9\\s+]', '');
                        newArticle.FAQ_Question_Category__c = f.name;
                        newArticle.FAQ_Question__c = fq.question;
                        newArticle.FAQ_Answer__c = fq.answer;
                        if(recordTypes.size() > 0){
                                newArticle.RecordTypeId = recordTypes[0].Id;
                        }
                        knowlagesToInset.add(newArticle);
                    }
                }

                insert knowlagesToInset; 


                return true;
        } catch (Exception e) {
                system.debug('exception in getTempalaterecords : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
                return false;
        }
    }

}