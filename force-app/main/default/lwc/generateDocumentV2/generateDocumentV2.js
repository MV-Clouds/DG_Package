import { LightningElement , api, track, wire} from 'lwc';
import getCombinedData from '@salesforce/apex/GenerateDocumentController.getCombinedData';
import generateAccessToken from '@salesforce/apex/GenerateDocumentController.generateAccessToken';
import storeInFiles from '@salesforce/apex/GenerateDocumentController.storeInFiles';
import postToChatter from '@salesforce/apex/GenerateDocumentController.postToChatter';
import sendEmail from '@salesforce/apex/GenerateDocumentController.sendEmail';
import upsertActivity from '@salesforce/apex/GenerateDocumentController.upsertActivity';
import getButtonNames from '@salesforce/apex/GenerateDocumentController.getButtonNames';
import queryRecord from '@salesforce/apex/GenerateDocumentController.queryRecord';
import createListViewButtons from '@salesforce/apex/ButtonGeneratorController.createListViewButtons';
import {navigationComps, nameSpace, errorDebugger} from 'c/globalPropertiesV2';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import fetchAllRecordIds from "@salesforce/apex/GoogleDocPreview.fetchAllRecordIds";
import getFileNames from "@salesforce/apex/GoogleDocPreview.getFileNames";
import storeDefaultProcesses from '@salesforce/apex/GenerateDocumentController.storeDefaultProcesses';
// import { loadScript } from 'lightning/platformResourceLoader';
// import JSZip from '@salesforce/resourceUrl/JSZip';
// import getContentFiles from '@salesforce/apex/GenerateDocumentController.getContentFiles';

//CSV Generation methods
import getTemplateData from '@salesforce/apex/GenerateDocumentController.getTemplateData';

//External Storage Methods
import uploadToDropBox from '@salesforce/apex/UploadController.uploadToDropBox';
import uploadToOneDrive from '@salesforce/apex/UploadController.uploadToOneDrive';
import uploadToAWS from '@salesforce/apex/UploadController.uploadToAWS';
import uploadToGoogleDrive from '@salesforce/apex/UploadController.uploadToGoogleDrive';

//Defaults Generation methods
import setDefaultOptions from '@salesforce/apex/GenerateDocumentController.setDefaultOptions';
import getTemplateDefaultValues from '@salesforce/apex/GenerateDocumentController.getTemplateDefaultValues';
import fetchProcessDefinedData from '@salesforce/apex/GenerateDocumentController.fetchProcessDefinedData';

//Delete content version if needed
import deleteContentVersion from '@salesforce/apex/GenerateDocumentController.deleteContentVersion';

import getFieldMappingKeys from '@salesforce/apex/KeyMappingController.getFieldMappingKeys';

//Helper Js
import {getDocumentTypes, getInternalStorages, getExternalStorages, getOutputChannels} from './generateDocumentHelper';
export default class GenerateDocumentV2 extends NavigationMixin(LightningElement) {

    @track showSpinner = true;
    @track labelOfLoader = 'Loading...';
    @track fieldLabelOptions = [];
    @track selectedFieldLabels = [];

    //Data from record
    parentId;
    relationshipName;
    parentObjName;
    @track contentVersionIds = [];
    @track nameMap = {};
    @track counter = 0;
    isDownloadZip = false;
    totalNum = 0;
    @track keyOptions = [
        {
            "label": "Parent Object Name",
            "value": "{{#parentObjName}}"
        },
        {
            "label": "Current Object Name",
            "value": "{{#currentObjName}}"
        },
    ];
    isExpand = false;
    isOnParent = false;
    bulkStatus = [];
    isProcessDefined = false;


    @api recordId;
    @api objectApiName;

    @track _internalObjectApiName;
    get internalObjectApiName() {
        return this._internalObjectApiName || this.objectApiName;
    }
    set internalObjectApiName(value) {
        this._internalObjectApiName = value;
    }
    @api calledFromWhere;
    @api templateTypeFromParent;
    @api templateIdFromParent;
    @api templateNameFromParent;
    @track buttonLabel;
    @track buttonName;
    @track bottomBtnLabel = 'Create Custom Button';
    allButtons = [];
    @track isOldButton = false;
    get buttonType(){
        return this.isCSVTemplate ? 'List View' : 'Quick Action';
    }
    @track hideHeader = false;

    @track isCalledFromDefaults = false;
    isCalledFromDefaultProcess = false;
    @track isCalledFromPreview = false;

    @track showAllTemplates = false;
    @track noTemplateFound = false;
    @track templateSearchKey ='';

    @track allTemplates = [];
    @track activeTemplates = [];
    @track templateList = [];
    @track isEditorAccess = false;

    @track selectedTemplate = null;
    @track showEmailSection = false;
    @track showCC = false;
    @track showBCC = false;

    @track toEmails = [];
    @track ccEmails = [];
    @track bccEmails = [];

    @track isToError = false;
    @track isCcError = false;
    @track isBccError = false;

    @track emailSubject = '';
    @track emailBody = '';
    @track previewEmailBody = '';

    isInitialStyleLoaded = false;

    //Objects for options
    @track documentTypes = getDocumentTypes();
    @track csvDocumentTypes = this.documentTypes.filter(doc => doc.name === 'XLS' || doc.name === 'CSV');
    @track generalDocumentTypes = this.documentTypes.filter(doc => !(doc.name === 'XLS' ||  doc.name === 'CSV'));
    @track internalStorageOptions = getInternalStorages();
    @track externalStorageOptions = getExternalStorages();
    @track outputChannels = getOutputChannels();

    @track allEmailTemplates = [];
    @track emailTemplatesToShow = [];
    @track selectedEmailTemplate;
    @track viewAsTypeOptions = [{
            label: "View as Plain Text",
            value: "plain"
        },{
            label: "View as Rich Text",
            value: "rich"
        }];
    @track selectedViewAsType = "rich";
    @track isPlainEmailBody = false;


    //CSV
    @track showCSVPreview = false;
    @track fetchedResults = [];
    @track generatedCSVData;
    @track isAdditionalInfo = false;
    accessToken;

    @track isCSVOnly = false;
    @track isRelatedList = false;
    @track isAllExceptCSV = false;

    //PDF - DOC
    @track showSimplePreview = false;
    @track generatePDF = false;
    @track vfGeneratePageSRC;

    //Google doc
    @track showGDocPreview = false;
    @track googleDocData;

    // Simple template docGenerate...
    completedSimTempPros = 0;
    simpleTemplate = false;

    //All files use
    @track showFolderSelection = false;
    @track fileName = '';
    @track allFolders = [];
    @track selectedFolder;
    @track recordIds;

    //Results
    succeeded = [];
    failed = {};
    resultPromises = [];

    //Default Generation
    @track isDefaultGenerate = false;

    //Confirmations 
    isClosableError = false;
    isButtonGeneration = false;

    @track isNotGoogleNotGenerable = false;
    activity = {
        Id : null,
        MVDG__DocGenius_Template__c : null,
        MVDG__Selected_Channels__c : null,
        MVDG__File_Name__c : null,
        MVDG__Download__c : null,
        MVDG__Email__c : null,
        MVDG__Google_Drive__c : null,
        MVDG__AWS__c : null,
        MVDG__One_Drive__c : null,
        MVDG__Dropbox__c : null,
        MVDG__Notes_Attachments__c : null,
        MVDG__Files__c : null,
        MVDG__Chatter__c : null,
        MVDG__Documents__c : null,
        MVDG__Related_Record_Id__c : null,
    }
    customTimeout;

    // @track fieldLabelOptions = [];
    // @track selectedFieldLabels = []; 
    @track fieldMappingsWithObj = [];
    emailregex = /^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i;
    @track selectedEmailType = 'to';
    @track emailTypeOptions = [
        { label: 'To', value: 'to' },
        { label: 'Cc', value: 'cc' },
        { label: 'Bcc', value: 'bcc' }
    ]; 

    //dynamic email 
    @track toFields = [];
    @track ccFields = [];
    @track bccFields = [];

    //for dynamic email verified email address from records fields
    @track toverified = [];
    @track ccverified = [];
    @track bccverified = [];

    @track originalFieldLabelOptions = [];

    

    get disableZipOption(){
        return !this.selectedChannels.includes('Download');
    }

    get disableParentOption(){
        return !(this.selectedChannels.includes('Notes & Attachments') || this.selectedChannels.includes('Files'));
    }

    get showCloseButton(){
        return this.isCSVOnly || this.isDefaultGenerate || this.isCalledFromPreview;
    }

    get openedTabName(){
        if(this.showCSVPreview){
            return 'CSV Preview';
        }else if(this.showSimplePreview){
            return this.templateType + ' Preview';
        }
        return 'Generate Document';
    }

    get documentTypesToShow(){
        if(this.selectedTemplate || this.isCalledFromDefaults || this.isCalledFromDefaultProcess){
            return this.templateType === 'CSV Template' || (this.isCalledFromDefaults && this.templateTypeFromParent==='CSV Template') ? this.csvDocumentTypes : this.generalDocumentTypes;
        }
        // if(this.isCalledFromDefaultProcess){
        //     return this.templateType === 'Simple Template';
        // }
        
        this.csvDocumentTypes.forEach(option => {option.isSelected = false});
        this.generalDocumentTypes.forEach(option => {option.isSelected = false});
        return this.documentTypes;
    }

    get isOtherModelOpen(){
        return this.showAllTemplates || this.showCSVPreview || this.showGDocPreview || this.showSimplePreview || this.isCalledFromDefaults || this.isCalledFromDefaultProcess;
    }

    get hideOptionSelection(){
        console.log('Hide option selection called');
        console.log(this.showAllTemplates);
        console.log(this.showCSVPreview);
        console.log(this.isEditDisabled);
        console.log(this.showGDocPreview);
        console.log(this.showSimplePreview);
        
        
        
        
        
        
        let theHideResult = this.showAllTemplates || this.showCSVPreview || this.isEditDisabled || this.showGDocPreview || this.showSimplePreview;
        this.template.host.style.setProperty('--display-for-main-container', theHideResult ? 'none' : 'flex' );
        return theHideResult;
    }

    get showBottomButtons(){
        return !this.showAllTemplates && this.isOtherModelOpen && !this.isCalledFromDefaults;
    }

    get showNoTemplateSelected(){
        return this.isEditDisabled && !this.isOtherModelOpen && !this.isCalledFromDefaults;
    }

    get filterForActiveTemplates(){
        let filters = [
            {field : 'MVDG__Object_API_Name__c', operator : 'eq', value : this.internalObjectApiName},
            {field : 'MVDG__Template_Status__c', operator : 'eq', value : true}
        ];
        if(this.isCSVOnly){
            filters.push({field : 'MVDG__Template_Type__c', operator : 'eq', value : 'CSV Template'});
        }
        if(this.isAllExceptCSV){
            filters.push({field : 'MVDG__Template_Type__c', operator : 'ne', value : 'CSV Template'});
        }
        if(this.isNotGoogleNotGenerable){
            filters.push({field : 'MVDG__Template_Type__c', operator : 'ne', value : 'Google Doc Template'});
        }
        return filters;
    }

    get updatedTemplates(){
        if(!this.templateSearchKey){
            this.noTemplateFound = this.allTemplates.length < 1 ? true : false;
            return this.allTemplates;
        }
        let searchedTemplates = this.allTemplates.filter(t => t.MVDG__Template_Name__c.toUpperCase().includes(this.templateSearchKey.toUpperCase()));
        this.noTemplateFound = searchedTemplates.length < 1 ? true : false;
        
        return searchedTemplates;
    }

    get isEditDisabled(){
        return this.selectedTemplate || this.isCalledFromDefaults || this.isCalledFromDefaultProcess ? false : true;
    }

    get templateType(){
        if( this.isCalledFromDefaultProcess ){
            console.log("Defined simple template");
            
            return 'Simple Template';
        }
        return !this.isCalledFromDefaults ? this.allTemplates.find(t => t.Id === this.selectedTemplate)?.MVDG__Template_Type__c || 'CSV Template' : this.templateTypeFromParent;
    }

    get templateName(){
        return this.allTemplates.find(t => t.Id === this.selectedTemplate)?.MVDG__Template_Name__c || '';
    }

    get isCSVTemplate(){
        return this.templateType==='CSV Template' ? true : false;
    }

    get selectedExtension(){
        return this.documentTypes.find(dt => dt.isSelected === true)?.extension;
    }

    get selectedChannels(){
        let channels = [];
        this.internalStorageOptions.forEach(o=>{
            o.isSelected ? channels.push(o.name): undefined;
        })
        this.externalStorageOptions.forEach(o=>{
            o.isSelected ? channels.push(o.name): undefined;
        })
        this.outputChannels.forEach(o=>{
            o.isSelected ? channels.push(o.name): undefined;
        })

        return channels;
    }

