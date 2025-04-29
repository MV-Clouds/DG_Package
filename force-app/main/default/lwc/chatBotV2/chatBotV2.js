import { LightningElement, track } from 'lwc';
import Feedback from "@salesforce/resourceUrl/Feedback";
import Id from "@salesforce/user/Id";
import fetchImageUrl from "@salesforce/apex/ChatBotController.getProfileUrl";
import chatBot from "@salesforce/resourceUrl/chatBot";
import chatUser from "@salesforce/resourceUrl/chatUser";
import sendEmailWithAttachment from '@salesforce/apex/ChatBotController.sendEmailWithAttachment';
import sendFeedbackEmail from '@salesforce/apex/ChatBotController.sendFeedbackEmail';
import getJsonFaqs from '@salesforce/apex/ChatBotController.getJsonFaqs';
import storeMessages from '@salesforce/apex/ChatBotController.storeMessages';
import checkOldChats from '@salesforce/apex/ChatBotController.checkOldChats';
import deleteOldChats from '@salesforce/apex/ChatBotController.deleteOldChats';
import { errorDebugger } from 'c/globalPropertiesV2';

export default class ChatBotV2 extends LightningElement {
    @track uploadedFiles = [];
    @track popupOpen = false; //used to open chatbot im child component
    @track issues = []; // options for user to select
    @track isSpinner = true; //used to track status of spinner
    @track textValue;
    @track isClearPopup = false;
    @track isFeedbackPopup = false;
    @track isEmail = false;
    @track toAddress = 'support-dg@mvclouds.com';
    @track replyAddress = '';
    @track subject = 'Support Request: DocGenius Product';
    @track body = '';
    @track mailSent = false;
    @track hideCircle = false;
    @track feedbackRating = '';
    @track keyword;
    @track useful = false;
    @track notHelpful = false;
    @track isOnlyEmail = true;
    @track userFeedback;
    @track isSolution;
    @track hideChatBar = true;
    @track emailErrorMessage = false;
    @track attachmentError = false;
    @track fileSizeError = false;
    @track emailWasActive = false;
    @track unknownError = false;
    @track isThankYou = false;

    selectedFileSize = 0;
    currentTime = '09:48';
    acceptedFormats = ['.pdf', '.png', '.jpg', '.doc', '.docx'];
    userId = Id;
    isIssue = false; //used to track if any active issue is there
    @track isSol = false;  //used to track if any active solution is there
    isTimer = false; //used to track time
    isChatStarted = false;
    messages = [];  //used to store users selected option as message
    solution = null; //used to display solution
    @track chatBot;
    @track chatUser;
    time = [1000, 1200, 1400];
    faq;
    query; //used when user searches something and result is not found
    oldChats = false;
    @track item1;
    @track item2;
    @track item3;
    @track item4;
    @track item5;
    @track question = 'What seems to be causing you trouble?';
    selectedJSON;
    customTimeout;

    static captureCurrentTime() {
        const date = new Date();

    const day = String(date.getDate()).padStart(2, '0');
    const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const month = monthNames[date.getMonth()];
    const year = date.getFullYear();

    const hours = date.getHours();
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const ampm = hours >= 12 ? 'PM' : 'AM';
    const formattedHours = hours % 12 || 12; // Convert 24-hour time to 12-hour time

    return `${day} ${month} ${year}, ${String(formattedHours).padStart(2, '0')}:${minutes} ${ampm}`;
    }

    get closeFooter(){
        if(this.isEmail == true || this.isFeedbackPopup == true || this.mailSent == true ){
            return true;
        }
        return false;
    }

    connectedCallback(){
        checkOldChats()
        .then((result) =>{
            if(result != null){
                this.isChatStarted = true;
                this.hideChatBar = true;
                this.isOnlyEmail = false;
                this.isSol = true;
                this.isIssue = false;
                this.messages = JSON.parse(result);
                this.oldChats = true;
                this.isSpinner = false;
            }
                
        });
        this.isSpinner = true;
        this.fetchingImageUrl();
        this.chatBot = chatBot;
        this.chatUser = chatUser;
        this.item1 = Feedback+'/item5.svg';
        this.item2 = Feedback+'/item4.svg';
        this.item3 = Feedback+'/item3.svg';
        this.item4 = Feedback+'/item2.svg';
        this.item5 = Feedback+'/item1.svg';  
        this.question = 'What seems to be causing you trouble?'; 
        this.fetchingMainFAQS();
              
    }

