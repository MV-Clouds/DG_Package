import { LightningElement, track, wire } from 'lwc';

import homePageImgs from '@salesforce/resourceUrl/homePageImgs';
import DocGeniusLogo from "@salesforce/resourceUrl/docGeniusLogoSvg";
import integrationImages from "@salesforce/resourceUrl/integrationImages";
import Dropablearea from "@salesforce/resourceUrl/dropAreaBackground";
import authorizeGoogle from "@salesforce/apex/GoogleDriveAuthorizationController.authorizeGoogle";
import getAuthCode from "@salesforce/apex/GoogleDriveAuthorizationController.getAuthCode";
import dropboxRedirect from "@salesforce/apex/DropBoxAuthorizationController.redirectUrl";
import onedriveRedirect from "@salesforce/apex/OneDriveAuthorizationController.redirectUrl";
import Popupimg from "@salesforce/resourceUrl/popupImage";
import checkgoogleauth from "@salesforce/apex/GoogleDriveAuthorizationController.checkgoogleauth";
import checkorggoogleauth from "@salesforce/apex/GoogleDriveAuthorizationController.checkorggoogleauth";
import checkawsauth from "@salesforce/apex/AwsAuthorizationController.checkawsauth"
import checkOneDriveAuth from "@salesforce/apex/OneDriveAuthorizationController.checkonedriveauth";
import checkDropBoxAuth from "@salesforce/apex/DropBoxAuthorizationController.checkdropboxauth";
import unauth from "@salesforce/apex/GoogleDriveAuthorizationController.unauthorize";
import orgunauth from "@salesforce/apex/GoogleDriveAuthorizationController.orgunauthorize";
import awsunauth from "@salesforce/apex/AwsAuthorizationController.unauthorize";
import onedriveunauth from "@salesforce/apex/OneDriveAuthorizationController.unauthorize";
import dropboxunauth from "@salesforce/apex/DropBoxAuthorizationController.unauthorize";
import noconnection from "@salesforce/resourceUrl/noconnection";
import awsAuthorization from "@salesforce/apex/AwsAuthorizationController.authorize";
import oneDriveAuthorization from "@salesforce/apex/OneDriveAuthorizationController.authorize";
import authorizeNamed from "@salesforce/apex/AwsAuthorizationController.authorizeNamed";
import dropboxAuthorization from "@salesforce/apex/DropBoxAuthorizationController.authorize";
import checkAccess from '@salesforce/apex/GoogleDriveAuthorizationController.checkAccess';
import getAccessToken from '@salesforce/apex/GenerateDocumentController.getAccessToken';
import getAuthProviderSettings from '@salesforce/apex/GenerateDocumentController.getAuthProviderSettings';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
// for trusted Url Verification
import checkTrustedUrl from '@salesforce/apex/HomePageController.checkTrustedUrl';
import {errorDebugger} from 'c/globalProperties';


export default class IntegrationDashborad extends NavigationMixin(LightningElement) {

   bgimg;
   logo;
   dropable;
   popupimg;
   nointegration = noconnection;
   consumerKey = '';
    consumerSecret = '';
    isDataInvalid = false;
    secretValue;
    keyValue;
    inputDisable;
    changeType = 'text';
    showNotes = false;
   @track restApiTrustedUrl;
   @track isTrustedUrlVerified = false;
   @track isAccessTokenVerified = false;
   @track onInit = true;
   @track isVerifying = false;
   @track isVerifyAccessToken = false;
   @track clipBoardTooltip = 'Copy to Clipboard';

   @track loadedResources = 0;
   @track ispopup = false;
   @track isAws = false;
   @track isGoogle = false;
   // @track isOrgGoogle = false;
   @track isDropBox = false;
   @track isOneDrive = false;
   @track draggedkey;
   @track namedCredential;
   @track isOrg;
   @track authcode;
   @track clientId;
   @track clientSecret;
   @track email;
   @track bucket;
   @track nickname;
   @track redirectUri;
   @track activeTab = 'isIntegration';
   isIntegration = false;
   isLimitations = false;
   isUserguide = false;
   isSetup = false;
   //used for displaying orggoogledate
   @track orggooglename;
   @track orggooglelinkdate;
   @track orggoogleemail;
   //to display status bar
   @track isActiveOrgGoogleAuth ;
   @track isActiveGoogleAuth ;
   @track isActiveDropboxAuth ;
   @track isActiveOnedriveAuth ;
   @track isActiveAwsAuth ;
   //used for active and inactive
   @track isWorkingOrgGoogleAuth = false;
   @track isWorkingGoogleAuth = false;
   @track isWorkingDropboxAuth = false;
   @track isWorkingOnedriveAuth = false;
    @track isWorkingAwsAuth = false;
    @track checkAccessToken = false;
    