    get isNotTemplateEditable(){
        return this.isEditDisabled || !this.selectedTemplate || !this.allTemplates?.find(t => t.Id === this.selectedTemplate)?.isEditable;
    }

    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() {
        // loadScript(this, JSZip)
        // .then(() => {
        //     this.zipLibLoaded = true;
        //     console.log('JSZip loaded');
        // })
        // .catch(error => {
        //     console.error('Failed to load JSZip', error);
        // });       
        this.showSpinner = true;
        try{
            if (typeof window !== 'undefined') {
                window.addEventListener('message', this.simpleTempFileGenResponse);
            }
            this.hideHeader = this.calledFromWhere === 'defaults' || this.calledFromWhere === 'defaultProcess';
            let isAutoGeneration = this.currentPageReference.type !== "standard__quickAction" && this.calledFromWhere!="preview" && this.calledFromWhere!="defaults" && this.calledFromWhere!="defaultProcess";
            if(isAutoGeneration){                
                this.internalObjectApiName = this.currentPageReference?.state?.c__objectApiName;
                this.isCSVOnly = this.currentPageReference?.state?.c__isCSVOnly === 'true' ? true : false;
                this.isRelatedList = this.currentPageReference?.state?.c__isRelatedList === 'true' ? true : false;
                this.isDefaultGenerate = this.currentPageReference?.state?.c__isDefaultGenerate === 'true' ? true : false;
                this.parentId = this.currentPageReference?.state?.c__parentId;
                this.parentObjName = this.currentPageReference?.state?.c__parentObjName;
                this.relationshipName = this.currentPageReference?.state?.c__relationshipName;
                this.recordIds = this.currentPageReference?.state?.c__ids ? this.currentPageReference?.state?.c__ids.split(',') : [];

                this.template.host.classList.add('pou-up-view');
                this.selectedTemplate = this.currentPageReference?.state?.c__templateIdToGenerate;
            }
            console.log(this.calledFromWhere);
            console.log(this.internalObjectApiName);
            
            Promise.resolve(this.internalObjectApiName)
            .then(() => {
                    return Promise.all([
                        this.fetchCombinedData(),
                    ]);
                })
            .then(() => {
                // console.log('internal obj'+this.internalObjectApiName);
                this.fetchFieldMapping();
                console.log('checkpoint 0');                
                if (this.calledFromWhere === "preview") {
                    console.log('checkpoint 0.4');
                    this.handleCalledFromPreview();
                } else if (this.calledFromWhere === 'defaultProcess'){  
                    console.log('checkpoint 0.5');
                    this.handleCalledFromDefaultProcess();
                } else if (this.calledFromWhere === 'defaults') {
                    console.log('checkpoint 0.6');
                    this.handleCalledFromDefaults();
                } else if(this.isCSVOnly){
                    console.log('checkpoint 0.7');

                    this.handleEmailTemplateSelect({detail:[]});
                    this.showSpinner = false;
                } else if (this.isRelatedList) {
                    console.log('checkpoint 0.8');
                    // this.selectedTemplate = this.currentPageReference?.state?.c__templateIdToGenerate;
                    this.handleCalledFromRelatedList();
                } else if (isAutoGeneration) {
                    console.log('checkpoint 0.9');
                    
                    this.handleAutoGeneration();
                } else if(this.currentPageReference.type === "standard__quickAction" && this.currentPageReference?.attributes?.apiName?.split('.')[1] !== 'DG_Generate_Document' && !this.currentPageReference?.attributes?.apiName?.split('.')[1]?.startsWith('DGP_')){
                    console.log('checkpoint 1');
                    let templateToAutoGenerate = this.allTemplates.find(item => item.MVDG__Button_Api_Name__c === this.currentPageReference?.attributes?.apiName?.split('.')[1]);
                    if(templateToAutoGenerate){
                        this.selectedTemplate = templateToAutoGenerate.Id;
                        this.handleAutoGeneration();
                    }else{
                        this.showWarningPopup('error', 'Something went wrong!', 'The Template Couldn\'t be found or does not exist!');
                        this.isClosableError = true;
                    }
                } else if(this.currentPageReference.type === "standard__quickAction" && this.currentPageReference?.attributes?.apiName?.split('.')[1] === 'DG_Generate_Document'){
                    console.log('checkpoint 2');
                    this.handleEmailTemplateSelect({detail:[]});
                    this.isAllExceptCSV = true;
                    this.allTemplates = this.allTemplates.filter(item => item.MVDG__Template_Type__c !== 'CSV Template');
                    this.showSpinner = false;
                } else if(this.currentPageReference.type === "standard__quickAction" && this.currentPageReference?.attributes?.apiName?.split('.')[1]?.startsWith('DGP_')){
                    console.log('checkpoint 3');
                    this.isProcessDefined = true;
                    this.handleEmailTemplateSelect({detail:[]});
                    this.isAllExceptCSV = true;
                    this.allTemplates = this.allTemplates.filter(item => item.MVDG__Template_Type__c !== 'CSV Template');
                    this.showSpinner = false;
                }
            })
            .catch(e => {
                this.showSpinner = false;
                errorDebugger('generateDocumentV2', 'connectedCallback > promise', e, 'error');
            });
        }catch(e){
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'connectedCallback', e, 'error');
        }
    }

    fetchFieldMapping() {
        try {
            getFieldMappingKeys({ sourceObjectAPI: this.objectApiName ? this.objectApiName : this.internalObjectApiName, getParentFields: true })
                .then(result => {
                    if (result.isSuccess) {
                        this.fieldMappingsWithObj = result.fieldMappingsWithObj[0];
                        let fieldOptions = [];
                    this.keyOptions = [];
                    let allowedTypes = ['STRING', 'PICKLIST', 'TEXTAREA', 'URL'];
                    this.fieldMappingsWithObj.fieldMappings
                        .filter(field => allowedTypes.includes(field.type))
                        .forEach(field => {
                            let transformedValue = field.key.replace(/{{#(.*)}}/, '$1');
                            let keyValue = '{{#' + transformedValue + '}}';
                            fieldOptions.push({
                                label: field.label,
                                value: transformedValue
                            });
                            this.keyOptions.push({
                                label: field.label,
                                value: keyValue
                            });
                        });
                    this.originalFieldLabelOptions = JSON.parse(JSON.stringify(fieldOptions));
                    this.fieldLabelOptions = this.updateAvailableOptions(); // Initialize with filtered options
                    }
                })
                .catch(error => {
                this.showSpinner = false;
                errorDebugger('generateDocumentV2', 'fetchFieldMapping', error, 'error');
                });
        } catch (error) {
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'fetchFieldMapping', error, 'error');
        }
    }

    updateAvailableOptions() {
        let fieldsToExclude = [];
        if (this.selectedEmailType === 'to') {
            fieldsToExclude = [...this.ccFields, ...this.bccFields];
        } else if (this.selectedEmailType === 'cc') {
            fieldsToExclude = [...this.toFields, ...this.bccFields];
        } else if (this.selectedEmailType === 'bcc') {
            fieldsToExclude = [...this.toFields, ...this.ccFields];
        }

        let currentFields = [];
        if (this.selectedEmailType === 'to') {
            currentFields = this.toFields;
        } else if (this.selectedEmailType === 'cc') {
            currentFields = this.ccFields;
        } else if (this.selectedEmailType === 'bcc') {
            currentFields = this.bccFields;
        }

        return this.originalFieldLabelOptions
            .filter(option => !fieldsToExclude.includes(option.value))
            .map(option => ({
                ...option,
                isSelected: currentFields.includes(option.value)
            }));
    }

    disconnectedCallback(){
        if (typeof window !== 'undefined') {
            window.removeEventListener('message', this.simpleTempFileGenResponse);
        }
    }

    handleFieldLabelSelect(event) {
        try {
            const selectedValues = Array.isArray(event.detail) ? event.detail : []; 
            this.selectedFieldLabels = selectedValues.map(item => item.replace(/{{#|}}|"|"/g, '')); 

            if (this.selectedEmailType === 'to') {
                this.toFields = [...new Set(this.selectedFieldLabels)];
                this.ccFields = this.ccFields.filter(f => !this.selectedFieldLabels.includes(f));
                this.bccFields = this.bccFields.filter(f => !this.selectedFieldLabels.includes(f));
            } else if (this.selectedEmailType === 'cc') {
                this.ccFields = [...new Set(this.selectedFieldLabels)];
                this.toFields = this.toFields.filter(f => !this.selectedFieldLabels.includes(f));
                this.bccFields = this.bccFields.filter(f => !this.selectedFieldLabels.includes(f));
            } else if (this.selectedEmailType === 'bcc') {
                this.bccFields = [...new Set(this.selectedFieldLabels)];
                this.toFields = this.toFields.filter(f => !this.selectedFieldLabels.includes(f));
                this.ccFields = this.ccFields.filter(f => !this.selectedFieldLabels.includes(f));
            }  

            this.previousFieldLabels = [...this.selectedFieldLabels];
            this.fieldLabelOptions = this.updateAvailableOptions();

            let combobox = this.template.querySelector('c-custom-combobox-v2.emailTempSelect');
            if (combobox) {
                combobox.value = this.selectedFieldLabels;
            }

            this.dispatchEvent(new CustomEvent('change', {
                detail: { value: this.selectedFieldLabels }
            }));

            this.validateToEmails();
        } catch (error) { 
            console.error('Error processing field labels:', error);
            errorDebugger('generateDocumentV2', 'handleFieldLabelSelect', error, 'error');
            this.selectedFieldLabels = [];
            this.previousFieldLabels = [];
        }
    }

    handleEmailTypeChange(event) {
        try {
            let selectedValue = Array.isArray(event.detail) && event.detail.length > 0 ? event.detail[0] : '';
            this.selectedEmailType = selectedValue;
            // console.log('Selected Email Type:', this.selectedEmailType);

            if (this.selectedEmailType === 'cc') {
                this.showCC = true;
            } else if (this.selectedEmailType === 'bcc') {
                this.showBCC = true;
            }

            let combobox = this.template.querySelector('c-custom-combobox-v2.emailTempSelect');
            if (combobox) {
                combobox.clearValue();
            } else {
                console.error('Combobox element not found');
            }

            this.selectedFieldLabels = [];
            this.previousFieldLabels = [];

            if (this.selectedEmailType === 'to') {
                this.selectedFieldLabels = [...(this.toFields || [])];
            } else if (this.selectedEmailType === 'cc') {
                this.selectedFieldLabels = [...(this.ccFields || [])];
            } else if (this.selectedEmailType === 'bcc') {
                this.selectedFieldLabels = [...(this.bccFields || [])];
            }
            // console.log('Updated selectedFieldLabels:', JSON.stringify(this.selectedFieldLabels));

            this.fieldLabelOptions = this.updateAvailableOptions();

            if (combobox) {
                combobox.value = this.selectedFieldLabels;
            }

            this.dispatchEvent(new CustomEvent('change', {
                detail: { value: this.selectedFieldLabels }
            }));
        } catch (error) {
            console.error('Error in handleEmailTypeChange:', error);
            errorDebugger('generateDocumentV2', 'handleEmailTypeChange', error, 'error');
        }
    }

    renderedCallback() {
        try{
            if(this.isInitialStyleLoaded) return;
            if (typeof window !== 'undefined') {
                let updatedStyle = document.createElement('style');
                updatedStyle.innerText = `
    
                    :host{
                        --border-color-of-email-body: darkgray;
                    }
    
                    .slds-modal__container{
                        padding:0;
                    }
                    .slds-modal__content{
                        border-radius: 0.5rem !important;
                    }
                    .modal-container.slds-modal__container {
                        width: 100%;
                        max-width: 100%;
                    }
    
                    .modal-container {
                        width: 100%;
                        padding: 0 15%;
                        min-width : unset;
                        max-width : unset;
                    }
                    .body-div .fix-slds-input_faux {
                        height: unset !important;
                    }
                        
                    .body-div button.slds-button.slds-color-picker__summary-button.slds-button_icon.slds-button_icon-more {
                        border: 1px solid darkgray;
                    }
    
                    .body-div .slds-rich-text-editor__textarea:last-child .slds-rich-text-area__content {
                        resize: vertical;
                        max-height: fit-content;
                        border-radius : 0.5rem;
                    }
                        
                    .body-div .slds-textarea {
                        min-height: 10rem;
                        height: 10rem;
                        border-radius: 0.5rem;
                        border: 1px solid darkgray;
                        box-shadow: none;
                    }
    
                    .body-div .slds-textarea:focus{
                        border-color: #00aeff;
                    }
    
                    .body-div .slds-rich-text-editor{
                        border: 1px solid var(--border-color-of-email-body, darkgray) !important;
                    }
    
                    .body-div .slds-rich-text-editor__toolbar.slds-shrink-none {
                        background-color: white;
                    }
                    .body-div .slds-has-focus{
                        box-shadow:none;
                        --border-color-of-email-body : #00aeff;
                    }
                    
                    .body-div .slds-rich-text-editor__toolbar{
                        border-bottom: 1px solid darkgray;
                    }
                    
                    .body-div :focus-visible{
                        outline : none;
                        box-shadow:none;
                    }
        
                    .body-div .slds-button_icon-border-filled{
                        border: 1px solid darkgray;
                        border-radius: 0.25rem;
                    }
                    .body-div .slds-button--icon-border-filled{
                        border: 1px solid darkgray;
                        border-radius: 0.25rem;
                    }
                    .body-div .slds-button_icon-border{
                        border: 1px solid darkgray;
                        border-radius: 0.25rem;
                    }
                    .body-div .slds-button--icon-border{
                        border: 1px solid darkgray;
                        border-radius: 0.25rem;
                    }
                    .body-div .slds-input_faux{
                        border: 1px solid darkgray;
                        border-radius: 0.25rem;
                    }
    
    
                    @media (max-width: 1440px) {
                        .modal-container {
                            width: 100%;
                            padding: 0 10%;
                            min-width : unset;
                            max-width : unset;
                        }
                    }
                    @media (max-width: 1024px) {
                        .modal-container {
                            width: 100%;
                            padding: 0 5%;
                            min-width : unset;
                            max-width : unset;
                            margin : 0;
                        }
                    }
                `;
                this.template.querySelector('.main-generate-document-div').appendChild(updatedStyle);
            }

            if(!this.customTimeout){
                this.customTimeout = this.template.querySelector('c-custom-timeout');
            }
            this.isInitialStyleLoaded = true;
        }catch (e) {
            errorDebugger('generateDocumentV2', 'renderedCallback', e, 'error');
        }

    }

    handleCalledFromRelatedList(){        
        this.handleSelectTemplate({ detail: [{ Id: this.selectedTemplate }] });
        this.showSpinner = false;
    }

    handleCalledFromPreview() {
        this.isCalledFromPreview = true;
        this.template.host.classList.add('pou-up-view');
        this.template.querySelector('.template-select-div').style.display = 'none';
        this.handleSelectTemplate({ detail: [{ Id: this.templateIdFromParent }] });
        this.handleEmailTemplateSelect({detail:[null]});
        this.showSpinner = false;
    }
    
    handleCalledFromDefaults() {
        try{
            this.isCalledFromDefaults = true;
            this.handleSelectTemplate({ detail: [{ Id: this.templateIdFromParent }] });
            this.fetchAllButtonNames()
            .then(() => {
                this.handleAutoGeneration();
                this.showSpinner = false;
            })
            .catch(e => {
                this.showSpinner = false;
                errorDebugger('generateDocumentV2', 'handleCalledFromDefaults > fetchAllButtonNames', e, 'error');
            });
        }catch(e){
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'handleCalledFromDefaults', e, 'error');
        }
    }

    handleCalledFromDefaultProcess() {
        try{
            this.isCalledFromDefaultProcess = true;
            this.showSpinner = false;
            this.generalDocumentTypes[0].isSelected = true;
            
        }catch(e){
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'handleCalledFromDefaultProcess', e, 'error');
        }
    }

    handleConfirmation(event){
        if(event.detail){
            if(this.isClosableError){
                this.handleClose();
            }else if(this.isButtonGeneration){
                this.handleCreateButton(true);
            }
        }
        this.isClosableError = false;
        this.isButtonGeneration = false;
    }

    handleTimeout(event){
        try {
            if(event?.detail?.function){
                event?.detail?.function();
            }
        } catch (error) {
            errorDebugger('DocumentLoaderV2', 'handleTimeout', error, 'warn')
        }
    }

    handleAutoGeneration() {
        this.showSpinner = true;
        try {
            // console.log('template id: ' + this.selectedTemplate);
            // console.log('record id: ' + this.recordId);
            getTemplateDefaultValues({ templateId: this.selectedTemplate, recordId: this.recordId })
                .then((data) => {
                    if (data) {
                        if (!data.templateStatus && !this.isCalledFromDefaults) {
                        this.showSpinner = false;
                        this.showWarningPopup('error', 'Inactive Template', 'The template you are trying to generate document from is inactive, please make it active to generate document.');
                        this.isClosableError = true;
                        return;
                    }
                        if (data?.docType) {
                            this.documentTypes.forEach(dt => { dt.isSelected = false; });
                        this.documentTypes.find(item => item.name === data?.docType).isSelected = true;
                    }
                    this.showEmailSection = data?.oChannel?.includes('Email') ? true : false;
                    this.template.querySelector('.email-create-div').style.display = this.showEmailSection ? 'unset' : 'none';
                        data?.iStorage?.split(', ')?.forEach((option) => {
                            this.internalStorageOptions.find(item => item.name === option).isSelected = true;
                        });
                        if (this.internalStorageOptions.find(item => item.name === 'Documents')?.isSelected) {
                        this.selectedFolder = data?.folderId;
                            if (this.isCalledFromDefaults && !this.allFolders.find(item => item.value === this.selectedFolder)) {
                            this.showWarningPopup('info', 'Folder not found!', 'The folder you selected to save documents does not exist, please select the folder.');
                            this.selectedFolder = null;
                        }
                        this.showFolderSelection = true;
                    } 
                    data?.eStorage?.split(', ')?.forEach((option) => {
                            let storageOption = this.externalStorageOptions.find(item => item.name === option);
                        if (storageOption) storageOption.isSelected = !storageOption.isDisabled;
                    });
                        data?.oChannel?.split(', ')?.forEach((option) => {
                            this.outputChannels.find(item => item.name === option).isSelected = true;
                        });
                        if (data?.emailAddresses?.includes('<|DGE|>')) {
                            let splitEmails = data.emailAddresses.split('<|DGE|>');
                            this.toEmails = splitEmails[0] ? splitEmails[0].split(',').map(email => email.trim()).filter(email => email !== '') : [];
                            this.ccEmails = splitEmails[1] ? splitEmails[1].split(',').map(email => email.trim()).filter(email => email !== '') : [];
                            this.bccEmails = splitEmails[2] ? splitEmails[2].split(',').map(email => email.trim()).filter(email => email !== '') : [];
                            this.toFields = splitEmails[3] ? splitEmails[3].split(',').map(field => field.trim()).filter(field => field !== '') : [];
                            this.ccFields = splitEmails[4] ? splitEmails[4].split(',').map(field => field.trim()).filter(field => field !== '') : [];
                            this.bccFields = splitEmails[5] ? splitEmails[5].split(',').map(field => field.trim()).filter(field => field !== '') : [];
                            this.selectedFieldLabels = this.bccFields ? [...this.bccFields] : [];
                            this.fieldLabelOptions = this.fieldLabelOptions.map(option => ({
                                ...option,
                                isSelected: this.selectedFieldLabels.includes(option.value)
                            })); 
                            this.dispatchEvent(new CustomEvent('change', {
                                detail: { value: this.selectedFieldLabels }
                            }));   
                            if (this.toFields.length > 0) {
                                this.selectedEmailType = 'to';
                                this.handleFieldLabelSelect({ detail: this.toFields });
                            }
                            if (this.ccFields.length > 0) {
                                this.selectedEmailType = 'cc';
                                this.handleFieldLabelSelect({ detail: this.ccFields });
                            }
                            if (this.bccFields.length > 0) {
                                this.selectedEmailType = 'bcc';
                                this.handleFieldLabelSelect({ detail: this.bccFields });
                            } 
                    }
                        this.selectedEmailTemplate = data?.emailTemplate ? data.emailTemplate : null;
                        this.handleEmailTemplateSelect({ detail: [this.selectedEmailTemplate] });
                        this.emailSubject = data?.emailSubject ? data.emailSubject : '';
                        this.emailBody = data?.emailBody ? data.emailBody : '';
                        this.buttonLabel = data?.buttonLabel ? data.buttonLabel : (this.templateNameFromParent ? this.templateNameFromParent.length > 80 ? this.templateNameFromParent.slice(0, 80) : this.templateNameFromParent : '');
                    this.buttonName = data?.buttonName || null;
                        if (this.buttonName && this.allButtons.includes(this.buttonName)) {
                        this.isOldButton = true;
                        this.bottomBtnLabel = 'Update Defaults';
                        } else {
                        this.buttonName = null;
                    }
                        this.fileName = this.templateName?.slice(0, 240);
                    this.showCC = this.ccEmails.length > 0 ? true : false;
                    this.showBCC = this.bccEmails.length > 0 ? true : false;
                    this.isAdditionalInfo = true;
                        if (!this.isCalledFromDefaults) {
                        this.showSpinner = true;
                            // Wait for handleGenerate to finish before hiding spinner
                            Promise.resolve(this.handleGenerate()).finally(() => {
                                this.showSpinner = false;
                            });
                        } else {
                            this.showSpinner = false;
                        }
                        
                        if (data?.toValues?.length > 0) {
                            this.toverified = data.toValues.filter(value =>
                                typeof value === 'string' && this.emailregex.test(value.trim())
                            );
                        }
                        if (data?.ccValues?.length > 0) {
                            this.ccverified = data.ccValues.filter(value =>
                                typeof value === 'string' && this.emailregex.test(value.trim())
                            );
                        }
                        if (data?.bccValues?.length > 0) {
                            this.bccverified = data.bccValues.filter(value =>
                                typeof value === 'string' && this.emailregex.test(value.trim())
                            );
                        } 
                        // console.log('toVerified Emails:', this.toverified);
                        // console.log('ccVerified Emails:', this.ccverified);
                        // console.log('bccVerified Emails:', this.bccverified);
                    } else {
                    this.showWarningPopup('error', 'Something went wrong!', 'The Template Couldn\'t be found or does not exist!');
                    this.isClosableError = true;
                }
            })
                .catch((e) => {
                errorDebugger('generateDocumentV2', 'getTemplateDefaultValues', e, 'error');
                    if (e.body.message.includes('Insufficient permissions')) {
                    this.showSpinner = false;
                    this.showWarningPopup('error', 'Insufficient permissions', 'Please check the permissions to access the data...');
                    this.isClosableError = true;
                    } else {
                    this.showToast('error', 'Something went Wrong!', 'Couldn\'t get default values, please try again...', 5000);
                }
                });
        } catch (e) {
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'handleAutoGeneration', e, 'error');
            this.showToast('error', 'Something went Wrong!', 'Couldn\'t get default values, please try again...', 5000);
        }
    }

    fetchCombinedData(){
        return new Promise((resolve, reject) => {
            try {
                getCombinedData({objName: this.internalObjectApiName})
                .then((data) => {
                    if (data.isSuccess){
                        this.isEditorAccess = data.isEditorAccess;
                        this.setUpAllTemplates(data.templates);
                        this.setUpIntegrationStatus(data.integrationWrapper);
                        this.setUpAllFolders(data.folderWrapper);
                        this.setUpAllEmailTemplates(data.emailTemplates);
                    } else {
                        this.showWarningPopup('error', 'Something Went Wrong!', 'We couldn\'t fetch the required data, please try again!');
                        this.isClosableError = true;
                    }
                    resolve();
                })
                .catch((e) =>{
                    reject(e);
                    errorDebugger('generateDocumentV2', 'getCombinedData', e, 'error');
                    this.showToast('error', 'Something went wrong!', 'We couldn\'t fetch the required data, try again!', 5000);
                })
            } catch (e) {
                reject(e);
                errorDebugger('generateDocumentV2', 'fetchCombinedData', e, 'error');
            }
        })
    }

    setUpAllTemplates(templates){
        try {
            if(this.isCSVOnly){
                templates = templates.filter(t => t.MVDG__Template_Type__c==='CSV Template');
            }
            this.allTemplates = templates.map((temp, index) => {
                const formattedDate = new Date(temp.LastModifiedDate).toLocaleDateString("en-US");
                return {
                    ...temp,
                    isSelectable : temp.MVDG__Template_Status__c,
                    isEditable : true,
                    LastModifiedDate: formattedDate,
                    index: +index + 1
                };
            });
            if(this.templateIdFromParent && !this.allTemplates.find(temp => temp.Id === this.templateIdFromParent)){
                this.showWarningPopup('error', 'Something went wrong!', 'The Template Couldn\'t be found or does not exist!');
                this.isClosableError = true;
                return;
            } 
            this.activeTemplates = this.allTemplates.filter(temp => temp.isSelectable === true);
            this.templateList =  this.activeTemplates.map((template) =>{
                return {
                    label:template.MVDG__Template_Name__c, value:template.Id
                }
            });
        } catch (e) {
            errorDebugger('generateDocumentV2', 'setUpAllTemplates', e, 'error');
        }
    }

    setUpIntegrationStatus(integrations){
        try {
            this.externalStorageOptions.find( o => o.name=== 'Google Drive').isDisabled = !integrations.isGoogleDriveIntegrated;
            this.externalStorageOptions.find( o => o.name=== 'AWS').isDisabled = !integrations.isAWSIntegrated;
            this.externalStorageOptions.find( o => o.name=== 'Dropbox').isDisabled = !integrations.isDropBoxIntegrated;
            this.externalStorageOptions.find( o => o.name=== 'One Drive').isDisabled = !integrations.isOneDriveIntegrated;
            if(!integrations.isUserWideAccessible && !integrations.isGoogleDriveIntegrated){
                this.isNotGoogleNotGenerable = true;
                this.allTemplates = this.allTemplates.map((t)=> {
                    return {
                        ...t,
                        isSelectable: t.MVDG__Template_Type__c === 'Google Doc Template' ? false : t.isSelectable,
                        isEditable: t.MVDG__Template_Type__c === 'Google Doc Template' ? false : t.isEditable
                    }
                })
            }else if(!integrations.isUserWideAccessible){
                this.allTemplates = this.allTemplates.map((t)=> {
                    return {
                        ...t,
                        isEditable: t.MVDG__Template_Type__c === 'Google Doc Template' ? false : t.isEditable
                    }
                })
            }
        } catch (e) {
            errorDebugger('generateDocumentV2', 'setUpIntegrationStatus', e, 'error');
        }
    }

    setUpAllFolders(folders){
        try {
            this.allFolders = folders;
            this.selectedFolder = this.allFolders[0].value;
        } catch (e) {
            errorDebugger('generateDocumentV2', 'setUpAllFolders', e, 'error');
        }
    }

    setUpAllEmailTemplates(data) {
            try {
                if(data){
                    this.allEmailTemplates = data;
                    this.emailTemplatesToShow = this.allEmailTemplates.map((temp) => {
                        return {
                            label: temp.Name,
                            value : temp.Id
                        }
                    });
                }
            } catch (e) {
                this.showToast('error', 'Something went wrong!', 'We couldn\'t fetch email templates!', 5000);
                errorDebugger('generateDocumentV2', 'setUpAllEmailTemplates', e, 'error');
            }
    }

    fetchAllButtonNames(){
        return new Promise((resolve, reject) =>{
            try{
                getButtonNames({objName : this.internalObjectApiName})
                .then((data) => {
                    this.allButtons = data;
                    resolve();
                })
                .catch((e) =>{
                    reject();
                    this.showToast('error', 'Something went wrong!', 'We couldn\'t fetch buttons on object!', 5000);
                    errorDebugger('generateDocumentV2', 'getButtonNames', e, 'error');
                })
            }catch (e) {
                reject();
                this.showToast('error', 'Something went wrong!', 'We couldn\'t fetch buttons on object!', 5000);
                errorDebugger('generateDocumentV2', 'fetchAllButtonNames', e, 'error');
            }
        })
    }

    handleSelectTemplate(event){
        try{
            this.showSpinner = true;
            let result = event.detail[0]?.Id;
            this.selectedTemplate = result || null;
            console.log('Logging select template');
            
            if(!this.isRelatedList){
                this.fileName = this.templateName?.slice(0,240);
            }
            else{
                this.fileName = '{{#Name}}_'
            }
            this.csvDocumentTypes.forEach(dt => {dt.isSelected = false});
            this.generalDocumentTypes.forEach(dt => {dt.isSelected = false});
            // console.log(this.isCSVOnly);
            
            if (this.isCSVTemplate) {
                this.csvDocumentTypes[0].isSelected = true;
                this.internalStorageOptions.find(item => item.name === 'Notes & Attachments').isDisabled = true;
            }else{
                this.generalDocumentTypes[0].isSelected = true;
                this.internalStorageOptions.find(item => item.name === 'Notes & Attachments').isDisabled = false;
            }
            
            if (this.isRelatedList) {
                // this.internalStorageOptions.find(item => item.name === 'Notes & Attachments').isDisabled = true;
                // this.internalStorageOptions.find(item => item.name === 'Files').isDisabled = true;
                this.internalStorageOptions.find(item => item.name === 'Chatter').isDisabled = true;
                // this.internalStorageOptions.find(item => item.name === 'Documents').isDisabled = true;
                this.externalStorageOptions.find(item => item.name === 'One Drive').isDisabled = true;
                this.externalStorageOptions.find(item => item.name === 'Google Drive').isDisabled = true;
                this.externalStorageOptions.find(item => item.name === 'Dropbox').isDisabled = true;
                this.externalStorageOptions.find(item => item.name === 'AWS').isDisabled = true;
            }

            if (this.isProcessDefined){
                fetchProcessDefinedData({ apiName: this.currentPageReference?.attributes?.apiName?.split('.')[1]})
                .then((data) => {
                    if(data){
                        if(data?.docType){
                            this.documentTypes.forEach(dt => {dt.isSelected = false});
                            this.documentTypes.find(item => item.name === data?.docType).isSelected = true;
                        }
                        this.showEmailSection = data?.oChannel?.includes('Email') ? true : false;
                        this.template.querySelector('.email-create-div').style.display = this.showEmailSection ? 'unset' : 'none';
                        data?.iStorage?.split(', ')?.forEach((option) => {this.internalStorageOptions.find(item => item.name === option).isSelected = true});
                        if(this.internalStorageOptions.find(item => item.name === 'Documents')?.isSelected){
                            this.selectedFolder = data?.folderId;
                            if(this.isCalledFromDefaults && !this.allFolders.find(item => item.value === this.selectedFolder)){
                                this.showWarningPopup('info', 'Folder not found!', 'The folder you selected to save documents does not exist, please select the folder.');
                                this.selectedFolder = null;
                            }
                            this.showFolderSelection = true;
                        } 
                        data?.eStorage?.split(', ')?.forEach((option) => {
                            const storageOption = this.externalStorageOptions.find(item => item.name === option);
                            if (storageOption) storageOption.isSelected = !storageOption.isDisabled;
                        });
                        data?.oChannel?.split(', ')?.forEach((option) => {this.outputChannels.find(item => item.name === option).isSelected = true});
                        if(data?.emailAddresses?.includes('<|DGE|>')){
                            const splitEmails = data?.emailAddresses.split('<|DGE|>');
                            this.toEmails = splitEmails[0] ? splitEmails[0].split(',').map(email => email.trim()) : [];
                            console.log(this.toEmails);
                            this.ccEmails = splitEmails[1] ? splitEmails[1].split(',').map(email => email.trim()) : [];
                            this.bccEmails = splitEmails[2] ? splitEmails[2].split(',').map(email => email.trim()) : [];
                            this.selectedFieldLabels = splitEmails[3] ? splitEmails[3].split(',').map(field => field.trim()) : [];
                            this.selectedEmailType = splitEmails[4] ? splitEmails[4].trim() : '';
                            this.handleFieldLabelSelect({ detail: this.selectedFieldLabels });
                            
                        }
                        this.selectedEmailTemplate = data?.emailTemplate ? data?.emailTemplate : null;
                        this.handleEmailTemplateSelect({detail:[this.selectedEmailTemplate]});
                        this.emailSubject = data?.emailSubject ? data?.emailSubject : '';
                        this.emailBody = data?.emailBody ? data?.emailBody : '';
                        this.fileName = this.templateName?.slice(0,240);
                        this.showCC = this.ccEmails.length > 0 ? true : false;
                        this.showBCC = this.bccEmails.length > 0 ? true : false;
                        this.isAdditionalInfo = true;
                        this.showSpinner = false;
                        if(!this.isCalledFromDefaults){
                            this.showSpinner = true;
                            this.handleGenerate();
                        } 

                        this.verifiedEmails = [];
                            if (data?.recordValues?.length > 0) {
                                this.verifiedEmails = data.recordValues.filter(value => 
                                    typeof value === 'string' && this.emailregex.test(value.trim())
                                );
                            }
                        console.log('Verified Emails in auto generation :', this.verifiedEmails);
                    }else{
                        this.showSpinner = false;
                        this.showWarningPopup('error', 'Something went wrong!', 'The Template Couldn\'t be found or does not exist!');
                        this.isClosableError = true;
                    }
                })
                .catch((e) => {
                    this.showToast('error', 'Something went wrong!', 'We couldn\'t fetch buttons on object!', 5000);
                    errorDebugger('generateDocumentV2', 'fetchProcessDefinedData', e, 'error');
                })         
            }
        }catch(e){
            errorDebugger('generateDocumentV2', 'handleSelectTemplate', e, 'error');
        }finally{
            this.showSpinner = false;
        }
    }

    openViewAllTemplates(){
        this.showAllTemplates = true;
    }

    handleRecordPickerError(event){
        errorDebugger('generateDocumentV2', 'handleRecordPickerError', event, 'error');
    }

    handleFileNameChange(event){
        if(event.key == 'Enter' && this.isExpand == true){
            this.isExpand = false;
        }
        this.fileName = event.target.value;
        if(this.fileName.length > 240){
            this.fileName = this.fileName.slice(0, 240);
            this.showToast('error', 'File name too Long!', 'Please use smaller name.', 5000);
        }        
    }

    handleAdditionalInfo(event){
        this.isAdditionalInfo = event.target.checked;
    }

    handleDownloadZip(event){
        if(this.selectedChannels.includes('Download')){
            this.isDownloadZip = event.target.checked;
        }
        else{
            this.isDownloadZip = false;
        }
        // console.log(this.isDownloadZip);
        
    }

    handleParentStorage(event){
        if(this.selectedChannels.includes('Notes & Attachments') || this.selectedChannels.includes('Files')){
            this.isOnParent = event.target.checked;
        }
        else{
            this.isOnParent = false;
        }
    }

    //Navigate to respective template builder
    handleEditClick() {
        try{
            this.showSpinner = true;
            let paramToPass = {
                templateId : this.selectedTemplate,
                objectName : this.internalObjectApiName,
            }
            if(this.templateType === 'Simple Template'){
                this.navigateToComp(navigationComps.simpleTemplateBuilder, paramToPass);
            }else if(this.templateType === 'CSV Template'){
                this.navigateToComp(navigationComps.csvTemplateBuilder, paramToPass);
            }else if(this.templateType === 'Google Doc Template'){
                this.navigateToComp(navigationComps.googleDocTemplateEditor, paramToPass);
            }
        }catch(e){
            errorDebugger('generateDocumentV2', 'handleEditClick', e, 'error');
        }finally{
            this.showSpinner = false;
        }
    }
    //Email Section
    toggleCC(){
        try {
            this.showCC = !this.showCC;
        }catch (e) {
            errorDebugger('generateDocumentV2', 'toggleCC', e, 'error');
        }
    }
    toggleBCC(){
        try {
            this.showBCC = !this.showBCC;
        }catch (e) {
            errorDebugger('generateDocumentV2', 'toggleBCC', e, 'error');
        }
    }

    handleToEmailChange(event){
        try {
            let emailString = event.target.value?.trim();
            let enteredChar = event.key;
            let typeOfEmail = event.target.dataset.type;
            if(enteredChar === ',' || enteredChar === 'Enter' || enteredChar === ' ' || enteredChar === 'Tab'  || !enteredChar){
                var emailValidator = /^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i;
                emailString.toLowerCase().replaceAll(' ', ',').split(',').forEach((email)=>{
                    if(email){
                        if(emailValidator.test(email)){
                            email = email.trim();
                            event.target.value = null;
                            if(!this[typeOfEmail+'Emails'].includes(email)) this[typeOfEmail+'Emails'].push(email);
                            this['is' + typeOfEmail.charAt(0).toUpperCase() + typeOfEmail.slice(1) + 'Error'] = false;
                            this.template.querySelector('.'+typeOfEmail + '-error-div')?.classList.add("not-display-div");
                            this.template.querySelector('.'+typeOfEmail + '-error-div').innerText = '';
                            event.target?.classList.remove("input-error-border");
                            event.preventDefault();
                        }else{
                            event.target.value = emailString;
                            this['is' + typeOfEmail.charAt(0).toUpperCase() + typeOfEmail.slice(1) + 'Error'] = true;
                            this.template.querySelector('.'+typeOfEmail + '-error-div').innerText = 'Please Enter valid Email..';
                            this.template.querySelector('.'+typeOfEmail + '-error-div')?.classList.remove("not-display-div");
                            event.target?.classList.add("input-error-border");
                        }
                    }
                })
            }
        }catch (e) {
            errorDebugger('generateDocumentV2', 'handleToEmailChange', e, 'error');
        }
    }

    handleRemoveAddedEmail(event){
        try{
            this.showSpinner = true;
            let index = event.currentTarget.dataset.index;
            let typeOfEmail = event.currentTarget.dataset.type;
            this[typeOfEmail+'Emails'].splice(index, 1);
            if(typeOfEmail === "to") this.validateToEmails();
        }catch (e) {
            errorDebugger('generateDocumentV2', 'handleRemoveAddedEmail', e, 'error');
        }finally{
            this.showSpinner = false;
        }
    }

    handleRemoveLabel(event) {
        try {
            this.showSpinner = true;
            const index = parseInt(event.currentTarget.dataset.index);
            const emailType = event.currentTarget.dataset.type;
            const removedLabel = event.currentTarget.dataset.label;

            if (!removedLabel) {
                console.error('No label found for removal:', { index, emailType });
                return;
            }

            this.selectedFieldLabels = this.selectedFieldLabels.filter(label => label !== removedLabel);

            if (emailType === 'to') {
                this.toFields = this.toFields.filter(field => field !== removedLabel);
            } else if (emailType === 'cc') {
                this.ccFields = this.ccFields.filter(field => field !== removedLabel);
            } else if (emailType === 'bcc') {
                this.bccFields = this.bccFields.filter(field => field !== removedLabel);
            } else {
                console.error('Invalid email type:', emailType);
                return;
            }

            this.previousFieldLabels = [...this.selectedFieldLabels];
            this.fieldLabelOptions = this.updateAvailableOptions(); 

            this.dispatchEvent(new CustomEvent('change', {
                detail: { value: this.selectedFieldLabels }
            }));

            let combobox = this.template.querySelector('c-custom-combobox-v2.emailTempSelect');
            if (combobox && removedLabel) {
                combobox.unselectOption(removedLabel);
            }

            // console.log('Removed label:', removedLabel, 'from', emailType, 'Updated selectedFieldLabels:', JSON.stringify(this.selectedFieldLabels));
        } catch (error) {
            console.error('Error in handleRemoveLabel:', error);
            errorDebugger('generateDocumentV2', 'handleRemoveLabel', error, 'error');
        } finally {
            this.showSpinner = false;
        }
    }

    validateToEmails(){
        try{
            let hasRecipients = this.toEmails.length > 0 || this.toFields.length > 0; 
            this.template.querySelector(".to-input").classList.toggle("input-error-border", !hasRecipients)
            this.template.querySelector(".to-error-div").innerText = hasRecipients ? '' : 'There must be at least one recipient..';
            this.template.querySelector(".to-error-div").classList.toggle("not-display-div", hasRecipients);
        }catch(e){
            errorDebugger('generateDocumentV2', 'validateToEmails', e, 'error');
        }
    }

    handleSubjectChange(event){
        try{
            this.emailSubject = event.target.value;
        }catch (e) {
            errorDebugger('generateDocumentV2', 'handleSubjectChange', e, 'error');
        }
    }

    handleBodyChange(event){
        try{
            this.emailBody = event.target.value;
        }catch (e) {
            errorDebugger('generateDocumentV2', 'handleBodyChange', e, 'error');
        }
    }

    handlePlainBodyChange(event){
        try {
            this.emailBody = event.target.value;
        } catch (e) {
            errorDebugger('generateDocumentV2', 'handlePlainBodyChange', e, 'error');
        }
    }

    handleEmailTemplateSelect(event) {
        try {
            this.selectedEmailTemplate = event.detail[0];
            this.template.host.style.setProperty('--display-for-email-body-div', this.selectedEmailTemplate ? "none" : "flex");
            this.template.host.style.setProperty('--display-for-email-preview-div', this.selectedEmailTemplate ? "flex" : "none");
            if(this.selectedEmailTemplate){
                this.previewEmailBody = this.allEmailTemplates.find(item => item.Id === this.selectedEmailTemplate)?.HtmlValue || this.allEmailTemplates.find(item => item.Id === this.selectedEmailTemplate)?.Body;
                this.emailSubject = this.allEmailTemplates.find(item => item.Id === this.selectedEmailTemplate)?.Subject || this.emailSubject;
            }else{
                this.emailSubject = '';
            }
        } catch (e) {
            errorDebugger('generateDocumentV2', 'handleEmailTemplateSelect', e, 'error');
        }
    }

    handleViewAsTypeSelect(event) {
        try {
            if(this.selectedViewAsType !== event.detail[0]){
                this.selectedViewAsType = event.detail[0];
                this.isPlainEmailBody = this.selectedViewAsType === "plain";
                this.template.host.style.setProperty('--display-of-the-rich-text',this.isPlainEmailBody ? "none" : "unset");
            }
        } catch (e) {
            errorDebugger('generateDocumentV2', 'handleViewAsTypeSelect', e, 'error');
        }
    }

    //Used for list of all the templates screen

    handleOptionSelection(event){
        try {
            console.log('Inside handle Option selection');
            
            this.showSpinner = true;
            let section = event.currentTarget.dataset.section;
            let option = event.currentTarget.dataset.item;
            let index = event.currentTarget.dataset.index;
            if(section==="type"){
                if(!this.selectedTemplate && this.isCalledFromDefaults){
                    return;
                }
                if(this.isCSVTemplate){
                    !this.csvDocumentTypes[index].isSelected ? this.csvDocumentTypes.forEach(dt => dt.isSelected = false) : undefined;
                    this.csvDocumentTypes[index].isSelected = true;
                }else{
                    !this.generalDocumentTypes[index].isSelected ? this.generalDocumentTypes.forEach(dt => dt.isSelected = false) : undefined;
                    this.generalDocumentTypes[index].isSelected = true;
                }
            }else if(section==='iStorage'){
                !this.internalStorageOptions[index].isDisabled ? this.internalStorageOptions[index].isSelected = !this.internalStorageOptions[index].isSelected : undefined;
                if(this.internalStorageOptions[index].name==='Documents'){
                    this.showFolderSelection = this.internalStorageOptions[index].isSelected;
                    if(this.showFolderSelection) this.selectedFolder = this.selectedFolder ? this.selectedFolder : this.allFolders[0]?.value;
                }
            }else if(section==='eStorage'){
                !this.externalStorageOptions[index].isDisabled ? this.externalStorageOptions[index].isSelected = !this.externalStorageOptions[index].isSelected : undefined;
            }else if(section==='output'){
                this.outputChannels[index].isSelected = !this.outputChannels[index].isSelected;
                if(option === "Download" && this.isRelatedList && this.outputChannels[index].isSelected == false){
                    this.isDownloadZip = false;
                    // console.log(this.isDownloadZip);
                }
                if(option==="Email"){
                    this.showEmailSection = this.outputChannels[index].isSelected;
                    this.template.querySelector('.email-create-div').style.display = this.showEmailSection ? 'unset' : 'none';
                    if(this.showEmailSection){
                        this.ccEmails.length>0 ? this.showCC=true : this.showCC= false;
                        this.bccEmails.length>0 ? this.showBCC=true : this.showBCC = false;
                        let mainDiv = this.template.querySelector('.main-container');
                        mainDiv.scrollTo({
                            top: mainDiv.scrollHeight,
                            left: 0,
                            behavior: "smooth",
                        });
                    }
                }
            }
        } catch (e) {
            errorDebugger('generateDocumentV2', 'handleOptionSelection', e, 'error');
        }finally{
            this.showSpinner = false;
        }
    }

    handleKeyClick(event){
        try {
            let inputbox = this.template.querySelector('.file-input');
            inputbox.value += event.target.dataset.value;

            this.fileName = inputbox.value;
            if(this.fileName.length > 240){
                this.fileName = this.fileName.slice(0, 240);
                inputbox.value = this.fileName;
                this.showToast('error', 'File name too Long!', 'Please use smaller name.', 5000);
            }
            // To bring cursor to the end
            const end = inputbox.value.length;
            inputbox.setSelectionRange(end, end);
            inputbox.focus();
            // console.log('inside handlekey click-->'+this.fileName);
            
        }
        catch (e) {
            errorDebugger('generateDocumentV2', 'handleKeyClick', e, 'error');
        }
    }

    handleTemplateSearch(event){
        this.templateSearchKey = event.target.value;
    }

    handleTemplateSelection(event){
        try{
            this.selectedTemplate = event.currentTarget.dataset.value;
            console.log('Selected Template: ', this.selectedTemplate);
            
            if(!this.isRelatedList){                
                this.fileName = this.selectedTemplate?.slice(0,240);
            }
            else {
                this.fileName = '{{#Name}}_';
            }
            this.handleSelectTemplate({detail:[{Id: this.selectedTemplate}]});
            console.log('Going back to generate');
            
            this.backToGenerate();
        }catch(e){
            errorDebugger('generateDocumentV2', 'handleTemplateSelection', e, 'error');
        }
    }

    handleTemplateEditClick(event){
        try{
            this.selectedTemplate = event.currentTarget.dataset.value;
            this.handleEditClick();
        }catch(e){
            errorDebugger('generateDocumentV2', 'handleTemplateEditClick', e, 'error');
        }
    }

    //Bottom Button Controls

    handleClose(){        
        if (typeof window !== 'undefined') {
            window?.removeEventListener('message', this.simpleTempFileGenResponse);
            if(this.currentPageReference.type === "standard__quickAction"){
                this.dispatchEvent(new CloseActionScreenEvent())
            }else if(this.isCalledFromPreview || this.isCalledFromDefaults || this.isCalledFromDefaultProcess){
                this.dispatchEvent(new CustomEvent('close'));
            }else{                
                location.replace(location.origin + '/lightning/o/' + this.internalObjectApiName + '/list' ,"_self");
            }
        }
    }

    bubbleSave(){
        try {
            this.showSpinner = true;

            if(this.selectedChannels.length < 1){
                this.showToast('error', 'Something Went Wrong!', 'Please select at least 1 storage or output channel.', 5000);
                return;
            }
            if(this.showEmailSection && this.toEmails.length < 1){
                this.validateToEmails();
                this.showToast('error', 'Something Went Wrong!', 'Please select at least one recipient to send email.', 5000);
                return;
            }
            if(this.selectedChannels.includes('Documents') && !this.selectedFolder){
                this.showSpinner = false;
                this.showToast('error', 'Something Went Wrong!', 'Please select folder to save document.', 5000);
                return;
            }
            let allEmailsString = '';
            allEmailsString += (this.toEmails.length>0 ? this.toEmails.join(', ') : '') + '<|DGE|>' + (this.ccEmails.length>0 ? this.ccEmails.join(', ') : '') + '<|DGE|>' + (this.bccEmails.length>0 ? this.bccEmails.join(', '): '') + '<|DGE|>' + this.selectedFieldLabels + '<|DGE|>' + this.selectedEmailType;
            console.log('allEmailString',allEmailsString);

            console.log('toEmails ',JSON.stringify(this.toEmails));
            console.log('ccEmails ',JSON.stringify(this.ccEmails));
            console.log('bccEmails ',JSON.stringify(this.bccEmails));
            console.log('selected field ',JSON.stringify(this.selectedFieldLabels));

            let iStorages = this.internalStorageOptions.filter(item => item.isSelected === true).map(item => {return item.name}).join(', ');
            let eStorages = this.externalStorageOptions.filter(item => item.isSelected === true).map(item => {return item.name}).join(', ');
            let oChannels = this.outputChannels.filter(item => item.isSelected === true).map(item => {return item.name}).join(', ');
            let defaults = {
                Name : 'DGP_'+this.internalObjectApiName,
                docType : this.selectedExtension?.slice(1,).toUpperCase(),
                iStorage : iStorages,
                folderId: this.selectedFolder,
                eStorage : eStorages,
                oChannel : oChannels,
                emailAddresses : allEmailsString,
                emailBody : this.emailBody,
                emailSubject : this.emailSubject,
                emailTemplate : this.selectedEmailTemplate
            }
            storeDefaultProcesses({defaultData: defaults})
            .then(() => {
                    this.showSpinner = false;
                    const event = new CustomEvent('save');
                    this.dispatchEvent(event);
            })
            .catch((e) => {
                this.showSpinner = false;
                errorDebugger('generateDocumentV2', 'bubbleSave > storeDefaultProcesses', e, 'error');
                this.showToast('error', 'Something went wrong!', 'Could not save default values, please try again!', 5000);
            });
            
        } catch (error) {
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'bubbleSave', e, 'error');
        }
    }

    handlePreview(){
        if(this.isCSVTemplate){
            this.showCSVPreview = true;
        }else if(this.templateType === 'Google Doc Template'){
            this.showSimplePreview = true;
        }else if(this.templateType === 'Simple Template'){
            this.showSimplePreview = true;
        }

    }

    handleDynamicName(){
        this.isExpand = !this.isExpand;
    }

    generateActivity() {
        return new Promise((resolve, reject) => {
            try {
                upsertActivity({ activity: this.activity })
                .then((result) => {
                    if(result){
                        this.activity.Id = result;
                        resolve(true);
                    }else{
                        reject('There was an error creating an activity for generation, please go back and try again...');
                    }
                })
                .catch((e) => {
                    errorDebugger('generateDocumentV2', 'generateActivity > upsertActivity', e, 'error');
                    reject('Could not start document generation, please check your org storage limits and try again!');
                });
            } catch (e) {
                errorDebugger('generateDocumentV2', 'generateActivity', e, 'error');
                reject('Could not start document generation, please try again!');
            }
        });
    }

    handleGenerate() {
        this.showSpinner = true;
    
        if (this.selectedChannels.length < 1) {
            this.showToast('error', 'Something Went Wrong!', 'Please select at least 1 storage or output channel.', 5000);
            this.showSpinner = false;
            return;
        }
    
        if (this.showEmailSection && this.toEmails.length < 1 && this.toFields.length < 1) {
            this.validateToEmails();
            this.showToast('error', 'Something Went Wrong!', 'Please select at least one recipient to send email.', 5000);
            this.showSpinner = false;
            return;
        }
    
        if (this.selectedChannels.includes('Documents') && !this.selectedFolder) {
            this.showToast('error', 'Something Went Wrong!', 'Please select folder to save document.', 5000);
            this.showSpinner = false;
            return;
        }

        this.activity.MVDG__DocGenius_Template__c = this.selectedTemplate;
        this.activity.MVDG__Selected_Channels__c = this.selectedChannels.join(',');
        if (!this.fileName && !this.isRelatedList) {
            const thisTemplate = this.allTemplates?.find(opt => opt.Id === this.selectedTemplate);
            this.fileName = thisTemplate?.MVDG__Template_Name__c?.slice(0, 240) || "DG_Document";
        }
        this.activity.MVDG__File_Name__c = this.fileName + this.selectedExtension;
        this.activity.MVDG__Related_Record_Id__c = this.isCSVTemplate ? null : this.recordId;

        const isQuickAction = this.currentPageReference?.type === "standard__quickAction";
        const isAutoGeneration = !isQuickAction && this.calledFromWhere !== "preview" && 
                                this.calledFromWhere !== "defaults" && !this.isCSVOnly && !this.isRelatedList;

        const processGeneration = () => {
        this.generateActivity()
                .then(result => {
                    if (!result) {
                        throw new Error('The activity couldn\'t be created for generation.');
                    }
                    if (this.isCSVTemplate) {
                        return this.handleGenerateCSVData();
                    } else if (this.templateType === 'Google Doc Template') {
                    this.generateGoogleDoc();
                    } else if (this.templateType === 'Simple Template') {
                    this.generateSimpleTemplateFile();
                }
                })
                .catch(e => {
                    const errorMsg = e?.message || e?.body?.message || 'Unknown Error';
                    ['Download', 'Notes & Attachments', 'Documents', 'Files', 'Chatter', 'Email', 'Google Drive', 'AWS', 'One Drive', 'Dropbox']
                        .forEach(key => this.failed[key] = errorMsg);
                    this.showWarningPopup('error', 'Something went wrong!', errorMsg);
                this.isClosableError = true;
        })
                .finally(() => {
                    this.showSpinner = false;
                });
        };

        if (!isQuickAction && !isAutoGeneration) {
            const allFields = [...new Set([...this.toFields, ...this.ccFields, ...this.bccFields])];
            if (allFields.length > 0 && this.internalObjectApiName && this.recordId) {
                queryRecord({
                    objectName: this.internalObjectApiName,
                    recordId: this.recordId,
                    fields: allFields
                })
                .then(result => {
                    this.toverified = this.toFields
                        .map(field => result[field])
                        .filter(value => typeof value === 'string' && this.emailregex.test(value.trim()));
                    this.ccverified = this.ccFields
                        .map(field => result[field])
                        .filter(value => typeof value === 'string' && this.emailregex.test(value.trim()));
                    this.bccverified = this.bccFields
                        .map(field => result[field])
                        .filter(value => typeof value === 'string' && this.emailregex.test(value.trim()));
                    
                    // console.log('toVerified Emails:', this.toverified);
                    // console.log('ccVerified Emails:', this.ccverified);
                    // console.log('bccVerified Emails:', this.bccverified);
                    
                    processGeneration();
                })
                .catch(e => {
                    errorDebugger('generateDocumentV2', 'handleGenerate > queryRecord', e, 'error');
                    this.showWarningPopup('error', 'Something went wrong!', 'Could not fetch field values: ' + e.body.message);
                    this.isClosableError = true;
                    this.showSpinner = false;
                });
            } else {
                processGeneration();
            }
        } else {
            processGeneration();
        }
    }

    //Back to generate
    backToGenerate(){
        this.templateSearchKey = null;
        this.noTemplateFound = this.allTemplates.length < 1 ? true : false;
        this.showAllTemplates = false;
        this.showCSVPreview = false;
        this.showGDocPreview = false;
        this.showSimplePreview = false;
    }

//-------------------------------------------------------CSV Preview / Generation Methods --------------------------------------------------------    

    handleGenerateCSVData() {
        this.showSpinner = true;
        return new Promise((resolve, reject) => {
            try {
                getTemplateData({ templateId: this.selectedTemplate })
                .then(data => {
                    if (!data) {
                        this.showToast('error', 'Something went wrong!', 'Nothing to generate, Please Update the Template...', 5000);
                        return;
                    }
                    if(data.error?.includes('Insufficient Access')){
                        this.showWarningPopup('error', 'Insufficient Access', data.error);
                        this.isClosableError = true;
                        return;
                    }
                    let fieldNames = data?.fields?.split(',');
                    let query = data?.query;
                    this.accessToken = data?.accessToken;
                    if (!this.accessToken) {
                        this.showToast('error', 'Something went wrong!', "Please verify connected app from user configuration.", 5000);
                        return;
                    }
                    if(!fieldNames || fieldNames?.length < 1){
                        this.showToast('error', 'Something went wrong!', 'No Columns Selected, Please Update the Template...', 5000);
                        return;
                    }
                    const generationCount = data?.count || 1000000;
    
                    if (this.selectedExtension === ".csv") {
                        let csvContent = '';
                        if (this.isAdditionalInfo) {
                            const thisTemplate = this.allTemplates.find(opt => opt.Id === this.selectedTemplate);
                            thisTemplate.MVDG__Description__c = thisTemplate.MVDG__Description__c || '-';
                            csvContent += 'Name : ,"' + thisTemplate.MVDG__Template_Name__c + '"\n'
                                + 'Description : ,"' + thisTemplate.MVDG__Description__c + '"\n'
                                + 'Object Api Name : ,' + thisTemplate.MVDG__Object_API_Name__c + '\n'
                                + 'CSV Creation Time : , ' + new Date().toLocaleString().replace(',', ' ') + '\n\n';
                        }
                        csvContent += fieldNames.join(',') + '\n';
    
                        const newQuery = '/services/data/v59.0/query/?q=' + query.split('LIMIT')[0];
    
                        this.fetchRecords(newQuery, this.accessToken, generationCount)
                        .then(isSuccess => {
                            if (isSuccess) {
                                if (this.fetchedResults.length === 0) {
                                    this.showToast('warning', 'Oops! No matching records Found!', 'Uh Oh!, Try changing the Filter criteria!!');
                                } else {
                                    this.fetchedResults.forEach((record) => {
                                        const rowValues = fieldNames.map(fieldName => {
                                            const value = this.getValueByKey(record, fieldName);
                                            return value ? `"${value}"` : '""';
                                        });
                                        csvContent += rowValues.join(',') + '\n';
                                    })
                                    this.generatedCSVData = csvContent;
                                }
                                this.generateCSVDocument();
                                resolve();
                            }
                        })
                        .catch(e => {
                            reject(e);
                            errorDebugger('generateDocumentV2', 'handleGenerateCSVData > fetchRecords > csv', e, 'error');
                            this.showToast('error', 'Oops! Something went wrong', 'Please make sure you have trusted url from user guide in effect...', 5000);
                        });
                    } else if (this.selectedExtension === '.xls') {
                        let xlsContent = '<table>';
                        xlsContent += '<style>';
                        xlsContent += 'table, th, td {';
                        xlsContent += '    border: 0.5px solid black;';
                        xlsContent += '    border-collapse: collapse;';
                        xlsContent += '}';          
                        xlsContent += '</style>';
    
                        if (this.isAdditionalInfo) {
                            const thisTemplate = this.allTemplates.find(opt => opt.Id === this.selectedTemplate);
                            thisTemplate.MVDG__Description__c = thisTemplate.MVDG__Description__c || '-';
                            xlsContent += '<tr> <th> Name : </th><td> ' + thisTemplate.MVDG__Template_Name__c + '</td></tr>'
                                + '<tr> <th> Description : </th><td> ' + thisTemplate.MVDG__Description__c + '</td></tr>'
                                + '<tr> <th> Object Api Name : </th><td> ' + thisTemplate.MVDG__Object_API_Name__c + '</td></tr>'
                                + '<tr> <th> CSV Creation Time : </th><td> ' + new Date().toLocaleString().replace(',', ' ') + '</td></tr>' + '<tr></tr>';
                        }
                        xlsContent += '<tr> <th> ' + fieldNames.join('</th><th>') + '</th> </tr>';
    
                        const newQuery = '/services/data/v59.0/query/?q=' + query.split('LIMIT')[0];
    
                        this.fetchRecords(newQuery, this.accessToken, generationCount)
                        .then(isSuccess => {
                            this.labelOfLoader = 'Arranging data...';
                            if (isSuccess) {
                                if (this.fetchedResults.length === 0) {
                                    this.showToast('warning', 'Oops! No matching records Found!', 'Uh Oh!, Try changing the Filter criteria!!');
                                } else {
                                    this.fetchedResults.forEach((record) => {
                                        const rowValues = fieldNames.map(fieldName => {
                                            const value = this.getValueByKey(record, fieldName);
                                            return value ? `${value}` : '';
                                        });
                                        xlsContent += '<tr> <td> ' + rowValues.join('</td><td>') + '</td> </tr> </br>';
                                    })
                                    xlsContent += '</table>';
                                    this.generatedCSVData = xlsContent;
                                }
                                this.generateCSVDocument();
                                resolve();
                            }
                        })
                        .catch(e => {
                            reject(e);
                            errorDebugger('generateDocumentV2', 'handleGenerateCSVData > fetchRecords  > xls', e, 'error');
                            });
                    }
                })
                .catch(e => {
                    reject(e);
                    errorDebugger('generateDocumentV2', 'getTemplateData', e, 'error');
                    this.showSpinner = false;
                });
            } catch (e) {
                reject(e);
                errorDebugger('generateDocumentV2', 'handleGenerateCSVData', e, 'error');
                this.showSpinner = false;
                this.handleGenerationResult();
            }
        })
    }
    getValueByKey(obj, key) {
        return key.split('.').reduce((o, i) => (o ? o[i] : undefined), obj);
    }

    fetchRecords(queryURL, accessToken, limitOfRecords) {
        try{
            const myHeaders = new Headers();
            let bearerString = "Bearer " + accessToken;
            myHeaders.append("Authorization", bearerString);
            //The batch size of the record fetching can go to max 2000, it will automatically set batch size optimally if not given
            // myHeaders.append("Sforce-Query-Options", "batchSize=2000");

            const requestOptions = {
                method: "GET",
                headers: myHeaders,
                redirect: "follow"
            };

            let domainURL;
            if (typeof window !== 'undefined') {
                domainURL = location.origin;
            }
            domainURL = domainURL.replace('lightning.force.com', 'my.salesforce.com');

            return fetch(encodeURI(domainURL + queryURL), requestOptions)
            .then(response => {
                return response.json();
            })
            .then(result => {
                if(result[0]?.errorCode){
                    let errorMessage = 'We couldn\'t fetch the records, please try again..';
                    let regex = /No such column '(\w+)' on entity '(\w+)'/;
                    let match = result[0].message.match(regex);
                    let fieldName = match ? match[1] : null;
                    let entityName = match ? match[2] : null;
                    if(match && fieldName && entityName){
                        errorMessage = 'Insufficient Access - You do not have access to field \''+ fieldName + '\' on object \'' + entityName + '\'.';
                    }
                    this.showWarningPopup('error', result[0].errorCode.replaceAll('_', ' '), errorMessage);
                    this.isClosableError = true;
                    return false;
                }
                
                let thisFetchedBatch = result.records;
                this.fetchedResults.push(...thisFetchedBatch);
                this.labelOfLoader = 'Fetching Records - ' + Math.min(Math.round(this.fetchedResults.length * 100 / limitOfRecords), 100) + '%';

                if (result.nextRecordsUrl && limitOfRecords > this.fetchedResults.length) {
                    return this.fetchRecords(result.nextRecordsUrl, accessToken, limitOfRecords);
                } else if (limitOfRecords < this.fetchedResults.length) {
                    this.fetchedResults = this.fetchedResults.slice(0, limitOfRecords);
                }
                return true;
            })
            .catch(e => {
                errorDebugger('generateDocumentV2', 'fetchRecords > fetch', e, 'error');
                this.showToast('error', 'Sorry, The records could not be fetched!', 'We couldn\'t fetch the records, please try again..', 5000);
                return false;
            });
        } catch(e){
            errorDebugger('generateDocumentV2', 'fetchRecords', e, 'error');
            this.showToast('error', 'Oops!, Something went wrong!', 'We couldn\'t fetch the records, please try again..');
            return false;
        }
    }

    generateCSVDocument(){
        try{
            this.resultPromises = [];
            this.showSpinner = true;
            let fileSizeInByte = (btoa(unescape(encodeURIComponent(this.generatedCSVData))).length / 4) * 3;

            if(!this.generatedCSVData){
                this.showToast('warning', ' No matching data.', 'Please try updating you filters...', 5000);
                return;
            }

            if(this.selectedChannels.includes("Download")){
                this.showSpinner = true;
                this.resultPromises.push(this.downloadCSV(this.generatedCSVData));
            }

            // Adding 5*1020*1020 for a little buffer in the data of 5 MB
            if(fileSizeInByte < 5*1020*1020 && this.selectedChannels.includes('Documents')){
                this.showSpinner = true;
                this.resultPromises.push(this.createDocument(btoa(unescape(encodeURIComponent(this.generatedCSVData)))));
            }else{
                this.failed['Documents'] = 'File Size Limit Exceeded';
            }

            if(fileSizeInByte < 25*1020*1020 && this.selectedChannels.includes('Notes & Attachments')){
                this.showSpinner = true;
                let contentType = this.selectedExtension === '.csv' ? "text/csv" : "application/vnd.ms-excel";
                this.resultPromises.push(this.createAttachments(btoa(unescape(encodeURIComponent(this.generatedCSVData))), contentType));
            }else{
                this.failed['Notes & Attachments'] = 'File Size Limit Exceeded';
            }

            if(fileSizeInByte < 37.5*1020*1020 && (this.selectedChannels.includes('Files') || this.selectedChannels.includes('Chatter') || this.selectedChannels.includes('Email') || this.selectedChannels.includes('Google Drive') || this.selectedChannels.includes('AWS') || this.selectedChannels.includes('One Drive') || this.selectedChannels.includes('Dropbox'))){
                this.showSpinner = true;
                this.labelOfLoader = 'Creating document to upload in Internal Storage...';
                this.createContentVersion(btoa(unescape(encodeURIComponent(this.generatedCSVData))))
                .then(cvId => {
                    this.labelOfLoader = 'Saving in Internal Storage...';
                    this.resultPromises.push(this.createFilesChatterEmail(cvId, this.recordId));
                    this.uploadToExternalStorage(cvId);
                    return Promise.all(this.resultPromises);
                })
                .then(() => {
                    this.handleGenerationResult();
                    this.fetchedResults = [];
                })
                .catch(e => {
                    this.showSpinner = false;
                    errorDebugger('generateDocumentV2', 'generateCSVDocument > generation', e, 'error');
                })
                .finally(() => {
                    this.labelOfLoader = 'Loading...';
                    this.showSpinner = false;
                });
        
            } else {
                ['Files', 'Chatter', 'Email', 'Google Drive', 'AWS', 'One Drive', 'Dropbox'].forEach(key => this.failed[key] = 'File Size Limit Exceeded');

                Promise.all(this.resultPromises)
                .then(() => {
                    this.handleGenerationResult();
                    this.fetchedResults = [];
                })
                .catch(e => {
                    this.showSpinner = false;
                    errorDebugger('generateDocumentV2', 'generateCSVDocument > this.resultPromises-Promises', e, 'error');
                })
                .finally(() => {
                    this.labelOfLoader = 'Loading...';
                    this.showSpinner = false;
                });
            }
        }catch(e){
            this.showSpinner =false;
            errorDebugger('generateDocumentV2', 'generateCSVDocument', e, 'error');
        }
    }
// -=-=- Used to download the Generated CSV in the local system -=-=-
    downloadCSV(csvContent) {
        this.labelOfLoader = 'Downloading...';
        this.showSpinner = true;
        try{
            this.fetchedResults = [];
            if(!this.fileName){
                let thisTemplate = this.allTemplates.find(opt => opt.Id === this.selectedTemplate);
                this.fileName = thisTemplate.Template_Name__c?.slice(0,240);
            }
            let element ;
            if(this.selectedExtension === '.csv'){
                element = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
            }else if(this.selectedExtension === '.xls'){
                element = 'data:application/vnd.ms-excel,' + encodeURIComponent(csvContent);
            }
            if (typeof window !== 'undefined') {
                let link = document.createElement('a');
                link.href = element;
                link.target = '_self';
                link.download = this.fileName+ this.selectedExtension;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                this.succeeded.push('Download');
            }
        }catch(e){
            this.failed['Download'] = e?.message;
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'downloadCSV', e, 'error');
        }finally{
            this.labelOfLoader = 'Loading...';
        }
    }

//------------------------------------------------------- Google DOC Generation Methods --------------------------------------------------------
   
    // generateGoogleDoc(){
    //     try{
    //         this.showSpinner = true;
    //         this.resultPromises = [];
    //         this.labelOfLoader = 'Generating document...';
    //         this.template.querySelector('c-generate-google-doc-file-v2')?.generateDocument(this.selectedTemplate, this.internalObjectApiName, this.recordId, this.selectedExtension);

    //     }catch(e){
    //         errorDebugger('generateDocumentV2', 'generateGoogleDoc', e, 'error');
    //     }
    // }

    generateGoogleDoc(){
        try{
            this.showSpinner = true;
            this.resultPromises = [];
            this.labelOfLoader = 'Generating document...';
            this.template.querySelector('c-generate-google-doc-file-v2')?.generateDocument(this.selectedTemplate, this.internalObjectApiName, this.recordId, this.selectedExtension);
        }catch(e){
            errorDebugger('generateDocumentV2', 'generateGoogleDoc', e, 'error');
        }
    }
    downloadGDocTemplate(){
        try{
            if (typeof window !== 'undefined') {
                this.showSpinner = true;
                this.labelOfLoader = 'Downloading...';
                const link = document.createElement('a');
                link.href = "data:application/pdf;base64,"+this.googleDocData;
                link.download = this.fileName+this.selectedExtension;
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                this.labelOfLoader = 'Loading ...';
                this.succeeded.push('Download');
            }
        }catch(e){
            this.failed['Download'] = e?.message;
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'downloadGDocTemplate', e, 'error');
        }
    }

    handleGoogleDocFile(event) {
        this.showSpinner = true;
        try {
            let data = event.detail.blob;
            this.labelOfLoader = 'Generating File...';
    
            if (data) {
                this.googleDocData = data;
                let fileSizeInByte = (decodeURIComponent(this.googleDocData).length / 4) * 3;
    
                if (this.selectedChannels.includes('Download')) {
                    this.resultPromises.push(this.downloadGDocTemplate());
                }
                if (fileSizeInByte < 5 * 1020 * 1020 && this.selectedChannels.includes('Documents')) {
                    this.resultPromises.push(this.createDocument(decodeURIComponent(this.googleDocData)));
                }else{
                    this.failed['Documents'] = 'File Size Limit Exceeded';
                }
                if (fileSizeInByte < 25 * 1020 * 1020 && this.selectedChannels.includes('Notes & Attachments')) {
                    let contentType = '';
                    if (this.selectedExtension === '.pdf') {
                        contentType = 'application/pdf';
                    } else if (this.selectedExtension === '.docx') {
                        contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
                    } else if (this.selectedExtension === '.ppt') {
                        contentType = 'application/vnd.ms-powerpoint';
                    }
                    this.resultPromises.push(this.createAttachments(decodeURIComponent(this.googleDocData), contentType));
                }else{
                    this.failed['Notes & Attachments'] = 'File Size Limit Exceeded';
                }
                if (fileSizeInByte < 37.5 * 1020 * 1020 && (this.selectedChannels.includes('Files') || this.selectedChannels.includes('Chatter') || this.selectedChannels.includes('Email') || this.selectedChannels.includes('Google Drive') || this.selectedChannels.includes('AWS') || this.selectedChannels.includes('One Drive') || this.selectedChannels.includes('Dropbox'))) {
                    this.showSpinner = true;
                    this.createContentVersion(decodeURIComponent(this.googleDocData))
                    .then(cvId => {
                        this.labelOfLoader = 'Saving in Internal Storage...';
                        this.resultPromises.push(this.createFilesChatterEmail(cvId, this.recordId));
                        this.uploadToExternalStorage(cvId);
                        return Promise.all(this.resultPromises);
                    })
                    .then(() => {
                        this.handleGenerationResult();
                        this.fetchedResults = [];
                    })
                    .catch(e => {
                        this.showSpinner = false;
                        errorDebugger('generateDocumentV2', 'handleGoogleDocFile > createContentVersion', e, 'error');
                    })
                    .finally(() => {
                        this.labelOfLoader = 'Loading...';
                        this.showSpinner = false;
                    });
                }else{
                    ['Files', 'Chatter', 'Email', 'Google Drive', 'AWS', 'One Drive', 'Dropbox'].forEach(key => this.failed[key] = 'File Size Limit Exceeded');

                    Promise.all(this.resultPromises)
                    .then(() => {
                        this.handleGenerationResult();
                        this.fetchedResults = [];
                    })
                    .catch(e => {
                        this.showSpinner = false;
                        errorDebugger('generateDocumentV2', 'handleGoogleDocFile > this.resultPromises - Promises', e, 'error');
                    })
                    .finally(() => {
                        this.labelOfLoader = 'Loading...';
                        this.showSpinner = false;
                    });
                }
            }else{
                ['Download', 'Notes & Attachments', 'Documents', 'Files', 'Chatter', 'Email', 'Google Drive', 'AWS', 'One Drive', 'Dropbox'].forEach(key => this.failed[key] = 'Error Generating File => '+event);
                this.showWarningPopup('error', 'Something went wrong!', 'The Document could not be generated, please try again...');
                this.isClosableError = true;
                this.showSpinner = false;
            }
        } catch (e) {
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'handleGoogleDocFile', e, 'error');
        }
    }
    

    changeLabelForGDoc(){
        this.showSpinner = true;
        this.labelOfLoader = 'Almost Done...'
    }

    handleGDocError(event){
        this.showSpinner = false;
        errorDebugger('generateDocumentV2', 'handleGDocError', event.detail, 'error');
        ['Download', 'Notes & Attachments', 'Documents', 'Files', 'Chatter', 'Email', 'Google Drive', 'AWS', 'One Drive', 'Dropbox'].forEach(key => this.failed[key] = 'Error Creating File => '+event?.detail?.message);
        this.showWarningPopup('error', 'Something went wrong!', event.detail.message ||'The Document could not be generated, please try again...' );
        this.isClosableError = true;
        this.showSpinner = false;
    }