    renderedCallback() {
        this.updateScroll();
        if(!this.customTimeout){
            this.customTimeout = this.template.querySelector('c-custom-timeout');
        }
    }


    checkEmailActive(){
        if(this.isEmail){
            const windowsize = this.template.querySelector('.popupopen');
            const windowmessage = this.template.querySelector('.message');
            windowsize.style.height = '500px';
            windowmessage.style.height = '500px';
            windowmessage.style.maxHeight = '500px';
        }
    }

    checkFeedbackActive(){
        if(this.isFeedbackPopup){
            const windowsize = this.template.querySelector('.popupopen');
            const windowmessage = this.template.querySelector('.message');
            windowsize.style.height = '500px';
            windowmessage.style.height = '500px';
            windowmessage.style.maxHeight = '500px';
        }
    }

    handleFilesChange(event) {
        this.attachmentError = false;
        this.fileSizeError = false;
    
        const files = Array.from(event.target.files);
        const allowedTypes = ['image/png', 'image/jpg', 'image/jpeg', 'image/gif'];
        const maxSize = 2.5 * 1024 * 1024; // 2.5 MB
    
        let totalFileSize = this.selectedFileSize;
        const currentLength = this.uploadedFiles.length;
        let validFiles = [];
    
        // Validate all files synchronously
        files.forEach((file) => {
            if (!allowedTypes.includes(file.type)) {
                this.attachmentError = true;
            } else if (totalFileSize + file.size > maxSize) {
                this.fileSizeError = true;
            } else {
                validFiles.push(file); // Only keep valid files for further processing
                totalFileSize += file.size; // Increment total file size
            }
        });
    
        // If there are errors, stop further processing
        if (this.attachmentError || this.fileSizeError) {
            return;
        }
    
        // Process valid files asynchronously
        validFiles.forEach((file, index) => {
            const reader = new FileReader();
            reader.onload = () => {
                const fileInfo = {
                    id: currentLength + index + 1, // Assign a unique id
                    fileName: file.name,
                    fileNameShort: file.name.length > 16 ? `${file.name.substring(0, 13)}...` : file.name,
                    fileNameExtraShort: file.name.length > 13 ? `${file.name.substring(0, 11)}...` : file.name,
                    fileSize: this.formatFileSize(file.size),
                    isImage: allowedTypes.includes(file.type),
                    displayUrl: reader.result,
                    fileUrl: reader.result.split(',')[1],
                };
    
                this.uploadedFiles = [...this.uploadedFiles, fileInfo]; // Update uploaded files
            };
            reader.readAsDataURL(file);
        });
    
        // Update total size after processing all valid files
        this.selectedFileSize = totalFileSize;
    }
    

    showDiv() {
        const hiddenDiv = this.template.querySelector('.circle-active svg');
        if (hiddenDiv) {
            hiddenDiv.style.visibility = 'visible';
        }
    }

    hideDiv() {
        const hiddenDiv = this.template.querySelector('.circle-active svg');
        if (hiddenDiv) {
            hiddenDiv.style.visibility = 'hidden';
        }
    }

    handleFeedbackChange(event){
        const userfeedback = event.target.value;
        this.userFeedback = userfeedback.trim();
        
    }

    handleInputChange(event){
        const field = event.target.dataset.id;
        if(field === 'replyAddress'){
            this.replyAddress = event.target.value.trim();
            const field = this.template.querySelector('.mail-body input');
            field.style.border = '';
            this.emailErrorMessage = false;
        }
        else if(field === 'body'){
            this.body = event.target.value.trim();
            const field = this.template.querySelector('.mail-body textarea');
            field.style.border = ''; 
        }
    }