   //usedfordisplayinggoogledata
   @track googlename;
   @track googlelinkdate;
   @track googleemail;
   //usedfordisplayingawsdata
   @track awslinkdate;
   @track awsbucket;
   @track awsNickname;
   @track awsuserdata=false;
   //usedfordisplayingonedrivedata
   @track onedrivename;
   @track onedriveemail;
   @track onedrivelinkdate;
   //usedfordisplayingdropboxdata
   @track dropboxname;
   @track dropboxemail;
   @track dropboxlinkdate;
   @track isSpinner = true;
   @track invoke; //used to track who called the popup

   @track isAccess = false;
   @track isPartialAccess;
   @track obj = {
        'googleKey' : false,
        'oneDriveKey' : false,
        'dropboxKey' : false,
        'awsKey' :false
   }


   get googledrive_(){
       return integrationImages + '/googleDrive.png';
   }

   get onedrive_(){
       return integrationImages + '/oneDrive.png';
   }

   get dropbox_(){
       return integrationImages + '/dropbox.png';
   }

   get aws_(){
       return integrationImages + '/aws.png';
   }
  
   get googledrive_user(){
       return integrationImages + '/googleDriveUser.png';
   }
  
   get googledrive_org(){
       return integrationImages + '/googleDriveOrg.png';
   }
   get allowGoogle() {
    return this.isAccess && !this.isActiveGoogleAuth;
   }
   get allowDropbox() {
    return this.isAccess && !this.isActiveDropboxAuth;
   }
   get allowOneDrive() {
    return this.isAccess && !this.isActiveOnedriveAuth;
   }
   get allowAws() {
    return this.isAccess && !this.isActiveAwsAuth;
   }


   @wire(CurrentPageReference)
   currentPageReference;
  
   connectedCallback() {
        if (this.currentPageReference.state && this.currentPageReference.state.fragment) {
            this[this.currentPageReference.state.fragment] = true;
            this.activeTab = this.currentPageReference.state.fragment;
            this.isSpinner = false;
            if (!['isSetup', 'isIntegration', 'isLimitations', 'isUserguide'].includes(this.activeTab)) {
                this.activeTab = 'isIntegration';
                this.isIntegration = true;
            }
        } else {
            this.isIntegration = true;
        }
       this.bgimg = homePageImgs + '/HomBg.png';
       this.logo = DocGeniusLogo;
       this.dropable = Dropablearea;
       this.popupimg = Popupimg;
       this.getTrustedUrlStatus();
       this.checkauth();
       this.checkAccess();
       this.checkAuthProviderSettings();
       if(typeof window !== 'undefined'){
            this.restApiTrustedUrl = location?.origin?.replace('lightning.force.com', 'my.salesforce.com');
       }else{
        this.restApiTrustedUrl = '[instance].my.salesforce.com';
       }
   }

    checkAuthProviderSettings() {
    getAuthProviderSettings({isUpdateSetting : true})
        .then(result => {
            if (result && result.length > 0 && result[0].MVDG__Client_Id__c && result[0].MVDG__Client_Secret__c) {
                this.keyValue = result[0].MVDG__Client_Id__c;
                this.secretValue = result[0].MVDG__Client_Secret__c;
                if (this.keyValue && this.secretValue) {
                    this.consumerKey = this.keyValue;
                    this.consumerSecret = this.secretValue;
                    this.inputDisable = true;
                    this.showNotes = false;
                    this.verifyAccessToken(true,false);
                }
            } else {
                this.consumerKey = '';
                this.consumerSecret = '';
                this.keyValue = '';
                this.secretValue = '';   
            }
        })
        .catch(error => {
            this.showNotes = true;
            this.consumerKey = '';
            this.consumerSecret = '';
            this.keyValue = '';
            this.secretValue = ''; 
        });
    }
    
