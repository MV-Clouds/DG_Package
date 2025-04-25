import { LightningElement , api, track } from 'lwc';
import cloneTemplateImage from '@salesforce/resourceUrl/clone_template_image';
import newTemplateBg from '@salesforce/resourceUrl/new_template_bg';
import cloneTempData from '@salesforce/apex/CloneTemplateDataController.cloneTempData'
// import { NavigationMixin } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import {navigationComps, nameSpace, errorDebugger} from 'c/globalPropertiesV2';


export default class CloneTemplateV2 extends NavigationMixin(LightningElement) {
  
    @api templatelist;
    @api selectedtemplateid;
    @api showModel;

    @track templateId;
    @track templateName;
    @track templateDescription;
    @track templateObject;
    @track templateType;
    @track templateImage = cloneTemplateImage;
    @track templateBg = newTemplateBg;
    @track isShowSpinner = false;
    @track showTempData = true;
    @track showSelectData = false;
    @track templateBody = true;
    @track header = true;
    @track footer = true;
    // @track watermark = true;
    @track pageConfiguration = true;
    @track templateTypeSimple = false;
    @track templateTypeCSV = false;

    @track templateSelectOption;
    

    isImageLoaded = false;
    isDataProcessed = false;
    // templateId = '';
    isDataInvalid = false;

    renderedCallback() {
        this.template.host.style.setProperty('--background-image-url',`url(${this.templateBg})`);
    }

    get showModal() {
        return true;
    }

    connectedCallback(){
        const template = this.templatelist.find(temp => temp.Id === this.selectedtemplateid);
        this.templateId =  template.Id;
        this.templateName = template.MVDG__Template_Name__c+'-copy';
        this.templateDescription = template.MVDG__Description__c;
        if(this.templateDescription == undefined || this.templateDescription == null){
            this.templateDescription='';
        }
        this.templateObject = template.MVDG__Object_API_Name__c;
        this.templateType = template.MVDG__Template_Type__c;
        if( this.templateType == 'CSV Template'){
            this.templateTypeCSV = true;
        }
        else if(this.templateType == 'Simple Template'){
            this.templateTypeSimple = true;
        }
        this.isDataProcessed = true;
    }

    imageLoaded(){
        this.isImageLoaded = true;
    }

    get doShowSpinner(){
        if(this.isImageLoaded && this.isDataProcessed && !this.isShowSpinner){
            return false;
        }
        return true;
    }

    handleTemplateNameChange(event) {
        this.isDataInvalid = false;
        this.template.querySelector('.t-name').classList.remove("error-border");
        this.template.querySelectorAll('label')[0].classList.remove("error-label");
        this.templateName = event.target.value.trim();
        if (!this.templateName || this.templateName.length > 255) {
            this.template.querySelector('.t-name').classList.add("error-border");
            this.template.querySelectorAll('label')[0].classList.add("error-label");
            this.isDataInvalid = true;
        }
    }

    handleTemplateDescriptionChange(event){
        this.templateDescription = event.target.value.trim() ? event.target.value.trim() : '';
    }

    closeModel(){
        if (typeof window !== 'undefined') {
            const closeModalEvent = new CustomEvent('closemodal');
            this.dispatchEvent(closeModalEvent);
        }
    }