    formatFileSize(size) {
        if (size < 1048576) return (size / 1024).toFixed(1) + ' KB';
        return (size / 1048576).toFixed(1) + ' MB';
    }

    submitFeedback(){
        if(this.feedbackRating != null){
            sendFeedbackEmail({toAddress: this.toAddress, key: this.feedbackRating, feedback: this.userFeedback, chats: JSON.stringify(this.messages)})
            .then(() => {
                this.isThankYou = true;
                this.customTimeout?.setCustomTimeoutMethod(() => {
                    this.handleClearClose();
                }, 2000);
            })
            .catch(() => {
                this.isThankYou = true;
                this.customTimeout?.setCustomTimeoutMethod(() => {
                    this.handleClearClose();
                }, 2000);
            })
        }
    }

    checkWord(){
    const keywords = ["EndChat", "GoogleDrive", "Dropbox", "OneDrive", "AWS" ,"Integration", "Simple Template", "CSV Template", "Google Doc Template", "Template Builder", "Template Status", "Template Limit", "Template Preview", "Template default button", "Template", "Unable to Perform Operations", "Doc Genius", "Email Us"];
    const keywordVariations = keywords.reduce((acc, keyword) => {
        const noSpaceKeyword = keyword.replace(/\s+/g, '').toLowerCase();
        acc[keyword] = new RegExp(noSpaceKeyword, 'i');
        return acc;
    }, {});

    // Initialize an empty array to store the found keywords
    const foundKeywords = '';

    // // Normalize the input to lower case and remove extra spaces for consistency
    const normalizedInput = this.textValue.toLowerCase().replace(/\s+/g, '');

    // Loop through each keyword variation
    for (const originalKeyword in keywordVariations) {
        const regex = keywordVariations[originalKeyword];
        if (regex.test(normalizedInput)) {
            // If the keyword or its variation is found, add the original keyword to the list
            if (!foundKeywords.includes(originalKeyword)) {
                if(originalKeyword === "EndChat"){
                    return null;
                }
                this.keyword = originalKeyword;
                this.updateParsedJson(this.jsonFaqs, this.keyword);
                    return originalKeyword;
            }
        }
    }
    return 'NORESULT';
    }

    updateParsedJson(data, keyword) {
        data.forEach((item) =>{
            if (item.subQuestions && item.subQuestions.length > 0) {
                this.findInSubQuestions(item.subQuestions, keyword);
            }
        });
        return null;
    }
    
    findInSubQuestions(subQuestions, keyword) {
        let foundSubQuestions = [];
        subQuestions.forEach((subItem) => {
            if (subItem.question.toLowerCase().includes(keyword.toLowerCase())) {
                this.selectedJSON = subItem;
                foundSubQuestions.push(subItem);
            }
            if (subItem.subQuestions && subItem.subQuestions.length > 0) {
                const result = this.findInSubQuestions(subItem.subQuestions, keyword);
                foundSubQuestions = foundSubQuestions.concat(result);
            }
        });
        return foundSubQuestions;
    }

    toggleFeedback(){
        if(this.isEmail){
            this.emailWasActive = true;
        }
        this.isFeedbackPopup = this.isFeedbackPopup ? false : true;
        this.isEmail = false;
        this.selectedFileSize = 0;
        this.checkFeedbackActive();
        if (!this.isFeedbackPopup) {
            this.handleClearClose();
        } 
    }

    toggleClear(){
        if(this.isFeedbackPopup){
            this.toggleFeedback();
        }
        this.isClearPopup = this.isClearPopup ? false : true;
              
    }

    toggleCircle(){
        this.hideCircle = !this.hideCircle;
        const bot = this.template.querySelector(".hidden-bot");
        bot.classList.add("expand");
    }

    toggleHelpful(){
        this.useful = false;
        this.toggleFeedback();
    }

    toggleNotHelpful(){
        this.useful = false;
        this.notHelpful = true;
    }
    

    redirectToFaq(){
        window.open('https://mvclouds.com/docgenius/faqs/', '_blank');
    }

    