     handleConsumerKeyChange(event) {
            try {
                this.isDataInvalid = false;
                this.template.querySelector('.t-key').classList.remove('error-border');
                this.template.querySelectorAll('label')[0].classList.remove('error-label');
                this.consumerKey = event.target.value.trim();
                if (!this.consumerKey) {
                    this.template.querySelector('.t-key').classList.add('error-border');
                    this.template.querySelectorAll('label')[0].classList.add('error-label');
                    this.isDataInvalid = true;
                }
            } catch (e) {
                errorDebugger('IntegrationDashborad', 'handleConsumerKeyChange', e, 'warn');
            }
        }
    
        handleConsumerSecretChange(event) {
            try {
                this.isDataInvalid = false;
                this.template.querySelector('.t-secret').classList.remove('error-border');
                this.template.querySelectorAll('label')[1].classList.remove('error-label');  
                this.consumerSecret = event.target.value.trim();
                if (!this.consumerSecret) {
                    this.template.querySelector('.t-secret').classList.add('error-border');
                    this.template.querySelectorAll('label')[1].classList.add('error-label'); 
                    this.isDataInvalid = true;
                }
            } catch (e) {
                errorDebugger('IntegrationDashborad', 'handleConsumerSecretChange', e, 'warn');
            }
        }
        
        onVerifyClickButton(){
            this.verifyAccessToken(false,true);
        }

    verifyAccessToken(initialLoad,isShowToast) {
            if (this.consumerKey === '' || this.consumerSecret === '') {
                this.isDataInvalid = true;
                this.template.querySelector('.t-key').classList.add('error-border');
                this.template.querySelectorAll('label')[0].classList.add('error-label');
                this.template.querySelector('.t-secret').classList.add('error-border');
                this.template.querySelectorAll('label')[1].classList.add('error-label');  
                this.showToast('error', 'Required field are missing!','Consumer key and secret are required!');
            } else {
                this.isVerifyAccessToken = true;
                getAccessToken({ clientId: this.consumerKey, clientSecret: this.consumerSecret, isUpdateSetting: true })
                    .then(result => {
                        if (result != null) {
                            this.changeType = 'password';
                            this.keyValue = this.consumerKey;
                            this.secretValue = this.consumerSecret;
                            this.inputDisable = true;
                            this.showNotes = false;
                            this.isVerifyAccessToken = false;
                            this.isAccessTokenVerified = true;
                        } else {
                            this.isVerifyAccessToken = false;
                            this.isAccessTokenVerified = false;
                            this.consumerKey = '';
                            this.consumerSecret = '';
                            this.keyValue = '';
                            this.secretValue = ''; 
                            this.inputDisable = false;
                            this.isDataInvalid = true;
                            if (isShowToast) {
                                if (initialLoad) {
                                    this.showNotes = true;
                                }
                                this.showToast('error', 'Missed a Step?','Failed to Configure Connected App, Check your credentials.');
                            } else {
                                this.showNotes = true;
                            }
                        }
              })
                    .catch(e => {
                        errorDebugger('IntegrationDashborad', 'verifyAccessToken', e, 'warn');
                    });
            }
    }
    
    getTrustedUrlStatus(event){
        this.isVerifying = true;
        try {
            checkTrustedUrl()
            .then((result) => {
                this.isTrustedUrlVerified = result ? result : false;
                this.template.host.style.setProperty('--height-for-create-button-div', this.isTrustedUrlVerified ? '100%' : '0%');
                this.template.host.style.setProperty('--visibility-for-create-button-div', this.isTrustedUrlVerified ? 'Visible' : 'Collapse');
                this.isVerifying = false;
                if(!this.isTrustedUrlVerified && event){
                    this.showToast('error', 'Missed a Step?','Please follow all the steps correctly!');
                }
            })
            .catch((e) => {
                errorDebugger('IntegrationDashborad', 'getTrustedUrlStatus > checkTrustedUrl > failure', e, 'warn');
                this.isVerifying = false;
                
            })
        } catch (e) {
            errorDebugger('IntegrationDashborad', 'getTrustedUrlStatus', e, 'warn');
            this.isVerifying = false;
        }
    }

    showToast(status, title, message){
        this.isSpinner = false;
        const messageContainer = this.template.querySelector('c-message-popup')
        messageContainer.showMessageToast({
            status: status,
            title: title,
            message : message,
            duration : 5000
        });
    }

    handleCopyTrustedUrl(){
        try {
            navigator.clipboard.writeText(this.restApiTrustedUrl);
            this.clipBoardTooltip = 'Copied!';
        } catch (e) {
            errorDebugger('IntegrationDashborad', 'handleCopyTrustedUrl', e, 'warn');
        }
    }

