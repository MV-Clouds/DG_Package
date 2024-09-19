import { LightningElement , track, api} from 'lwc';
import getAllObjects from '@salesforce/apex/ButtonGeneratorController.getAllObjects';
import getCombinedData from '@salesforce/apex/NewTemplateCreationController.getCombinedData';
import saveTemplate from '@salesforce/apex/NewTemplateCreationController.saveTemplate';
import { NavigationMixin } from 'lightning/navigation';
import {navigationComps, nameSpace, errorDebugger} from 'c/globalProperties';

export default class NewTemplateCreation extends NavigationMixin(LightningElement) {

    @api showModel;
    @track isShowSpinner = false;
    @track objectNames = [];
    @track templateTypes = [];
    
    isImageLoaded;
    templateId = '';
    templateName = '';
    templateDescription = '';
    selectedObject = '';
    selectedTemplateType = '';
    isDataInvalid = false;
    
    connectedCallback() {
        try {
            this.showSpinner = true;
            this.isImageLoaded = false;
            this.fetchData();
        } catch (e) {
            errorDebugger('newTemplateCreation', 'connectedCallback', e, 'warn');
        }
    }
      
    imageLoaded() {
        this.isImageLoaded = true;
    }
    
    get doShowSpinner() {
        if ( !this.isShowSpinner && this.isImageLoaded === true && this.objectNames.length > 0 && this.templateTypes.length > 0) {
        return false;
        }
        return true;
    }
    fetchData() {
        try {
            this.showSpinner = true; // Start spinner
            getAllObjects()
            .then((data) => {
                if(data) {
                    this.objectNames = data.slice().sort((a, b) => a.label.localeCompare(b.label)).map(obj => {
                        return {
                            ...obj,
                            description : obj.value
                        }
                    })
                    getCombinedData()
                    .then((combinedData) => {
                        if(combinedData){
                            if(combinedData?.templateTypes){
                                this.templateTypes = combinedData.templateTypes.map(type => {
                                    return {
                                        label: type,
                                        value: type,
                                        disabled: type === 'Google Doc Template' ? (!combinedData?.isGoogleIntegrated ? !combinedData?.isGoogleIntegrated : false) : false,
                                    }
                                });
                            }
                        }else{
                            errorDebugger('newTemplateCreation', 'fetchData > getCombinedData', 'Could not fetch template types or integration status', 'warn');
                            this.showToast('error', 'Something went wrong!', 'Could not fetch required data, please try again!', 5000);
                        }
                    }).catch(e=> {
                        this.showToast('error', 'Something went wrong!', 'Could not fetch required data, please try again!', 5000);
                        errorDebugger('newTemplateCreation', 'fetchData > getCombinedData', e, 'warn');
                    });
                }else {
                    this.showToast('error', 'Something went wrong!', 'Could not get all the objects, please try again!', 5000);
                    errorDebugger('newTemplateCreation', 'fetchData > getAllObjects', 'Could not get all the objects', 'warn');
                }
            }).catch(e=> {
                this.showToast('error', 'Something went wrong!', 'Could not fetch required data, please try again!', 5000);
                errorDebugger('newTemplateCreation', 'fetchData > getAllObjects', e, 'warn');
            });
        } catch (e) {
            errorDebugger('newTemplateCreation', 'fetchData', e, 'warn');
        } finally {
            this.showSpinner = false; // End spinner
        }
    }

      
    handleTemplateNameChange(event) {
        try {
            this.isDataInvalid = false;
            this.template.querySelector('.t-name').classList.remove('error-border');
            this.template.querySelectorAll('label')[0].classList.remove('error-label');
            this.templateName = event.target.value.trim();
            if (!this.templateName) {
                this.template.querySelector('.t-name').classList.add('error-border');
                this.template.querySelectorAll('label')[0].classList.add('error-label');
                this.isDataInvalid = true;
            }
        } catch (e) {
            errorDebugger('newTemplateCreation', 'handleTemplateNameChange', e, 'warn');
        }
    }
      
    handleTemplateDescriptionChange(event) {
        try {
            this.templateDescription = event.target.value.trim() ? event.target.value.trim() : '';
        } catch (e) {
            errorDebugger('newTemplateCreation', 'handleTemplateDescriptionChange', e, 'warn');
        }
    }
    