    fetchingMainFAQS() {
        // No async operation, no polling, just direct checks
        getJsonFaqs()
                .then(result =>{
                    this.jsonFaqs = JSON.parse(result);
                    if (this.isEmail) {
                        this.issues = null;
                        this.isSpinner = false;
                    } else if (this.jsonFaqs && !this.oldChats) {
                        this.issues = this.jsonFaqs.map(item => item.question);
                    } else if (this.oldChats) {
                        this.issues = null;
                    } else {
                        if (this.jsonFaqs) {
                            this.issues = this.jsonFaqs.map(item => item.question);
                        } else {
                            this.isSpinner = false;
                        }
                    }
                
                    if (this.issues != null) {
                        this.isSpinner = false;
                        this.isIssue = true;
                    }
                })
    }

    fetchingSubFAQS(selectedQuestion){
        if(this.selectedJSON == null){
            this.selectedJSON = this.jsonFaqs.find(faq => faq.question === selectedQuestion);
            this.checkSpinnerDuration((result) => {
                if(result === 'success'){
                    this.isTimer = true;
                    if(this.isEmail){
                        this.issues = null;
                        this.isSpinner = false;
                    }
                    else if (this.selectedJSON && this.selectedJSON.subQuestions.length > 0) {
                        this.issues = this.selectedJSON.subQuestions.map(item => item.question);
                    } else {
                        this.issues = [];
                    }
                    if(this.isTimer == true && (this.issues != null || this.solution != null)){
                        this.isSpinner = false;
                        if(this.issues != null){
                            this.isIssue = true;
                        }
                    }
                }
            });
        }
        else{
            this.selectedJSON = this.selectedJSON.subQuestions.find(faq => faq.question === selectedQuestion);
            this.checkSpinnerDuration((result) => {
                if(result === 'success'){
                    this.isTimer = true;
                    if(this.isEmail){
                        this.issues = null;
                        this.isSpinner = false;
                    }
                    else if (this.selectedJSON && this.selectedJSON.subQuestions && this.selectedJSON.subQuestions.length > 0) {
                        this.issues = this.selectedJSON.subQuestions.map(item => item.question);
                    } else if(this.selectedJSON && this.selectedJSON.answer) {
                        this.isSolution = true;
                        this.useful = true;
                        this.solution = this.selectedJSON.answer;
                        this.issues = [];
                    }
                    if(this.isTimer == true && (this.issues != null || this.isSolution == true)){
                        this.isSpinner = false;
                        if(this.issues != null){
                            this.isIssue = true;
                        }
                        if(this.isSolution == true){
                            this.isIssue = false;
                            this.isSol = true;
                            this.hideChatBar = true;
                            this.currentTime = ChatBotV2
                        .captureCurrentTime();
                            this.messages.push({text: this.solution, isSolution: true, time: this.currentTime});
                            this.updateScroll();
                            storeMessages({msg: JSON.stringify(this.messages)})
                            .then(()=>{
                            })
                        }
                    }
                }
            });
        }
        
    }

    

    get popupClass() {
        return this.popupOpen ? 'popupopen' : 'popup';
    }


    handleSendEmail() {
        this.emailErrorMessage = false;

        if(this.replyAddress == ''){
           const field = this.template.querySelector('.mail-body input');
           field.style.border = '1px solid red'; 
        }
        if(this.body == ''){
            const field = this.template.querySelector('.mail-body textarea');
            field.style.border = '1px solid red'; 
        }
        else if(this.body && this.replyAddress){
            
        const fileNames = this.uploadedFiles.map(file => file.fileName);
        const fileContents = this.uploadedFiles.map(file => file.fileUrl);
        const btn = this.template.querySelector('.mail-submit');
        btn.style.background = 'grey';
        btn.setAttribute('disabled', true);
        

        sendEmailWithAttachment({ parameters: {
            toAddress: this.toAddress,
            replyTo: this.replyAddress,
            subject: this.subject,
            body: this.body,
            fileNames: fileNames,
            fileContents: fileContents
        }})
        .then(() => {
            // handle success, show a success message or toast
            this.mailSent = true;
            this.isEmail = false;
            this.emailErrorMessage = false;
            this.fileSizeError = false;
            this.unknownError = false;
            this.attachmentError = false;
            this.selectedFileSize = 0;
        })
        .catch(error => {
            // handle error, show an error message or toast
            
            const existingErrorElement = this.template.querySelector('.error-message');
            if (existingErrorElement) {
                existingErrorElement.remove();
            }
            if(error.body && error.body.message && error.body.message.includes('INVALID_EMAIL_ADDRESS')){
                this.emailErrorMessage = true;
                const btn = this.template.querySelector('.mail-submit');
                btn.style.background = '#00AEFF';
                btn.removeAttribute('disabled');
            }
            else{
                this.unknownError = true;
            }

        });
    }
    }

