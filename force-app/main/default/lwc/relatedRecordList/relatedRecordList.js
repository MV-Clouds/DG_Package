import { LightningElement, api, track, wire } from 'lwc';
import getRelatedRecords from '@salesforce/apex/RelatedListController.getRelatedRecords';

export default class RelatedRecordList extends LightningElement {
    parentId;
    objectname;
    parentObj;
    relationshipName;
    templateId;

    @track records = [];
    @track selectedIds = [];
    error;
    @track showLimitError = false;
    

    columns = [
        {
            label: 'Index',
            fieldName: 'index',
            type: 'number',
            initialWidth: 80, // smaller width
            cellAttributes: { alignment: 'center' } // center alignment
        },
        {
            label: 'Name',
            fieldName: 'Name',
            type: 'text',
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
        return this.records.map((record, idx) => ({
            ...record,
            index: idx + 1
        }));
    }

    connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        this.parentId = urlParams.get('c__parentId');
        this.objectname = urlParams.get('c__objectname');
        this.parentObj = urlParams.get('c__parentObj');
        this.relationshipName = urlParams.get('c__relationshipName');
        this.templateId = urlParams.get('c__templateId');

        this.fetchRelatedRecords();

    }

    fetchRelatedRecords() {
        console.log(this.parentId);
        console.log(this.relationshipName);
        console.log(this.parentObj);
        
        
        getRelatedRecords({
            RelatedRecordId: this.parentId,
            objectname: this.parentObj,
            relationshipName: this.relationshipName
        })
        .then((data) => {
            this.records = data;
            this.error = undefined;
            this.selectedIds = [];
        })
        .catch((error) => {
            this.error = error;
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
            this.error = 'No records selected';
            return;
        }
        if (this.selectedIds.length > 20) {
            this.showLimitError = true;
            return;
        }

        const url = `/lightning/cmp/c__generateDocumentV2?c__objectApiName=${this.objectname}&c__isRelatedList=true&c__isDefaultGenerate=true&c__templateIdToGenerate=${this.templateId}&c__parentId=${this.parentId}&c__relationshipName=${this.relationshipName}&c__parentObjName=${this.parentObj}&c__ids=${this.selectedIds.join(',')}`;
        
        window.open(url, '_blank');
    }
}
