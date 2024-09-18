import { LightningElement, track } from 'lwc';
import createListViewButtons from '@salesforce/apex/ButtonGeneratorController.createListViewButtons';
import getCombinedData from '@salesforce/apex/ButtonGeneratorController.getCombinedData';

import getSessionId from '@salesforce/apex/GenerateDocumentController.getSessionId';
import { errorDebugger } from 'c/globalProperties'

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


    get enableLVCreate(){
        return this.selectedLVObjects.length > 0;
    }

    get enableQACreate(){
        return this.selectedQAObjects.length > 0;
    }

    get enableBPCreate(){
        return this.selectedBPObjects.length > 0;
    }
    
    connectedCallback(){
        this.showSpinner = true;
        try{
            this.fetchAlreadyCreatedObjects();
        }catch(e){
            this.showSpinner = false;
            errorDebugger('buttonGenerator', 'connectedCallback', e, 'warn');
        }
    }

    fetchAlreadyCreatedObjects(){
        try{
            getCombinedData()
            .then((data) => {
                if(data.isSuccess){
                    this.allObjects = data.allObjects;
                    this.allObjects = this.allObjects.slice().sort((a, b) => a.label.localeCompare(b.label)).filter((obj) => obj.value!='Pricebook2');

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

                    this.template.querySelector('.list-view-generator').value = this.selectedLVObjects.length > 0 ? this.selectedLVObjects : null;
                    this.template.querySelector('.quick-action-generator').value = this.selectedQAObjects.length > 0 ? this.selectedQAObjects : null;
                    this.template.querySelector('.basic-print-generator').value = this.selectedBPObjects.length > 0 ? this.selectedBPObjects : null;
                }else{
                    this.showToast('error', 'Something went wrong!', 'Error fetching all required data, please try again!', 5000);
                }
                this.showSpinner = false;
            })
            .catch((e) => {
                this.showSpinner = false;
                errorDebugger('buttonGenerator', 'getCombinedData', e, 'warn');
                this.showToast('error', 'Something went wrong!', 'Error fetching all required data, please try again!', 5000);
            })
        }catch(e){
            this.showSpinner = false;
            errorDebugger('buttonGenerator', 'fetchAlreadyCreatedObjects', e, 'warn');
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
            errorDebugger('buttonGenerator', 'handleObjectSeparation', e, 'warn');
            return null;
        }
    }
    handleObjectSelection(event){
        try{
            let type = event.target.dataset.type;
            if(type === "listView"){
                this.selectedLVObjects = event.detail;
            }else if(type === 'quickAction'){
                this.selectedQAObjects = event.detail;
            }else if(type === 'basicPrint'){
                this.selectedBPObjects = event.detail;
            }
        }catch(e){
            errorDebugger('buttonGenerator', 'handleObjectSelection', e, 'warn');
        }
    }

    handleCreate(event){
        this.showSpinner = true;
        try {
            let type = event.target.dataset.type;
            if(type){
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
            }else{
                this.showToast('error','Something went wrong!','Action Could not be performed, please try again...', 5000);
            }
        } catch (e) {
            this.showSpinner = false;
            this.showToast('error','Something went Wrong!','Buttons couldn\'t be created please try again.', 5000);
            errorDebugger('buttonGenerator', 'handleCreate', e, 'warn');
        }
    }

    handleCreateWebLinkButton(type){
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
            .then((result)=>{
                if(result !== 'success'){
                    this.showToast('error', 'Something went wrong!','The button creation process could not be completed!', 5000);
                    errorDebugger('buttonGenerator', 'createListViewButtons > failure', result, 'warn');
                }
                this.showSpinner = false;
                this.fetchAlreadyCreatedObjects();
            })
            .catch((e)=>{
                this.showToast('error', 'Something went wrong!','The button creation process could not be completed!', 5000);
                errorDebugger('buttonGenerator', 'createListViewButtons', e, 'warn');
                this.showSpinner = false;
                this.fetchAlreadyCreatedObjects();
            })
        } catch (e) {
            this.showSpinner = false;
            this.showToast('error', 'Something went wrong!','The button creation process could not be completed!', 5000);
            errorDebugger('buttonGenerator', 'handleCreateWebLinkButton', e, 'warn');
        }finally{
            type === 'listView' ? this.selectedLVObjects = [] : this.selectedBPObjects = [];
        }
    }

    handleCreateQuickAction(){
        try {
            getSessionId()
            .then((data) => {
                let domainURL = window.location.origin.replace('lightning.force.com', 'my.salesforce.com');
                let endpoint = domainURL + '/services/data/v61.0/tooling/sobjects/QuickActionDefinition';

                let sessionId = data;
                let myHeaders = new Headers();
                myHeaders.append("Content-Type", "application/json");
                myHeaders.append("Authorization", "Bearer "+sessionId);

                let requestBodyExpanded = this.selectedQAObjects.map(obj => ({
                    Metadata: {
                        label: "DG Generate Document",
                        optionsCreateFeedItem: false,
                        type: "LightningWebComponent",
                        lightningWebComponent: "MVDG__generateDocument"
                    },
                    FullName: `${obj}.DG_Generate_Document`
                }));
                let failedButtonsNumber = 0;
                requestBodyExpanded.forEach((requestBody, i) => {
                    let requestOptions = {
                        method: 'POST',
                        headers: myHeaders,
                        body: JSON.stringify(requestBody),
                        redirect: 'follow'
                        };
                        fetch(encodeURI(endpoint), requestOptions)
                        .then(response => response.json())
                        .then(result => {
                            if(i == requestBodyExpanded.length - 1){
                                this.fetchAlreadyCreatedObjects();
                                if(failedButtonsNumber > 0){
                                    this.showToast('error','Something went Wrong!','There was error creating '+ failedButtonsNumber + (failedButtonsNumber==1?' button,' : ' buttons,') + 'please try again...', 5000);
                                }
                            }
                            if(!result?.success){
                                failedButtonsNumber++;
                            }
                        })
                        .catch(e => {
                            if(i == requestBodyExpanded.length - 1){
                                this.fetchAlreadyCreatedObjects();
                                if(failedButtonsNumber > 0){
                                    this.showToast('error','Something went Wrong!','There was error creating '+ failedButtonsNumber + (failedButtonsNumber==1?' button,' : 'buttons,') + 'please try again...', 5000);
                                }
                            }
                            errorDebugger('buttonGenerator', 'handleCreateQuickAction > fetch', e, 'warn');
                            this.showToast('error','Something went Wrong!','There was some error creating button, try again...', 5000);
                        });
                    })
                    this.selectedQAObjects = [];
                })
            .catch((e)=>{
                this.showSpinner = false;
                this.showToast('error','Something went Wrong!','Buttons couldn\'t be created please try again.', 5000);
                errorDebugger('buttonGenerator', 'handleCreateQuickAction > getSessionId', e, 'warn');
            })
        } catch (e) {
            this.showSpinner = false;
            errorDebugger('buttonGenerator', 'handleCreateQuickAction', e, 'warn');
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