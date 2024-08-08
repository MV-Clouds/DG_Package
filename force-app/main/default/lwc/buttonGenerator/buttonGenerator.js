import { LightningElement, track } from 'lwc';
import createListViewButtons from '@salesforce/apex/ButtonGeneratorController.createListViewButtons';
import getCombinedData from '@salesforce/apex/ButtonGeneratorController.getCombinedData';

import getSessionId from '@salesforce/apex/GenerateDocumentController.getSessionId';

export default class ButtonGenerator extends LightningElement {

    @track createdLVButtonObj = [];
    @track createdQAButtonObj = [];
    @track createdBPButtonObj = [];
    @track isNoObjectsAlreadyCreated = true;

    @track allObjects = [];
    @track selectedLVObjects = [];
    @track selectedQAObjects = [];
    @track selectedBPObjects = [];

    @track showSpinner = false;

    @track isNoLVObjectCreated = true;
    @track isNoQAObjectCreated = true;
    @track isNoBPObjectCreated = true;

    @track objOptionsForLVButton = [];
    @track objOptionsForQAButton = [];
    @track objOptionsForBPButton = [];
    
    connectedCallback(){
        this.showSpinner = true;
        try{
            this.fetchAlreadyCreatedObjects();
        }catch(e){
            this.showSpinner = false;
            console.log('Error in connectedCallback ::', e.message);
        }
    }

    fetchAlreadyCreatedObjects(){
        try{
            getCombinedData()
            .then((data) => {
                console.log('Data fetched ::', data);
                if(data.isSuccess){
                    this.allObjects = data.allObjects;
                    this.allObjects = this.allObjects.slice().sort((a, b) => a.label.localeCompare(b.label));

                    let listViewData = this.handleObjectSeparation(data.listViewButtonObj);
                    this.objOptionsForLVButton = listViewData?.options;
                    this.createdLVButtonObj = listViewData?.buttons;
                    let QuickActionData = this.handleObjectSeparation(data.quickActionButtonObj);
                    this.objOptionsForQAButton = QuickActionData?.options;
                    this.createdQAButtonObj = QuickActionData?.buttons;
                    let BasicPrintData = this.handleObjectSeparation(data.basicPrintButtonObj);
                    this.objOptionsForBPButton = BasicPrintData?.options;
                    this.createdBPButtonObj = BasicPrintData?.buttons;

                    this.isNoLVObjectCreated = this.createdLVButtonObj.length > 0 ? false : true;
                    this.isNoQAObjectCreated = this.createdQAButtonObj.length > 0 ? false : true;
                    this.isNoBPObjectCreated = this.createdBPButtonObj.length > 0 ? false : true;
                }else{
                    this.showToast('error', 'Something went wrong!', 'Error fetching all required data, please try again!', 5000);
                }
                this.showSpinner = false;
            })
            .catch((error) => {
                this.showSpinner = false;
                console.log('Error in getCombinedData', error.message);
                this.showToast('error', 'Something went wrong!', 'Error fetching all required data, please try again!', 5000);
            })
        }catch(e){
            this.showSpinner = false;
            console.log('Error in fetchAlreadyCreatedObjects', e.message);
            this.showToast('error', 'Something went wrong!', 'Error fetching all required data, please try again!', 5000);
        }
    }

    handleObjectSeparation(data){
        try {
            let objLabelList = [];
            let updatedObject = [];

            this.allObjects.forEach((obj) =>{
                if(data.includes(obj.value)){
                    objLabelList.push(obj.label) 
                }else{
                    updatedObject.push(obj);
                } 
            })
            return {options : updatedObject, buttons: objLabelList}
        } catch (e) {
            console.log('Error in function handleObjectSeparation:::', e.message);
            return null;
        }
    }
    handleObjectSelection(event){
        try{
            let type = event.target.dataset.type;
            if(type === "listView"){
                this.selectedLVObjects = event.detail;
                this.template.querySelector('.list-view-btn').classList.toggle('disabled-btn', this.selectedLVObjects.length === 0);                
            }else if(type === 'quickAction'){
                this.selectedQAObjects = event.detail;
                this.template.querySelector('.quick-action-btn').classList.toggle('disabled-btn', this.selectedQAObjects.length === 0);
            }else if(type === 'basicPrint'){
                this.selectedBPObjects = event.detail;
                this.template.querySelector('.basic-print-btn').classList.toggle('disabled-btn', this.selectedBPObjects.length === 0);
            }
        }catch(e){
            console.log('Error in handleObjectSelection ::' , e.message);
        }
    }

