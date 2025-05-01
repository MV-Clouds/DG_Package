import { LightningElement, track } from 'lwc';
import createListViewButtons from '@salesforce/apex/ButtonGeneratorController.createListViewButtons';
import getCombinedData from '@salesforce/apex/ButtonGeneratorController.getCombinedData';

import generateAccessToken from '@salesforce/apex/GenerateDocumentController.generateAccessToken';
import { errorDebugger } from 'c/globalPropertiesV2'

export default class ButtonGeneratorV2 extends LightningElement {

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

    @track showInitialButtonCreation = false;
    operationCounter = 0;
    initialObjectsList = ['Account' , 'Contact' , 'Lead', 'Opportunity', 'Case', 'Contract'];

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
            if(!this.operationCounter==0) return;
            getCombinedData()
            .then((data) => {
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

                    this.showInitialButtonCreation = !this.initialObjectsList.some(obj => [...this.createdLVButtonObj , ...this.createdBPButtonObj, ...this.createdQAButtonObj].includes(obj));

                    this.template.querySelector('.list-view-generator').value = this.selectedLVObjects.length > 0 ? this.selectedLVObjects : null;
                    this.template.querySelector('.quick-action-generator').value = this.selectedQAObjects.length > 0 ? this.selectedQAObjects : null;
                    this.template.querySelector('.basic-print-generator').value = this.selectedBPObjects.length > 0 ? this.selectedBPObjects : null;
                }else{
                    errorDebugger('buttonGenerator', 'getCombinedData > not success', 'Error in Getting Combined Data.', 'warn');
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

    handleInitialCreate(){
        try {
            this.showSpinner = true;
            ['LV', 'BP', 'QA'].forEach(type =>{
                this['selected'+ type + 'Objects'] = JSON.parse(JSON.stringify(this.initialObjectsList));
            })
            this.operationCounter += 3;
            this.handleCreateWebLinkButton('listView');
            this.handleCreateWebLinkButton('basicPrint');
            this.handleCreateQuickAction();
        } catch (e) {
            this.showSpinner = false;
            errorDebugger('buttonGenerator', 'handleInitialCreate', e, 'warn');
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
                    this.operationCounter++;
                    this.handleCreateWebLinkButton('listView');
                }else if(type === 'quickAction'){
                    if(this.selectedQAObjects.length < 1){
                        this.showToast('error', 'Something Went Wrong!', 'Please select at least 1 object.', 5000);
                        return;
                    }
                    this.operationCounter++;
                    this.handleCreateQuickAction();
                }else if(type === 'basicPrint'){
                    if(this.selectedBPObjects.length < 1){
                        this.showToast('error', 'Something Went Wrong!', 'Please select at least 1 object.', 5000);
                        return;
                    }
                    this.operationCounter++;
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
                this.operationCounter--;
                this.fetchAlreadyCreatedObjects();
            })
            .catch((e)=>{
                this.showToast('error', 'Something went wrong!','The button creation process could not be completed!', 5000);
                errorDebugger('buttonGenerator', 'createListViewButtons', e, 'warn');
                this.operationCounter--;
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
            generateAccessToken()
            .then((data) => {
                if (!data) {
                    this.showToast('error', 'Something went wrong!','Please verify connected app from user configuration.', 5000);
                    return;
                }
                let domainURL = window.location.origin.replace('lightning.force.com', 'my.salesforce.com');
                let endpoint = domainURL + '/services/data/v61.0/tooling/sobjects/QuickActionDefinition';

                let accessToken = data;
                let myHeaders = new Headers();
                myHeaders.append("Content-Type", "application/json");
                myHeaders.append("Authorization", "Bearer "+accessToken);

                let requestBodyExpanded = this.selectedQAObjects.map(obj => ({
                    Metadata: {
                        label: "DG Generate Document",
                        optionsCreateFeedItem: false,
                        type: "LightningWebComponent",
                        lightningWebComponent: "MVDG__generateDocumentV2"
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
                            if(!result?.success){
                                failedButtonsNumber++;
                            }
                            if(i == requestBodyExpanded.length - 1){
                                if(failedButtonsNumber > 0){
                                    this.showToast('error','Something went Wrong!','One or more objects encountered an error creating button, please try again...', 5000);
                                }
                                this.operationCounter--;
                                this.fetchAlreadyCreatedObjects();
                            }
                        })
                        .catch(e => {
                            if(i == requestBodyExpanded.length - 1){
                                this.operationCounter--;
                                this.fetchAlreadyCreatedObjects();
                            }
                            errorDebugger('buttonGenerator', 'handleCreateQuickAction > fetch', e, 'warn');
                            this.showToast('error','Something went wrong!','One or more objects encountered an error creating button, please try again...', 5000);
                        });
                    })
                    this.selectedQAObjects = [];
                })
            .catch((e)=>{
                this.showSpinner = false;
                this.showToast('error','Something went wrong!','Buttons couldn\'t be created please try again.', 5000);
                errorDebugger('buttonGenerator', 'handleCreateQuickAction > generateAccessToken', e, 'warn');
                this.operationCounter--;
                this.fetchAlreadyCreatedObjects();
            })
        } catch (e) {
            this.showSpinner = false;
            errorDebugger('buttonGenerator', 'handleCreateQuickAction', e, 'warn');
            this.operationCounter--;
            this.fetchAlreadyCreatedObjects();
        }
    }

    showToast(status, title, message, duration){
        this.showSpinner = false;
        const messageContainer = this.template.querySelector('c-message-popup-v2')
        messageContainer.showMessageToast({
            status: status,
            title: title,
            message : message,
            duration : duration
        });
    }
}