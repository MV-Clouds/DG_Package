import { LightningElement, track } from 'lwc';
import createListViewButtons from '@salesforce/apex/ButtonGeneratorController.createListViewButtons';
import getCombinedData from '@salesforce/apex/ButtonGeneratorController.getCombinedData';
import getChildObjects from '@salesforce/apex/ButtonGeneratorController.getChildObjects';
import getRelationshipsBetweenObjects from '@salesforce/apex/ButtonGeneratorController.getRelationshipsBetweenObjects';
import createRelatedListButtons from '@salesforce/apex/ButtonGeneratorController.createRelatedListButtons';
import fetchFieldOptionsForRL from '@salesforce/apex/ButtonGeneratorController.fetchFieldOptionsForRL';

import generateAccessToken from '@salesforce/apex/GenerateDocumentController.generateAccessToken';
import { errorDebugger } from 'c/globalPropertiesV2'

export default class ButtonGeneratorV2 extends LightningElement {

    @track createdLVButtonObj = [];
    @track createdQAButtonObj = [];
    @track createdBPButtonObj = [];
    @track createdRLButtonObj = [];
    @track createdDPButtonObj = [];
    @track isNoObjectsAlreadyCreated = true;

    @track allObjects = [];
    @track selectedLVObjects = [];
    @track selectedQAObjects = [];
    @track selectedBPObjects = [];
    @track selectedRLObjects = [];
    @track selectedROLObjects = [];
    @track selectedCRObjects = [];
    @track selectedDPObjects = [];
    @track selectedFieldsForRL = [];

    @track showSpinner = false;

    @track isNoLVObjectCreated = true;
    @track isNoQAObjectCreated = true;
    @track isNoBPObjectCreated = true;
    @track isNoRLObjectCreated = true;
    @track isNoDPObjectCreated = true;

    @track objOptionsForLVButton = [];
    @track objOptionsForQAButton = [];
    @track objOptionsForBPButton = [];
    @track objOptionsForRLButton = [];
    @track objOptionsForROLButton = [];
    @track objOptionsForCRButton = [];
    @track objOptionsForDPButton = [];
    @track fieldOptionsForRL = [];

    @track showInitialButtonCreation = false;
    operationCounter = 0;
    isChooseChannel = false;
    isChooseFields = false;
    isDefaultProcess = false;
    isInitialized = false;

    initialObjectsList = ['Account' , 'Contact' , 'Lead', 'Opportunity', 'Case', 'Contract'];
    dragIndex;
    lastGapTarget;
    lastPosition;


    get selectedDPObject(){
        if(this.selectedDPObjects.length > 0){
            return this.selectedDPObjects[0]
        }
        return null;
    }

    get enableLVCreate(){
        return this.selectedLVObjects.length > 0;
    }

    get enableQACreate(){
        return this.selectedQAObjects.length > 0;
    }

    get enableBPCreate(){
        return this.selectedBPObjects.length > 0;
    }

    get enableROList(){
        return this.selectedROLObjects.length > 0;
    }

    get enableRList(){
        return this.selectedRLObjects.length > 0;
    }

