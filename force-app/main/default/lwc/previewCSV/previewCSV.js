import { LightningElement, api, track } from 'lwc';
import fetchPreviewData from '@salesforce/apex/PreviewCSVController.fetchPreviewData';
import {navigationComps, nameSpace, errorDebugger} from 'c/globalProperties';
import { NavigationMixin } from 'lightning/navigation';

export default class previewCSV extends NavigationMixin(LightningElement) {

    //Passed parameters from component, which redirects user to this component
    @api templateId;
    @api objectName;
    _popup;
    @api get isPopup(){ return this._popup }
    set isPopup(value){ this._popup= value === "true" ?  true : false }

    _previewFromEditor;
    @api get previewFromEditor(){ return this._previewFromEditor }
    set previewFromEditor(value){ this._previewFromEditor= value === "true" ?  true : false }
    
    @track _showAdditionalInfo = false;

    @api
    set showAdditionalInfo(value) { this._showAdditionalInfo = value;}
    get showAdditionalInfo() { return this._showAdditionalInfo; }
    
    @track noResultsFound = false;
    @track noDataFoundText = 'Could not found any data to preview, update template and try again...';

    //to show spinner
    @track showSpinner = false;

    // Preview Data
    @track previewData;
    @track fields;
    additionalFields = ['Name', 'Description', 'Object Api Name', 'CSV Creation Time'];
    additionalData = {
        'Name' : '',
        'Description' : '',
        'Object Api Name' :'',
        'CSV Creation Time': ''
    }

    @track isGenerate = false;
    @track isTemplateInactive = false;

    get tableData() {
        return this.previewData?.map(record => {
            return this.fields?.map(field => ({
                field,
                value: this.getValueByKey(record, field) || ' '
            }));
        });
    }

    get additionalInfo() {
        return this.additionalFields.map(field => ({
            field,
            value: field === 'CSV Creation Time' ? new Date().toLocaleString().replace(',', ' ') :this.additionalData[field] || ''
        }));
    }

    get canNotGenerate(){
        return this.noResultsFound || this.isTemplateInactive;
    }

    connectedCallback(){
        this.getPreviewData();
    }

    getPreviewData(){
        this.showSpinner = true;
        try{
            fetchPreviewData({templateId: this.templateId})
            .then((result) =>{
                this.noResultsFound = true;
                if(result.errorMessage){
                    this.noDataFoundText = 'There was some error fetching preview data, please try again...';
                    let regex = /No such column '(\w+)' on entity '(\w+)'/;
                    let match = result.errorMessage.match(regex);
                    let fieldName = match ? match[1] : null;
                    let entityName = match ? match[2] : null;
                    if(match && fieldName && entityName){
                        this.noDataFoundText = 'Please check permission of the field \''+ fieldName + '\' on object \'' + entityName + '\'.';
                    }
                    this.showSpinner = false;
                    return;
                }
                this.previewData = result.records;
                this.fields = result.templateData.MVDG__CSV_Fields__c?.split(',');
                this.additionalData['Name'] = result.templateData.MVDG__Template__r.MVDG__Template_Name__c;
                this.additionalData['Object Api Name'] = result.templateData.MVDG__Template__r.MVDG__Object_API_Name__c;
                let description = result.templateData.MVDG__Template__r.MVDG__Description__c || '-';
                description = description.length > 50 ? description.slice(0,50)+'...' : description;
                this.additionalData['Description'] = description;
                this.isTemplateInactive = !result.templateData.MVDG__Template__r.MVDG__Template_Status__c;
                this.additionalData['CSV Creation Time'] = new Date().toLocaleString().replace(',', ' ');
                if(!this.fields || this.fields?.length < 1){
                    this.noDataFoundText = 'No columns selected, select columns to see preview...';
                    this.showSpinner = false;
                    return;
                }
                if(!this.previewData || this.previewData.length < 1){
                    this.noDataFoundText = "No matching records to preview, try updating the filters...";
                    this.showSpinner = false;
                    return;
                }
                this.noResultsFound = false;
                this.showSpinner = false;
            })
            .catch(e=>{
                this.noDataFoundText = 'There was some error fetching preview data, please try again...';
                errorDebugger('previewCSV', 'fetchPreviewData', e, 'warn');
                this.showSpinner = false;
            })
        }catch(e){
            this.showSpinner = false;
            errorDebugger('previewCSV', 'getPreviewData', e, 'warn');
        }
    }

    getValueByKey(obj, key) {
        return key.split('.').reduce((o, i) => (o ? o[i] : undefined), obj);
    }

    toggleAdditionalInfoDiv(){
        try {
            this._showAdditionalInfo = !this._showAdditionalInfo;
        } catch (e) {
            errorDebugger('previewCSV', 'toggleAdditionalInfoDiv', e, 'warn');
        }
    }

    // Get Back to the Document Generator
    handleClose(){
        try{
            this.dispatchEvent(new CustomEvent("close"));
        }catch(e){
            errorDebugger('previewCSV', 'handleClose', e, 'warn');
        }
    }

    //Navigate to CSV template builder
    handleEditClick() {
        try{
            this.showSpinner = true;
            let paramToPass = {
                templateId : this.templateId,
                objectName : this.objectName,
            }
            this.navigateToComp(navigationComps.csvTemplateBuilder, paramToPass);
        }catch(e){
            errorDebugger('previewCSV', 'handleEditClick', e, 'warn');
        }finally{
            this.showSpinner = false;
        }
    }

    // //Navigate to CSV Generator
    handleGenerateClick(){
        try{
            this.isGenerate = true;
        }catch(e){
            errorDebugger('previewCSV', 'handleGenerateClick', e, 'warn');
        }
    }

    closeGenerate(){
        this.isGenerate = false;
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
            errorDebugger('previewCSV', 'navigateToComp', e, 'warn');
        }
    }
}