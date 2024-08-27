import { LightningElement, api, track, wire } from "lwc";
import previewModalImg from "@salesforce/resourceUrl/previewModal_img";
import getObjectNameField from '@salesforce/apex/TemplateBuilder_Controller.getObjectNameField';

export default class TemplatePreviewModal extends LightningElement {

    @api templateid;
    @api objectname;
    @api recordId;
    @api templateType;

    _isCalledFromGenerateDoc;
    @api get isCalledFromGenerateDoc(){ return this._isCalledFromGenerateDoc }
    set isCalledFromGenerateDoc(value){ this._isCalledFromGenerateDoc = (value === "true" ||  value === true) ? true : false  }

    _isActive
    @api get isActive(){ return this._isActive}
    set isActive(value){ this._isActive = (value === "true" ||  value === true) ? true : false }

    @track previewModalImg = previewModalImg;
    @track spinnerLabel = null;

    @track objectRecordList = null;
    @track selectedRecordId = null;

    @track isSpinner = false;
    @track showPreview;
    @track vfPageSRC; 
    @track errorDetail = {};

    customSetTimeout;
    customSetTimeoutMethod;

    @track objectLabel = '';
    @track recordLabelField;
    @track recordLabelFieldType;
    @track searchByField;

    // @track filters = [
    //     {
    //         or : [
    //             {field : 'Name', operator : 'eq', value : 'test now'}
    //         ]
    //     }  
    // ]


    get popUpStyle(){
        if(!this.isCalledFromGenerateDoc){
            return `
            position : fixed;
            background: rgb(0 0 0 / 65%);
            `;
        }
        return ``;
    }

    get widthStyleForGeneratePreview(){
        if(this.isCalledFromGenerateDoc){
            return `
            width: 100% !important;
            `;
        }
        return ``;
    }
    
    get label(){
        return `Select ${this.objectLabel} record`;
    }

    get placeHolder(){
        return `Search ${this.objectLabel} by Name or Id...`;
    }

    get helpText(){
       return `Select ${this.objectLabel} Record To Dispay Data on Template.`;
    }

    get disableRecordPicker(){
        return this.recordId ? true : false;
    }

    get disablePreviewBtn(){
        return !this.selectedRecordId;
    }

    get disableGenerateBtn(){
        return !this.selectedRecordId || !this.isActive;
    }

    get loadingInfo(){
        var info = `To generate a preview, please select any ${this.objectLabel} record first.`;
        return this.isSpinner === false ? info : `Generating Preview...`
    }

    get isSimpleTemplatePreview(){
        return this.templateType === 'Simple Template' ? true : false;
    }

    connectedCallback(){
        try {
            // Set pre-selected Record Id...
            if(this.recordId){
                this.selectedRecordId = this.recordId;
                this.generatePreview();
            }
            else{
                this.isSpinner = true;
                getObjectNameField({objectApiName: this.objectname})
                .then(result => {
                    console.log('getObjectNameField :  ', result);
                    this.objectLabel = result.label;
                    this.recordLabelField = result.nameField;
                    if(result.nameFieldType === 'NUMBER' || result.nameFieldType === 'PERCENTAGE' || result.nameFieldType === 'CURRENCY'){
                        this.recordLabelFieldType = 'number';
                    }
                    else{
                        this.recordLabelFieldType = 'text';
                    }
                })
                .catch(() => {
                    this.recordLabelField = 'Id';
                    this.recordLabelFieldType = 'text';
                })
                .finally(() => {
                    this.searchByField = `${this.recordLabelField}`;
                    this.isSpinner = false;
                })
            }

            // this.vfPageMessageHandler();

        } catch (error) {
            console.warn('error in TemplatePreviewModal > connectedCallback', error.message);
        }
    }

    renderedCallback(){
        try {
        } catch (error) {
            console.warn('error in TemplatePreviewModal > renderedCallback : ', error.message);
        }
    }

    onRecordSelect(event){
        try {
            if(event.detail && event.detail.length){
                this.selectedRecordId = event.detail[0].Id;
            }
            else{
                this.selectedRecordId = null;
            }
        } catch (error) {
            console.warn('error in TemplatePreviewModal > onRecordSelect', error.message);
        }
    }

    handleRecordPickerError(event){
        console.warn('handleRecordPickerError : ', event.detail);
    }

