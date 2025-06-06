import { LightningElement,wire, track } from 'lwc';
import getRelatedRecords from '@salesforce/apex/RelatedListController.getRelatedRecords';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class RelatedRecordList extends LightningElement {
    parentId;
    objectname;
    parentObj;
    relationshipName;
    fields = [];

    @track records = [];
    @track selectedIds = [];
    @track showLimitError = false;
    

    columns = [
        {
            label: 'Index',
            fieldName: 'index',
            type: 'number',
            initialWidth: 80, // smaller width
            cellAttributes: { alignment: 'center' } // center alignment
        }
    ];

    get isDisable(){
        if(this.selectedIds.length === 0){
            return true;
        }else{
            return false;
        }
    }

    get indexedRecords() {
        console.log(this.records.map((record, idx) => ({
            ...record,
            index: idx + 1
        })));
        
        return this.records.map((record, idx) => ({
            ...record,
            index: idx + 1
        }));

    }

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {

            this.recordId = currentPageReference.attributes?.recordId || null;

            const state = currentPageReference.state || {};
            this.parentId = state.c__parentId || null;
            this.objectname = state.c__objectname || null;
            this.parentObj = state.c__parentObj || null;
            this.relationshipName = state.c__relationshipName || null;
            this.fields = JSON.parse(state.c__fields) || null;
            console.log(this.fields);
            if(this.fields === null || this.fields.length === 0){
                this.fields = ['Name']; // Default field if none provided
            }
            let dynamicColumns = this.fields.map(field => {
                return {
                    label: field, 
                    fieldName: field,
                    type: 'text', 
                    cellAttributes: { alignment: 'center' }
                };
            });
        
            this.columns = [...this.columns, ...dynamicColumns];
            console.log(this.columns);
            
            this.fetchRelatedRecords();
        }
    }

    fetchRelatedRecords() {        
        getRelatedRecords({
            RelatedRecordId: this.parentId,
            objectname: this.parentObj,
            relationshipName: this.relationshipName,
            fieldList: this.fields
            
        })
        .then((data) => {
            console.log({data});
            this.records = data;
            console.log(data);
            
            this.selectedIds = [];
        })
        .catch((error) => {
            this.showToast('Error', 'Failed to fetch related records', 'error');
            this.records = [];
            this.selectedIds = [];
        });
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedIds = selectedRows.map(row => row.Id);        
        this.showLimitError = false; // reset error on change
        this.error = null; // reset error on change
    }


    handleButtonClick() {
        if (this.selectedIds.length === 0) {
            this.showToast('Error', 'No records selected', 'error');
            return;
        }
        // if (this.selectedIds.length > 20) {
        //     this.showLimitError = true;
        //     return;
        // }
        const url = `/lightning/cmp/MVDG__generateDocumentV2?c__objectApiName=${this.objectname}&c__isRelatedList=true&c__isDefaultGenerate=true&c__parentId=${this.parentId}&c__relationshipName=${this.relationshipName}&c__parentObjName=${this.parentObj}&c__ids=${this.selectedIds.join(',')}`;
        window.location.href = url;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    handleClose(){        
        if (typeof window !== 'undefined') {
                location.replace(location.origin + '/lightning/o/' + this.objectname + '/list' ,"_self");
        }
    }
}