    fetchingImageUrl(){
        fetchImageUrl({cid: this.userId})
        .then(result =>{
            if(!result.endsWith('/profilephoto/005/F')){
            this.chatUser = result;
            }
        });
    }


    toggleBot(){
        this.popupOpen = true;
        if(!this.isChatStarted){
            this.isSpinner = true;
            this.issues = null;
            this.isIssue = false;
            this.fetchingMainFAQS();
        }
        if(this.isChatStarted && this.oldChats){
            this.fetchingMainFAQS();
        }
        
        this.customTimeout?.setCustomTimeoutMethod(() => {
            this.checkEmailActive();
            this.checkFeedbackActive();
        }, 300);
    }

    togglePopupClose(){
        if(this.isFeedbackPopup && this.emailWasActive){
            this.isEmail = true;
        }
        this.isFeedbackPopup = false;
        if(!this.mailSent){
            this.attachmentError = false;
            this.fileSizeError = false;
            this.unknownError = false;
            this.replyAddress = '';
            this.body = '';
            this.emailErrorMessage = false;
            this.uploadedFiles = [];
        }
        this.popupOpen = false;
    }

    updateScroll(){
        const scrollable = this.template.querySelector('.message');       
        scrollable && (scrollable.scrollTop = scrollable.scrollHeight);
    }

    handleClick(event){      
        if(!this.isChatStarted){
            this.isChatStarted = true;
            this.hideChatBar = true;
            this.isOnlyEmail = false;

        }
        this.hideChatBar = false;
        this.isIssue = false;
        this.isSol = false;
        this.isSpinner = true;
        this.isTimer = false;
        this.checkSpinnerDuration(() => {
        });
        this.currentTime = ChatBotV2
    .captureCurrentTime();
        this.issues = null;
        this.messages.push({text: this.question, isQuestion: true, time: this.currentTime});
        this.messages.push({text: event.currentTarget.dataset.value, isAnswer: true, time: this.currentTime});
        this.question = 'What seems to be causing you trouble in '+ event.currentTarget.dataset.value+ ' ?';
        storeMessages({msg: JSON.stringify(this.messages)})
        .then(()=>{
        })
        this.fetchingSubFAQS(event.currentTarget.dataset.key);

    }

    handleChat(){
        this.isThankYou = false;
        this.body = '';
        this.subject = '';
        this.replyAddress = '';
        this.uploadedFiles = null;
        this.isOnlyEmail = true;
        this.hideChatBar = true;
        this.selectedFileSize = 0;
        this.emailWasActive = false;
        this.isIssue = false;
        this.isSol = false;
        this.issues = null;
        this.messages = [];
        this.solution = null;
        this.uploadedFiles = [];
        this.notHelpful = false;
        this.Email
        this.isEmail = false;
        this.mailSent = false;
        this.isChatStarted = false;
        this.selectedJSON = null;
        this.isSolution = false;
        this.useful = false;
        this.isFeedbackPopup = false;
        this.attachmentError = false;
        this.fileSizeError = false;
        this.unknownError = false;
        const windowsize = this.template.querySelector('.popupopen');
        const windowmessage = this.template.querySelector('.message');
        windowsize.style.height = '430px';
        windowmessage.style.height = '430px';
        windowmessage.style.maxHeight = '430px';
        this.oldChats = false;
        // this.toggleClear();
        deleteOldChats()
        .then(()=>{
            this.connectedCallback();
        })
        .catch(() =>{
            this.connectedCallback();
        });
        this.isTimer = false;
    }

