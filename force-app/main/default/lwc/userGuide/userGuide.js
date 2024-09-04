import { LightningElement, track } from 'lwc';
import Userguide from "@salesforce/resourceUrl/Userguide";
import integrationImages from "@salesforce/resourceUrl/integrationImages";
import homePageImgs from "@salesforce/resourceUrl/homePageImgs";

export default class UserGuide extends LightningElement {

    // Logos
    get gdriveLogo() {
        return integrationImages + '/googleDrive.png';
    }
    get awsLogo(){
        return integrationImages + '/aws.png';
    }
    get odriveLogo(){
        return integrationImages + '/oneDrive.png';
    }
    get dropboxLogo(){
        return integrationImages + '/dropbox.png';
    }
    get stempLogo() {
        return integrationImages + '/simpletemplate.png';
    }
    get csvLogo() {
        return integrationImages + '/csvtemplate.png';
    }
    get gdtempLogo() {
        return integrationImages + '/googledoctemplate.png';
    }

    // AWS Images
    get aws1(){
        return Userguide + '/aws1.png';
    }
    get aws2(){
        return Userguide + '/aws2.png';
    }
    get aws3(){
        return Userguide + '/aws3.png';
    }
    get aws4(){
        return Userguide + '/aws4.png';
    }
    get aws5(){
        return Userguide + '/aws5.png';
    }
    get aws6(){
        return Userguide + '/aws6.png';
    }
    get aws7(){
        return Userguide + '/aws7.png';
    }
    get aws8(){
        return Userguide + '/aws8.png';
    }

    // Google Drive Images
    get gdrive1(){
        return Userguide + '/googlescreen.png';
    }
    get gdrive2(){
        return Userguide + '/generatecode.png';
    }
    get gdrive3(){
        return Userguide + '/accounts.png';
    }
    get gdrive4(){
        return Userguide + '/verification.png';
    }
    get gdrive5(){
        return Userguide + '/googlecopycode.png';
    }
    get gdrive6(){
        return Userguide + '/googleauthorise.png';
    }
    get gdrive7(){
        return Userguide + '/googlescreen2.png';
    }

    // Dropbox Images
    get dropbox1(){
        return Userguide + '/dropboxsite.png';
    }
    get dropbox2(){
        return Userguide + '/dropboxnewapp.png';
    }
    get dropbox3(){
        return Userguide + '/dropboxusersenable.png';
    }
    get dropbox4(){
        return Userguide + '/dropboxpermissions.png';
    }
    get dropbox5(){
        return Userguide + '/dropboxpermissions2.png';
    }
    get dropbox6(){
        return Userguide + '/dropboxsettings.png';
    }
    get dropbox7(){
        return Userguide + '/dropboxcredentials.png';
    }
    get dropbox8(){
        return Userguide + '/dropboxscreen.png';
    }
    get dropbox9(){
        return Userguide + '/dropboxapp.png';
    }
    get dropbox10(){
        return Userguide + '/dropboxactive.png';
    }

    // One Drive Images
    get odrive1(){
        return Userguide + '/onedriveappregister.png';
    }
    get odrive2(){
        return Userguide + '/onedriveappregister2.png';
    }
    get odrive3(){
        return Userguide + '/onedriveauthorise.png';
    }
    get odrive4(){
        return Userguide + '/onedriveapp.png';
    }
    get odrive5(){
        return Userguide + '/onedrivecredentials.png';
    }
    get odrive6(){
        return Userguide + '/onedrivecredentials2.png';
    }
    get odrive7(){
        return Userguide + '/onedrivescope.png';
    }
    get odrive8(){
        return Userguide + '/onedrivescope2.png';
    }
    get odrive9(){
        return Userguide + '/onedrivescope2.png';
    }
    get odrive10(){
        return Userguide + '/onedrivepermissions.png';
    }
    get odrive11(){
        return Userguide + '/onedriveaddpermissions.png';
    }
    get odrive12(){
        return Userguide + '/onedriveaddpermissions2.png';
    }
    get odrive13(){
        return Userguide + '/onedriveactive.png';
    }

    // Simple Template
    get stemp1() {
        return Userguide + '/homescreen.png';
    }
    get stemp2() {
        return Userguide + '/pageconfig.png';
    }
    get stemp3() {
        return Userguide + '/header.png';
    }
    get stemp4() {
        return Userguide + '/footer.png';
    }
    get stemp5() {
        return Userguide + '/basicdetails.png';
    }

