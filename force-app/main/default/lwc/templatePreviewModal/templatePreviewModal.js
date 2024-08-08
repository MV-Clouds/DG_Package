import { LightningElement, api, track, wire } from "lwc";
import previewModalImg from "@salesforce/resourceUrl/previewModal_img";
import getObjectNameField from '@salesforce/apex/TemplateBuilder_Controller.getObjectNameField';

export default class TemplatePreviewModal extends LightningElement {

    @api templateid;
    @api objectname;
    @api recordId;
    @api templateType;

    _label;
    @api get isCalledFromGenerateDoc(){ return this._label }
    set isCalledFromGenerateDoc(value){ value === "true" ? this._label= true : this._label = false }

    @track previewModalImg = previewModalImg;
    @track spinnerLabel = null;

    @track objectRecordList = null;
    @track selectedRecordId = null;

    @track isSpinner = false;
    @track vfPageSRC; 
    @track vfGeneratePageSRC;
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

    get disableGenerateBtn(){
        return this.selectedRecordId ? false : true;
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
    
                // var newSRC = '/apex/DocPreviewPage?paraData=' + paraDataStringify;
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
                    }, 100);
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


    // ========= ========== ============ ========== ========== ========= GENERIC Method ========= ========== ============ ========== ========== =========
     // Generic Method to test Message Popup and Toast
     showMessagePopup(Status, Title, Message){
        const messageContainer = this.template.querySelector('c-message-popup');
        console.log('messageContainer : ', messageContainer);
        if(messageContainer){
            messageContainer.showMessagePopup({
                status: Status,
                title: Title,
                message : Message,
            });
        }
    }

    showMessageToast(Status, Title, Message, Duration){
        const messageContainer = this.template.querySelector('c-message-popup')
        if(messageContainer){
            messageContainer.showMessageToast({
                status: Status,
                title: Title,
                message : Message,
                duration : Duration
            });
        }
    }

    // === === === === Custom Timeout Methods -- START --- === === === ====
    // customTimeoutProcessList = [];
    // usedTimeoutProcessNumber = [];
    // setCustomTimeoutMethod(methodToRun, delayTime){
    //     try {
    //         let maxTimeoutProcesses = 10
    //         if(this.customTimeoutProcessList.length < maxTimeoutProcesses){
    //             const timeoutProcessInstance = {
    //                 // ** Add Method into variable which you want run after timeout...
    //                 delay : delayTime,
    //                 method : methodToRun,
    //                 name : `customSetTimeout${this.setProcessNumber()}`,
    //                 processNumber : this.setProcessNumber(),
    //             }
                
    //             this.customTimeoutProcessList.push(timeoutProcessInstance);
    //             console.log('timeout method in queue ', this.customTimeoutProcessList.length);
    //             this.addedEventListener(timeoutProcessInstance);
    //         }
    //         else{
    //             console.warn('you have reach maximum limit of custom settimeout')
    //         }

    //     } catch (error) {
    //         console.warn('error in setCustomTimeoutMethod : ', error.stack);
    //     }
    // }

    // addedEventListener(method){
    //     try {
    //         const customSetTimeoutDiv = this.template.querySelector(`[data-name="${method.name}"]`);
    //         if(customSetTimeoutDiv){
    //             customSetTimeoutDiv.addEventListener('animationend', this.executeTimeoutMethod);

    //             // ** Add setTimeout time into CSS variable...
    //             customSetTimeoutDiv.style.setProperty('--timeoutTime', `${method.delay}ms`);
    //             // ** Add css class to start timeout animation.. at end of this animation, settimeout method will run....
    //             customSetTimeoutDiv.classList.add('setTimeAnimation');
    //         }
    //     } catch (error) {
    //         console.warn('error in addedEventListener : ', error.stack);
    //     }
    // }

    // // Use Arrow Function for EventListener Method....
    // executeTimeoutMethod = (event) =>{
    //     try {
    //         // ** This method will at the end of the animation...
    //         let processNumber;
    //         this.customTimeoutProcessList.forEach(ele =>{
    //             if(ele.name === event.target.dataset.name){
    //                 // ** Remove eventLister and animation class once method run...
    //                 event.target.removeEventListener('animationend', null);
    //                 event.target.classList.remove('setTimeAnimation');
    //                 processNumber = ele.processNumber;

    //                 // ** Run Timeout method...
    //                 try {
    //                     ele.method();
    //                 } catch (error) {
    //                     console.warn('error in executeTimeoutMethod for : ', error.message);
    //                 }
    //             }
    //         });

    //         this.customTimeoutProcessList = this.customTimeoutProcessList.filter(ele => ele.processNumber !== processNumber);
    //         this.usedTimeoutProcessNumber = this.usedTimeoutProcessNumber.filter(ele => ele !== processNumber);

    //         console.log('timeout method in queue ', this.customTimeoutProcessList.length);
    //     } catch (error) {
    //         console.log('error in executeTimeoutMethod : ', error.stack);
    //     }
    // }

    // setProcessNumber(){
    //     if(!this.usedTimeoutProcessNumber.includes(this.customTimeoutProcessList.length)){
    //         this.usedTimeoutProcessNumber.push(this.customTimeoutProcessList.length);
    //         return this.customTimeoutProcessList.length;
    //     }
    //     else{
    //         for(let i = 0; i < 9; i++){
    //             if(!this.usedTimeoutProcessNumber.includes(i)){
    //                 this.usedTimeoutProcessNumber.push(i);
    //                 return i;
    //             }
    //         }
    //     }

    //     return 0;
    // }

    // === === === === Custom Timeout Methods -- END --- === === === ====

}