    handleClearClose(){
        this.uploadedFiles = null;
        this.popupOpen = false;
        this.handleChat();
    }

    handleTimeout(event){
        try {
            if(event?.detail?.function){
                event?.detail?.function();
            }
        } catch (error) {
            errorDebugger('DocumentLoaderV2', 'handleTimeout', error, 'warn')
        }
    }


    getRandomTime(){
        const randomIndex = Math.floor(Math.random() * this.time.length);
        const randomTime = this.time[randomIndex];
        return randomTime;
    }

    checkSpinnerDuration(callback){
        this.customTimeout?.setCustomTimeoutMethod(() => {
            callback('success');
        }, this.getRandomTime());
    }

    checkEnter(event){

          if (event.key === "Enter") {
            event.preventDefault();
            this.sendChat();
          }
        
    }

    sendChat(){
        if(this.template.querySelector('.communicate').value != ''){
            if(!this.isChatStarted){
                this.isChatStarted = true;
            }
            this.textValue = this.template.querySelector('.communicate').value;
            this.template.querySelector('.communicate').value = null;
            this.isIssue = false;
            this.issues = null;
            this.isSol = false;
            this.isSolution = false;
            this.useful = false;
            this.solution = null;
            this.isSpinner = true;
            this.isTimer = false;
            this.query = null;
            this.checkSpinnerDuration((result) => {
                this.isTimer = true;
                if(result === 'success' && this.query ==='NORESULT' ){
                    this.currentTime = ChatBotV2
                .captureCurrentTime();
                    this.messages.push({text: 'Oops, I couldn\'t understand that.', isQuestion: true, time: this.currentTime});
                    this.isSpinner = false;
                    storeMessages({msg: JSON.stringify(this.messages)})
                }
                else if(this.query == null){
                    this.isSpinner = false;
                    this.handleChat();
                    this.toggleBot();
                }
                else if(result === 'success' && this.query != null){
                    this.question = 'Is this what you were looking for?';

                    if (this.selectedJSON && this.selectedJSON.subQuestions && this.selectedJSON.subQuestions.length > 0) {
                        this.issues = this.selectedJSON.subQuestions.map(item => item.question);
                    }else if(this.query == null){
                        this.isSpinner = false;
                        this.handleChat();
                        this.toggleBot();
                    } else if(this.selectedJSON && this.selectedJSON.answer) {
                        this.isSolution = true;
                        this.useful = true;
                        this.solution = this.selectedJSON.answer
                        this.issues = [];
                    }
                    if(this.isTimer == true && (this.issues != null || this.isSolution == true)){
                        this.isSpinner = false;
                        if(this.issues != null){
                            this.isIssue = true;
                        }
                        if(this.isSolution == true){
                            this.isIssue = false;
                            this.hideChatBar = true;
                            this.isSol = true;
                            this.currentTime = ChatBotV2
                        .captureCurrentTime();
                            this.messages.push({text: this.solution, isSolution: true, time: this.currentTime});
                            storeMessages({msg: JSON.stringify(this.messages)})
                            .then(()=>{
                            })
                        }
                    }
                }
            });
            this.issues = null;
            this.currentTime = ChatBotV2
        .captureCurrentTime();
            this.messages.push({text: this.textValue, isAnswer: true, time: this.currentTime});
            storeMessages({msg: JSON.stringify(this.messages)})
            .then(()=>{
            });
            this.query = this.checkWord();
            if(this.query === 'NORESULT' && this.isTimer == true){
                this.currentTime = ChatBotV2
            .captureCurrentTime();
                this.messages.push({text: 'Sorry, I couldn\'t understand that.', isQuestion: true, time: this.currentTime});
                this.isSpinner = false;
                storeMessages({msg: JSON.stringify(this.messages)})
                .then(()=>{
                });
            }
            else if(this.query != null && this.isTimer == true){
                // this.fetchingSubFAQS(key);
                this.question = 'Is this what you were looking for?';
                
                        // this.isTimer = true;
                        if (this.selectedJSON && this.selectedJSON.subQuestions && this.selectedJSON.subQuestions.length > 0) {
                            this.issues = this.selectedJSON.subQuestions.map(item => item.question);
                        } else if(this.selectedJSON && this.selectedJSON.answer) {
                            this.isSolution = true;
                            this.useful = true;
                            this.solution = this.selectedJSON.answer
                            this.issues = [];
                        }
                        if(this.isTimer == true && (this.issues != null || this.isSolution == true)){
                            this.isSpinner = false;
                            if(this.issues != null){
                                this.isIssue = true;
                            }
                            if(this.isSolution == true){
                                this.isIssue = false;
                                this.isSol = true;
                                this.hideChatBar = true;
                                this.currentTime = ChatBotV2
                            .captureCurrentTime();
                                this.messages.push({text: this.solution, isSolution: true, time: this.currentTime});
                                storeMessages({msg: JSON.stringify(this.messages)})
                                .then(()=>{
                                })
                            }
                        }
            }
        }   
    }

