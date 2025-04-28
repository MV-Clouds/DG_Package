import { LightningElement , api, track} from 'lwc';
import Popupimg from "@salesforce/resourceUrl/popupImage";
import { NavigationMixin } from 'lightning/navigation';
import isOrgWide from '@salesforce/apex/GoogleDriveAuthorizationController.isOrgWide';
import {errorDebugger} from 'c/globalPropertiesV2';

export default class integrationPopupV2 extends NavigationMixin(LightningElement) {

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
    @track redirectUrl;
    @track isDropbox = false;
    @track isGoogleDrive = false;
    @track isOneDrive = false;
    @track isAws = false;
    @track isNamedCredential = false;
    @track authorizationCode = '';
    @track isRedirectUri = false;
    @track redirectText = '';
    @track showModelTrack = this.showModel;
    
    isImageLoaded;
    isDataInvalid = false;

    connectedCallback(){
        this.redirectUrl = this.redirecturi;
        this.showModelTrack = true;
        this.showSpinner = true;
        this.isImageLoaded = false;
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
    }

    checkBtn(){
        if(this.isAws && this.bucket != '' && this.clientId != '' && this.clientSecret != '' && this.nickname != '' && !this.isNamedCredential){
            const authBtn = this.template.querySelector('.save-btn');
            authBtn.style.background = '#00AEFF';
            authBtn.disabled = false;
        }
        else if(this.isAws && this.isNamedCredential && this.namedCredential != ''){
            const authBtn = this.template.querySelector('.save-btn');
            authBtn.style.background = '#00AEFF';
            authBtn.removeAttribute('disabled');
        }
        else if(this.isGoogleDrive && this.authorizationCode != ''){
            const authBtn = this.template.querySelector('.save-btn');
            authBtn.style.background = '#00AEFF';
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
        const copyIconContainer = this.template.querySelector('.icon-copy');
        copyIconContainer.classList.add('show-copied');
        copyIconContainer.addEventListener('animationend', () => {
            copyIconContainer.classList.remove('show-copied');
        });
        this.isSpinner = true;
        var copyText = this.template.querySelector(".copy");
        copyText.select();
        copyText.setSelectionRange(0, 99999); // For mobile devices
        navigator.clipboard.writeText(copyText.value);
        copyText.setSelectionRange(0, 0); // For mobile devices
        this.isSpinner = false;
    }

    imageLoaded(){
        this.isImageLoaded = true;
        const onimgload = new CustomEvent('onimgload');
        if(typeof window !== 'undefined'){
            this.dispatchEvent(onimgload);
        }
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
        this.checkBtn();
    }

    toggleNamedCredential(){
        this.clientId = '';
        this.clientSecret = '';
        this.bucket = '';
        this.nickname = '';
        this.namedCredential = '';
        this.isNamedCredential = !this.isNamedCredential;       
        const authBtn = this.template.querySelector('.save-btn');
        authBtn.style.background = '';
        authBtn.disabled = true;
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
        this.checkBtn();

    }

    handleGenAuthCode(){
        try{
            const onauthcode = new CustomEvent('authcode');
            if(typeof window !== 'undefined'){
                this.dispatchEvent(onauthcode);
            }
        }
        catch (error){
            errorDebugger('IntegrationPopupV2', 'handleGenAuthCode', error, 'warn');
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
        this.checkBtn();
    }

    authorize(){
        if(!this.isGoogleDrive && !this.isNamedCredential){
        this.template.querySelector('.t-clientid').classList.remove("error-border");
        this.template.querySelectorAll('label')[1].classList.remove("error-label");
        this.template.querySelector('.t-clientsecret').classList.remove("error-border");
        this.template.querySelectorAll('label')[2].classList.remove("error-label");
        }
        if(this.isAws && !this.isNamedCredential){
        this.template.querySelector('.t-name').classList.remove("error-border");
        this.template.querySelectorAll('label')[3].classList.remove("error-label");
        this.template.querySelector('.t-bucket').classList.remove("error-border");
        this.template.querySelectorAll('label')[4].classList.remove("error-label");
        }
        if(this.isGoogleDrive){
            this.template.querySelector('.t-authorizationcode').classList.remove("error-border");
            this.template.querySelectorAll('label')[0].classList.remove("error-label");
        }
        this.isDataInvalid = false;
        if (!this.clientId && !this.isGoogleDrive && !this.isNamedCredential) {
            this.template.querySelector('.t-clientid').classList.add("error-border");
            this.template.querySelectorAll('label')[1].classList.add("error-label");
            this.isDataInvalid = true;
        }
        if (!this.clientSecret && !this.isGoogleDrive && !this.isNamedCredential) {
            this.template.querySelector('.t-clientsecret').classList.add("error-border");
            this.template.querySelectorAll('label')[2].classList.add("error-label");
            this.isDataInvalid = true;
        }
        if (!this.bucket && this.isAws == true && !this.isNamedCredential) {
            this.template.querySelector('.t-bucket').classList.add("error-border");
            this.template.querySelectorAll('label')[4].classList.add("error-label");
            this.isDataInvalid = true;
        }
        if (!this.nickname && this.isAws == true && !this.isNamedCredential ) {
            this.template.querySelector('.t-name').classList.add("error-border");
            this.template.querySelectorAll('label')[3].classList.add("error-label");
            this.isDataInvalid = true;
        }
        if (!this.authorizationCode && this.isGoogleDrive){
            this.template.querySelector('.t-authorizationcode').classList.add("error-border");
            this.template.querySelectorAll('label')[0].classList.add("error-label");
            this.isDataInvalid = true;
        }
        if(!this.isDataInvalid){
            try{
            if(typeof window !== 'undefined'){
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
            }
            catch(error){
                errorDebugger('chatBotV2', 'submitFeedback', error, 'warn');
            }
            this.bucket = null;
            this.clientId = null;
            this.clientSecret = null;
            this.redirectUrl = null;
            this.nickname = null;
            this.authorizationCode = null;
        }
    }

    closeModel(){
        if(typeof window !== 'undefined'){
            const closeModalEvent = new CustomEvent('closemodal');
            this.bucket = null;
            this.clientId = null;
            this.clientSecret = null;
            this.redirectUrl = null;
            this.nickname = null;
            this.namedCredential = null
            this.dispatchEvent(closeModalEvent);
        }
    }

}