    generatePreview(){
        try {
            if(this.templateType === 'Simple Template'){
                this.spinnerLabel = 'Generating Preview...';
                this.isSpinner = true;
                this.showPreview = false;

                var previousSRC = this.vfPageSRC;
    
                var paraData = {
                    'templateId' : this.templateid,
                    'MVDG__Object_API_Name__c' : this.objectname,
                    'recordId' : this.selectedRecordId,
                    'useMode' : 'preview',
                }
                var paraDataStringify = JSON.stringify(paraData);

                // var newSRC = '/apex/DocGeneratePage?paraData=' + paraDataStringify;
                var newSRC = '/apex/MVDG__DocGeneratePage?paraData=' + paraDataStringify;
    
                if(newSRC !== previousSRC){
                    this.vfPageSRC = newSRC;
                    this.showPreview = true;

                    // setTimeout(() => {
                    //     this.updateSpinnerLabel('We are Almost There... Please wait a while...');
                    // }, 4000)

                    this.template.querySelector('[data-id="previewTimeout"]')?.setCustomTimeoutMethod(() => {
                        this.updateSpinnerLabel('We are Almost There... Please wait a while...');
                    }, 4000);
                }
                else{
                    // this.vfPageSRC = '/apex/DocGeneratePage';
                    this.vfPageSRC = '/apex/MVDG__DocGeneratePage';

                    // setTimeout( () => {
                    //     this.vfPageSRC = newSRC;
                    //     this.showPreview = true;

                    //     this.template.querySelector('[data-id="previewTimeout"]')?.setCustomTimeoutMethod(() => {
                    //         this.updateSpinnerLabel('We are Almost There... Please wait a while...')
                    //     }, 4000);
                    // }, 100)

                    this.template.querySelector('[data-id="previewTimeout"]')?.setCustomTimeoutMethod(() => {
                        this.vfPageSRC = newSRC;
                        this.showPreview = true;

                        this.template.querySelector('[data-id="previewTimeout"]')?.setCustomTimeoutMethod(() => {
                            this.updateSpinnerLabel('We are Almost There... Please wait a while...')
                        }, 4000);
                    }, 400);
                }
            }
            else if(this.templateType === 'Google Doc Template'){
                 this.isSpinner = false;
                this.showPreview = true;
                setTimeout(() => {
                    this.generateGoogleDocPreview();
                }, 300)
                // this.template.querySelector('[data-id="previewTimeout"]')?.setCustomTimeoutMethod( () => {
                //     this.generateGoogleDocPreview()
                // }, 300);
            }
        } catch (error) {
            console.warn('error in TemplatePreviewModal > previewData', error.message);
        }
    }

    generateGoogleDocPreview(){
        this.template.querySelector('c-preview-google-document').previewDocument();
    }

    contentLoaded(){
        try {
            this.isSpinner = false;
            this.spinnerLabel = 'Ready to Preview...';
        } catch (error) {
            console.warn('error in TemplatePreviewModal > contentLoaded', error.message);
        }
    }
  
    fileDownloaded(){
        this.isSpinner = false;
    }

    updateSpinnerLabel(labelToUpdate){
        if(this.isSpinner && this.spinnerLabel !== 'Your Document took a little long... Thank you for your patience...'){
            this.spinnerLabel = labelToUpdate;

            // setTimeout(() => {
            //     this.updateSpinnerLabel('Your Document took a little long... Thank you for your patience...')
            // }, 5000)

            this.template.querySelector('[data-id="previewTimeout"]')?.setCustomTimeoutMethod(() => {
                this.updateSpinnerLabel('Your Document took a little long... Thank you for your patience...')
            }, 5000);
        }
    }

    @track isGenerate = false;
    generateDocument(){
        try {
            this.isGenerate = true;
        } catch (error) {
            console.warn('error in TemplatePreviewModal > generateDocument : ', error.message);
        }
    }

    closeTemplatePreview(){
        try {
            this.showPreview = true;
            this.dispatchEvent(new CustomEvent('closepreview'));
        } catch (error) {
            console.warn('error in TemplatePreviewModal > closeTemplatePreview', error.message);
        }
    }

    closeGenerate(){
        this.isGenerate = false;
    }

    runTimeoutMethod(event){
        if(event?.detail?.function){
            event.detail.function();
        }
    }

}