    handleRemoveFile(event) {
        const fileId = event.target.dataset.id;
        const fileToRemove = this.uploadedFiles.find(file => file.id === parseInt(fileId, 10));
        
    
        if (fileToRemove) {
            
            const fileSizeInBytes = this.convertFileSizeToBytes(fileToRemove.fileSize);
            this.selectedFileSize -= fileSizeInBytes;            
            
            this.uploadedFiles = this.uploadedFiles.filter(file => file.id !== parseInt(fileId, 10));
        }
    
        this.fileSizeError = false;
    }
    
    convertFileSizeToBytes(fileSize) {
        // Assuming fileSize comes in formats like '2 MB', '500 KB', etc.
        const sizeUnit = fileSize.slice(-2).toUpperCase(); // Get the unit (MB, KB)
        const sizeValue = parseFloat(fileSize); // Get the numeric part
    
        let fileSizeInBytes = 0;
        switch (sizeUnit) {
            case 'MB':
                fileSizeInBytes = sizeValue * 1024 * 1024; // Convert MB to bytes
                break;
            case 'KB':
                fileSizeInBytes = sizeValue * 1024; // Convert KB to bytes
                break;
            case 'B':
            default:
                fileSizeInBytes = sizeValue; // Already in bytes
                break;
        }
        return fileSizeInBytes;
    }

    toggleitem(event){
        const images = this.template.querySelectorAll('.stars img');
        images.forEach(img => {
            img.style.filter = 'grayscale(1)';
        });

        

        const clickedImage = event.target;
        if(event.target.dataset.key == '1'){          
            this.feedbackRating = 1;
            clickedImage.style.filter = 'grayscale(0)';
        }
        else if(event.target.dataset.key == '2'){
            this.feedbackRating = 2;

            clickedImage.style.filter = 'grayscale(0)';
        }
        else if(event.target.dataset.key == '3'){
            this.feedbackRating = 3;
            clickedImage.style.filter = 'grayscale(0)';

        }
        else if(event.target.dataset.key == '4'){
            this.feedbackRating = 4;
            clickedImage.style.filter = 'grayscale(0)';

        }
        else if(event.target.dataset.key == '5'){
            clickedImage.style.filter = 'grayscale(0)';
            this.feedbackRating = 5;
        }

        if(this.feedbackRating != ''){
            const enableBtn = this.template.querySelector('.feedbackBtn');
            enableBtn.style.background = '#00AEFF';
            enableBtn.disabled = false;
            }
        
    }

    emailPopup(){
        this.isChatStarted = true;
        this.isIssue = false;
        this.isEmail = true;
        this.selectedFileSize = 0;
        this.mailSent = false;
        const windowsize = this.template.querySelector('.popupopen');
        const windowmessage = this.template.querySelector('.message');
        windowsize.style.height = '500px';
        windowmessage.style.height = '500px';
        windowmessage.style.maxHeight = '500px';
    }

}