    updateCopyTooltip(){
        this.clipBoardTooltip = 'Copy to Clipboard';
    }

    closeAccessTokenScreen() {
        this.checkAccessToken = !this.checkAccessToken;
    }

   checkAccess(){
    try {
        
        checkAccess()
        .then((result) =>{
             if(result == 'DocGenius_Admin_Permissions'){
                 this.isAccess = true;

             }
             else if(result == 'DocGenius_Standard_Permissions'){
                 this.isPartialAccess = true;
                 const dgSetup = this.template.querySelector('.text0');
                 if(dgSetup) dgSetup.style.display = 'none';

                 this.obj.oneDriveKey = false;
                 this.obj.awsKey = false;
                 this.obj.dropboxKey = false;
             }
             else{
                const dgSetup = this.template.querySelector('.text0');
                if(dgSetup) dgSetup.style.display = 'none';

                this.obj.googleKey = false;
                this.obj.oneDriveKey = false;
                this.obj.awsKey = false;
                this.obj.dropboxKey = false;
             }
             if (this.activeTab == 'isSetup' && !this.isAccess) {
                const messageContainer = this.template.querySelector('c-message-popup')
                messageContainer.showMessageToast({
                    status: 'error',
                    title: 'error',
                    message : 'Error you don\'t have access to DG Setup',
                });
                let activeEl = this.template.querySelector(`[data-name="isIntegration"]`);
                if (activeEl) {
                    activeEl.classList.add('enable');
                }
                this.handleSetActive({currentTarget: {dataset: {name: 'isIntegration'}}})
            }
 
        });
    } catch (error) {
        errorDebugger('IntegrationDashborad', 'checkAccess > checkAccess > failure', error, 'warn');
    }
   }

   checkauth(){
       this.checkingorggoogleauth();
       this.checkinggoogleauth();
       this.checkingawsauth();
       this.checkingonedriveauth();
       this.checkingdropboxauth();
   }

   toggleGreenColor(){
       this.isGreen = !this.isGreen;
   }

   toggleRedColor(){
       this.isRed = !this.isRed;
   }

   get boxStyle() {
       return `background-color: ${this.isGreen ? this.greenColor : this.lightGreenColor}`;
   }

   get redBoxStyle() {
       return `background-color: ${this.isRed ? this.redColor : this.lightRedColor}`;
   }


   renderedCallback() {
       if(this.awsuserdata){
               if (this.template.querySelector('.hide-bucket') && this.awsbucket == 'Unknown') { // Check if all filters are rendered
                   const awsbucket = this.template.querySelector('.hide-bucket');
                   if(awsbucket) awsbucket.style.display = 'none';
               }
               this.awsuserdata = false;
           }

        if(!this.isAccess && this.activeTab == 'isIntegration'){
            if(this.isPartialAccess){
                const unlink = this.template.querySelectorAll('.partial-btn');
                unlink?.forEach(ele => {
                    ele.disabled = true;
                })
            }
            else{
                const unlink = this.template.querySelectorAll('.unauthorize');
                unlink?.forEach(ele => {
                    ele.disabled = true;
                })
                const card = this.template.querySelectorAll('.card');
                card?.forEach(ele => {
                    ele.removeAttribute('draggable');
                })
            }
        }
        let activeEl = this.template.querySelector(`[data-name="${this.activeTab}"]`);
        if (activeEl && this.onInit) {
            activeEl.classList.add('enable');
            this.onInit = false;

        }
   }

   checkinggoogleauth(){
       checkgoogleauth()
       .then(result =>{
           this.displaydetails(result, 'google');
           this.loaded();
       })
   }

   checkingorggoogleauth(){
       checkorggoogleauth()
       .then(result =>{
           this.displaydetails(result, 'orggoogle');
           this.loaded();
       })
   }

   loaded(){
       this.loadedResources++;
       if(this.loadedResources >= 8 || this.activeTab!='isIntegration'){
           this.isSpinner = false;
       }
   }


