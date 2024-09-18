import { LightningElement , api, track } from 'lwc';
import cloneTemplateImage from '@salesforce/resourceUrl/clone_template_image';
import newTemplateBg from '@salesforce/resourceUrl/new_template_bg';
import cloneTempData from '@salesforce/apex/CloneTemplateDataController.cloneTempData'
// import { NavigationMixin } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import {navigationComps, nameSpace} from 'c/globalProperties';


export default class CloneTemplate extends NavigationMixin(LightningElement) {
  
    @api templatelist;
    @api selectedtemplateid;
    @api showModel;

    @track templateId;
    @track templateName;
    @track templateDescription;
    @track trmplateObject;
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
        console.log('template *** : ',JSON.stringify(template));
        this.templateId =  template.Id;
        this.templateName = template.MVDG__Template_Name__c+'-copy';
        this.templateDescription = template.MVDG__Description__c;
        if(this.templateDescription == undefined || this.templateDescription == null){
            this.templateDescription='';
        }
        this.trmplateObject = template.MVDG__Object_API_Name__c;
        this.templateType = template.MVDG__Template_Type__c;
        console.log('this.templateType *** : ',this.templateType);
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
        if (!this.templateName) {
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
            this.templateDescription = this.template.querySelector(`[data-name="temp-description"]`).value;
            console.log("templateType *** : ",this.templateType);
            if(this.templateType == 'Simple Template'){
                let templateBody = this.template.querySelector(`[data-name="templateBody"]`).checked;
                console.log('templateBody *** : ',templateBody);
                // let watermark = this.template.querySelector(`[data-name="watermark"]`).checked;
                // console.log('watermark *** : ',watermark);
                let header = this.template.querySelector(`[data-name="header"]`).checked;
                console.log('header *** : ',header);
                let pageConfiguration = this.template.querySelector(`[data-name="pageConfiguration"]`).checked;
                console.log('pageConfiguration *** : ',pageConfiguration);
                let footer = this.template.querySelector(`[data-name="footer"]`).checked;
                console.log('footer *** : ',footer);
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
                console.log('selectedFields *** : ',selectedFields);
                let fieldsFilters = this.template.querySelector(`[data-name="fieldsFilters"]`).checked;
                console.log('fieldsFilters *** : ',fieldsFilters);
                let fieldOrderBy = this.template.querySelector(`[data-name="fieldOrderBy"]`).checked;
                console.log('fieldOrderBy *** : ',fieldOrderBy);
                let fieldLimit = this.template.querySelector(`[data-name="fieldLimit"]`).checked;
                console.log('fieldLimit *** : ',fieldLimit);
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
                // console.log('jsonData *** : ',jsonData);
                this.templateSelectOption = jsonData;
            }
            console.log('this is a test log ');
            cloneTempData({templateId: this.templateId, jsonData: this.templateSelectOption })
            .then(response=>{
                console.log('This is a Test Log *** : ',response);
                this.templateId = response.tempId;
                this.trmplateObject = response.tempObj;
                this.handleNavigate();
                if (typeof window !== 'undefined') {
                    this.dispatchEvent(new CustomEvent('aftersave'));
                }
                this.closeModel();
            }).catch(error=>{
                this.isShowSpinner = false;
                console.log('error in apex cloneTempData : ', error);
                console.log('error in apex cloneTempData : ', error.stack);
            })
        } catch (error) {
            this.isShowSpinner = false;
            console.log('error in cloneTemplate : ', error.stack);
        }
    }

    handleNavigate() {
        try {
            console.log('selected Template Type: ' + this.selectedTemplateType);
            var paramToPass = {
                templateId: this.templateId,
                objectName: this.trmplateObject,
            };
            if (this.templateType === 'Simple Template') {
                console.log('Navigating to simple template....... ' + this.templateId);
                this.navigateToComp(navigationComps.simpleTemplateBuilder, paramToPass);
            } else if (this.templateType === 'CSV Template') {
                console.log('Navigating to CSV template....... ');
                this.navigateToComp(navigationComps.csvTemplateBuilder, paramToPass);
            } else if (this.templateType === 'Drag&Drop Template') {
                console.log('Navigating to Drag&Drop template....... ');
                this.navigateToComp(navigationComps.dNdTemplateBuilder, paramToPass);
            } else if(this.templateType === 'Google Doc Template'){
                this.navigateToComp(navigationComps.googleDocTemplateEditor, paramToPass);
            }
        } catch (error) {
            console.error('Error in handleNavigate:', error.message);
        }
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
            console.log('encodedDef : ', encodedDef);
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                url:  "/one/one.app#" + encodedDef
                }
            });
        } catch (error) {
            console.log('error in navigateToComp : ', error.stack);
        }
    }
}