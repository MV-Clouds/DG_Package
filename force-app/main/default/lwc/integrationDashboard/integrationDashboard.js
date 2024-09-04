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
import dropboxAuthorization from "@salesforce/apex/DropBoxAuthorizationController.authorize"
import { NavigationMixin } from 'lightning/navigation';



export default class IntegrationDashborad extends NavigationMixin(LightningElement) {

   bgimg;
   logo;
   dropable;
   popupimg;
   nointegration = noconnection;

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
   @track activeTab = 'text1';
   isIntegration = true;
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


  
   connectedCallback() {
       this.bgimg = homePageImgs + '/HomBg.png';
       this.logo = DocGeniusLogo;
       this.dropable = Dropablearea;
       this.popupimg = Popupimg;
       // this.blinktimer();
       this.checkauth();
   }

   checkauth(){
       this.checkingorggoogleauth();
       this.checkinggoogleauth();
       this.checkingawsauth();
       this.checkingonedriveauth();
       this.checkingdropboxauth();
   }


   blinktimer(){
       setInterval(() => {
           let workingMethods = 0;
           let nonWorkingMethods = 0;

           if (this.isWorkingGoogleAuth && this.isActiveGoogleAuth) workingMethods++;
           if (this.isWorkingAwsAuth && this.isActiveAwsAuth) workingMethods++;
           if (this.isWorkingOnedriveAuth && this.isActiveOnedriveAuth) workingMethods++;
           if (this.isWorkingDropboxAuth && this.isActiveDropboxAuth) workingMethods++;
           if (!this.isWorkingGoogleAuth && this.isActiveGoogleAuth) nonWorkingMethods++;
           if (!this.isWorkingAwsAuth && this.isActiveAwsAuth) nonWorkingMethods++;
           if (!this.isWorkingOnedriveAuth && this.isActiveOnedriveAuth) nonWorkingMethods++;
           if (!this.isWorkingDropboxAuth && this.isActiveDropboxAuth) nonWorkingMethods++;
           if (workingMethods > 0) {
               this.toggleGreenColor();
           }
           if(nonWorkingMethods > 0){
               this.toggleRedColor();
           }
          
       }, 1000);
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
           // console.log('inaws');
           // console.log('bucket'+this.awsbucket);
               if (this.template.querySelector('.hide-bucket') && this.awsbucket == 'Unknown') { // Check if all filters are rendered
                   // console.log('inawsbucket'+this.awsbucket);
                   const awsbucket = this.template.querySelector('.hide-bucket');
                   // console.log('inawsbucket'+awsbucket);

                   awsbucket.style.display = 'none';
               }
               this.awsuserdata = false;
           }
   }

   checkinggoogleauth(){
       checkgoogleauth()
       .then(result =>{
           this.displaydetails(result, 'google', 'gc');
           this.loaded();
       })
   }

   checkingorggoogleauth(){
       checkorggoogleauth()
       .then(result =>{
           this.displaydetails(result, 'orggoogle', 'gc');
           this.loaded();
       })
   }

   loaded(){
       this.loadedResources++;
       // console.log(this.loadedResources);
       if(this.loadedResources >= 8){
           this.isSpinner = false;
       }
   }


   checkingawsauth(){
       checkawsauth()
       .then(result =>{
           if(result.bucket != null  && result.linkdate != null && result.name !=null){
             
               this.awsNickname = result.name;
               this.awsbucket = result.bucket;
               this.isWorkingAwsAuth = result.active;
               this.awslinkdate = result.linkdate;
               this.awsuserdata = true;
               // this.template.querySelector('.ac').style.opacity = '0.5';
               const awsimg = this.template.querySelector('.ac img');
               awsimg.style.opacity = '0.5';
               const awsintegration = this.template.querySelector('.ac');
               awsintegration.removeAttribute('draggable');
               const awsintegrationhover = this.template.querySelector('.ac');
               awsintegrationhover.style.pointerEvents = "none";
               this.isActiveAwsAuth = true;
           }
           else{
               this.isActiveAwsAuth = false;
               // this.template.querySelector('.ac').style.opacity = '1';
               const awsimg = this.template.querySelector('.ac img');
               awsimg.style.opacity = '1';
               const awsintegration = this.template.querySelector('.ac');
               awsintegration.setAttribute('draggable', 'true');
               const awsintegrationhover = this.template.querySelector('.ac');
               awsintegrationhover.style.pointerEvents = "auto";
           }
           this.loaded();
       })
   }

  
   checkingonedriveauth(){
       checkOneDriveAuth()
       .then(result =>{
           this.displaydetails(result, 'onedrive', 'oc')
           this.loaded();
       })
   }

   checkingdropboxauth(){
       checkDropBoxAuth()
       .then(result =>{
           this.displaydetails(result, 'dropbox', 'dc')
           this.loaded();
       })
   }

   displaydetails(result, integrationname, cssname){
       if(result.linkdate != null && result.email != null) {
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
           }
           else if(integrationname == 'onedrive'){
               this.isWorkingOnedriveAuth = result.active;
               this.isActiveOnedriveAuth = true;
           }
           else if(integrationname == 'google'){
               this.isWorkingGoogleAuth = result.active;
               this.isActiveGoogleAuth = true;
           }
           else if(integrationname == 'orggoogle'){
               this.isWorkingOrgGoogleAuth = result.active;
               this.isActiveOrgGoogleAuth = true;
           }
           this[integrationname + 'linkdate'] = result.linkdate;
           // this.template.querySelector('.'+cssname).style.opacity = '0.5';
           if(integrationname != 'orggoogle'){
           const integrationimg = this.template.querySelector('.'+cssname + ' img');
           integrationimg.style.opacity = '0.5';
           const integrations = this.template.querySelector('.'+cssname);
           integrations.removeAttribute('draggable');
           const integrationhover = this.template.querySelector('.'+cssname);
           integrationhover.style.pointerEvents = "none";
           }
       }
       else{
           if(integrationname == 'dropbox'){
               this.isActiveDropboxAuth = false;
           }
           else if(integrationname == 'onedrive'){
               this.isActiveOnedriveAuth = false;
           }
           else if(integrationname == 'google'){
               this.isActiveGoogleAuth = false;

           }
           if(integrationname != 'orggoogle'){
           // this.template.querySelector('.'+cssname).style.opacity = '1';
           const integrationimg = this.template.querySelector('.'+cssname + ' img');
           integrationimg.style.opacity = '1';
           const integrations = this.template.querySelector('.'+cssname);
           integrations.setAttribute('draggable', 'true');
           const integrationhover = this.template.querySelector('.'+cssname);
           integrationhover.style.pointerEvents = "auto";
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
       // console.log(key);
       this.template.querySelector('.dragbackground').style.opacity = '0.5';
       this.template.querySelector('.dropandstatus').style.opacity = '0.5';

   }

   handleDragOver(event){
       event.preventDefault();
   }

   handleNickname(event){
       this.nickname = event.target.value.trim();
       // console.log(this.nickname);
   }


   handledDrop(event){
       // console.log('handledDrop Invoked');
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
       // console.log(this.clientId);
   }


   handleClientSecret(event) {
       this.clientSecret = event.target.value.trim();
       // console.log(this.clientSecret);
   }


   handleBucket(event){
       this.bucket = event.target.value.trim();
       // console.log(this.bucket);
   }


   handleSetActive(event){
       const tabName = event.currentTarget.dataset.name;
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
               if(ele.dataset.name == tabName){
                   ele.classList.add('enable');
                   if(tabName == 'text0'){
                       this.isSetup = true;
                       this.isSpinner = false;
                   }
                   else if(tabName == "text1"){
                       this.isIntegration  = true;
                       this.connectedCallback();
                   }
                   else if(tabName == "text2"){
                       this.isLimitations = true;
                       this.isSpinner = false;
                   }
                   else if(tabName == "text3"){
                       this.isUserguide = true;
                       this.isSpinner = false;
                   }
               }
               else{
                   ele.classList.remove('enable');
               }
           })
       }
       // this.isSpinner = false;
   }

   copyToClipboard() {
       this.isSpinner = true;
       // console.log('Invoked clipboard');
       var copyText = this.template.querySelector(".clipboard");
       // console.log(copyText);
       copyText.select();
       copyText.setSelectionRange(0, 99999); // For mobile devices
       navigator.clipboard.writeText(copyText.value);
       copyText.setSelectionRange(0, 0); // For mobile devices
       this.isSpinner = false;
   }

   handleGoogleAuthorization(){
       try{
           if (!this.authcode) {
               // console.log('All details are compulsory');
               return;
           }
           else{
               // console.log('going for integration');
               // console.log(this.isOrg);
               // console.log(typeof(this.isOrg));
               authorizeGoogle({ authcode: this.authcode, isOrg: this.isOrg})
               .then(result =>{
                   if(result === 'success'){
                      
                       // console.log('success');
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
                       // console.log('error');
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
           console.log(error.getMessage);
           this.isSpinner = false;
           this.ispopup = false;
           console.error('this is error'+JSON.stringify(error));
       }
   }


   handleAuthCode(event) {
       // console.log('inside parent');
       if(!this.clientId || !this.clientSecret){
           console.log('both client id and secret are compulsary');
       }
       else{
           getAuthCode({ clientId: this.clientId, clientSecret: this.clientSecret})
           .then(durl =>{
               window.open(durl, '_blank');
           })
           .catch(error =>{
               console.error('Error:', error);
           })
       }
   }

   handleAwsAuthorization(){
       if(this.namedCredential != ''){
           authorizeNamed({ named: this.namedCredential })
           .then(result =>{
               // console.log(result);
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
           // console.log('All details are compulsory');
           return;
       }
       else{
           this.ispopup = false;
           this.isAws = false;
           awsAuthorization({ clientId: this.clientId, clientSecret: this.clientSecret, bucket: this.bucket, awsNickname: this.nickname })
           .then(result =>{
               console.log(result);
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
       // this.invoke = event.target.dataset.key;
       // console.log(event.target.dataset.key);
       this.invoke = event.target.dataset.key;
       // console.log(this.invoke);
       const messageContainer = this.template.querySelector('c-message-popup')
               messageContainer.showMessagePopup({
                       status: 'Warning',
                       title: 'Confirm',
                       message : 'Are you sure you want to unlink integration',
                   });
      
       // console.log('something will happen');
   }

   handleConfimation(event){
       console.log('handleConfimation : ', event.detail);
       // console.log(this.invoke);
       if(event.detail == true && this.invoke =='google'){
           this.isSpinner = true;
           unauth()
           .then(result =>{
               // console.log(result);
               if(result){
                   // console.log('inside');
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
           .catch(error =>{
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
           .catch(error =>{
               this.isSpinner = false;
           })
       }
       else if(event.detail == true && this.invoke =='aws'){
           this.isSpinner = true;
           awsunauth()
           .then(result =>{
               // console.log(result);
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
                   // console.log('inside');
                   this.isActiveAwsAuth = false;
                   this.checkingawsauth();
               }
               else{
                   this.isSpinner = false;
               }
           }).catch(error =>{
               this.isSpinner = false;
           })
      
       this.isSpinner = false;
       }
       else if(event.detail == true && this.invoke =='onedrive'){
           this.isSpinner = true;
           onedriveunauth()
           .then(result =>{
               // console.log(result);
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
                   // console.log('inside');        
               }
               else{
                   this.isSpinner = false;
               }
           }).catch(error =>{
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
           .catch(error =>{
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
           // console.log('both client id and secret are compulsary');
           return;
       }
       else{
       // console.log('Going for authorization');
       this.ispopup = false;
       this.isOneDrive = false;
       oneDriveAuthorization({clientId: this.clientId, clientSecret: this.clientSecret})
       .then(durl => {
           window.location.href = durl;
       })
       .catch(error => {
        this.isSpinner = false;
           console.error('Error:', error);
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
           // console.log('both client id and secret are compulsary');
           return;
       }
       else{
       // console.log('Going for authorization');
       this.ispopup = false;
       this.isDropBox = false;
       dropboxAuthorization({clientId: this.clientId, clientSecret: this.clientSecret})
       .then(durl => {
           window.location.href = durl;
       })
       .catch(error => {
            this.isSpinner = false;
           console.error('Error:', error);
       });
       this.clientId = '';
       this.clientSecret = '';
       }
   }

   authorizeremaining() {
       const messageContainer = this.template.querySelector('c-message-popup')
           messageContainer.showMessagePopup({
                       status: 'info',
                       title: 'Under Construction',
                       message : 'Page Under Construction',
                   });
   }

   closeCreateTemplate(event){
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
       // console.log('parent1');
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
       // console.log(isOrg);
       // console.log(this.isOrg);
       if(this.isAws){
           // console.log('1');
           this.handleAwsAuthorization();
           this.ispopup = false;
           this.isAws = false;
       }
       else if(this.isGoogle){
           // console.log('2');
           this.handleGoogleAuthorization();
           this.isGoogle = false;
       }
       else if(this.isDropBox){
           // console.log('3');
           this.handleDropboxAuthorization();
           this.isDropBox = false;
           this.ispopup = false;

       }
       else if(this.isOneDrive){
           // console.log('4');
           this.handleOneDriveAuthorization();
           this.isOneDrive = false;
           this.ispopup = false;
       }
   }
}