   checkingawsauth(){
       checkawsauth()
       .then(result =>{
           if(result!= null && result.bucket != null  && result.linkdate != null && result.name !=null){
             
               this.awsNickname = result.name;
               this.awsbucket = result.bucket;
               this.isWorkingAwsAuth = result.active;
               this.awslinkdate = result.linkdate;
               this.awsuserdata = true;
               this.obj.awsKey = false;
               this.isActiveAwsAuth = true;
           }
           else{
            if(!this.isPartialAccess){
                this.isActiveAwsAuth = false;
                this.obj.awsKey = true;
                const awsintegrationhover = this.template.querySelector('.ac');
                if(awsintegrationhover) awsintegrationhover.style.pointerEvents = "auto";
            }
           }
           this.loaded();
       })
   }

  
   checkingonedriveauth(){
       checkOneDriveAuth()
       .then(result =>{
           this.displaydetails(result, 'onedrive')
           this.loaded();
       })
   }

   checkingdropboxauth(){
       checkDropBoxAuth()
       .then(result =>{
           this.displaydetails(result, 'dropbox')
           this.loaded();
       })
   }

   displaydetails(result, integrationname){
       if(result != null && result.linkdate != null && result.email != null) {
           if(result.name != null && result.name != ''){
               this[integrationname + 'name'] = result.name;
           }
           else{
               this[integrationname + 'name'] = 'No username';
           }
               this[integrationname + 'email'] = result.email;
           if(integrationname == 'dropbox'){
               this.isWorkingDropboxAuth = result.active;
               this.isActiveDropboxAuth = true;
               this.obj.dropboxKey = false;
           }
           else if(integrationname == 'onedrive'){
               this.isWorkingOnedriveAuth = result.active;
               this.isActiveOnedriveAuth = true;
               this.obj.oneDriveKey = false;

           }
           else if(integrationname == 'google'){
               this.isWorkingGoogleAuth = result.active;
               this.isActiveGoogleAuth = true;
               this.obj.googleKey = false;

           }
           else if(integrationname == 'orggoogle'){
               this.isWorkingOrgGoogleAuth = result.active;
               this.isActiveOrgGoogleAuth = true;
           }
           this[integrationname + 'linkdate'] = result.linkdate;
       }
       else{
            if(integrationname == 'google'){
                this.isActiveGoogleAuth = false;
                this.obj.googleKey = true;
            }
            if(!this.isPartialAccess){
                if(integrationname == 'dropbox'){
                    this.isActiveDropboxAuth = false;
                    this.obj.dropboxKey = true;
                }
                else if(integrationname == 'onedrive'){
                    this.isActiveOnedriveAuth = false;
                    this.obj.oneDriveKey = true;
                } 
            }
       }
   }




   fetchdropboxredirecturi(){
       dropboxRedirect()
       .then(result =>{
           this.redirectUri = result;
           this.ispopup = true;
       });
   }

   fetchonedriveredirecturi(){
       onedriveRedirect()
       .then(result =>{
           this.redirectUri = result;
           this.ispopup = true;
       });
   }
  


   handleDragStart(event){
       const key = event.target.dataset.key;
       event.dataTransfer.setData('key', key);
       this.template.querySelector('.dragbackground').style.opacity = '0.5';
       this.template.querySelector('.dropandstatus').style.opacity = '0.5';

   }

   handleDragOver(event){
       event.preventDefault();
   }

   handleNickname(event){
       this.nickname = event.target.value.trim();
   }


   handledDrop(event){
       if(this.isAccess){
           this.template.querySelector('.dragbackground').style.opacity = '1';
           this.draggedkey = event.dataTransfer.getData('key');
           this.isSpinner = true;
           if(this.draggedkey == 'aws'){
               this.isAws = true;
               this.ispopup = true;
           }
           else if(this.draggedkey == 'onedrive'){
               this.fetchonedriveredirecturi();
               this.isOneDrive = true;
              
           }
           else if(this.draggedkey == 'google'){
               // this.fetchgoogledredirecturi();
               this.clientId='google';
               this.clientSecret = 'google';
               this.isGoogle = true;
               this.ispopup = true;
           }
           else if(this.draggedkey == 'dropbox'){
               this.fetchdropboxredirecturi();
               this.isDropBox = true;
           }
           else{
               this.isSpinner = false;
               this.ispopup = false;
           }
       }
       else if(this.isPartialAccess){
        this.template.querySelector('.dragbackground').style.opacity = '1';
           this.draggedkey = event.dataTransfer.getData('key');
           this.isSpinner = true;
           if(this.draggedkey == 'google'){
            this.clientId='google';
            this.clientSecret = 'google';
            this.isGoogle = true;
            this.ispopup = true;
            }
            else{
                this.isSpinner = false;
            }
       }
   }


