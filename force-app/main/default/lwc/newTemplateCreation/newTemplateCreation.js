import { LightningElement , api, track} from 'lwc';
import getAllObjects from '@salesforce/apex/ButtonGeneratorController.getAllObjects';
import getTemplateTypes from '@salesforce/apex/NewTemplateCreationController.getTemplateTypes';
import saveTemplate from '@salesforce/apex/NewTemplateCreationController.saveTemplate';
import isGoogleIntegrated from '@salesforce/apex/NewTemplateCreationController.isGoogleIntegrated';
import { NavigationMixin } from 'lightning/navigation';
import {navigationComps, nameSpace} from 'c/globalProperties';

export default class NewTemplateCreation extends NavigationMixin(LightningElement) {

    @api showModel;
    @track showSpinner;
    @track objectNames = [];
    @track templateTypes = [];
    @track cellDivs = [];
    
    isImageLoaded;
    templateId = '';
    templateName = '';
    templateDescription = '';
    selectedObject = '';
    selectedTemplateType = '';
    isDataInvalid = false;
    selectedRows = null;
    selectedColumns = null;
    totalRows = 5;
    totalColumns = 3;
    
    connectedCallback() {
        try {
            this.showModel = true;
            this.showSpinner = true;
            this.isImageLoaded = false;
            this.fetchData();
            this.createDivs();
        } catch (error) {
            console.error('Error in connectedCallback:', error.message);
        }
    }
      
    imageLoaded() {
        this.isImageLoaded = true;
    }
    
    get doShowSpinner() {
        if (this.isImageLoaded === true && this.objectNames.length > 0 && this.templateTypes.length > 0) {
        return false;
        }
        return true;
    }
    
    createDivs() {
        try {
            this.cellDivs = [];
            for (let i = 0; i < 5; i++) {
                for (let j = 0; j < 3; j++) {
                i === 0 && j === 0
                    ? this.cellDivs.push('table-cell unselected-cell selected-cell d' + i + '' + j)
                    : this.cellDivs.push('table-cell unselected-cell d' + i + '' + j);
                }
            }
        } catch (error) {
            console.error('Error in createDivs:', error.message);
        }
    }
    fetchData() {
        try {
            this.showSpinner = true; // Start spinner
            getAllObjects()
            .then((data) => {
                if (data) {

                    // Process object names
                    this.objectNames = data.slice().sort((a, b) => a.label.localeCompare(b.label))

                    isGoogleIntegrated()
                    .then((isIntegrated) => {

                        getTemplateTypes()
                        .then((result) => {
                            this.templateTypes = result.map(type => {
                                return {
                                    label: type,
                                    value: type,
                                    disabled: type === 'Google Doc Template' ? !isIntegrated : false,
                                }
                            });
                        }).catch(error => {
                            console.log('error in getTemplateTypes==>', error.message);
                        });
                        
                    }).catch(error => {
                        console.log('error in isGoogleIntegrated==>', error.message);
                    });
                } else {
                    console.error('Error fetching object info: No data returned');
                }
            }).catch(error => {
                console.log('error in getObjects==>', error.message);
            });
    
        } catch (error) {
            console.error('Error in fetchData:', error.stack); // Log error stack
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
        } catch (error) {
            console.error('Error in handleTemplateNameChange:', error.message);
        }
    }
      
    handleTemplateDescriptionChange(event) {
        try {
            this.templateDescription = event.target.value.trim() ? event.target.value.trim() : '';
        } catch (error) {
            console.error('Error in handleTemplateDescriptionChange:', error.message);
        }
    }
    
    handleObjectChange(event) {
        try {
            this.selectedObject = event.detail[0];
            if (this.selectedObject) {
                this.template.querySelectorAll('.select-dropdown')[0].classList.remove('error-combo-box');
            } else {
                this.template.querySelectorAll('.select-dropdown')[0].classList.add('error-combo-box');
            }
        } catch (error) {
            console.error('Error in handleObjectChange:', error.message);
        }
    }
    handleTypeChange(event) {
        try {
            this.selectedTemplateType = event.detail[0];
            if (this.selectedTemplateType) {
                this.template.querySelectorAll('.select-dropdown')[1].classList.remove('error-combo-box');
            } else {
                this.template.querySelectorAll('.select-dropdown')[1].classList.add('error-combo-box');
            }
        } catch (error) {
            console.error('Error in handleTypeChange:', error.message);
        }
    }
    
    closeModel() {
        const closeModalEvent = new CustomEvent('closemodal');
        this.dispatchEvent(closeModalEvent);
    }
    handleNavigate() {
        try {
            console.log('selected Template Type: ' + this.selectedTemplateType);
            let paramToPass = {
                templateId: this.templateId,
                objectName: this.selectedObject,
                isNew: true
            };
            if (this.selectedTemplateType === 'Simple Template') {
                this.navigateToComp(navigationComps.simpleTemplateBuilder, paramToPass);
            } else if (this.selectedTemplateType === 'CSV Template') {
                this.navigateToComp(navigationComps.csvTemplateBuilder, paramToPass);
            }else if(this.selectedTemplateType === 'Google Doc Template'){
                this.navigateToComp(navigationComps.googleDocTemplateEditor, paramToPass);
            }
        } catch (error) {
            console.error('Error in handleNavigate:', error.message);
        }
    }

    saveNewTemplate() {
        try {
            this.template.querySelector('.t-name').classList.remove("error-border");
            this.template.querySelectorAll('label')[0].classList.remove("error-label");
            this.template.querySelector('.t-description').classList.remove("error-border");
            this.template.querySelectorAll('label')[1].classList.remove("error-label");
            this.template.querySelectorAll('.select-dropdown').forEach(element => {
                element.classList.remove("error-combo-box");
            });
            this.isDataInvalid = false;

            if (!this.templateName) {
                this.template.querySelector('.t-name').classList.add("error-border");
                this.template.querySelectorAll('label')[0].classList.add("error-label");
                this.isDataInvalid = true;
            }
            if (!this.selectedObject) {
                this.template.querySelectorAll('.select-dropdown')[0].classList.add("error-combo-box");
                this.isDataInvalid = true;
            }
            if (!this.selectedTemplateType) {
                this.template.querySelectorAll('.select-dropdown')[1].classList.add("error-combo-box");
                this.isDataInvalid = true;
            }
            if(!this.isDataInvalid){
                this.isImageLoaded = false;
                let templateData = {
                    templateName: this.templateName,
                    templateDescription: this.templateDescription,
                    sourceObject: this.selectedObject,
                    templateType: this.selectedTemplateType
                }
                saveTemplate({ templateData : templateData })
                .then((data) => {
                    this.templateId = data;
                    this.showToast('success', 'Everything worked!', 'The Template was saved Successfully!');
                    this.handleNavigate();
                    this.dispatchEvent(new CustomEvent('aftersave'))
                    this.closeModel();

                })
                .catch(error => {
                    console.error('Error saving template:', error);
                    this.showToast('error', 'Something went wrong!', 'There was error saving the template...');
                });
            }
        } catch (error) {
            console.error('Error in saveNewTemplate:', error.message);
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
        this.isImageLoaded = true;
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