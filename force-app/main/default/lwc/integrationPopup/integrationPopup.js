import { LightningElement , api, track , wire} from 'lwc';
import Popupimg from "@salesforce/resourceUrl/popupImage";
import { NavigationMixin } from 'lightning/navigation';
import isOrgWide from '@salesforce/apex/GoogleDriveAuthorizationController.isOrgWide';
export default class integrationPopup extends NavigationMixin(LightningElement) {

    @track popupimg = Popupimg;
    @api showModel;
    @track showSpinner;
    
    @api draggedkey;
    @track clientId = '';
    @track clientSecret = '';
    @track bucket = '';
    @track nickname = '';
    @track namedCredential = '';
    @track isOrg = false;
    @api redirecturi; 
    @track isDropbox = false;
    @track isGoogleDrive = false;
    @track isOneDrive = false;
    @track isAws = false;
    @track isNamedCredential = false;
    @track authorizationCode = '';
    @track isRedirectUri = false;
    @track redirectText = '';
    
    isImageLoaded;
    isDataInvalid = false;

    connectedCallback(){
        this.showModel = true;
        this.showSpinner = true;
        this.isImageLoaded = false;
        // console.log(this.redirecturi);
        // console.log(this.draggedkey);
        if(this.draggedkey == 'dropbox'){
            this.isDropbox = true;
            this.isRedirectUri = true;
            this.redirectText = 'Paste this in your Dropbox developer console\'s redirect uri section. For more details refer User Guide.';
        }
        else if(this.draggedkey == 'onedrive'){
            this.isOneDrive = true;
            this.isRedirectUri = true;
            this.redirectText = 'Paste this in your Azure developer console\'s redirect uri section. For more details refer User Guide.';
        }
        else if(this.draggedkey == 'aws'){
            this.isAws = true;
        }
        else if(this.draggedkey == 'google'){
            this.isGoogleDrive = true;
            this.checkOrgWide();
            
        }
    }

    checkOrgWide(){
        isOrgWide()
        .then((result) =>{
            if(result == true){
                const toggleOrg = this.template.querySelector('.googleOrg');
                toggleOrg.disabled = true;
                toggleOrg.title = 'Org wide already exist';
            }
        });
    }


    toggleIsOrg(){
        this.isOrg = !this.isOrg;
        // console.log(this.isOrg); 
    }

    checkBtn(){
        debugger
        if(this.isAws && this.bucket != '' && this.clientId != '' && this.clientSecret != '' && this.nickname != '' && !this.isNamedCredential){
            const authBtn = this.template.querySelector('.save-btn');
            authBtn.style.background = '#00AEFF';
            authBtn.disabled = false;
        }
        else if(this.isAws && this.isNamedCredential && this.namedCredential != ''){
            const authBtn = this.template.querySelector('.save-btn');
            authBtn.style.background = '#00AEFF';
            // console.log(this.authorizationCode);
            authBtn.removeAttribute('disabled');
        }
        else if(this.isGoogleDrive && this.authorizationCode != ''){
            const authBtn = this.template.querySelector('.save-btn');
            authBtn.style.background = '#00AEFF';
            // console.log(this.authorizationCode);
            authBtn.removeAttribute('disabled');
        }
        else if(this.isOneDrive && this.clientId != '' && this.clientSecret != ''){
            const authBtn = this.template.querySelector('.save-btn');
            authBtn.style.background = '#00AEFF';
            authBtn.disabled = false;
        }
        else if(this.isDropbox && this.clientId != '' && this.clientSecret != ''){
            const authBtn = this.template.querySelector('.save-btn');
            authBtn.style.background = '#00AEFF';
            authBtn.removeAttribute('disabled');
        }
        else {
            const authBtn = this.template.querySelector('.save-btn');
            authBtn.style.background = '';
            authBtn.disabled = true;
        }
    }

    copyToClipboard() {
        this.isSpinner = true;
        // console.log('Invoked clipboard');
        var copyText = this.template.querySelector(".copy");
        // console.log(copyText);
        copyText.select();
        copyText.setSelectionRange(0, 99999); // For mobile devices
        navigator.clipboard.writeText(copyText.value);
        copyText.setSelectionRange(0, 0); // For mobile devices
        this.isSpinner = false;
    }

