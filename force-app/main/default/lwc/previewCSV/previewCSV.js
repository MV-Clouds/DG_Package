import { LightningElement, api, track } from 'lwc';
import fetchPreviewData from '@salesforce/apex/PreviewCSVController.fetchPreviewData';
import {navigationComps, nameSpace} from 'c/globalProperties';
import { NavigationMixin } from 'lightning/navigation';

export default class previewCSV extends NavigationMixin(LightningElement) {

    //Passed parameters from component, which redirects user to this component
    @api templateId;
    @api objectName;
    _popup;
    @api get isPopup(){ return this._popup }
    set isPopup(value){ this._popup= value === "true" ?  true : false }
    // @api isPopup = false; 
    @api showAdditionalInfo = false;


    // @track showModel= true;
    @track noResultsFound = false;
    @track noDataFoundText = 'No records match your applied filters, try changing filter...';


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

    connectedCallback(){
        this.getPreviewData();
    }

    getPreviewData(){
        this.showSpinner = true;
        fetchPreviewData({templateId: this.templateId})
        .then((result) =>{
            this.noResultsFound = true;
            console.log('Received preview data::', result);
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
            this.noDataFoundText = 'There was some error fetching preview data, please try again...';
            console.log('error fetching preview data::', e.message);
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
                console.log('in the additional fields');
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
            console.log('Error in setData :', e.message);
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
            console.log('Event Dispatched::');
            this.dispatchEvent(new CustomEvent('close',{
                detail : true
            }));
        }catch(e){
            console.log('Error in handleBackClick ,' , e.message);
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
            console.log('Error in Edit Navigation ', e.stack);
        }finally{
            this.showSpinner = false;
        }
    }

    // //Navigate to CSV Generator
    handleGenerateClick(){
        try{
            this.isGenerate = true;
        }catch(e){
            console.log('Error in Generate Navigation ', e.stack);
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
            // console.log('encodedDef : ', encodedDef);
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