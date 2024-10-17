import { LightningElement, track } from 'lwc';
import faqImage from '@salesforce/resourceUrl/faqImage';
import docGeniusLogoSvg from "@salesforce/resourceUrl/docGeniusLogoSvg";
import getAllFaqs from '@salesforce/apex/FaqsController.getAllFaqs';
import getFAQKnowledge from '@salesforce/apex/FaqsController.getFAQKnowledge';

export default class Faqs extends LightningElement {


    faqImage = faqImage;
    docGeniusLogoSvg = docGeniusLogoSvg;
    @track activeSection = 'Integration';
    @track contentSections = [];
    @track faqs = [];
    initialRender = true;
    @track mobileView = false;

    connectedCallback(){
      try {
            this.fetchFAQS();
            if (typeof window !== 'undefined') {
                window.addEventListener('resize', this.resizeFunction);
            }
            this.resizeFunction();
      } catch (error) { 
        console.log(`error in connectedCallback : ${error.stack}`);
      }
    }

    renderedCallback(){
        try {
            if(this.initialRender){
    
                const mainDiv = this.template.querySelector('.faq-maindiv');
                if(mainDiv){
                    const style = document.createElement('style');
                    style.innerText =  `
                            .accordion-div .slds-accordion__summary-heading .slds-button:focus{
                                box-shadow: none;
                            }
                            .accordion-div .slds-button:hover{
                                color: #06aeff;
                            }
                            .accordion-div .slds-accordion__contentt{
                                padding-left : 1.5rem !important;
                            }
                    `;
                    mainDiv.appendChild(style);
                    this.initialRender = false;
                }
            }
            
        } catch (error) {
            console.log('error in renderedCallback : ', error.message);
            
        }
    }

    // Use Arrow Function...
    resizeFunction = () => {
       this.mobileView = window.innerWidth < 600
    };

    fetchFAQS(){
        try {
            // getAllFaqs()
            getFAQKnowledge()
            .then(result => {
                if(result) {
                    if(result){
                        this.setFAQs(result);
                    }
                }
                else{
                    console.log('error to fetch faqs');
                }
            })
        } catch (error) {
            console.log('error in fetchFAQS : ', error.message);
            
        }
    }

    setFAQs(faqs_temp){
        try {

            var faqCategories = new Set();
            faqs_temp?.forEach(ele => {
                var cate = ele.FAQ_Question_Category__c ?? 'Other';
                faqCategories.add(cate);
            });

            faqCategories?.forEach(ele => {
                this.faqs.push({
                    'faqId' : ele,
                    'name' : ele,
                    'questions' : []
                });
            });

            faqs_temp?.forEach(ele => {
                var cate = ele.FAQ_Question_Category__c ?? 'Other';
                var faq = this.faqs.find(ele => ele.name === cate);
                faq['selected'] = faq.name === this.activeSection;
                faq.questions.push({
                    'questionId' : ele.Id,
                    'question' : this.extractTextFromHTMLTag(ele.FAQ_Question__c),
                    'answer' :  this.extractTextFromHTMLTag(ele.FAQ_Answer__c),
                    'opened' : false,
                });
            });

        } catch (error) {
            console.log('error in setFAQs : ', error.message);
        }
    }

    @track showSelectBtn = false;
    toggleFaqsBtn(){
        this.showSelectBtn = !this.showSelectBtn
    }

    handleContentChange(event) {
        try {
            const faqId = event.currentTarget.dataset.id;
            this.activeSection = faqId;
            this.showSelectBtn = !this.showSelectBtn;
            this.setActiveSection();
        } catch (error) {
            console.log(`error in handleContentChange : ${error.stack}`);
        }
    }

    setActiveSection(){
        try {
            this.faqs?.forEach(ele => {
                ele['selected'] = ele.faqId === this.activeSection;
                ele?.questions?.forEach(item => {
                    item['opened'] = false;
                })
            });
            this.selectedFAQName = this.faqs.find(ele => ele.faqId === this.activeSection).name;
            
        } catch (error) {
            console.log(`error in setActiveSection : ${error.stack}`);
        }
    }

    openAccordionContent(event){
        try {
            const faqId = event.currentTarget.dataset.faqid;
            const question = event.currentTarget.dataset.id;

            // this.faqs?.forEach(ele => {
            //     if(ele.faqId === faqId){
            //         ele.questions.find(item => item.question === question).opened = true;
            //     }
            // })

            const targetFaqs = this.faqs?.find(faq => faq.faqId === faqId)?.questions;
            targetFaqs?.forEach(ele => {
                const targetDiv = this.template.querySelector(`[data-question-id="${ele.questionId}"]`);
                if(ele.questionId === question){
                    const maxHeight = ele.opened ? 0 : targetDiv?.scrollHeight;
                    targetDiv.style = `--maxHeight : ${maxHeight}px`;
                    ele.opened = !ele.opened
                }
                else{
                    targetDiv.style = `--maxHeight : 0px`
                    ele.opened = false;
                }
            })

        } catch (error) {
            console.log(`error in setActiveSection : ${error.stack}`);
        }
    }

    extractTextFromHTMLTag(html){
        try {
            var temEle = document.createElement('div');
            temEle.innerHTML = html;
            const textarea = document.createElement('textarea');
            textarea.innerText = temEle.innerText;
            var returnValue =  textarea.value;
            temEle.remove();
            textarea.remove();
            return returnValue;
        } catch (error) {
            console.log(`error in extractTextFromHTMLTag : ${error.stack}`);
            return '';
        }
    }

