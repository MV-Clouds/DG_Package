import { LightningElement, track } from 'lwc';
import Userguide from "@salesforce/resourceUrl/Userguide";
import Userguide2 from "@salesforce/resourceUrl/Userguide2";
import integrationImages from "@salesforce/resourceUrl/integrationImages";
import { errorDebugger } from 'c/globalProperties';

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
        return Userguide + '/aws/aws1.png';
    }
    get aws2(){
        return Userguide + '/aws/aws2.png';
    }
    get aws3(){
        return Userguide + '/aws/remotesiteaws.png';
    }
    get aws4(){
        return Userguide + '/aws/aws3.png';
    }
    get aws5(){
        return Userguide + '/aws/aws5.png';
    }
    get aws6(){
        return Userguide + '/aws/aws6.png';
    }
    get aws7(){
        return Userguide + '/aws/aws7.png';
    }
    get aws8(){
        return Userguide + '/aws/aws8.png';
    }
    get aws9(){
        return Userguide + '/aws/awsnamedcredential.png';
    }

    // Google Drive Images
    get gdrive1(){
        return Userguide + '/google/googlescreen.png';
    }
    get gdrive2(){
        return Userguide + '/google/generatecode.png';
    }
    get gdrive3(){
        return Userguide + '/google/accounts.png';
    }
    get gdrive4(){
        return Userguide + '/google/googlecopycode.png';
    }
    get gdrive5(){
        return Userguide + '/google/googleauthorise.png';
    }
    get gdrive6(){
        return Userguide + '/google/googlescreen2.png';
    }

    // Dropbox Images
    get dropbox1(){
        return Userguide + '/dropbox/dropboxsite.png';
    }
    get dropbox2(){
        return Userguide + '/dropbox/dropboxnewapp.png';
    }
    get dropbox3(){
        return Userguide + '/dropbox/dropboxusersenable.png';
    }
    get dropbox4(){
        return Userguide + '/dropbox/dropboxpermissions.png';
    }
    get dropbox5(){
        return Userguide + '/dropbox/dropboxpermissions2.png';
    }
    get dropbox6(){
        return Userguide + '/dropbox/dropboxsettings.png';
    }
    get dropbox7(){
        return Userguide + '/dropbox/dropboxcredentials.png';
    }
    get dropbox8(){
        return Userguide + '/dropbox/dropboxscreen.png';
    }
    get dropbox9(){
        return Userguide + '/dropbox/dropboxapp.png';
    }
    get dropbox10(){
        return Userguide + '/dropbox/dropboxactive.png';
    }

    // One Drive Images
    get odrive1(){
        return Userguide + '/onedrive/onedriveappregister.png';
    }
    get odrive2(){
        return Userguide + '/onedrive/onedriveappregister2.png';
    }
    get odrive3(){
        return Userguide + '/onedrive/onedriveauthorise.png';
    }
    get odrive4(){
        return Userguide + '/onedrive/onedriveapp.png';
    }
    get odrive5(){
        return Userguide + '/onedrive/odriveclientid.png';
    }
    get odrive6(){
        return Userguide + '/onedrive/onedrivecredentials2.png';
    }
    get odrive7(){
        return Userguide + '/onedrive/onedrivecredentials.png';
    }
    get odrive8(){
        return Userguide + '/onedrive/odriveaddscope.png';
    }
    get odrive9(){
        return Userguide + '/onedrive/onedrivescope.png';
    }
    get odrive10(){
        return Userguide + '/onedrive/onedrivescope2.png';
    }
    get odrive11(){
        return Userguide + '/onedrive/onedrivescope2.png';
    }
    get odrive12(){
        return Userguide + '/onedrive/onedriveaddpermissions.png';
    }
    get odrive13(){
        return Userguide + '/onedrive/onedrivepermissions.png';
    }
    get odrive14(){
        return Userguide + '/onedrive/onedriveaddpermissions2.png';
    }
    get odrive15(){
        return Userguide + '/onedrive/onedriveactive.png';
    }

    // Simple Template
    get stemp1() {
        return Userguide + '/simple/homescreen.png';
    }
    get stemp2() {
        return Userguide + '/simple/pageconfig.png';
    }
    get stemp3() {
        return Userguide + '/simple/header.png';
    }
    get stemp4() {
        return Userguide + '/simple/footer.png';
    }
    get stemp5() {
        return Userguide + '/simple/basicdetails.png';
    }

    // Google Doc Images
    get gdtemp1() {
        return Userguide + '/googledoc/creationpage.png';
    }
    get gdtemp2() {
        return Userguide + '/googledoc/alltemplates.png';
    }
    get gdtemp3() {
        return Userguide + '/googledoc/keymappingpage.png';
    }
    get gdtemp4() {
        return Userguide + '/googledoc/previewbutton.png';
    }
    get gdtemp5() {
        return Userguide + '/googledoc/previewpage.png';
    }
    get gdtemp6() {
        return Userguide + '/googledoc/previewpage2.png';
    }
    get gdtemp7() {
        return Userguide + '/googledoc/gbasicdetails.png';
    }
    get gdtemp8() {
        return Userguide + '/googledoc/setdefaults.png';
    }

    // CSV Template
    get csv1() {
        return Userguide + '/csv/NewCSVTemplateCreation.png';
    }
    get csv2() {
        return Userguide + '/csv/ListViewPopUp.png';
    }
    get csv3() {
        return Userguide + '/csv/EditTemplatetab.png';
    }
    get csv4() {
        return Userguide + '/csv/Selectcolumns.png';
    }
    get csv5() {
        return Userguide + '/csv/ApplyFilters.png';
    }
    get csv6() {
        return Userguide + '/csv/OrderBy.png';
    }
    get csv7() {
        return Userguide + '/csv/Limit.png';
    }
    get csv8() {
        return Userguide + '/csv/BasicDetailstab.png';
    }
    get csv9() {
        return Userguide + '/csv/TemplateDefaultstab.png';
    }

    // Button Generator
    get btngen1() {
        return Userguide + '/button/Buttongenerator.png';
    }

    // Document Generator
    get docgen1() {
        return Userguide2 + '/document/DGGenerateCSV.png';
    }
    get docgen2() {
        return Userguide2 + '/document/DGGenerateDocument.png';
    }
    get docgen3() {
        return Userguide2 + '/document/Selecttemplatetogenerate.png';
    }
    get docgen4() {
        return Userguide2 + '/document/viewalltemplatesbutton.png';
    }
    get docgen5() {
        return Userguide2 + '/document/viewalltemplatesUI.png';
    }
    get docgen6() {
        return Userguide2 + '/document/generatedocument.png';
    }
    get docgen7() {
        return Userguide2 + '/document/composeemail.png';
    }

    // Home Page Images
    get dochome1() {
        return Userguide2 + '/home/homeemptycreate.png';
    }
    get dochome2() {
        return Userguide2 + '/home/homenewtemplates.png';
    }
    get dochome3() {
        return Userguide2 + '/home/homenewbutton.png';
    }
    get dochome4() {
        return Userguide2 + '/home/homebuttons.png';
    }
    get dochome5() {
        return Userguide2 + '/home/hometemplates.png';
    }
    get dochome6() {
        return Userguide2 + '/home/homefilters.png';
    }

    // key mapping container
    get keysec1() {
        return Userguide2 + '/key/keyoptions2.png';
    }
    get keysec2() {
        return Userguide2 + '/key/keyoptions.png';
    }
    get keysec3() {
        return Userguide2 + '/key/keyoptionscopy.png';
    }
    get keysec4() {
        return Userguide2 + '/key/datetimeformat.png';
    }
    get keysec5() {
        return Userguide2 + '/key/dateformat.png';
    }
    get keysec6() {
        return Userguide2 + '/key/timeformat.png';
    }
    get keysec7() {
        return Userguide2 + '/key/numberformat.png';
    }
    get keysec8() {
        return Userguide2 + '/key/checkboxformat.png';
    }
    get keysec9() {
        return Userguide2 + '/key/relatedlistfields.png';
    }
    get keysec10() {
        return Userguide2 + '/key/copytable2.png';
    }
    get keysec11() {
        return Userguide2 + '/key/copytable.png';
    }
    get keysec12() {
        return Userguide2 + '/key/generalfields.png';
    }
    get keysec13() {
        return Userguide2 + '/key/mergetemplates.png';
    }
    get keysec14() {
        return Userguide2 + '/key/salesforceimages.png';
    }
    get keysec15() {
        return Userguide2 + '/key/signatureimages.png';
    }
    
    @track selectedImage;

    @track dochomeTab = false;
    @track btngenTab = true;
    @track awsTab = false;
    @track gdriveTab = false;
    @track odriveTab = false;
    @track dropboxTab = false;
    @track stempTab = false;
    @track csvtempTab = false;
    @track gdtempTab = false;
    @track keysecTab = false;
    @track docgenTab = false;
    @track tabList = ['btngenTab', 'awsTab', 'gdriveTab', 'odriveTab', 'dropboxTab', 'gdtempTab', 'stempTab', 'csvtempTab', 'dochomeTab', 'keysecTab', 'docgenTab'];

    @track isOpen = true;
    @track showModal = false;

    closeModal() {
        this.showModal = false;
    }
    openModal(event) {
        this.selectedImage = event.target.src;
        this.showModal = true;
    }

    handleKeyPress = (event) => {
        if (event.key == 'Escape') {
            this.closeModal();
        }
    }

    renderedCallback() {
        try {
            if (this.showModal) {
                window.addEventListener('keydown', this.handleKeyPress);
            } else {
                window.removeEventListener('keydown', this.handleKeyPress);
            }
        } catch (error) {
            errorDebugger("userGuide", 'handleKeyPress', error, 'error', 'Error in handling keyboard events. Please try again later');
        }
    }

    handleOnScroll() {
        try {
            for (let i = 0; i < this.tabList.length; i++) {
                const element = this.template.querySelector(`[data-id="${this.tabList[i]}"]`);
                if (element && this.isInViewport(element)) {
                    
                    let currentTab = this.template.querySelector('.selected-tab');
                    if (currentTab) {
                        currentTab.classList.remove('selected-tab');
                    }
                    let tab = this.template.querySelector(`a.tabs[data-tab="${this.tabList[i].slice(0, -3)}"]`);
                    if (tab) {
                        tab.classList.add('selected-tab');
                        tab.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'nearest' });
                    }
                    break;
                }
            }
        } catch (error) {
            errorDebugger("userGuide", 'handleOnScroll', error, 'error', 'Error in scrolling tabs. Please try again later');
        }
    }

    // Switch Tabs
    handleTabSelection(event) {
        try {
            if (window && window.innerWidth && window.innerWidth < 1024 ) {
                this.closeTab();
            }
            let tabName = event.target.dataset.tab;
            if (!tabName) {
                tabName = event.target.parentElement.dataset.tab;
            }
        } catch (error) {
            errorDebugger("userGuide", 'handleTabSelection', error, 'error', 'Error in changing tabs. Please try again later');
        }
    }

    isInViewport(element) {
        try {
            var rect = element.getBoundingClientRect();
            var parent = this.template.querySelector('.white-background');
            var parentRect = parent.getBoundingClientRect();
            
            var isTallerThanParent = rect.height > parentRect.height;
            if (isTallerThanParent) {
                return (rect.bottom > parentRect.top && rect.top < parentRect.bottom);
            }
            return (rect.top >= parentRect.top && rect.left >= parentRect.left && rect.bottom <= parentRect.bottom && rect.right <= parentRect.right);
        } catch (error) {
            errorDebugger("userGuide", 'isInViewport', error, 'error', 'Error in checking if element is in viewport. Please try again later');
        }
        return false;
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
        // this.template.querySelector('.container').style.gap = '20px';
        this.isOpen = true;
    } 
    
    closeTab() {
        this.template.querySelector('.svg-arrow').style.transform = 'rotate3d(0, 0, 0, 180deg)';
        this.template.querySelector('.left-section').style.width = '0';
        // this.template.querySelector('.container').style.gap = '0';
        this.isOpen = false;
    }
}