//-------------------------------------------------------PDF / DOC Generation Methods --------------------------------------------------------

    
    @track vfInks = [];
    // Simple template docGenerate...
    generateSimpleTemplateFile(){
        try{
            if (this.isRelatedList) {                
                if (this.recordIds?.length > 0) {
                    getFileNames({ sObjectType: this.internalObjectApiName, recordIds: this.recordIds, fileName: this.fileName, parentsObject: this.parentObjName })
                    .then((result) => {
                        this.nameMap = result;
                        this.generateMultipleDocuments();
                    });
                }
                else{
                    fetchAllRecordIds({ objectname: this.parentObjName, RelatedRecordId: this.parentId,relationshipName: this.relationshipName, parentsObject: this.parentObjName})
                    .then((result) => {
                        this.recordIds = result;
                        getFileNames({ sObjectType: this.internalObjectApiName, recordIds: this.recordIds, fileName: this.fileName })
                        .then((result) => {
                            this.nameMap = result;
                            this.generateMultipleDocuments();
                        })
                    })
                }
                
            }
            else{
                this.simpleTemplate = false;
                this.labelOfLoader = "Generating document...";
                let previousSRC = this.vfGeneratePageSRC;
                let paraData2 = {
                    'templateId' : this.selectedTemplate,
                    'recordId' : this.recordId,
                    'selectedExtension' : this.selectedExtension,
                    'selectedChannels' : this.selectedChannels.join(','),
                    'fileName' : this.fileName,
                    'selectedFolder' : this.selectedFolder,
                }
                let paraDataStringify2 = JSON.stringify(paraData2);
                let newSRC = '/apex/MVDG__DocGeneratePage?paraData=' + encodeURIComponent(paraDataStringify2);

                if(newSRC !== previousSRC){
                    this.vfGeneratePageSRC = newSRC;
                    this.simpleTemplate = true;
                    this.vfInks.push(newSRC);
                }
                else{
                    this.vfGeneratePageSRC = '/apex/MVDG__DocGeneratePage';
                    this.customTimeout?.setCustomTimeoutMethod(() => {
                        this.vfGeneratePageSRC = newSRC;
                        this.vfInks.push(newSRC);
                        this.simpleTemplate = true;
                    }, 300);

                    // setTimeout(() => {
                    //     this.vfGeneratePageSRC = newSRC;
                    //     this.simpleTemplate = true;
                    // }, 300)
                }
            }
            
        }
        catch(e){
            this.labelOfLoader = 'loading...';
            errorDebugger('generateDocumentV2', 'generateSimpleTemplateFile', e, 'error');
        }
    }

    generateMultipleDocuments(){
        try {
                if(!this.recordIds || this.recordIds.length > 0){
                    this.totalNum = this.recordIds.length;
                }
                this.counter = 0;
                const validChannels = ['Download', 'Notes & Attachments', 'Documents', 'Files'];
                const multiplier = validChannels.filter(channel => this.selectedChannels.includes(channel)).length;
            
                // console.log('Selected channels --->', this.selectedChannels);
                // console.log(multiplier);
                
                this.totalNum *= multiplier;
                // console.log('totalNum --->'+ this.totalNum);
                    
                
                this.vfInks = [];
                let timeout = 500;
                this.showSpinner = true;
                this.labelOfLoader = 'Generating document...';
                for (let i = 0; i < this.recordIds.length; i++) {                                    
                    setTimeout(() => {
                        let bool = false;
                        bool = i === this.recordIds.length - 1 ? 'true' : 'false';
                        let recordId = this.recordIds[i];
                        this.simpleTemplate = true;
                        this.labelOfLoader = "Generating document...";
                        let name = this.nameMap[recordId];
                        let paraData2 = {
                            'templateId' : this.selectedTemplate,
                            'recordId' : recordId,
                            'selectedExtension' : this.selectedExtension,
                            'selectedChannels' : this.selectedChannels.join(','),
                            'fileName' : name,
                            'selectedFolder' : this.selectedFolder,
                            'isLast': bool,
                            'isBulk': 'true',
                            'isZip': JSON.stringify(this.isDownloadZip),
                            'parentId' : this.parentId,
                        }
                        let paraDataStringify2 = JSON.stringify(paraData2);
                        let newSRC = '/apex/MVDG__DocGeneratePage?paraData=' + encodeURIComponent(paraDataStringify2);
                        this.vfInks.push(newSRC);
        
                    }, timeout);
                    timeout += 200;
                }
        } catch (error) {            
            errorDebugger('generateDocumentV2', 'generateMultipleDocuments', error, 'error');
        }    
    }

    simpleTempFileGenResponse = (message) => {
        try{             
            // console.log(message);
            
            this.counter++;
            // console.log('COUNTER--->'+this.counter);
            
            
            if(message.data.messageFrom === 'docGenerate' && message.data.completedChannel === 'unknown'){
                this.completedSimTempPros = this.selectedChannels.length;
                ['Download', 'Notes & Attachments', 'Documents', 'Files', 'Chatter', 'Email', 'Google Drive', 'AWS', 'One Drive', 'Dropbox'].forEach(key => this.failed[key] = 'Error In File Generation => '+ message.data.error?.message);
                this.simpleTemplateFileDone();
                this.showWarningPopup('error', 'Something went wrong!', 'The Document could not be generated, please try again...');
                this.isClosableError = true;
                this.showSpinner = false;
            }
            else if(message.data.messageFrom === 'docGenerate' && message.data.completedChannel !== 'unknown'){
                
                if(message.data.completedChannel === 'Download' || message.data.completedChannel === 'Documents' || message.data.completedChannel === 'Notes & Attachments'){
                        if(message.data.status){
                            if((message.data.isBulk == 'true' && this.totalNum == this.counter) || (message.data.isBulk == 'false')){
                                this.succeeded.push(message.data.completedChannel);
                            }
                        }else{
                            this.failed[message.data.completedChannel] = message.data.error?.message;
                        }
                        if(this.isRelatedList){
                            this.bulkStatus.push(message.data.completedChannel);
                        }
                        else{
                            this.completedSimTempPros++;
                        }
                        this.simpleTemplateFileDone();
                }else if(message.data.completedChannel === 'External Storage'){
                    
                    let cvId = message.data.cvId;
                    // console.log('Got cvid in external storage response ---> '+ cvId);
                    
                    if(cvId){
                        if (message.data.isBulk == 'true') {
                            if(this.selectedChannels.includes('Download') && this.isDownloadZip){
                                this.bulkStatus.push('Download');
                            }
                            let recId = message.data.recordId;
                            this.contentVersionIds.push(cvId);
                            this.resultPromises.push(this.createFilesChatterEmail(cvId, recId));
                            if(!(this.selectedChannels.includes('Files') || this.selectedChannels.includes('Chatter') || this.selectedChannels.includes('Email')) && (this.selectedChannels.includes('Dropbox') || this.selectedChannels.includes('One Drive') || this.selectedChannels.includes('Google Drive') || this.selectedChannels.includes('AWS'))){
                                deleteContentVersion({cvId: cvId});
                            }
                            
                            if ((this.totalNum == this.counter || this.bulkStatus.filter(item => item === 'Download').length == this.recordIds.length) && !this.isDownloadZip ){
                                this.handleGenerationResult();
                            }
                            this.simpleTemplateFileDone();
                        }
                        if (message.data.isBulk != 'true'){
                            // console.log('record id in externalstorage'+this.recordId);
                            
                            this.resultPromises.push(this.createFilesChatterEmail(cvId, this.recordId));
                            this.uploadToExternalStorage(cvId);
                            this.handleGenerationResult();
                        }
                    }else{
                        ['Files', 'Chatter', 'Email', 'Google Drive', 'AWS', 'One Drive', 'Dropbox'].forEach(key => this.failed[key] = message.data.error?.message);
                        this.handleGenerationResult();
                        this.showSpinner = false;
                    }
                }
            }
        }catch(e){
            errorDebugger('generateDocumentV2', 'simpleTempFileGenResponse', e, 'error');
        }
    }

    simpleTemplateFileDone(){

        console.log('this is completedsimtemppro ---> '+this.completedSimTempPros);
        console.log('this is selected Channels -----> '+this.selectedChannels?.length);
        console.log('this is totalNum ---> '+this.totalNum);
        console.log('this is bulkStatus ---> '+this.bulkStatus?.length);

        
        
        if((this.totalNum == this.counter || this.bulkStatus.filter(item => item === 'Download')?.length == this.recordIds?.length) && this.isDownloadZip && this.isRelatedList){
            this.generateZipFile();
        }
        
        if(this.selectedChannels?.length === this.completedSimTempPros || this.bulkStatus?.length === this.totalNum){
            this.showSpinner = false;
            this.simpleTemplate = false;
            this.completedSimTempPros = 0;
            this.handleGenerationResult();
        }
    }