   closeSpinner(){
       this.isSpinner = false;
   }


   handleDragEnd(event) {
       event.preventDefault();
       this.template.querySelector('.dragbackground').style.opacity = '1';
       this.template.querySelector('.dropandstatus').style.opacity = '1';
   }


   handleClientId(event) {
       this.clientId = event.target.value.trim();
   }


   handleClientSecret(event) {
       this.clientSecret = event.target.value.trim();
   }


   handleBucket(event){
       this.bucket = event.target.value.trim();
   }


   handleSetActive(event){
       const tabName = event.currentTarget.dataset.name;
       if(this.activeTab == 'isSetup' && this.isAccess) this.getTrustedUrlStatus();
       if(this.activeTab != tabName){
           this.isSpinner = true;
           this.loadedResources = 0;
           this.activeTab = tabName;
           this.isIntegration = false;
           this.isSetup = false;
           this.isUserguide = false;
           this.isLimitations = false;
           const cursor = this.template.querySelectorAll('.cursor');
           cursor?.forEach(ele => {
                if(ele.dataset.name == tabName && tabName == 'isSetup' && !this.isAccess){
                    this.isSpinner = false;
                    const messageContainer = this.template.querySelector('c-message-popup')
                       messageContainer.showMessageToast({
                           status: 'error',
                           title: 'error',
                           message : 'Error you don\'t have access to DG Setup',
                       });
                }
               else if(ele.dataset.name == tabName){
                   ele.classList.add('enable');
                   this[tabName] = true;
                   this.isSpinner = false;
               }
               else{
                   ele.classList.remove('enable');
               }
           })
       }
   }

    handleIframeLoad(){
        this.isSpinner = false;
    }

   copyToClipboard() {
       this.isSpinner = true;
       var copyText = this.template.querySelector(".clipboard");
       copyText.select();
       copyText.setSelectionRange(0, 99999); // For mobile devices
       navigator.clipboard.writeText(copyText.value);
       copyText.setSelectionRange(0, 0); // For mobile devices
       this.isSpinner = false;
   }

   handleGoogleAuthorization(){
       try{
           if (!this.authcode) {
               return;
           }
           else{
               authorizeGoogle({ authcode: this.authcode, isOrg: this.isOrg, isAccess: this.isAccess})
               .then(result =>{
                   if(result === 'success'){
                      
                       this.isSpinner = false;
                       const messageContainer = this.template.querySelector('c-message-popup')
                       messageContainer.showMessageToast({
                           status: 'success',
                           title: 'Success',
                           message : 'Successfully connected to Google Drive',
                       });
                       this.checkinggoogleauth();
                       this.checkingorggoogleauth();
                       this.ispopup = false;
                       this.isSpinner = false;
                   }
                   else{
                       this.ispopup = false;
                       this.isSpinner = false;
                       const messageContainer = this.template.querySelector('c-message-popup')
                       messageContainer.showMessageToast({
                           status: 'error',
                           title: 'error',
                           message : 'Error connecting to Google Drive',
                       });
                       }
                   })
               }
           } catch(error){
           this.isSpinner = false;
           this.ispopup = false;
           errorDebugger('IntegrationDashborad', 'handleGoogleAuthorization', error, 'warn');
       }
   }


   handleAuthCode() {
       if(!this.clientId || !this.clientSecret){
           null;
       }
       else{
           getAuthCode({ clientId: this.clientId, clientSecret: this.clientSecret})
           .then(durl =>{
                if(typeof window !== 'undefined'){
                    window.open(durl, '_blank');
                }
           })
           .catch(error =>{
                errorDebugger('IntegrationDashborad', 'handleAuthCode > getAuthCode > failure', error, 'warn');
           })
       }
   }