    handleCreate(event){
        this.showSpinner = true;
        try {
            let type = event.target.dataset.type;
            if(type){
                console.log('type is ', type);
                if(type === 'listView'){
                    if(this.selectedLVObjects.length < 1){
                        this.showToast('error', 'Something Went Wrong!', 'Please select at least 1 object.', 5000);
                        return;
                    }
                    this.handleCreateWebLinkButton('listView');
                }else if(type === 'quickAction'){
                    if(this.selectedQAObjects.length < 1){
                        this.showToast('error', 'Something Went Wrong!', 'Please select at least 1 object.', 5000);
                        return;
                    }
                    this.handleCreateQuickAction();
                }else if(type === 'basicPrint'){
                    if(this.selectedBPObjects.length < 1){
                        this.showToast('error', 'Something Went Wrong!', 'Please select at least 1 object.', 5000);
                        return;
                    }
                    this.handleCreateWebLinkButton('basicPrint')
                }
    
                this.template.querySelector('.list-view-btn').classList.add('disabled-btn');  
                this.template.querySelector('.quick-action-btn').classList.add('disabled-btn');
                this.template.querySelector('.basic-print-btn').classList.add('disabled-btn');
            }else{
                this.showToast('error','Something went wrong!','Action Could not be performed, please try again...', 5000);
            }
        } catch (e) {
            this.showSpinner = false;
            this.showToast('error','Something went Wrong!','Buttons couldn\'t be created please try again.', 5000);
            console.log('Error in handleCreate :::', e.message);
        }
    }

    handleCreateWebLinkButton(type){
        console.log('Creating Web Link Button');
        try {
            let buttonData = {
                buttonLabel: null,
                buttonName: null,
                buttonEndURL: null
            }
            let objects = null;
            if(type === 'listView'){
                objects = this.selectedLVObjects;
                buttonData.buttonLabel = 'DG Generate CSV';
                buttonData.buttonName = 'DG_Generate_CSV';
                buttonData.buttonEndURL = '&c__isCSVOnly=true';
            }
            else if(type === 'basicPrint'){
                objects  = this.selectedBPObjects;
                buttonData.buttonLabel = 'DG Basic Print';
                buttonData.buttonName = 'DG_Basic_Print';
            }
            createListViewButtons({objects: objects ,buttonData : buttonData})
            .then(()=>{
                console.log('Successfully created list view buttons.');
                this.showSpinner = false;
                this.fetchAlreadyCreatedObjects();
            })
            .catch((error)=>{
                this.showToast('error', 'Something went wrong!','The button creation process could not be completed!', 5000);
                console.log('error in createListViewButtons ::', error.message);
                this.showSpinner = false;
            })
        } catch (e) {
            this.showSpinner = false;
            this.showToast('error', 'Something went wrong!','The button creation process could not be completed!', 5000);
            console.log('Error in function handleCreateWebLinkButton:::', e.message);
        }finally{
            this.selectedLVObjects = [];
            this.selectedBPObjects = [];
        }
    }

    handleCreateQuickAction(){
        try {
            console.log('Creating Quick Action');
            getSessionId()
            .then((data) => {
                let domainURL = window.location.origin.replace('lightning.force.com', 'my.salesforce.com');
                let endpoint = domainURL + '/services/data/v61.0/tooling/sobjects/QuickActionDefinition';

                let sessionId = data;
                let myHeaders = new Headers();
                myHeaders.append("Content-Type", "application/json");
                myHeaders.append("Authorization", "Bearer "+sessionId);

                let requestBodyExpanded = this.selectedQAObjects.map(record => ({
                    Metadata: {
                        label: "DG Generate Document",
                        optionsCreateFeedItem: false,
                        type: "LightningWebComponent",
                        lightningWebComponent: "generateDocument"
                    },
                    FullName: `${record}.DG_Generate_Document`
                }));
                requestBodyExpanded.forEach((requestBody, i) => {
                    console.log('the requestBody :::  ', requestBody);
                    let requestOptions = {
                        method: 'POST',
                        headers: myHeaders,
                        body: JSON.stringify(requestBody),
                        redirect: 'follow'
                        };
                        fetch(encodeURI(endpoint), requestOptions)
                        .then(response => response.json())
                        .then(result => {
                            (i == requestBodyExpanded.length - 1) ? this.fetchAlreadyCreatedObjects() : undefined;
                            console.log(result);
                        })
                        .catch(error => {
                            (i == requestBodyExpanded.length - 1) ? this.fetchAlreadyCreatedObjects() : undefined;
                            console.log('error', error);
                            this.showToast('error','Something went Wrong!','Buttons couldn\'t be created please try again.', 5000);
                        });
                    })
                    this.selectedQAObjects = [];
                })
            .catch((error)=>{
                this.showSpinner = false;
                this.showToast('error','Something went Wrong!','Buttons couldn\'t be created please try again.', 5000);
                console.log('error in getSessionId ::', error.message);
            })
        } catch (e) {
            this.showSpinner = false;
            console.log('Error in function handleCreateQuickAction:::', e.message);
        }
    }

    showToast(status, title, message, duration){
        this.showSpinner = false;
        const messageContainer = this.template.querySelector('c-message-popup')
        messageContainer.showMessageToast({
            status: status,
            title: title,
            message : message,
            duration : duration
        });
    }
}