    cloneTemplate(){
        try {
            this.isShowSpinner = true;
            this.templateName = this.template.querySelector(`[data-name="temp-name"]`).value;
            if(!this.templateName){
                this.isShowSpinner = false;
                return;
            }
            if(this.templateName.length > 255){
                this.showToast('error', 'Something went wrong!', 'Template Name should not be more than 255 characters!', 5000);
                this.template.querySelector('.t-name').classList.add('error-border');
                this.template.querySelectorAll('label')[0].classList.add('error-label');
                this.isShowSpinner = false;
                return;
            }
            this.templateDescription = this.template.querySelector(`[data-name="temp-description"]`).value;
            if(this.templateType == 'Simple Template'){
                let templateBody = this.template.querySelector(`[data-name="templateBody"]`).checked;
                // let watermark = this.template.querySelector(`[data-name="watermark"]`).checked;
                let header = this.template.querySelector(`[data-name="header"]`).checked;
                let pageConfiguration = this.template.querySelector(`[data-name="pageConfiguration"]`).checked;
                let footer = this.template.querySelector(`[data-name="footer"]`).checked;
                const newTemplateOption = {
                    templateName: this.templateName,
                    templateDescription: this.templateDescription,
                    templateType:this.templateType,
                    templateBody: templateBody,
                    // watermark: watermark,
                    header: header,
                    pageConfiguration: pageConfiguration,
                    footer:footer
                };
                const jsonData = JSON.stringify(newTemplateOption);
                this.templateSelectOption = jsonData;
            }else if(this.templateType == 'CSV Template'){
                let selectedFields = this.template.querySelector(`[data-name="selectedFields"]`).checked;
                let fieldsFilters = this.template.querySelector(`[data-name="fieldsFilters"]`).checked;
                let fieldOrderBy = this.template.querySelector(`[data-name="fieldOrderBy"]`).checked;
                let fieldLimit = this.template.querySelector(`[data-name="fieldLimit"]`).checked;
                const dataMap = {
                    templateName: this.templateName,
                    templateDescription: this.templateDescription,
                    templateType:this.templateType,
                    newSelectedFields: selectedFields,
                    newFieldsFilters: fieldsFilters,
                    newFieldOrderBy: fieldOrderBy,
                    newFieldLimit: fieldLimit
                };
                const jsonData = JSON.stringify(dataMap);
                this.templateSelectOption = jsonData;
            }
            cloneTempData({templateId: this.templateId, jsonData: this.templateSelectOption })
            .then(response=>{
                if(response.isSuccess ){
                    this.templateId = response.tempId;
                    this.templateObject = response.tempObj;
                    this.handleNavigate();
                    if (typeof window !== 'undefined') {
                        this.dispatchEvent(new CustomEvent('aftersave'));
                    }
                    this.closeModel();
                }else{
                    this.showToast('error','Something went wrong!','The template could not be cloned, please try again...', 5000);
                }
            }).catch(error=>{
                this.isShowSpinner = false;
                errorDebugger('CloneTemplate', 'cloneTemplate > cloneTempData', error, 'warn');
            })
        } catch (error) {
            this.isShowSpinner = false;
            errorDebugger('CloneTemplate', 'cloneTemplate', error, 'warn');
        }
    }

    handleNavigate() {
        try {
            var paramToPass = {
                templateId: this.templateId,
                objectName: this.templateObject,
            };
            if (this.templateType === 'Simple Template') {
                this.navigateToComp(navigationComps.simpleTemplateBuilder, paramToPass);
            } else if (this.templateType === 'CSV Template') {
                paramToPass.isCloned = true;
                this.navigateToComp(navigationComps.csvTemplateBuilder, paramToPass);
            } else if (this.templateType === 'Drag&Drop Template') {
                this.navigateToComp(navigationComps.dNdTemplateBuilder, paramToPass);
            } else if(this.templateType === 'Google Doc Template'){
                this.navigateToComp(navigationComps.googleDocTemplateEditor, paramToPass);
            }
        } catch (error) {
            errorDebugger('CloneTemplate', 'handleNavigate', error, 'warn');
        }
    }
    showToast(status, title, message, duration){
        this.showSpinner = false;
        const messageContainer = this.template.querySelector('c-message-popup-v2')
        messageContainer.showMessageToast({
            status: status,
            title: title,
            message : message,
            duration : duration
        });
    }

    // -=-=- Used to navigate to the other Components -=-=-
    navigateToComp(componentName, paramToPass){
        try {
            var cmpDef;
            if(paramToPass && Object.keys(paramToPass).length > 0){
                cmpDef = {
                    componentDef: `${nameSpace}:${componentName}`,
                    attributes: paramToPass,
                };
            }
            else{
                cmpDef = {
                    componentDef: `${nameSpace}:${componentName}`,
                };
            }
            
            let encodedDef = btoa(JSON.stringify(cmpDef));
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                url:  "/one/one.app#" + encodedDef
                }
            });
        } catch (error) {
            errorDebugger('CloneTemplate', 'navigateToComp', error, 'warn');
        }
    }
}