   handleAwsAuthorization(){
       if(this.namedCredential != ''){
           authorizeNamed({ named: this.namedCredential })
           .then(result =>{
               this.isSpinner = false;
               if(result === 'Success'){
               const messageContainer = this.template.querySelector('c-message-popup')
                   messageContainer.showMessageToast({
                       status: 'success',
                       title: 'Integration successfull',
                       message : 'Aws integration successful',
                       duration : 5000
                   });
                   this.checkingawsauth();
               }
               else{
                   const messageContainer = this.template.querySelector('c-message-popup')
                   messageContainer.showMessageToast({
                       status: 'error',
                       title: 'Integration failed',
                       message : 'Remote site or Aws details are wrong',
                       duration : 5000
                   });
               }
           }); 
       }
       else{
       const inputs = this.template.querySelectorAll('input');
       inputs.forEach(input =>{
           if(input.value.trim() == null || input.value.trim() == ''){
               input.classList.add('error-border');
           }
           else{
               input.classList.remove('error-border');
           }
       })
       if (!this.clientId || !this.clientSecret || !this.bucket) {
           return;
       }
       else{
           this.ispopup = false;
           this.isAws = false;
           awsAuthorization({ clientId: this.clientId, clientSecret: this.clientSecret, bucket: this.bucket, awsNickname: this.nickname })
           .then(result =>{
               this.isSpinner = false;
               if(result === 'Success'){
               const messageContainer = this.template.querySelector('c-message-popup')
                   messageContainer.showMessageToast({
                       status: 'success',
                       title: 'Integration successfull',
                       message : 'Aws integration successful',
                       duration : 5000
                   });
                   this.checkingawsauth();
               }
               else{
                   const messageContainer = this.template.querySelector('c-message-popup')
                   messageContainer.showMessageToast({
                       status: 'error',
                       title: 'Integration failed',
                       message : 'Aws details are wrong',
                       duration : 5000
                   });
               }
           }); 
           this.isSpinner = false;
           this.bucket = '';
           this.clientId = '';
           this.clientSecret = '';
           this.nickname = '';
   }
}
}

   unauthorize(event) {
    if(this.isAccess){
        this.invoke = event.target.dataset.key;
        const messageContainer = this.template.querySelector('c-message-popup')
                messageContainer.showMessagePopup({
                        status: 'Warning',
                        title: 'Confirm',
                        message : 'Are you sure you want to unlink integration',
                    });
        }
    else if(this.isPartialAccess && event.target.dataset.key == 'google'){
        this.invoke = event.target.dataset.key;
        const messageContainer = this.template.querySelector('c-message-popup')
                messageContainer.showMessagePopup({
                        status: 'Warning',
                        title: 'Confirm',
                        message : 'Are you sure you want to unlink integration',
                    });
        }
    
   }

   handleConfimation(event){
       if(event.detail == true && this.invoke =='google'){
           this.isSpinner = true;
           unauth()
           .then(result =>{
               if(result){
                   this.isActiveGoogleAuth = false;
                   this.checkinggoogleauth();
                   this.isSpinner = false;
                   const messageContainer = this.template.querySelector('c-message-popup')
                   messageContainer.showMessageToast({
                       status: 'success',
                       title: 'Deleted Successfully',
                       message : 'User\'s Google Drive Integration deleted Successfully',
                       duration : 5000
                   });
               }
               else{
                   this.isSpinner = false;
               }
           })
           .catch(() =>{
               this.isSpinner = false;
           })
       }
       else if(event.detail == true && this.invoke =='orggoogle'){
           this.isSpinner = true;
           orgunauth()
           .then(result =>{
               if(result){

                   this.isActiveOrgGoogleAuth = false;
                   this.checkingorggoogleauth();
                   this.isSpinner = false;
                   const messageContainer = this.template.querySelector('c-message-popup')
                   messageContainer.showMessageToast({
                       status: 'success',
                       title: 'Deleted Successfully',
                       message : 'Org Wide Google Drive Integration deleted Successfully',
                       duration : 5000
                   });
               }
               else{
                   this.isSpinner = false;
               }
           })
           .catch(() =>{
               this.isSpinner = false;
           })
       }
       else if(event.detail == true && this.invoke =='aws'){
           this.isSpinner = true;
           awsunauth()
           .then(result =>{
               if(result){
                   this.isActiveAwsAuth = false;
                   this.checkingawsauth();
                   this.isSpinner = false;
                   const messageContainer = this.template.querySelector('c-message-popup')
                   messageContainer.showMessageToast({
                       status: 'success',
                       title: 'Deleted successfully',
                       message : 'Aws integration deleted successfully',
                       duration : 5000
                   });
                   this.isActiveAwsAuth = false;
                   this.checkingawsauth();
               }
               else{
                   this.isSpinner = false;
               }
           }).catch(() =>{
               this.isSpinner = false;
           })
      
       this.isSpinner = false;
       }
       else if(event.detail == true && this.invoke =='onedrive'){
           this.isSpinner = true;
           onedriveunauth()
           .then(result =>{
               if(result){
                   this.isActiveOnedriveAuth = false;
                   this.checkingonedriveauth();
                   this.isSpinner = false;
                   const messageContainer = this.template.querySelector('c-message-popup')
                   messageContainer.showMessageToast({
                       status: 'success',
                       title: 'Deleted successfully',
                       message : 'Onedrive integration deleted successfully',
                       duration : 5000
                   });
               }
               else{
                   this.isSpinner = false;
               }
           }).catch(() =>{
               this.isSpinner =  false;
           })
      
       this.isSpinner = false;
       }
       else if(event.detail == true && this.invoke =='dropbox'){
           this.isSpinner = true;
           dropboxunauth()
           .then(result =>{
               if(result){
                   this.isActiveDropboxAuth = false;
                   this.checkingdropboxauth();
                   this.isSpinner = false;
                   const messageContainer = this.template.querySelector('c-message-popup')
                   messageContainer.showMessageToast({
                       status: 'success',
                       title: 'Deleted successfully',
                       message : 'dropbox integration deleted successfully',
                       duration : 5000
                   });
               }
               else{
                   this.isSpinner = false;
               }
           })
           .catch(() =>{
               this.isSpinner = false;
           })
       }
      
   }