    imageLoaded(){
        this.isImageLoaded = true;
        // console.log('image is loaded');
        const onimgload = new CustomEvent('onimgload');
        this.dispatchEvent(onimgload);
    }

    get doShowSpinner(){
        if(this.isImageLoaded == true){
            return false;
        }
        return true;
    }
    handleNickname(event){
        this.isDataInvalid = false;
        this.template.querySelector('.t-name').classList.remove("error-border");
        this.template.querySelectorAll('label')[3].classList.remove("error-label");
        this.nickname = event.target.value.trim();
        if (!this.nickname) {
            this.template.querySelector('.t-name').classList.add("error-border");
            this.template.querySelectorAll('label')[3].classList.add("error-label");
            this.isDataInvalid = true;
        }
        // console.log(this.nickname);
        this.checkBtn();
    }

    handleNamedCredentials(event){
        this.isDataInvalid = false;
        this.template.querySelector('.t-named').classList.remove("error-border");
        this.template.querySelectorAll('label')[1].classList.remove("error-label");
        this.namedCredential = event.target.value.trim();
        if (!this.namedCredential) {
            this.template.querySelector('.t-named').classList.add("error-border");
            this.template.querySelectorAll('label')[1].classList.add("error-label");
            this.isDataInvalid = true;
        }
        // console.log(this.namedCredential);
        this.checkBtn();
    }

    handleClientId(event) {
        this.isDataInvalid = false;
        this.template.querySelector('.t-clientid').classList.remove("error-border");
        this.template.querySelectorAll('label')[1].classList.remove("error-label");
        this.clientId = event.target.value.trim();
        if (!this.clientId) {
            this.template.querySelector('.t-clientid').classList.add("error-border");
            this.template.querySelectorAll('label')[1].classList.add("error-label");
            this.isDataInvalid = true;
        }
        // console.log(this.clientId);
        this.checkBtn();
    }

    toggleNamedCredential(event){
        this.clientId = '';
        this.clientSecret = '';
        this.bucket = '';
        this.nickname = '';
        this.namedCredential = '';
        this.isNamedCredential = !this.isNamedCredential;
        if(this.isNamedCredential){
            this.handleNamedCredentials();
        }
        else{
            this.handleClientId();
            this.handleClientSecret();
            this.handleNickname();
            this.handleBucket();
        }
        
        // console.log(this.isNamedCredential);        
    }

    handleClientSecret(event) {
        this.isDataInvalid = false;
        this.template.querySelector('.t-clientsecret').classList.remove("error-border");
        this.template.querySelectorAll('label')[2].classList.remove("error-label");
        this.clientSecret = event.target.value.trim();
        if (!this.clientSecret) {
            this.template.querySelector('.t-clientsecret').classList.add("error-border");
            this.template.querySelectorAll('label')[2].classList.add("error-label");
            this.isDataInvalid = true;
        }
        // console.log(this.clientSecret);
        this.checkBtn();

    }

    handleBucket(event){
        this.isDataInvalid = false;
        this.template.querySelector('.t-bucket').classList.remove("error-border");
        this.template.querySelectorAll('label')[4].classList.remove("error-label");
        this.bucket = event.target.value.trim();
        if (!this.bucket) {
            this.template.querySelector('.t-bucket').classList.add("error-border");
            this.template.querySelectorAll('label')[4].classList.add("error-label");
            this.isDataInvalid = true;
        }
        // console.log(this.bucket);
        this.checkBtn();

    }

    handleGenAuthCode(event){
        try{
        const onauthcode = new CustomEvent('authcode');
        // console.log('going for auth code');
        this.dispatchEvent(onauthcode);
        // console.log('success');
        }
        catch (error){
            // console.error(error);
        }
    }