// ------------------------------------------------------- Generate Zip ---------------------------------------------------------------

    generateZipFile(){
        try {
            console.log('Inside generate zip file');
            
            const baseUrl = '/sfc/servlet.shepherd/version/download/';
            const fullUrl = baseUrl + this.contentVersionIds.join('/');
        
            const link = document.createElement('a');
            link.href = fullUrl;
            link.download = 'TEST.zip'; 
            link.target = '_blank'; // Open in new tab if needed
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            this.succeeded.push('Download');
            this.handleGenerationResult();

        } catch (error) {
            errorDebugger('generateDocumentV2', 'simpleTempFileGenResponse', error, 'error');
        }
    }


// ------------------------------------------------------- Folder Selection Methods ----------------------------------------------------

    handleFolderSelect(event){
        this.selectedFolder = event.detail[0];
    }

// --------------------------------------------------- Mutual Document Generation Methods ----------------------------------------------------

    createDocument(fileData) {
        try {
            this.showSpinner = true;
            this.labelOfLoader = 'Saving in Internal Storage...';

            if(!this.allFolders.find(item => item.value === this.selectedFolder)){
                this.failed['Documents'] ='The Selected folder (Id: ' + this.selectedFolder + ') to store documents does not exists.';
                return;
            }

            generateAccessToken()
                .then(accessToken => {
                    if (!accessToken) {
                        this.showToast('error', 'Something went wrong!', "Please verify connected app from user configuration.", 5000);
                        errorDebugger('generateDocumentV2', 'createDocument > generateAccessToken', 'Session ID not obtained', 'error');
                        this.showSpinner = false;
                        return;
                        // throw new Error('Session ID not obtained');
                    }

                    if (typeof window === 'undefined') {
                        return;
                    }
                    const domainURL = location.origin.replace('lightning.force.com', 'my.salesforce.com');
                    const myHeaders = new Headers();
                    myHeaders.append("Authorization", "Bearer " + accessToken);
                    myHeaders.append("Content-Type", "application/json");

                    const raw = JSON.stringify({
                        "Name": this.fileName,
                        "Type": this.selectedExtension.split(".")[1],
                        "FolderId": this.selectedFolder,
                        "Body": fileData
                    });

                    const requestOptions = {
                        method: 'POST',
                        headers: myHeaders,
                        body: raw,
                        redirect: 'follow'
                    };

                    const queryURL = "/services/data/v61.0/sobjects/Document";

                    return fetch(encodeURI(domainURL + queryURL), requestOptions);
                })
                .then(response => response.json())
                .then(result => {
                    
                    if (result.success) {
                        this.succeeded.push('Documents');
                    }else{
                        this.failed['Documents'] ='Error Code => '+  result[0]?.errorCode + '\n Error Message =>  ' + result[0]?.message + '\n Error Fields (if any) => ' + result[0]?.fields ;
                    }
                })
                .catch(e => {
                    this.showSpinner = false;
                    errorDebugger('generateDocumentV2', 'createDocument > fetch', e, 'error');
                })
                .finally(() => {
                    this.labelOfLoader = 'Loading...';
                });
        } catch (e) {
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'createDocument', e, 'error');
        }
    }

    createAttachments(fileData, contentType) {
        try {
            this.showSpinner = true;
            this.labelOfLoader = 'Saving in Internal Storage...';
    
            generateAccessToken()
                .then(accessToken => {
                    if (!accessToken) {
                        this.showToast('error', 'Something went wrong!', "Please verify connected app from user configuration.", 5000);
                        errorDebugger('generateDocumentV2', 'createAttachments > generateAccessToken', 'Session ID not obtained', 'error');
                        this.showSpinner = false;
                        return;
                        // throw new Error('Session ID not obtained'); 
                    }
    
                    if (typeof window === 'undefined') {
                        return;
                    }
                    const domainURL = location.origin.replace('lightning.force.com', 'my.salesforce.com');
                    const myHeaders = new Headers();
                    myHeaders.append("Authorization", "Bearer " + accessToken);
                    myHeaders.append("Content-Type", "application/json");
    
                    const raw = JSON.stringify({
                        "Name": this.fileName + this.selectedExtension,
                        "ParentId": this.recordId,
                        "contentType": contentType,
                        "Body": fileData
                    });
    
                    const requestOptions = {
                        method: 'POST',
                        headers: myHeaders,
                        body: raw,
                        redirect: 'follow'
                    };
    
                    const queryURL = "/services/data/v61.0/sobjects/Attachment";
    
                    return fetch(encodeURI(domainURL + queryURL), requestOptions);
                })
                .then(response => response.json())
                .then(result => {
                    if (result.success) {
                        this.succeeded.push('Notes & Attachments');
                    }else{
                        this.failed['Notes & Attachments'] ='Error Code => '+  result[0]?.errorCode + '\n Error Message =>  ' + result[0]?.message + '\n Error Fields (if any) => ' + result[0]?.fields ;
                    }
                })
                .catch(e => {
                    this.showSpinner = false;
                    errorDebugger('generateDocumentV2', 'createAttachments > fetch', e, 'error');
                })
                .finally(() => {
                    this.labelOfLoader = 'Loading...';
                });
        } catch (e) {
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'createAttachments', e, 'error');
        }
    }

    addToFiles(cvId, recId) {
        if(this.isOnParent){
            recId = this.parentId;
        }
        
        return new Promise((resolve) => {
            try {
                this.showSpinner = true;
                this.labelOfLoader = 'Saving in Internal Storage...';
        
                if (!this.isCSVTemplate) {
                    storeInFiles({ combinedData: {contentVersionId: cvId, recordId: recId ? recId : this.selectedTemplate, activityId : this.activity.Id} })
                    .then((result) => {
                        if(result === 'success'){
                            this.succeeded.push('Files');
                            resolve();
                        }else{
                            this.failed['Files'] = result;
                            errorDebugger('generateDocumentV2', 'addToFiles > storeInFiles > failure', result, 'error');
                            this.showSpinner = false;
                            resolve();
                        }
                    })
                    .catch(e => {
                        errorDebugger('generateDocumentV2', 'addToFiles > storeInFiles > failure', e, 'error');
                    });
                }else{
                    this.succeeded.push('Files');
                    resolve();
                }
            } catch (e) {
                errorDebugger('generateDocumentV2', 'addToFiles', e, 'error');
                this.showSpinner = false;
                resolve();
            }
        })
    }

    addToChatter(cvId) {
        return new Promise((resolve) => {
            try {
                this.showSpinner = true;
                this.labelOfLoader = 'Saving in Internal Storage...';
                let bodyString = 'Generated "' + this.fileName + this.selectedExtension + '".';
                postToChatter({ combinedData: { contentVersionId: cvId, recordId: this.recordId, body: bodyString, activityId : this.activity.Id }})
                .then((result) => {
                    if(result === 'success'){
                        this.succeeded.push('Chatter');
                        if (this.selectedChannels.includes('Files')) {
                            this.succeeded.push('Files');
                        }
                        resolve();
                    }else{
                        this.failed['Chatter'] = result;
                        errorDebugger('generateDocumentV2', 'addToChatter > postToChatter > failure', result, 'error');
                        if (this.selectedChannels.includes('Files')) {
                            this.resultPromises.push(
                                this.addToFiles(cvId)
                                .then(() => {
                                    resolve();
                                })
                                .catch(() => {
                                    resolve();
                                })
                            );
                        }else{
                            resolve();
                        }
                    }
                })
                .catch((e)=>{
                    this.failed['Chatter'] = e;
                    this.failed['Files'] = e;
                    errorDebugger('generateDocumentV2', 'addToChatter > postToChatter', e, 'error');
                })
            } catch (e) {
                errorDebugger('generateDocumentV2', 'addToChatter', e, 'error');
                this.showSpinner = false;
                resolve();
            }
        })
    }

    sendWithEmail(cvId) {
        return new Promise((resolve) => {
            try {
                this.showSpinner = true;
                this.labelOfLoader = 'Sending email...';
        
                let allEmails = {
                    toEmails: this.toEmails,
                    ccEmails: this.ccEmails,
                    bccEmails: this.bccEmails
                }
                
                allEmails.toEmails=allEmails.toEmails.concat(this.toverified);
                allEmails.ccEmails=allEmails.ccEmails.concat(this.ccverified);
                allEmails.bccEmails=allEmails.bccEmails.concat(this.bccverified);
                

                 
                let emailData = {
                    contentVersionId: cvId,
                    emailSubject: this.emailSubject,
                    emailBody: this.selectedEmailTemplate ? this.allEmailTemplates.find(item => item.Id === this.selectedEmailTemplate).HtmlValue || this.allEmailTemplates.find(item => item.Id === this.selectedEmailTemplate).Body || '' : this.emailBody
                };
                // console.log('selecrtred fields in auto generation',JSON.stringify(this.selectedFieldLabels));
                // console.log('all emails',JSON.stringify(allEmails));
                sendEmail({ allEmails:allEmails, emailData:emailData, activityId : this.activity.Id })
                .then((result) => {
                    if(result === 'success'){
                        this.succeeded.push('Email');
                        resolve();
                    }else{
                        this.failed['Email'] = result;
                        errorDebugger('generateDocumentV2', 'sendWithEmail > sendEmail > failure', result, 'error');
                        this.showSpinner = false;
                        resolve();
                    }
                })
                .catch(e => {
                    this.failed['Email'] = e?.body?.message;
                    errorDebugger('generateDocumentV2', 'sendWithEmail > sendEmail', e, 'error');
                    this.showSpinner = false;
                    resolve();
                });
            } catch (e) {
                errorDebugger('generateDocumentV2', 'sendWithEmail', e, 'error');
                this.showSpinner = false;
                resolve();
            }
        })
    }

    createContentVersion(fileData) {
        this.showSpinner = true;
        this.labelOfLoader = 'Generating File...';
    
        return generateAccessToken()
            .then(accessToken => {
                if (!accessToken) {
                    this.showToast('error', 'Something went wrong!', "Please verify connected app from user configuration.", 5000);
                    errorDebugger('generateDocumentV2', 'createContentVersion > generateAccessToken', 'Session ID not obtained', 'error');
                    this.showSpinner = false;
                    return;
                    // throw new Error('Session ID not obtained');
                }
    
                if (typeof window === 'undefined') {
                    return;
                }
                const domainURL = location.origin.replace('lightning.force.com', 'my.salesforce.com');
                const myHeaders = new Headers();
                myHeaders.append("Authorization", "Bearer " + accessToken);
                myHeaders.append("Content-Type", "application/json");
    
                const raw = JSON.stringify({
                    "title": this.fileName,
                    "PathOnClient": this.fileName + this.selectedExtension,
                    "versionData": fileData
                });
    
                const requestOptions = {
                    method: "POST",
                    headers: myHeaders,
                    body: raw,
                    redirect: "follow"
                };
    
                const queryURL = "/services/data/v61.0/sobjects/ContentVersion";
                return fetch(encodeURI(domainURL + queryURL), requestOptions);
            })
            .then(response => response.json())
            .then(result => {
                if (!result.success || !result.id) {
                    this.showToast('error', 'Something went wrong!', 'Couldn\'t create the document, please try again.', 5000);
                    throw new Error('Failed to create content version');
                }
                return result.id;
            })
            .catch(e => {
                errorDebugger('generateDocumentV2', 'createContentVersion > fetch', e, 'error');
                this.showSpinner = false;
            })
            .finally(() => {
                this.labelOfLoader = 'Loading...';
            });
    }

    createFilesChatterEmail(contentVersionId, recId) {
        try {
            this.showSpinner = true;
    
            if (this.selectedChannels.includes('Chatter')) {
                this.resultPromises.push(this.addToChatter(contentVersionId));
            } else if (this.selectedChannels.includes('Files')) {
                // console.log('recId in 1'+recId);
                if(this.isRelatedList){
                    this.bulkStatus.push('Files');
                }
                if(!recId){
                    recId = this.recordId;
                }                
                this.resultPromises.push(this.addToFiles(contentVersionId, recId));
            }
    
            if (this.selectedChannels.includes('Email')) {
                this.resultPromises.push(this.sendWithEmail(contentVersionId));
            }
        } catch (e) {
            errorDebugger('generateDocumentV2', 'createFilesChatterEmail', e, 'error');
            this.showSpinner = false;
        }
    }

    uploadToExternalStorage(contentVersionId){
        try {
            if(this.selectedChannels.includes('Google Drive')){
                this.succeeded.push('Google Drive');
                uploadToGoogleDrive({cvid : contentVersionId, activityId : this.activity.Id});
            }
            if(this.selectedChannels.includes('AWS')){
                this.succeeded.push('AWS');
                uploadToAWS({cvid : contentVersionId, activityId : this.activity.Id});
            }
            if(this.selectedChannels.includes('One Drive')){
                this.succeeded.push('One Drive');
                uploadToOneDrive({cvid : contentVersionId, activityId : this.activity.Id});
            }
            if(this.selectedChannels.includes('Dropbox')){
                this.succeeded.push('Dropbox');
                uploadToDropBox({ cvid : contentVersionId, activityId : this.activity.Id});      
            }
            if(!(this.selectedChannels.includes('Files') || this.selectedChannels.includes('Chatter') || this.selectedChannels.includes('Email')) && (this.selectedChannels.includes('Dropbox') || this.selectedChannels.includes('One Drive') || this.selectedChannels.includes('Google Drive') || this.selectedChannels.includes('AWS'))){
                deleteContentVersion({cvId: contentVersionId});
            }
        } catch (e) {
            errorDebugger('generateDocumentV2', 'uploadToExternalStorage', e, 'error');
            this.showSpinner = false;
        }
    }

    handleGenerationResult() {
        try {            
            Promise.all(this.resultPromises)
                .then(() => {
                    let combinedLists = {
                        succeeded : [],
                        inProgress : []
                    }
                    let combinedMaps = {
                        failed : {},
                        templateData : {
                            'name' : this.templateName,
                            'type' : this.templateType,
                            'object' : this.internalObjectApiName,
                            'fileName' : this.fileName + this.selectedExtension
                        }
                    }
                    this.selectedChannels.forEach(channel => {
                        if (this.failed[channel]){
                           combinedMaps.failed[channel] = this.failed[channel];
                        } else if(['Google Drive', 'AWS', 'One Drive', 'Dropbox'].includes(channel)){
                            combinedLists.inProgress.push(channel);
                            this.succeeded = this.succeeded.filter(item => !item.includes(channel));
                        } else if(!this.succeeded.includes(channel) && this.isRelatedList){
                            combinedLists.succeeded.push(channel);
                            this.succeeded.push(channel);
                        } else if (!this.succeeded.includes(channel)) {
                            combinedMaps.failed[channel] = 'Internal Error';
                        }
                    });

                    this.failed = {...combinedMaps.failed};
                    combinedLists.succeeded = this.succeeded;
                    
                    Object.keys(this.failed).forEach(key => {
                        this.activity['MVDG__' + key.replaceAll(' & ', '_').replaceAll(' ', '_') + '__c'] = this.failed[key] || 'No Error Returned!!';
                    });
                    this.succeeded.forEach(item => {
                        this.activity['MVDG__' + item.replaceAll(' & ', '_').replaceAll(' ', '_') + '__c'] = 'Success';
                    });
                    this.generateActivity();
                    
                    this.handleClose();
                    this.showSpinner = false;
                })
                .catch(e => {
                    this.showSpinner = false;
                    errorDebugger('generateDocumentV2', 'handleGenerationResult > this.resultPromises - Promises', e, 'error');
                });
        } catch (e) {
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'handleGenerationResult', e, 'error');
        }
    }
    