    handleObjectChange(event) {
        try {
            this.selectedObject = event.detail[0];
        } catch (e) {
            errorDebugger('newTemplateCreation', 'handleObjectChange', e, 'warn');
        }
    }
    handleTypeChange(event) {
        try {
            this.selectedTemplateType = event.detail[0];
        } catch (e) {
            errorDebugger('newTemplateCreation', 'handleTypeChange', e, 'warn');
        }
    }
    
    closeModel() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }
    handleNavigate() {
        try {
            let paramToPass = {
                templateId: this.templateId,
                objectName: this.selectedObject,
            };
            if (this.selectedTemplateType === 'Simple Template') {
                this.navigateToComp(navigationComps.simpleTemplateBuilder, paramToPass);
            } else if (this.selectedTemplateType === 'CSV Template') {
                this.navigateToComp(navigationComps.csvTemplateBuilder, paramToPass);
            }else if(this.selectedTemplateType === 'Google Doc Template'){
                this.navigateToComp(navigationComps.googleDocTemplateEditor, paramToPass);
            }
        } catch (e) {
            errorDebugger('newTemplateCreation', 'handleNavigate', e, 'warn');
        }
    }

    saveNewTemplate() {
        this.isShowSpinner = true;
        try {
            this.template.querySelector('.t-name').classList.remove("error-border");
            this.template.querySelectorAll('label')[0].classList.remove("error-label");
            this.template.querySelector('.t-description').classList.remove("error-border");
            this.template.querySelectorAll('label')[1].classList.remove("error-label");
            this.isDataInvalid = false;

            if (!this.templateName) {
                this.template.querySelector('.t-name').classList.add("error-border");
                this.template.querySelectorAll('label')[0].classList.add("error-label");
                this.isDataInvalid = true;
            }
            if (!this.selectedObject) {
                this.template.querySelectorAll('.select-dropdown')[0].isInvalidInput(true);
                this.isDataInvalid = true;
            }
            if (!this.selectedTemplateType) {
                this.template.querySelectorAll('.select-dropdown')[1].isInvalidInput(true);
                this.isDataInvalid = true;
            }
            if(!this.isDataInvalid){
                let templateData = {
                    templateName: this.templateName,
                    templateDescription: this.templateDescription,
                    sourceObject: this.selectedObject,
                    templateType: this.selectedTemplateType
                }
                saveTemplate({ templateData : templateData })
                .then((result) => {
                    if(!result.includes('Error')){
                        this.templateId = result;
                        this.handleNavigate();
                        this.dispatchEvent(new CustomEvent('aftersave'));
                        this.closeModel();
                    }else{
                        this.isShowSpinner = false;
                        errorDebugger('newTemplateCreation', 'saveNewTemplate > saveTemplate > failure', result, 'warn');
                        if( result.includes('STORAGE_LIMIT_EXCEEDED')){
                            this.showToast('error', 'Storage Limit Exceeded!', 'You are running out of your data storage, please clean up data and try again...', 5000);
                        }else{
                            this.showToast('error', 'Something went wrong!', 'There was error saving the template...');
                        }
                    }
                })
                .catch(e => {
                    this.showToast('error', 'Something went wrong!', 'There was error saving the template...', 5000);
                    errorDebugger('newTemplateCreation', 'saveNewTemplate > saveTemplate > failure', e, 'warn');
                });
            }else{
                this.isShowSpinner = false;
            }
        } catch (e) {
            this.isShowSpinner = false;
            errorDebugger('newTemplateCreation', 'saveNewTemplate', e, 'warn');
        }
    }

    showToast(status, title, message){
        const messageContainer = this.template.querySelector('c-message-popup')
        messageContainer.showMessageToast({
            status: status,
            title: title,
            message : message,
            duration : 5000
        });
        this.isShowSpinner = false;
    }
      

// -=-=- Used to navigate to the other Components -=-=-
    navigateToComp(componentName, paramToPass){
        try {
            let cmpDef;
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
        } catch (e) {
            errorDebugger('newTemplateCreation', 'navigateToComp', e, 'warn');
        }
    }
}