    get enableCRCreate(){
        if(this.selectedCRObjects.length > 0 && !this.isInitialized){
                this.isChooseFields = true;
                this.isInitialized = true;
                fetchFieldOptionsForRL({childObject :this.selectedROLObjects[0]})
                    .then((data) => {
                        console.log(data);
                        
                        this.fieldOptionsForRL = data;
                        
                    }).catch((e) => {
                        errorDebugger('buttonGenerator', 'fetchFieldOptionsForRL', e, 'warn');
                    });
                
        }
        else if(this.selectedCRObjects.length < 1 && this.isInitialized){
            this.isChooseFields = false;
            this.isInitialized = false;
        }

        return this.selectedCRObjects.length > 0;
    }

    
    get enableDPCreate(){
        if(!(this.selectedDPObjects.length > 0)){
            this.isChooseChannel = false;
        }
        return this.selectedDPObjects.length > 0;
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

    handleDragStart(evt) {
        this.dragIndex = parseInt(evt.currentTarget.dataset.index, 10);
        evt.currentTarget.classList.add('dragging');
    }

    handleDragEnd(evt) {
        this.clearGap();
        evt.currentTarget.classList.remove('dragging');
    }

    handleDragOver(evt) {
        evt.preventDefault();
        const x = evt.clientX;
        const y = evt.clientY;

        // find all non-dragging tiles
        const tiles = Array.from(this.template.querySelectorAll('.tile:not(.dragging)'));
        if (!tiles.length) { this.clearGap(); return; }

        // 1) pick closest row
        let minRowDist = Infinity, rowTiles = [];
        tiles.forEach(tile => {
        const r = tile.getBoundingClientRect();
        const rowDist = Math.abs(y - (r.top + r.height/2));
        if (rowDist < minRowDist - 5) {
            minRowDist = rowDist;
            rowTiles = [tile];
        } else if (Math.abs(rowDist - minRowDist) <= 5) {
            rowTiles.push(tile);
        }
        });

        // 2) among those, pick closest horizontally
        let closest = { el: null, dist: Infinity };
        rowTiles.forEach(tile => {
        const r = tile.getBoundingClientRect();
        const dist = Math.abs(x - (r.left + r.width/2));
        if (dist < closest.dist) {
            closest = { el: tile, dist };
        }
        });
        const target = closest.el;
        if (!target) { this.clearGap(); return; }

        // decide before/after by comparing to its midpoint
        const rect = target.getBoundingClientRect();
        const pos = (x < rect.left + rect.width/2) ? 'before' : 'after';

        if (target !== this.lastGapTarget || pos !== this.lastPosition) {
        this.clearGap();
        this.lastGapTarget = target;
        this.lastPosition = pos;
        target.classList.add(pos === 'before' ? 'gap-before' : 'gap-after');
        }
    }

    handleDrop(evt) {
        evt.preventDefault();
        if (this.lastGapTarget && this.lastPosition != null) {
        // get source index
        const from = this.dragIndex;
        // get drop target index
        const to = parseInt(this.lastGapTarget.dataset.index, 10)
                    + (this.lastPosition === 'after' ? 1 : 0);

        // avoid no-ops
        if (from !== to && from + 1 !== to) {
            const arr = [...this.selectedFieldsForRL];
            const [moved] = arr.splice(from, 1);
            // adjust insertion index if we removed earlier in array
            const insertAt = (to > from) ? to - 1 : to;
            arr.splice(insertAt, 0, moved);
            this.selectedFieldsForRL = arr;
        }
        }
        this.clearGap();
    }

    clearGap() {
        if (this.lastGapTarget) {
        this.lastGapTarget.classList.remove('gap-before','gap-after');
        this.lastGapTarget = null;
        this.lastPosition = null;
        }
    }

    fetchAlreadyCreatedObjects(){
        try{
            if(!this.operationCounter==0) return;
            getCombinedData()
            .then((data) => {
                if(data.isSuccess){
                    console.log(data);
                    console.log(data.relatedListButtonObj);
                    
                    
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
                    let RelatedListData = this.handleObjectSeparation(data.relatedListButtonObj);
                    this.objOptionsForRLButton = RelatedListData?.options;
                    this.createdRLButtonObj = data.relatedListButtonObj;
                    let DefaultProcessData = this.handleObjectSeparation(data.defaultProcessButtonObj);
                    this.objOptionsForDPButton = DefaultProcessData?.options;
                    this.createdDPButtonObj = DefaultProcessData?.buttons;
                    

                    this.isNoLVObjectCreated = this.createdLVButtonObj?.length > 0 ? false : true;
                    this.isNoQAObjectCreated = this.createdQAButtonObj?.length > 0 ? false : true;
                    this.isNoBPObjectCreated = this.createdBPButtonObj?.length > 0 ? false : true;
                    this.isNoRLObjectCreated = this.createdRLButtonObj?.length > 0 ? false : true;
                    this.isNoDPObjectCreated = this.createdDPButtonObj?.length > 0 ? false : true;

                    this.showInitialButtonCreation = !this.initialObjectsList.some(obj => [...this.createdLVButtonObj , ...this.createdBPButtonObj, ...this.createdQAButtonObj].includes(obj));

                    this.template.querySelector('.list-view-generator').value = this.selectedLVObjects?.length > 0 ? this.selectedLVObjects : null;
                    this.template.querySelector('.quick-action-generator').value = this.selectedQAObjects?.length > 0 ? this.selectedQAObjects : null;
                    this.template.querySelector('.basic-print-generator').value = this.selectedBPObjects?.length > 0 ? this.selectedBPObjects : null;
                    this.template.querySelector('.related-list-generator').value = this.selectedRLObjects?.length > 0 ? this.selectedRLObjects : [];
                    this.template.querySelector('.default-process-generator').value = this.selectedDPObjects?.length > 0 ? this.selectedDPObjects : [];
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
            }else if(type === 'relatedList'){
                this.selectedRLObjects = event.detail;
                console.log(this.selectedRLObjects);
                this.fetchChildObjects();                
                this.selectedROLObjects = [];
                this.selectedCRObjects = [];
            }else if(type === 'relatedObjList'){
                this.selectedROLObjects = event.detail;
                this.fetchChildRelations();        
                this.selectedCRObjects = [];
            }else if(type === 'relatedCRList'){
                this.selectedCRObjects = event.detail;
            }else if(type === 'defaultProcess'){
                this.selectedDPObjects = event.detail;
            }else if(type === 'objectFields'){  
                if(event.detail.length > 3){
                    this.showToast('error', 'Something Went Wrong!', 'Please select only 3 fields.', 5000);
                    const arr = [...this.selectedFieldsForRL];
                    this.selectedFieldsForRL = [];
                    this.selectedFieldsForRL = JSON.parse(JSON.stringify(arr));
                    return;
                }
                else{
                    this.selectedFieldsForRL = event.detail;
                }
                console.log(this.selectedFieldsForRL);
                
            }
        }catch(e){
            errorDebugger('buttonGenerator', 'handleObjectSelection', e, 'warn');
        }
    }
    

    fetchChildObjects(){
        getChildObjects({parentObjectApiName: this.selectedRLObjects[0]})
        .then((data) => {
            if (Array.isArray(data) && data.length > 0) {
                console.log('Inside conditions');
                // Create a Set of values from allobjects for fast lookup
                let commonObjects = this.allObjects.filter(obj1 =>
                    data.some(obj2 =>
                        obj1.label === obj2.label && obj1.value === obj2.value
                    )
                );
    
                // Filter only those records from data whose 'value' is also in allobjects
                this.objOptionsForROLButton = commonObjects;
                console.log('this is obj options',this.objOptionsForROLButton);
            } else {
                this.objOptionsForROLButton = [];
            }
        })
        .catch((e) => {
            errorDebugger('buttonGenerator', 'fetchChildObjects', e, 'warn');
        })

    }

    fetchChildRelations(){
        getRelationshipsBetweenObjects({parentObject: this.selectedRLObjects[0], childObject: this.selectedROLObjects[0]})
        .then((data) => {
            if(data.length > 0){
                this.objOptionsForCRButton = data;
                console.log('Data for relationships'+data);
            }
        })
        .catch((e) => {
            errorDebugger('buttonGenerator', 'fetchChildObjects', e, 'warn');
        })
    }

    handleCreate(event){
        // this.showSpinner = true;
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
                else if(type === 'relatedList'){
                    if(this.selectedRLObjects.length < 1 || this.selectedROLObjects.length < 1 || this.selectedCRObjects.length < 1){
                        this.showToast('error', 'Something Went Wrong!', 'Please select at least 1 object.', 5000);
                        return;
                    }
                    this.operationCounter++;
                    this.handleCreateWebLinkButton('relatedList');
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

    handleDefaultProcessCreate(){
        this.showSpinner = true;
        try {
            if(this.selectedDPObjects.length < 1){
                this.showToast('error', 'Something Went Wrong!', 'Please select at least 1 object.', 5000);
                return;
            }
            console.log('Inside default process create');
            
            this.operationCounter++;
            this.isDefaultProcess = true;
            this.handleCreateQuickAction();
        } catch (error) {
            this.showSpinner = false;
            this.showToast('error','Something went Wrong!','Buttons couldn\'t be created please try again.', 5000);
            errorDebugger('buttonGenerator', 'handleDefaultProcessCreate', e, 'warn');
        }
    }

    handleSelectChannel(event){
        this.isChooseChannel = true;
        setTimeout(() => {
            const target = this.template.querySelector('[data-id="targetSection"]');
            if (target) {
                target.scrollIntoView({ behavior: 'smooth', block: 'start' });
                target.focus(); // optional, if you want keyboard focus
            }
        }, 0);
    }

    handleClose(){
        this.isChooseChannel = false;
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
            else if(type === 'relatedList'){           
                objects = this.selectedROLObjects;
                buttonData.buttonLabel = 'DG RL '+ this.selectedCRObjects[0];
                buttonData.buttonName = 'DG_RL'+ this.selectedRLObjects[0].replaceAll('__', '_') +this.selectedCRObjects[0].replaceAll('__', '_');
                buttonData.parentObject = this.selectedRLObjects[0];
                buttonData.relationshipName = this.selectedCRObjects[0];
                console.log(this.selectedFieldsForRL);
                
                buttonData.fields = JSON.stringify(this.selectedFieldsForRL);
                console.log(buttonData.fields);
                
            }
            if(type != 'relatedList'){
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
            }
            else {
                createRelatedListButtons({objects: objects ,buttonData : buttonData})
                .then((result)=>{
                    if(result !== 'success'){
                        this.showToast('error', 'Something went wrong!','The button creation process could not be completed!', 5000);
                        errorDebugger('buttonGenerator', 'createRelatedListButtons > failure', result, 'warn');
                    }
                    this.operationCounter--;
                    this.fetchAlreadyCreatedObjects();
                })
                .catch((e)=>{
                    this.showToast('error', 'Something went wrong!','The button creation process could not be completed!', 5000);
                    errorDebugger('buttonGenerator', 'createRelatedListButtons', e, 'warn');
                    this.operationCounter--;
                    this.fetchAlreadyCreatedObjects();
                })
            }
        } catch (e) {
            this.showSpinner = false;
            this.showToast('error', 'Something went wrong!','The button creation process could not be completed!', 5000);
            errorDebugger('buttonGenerator', 'handleCreateWebLinkButton', e, 'warn');
        }finally{
            type === 'listView' ? this.selectedLVObjects = [] : this.selectedBPObjects = [];
            type === 'relatedList' ? this.selectedROLObjects = [] : null;
            type === 'relatedList' ? this.selectedRLObjects = [] : null;
            type === 'relatedList' ? this.selectedCRObjects = [] : null;
            type === 'relatedList' ? this.selectedFieldsForRL = [] : null;
        }
    }


    handleCreateQuickAction(){
        try {
            generateAccessToken()
            .then((data) => {
                console.log('Generate handle create quick action');
                
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
                let requestBodyExpanded;
                if(this.isDefaultProcess){
                    requestBodyExpanded = this.selectedDPObjects.map(obj => ({
                        Metadata: {
                            label: "DGP_"+obj.replaceAll('__', '_'),
                            optionsCreateFeedItem: false,
                            type: "LightningWebComponent",
                            lightningWebComponent: "generateDocumentV2"
                        },
                        FullName: `${obj}.DGP_${obj.replaceAll('__', '_')}`
                    }));
                }else{
                    requestBodyExpanded = this.selectedQAObjects.map(obj => ({
                        Metadata: {
                            label: "DG Generate Document",
                            optionsCreateFeedItem: false,
                            type: "LightningWebComponent",
                            lightningWebComponent: "MVDG__generateDocumentV2"
                        },
                        FullName: `${obj}.DG_Generate_Document`
                    }));
                }
                console.log('REQ-->'+requestBodyExpanded);
                

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
                    this.selectedDPObjects = [];
                    this.isDefaultProcess = false;
                    this.handleClose();
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