     // @track faqs = [
    //     {
    //         faqId: 'integration',
    //         name: 'Integration',
    //         questions: [
    //             {
    //                 question: "Why can't I integrate GoogleDrive / OneDrive / Dropbox / AWS?",
    //                 answer: "You might not have the necessary permissions. Ask your System Administrator for access and ensure you\'ve followed the steps in the user guide. For GoogleDrive, if you already have an active user-wide integration, you need to remove it first and then you can integrate as both user and org-wide."
    //             },
    //             {
    //                 question: "How do I change my GoogleDrive / OneDrive / Dropbox / AWS Account?",
    //                 answer: "Unlink the current integration and follow the integration process again."
    //             },
    //             {
    //                 question: "Can I use multiple GoogleDrive / OneDrive / Dropbox / AWS accounts?",
    //                 answer: "No, each user can have one Google Drive integration but you can use it for saving Google Doc templates. You cannot have multiple external storage accounts integrated to upload files."
    //             },
    //             {
    //                 question: "What is the difference between org-wide and user-wide Google Drive?",
    //                 answer: "Files are uploaded to the org-wide Google Drive, while Google Doc templates use your personal (user-wide) Drive."
    //             },
    //         ]
    //     },
    //     {
    //         faqId: 'simpleTemplate',
    //         name: 'Simple Template',
    //         questions: [
    //             {
    //                 question: "Can documents be generated in landscape mode?",
    //                 answer: "Yes, you can. Go to the 'Basic Details' tab and change the page orientation in the page configuration."
    //             },
    //             {
    //                 question: "Can we add a watermark in a simple template?",
    //                 answer: "No, watermarks aren't supported in the simple template. You can use the Google Doc template for this feature, as it\'s more advanced."
    //             },
    //             {
    //                 question: "Can we change the page size in a simple template?",
    //                 answer: "Yes, you can adjust the page size, orientation, and margins in the page configuration."
    //             }
    //         ]
    //     },
    //     {
    //         faqId: 'csvTemplate',
    //         name: 'CSV Template',
    //         questions: [
    //             {
    //                 question: "Why can't I import the list view even after adding a trusted URL?",
    //                 answer: "The trusted URL may take up to 15 minutes to take effect. Try logging out and back in."
    //             },
    //             {
    //                 question: "What is the Edit Template tab?",
    //                 answer: "It lets you customize the CSV, including selecting fields, applying filters, sorting records, and setting limits."
    //             }
    //         ]
    //     },
    //     {
    //         faqId: 'googleDocTemplate',
    //         name: 'Google Doc Template',
    //         questions: [
    //             {
    //                 question: "What happens if a record doesn't have a value for a merge field?",
    //                 answer: "An empty value would be displayed."
    //             },
    //             {
    //                 question: "Why do I see permission issues even though I've integrated from another account?",
    //                 answer: "You might be logged in to a different Google account in your browser."
    //             }
    //         ]
    //     },
    //     {
    //       faqId: 'buttons',
    //       name: 'Generate Button',
    //       questions: [
    //             {
    //                 question: "Why can\'t I upload a file to GoogleDrive / OneDrive / Dropbox / AWS of size 100 MB?",
    //                 answer: "Currently, we have a limitation of uploading files up to 35 MB, and 10 MB for AWS integration without named credential."
    //             },
    //             {
    //                 question: "Why can't I see my file on external storages after uploading it?",
    //                 answer: "Uploads take a few minutes. Check your email for any errors."
    //             },
    //             {
    //                 question: "Why am I not able to select Google Drive while generating documents?",
    //                 answer: "Make sure you have integrated GoogleDrive org-wide to upload files into GoogleDrive."
    //             },
    //             {
    //                 question: "Why am I getting an error while uploading a file?",
    //                 answer: "Make sure your integration is active and that the document is as small as possible."
    //             }
    //       ]
    //     },
    //     {
    //         faqId: 'keyMapping',
    //         name: 'Key Mapping',
    //         questions: [
    //             {
    //                 question: "Why are some fields not available in key mapping?",
    //                 answer: "Address and geolocation type fields are not supported."
    //             },
    //             {
    //                 question: "How can we format date, time, numbers, strings, checkbox field's value?",
    //                 answer: "Click on the 3 dots next to the field in the key mapping component to format."
    //             }
    //         ]
    //     },
    //     {
    //       faqId: 'fileUpload',
    //       name: 'File Upload',
    //       questions: [
    //             {
    //                 question: "How can I rename a button generated using the 'Create Button' feature?",
    //                 answer: "Go to Setup > Object Manager > Select Object > Buttons, Links, and Actions > Select Button > Edit."
    //             },
    //             {
    //                 question: "Why can\'t I change the name of a custom default button?",
    //                 answer: "You can only name the button during creation. To rename it later, go to the setup and edit the button label."
    //             },
    //             {
    //                 question: "How can I add email addresses for To, CC, and BCC?",
    //                 answer: "Enter addresses directly into the 'To' field, and click 'CC' or 'BCC' to add those addresses."
    //             },
    //             {
    //                 question: "What happens if I update data without a trusted URL?",
    //                 answer: "The data will update, but the list view won\'t import, and you\'ll receive an error if you try to update the list view."
    //             },
    //             {
    //                 question: "Why can't I deselect a document type?",
    //                 answer: "At least one document type must be selected when generating documents or creating a default button."
    //             },
    //             {
    //                 question: "How do I use an email template to send emails?",
    //                 answer: "After selecting email as the output channel, choose an email template from the dropdown. The subject and body will auto-fill. Deselecting the template allows you to manually enter the email body."
    //             }
    //       ]
    //     },
    // ];

}