    handleAuthorizationCode(event) {
        this.isDataInvalid = false;
        this.template.querySelector('.t-authorizationcode').classList.remove("error-border");
        this.template.querySelectorAll('label')[0].classList.remove("error-label");
        this.authorizationCode = event.target.value.trim();
        if (!this.authorizationCode) {
            this.template.querySelector('.t-authorizationcode').classList.add("error-border");
            this.template.querySelectorAll('label')[0].classList.add("error-label");
            this.isDataInvalid = true;
        }
        // console.log(this.clientId);
        this.checkBtn();
    }

    authorize(){
        // console.log('inside authorize');
        if(!this.isGoogleDrive && !this.isNamedCredential){
            // console.log('-2');
        this.template.querySelector('.t-clientid').classList.remove("error-border");
        this.template.querySelectorAll('label')[1].classList.remove("error-label");
        this.template.querySelector('.t-clientsecret').classList.remove("error-border");
        this.template.querySelectorAll('label')[2].classList.remove("error-label");
        }
        if(this.isAws && !this.isNamedCredential){
        // console.log('-1');
        this.template.querySelector('.t-name').classList.remove("error-border");
        this.template.querySelectorAll('label')[3].classList.remove("error-label");
        this.template.querySelector('.t-bucket').classList.remove("error-border");
        this.template.querySelectorAll('label')[4].classList.remove("error-label");
        }
        if(this.isGoogleDrive){
            // console.log('0');
            this.template.querySelector('.t-authorizationcode').classList.remove("error-border");
            this.template.querySelectorAll('label')[0].classList.remove("error-label");
        }
        this.isDataInvalid = false;
        // console.log('child0');
        if (!this.clientId && !this.isGoogleDrive && !this.isNamedCredential) {
            // console.log('1');
            this.template.querySelector('.t-clientid').classList.add("error-border");
            this.template.querySelectorAll('label')[1].classList.add("error-label");
            this.isDataInvalid = true;
        }
        if (!this.clientSecret && !this.isGoogleDrive && !this.isNamedCredential) {
            // console.log('2');
            this.template.querySelector('.t-clientsecret').classList.add("error-border");
            this.template.querySelectorAll('label')[2].classList.add("error-label");
            this.isDataInvalid = true;
        }
        if (!this.bucket && this.isAws == true && !this.isNamedCredential) {
            // console.log('3');
            this.template.querySelector('.t-bucket').classList.add("error-border");
            this.template.querySelectorAll('label')[4].classList.add("error-label");
            this.isDataInvalid = true;
        }
        if (!this.nickname && this.isAws == true && !this.isNamedCredential ) {
            // console.log('4');
            this.template.querySelector('.t-name').classList.add("error-border");
            this.template.querySelectorAll('label')[3].classList.add("error-label");
            this.isDataInvalid = true;
        }
        if (!this.authorizationCode && this.isGoogleDrive){
            // console.log('5');
            this.template.querySelector('.t-authorizationcode').classList.add("error-border");
            this.template.querySelectorAll('label')[0].classList.add("error-label");
            this.isDataInvalid = true;
        }
        if(!this.isDataInvalid){
            // console.log('child1');
            try{
                // console.log('dispatching data');
            this.dispatchEvent(new CustomEvent('authorize', {
                detail: {
                    clientId: this.clientId,
                    clientSecret: this.clientSecret,
                    bucket: this.bucket,
                    nickname: this.nickname,
                    draggedkey: this.draggedkey,
                    named: this.namedCredential,
                    isOrg: this.isOrg,
                    authcode: this.authorizationCode
                }
            }));
            }
            catch(error){
                // console.log('Eroor'+error);
            }
            // console.log('child2');
            this.bucket = null;
            this.clientId = null;
            this.clientSecret = null;
            this.redirecturi = null;
            this.nickname = null;
            this.authorizationCode = null;
        }
    }

    closeModel(){
        const closeModalEvent = new CustomEvent('closemodal');
        this.bucket = null;
        this.clientId = null;
        this.clientSecret = null;
        this.redirecturi = null;
        this.nickname = null;
        this.namedCredential = null
        this.dispatchEvent(closeModalEvent);
    }

}