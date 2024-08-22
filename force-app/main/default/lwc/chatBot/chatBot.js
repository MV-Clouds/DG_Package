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

export default class ChatBot extends LightningElement {
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
    @track subject = 'Issue in Docgenius';
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

    currentTime = '09:48';
    rendered = false;
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
        getJsonFaqs()
                .then(result =>{
                    this.jsonFaqs = JSON.parse(result);
                    // console.log(JSON.stringify(this.jsonFaqs));
                })
                .catch(error =>{
                    console.error(error);
                });  
        checkOldChats()
        .then((result) =>{
            if(result != null){
                this.isChatStarted = true;
                this.hideChatBar = false;
                this.isOnlyEmail = false;
                // console.log(result);
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
        // console.log('rendered');
        this.updateScroll();
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
        const files = event.target.files;
        const allowedTypes = ['image/png', 'image/jpg', 'image/jpeg', 'image/gif'];
        const currentLength = this.uploadedFiles.length;

        const existingErrorElement = this.template.querySelector('.error-message');
        if (existingErrorElement) {
            existingErrorElement.remove();
        }

        Array.from(files).forEach((file, index) => {
            if (!allowedTypes.includes(file.type)) {
                this.errorMessage = 'Only image files (PNG, JPG, JPEG, GIF) are allowed.';
                const field = this.template.querySelector('.mail-body');
                const newParagraph = document.createElement('p');
                newParagraph.className = 'error-message';
                newParagraph.style.color = 'red';
                newParagraph.textContent = 'Only image files (PNG, JPG, JPEG, GIF) are allowed.';
                field.appendChild(newParagraph);
                return; // Stop processing further files if an error occurs
            }

            const reader = new FileReader();
            reader.onload = () => {
                const fileInfo = {
                    id: currentLength + index + 1, // Assign a unique id starting from 1
                    fileName: file.name,
                    fileNameShort: file.name.length > 16 ? `${file.name.substring(0, 13)}...` : file.name,
                    fileNameExtraShort:file.name.length > 13 ? `${file.name.substring(0, 11)}...` : file.name,
                    fileSize: this.formatFileSize(file.size),
                    isImage: ['image/png', 'image/jpg', 'image/jpeg', 'image/gif'].includes(file.type),
                    displayUrl: reader.result,
                    fileUrl: reader.result.split(',')[1]
                };

                this.uploadedFiles = [...this.uploadedFiles, fileInfo];
            };
            reader.readAsDataURL(file);
        });
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
        const userfeedback = event.target.dataset.id;
        this.userFeedback = userfeedback.trim();
    }

    handleInputChange(event){
        const field = event.target.dataset.id;
        if(field === 'replyAddress'){
            this.replyAddress = event.target.value.trim();
            const field = this.template.querySelector('.mail-body input');
            field.style.border = ''; 
        }
        else if(field === 'body'){
            this.body = event.target.value.trim();
            const field = this.template.querySelector('.mail-body textarea');
            field.style.border = ''; 
        }
    }

    formatFileSize(size) {
        // console.log(size);
        if (size < 1048576) return (size / 1024).toFixed(1) + ' KB';
        return (size / 1048576).toFixed(1) + ' MB';
    }

    submitFeedback(){
        // console.log('FEEDBACK'+this.feedbackRating);
        if(this.feedbackRating != null){
            sendFeedbackEmail({toAddress: this.toAddress, key: this.feedbackRating, feedback: this.userFeedback, chats: JSON.stringify(this.messages)})
            .then((result) => {
                this.handleClearClose();
            })
            .catch((error) => {
                console.error('error sending feedback');
                this.handleClearClose();
            })
        }
    }

    checkWord(){
    const keywords = ["EndChat", "Template Builder", "Template", "GoogleDrive", "Dropbox" ,"Integration"];
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
                    // console.log('returning null');
                    return null;
                }
                // console.log(originalKeyword);
                // console.log('finding issue');
                this.keyword = originalKeyword;
                this.updateParsedJson(this.jsonFaqs, this.keyword);
                    // console.log('no issues found');
                    return originalKeyword;
            }
        }
    }
    return 'NORESULT';
    }

    updateParsedJson(data, keyword) {
        // console.log('Inside update json');
        for (const item of data) {
            if (item.question.toLowerCase() === keyword.toLowerCase()) {
                // console.log(JSON.stringify(item));
                // console.log('outside updateParsed json1');
            }
            if (item.subQuestions && item.subQuestions.length > 0) {
                const subQuestions = this.findInSubQuestions(item.subQuestions, keyword);
                // console.log('outside updateParsed json2');
            }
        }
        return null;
    }
    
    findInSubQuestions(subQuestions, keyword) {
        let foundSubQuestions = [];
        // console.log('inside findInSubQuesitons');
        for (const subItem of subQuestions) {
            if (subItem.question.toLowerCase().includes(keyword.toLowerCase())) {
                this.selectedJSON = subItem;
                // // console.log(JSON.stringify(subItem))
                foundSubQuestions.push(subItem);
                // console.log('outside findInSubQuesitons');
            }
            if (subItem.subQuestions && subItem.subQuestions.length > 0) {
                const result = this.findInSubQuestions(subItem.subQuestions, keyword);
                // console.log(JSON.stringify(result));
                foundSubQuestions = foundSubQuestions.concat(result);
                // console.log('outside findInSubQuesitons');
            }
        }
        return foundSubQuestions;
    }

    toggleFeedback(){
        
        this.isFeedbackPopup = this.isFeedbackPopup ? false : true;
        this.checkFeedbackActive();
        if (!this.isFeedbackPopup) {
            this.handleClearClose();
        }
        setTimeout(() =>{
            const images = this.template.querySelectorAll('img[data-key]');
    
            images.forEach(img => {
                img.style.filter = 'grayscale(1)';
            });
            this.toggleitem();
        }, 100);
        
       
    }

    toggleClear(){
        if(this.isFeedbackPopup){
            this.toggleFeedback();
        }
        // console.log(this.isClearPopup);
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
        window.open('https://www.google.com', '_blank');
    }

    

    fetchingMainFAQS(){
        // console.log('invoked mainfaqs');
        this.checkSpinnerDuration((result) => {
            if(result === 'success'){
                this.isTimer = true;
                // console.log('Time completed and finding issues');
                if(this.isEmail){
                    this.issues = null;
                    this.isSpinner = false;
                }
                else if(this.jsonFaqs && !this.oldChats){
                    this.issues = this.jsonFaqs.map(item => item.question);
                }
                else if(this.oldChats){
                    this.issues = null;
                }
                else{
                    let waitCount = 0;
                    const maxRetries = 5;
                    const waitLoop = setTimeout(() => {
                        // console.log('counting');
                        waitCount++;
                        if (this.jsonFaqs || waitCount >= maxRetries){
                            // console.log('clearing interval');
                            clearInterval(waitLoop);
                            if(this.isEmail){
                                this.issues = null;
                                this.isSpinner = false;
                            }
                            else if (this.jsonFaqs){
                                this.issues = this.jsonFaqs.map(item => item.question);
                            }
                            else{
                                this.isSpinner = false;
                                console.error('Failed to fetch Faqs');
                            }
                        }
                    }, 1000);
                }
                // console.log('Fetched MainFAQs:', this.issues);

                if(this.isTimer == true && this.issues != null){
                    this.isSpinner = false;
                    this.isIssue = true;
                }
            }
        });
        
    }

    fetchingSubFAQS(selectedQuestion){
        if(this.selectedJSON == null){
            this.selectedJSON = this.jsonFaqs.find(faq => faq.question === selectedQuestion);
            // // console.log('This is subfaq '+ JSON.stringify(JSON.parse(this.selectedJSON)));
            this.checkSpinnerDuration((result) => {
                if(result === 'success'){
                    this.isTimer = true;
                    // console.log('Time completed');
                    if(this.isEmail){
                        this.issues = null;
                        this.isSpinner = false;
                    }
                    else if (this.selectedJSON && this.selectedJSON.subQuestions.length > 0) {
                        this.issues = this.selectedJSON.subQuestions.map(item => item.question);
                        // console.log(`Fetched SubFAQs for ${selectedQuestion}:`, this.issues);
                    } else {
                        this.issues = [];
                        // console.log(`No SubFAQs found for ${selectedQuestion}.`);
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
            // // console.log('selected json is not null-->'+JSON.stringify(JSON.parse(JSON.stringify(this.selectedJSON))));
            this.selectedJSON = this.selectedJSON.subQuestions.find(faq => faq.question === selectedQuestion);
            // // console.log('This is subfaq '+ JSON.stringify(this.selectedJSON));
            this.checkSpinnerDuration((result) => {
                if(result === 'success'){
                    this.isTimer = true;
                    // console.log('Time completed');
                    if(this.isEmail){
                        this.issues = null;
                        this.isSpinner = false;
                    }
                    else if (this.selectedJSON && this.selectedJSON.subQuestions && this.selectedJSON.subQuestions.length > 0) {
                        this.issues = this.selectedJSON.subQuestions.map(item => item.question);
                        // console.log(`Fetched SubFAQs for ${selectedQuestion}:`, this.issues);
                    } else if(this.selectedJSON && this.selectedJSON.answer) {
                        // console.log('inside else');
                        this.isSolution = true;
                        this.useful = true;
                        this.solution = this.selectedJSON.answer;
                        this.issues = [];
                        // console.log(`No SubFAQs found for ${selectedQuestion}.`);
                    }
                    if(this.isTimer == true && (this.issues != null || this.isSolution == true)){
                        this.isSpinner = false;
                        if(this.issues != null){
                            // console.log('issue');
                            this.isIssue = true;
                        }
                        if(this.isSolution == true){
                            // console.log('solution');
                            this.isIssue = false;
                            this.isSol = true;
                            this.hideChatBar = true;
                            this.currentTime = ChatBot
                        .captureCurrentTime();
                            this.messages.push({text: this.solution, isSolution: true, time: this.currentTime});
                            this.updateScroll();
                            storeMessages({msg: JSON.stringify(this.messages)})
                            .then((result)=>{
                                // console.log(result);
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
        // console.log('Chatbot mail invoked');
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
        // console.log(this.body);
        // console.log(this.subject);
        // console.log(this.toAddress);
        // console.log(fileNames);
        // console.log(fileContents);
        // console.log('Sending email');
        sendEmailWithAttachment({ parameters: {
            toAddress: this.toAddress,
            replyTo: this.replyAddress,
            subject: this.subject,
            body: this.body,
            fileNames: fileNames,
            fileContents: fileContents
        }})
        .then(result => {
            // handle success, show a success message or toast
            // console.log('Email sent successfully');
            this.mailSent = true;
            this.isEmail = false;
        })
        .catch(error => {
            // handle error, show an error message or toast
            const existingErrorElement = this.template.querySelector('.error-message');
            if (existingErrorElement) {
                existingErrorElement.remove();
            }
            if(error.body && error.body.message && error.body.message.includes('INVALID_EMAIL_ADDRESS')){
            const field = this.template.querySelector('.mail-body');
            const newParagraph = document.createElement('p');
            newParagraph.className = 'error-message'; // Assign a class for easier identification
            newParagraph.style.color = 'red';
            newParagraph.textContent = 'Invalid Email Address';
            field.appendChild(newParagraph);
            console.error('Error sending email: ', error);
            // console.log(error.body);
            // console.log(error.body.message);
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
        // console.log('Is popup open'+this.popupOpen);
        if(!this.isChatStarted){
            this.isSpinner = true;
            this.issues = null;
            this.isIssue = false;
            this.fetchingMainFAQS();
        }
        if(this.isChatStarted && this.oldChats){
            this.fetchingMainFAQS();
        }
        setTimeout(() =>{
            this.checkEmailActive();
            this.checkFeedbackActive();
        },100);
        // console.log('checked');
    }

    togglePopupClose(){

        // console.log('closing');
        this.rendered = false;
        this.popupOpen = false;
        this.isFeedbackPopup = false;
        
    }

    updateScroll(){
        const scrollable = this.template.querySelector('.popupopen .message');
        if (scrollable && scrollable.lastElementChild) {
            scrollable.lastElementChild.scrollIntoView({ behavior: 'smooth', block: 'end' });
        }
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
        this.checkSpinnerDuration((result) => {
            // console.log(result); // Will log 'success' after a random time
        });
        // console.log(event.currentTarget.dataset.key);
        // console.log(event.currentTarget.dataset.value);
        this.currentTime = ChatBot
    .captureCurrentTime();
        this.issues = null;
        this.messages.push({text: this.question, isQuestion: true, time: this.currentTime});
        this.messages.push({text: event.currentTarget.dataset.value, isAnswer: true, time: this.currentTime});
        storeMessages({msg: JSON.stringify(this.messages)})
        .then((result)=>{
            // console.log(result);
        })
        // console.log('this is message -->',JSON.stringify(this.messages));
        this.fetchingSubFAQS(event.currentTarget.dataset.key);

    }

    handleChat(){
        this.isOnlyEmail = true;
        this.hideChatBar = true;
        // console.log('Inside handle chat');
        this.isIssue = false;
        this.isSol = false;
        this.issues = null;
        this.messages = [];
        this.solution = null;
        this.notHelpful = false;
        this.Email
        this.isEmail = false;
        this.mailSent = false;
        this.isChatStarted = false;
        this.selectedJSON = null;
        this.isSolution = false;
        this.useful = false;
        this.isFeedbackPopup = false;
        const windowsize = this.template.querySelector('.popupopen');
        const windowmessage = this.template.querySelector('.message');
        windowsize.style.height = '430px';
        windowmessage.style.height = '430px';
        windowmessage.style.maxHeight = '430px';
        this.oldChats = false;
        // this.toggleClear();
        deleteOldChats()
        .then(result=>{
            this.connectedCallback();
        })
        .catch((error) =>{
            this.connectedCallback();
        });
        this.isTimer = false;
    }

    handleClearClose(){
        this.rendered = false;
        this.popupOpen = false;
        this.handleChat();
    }


    getRandomTime(){
        const randomIndex = Math.floor(Math.random() * this.time.length);
        const randomTime = this.time[randomIndex];
        // console.log(randomTime);
        return randomTime;
    }

    checkSpinnerDuration(callback){
        setTimeout(()=>{
            callback('success');
        }, this.getRandomTime());
    }

    checkEnter(event){

          if (event.key === "Enter") {
            event.preventDefault();
            // console.log('check enter');
            this.sendChat();
          }
        
    }

    sendChat(){
        if(this.template.querySelector('.communicate').value != ''){
            if(!this.isChatStarted){
                this.isChatStarted = true;
            }
            this.textValue = this.template.querySelector('.communicate').value;
            // console.log(this.textValue);
            this.template.querySelector('.communicate').value = null;
            // console.log('Issue with variable');
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
                    this.currentTime = ChatBot
                .captureCurrentTime();
                    this.messages.push({text: 'Sorry, I couldn\'t understand.', isQuestion: true, time: this.currentTime});
                    this.isSpinner = false;
                    storeMessages({msg: JSON.stringify(this.messages)})
                    .then((result)=>{
                        // console.log(result);
                    });
                }
                else if(this.query == null){
                    this.isSpinner = false;
                    this.handleChat();
                    this.toggleBot();
                }
                else if(result === 'success' && this.query != null){
                    this.question = 'Is this what you were looking for?';

                    if (this.selectedJSON && this.selectedJSON.subQuestions && this.selectedJSON.subQuestions.length > 0) {
                        // console.log('INSIDE IF');
                        // console.log(this.selectedJSON);
                        this.issues = this.selectedJSON.subQuestions.map(item => item.question);
                        // console.log(JSON.stringify(this.issues));
                    }else if(this.query == null){
                        this.isSpinner = false;
                        this.handleChat();
                        this.toggleBot();
                    } else if(this.selectedJSON && this.selectedJSON.answer) {
                        // console.log('inside else');
                        this.isSolution = true;
                        this.useful = true;
                        this.solution = this.selectedJSON.answer
                        this.issues = [];
                        // console.log(`No SubFAQs found for ${selectedQuestion}.`);
                    }
                    if(this.isTimer == true && (this.issues != null || this.isSolution == true)){
                        this.isSpinner = false;
                        if(this.issues != null){
                            // console.log('issue');
                            this.isIssue = true;
                        }
                        if(this.isSolution == true){
                            // console.log('solution');
                            this.isIssue = false;
                            this.hideChatBar = true;
                            this.isSol = true;
                            this.currentTime = ChatBot
                        .captureCurrentTime();
                            this.messages.push({text: this.solution, isSolution: true, time: this.currentTime});
                            storeMessages({msg: JSON.stringify(this.messages)})
                            .then((result)=>{
                                // console.log(result);
                            })
                        }
                    }
                }
                // console.log(result); // Will log 'success' after a random time
            });
            this.issues = null;
            this.currentTime = ChatBot
        .captureCurrentTime();
            this.messages.push({text: this.textValue, isAnswer: true, time: this.currentTime});
            storeMessages({msg: JSON.stringify(this.messages)})
            .then((result)=>{
                // console.log(result);
            });
            this.query = this.checkWord();
            // console.log();
            if(this.query === 'NORESULT' && this.isTimer == true){
                this.currentTime = ChatBot
            .captureCurrentTime();
                this.messages.push({text: 'Sorry, I couldn\'t understand that.', isQuestion: true, time: this.currentTime});
                this.isSpinner = false;
                storeMessages({msg: JSON.stringify(this.messages)})
                .then((result)=>{
                    // console.log(result);
                });
            }
            else if(this.query != null && this.isTimer == true){
                // console.log('checked keyword');
                // this.fetchingSubFAQS(key);
                this.question = 'Is this what you were looking for?';
                // console.log('skipped if');
                
                        // this.isTimer = true;
                        // console.log('Time completed');
                        // console.log(JSON.stringify(this.selectedJSON));
                        if (this.selectedJSON && this.selectedJSON.subQuestions && this.selectedJSON.subQuestions.length > 0) {
                            // console.log('INSIDE IF');
                            // console.log(this.selectedJSON);
                            this.issues = this.selectedJSON.subQuestions.map(item => item.question);
                            // console.log(JSON.stringify(this.issues));
                        } else if(this.selectedJSON && this.selectedJSON.answer) {
                            // console.log('inside else');
                            this.isSolution = true;
                            this.useful = true;
                            this.solution = this.selectedJSON.answer
                            this.issues = [];
                            // console.log(`No SubFAQs found for ${selectedQuestion}.`);
                        }
                        if(this.isTimer == true && (this.issues != null || this.isSolution == true)){
                            this.isSpinner = false;
                            if(this.issues != null){
                                // console.log('issue');
                                this.isIssue = true;
                            }
                            if(this.isSolution == true){
                                // console.log('solution');
                                this.isIssue = false;
                                this.isSol = true;
                                this.hideChatBar = true;
                                this.currentTime = ChatBot
                            .captureCurrentTime();
                                this.messages.push({text: this.solution, isSolution: true, time: this.currentTime});
                                storeMessages({msg: JSON.stringify(this.messages)})
                                .then((result)=>{
                                    // console.log(result);
                                })
                            }
                        }
            }
        }   
    }

    handleRemoveFile(event) {
        // console.log('removing');
        const fileId = event.target.dataset.id;
        this.uploadedFiles = this.uploadedFiles.filter(file => file.id !== parseInt(fileId, 10));
    }

    toggleitem(event){
        const images = this.template.querySelectorAll('.stars img');
        images.forEach(img => {
            img.style.filter = 'grayscale(1)';
        });

        

        const clickedImage = event.target;
        // console.log(clickedImage)
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
        this.mailSent = false;
        const windowsize = this.template.querySelector('.popupopen');
        const windowmessage = this.template.querySelector('.message');
        windowsize.style.height = '500px';
        windowmessage.style.height = '500px';
        windowmessage.style.maxHeight = '500px';
    }

}