// -------------------------------------------------------- Default Set Methods -------------------------------------------------------- 

    handleSetDefaults(){
        try{
            this.showSpinner = true;
            if(!this.buttonLabel){
                this.showToast('error', 'Something Went Wrong!', 'Please enter the name for the button.', 5000);
                return;
            }
            if(!this.buttonLabel.trim()[0].match(/[a-zA-Z]/i)){
                this.showToast('error', 'Something went wrong!','This first letter of name, should be an alphabet.!', 5000)
                return;
            }

            if(!this.isOldButton && this.allButtons.includes(this.buttonLabel.trim().replace(/[^a-zA-Z0-9_]+/g, '_'))){
                this.showToast('error', 'Something went wrong!','This button name is used, try changing name!', 5000)
                return;
            }
            if(this.selectedChannels.length < 1){
                this.showToast('error', 'Something Went Wrong!', 'Please select at least 1 storage or output channel.', 5000);
                return;
            }
            
            if(this.showEmailSection && this.toEmails.length < 1 && this.toFields.length < 1){
                this.validateToEmails();
                this.showToast('error', 'Something Went Wrong!', 'Please select at least one recipient to send email.', 5000);
                return;
            }
            if(this.selectedChannels.includes('Documents') && !this.selectedFolder){
                this.showSpinner = false;
                this.showToast('error', 'Something Went Wrong!', 'Please select folder to save document.', 5000);
                return;
            }
            if(this.allTemplates?.find(temp => temp.Id === this.templateIdFromParent)?.MVDG__Template_Status__c){
                this.handleCreateButton(false);
            }else{
                this.showWarningPopup('warning', 'Activate Template', 'This template is inactive. Creating or updating custom button will also activate this template.');
                this.isButtonGeneration = true;
            }
        }catch(e){
            this.showSpinner = false;
            errorDebugger('generateDocumentV2', 'handleSetDefaults', e, 'error');
        }
    }

    handleCreateButton(changeStatus){
        this.showSpinner = true;
        try {
            let allEmailsString = '';
            allEmailsString += (this.toEmails.length>0 ? this.toEmails.join(', ') : '') + '<|DGE|>' + (this.ccEmails.length>0 ? this.ccEmails.join(', ') : '') + '<|DGE|>' + (this.bccEmails.length>0 ? this.bccEmails.join(', '): '') + '<|DGE|>' + this.toFields + '<|DGE|>' + this.ccFields + '<|DGE|>' + this.bccFields;
            // console.log('allEmailString',allEmailsString);


            let iStorages = this.internalStorageOptions.filter(item => item.isSelected === true).map(item => {return item.name}).join(', ');
            let eStorages = this.externalStorageOptions.filter(item => item.isSelected === true).map(item => {return item.name}).join(', ');
            let oChannels = this.outputChannels.filter(item => item.isSelected === true).map(item => {return item.name}).join(', ');
            let defaults = {
                templateId : this.templateIdFromParent,
                buttonLabel : this.buttonLabel,
                buttonName: this.buttonName ? this.buttonName : this.buttonLabel.trim().replace(/[^a-zA-Z0-9_]+/g, '_'),
                docType : this.selectedExtension?.slice(1,).toUpperCase(),
                iStorage : iStorages,
                folderId: this.selectedFolder,
                eStorage : eStorages,
                oChannel : oChannels,
                emailAddresses : allEmailsString,
                emailBody : this.emailBody,
                emailSubject : this.emailSubject,
                templateType : this.templateTypeFromParent,
                emailTemplate : this.selectedEmailTemplate
            }
            setDefaultOptions({ defaultData: defaults })
            .then(()=>{
                if(!this.isOldButton){
                    if(this.isCSVTemplate){
                        let objList = [];
                        objList.push(this.internalObjectApiName);
                        let buttonData = {
                            buttonLabel: this.buttonLabel,
                            buttonName: this.buttonName ? this.buttonName : this.buttonLabel.replace(/[^a-zA-Z0-9_]+/g, '_'),
                            buttonEndURL: '&c__isDefaultGenerate=true&c__templateIdToGenerate='+this.templateIdFromParent
                        }
                        createListViewButtons({objects: objList, buttonData : buttonData})
                        .then((isSuccess) => {
                            if(isSuccess == false){
                                this.showToast('error', 'Something went wrong!','The button couldn\'t be created with defaults!', 5000);
                            }else{
                                this.isOldButton = true;
                                this.bottomBtnLabel = 'Update Defaults';
                                this.showToast('success', 'Action Performed!','The button is created with defaults!', 5000);
                            }
                        })
                        .catch((e) => {
                            this.showToast('error', 'Something went wrong!','The button couldn\'t be created with defaults!', 5000);
                            errorDebugger('generateDocumentV2', 'handleCreateButton > createListViewButtons', e, 'error');
                        })
                    }else{
                        generateAccessToken()
                        .then((data) => {
                            if (!data) {
                                this.showToast('error', 'Something went wrong!','Please verify connected app from user configuration.', 5000);
                                return;
                            }
                            if (typeof window === 'undefined') {
                                return;
                            }
                            let domainURL = location.origin.replace('lightning.force.com', 'my.salesforce.com');
                            let endpoint = domainURL + '/services/data/v61.0/tooling/sobjects/QuickActionDefinition';
    
                            let accessToken = data;
                            let myHeaders = new Headers();
                            myHeaders.append("Content-Type", "application/json");
                            myHeaders.append("Authorization", "Bearer "+accessToken);
    
                            let requestBody = {
                                Metadata: {
                                    label: this.buttonLabel,
                                    optionsCreateFeedItem: false,
                                    type: "LightningWebComponent",
                                    lightningWebComponent: "MVDG__generateDocumentV2"
                                },
                                FullName: this.internalObjectApiName+'.'+defaults.buttonName
                            };
                            let requestOptions = {
                                method: 'POST',
                                headers: myHeaders,
                                body: JSON.stringify(requestBody),
                                redirect: 'follow'
                                };
                                fetch(encodeURI(endpoint), requestOptions)
                                .then(response => response.json())
                                .then(result => {
                                    if(result.success){
                                        this.isOldButton = true;
                                        this.bottomBtnLabel = 'Update Defaults'
                                        this.showToast('success', 'Action Performed!','The button is created with defaults!', 5000);
                                    }else{
                                        errorDebugger('generateDocumentV2', 'handleCreateButton > fetch (create quick action button) > failure', result, 'error');
                                        this.showToast('error', 'Something went wrong!','The button couldn\'t be created with defaults!', 5000); 
                                    }
                                })
                                .catch(e => {
                                    this.showToast('error', 'Something went wrong!','The button couldn\'t be created with defaults!', 5000);
                                    errorDebugger('generateDocumentV2', 'handleCreateButton > fetch (create quick action button)', e, 'error');
                                });
                            })
                        .catch((e)=>{
                            this.showSpinner = false;
                            this.showToast('error', 'Something went wrong!','Some technical issue occurred, please try again!', 5000);
                            errorDebugger('generateDocumentV2', 'handleCreateButton > generateAccessToken', e, 'error');
                        })
                    }
                }else{
                    this.isOldButton = true;
                    this.bottomBtnLabel = 'Update Defaults'
                    this.showToast('success', 'Action Performed!', 'The defaults for ' + this.buttonLabel + ' button is updated!', 5000);
                }
                if(changeStatus){
                    this.allTemplates.find(temp => temp.Id === this.templateIdFromParent).MVDG__Template_Status__c = true;
                    if (typeof window !== 'undefined') {
                        this.dispatchEvent(new CustomEvent('activate'));
                    }
                }
            })
            .catch(e => {
                this.showSpinner = false;
                errorDebugger('generateDocumentV2', 'handleCreateButton > setDefaultOptions', e, 'error');
            })
        } catch (e) {
            errorDebugger('generateDocumentV2', 'handleCreateButton', e, 'error');
        }
    }

    handleButtonLabelChange(event){
        this.buttonLabel = event.target.value;
        if(this.buttonLabel){
            this.template.querySelector('.button-label-input').classList.remove('error-input');
            this.template.querySelector('.button-label').classList.remove('error-label');
        }else{
            this.template.querySelector('.button-label-input').classList.add('error-input');
            this.template.querySelector('.button-label').classList.add('error-label');
        }
    }


// --------------------------------------------------------General Use Methods ---------------------------------------------------------
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

    showWarningPopup(status, title, message){
        this.showSpinner = false;
        const messageContainer = this.template.querySelector('c-message-popup-v2')
        messageContainer.showMessagePopup({
            status: status,
            title: title,
            message : message,
        });
    }

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
            errorDebugger('generateDocumentV2', 'navigateToComp', e, 'error');
        }
    }
}