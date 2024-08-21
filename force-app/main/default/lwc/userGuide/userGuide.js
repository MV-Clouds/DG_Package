import { LightningElement, track } from 'lwc';
import Userguide from "@salesforce/resourceUrl/Userguide";
import homePageImgs from "@salesforce/resourceUrl/homePageImgs";

export default class UserGuide extends LightningElement {
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
    
    activeSections = [];
    @track awsTab = true;
    @track gdriveTab = false;
    @track odriveTab = false;
    @track dropboxTab = false;
    @track stempTab = false;
    @track csvtempTab = false;
    @track gdtempTab = false;

    @track isOpen = true;

    handleTabSelection(event) {
        let tabName = event.target.dataset.tab;

        this.awsTab = false;
        this.gdriveTab = false;
        this.odriveTab = false;
        this.dropboxTab = false;
        this.stempTab = false;
        this.csvtempTab = false;
        this.gdtempTab = false;
        
        this[tabName + 'Tab'] = true;
        this.closeTab();

        let currentTab = this.template.querySelector('.selected-tab');
        currentTab.classList.remove('selected-tab');

        let tab = this.template.querySelector(`.tabs[data-tab="${tabName}"]`);
        tab.classList.add('selected-tab');
    }

    toggleTab() {
        if(this.isOpen) {
            this.closeTab();
        } else if (!this.isOpen) {
            this.openTab();
        }
    }

    openTab() {
        this.template.querySelector('.left-section').style.width = '30%';
        this.template.querySelector('.container').style.gap = '20px';
        this.isOpen = true;
    } 
    
    closeTab() {
        this.template.querySelector('.left-section').style.width = '0';
        this.template.querySelector('.container').style.gap = '0';
        this.isOpen = false;
    }

    connectedCallback() {
        // this.closeTab();
    }

    renderedCallback(){
        // const el = document.querySelectorAll('lightning-accordion-section');
        // const shadowRoot = el.attachShadow({mode: 'open'});
        // shadowRoot.style = 'border-radius: 5px';
    }
}