   handleOneDriveAuthorization(){
       const inputs = this.template.querySelectorAll('input');
       inputs.forEach(input =>{
           if(input.value == null || input.value == ''){
               input.classList.add('error-border');
           }
           else{
               input.classList.remove('error-border');
           }
       })
       if (!this.clientId || !this.clientSecret) {
           return;
       }
       else{
       this.ispopup = false;
       this.isOneDrive = false;
       oneDriveAuthorization({clientId: this.clientId, clientSecret: this.clientSecret})
       .then(durl => {
            if(typeof window !== 'undefined'){
                window.location.href = durl;
            }
       })
       .catch(error => {
            this.isSpinner = false;
            errorDebugger('IntegrationDashborad', 'handleOneDriveAuthorization > oneDriveAuthorization', error, 'warn');
       });
       this.clientId = '';
       this.clientSecret = '';
       }
   }

   handleDropboxAuthorization() {
       const inputs = this.template.querySelectorAll('input');
       inputs.forEach(input =>{
           if(input.value == null || input.value == ''){
               input.classList.add('error-border');
           }
           else{
               input.classList.remove('error-border');
           }
       })
       if (!this.clientId || !this.clientSecret) {
           return;
       }
       else{
       this.ispopup = false;
       this.isDropBox = false;
       dropboxAuthorization({clientId: this.clientId, clientSecret: this.clientSecret})
       .then(durl => {
            if(typeof window !== 'undefined'){
                window.location.href = durl;
            }
       })
       .catch(error => {
            this.isSpinner = false;
            errorDebugger('IntegrationDashborad', 'handleDropboxAuthorization > dropboxAuthorization > failure', error, 'warn');
       });
       this.clientId = '';
       this.clientSecret = '';
       }
   }

   closeCreateTemplate(){
       this.ispopup = false
       this.isAws = false;
       this.isOneDrive = false;
       this.isGoogle = false;
       this.isDropBox = false;
       this.isSpinner = false;
       this.clientId = null;
       this.clientSecret = null;
       this.bucket = null;
       this.nickname = null;
   }

   handleAfterSave(event){
       this.isSpinner = true;
       const { clientId, clientSecret, bucket, nickname, draggedkey, named, isOrg, authcode } = event.detail;
       if(!this.isGoogle){
       this.clientId = clientId;
       this.clientSecret = clientSecret;
       }
       this.bucket = bucket;
       this.nickname = nickname;
       this.draggedkey = draggedkey;
       this.namedCredential = named;
       this.authcode = authcode;
       this.isOrg = isOrg;
       if(this.isAws){
           this.handleAwsAuthorization();
           this.ispopup = false;
           this.isAws = false;
       }
       else if(this.isGoogle){
           this.handleGoogleAuthorization();
           this.isGoogle = false;
       }
       else if(this.isDropBox){
           this.handleDropboxAuthorization();
           this.isDropBox = false;
           this.ispopup = false;

       }
       else if(this.isOneDrive){
           this.handleOneDriveAuthorization();
           this.isOneDrive = false;
           this.ispopup = false;
       }
   }
}