    // Google Doc Images
    get gdtemp1() {
        return Userguide + '/creationpage.png';
    }
    get gdtemp2() {
        return Userguide + '/alltemplates.png';
    }
    get gdtemp3() {
        return Userguide + '/keymappingpage.png';
    }
    get gdtemp4() {
        return Userguide + '/previewbutton.png';
    }
    get gdtemp5() {
        return Userguide + '/previewpage.png';
    }
    get gdtemp6() {
        return Userguide + '/previewpage2.png';
    }
    get gdtemp7() {
        return Userguide + '/gbasicdetails.png';
    }
    get gdtemp8() {
        return Userguide + '/setdefaults.png';
    }

    // CSV Template
    get csv1() {
        return Userguide + '/NewCSVTemplateCreation.png';
    }
    get csv2() {
        return Userguide + '/ListViewPopUp.png';
    }
    get csv3() {
        return Userguide + '/EditTemplatetab.png';
    }
    get csv4() {
        return Userguide + '/Selectcolumns.png';
    }
    get csv5() {
        return Userguide + '/ApplyFilters.png';
    }
    get csv6() {
        return Userguide + '/OrderBy.png';
    }
    get csv7() {
        return Userguide + '/Limit.png';
    }
    get csv8() {
        return Userguide + '/BasicDetailstab.png';
    }
    get csv9() {
        return Userguide + '/TemplateDefaultstab.png';
    }

    // Button Generator
    get btngen1() {
        return Userguide + '/Buttongenerator.png';
    }

    // Document Generator
    get docgen1() {
        return Userguide + '/DGGenerateCSV.png';
    }
    get docgen2() {
        return Userguide + '/DGGenerateDocument.png';
    }
    get docgen3() {
        return Userguide + '/Selecttemplatetogenerate.png';
    }
    get docgen4() {
        return Userguide + '/viewalltemplatesbutton.png';
    }
    get docgen5() {
        return Userguide + '/viewalltemplatesUI.png';
    }
    get docgen6() {
        return Userguide + '/generatedocument.png';
    }
    get docgen7() {
        return Userguide + '/composeemail.png';
    }
    
    activeSections = [];
    @track selectedImage = this.aws1;

    @track dochomeTab = false;
    @track btngenTab = false;
    @track awsTab = true;
    @track gdriveTab = false;
    @track odriveTab = false;
    @track dropboxTab = false;
    @track stempTab = false;
    @track csvtempTab = false;
    @track gdtempTab = false;
    @track keysecTab = false;
    @track docgenTab = false;
    @track tabList = ['dochomeTab', 'btngenTab', 'awsTab', 'gdriveTab', 'odriveTab', 'dropboxTab', 'stempTab', 'csvtempTab', 'gdtempTab', 'keysecTab', 'docgenTab'];

    @track isOpen = false;
    @track showModal = false;

    closeModal() {
        this.showModal = false;
    }
    openModal(event) {
        this.selectedImage = event.target.src;
        this.showModal = true;
    }

    // Switch Tabs
    handleTabSelection(event) {
        try {
            this.closeTab();
            let tabName = event.target.dataset.tab;
            this.tabList.forEach(tab => {
                this[tab] = false;
            });
            this[tabName + 'Tab'] = true;
            
            let currentTab = this.template.querySelector('.selected-tab');
            currentTab.classList.remove('selected-tab');
            let tab = this.template.querySelector(`.tabs[data-tab="${tabName}"]`);
            tab.classList.add('selected-tab');

            this.template.querySelector('.tab-content').scrollTop = 0;
            this.template.querySelector('.content').scrollTop = 0;
            this.template.querySelector('.white-background').scrollTop = 0;
        } catch (error) {
            console.log(error);
        }
    }

    toggleTab() {
        if(this.isOpen) {
            this.closeTab();
        } else if (!this.isOpen) {
            this.openTab();
        }
    }

    openTab() {
        this.template.querySelector('.svg-arrow').style.transform = 'rotate3d(0, 1, 0, 180deg)';
        this.template.querySelector('.left-section').style.width = '30%';
        this.template.querySelector('.container').style.gap = '20px';
        this.isOpen = true;
    } 
    
    closeTab() {
        this.template.querySelector('.svg-arrow').style.transform = 'rotate3d(0, 0, 0, 180deg)';
        this.template.querySelector('.left-section').style.width = '0';
        this.template.querySelector('.container').style.gap = '0';
        this.isOpen = false;
    }
}