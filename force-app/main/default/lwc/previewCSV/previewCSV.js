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
    @api showAdditionalInfo = false;
    @track noResultsFound = false;
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

    get loadStyle(){
        if(this.isPopup){
            return `
                    position: absolute;
                    width: min(80%, 60rem);
                    height: 90%;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
            `
        }
        return ``;
    }

    connectedCallback(){
        this.getPreviewData();
    }

    getPreviewData(){
        this.showSpinner = true;
        fetchPreviewData({templateId: this.templateId})
        .then((result) =>{
            this.noResultsFound = true;
            this.previewData = result.records;
            this.fields = result.fields?.split(',');
            this.additionalData['Name'] = result.templateName;
            this.additionalData['Object Api Name'] = result.templateObject;
            this.additionalData['Description'] = result.templateDescription || 'No Description Available for this template';
            this.additionalData['CSV Creation Time'] = new Date().toLocaleString().replace(',', ' ');
            if(this.fields.length > 0 && this.previewData.length > 0){
                this.setData();
                this.noResultsFound = false;
            }
            this.showSpinner = false;
        })
        .catch(e=>{
            errorDebugger('previewCSV', 'getPreviewData', e, 'warn');
            this.showSpinner = false;
        })
    }

    setData() {
        this.showSpinner = true;
        try{
            // Ensure data is received before processing
            if (!this.previewData || !this.fields) {
                return;
            }
        
            const tableBody = this.template.querySelector('tbody');
            tableBody.innerText = '';

            // Display additional fields if checkbox is ticked
            if(this.showAdditionalInfo){
                this.additionalFields.forEach(field => {
                    const tableRow = document.createElement('tr');
                    tableRow.style.cssText = `
                        border : 1px solid darkgray;
                        text-align : center;
                    `;
                    const emptyTableCell = document.createElement('td');
                    emptyTableCell.style.cssText = `
                            border : 1px solid darkgray;
                            text-align : center;
                            padding: 0.1rem 0.5rem;
                    `;
                    tableRow.appendChild(emptyTableCell);
                    const fieldNameCell = document.createElement('th');
                    fieldNameCell.style.cssText = `
                            border : 1px solid darkgray;
                            text-align : center;
                            padding: 0.1rem 0.5rem;
                            background-color: #d5ebff;
                    `;
                    fieldNameCell.textContent = field+' :';
                    tableRow.appendChild(fieldNameCell);
                    const fieldDataCell = document.createElement('td');
                    fieldDataCell.style.cssText = `
                            border : 1px solid darkgray;
                            text-align : center;
                            padding: 0.1rem 0.5rem;
                    `;
                    fieldDataCell.textContent = this.additionalData[field] || ''; // Display empty string for missing values
                    tableRow.appendChild(fieldDataCell);
                    tableBody.appendChild(tableRow);
                });
                const emptyTableRow = document.createElement('tr');
                emptyTableRow.style.cssText = `
                    border : 1px solid darkgray;
                    text-align : center;
                    height : 1.3rem;
                `;
                tableBody.appendChild(emptyTableRow);
            }
            
        
            // Update header row (optional)
            // const tableHead = this.template.querySelector('tbody tr');
            const tableHead = document.createElement('tr');
            tableHead.style.cssText = `
                background-color: #d5ebff;
                height: 1.5rem;
                position : sticky;
                top : -1px;
                z-index : 1;
            `;
            if (tableHead) {
                tableHead.innerText = '';
                this.fields.forEach(field => {
                const tableHeaderCell = document.createElement('th');
                tableHeaderCell.style.cssText = `
                        border : 1px solid darkgray;
                        text-align : center;
                        background-color: #d5ebff;
                        padding: 0.3rem 0.5rem;
                `;
                tableHeaderCell.textContent = field; // Set header text based on field names
                tableHead.appendChild(tableHeaderCell);
                });
                tableBody.appendChild(tableHead);
            }
            this.previewData.forEach(record => {
                const tableRow = document.createElement('tr');
                tableRow.style.cssText = `
                    border : 1px solid darkgray;
                    text-align : center;
                `;
        
                // Display only fields specified in 'fields'
                this.fields.forEach(field => {
                const tableCell = document.createElement('td');
                tableCell.style.cssText = `
                        border : 1px solid darkgray;
                        text-align : center;
                        padding: 0.1rem 0.5rem;
                `;
                tableCell.textContent = this.getValueByKey(record, field) || ''; // Display empty string for missing values
                tableRow.appendChild(tableCell);
                });
        
                tableBody.appendChild(tableRow);
            });
        
        }catch(e){
            errorDebugger('previewCSV', 'setData', e, 'warn');
        }finally{
            this.showSpinner = false;
        }
    }

    getValueByKey(obj, key) {
        return key.split('.').reduce((o, i) => (o ? o[i] : undefined), obj);
    }

    // Get Back to the Document Generator
    handleBackClick(){
        try{
            this.dispatchEvent(new CustomEvent('close',{
                detail : true
            }));
        }catch(e){
            errorDebugger('previewCSV', 'handleBackClick', e, 'warn');
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
            errorDebugger('previewCSV', 'navigateToComp', e, 'error');
        }
    }
}