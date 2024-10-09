import { LightningElement, api, track } from "lwc";
// import basePath from '@salesforce/community/basePath';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle, loadScript } from "lightning/platformResourceLoader";
import summerNote_Editor from "@salesforce/resourceUrl/summerNote_Editor";
import docGeniusLogoSvg from "@salesforce/resourceUrl/docGeniusLogoSvg";
import getTemplateData from '@salesforce/apex/TemplateBuilder_Controller.getTemplateData';
import saveTemplateApex from '@salesforce/apex/TemplateBuilder_Controller.saveTemplateApex';
import saveTempDataRecordsInBatch from '@salesforce/apex/TemplateBuilder_Controller.saveTempDataRecordsInBatch';
import updateTemplate from '@salesforce/apex/HomePageController.updateTemplate';
import { initializeSummerNote } from './editorConf.js';
import {navigationComps, nameSpace, pageFormats, unitMultiplier, unitConverter, errorDebugger} from 'c/globalProperties';

export default class TemplateBuilder extends NavigationMixin(LightningElement) {

    @api templateId;                                // Template Id 
    @api objectName;                                // Source Object API name
    @api activeTabName;                             // To define active tab

    @track defaultTab = 'contentTab';               // To open default on component load
    @track startchat = true;                        // To used in chatbot
    @track isSpinner = false;                       // To show hide spinner
    @track isPreview = false;                       // To Show hide preview modal
    isInitialRender = true;                         // To check dom and editor rended or not

    @track bodyData = '';                           // To store template main content data.
    @track headerData = '';                         // To store template header data.

    @track templateRecord = {}                      // Store template record field data,
    @track tempRecordSaved = {}                    // for backup to revert template data on cancel click,

    @track vfPageSRC = ''                           // DocGenerate VF page src to generate preview or file,

    @track isMappingContainerExpanded = false;      // #fieldMapping...

    contentEditor;                                  // store initialize main content editor for further process
    headerEditor;                                   // store initialize header editor for further process
    footerEditor;                                   // store initialize footer editor for further process

    valueInserted = false;                          // To check template content data insert or not in editor to stop spinner,
    dataLoaded = false;                             // To check data fetch or not from backed to stop spinner,
    searchFieldValue = '';                          
    @track loaderLabel = null;                      // To set label of loaded based on on-going process

    isCloseConfirmation = false                     // To define user click on close button and confirmation popup open
    noTemplateFound = false;                        // To check weather template available for not

    editorDataChanges = false;                      // To identify any editor data change or not

    @track doneButtonLabel = 'Okay';
    @track spinnerFor = null                        // To define spinner is running for which action

    @track currentTab = '';

    /**
     * variable to store page configuration to display on UI, used in HTML
     * value into this variable assigned from MVDG__Template_Page__c record fetched from backed..
     */
    @track pageConfigs = {
        pageMargins : [
            {name : 'top', value : 1},
            {name : 'bottom', value : 1},
            {name : 'left', value : 1},
            {name : 'right', value : 1},
        ],
        pageSize : [
            {name : 'A4', value : 'a4', size : '8.27" x 11.69"', selected : true},
            {name : 'A5', value : 'a5', size : '5.83" x 8.27"', selected : false},
            {name : 'Letter', value : 'letter', size : '8.5" x 11"', selected : false},
            {name : 'Legal', value : 'legal', size : '8.5" x 14"', selected : false},
            {name : 'Executive', value : 'executive', size : '7.25" x 10.5"', selected : false},
            {name : 'Statement', value : 'statement', size : '5.5" x 8.25"', selected : false},
        ],
        pageOrientation : [
            {name : 'Portrait', value : 'portrait', selected : true},
            {name : 'Landscape', value : 'landscape',  selected : false},
        ],
        unitOptions : [
            {name : 'inch', value : 'in', selected: true},
            {name : 'cm', value : 'cm' , selected: false},
            {name : 'px', value : 'px' , selected: false},
        ],
        unit : 'in',
        header : {
            show: true,
            marginTop : 10,
        },
        footer : {
            show: true,
            marginBottom : 10,
        },
        watermark : {
            show : true,
        }

    }

    /**
     * Used to store value fetched from MVDG__Template_Page__c record.
     */
    @track pageConfigRecord = {};
    @track popConfigDiscard = {};       // Used when user discard page configuration from page config popup
    @track pageConfigSaved = {};     // Used to restore last saved page configs
    currentPageWidth = 792;             // in PX...
    currentPageHeight = 1120;           // in PX...

    lastRelatedListTableCount = 0;      // Count of inserted relate list (child object) table
    maxRelatedLIstTableLimit = 10;      // Maximum limit of relate list (child object) table

    maxImageSize = 3*1024*1024;         // Max image size to upload using editor
    allowFileExtensions = ".png,.jpg,.jpeg,.avif,.webp,.heic,.ico,.jfif,.jps,.jpe";       // Allow file extension using editor  

    /**
     * Option for watermark [Currently it is not available]
     */
    @track watermarkOptsTabs = {
        watermarkImage : true,
        watermarkText : false
    }
    @track watermark = {
        text : {
            text : '',
            bold : false,
            italic : false,
            underline : false,
            strikethrough : false,
            size : 16,
            fontFamily : '',
            color : 'black',
            top : 50,
            left : 50,
            rotate : 0,
            opacity : 100,
        },
        image : {
            size : 50,
            top : 50,
            left : 50,
            rotate : 0,
            opacity : 100,
            src : '',
        },
    }

    isPageSetup = false;                    // To defined page setup is open or not
    @track activePageConfigs = [];          // To set by default open page config accordions

   get setdocGeniusLogoSvg(){
    return docGeniusLogoSvg;
   }
   
   get showTempDetail(){
        return Object.keys(this.templateRecord).length ? true : false;
   }

   get inputStep(){
        switch (this.pageConfigs.unit){
            case "px":
                return 1;

            case "in":
                return 0.1;

            case "cm" : 
                return 0.5;
        }
        return 0
   }

    _resolvedPromise = 0;
    get resolvedPromise(){ return this._resolvedPromise };
    set resolvedPromise(value){
        if(value == 2){
            this.isSpinner = false;
        }
        this._resolvedPromise = value;
    }

    get tabs(){
        return {
            contentTab : this.currentTab === 'contentTab',
            headerTab : this.currentTab === 'headerTab',
            footerTab : this.currentTab === 'footerTab',
            waterMarkTab : this.currentTab === 'waterMarkTab',
            basicTab : this.currentTab === 'basicTab',
            templateDefault : this.currentTab === 'templateDefault',
        }
    }

    get hideToolbar(){
        return !(this.currentTab === 'contentTab' || this.currentTab === 'headerTab' || this.currentTab === 'footerTab');
    }

    get showKeyMapping(){
        return (this.currentTab === 'contentTab' || this.currentTab === 'headerTab' || this.currentTab === 'footerTab');
    }

    connectedCallback(){
        try {
            // If Active Tab is Not set by default... 
            this.currentTab =  this.activeTabName ? this.activeTabName : this.defaultTab;
                if(this.templateId){
                    this.isSpinner = true;
                    this.getTemplateValues();
                }
                else{
                    this.noTemplateFound = true;
                }
                if (typeof window !== 'undefined') {   
                    window?.addEventListener('resize', this.resizeFunction);
                }

        } catch (error) {
            errorDebugger('TemplateBuilder', 'connectedCallback', error, 'warn');
        }
    }

    renderedCallback(){
        try {
            if(this.isInitialRender){
                // this.isSpinner = true;
                // ------------------------------------- Editor  -------------------------------------------
                Promise.all([
                    loadScript(this, summerNote_Editor + '/jquery-3.7.1.min.js'),
                ])
                .then(() => { 
                    Promise.all([
                        loadStyle(this, summerNote_Editor + '/summernote-lite.css'),
                        loadScript(this, summerNote_Editor + '/summernote-lite.js'),

                        // loadStyle(this, summerNote_Editor + '/codeMirror/codemirror.css'),
                        // loadStyle(this, summerNote_Editor + '/codeMirror/blackboard.min.css'),
                        // loadStyle(this, summerNote_Editor + '/codeMirror/monokai.css'),
                        // loadScript(this, summerNote_Editor + '/codeMirror/codemirror.js'),
                        // loadScript(this, summerNote_Editor + '/codeMirror/formatting.js'),
                        // loadScript(this, summerNote_Editor + '/codeMirror/xml.js'),
                    ])
                    .then(() => {
                        this.isInitialRender = false;
                        console.log('library loaded SuccessFully');
                        this.initialize_Content_Editor();
                        this.initialize_Header_Editor();
                        this.initialize_Footer_Editor();

                        var self = this;
                        if (typeof window !== 'undefined') {   
                            $(document).on("keydown", function(event){
                                // if user press clt + s on keyboard
                                if ((event.key == 's' || event.key == 'S') && (event.ctrlKey || event.metaKey)){
                                    if(!self.isPreview && self.currentTab !== 'templateDefault'){
                                        self.saveTemplateData();
                                    }
                                }
                            });
                        }
                    })
                    .catch(err => {
                        errorDebugger('TemplateBuilder', 'renderedCallback', err, 'warn', 'Error To Load summerNote_Editor');
                    })
                })
                .catch(error => { 
                    errorDebugger('TemplateBuilder', 'renderedCallback', error, 'warn', 'Error To Load Jquery');
                })

                this.setActiveTab();

                this.template.querySelector(`[data-name="custom_timeout"]`)?.addEventListener('animationend', this.customTimeoutMethod)
            }

            if(this.noTemplateFound){
                this.showMessagePopup('Error', 'Error While Fetching Template', 'Template Not Found');
            }
        }
        catch(error){
            errorDebugger('TemplateBuilder', 'renderedCallback', error, 'warn');
        }
    }

    initialize_Content_Editor(){
        try {
            this.contentEditor = this.template.querySelector(`[data-name="templateContent"]`);
            this.isLoadedSuccessfully = initializeSummerNote(this ,docGeniusLogoSvg, 'templateContent');

            if(this.isLoadedSuccessfully == true){
                this.resizeFunction();
                this.setDataInMainEditor();
                this.resolvedPromise++
            }
            else{
                this.showMessagePopup('Error','Error' ,'There is Some issue to Load Editor Properly, Please reload current page or try after some time.', 'Reload Page')
                this.resolvedPromise++
            }
        } catch (error) {
            errorDebugger('TemplateBuilder', 'initialize_Content_Editor', error, 'warn');
        }
    }

    initialize_Header_Editor(){
        try {
            this.headerEditor = this.template.querySelector(`[data-name="headerEditor"]`);
            let isLoadedSuccessfully = initializeSummerNote(this, docGeniusLogoSvg, 'headerEditor');

            if(!isLoadedSuccessfully){
                this.showMessagePopup('Error','Error' ,'There is Some issue to Load Editor Properly, Please reload current page or try after some time.', 'Reload Page')
            }           
        } catch (error) {
            errorDebugger('TemplateBuilder', 'initialize_Header_Editor', error, 'warn');
        }
    }

    initialize_Footer_Editor(){
        try {
            this.footerEditor = this.template.querySelector(`[data-name="footerEditor"]`);
            let isLoadedSuccessfully = initializeSummerNote(this, docGeniusLogoSvg, 'footerEditor');

            if(!isLoadedSuccessfully){
                this.showMessagePopup('Error','Error' ,'There is Some issue to Load Editor Properly, Please reload current page or try after some time.', 'Reload Page')
            }
        } catch (error) {
            errorDebugger('TemplateBuilder', 'initialize_Footer_Editor', error, 'warn');
        }
    }

    // Use Arrow Function...
    resizeFunction = () => {
        this.setEditorArea();
    };

    getTemplateValues(){
        try {
            getTemplateData({templateId : this.templateId})
            .then(result => {
                if(result.isSuccess){
                    // console.log(' get result size : ' , new Blob([JSON.stringify(result)]).size / 1000000, ' mb');
                    this.templateRecord = result.template;
                    this.templateRecord.createDateOnly = this.templateRecord.CreatedDate.split("T")[0];
                    this.tempRecordSaved = JSON.parse(JSON.stringify(this.templateRecord));
                    this.bodyData = '';
                    this.headerData = '';
                    this.footerData = '';
                    let watermarkData = ''
                    this.pageConfigRecord = result.pageConfigs;
                    this.pageConfigSaved = JSON.parse(JSON.stringify(this.pageConfigRecord));

                    // Collect Value in Single variable...
                    result.template.MVDG__Template_Data__r?.forEach(ele => {
                        if(ele.MVDG__Value_Type__c == 'Body Value'){
                            this.bodyData += ele.MVDG__Template_Value_Simple__c ? ele.MVDG__Template_Value_Simple__c : '';
                        }
                        else if(ele.MVDG__Value_Type__c == 'Header Value'){
                            this.headerData = ele.MVDG__Template_Value_Simple__c ? ele.MVDG__Template_Value_Simple__c : '';
                        }
                        else if(ele.MVDG__Value_Type__c == 'Footer Value'){
                            this.footerData = ele.MVDG__Template_Value_Simple__c ? ele.MVDG__Template_Value_Simple__c : '';
                        }
                        else if(ele.MVDG__Value_Type__c == 'Watermark Value'){
                            watermarkData += ele.MVDG__Template_Value_Simple__c ? ele.MVDG__Template_Value_Simple__c : '';
                        }
                    });
                    
                    this.dataLoaded = true;
                    this.setPageConfigVariable();
                    this.setDataInMainEditor();
                    this.setDataInHeader();
                    this.setDataInFooter();
                    watermarkData && watermarkData != '' && (this.watermark = JSON.parse(watermarkData));
                    this.setWatermarkPreview();

                    delete this.templateRecord['MVDG__Template_Data__r'];

                    this.resolvedPromise++
                }
                else{
                    this.resolvedPromise++
                    this.noTemplateFound = true;
                    this.showMessagePopup('Error', 'Error While Fetching Template Data', result.returnMessage);
                }
            })
            .catch(error => {
                this.resolvedPromise++
                errorDebugger('TemplateBuilder', 'getTemplateValues', error, 'warn', 'Error in getTemplateData APEX Method.');
            })
        } catch (error) {
            errorDebugger('TemplateBuilder', 'getTemplateValues', error, 'warn');
        }
    }

    setDataInMainEditor(){
        try {
            if(this.contentEditor && this.dataLoaded && !this.valueInserted){
                $(this.contentEditor).summernote('code', this.bodyData);
                this.setEditorPageSize();
                this.valueInserted = true;
            }
        } catch (error) {
            errorDebugger('TemplateBuilder', 'setDataInMainEditor', error, 'warn');
        }
    }

    setDataInHeader(){
        if(this.headerEditor && this.dataLoaded){
            $(this.headerEditor).summernote('code', this.headerData);
        }
    }

    setDataInFooter(){
        if(this.footerEditor && this.dataLoaded){
            $(this.footerEditor).summernote('code', this.footerData);
            this.setPageHeaderFooterMargin()
        }
    }

    // ==> Save methods
    saveTemplateData(){
        if(this.lastRelatedListTableCount <= this.maxRelatedLIstTableLimit){
            if(this.templateRecord?.MVDG__Template_Name__c){
                this.isSpinner = true;
                this.saveTemplateValue('save');
            }
            else{
                this.showMessagePopup('error', 'Template Name Empty!', `Template Name is Required, You can not save template without a name.`);
            }
        }
        else{
            this.showMessagePopup('error', 'Warning !', `Related List Table Limit Exceeded. You Can Not Add More Then ${this.maxRelatedLIstTableLimit} Related List Tables.`);
        }
    }

    saveTemplateValue(actionName){
        try {
            this.loaderLabel = 'Saving Data...'

            /**
             * To get editor content, do not use .summernote('code') directly, 
             * Please create dom element and add innerHTML into it and then get that element's innerHTML as editor content,
             * This is doing in order to maintain formatting with extracted child table,
             * If we directly use .summernote('code') method to get editor content, it result in unmatched attribute position for child table during the document creation...
             */
            let headerEle, footerEle, bodyEle;
            
            if (typeof window !== 'undefined') {   
                headerEle = document.createElement('div');
                headerEle.innerHTML = $(this.headerEditor).summernote('code');
                
                footerEle = document.createElement('div');
                footerEle.innerHTML = $(this.footerEditor).summernote('code');
                
                bodyEle = document.createElement('div');
                bodyEle.innerHTML = $(this.contentEditor).summernote('code');
            }
                
            this.headerData = headerEle.innerHTML;
            this.bodyData = bodyEle.innerHTML;
            this.footerData = footerEle.innerHTML;
            let watermarkData = JSON.stringify(this.watermark);
            // extract mapping keys...
            let extractedMappingKeys = this.extractMappingKeys();

            // Separate Template Data By Long TExt area Length....
            let splitLength = 130000;       // character length to store in long text area....
            // (1 record (Portion) = 130000 character = 0.13 MB => 30 records = 3.9 MB )
            let batchSize = 30;             // number of template data records (portions) in single batch...
            let totalBatches = 0;

            let headerDataRecords = [];
            let footerDataRecords = [];
            let bodyDataRecords = [];
            let watermarkDataRecords = [];

            // separate header value by 130000 characters...
            let headerDataPortions = Math.ceil(this.headerData.length / splitLength);
            for(let i = 1; i<= headerDataPortions; i++){
                let startIndex = (i - 1)*splitLength ;
                let endIndex = i ==  headerDataPortions ? this.headerData.length : (i * splitLength);
                headerDataRecords.push(this.headerData.substring(startIndex, endIndex));
            }

            // separate footer value by 130000 characters...
            let footerDataPortions = Math.ceil(this.footerData.length / splitLength);
            for(let i = 1; i<= footerDataPortions; i++){
                let startIndex = (i - 1)*splitLength ;
                let endIndex = i ==  footerDataPortions ? this.footerData.length : (i * splitLength);
                footerDataRecords.push(this.footerData.substring(startIndex, endIndex));
            }

            // separate body value by 130000 characters...
            let bodyDataPortions = Math.ceil(this.bodyData.length / splitLength);
            for(let i = 1; i<= bodyDataPortions; i++){
                let startIndex = (i - 1)*splitLength ;
                let endIndex = i ==  bodyDataPortions ? this.bodyData.length : (i * splitLength);
                bodyDataRecords.push(this.bodyData.substring(startIndex, endIndex));
            }

            // separate body value by 130000 characters...
            let watermarkDataPortions = Math.ceil(watermarkData.length / splitLength);
            for(let i = 1; i<= watermarkDataPortions; i++){
                let startIndex = (i - 1)*splitLength ;
                let endIndex = i ==  watermarkDataPortions ? watermarkData.length : (i * splitLength);
                watermarkDataRecords.push(watermarkData.substring(startIndex, endIndex));
            }

            // merge body, header, footer and extracted key values in single object to send to apex...
            let templateValuePortion = {
                'Header Value' : headerDataRecords,
                'Footer Value' : footerDataRecords,
                'Watermark Value' : watermarkDataRecords,
                'Extracted Mapping Keys' : [JSON.stringify(extractedMappingKeys)],
            }

            let bodyDataBatchesByMB = [];
            // if total data portion is lesser than 30 =>  30 * 1,30,000 = 3.9 MB
            // means total data is lesser than 4 MB (around 3.64MB)... so send all data in one apex call...
            if((headerDataPortions + footerDataPortions + bodyDataPortions + watermarkDataPortions) < batchSize){
                templateValuePortion['Body Value'] = bodyDataRecords;
            }
            else{
                // else data may be larger data 4MB... so Send Body Value is batches....
                totalBatches = Math.ceil(bodyDataRecords.length / batchSize);
                for(let i = 1; i <= totalBatches; i++){
                    let start = (i-1)*batchSize;
                    let end = i*batchSize > bodyDataRecords.length ? bodyDataRecords.length : (i*batchSize) - 1;
                    const currentBatchRecords ={};
                    for(let j = start ; j <= end; j++){
                        currentBatchRecords[j+1] = bodyDataRecords[j];
                    }
                    bodyDataBatchesByMB.push(currentBatchRecords);
                }
            }

            let totalProcesses = totalBatches + 1;
            let completedProcess = 0;

            console.log('templateValuePortion : ', templateValuePortion);
            

            // Call Apex Method to save Template...
            saveTemplateApex({templateRecord : this.templateRecord, templateValues : templateValuePortion, pageConfigs : this.pageConfigRecord})
            .then((result) => {
                if(result){
                    completedProcess++;
                    this.handleOngoingAction(actionName, completedProcess, totalProcesses);
                    this.tempRecordSaved = JSON.parse(JSON.stringify(this.templateRecord));
                    this.pageConfigSaved = JSON.parse(JSON.stringify(this.pageConfigRecord));
                }
                else{
                    completedProcess++;
                    this.isSpinner = this.stopSpinner(completedProcess, totalProcesses);
                    errorDebugger('TemplateBuilder', 'saveTemplateValue', result, 'warn', 'Error in saveTemplateApex APEX Method');
                }
            })
            .catch(error => {
                errorDebugger('TemplateBuilder', 'saveTemplateValue', error, 'warn', 'Error in saveTemplateApex APEX Method');
                completedProcess++;
                this.isSpinner = this.stopSpinner(completedProcess , totalProcesses);
            })

            const tempIdVsValueType = {};
            tempIdVsValueType[this.templateRecord.Id] = 'Body Value';
            // will execute when we required to save data in batch (totalBatches < 0)...
            for(let i = 1; i <= totalBatches; i++){
                const isLastBatch = i == totalBatches ? true : false;
                saveTempDataRecordsInBatch({templateDataList : bodyDataBatchesByMB[i-1], tempIdVsValueType : tempIdVsValueType, isLastBatch : isLastBatch})
                .then((result) => {
                    if(result){
                        completedProcess++;
                        this.handleOngoingAction(actionName, completedProcess, totalProcesses);
                    }
                    else{
                        completedProcess++;
                        this.isSpinner = this.stopSpinner(completedProcess , totalProcesses);
                        errorDebugger('TemplateBuilder', 'saveTemplateValue', {'message' : result.returnMessage}, 'warn', 'Error in saveTempDataRecordsInBatch APEX Method');
                    }
                })
                .catch((error) => {
                    completedProcess++;
                    this.isSpinner = this.stopSpinner(completedProcess , totalProcesses);
                    errorDebugger('TemplateBuilder', 'saveTemplateValue', error, 'warn', 'Error in saveTempDataRecordsInBatch APEX Method');
                })
            }

        } catch (error) {
            this.isSpinner = false;
            errorDebugger('TemplateBuilder', 'saveTemplateValue', error, 'warn', `Error during ${actionName}`);
        }
    }

    handleOngoingAction(actionName, completedProcess, totalProcesses){
        try {
            this.isSpinner = this.stopSpinner(completedProcess , totalProcesses);
            if(!this.isSpinner){
                this.spinnerFor = actionName;
                if(actionName == 'save'){
                    this.loaderLabel = 'Data Saved Successfully...'
                }
                else if(actionName == 'preview'){
                    // Spinner is running for preview; 
                    // On the spinner close, dispatch event will run, that will make variable true to open preview modal
                    this.loaderLabel = 'Opening Preview...'
                }
            }
        } catch (error) {
            errorDebugger('TemplateBuilder', 'handleOngoingAction', error, 'warn');
        }
    }

    stopSpinner(completedProcess, totalProcesses){
        return completedProcess == totalProcesses ? false : true;
    }

    handleCloseEdit(){
        try {
            this.isCloseConfirmation = true;
            this.showMessagePopup('Warning', 'Are You Want to Leave?', `Your unsaved changes will be discarded once you leave the this page.`);

        } catch (error) {
            errorDebugger('TemplateBuilder', 'handleCloseEdit', error, 'warn');
        }
    }
    
    closeEditTemplate(){
        try {
            $(this.contentEditor)?.summernote('destroy');
            this.navigateToComp(navigationComps.home);

        } catch (error) {
            errorDebugger('TemplateBuilder', 'closeEditTemplate', error, 'warn');
        }
    }

    cancelEditTemplate(){
        this.templateRecord = JSON.parse(JSON.stringify(this.tempRecordSaved));
        this.pageConfigRecord = JSON.parse(JSON.stringify(this.pageConfigSaved));
        
        this.setPageConfigVariable();
        this.currentTab = 'contentTab';
        this.setActiveTab();
    }

    handleSaveNPreview(){
        if(this.lastRelatedListTableCount <= this.maxRelatedLIstTableLimit){
            if(this.templateRecord?.MVDG__Template_Name__c){
                this.isSpinner = true;
                this.saveTemplateValue('preview');
            }
            else{
                this.showMessagePopup('error', 'Template Name Empty!', `Template Name is Required, You can not save template without a name.`);
            };
        }
        else{
            this.showMessagePopup('error', 'Warning !', `Related List Table Limit Exceeded. You Can Not Add More Then ${this.maxRelatedLIstTableLimit} Related List Tables.`);
        }
    }

    vfPageLoaded(){
        try {
            this.isSpinner = false;
            // const iframe = this.template.querySelector('iframe');
            // const pdfViewer = iframe.querySelector( 'pdf-viewer' );
        } catch (error) {
            errorDebugger('TemplateBuilder', 'vfPageLoaded', error, 'warn');
        }
    }

    closeTemplatePreview(){
        try {
            this.isPreview = false;
        } catch (error) {
            errorDebugger('TemplateBuilder', 'closeTemplatePreview', error, 'warn');
        }
    }

    // ==== Toggle Tabs Methods - START - ========
    activeTab(event){
        try {
            if(event){
                this.currentTab = event.currentTarget.dataset.name;
            }
            this.setActiveTab();
        } catch (error) {
            errorDebugger('TemplateBuilder', 'activeTab', error, 'warn');
        }
    }

    setActiveTab(){
        try {
            const activeTabBar = this.template.querySelector(`.activeTabBar`);
            const activeTab = this.template.querySelector(`[data-name="${this.currentTab}"]`);
            activeTabBar.style = `  transform: translateX(${activeTab.offsetLeft}px);
                                    width : ${activeTab.clientWidth}px;`;

            // this.currentTab === 'basicTab' && this.setDummyPageSize();
        } catch (error) {
            errorDebugger('TemplateBuilder', 'setActiveTab', error, 'warn');
        }
    }
    // ==== Toggle Tabs Methods - END - ========

    // #fieldMapping...
    toggleMappingContainerHeight(){
        try {
            const keyMappingContainer = this.template.querySelector('c-key-mapping-container');
            if(this.isMappingContainerExpanded){
                this.isMappingContainerExpanded = false;
                keyMappingContainer.style = ``;
            }
            else {
                this.isMappingContainerExpanded = true;
                keyMappingContainer.style = ` height : calc(100% - 0.9rem);
                                                top : 0.1rem;`;
            }
        } catch (error) {
            errorDebugger('TemplateBuilder', 'toggleMappingContainerHeight', error, 'warn');
        }
    }

    handleEditDetail(event){
        try {
            const targetInput = event.currentTarget.dataset.name;
            if(event.target.type === 'checkbox'){
                this.templateRecord[targetInput] = event.target.checked;
            }
            else{
                this.templateRecord[targetInput] = (event.target.value).trim();
            }
        } catch (error) {
            errorDebugger('TemplateBuilder', 'handleEditDetail', error, 'warn');
        }
    }

    // ==== === === === PAGE Config and PAGE Size Setup Method --- START --- ==== ===== ===== =====

    // Function -- run when change page config values from UI...
    // To set page config on in pageConfigs variable and pageConfigRecord Object ...
    managePageConfigs(event){
        try {
            const pageConfig = event.currentTarget.dataset.config;
            const configName = event.currentTarget.dataset.name;
            const value = event.target.value;

            if(pageConfig == 'pageOrientation' || pageConfig == 'pageSize'){
                this.pageConfigs[pageConfig].forEach(ele => {
                    ele.selected = ele.name == configName ? true : false;
                })

                this.pageConfigRecord.MVDG__Page_Orientation__c = pageConfig == 'pageOrientation' ? value : this.pageConfigRecord.MVDG__Page_Orientation__c;
                this.pageConfigRecord.MVDG__Page_Size__c = pageConfig == 'pageSize' ? value : this.pageConfigRecord.MVDG__Page_Size__c;

            }
            else if(pageConfig == 'unitOptions'){
                this.pageConfigs[pageConfig].forEach(ele => {
                    ele.selected = ele.value == value ? true : false;
                });
                this.pageConfigs['unit'] = value;

                this.convertConfigValue(this.pageConfigRecord.MVDG__Unit_of_Page_Configs__c, value);
                this.pageConfigRecord.MVDG__Unit_of_Page_Configs__c = value;
                
            }
            else if(pageConfig == 'pageMargins'){
                this.pageConfigs[pageConfig].find(ele => ele.name == configName).value = value;

            }
            else if(pageConfig == 'header' || pageConfig == 'footer'){
                if(configName == 'show'){
                    this.pageConfigs[pageConfig][configName] = event.target.checked;
                }
                else{
                    this.pageConfigs[pageConfig][configName] = value ? value : 0;
                }
            }
            
            this.setPageMarginValue();                  // Do not remove it, it is added intentionally
            this.setHeaderFooterMargin();               // Do not remove it, it is added intentionally
            this.setEditorPageSize();
            (pageConfig != 'pageMargins') && this.setPageMarginValue();
            (pageConfig != 'header' && pageConfig != 'footer') && this.setHeaderFooterMargin();
        } catch (error) {
            errorDebugger('TemplateBuilder', 'managePageConfigs', error, 'warn');
        }
    }

    // Function Set Page Margin value from pageConfig variable to pageConfigRecord Object for the backend side work...
    setPageMarginValue(){
        try {
            let pageMarginsTop = this.pageConfigs['pageMargins'][0].value;
            let pageMarginsBottom = this.pageConfigs['pageMargins'][1].value;
            let pageMarginsLeft = this.pageConfigs['pageMargins'][2].value;
            let pageMarginsRight = this.pageConfigs['pageMargins'][3].value;

            let k = unitMultiplier(this.pageConfigRecord.MVDG__Unit_of_Page_Configs__c)* 1.3334;

            pageMarginsTop = pageMarginsTop ? pageMarginsTop : 0;
            pageMarginsTop = Math.max(pageMarginsTop, 0);
            
            pageMarginsBottom = pageMarginsBottom ? pageMarginsBottom : 0;
            pageMarginsBottom = Math.max(pageMarginsBottom, 0);
            
            pageMarginsLeft = pageMarginsLeft ? pageMarginsLeft : 0;
            pageMarginsLeft = Math.max(pageMarginsLeft, 0);
            
            pageMarginsRight = pageMarginsRight ? pageMarginsRight : 0;
            pageMarginsRight = Math.max(pageMarginsRight, 0);

            // restrict margin/padding to exceed page page width/height....
            // when margin value is more than page width/height - opposite margin value... restrict to increase margin value...
            
            // configName == 'top' 
            pageMarginsTop = Math.min(pageMarginsTop, (this.currentPageHeight / k - pageMarginsBottom))
            pageMarginsTop = Math.max(pageMarginsTop, 0);
            (this.pageConfigs['pageMargins'][0].value = pageMarginsTop);

            // configName == 'bottom'
            pageMarginsBottom = Math.min(pageMarginsBottom, (this.currentPageHeight / k - pageMarginsTop))
            pageMarginsBottom = Math.max(pageMarginsBottom, 0);
            (this.pageConfigs['pageMargins'][1].value = pageMarginsBottom);

            // configName == 'left'
            pageMarginsLeft = Math.min(pageMarginsLeft, (this.currentPageWidth / k - pageMarginsRight))
            pageMarginsLeft = Math.max(pageMarginsLeft, 0);
            (this.pageConfigs['pageMargins'][2].value = pageMarginsLeft);

            // configName == 'right'
            pageMarginsRight = Math.min(pageMarginsRight, (this.currentPageWidth / k - pageMarginsLeft))
            pageMarginsRight = Math.max(pageMarginsRight, 0);
            (this.pageConfigs['pageMargins'][3].value = pageMarginsRight);

            this.pageConfigRecord.MVDG__Page_Margin__c = pageMarginsTop+';'+pageMarginsBottom+';'+pageMarginsLeft+';'+pageMarginsRight;
        } catch (error) {
            errorDebugger('TemplateBuilder', 'setPageMarginValue', error, 'warn');
        }
    }

        // Set Header(top) and footer(bottom) editor margin in config variable...
    setHeaderFooterMargin(){
        try {
            let k = unitMultiplier(this.pageConfigRecord.MVDG__Unit_of_Page_Configs__c)* 1.3334;
            let pageHeight = this.currentPageHeight / k;

            if(this.pageConfigs.header.marginTop > pageHeight * 0.4){
                this.pageConfigs.header.marginTop = pageHeight * 0.4
            }
            else if(this.pageConfigs.header.marginTop < 0){
                this.pageConfigs.header.marginTop = 0;
            }

            if(this.pageConfigs.footer.marginBottom > pageHeight * 0.4){
                this.pageConfigs.footer.marginBottom = pageHeight * 0.4;
            }
            else if(this.pageConfigs.footer.marginBottom < 0){
                this.pageConfigs.footer.marginBottom = 0;
            }

            this.pageConfigRecord.MVDG__Show_Header__c = this.pageConfigs.header.show;
            this.pageConfigRecord.MVDG__Header_margin_top__c = this.pageConfigs.header.marginTop;

            this.pageConfigRecord.MVDG__Show_Footer__c = this.pageConfigs.footer.show;
            this.pageConfigRecord.MVDG__Footer_margin_bottom__c = this.pageConfigs.footer.marginBottom;

            this.setPageHeaderFooterMargin();

        } catch (error) {
            errorDebugger('TemplateBuilder', 'setHeaderFooterMargin', error, 'warn');
        }
    }

    // Set Header(top) and footer(bottom) editor margin in editor page...
    setPageHeaderFooterMargin(){
        if (typeof window !== 'undefined') {   
            const root = document?.querySelector(':root');
            let unit = this.pageConfigRecord.MVDG__Unit_of_Page_Configs__c;
            
            root.style.setProperty('--headerMarginsTop', `${this.pageConfigs.header.marginTop}${unit}`);
            root.style.setProperty('--footerMarginsBottom', `${this.pageConfigs.footer.marginBottom}${unit}`);
        }
    }

    convertConfigValue(previousUnit, currentUnit){
        try {
            this.pageConfigs.pageMargins.forEach(ele => {
                ele.value = unitConverter(previousUnit, currentUnit, ele.value);
            })

            this.pageConfigs.header.marginTop = unitConverter(previousUnit, currentUnit, this.pageConfigs.header.marginTop);
            this.pageConfigs.footer.marginBottom = unitConverter(previousUnit, currentUnit, this.pageConfigs.footer.marginBottom);

        } catch (error) {
            errorDebugger('TemplateBuilder', 'convertConfigValue', error, 'warn');
        }
    }

    // === ==== === Function to Set template page record's value in pageConfig variable to display in UI/Front-End.. === === ===
    setPageConfigVariable(){
        try {
            this.pageConfigs['pageMargins'][0].value = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[0];
            this.pageConfigs['pageMargins'][1].value = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[1];
            this.pageConfigs['pageMargins'][2].value = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[2];
            this.pageConfigs['pageMargins'][3].value = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[3];

            this.pageConfigs['pageOrientation'].forEach(ele => {
                ele['selected'] = ele.value == this.pageConfigRecord.MVDG__Page_Orientation__c ? true : false;
            });

            this.pageConfigs['pageSize'].forEach(ele => {
                ele['selected'] = ele.value == this.pageConfigRecord.MVDG__Page_Size__c ? true : false;
            });

            this.pageConfigs['unitOptions'].forEach(ele => {
                ele['selected'] = ele.value == this.pageConfigRecord.MVDG__Unit_of_Page_Configs__c ? true : false;
            });

            this.pageConfigs['unit'] = this.pageConfigRecord.MVDG__Unit_of_Page_Configs__c;

            if(this.contentEditor && this.dataLoaded){
                this.setEditorPageSize();
            }

            this.pageConfigs.header.show = this.pageConfigRecord.MVDG__Show_Header__c;
            this.pageConfigs.header.marginTop = this.pageConfigRecord.MVDG__Header_margin_top__c;

            this.pageConfigs.footer.show = this.pageConfigRecord.MVDG__Show_Footer__c;
            this.pageConfigs.footer.marginBottom = this.pageConfigRecord.MVDG__Footer_margin_bottom__c;

            this.pageConfigs.watermark.show = this.pageConfigRecord.MVDG__Show_Watermark__c;

        } catch (error) {
            errorDebugger('TemplateBuilder', 'setPageConfigVariable', error, 'warn');
        }
    }

    // Set all Editor page size based on page config changes...
    setEditorPageSize(){
        try {
            let root;
            if (typeof window !== 'undefined') {   
                root = document?.querySelector(':root');
            }

            let pageMarginsTop = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[0];
            let pageMarginsBottom = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[1];
            let pageMarginsLeft = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[2];
            let pageMarginsRight = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[3];

            let unit = this.pageConfigRecord.MVDG__Unit_of_Page_Configs__c;
            let pageSize = this.pageConfigRecord.MVDG__Page_Size__c;
            let orientation = this.pageConfigRecord.MVDG__Page_Orientation__c;

            this.currentPageWidth = (orientation == 'portrait' ? pageFormats[pageSize][0] : pageFormats[pageSize][1]) * 1.3334;
            this.currentPageHeight = (orientation == 'portrait' ? pageFormats[pageSize][1] : pageFormats[pageSize][0]) * 1.3334;

            root.style.setProperty('--pageWidth', `${this.currentPageWidth}px`);
            root.style.setProperty('--pageHeight', `${this.currentPageHeight}px`);
            root.style.setProperty('--pageMarginTop', `${pageMarginsTop}${unit}`);
            root.style.setProperty('--pageMarginBottom', `${pageMarginsBottom}${unit}`);
            root.style.setProperty('--pageMarginLeft', `${pageMarginsLeft}${unit}`);
            root.style.setProperty('--pageMarginRight', `${pageMarginsRight}${unit}`);

            this.setEditorArea();
            // this.setDummyPageSize();

        } catch (error) {
            errorDebugger('TemplateBuilder', 'setEditorPageSize', error, 'warn');
        }
    }

    // Set keyMapping container and editor area as per page size....
    setEditorArea(){
        try {
            let root;
            if (typeof window !== 'undefined') {
                root = document?.querySelector(':root');
            }
            let keyMappingContainer = this.template.querySelector('c-key-mapping-container');

            if (typeof window !== 'undefined') {   
                if(window.innerWidth > 1350){
                    // Here, Windows.innerWidth represent the width of contentEditorFrame/(.note-frame) width;
                    const mapContainerWidth = (window?.innerWidth >= 1440 ? (35 * 16) : (30 * 16)) + 32;
                    if(window?.innerWidth - this.currentPageWidth < mapContainerWidth){
                        //  If difference Screen width and editor page width is less than key Mapping container width... 
                        // key Mapping container can not set in that place... So Toggle the container
                        keyMappingContainer?.toggleMappingContainer(true);
                        root.style.setProperty('--editingAreaWidth', 'calc(100% - 2rem)');
                    }
                    else{
                        // Show field Mapping Container
                        keyMappingContainer?.toggleMappingContainer(false);
                        
                        root.style.setProperty('--editingAreaWidth', `calc(100% - var(--keyMappingWidth) - 1.25rem)`);
                    }
                }
                else{
                    // Hide field Mapping Container
                    // Show Button ( << Insert Field Button) to Open Field Mapping...
                    keyMappingContainer?.toggleMappingContainer(true);
                    // Set Editor Page CSS....
                    root.style.setProperty('--editingAreaWidth', 'calc(100% - 2rem)');
                }
            }

        } catch (error) {
            errorDebugger('TemplateBuilder', 'setEditorArea', error, 'warn');
        }
    }

    setDummyPageSize(){
        try {
            let pageMarginsTop = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[0];
            let pageMarginsBottom = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[1];
            let pageMarginsLeft = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[2];
            let pageMarginsRight = this.pageConfigRecord.MVDG__Page_Margin__c.split(';')[3];
        
            let unit = this.pageConfigRecord.MVDG__Unit_of_Page_Configs__c;
            let aspectRatio = this.currentPageWidth/this.currentPageHeight;
        
            const dummyPage = this.template.querySelector('.dummyPage');
            dummyPage.style = `aspect-ratio : ${aspectRatio}`;
            const dummyPageWidth = dummyPage?.clientWidth;
            const m = dummyPageWidth/this.currentPageWidth;
            dummyPage.style = ` padding : ${pageMarginsTop*m}${unit} ${pageMarginsRight*m}${unit} ${pageMarginsBottom*m}${unit} ${pageMarginsLeft*m}${unit} !important;
                                aspect-ratio : ${aspectRatio}`;
        } catch (error) {
            errorDebugger('TemplateBuilder', 'setDummyPageSize', error, 'warn');
        }
    }
    // ==== === === === PAGE Config and PAGE Size Setup Method --- END --- ==== ===== ===== =====


    selectAllOnFocus(event){
        event.target.select();
    }

    // === ==== ==== Child Record table Generation Method -- START --- === === === ====
    openGenChildTablePopup(event){
        const childObjectTableBuilder = this.template.querySelector('c-child-object-table-builder');
        childObjectTableBuilder && childObjectTableBuilder.openPopup(event);
    }

    closeGenChildTable(){
        const childObjectTableBuilder = this.template.querySelector('c-child-object-table-builder');
        childObjectTableBuilder && childObjectTableBuilder.closePopup();
    }
    // === ==== ==== Child Record table Generation Method -- END --- === === === ====


    // === ==== ==== ==== ==== Method called from EditorConfig JS -- START--  === ==== ==== ==== ==== ====
    //  Method to Calculation Related List (Child Table) --- ---- -----
    calculateRelatedListTable(note){
        try {
            const keyMappingChildComp = this.template.querySelector('c-key-mapping-container ');
            if(keyMappingChildComp){
              const page = note.noteEditorFrame.querySelector('.note-editable');
              let relatedListTables = page?.querySelectorAll(`[data-name="childRecords"]`);
    
              let validTableCount = 0;
              relatedListTables?.forEach(ele => {
                if(ele.querySelector('[data-name="keyRow"]') &&
                  ele.querySelector('[data-name="infoRow"]')){
                    validTableCount ++;
                  }
              })
    
              if(validTableCount >= this.maxRelatedLIstTableLimit){
                // When Limit Exceed
                keyMappingChildComp.relatedListTableLimitExceed(true);
              }
              else if(validTableCount != this.lastRelatedListTableCount){
                keyMappingChildComp.relatedListTableLimitExceed(false);
              }
              this.lastRelatedListTableCount = validTableCount;
            }
        } catch (error) {
          errorDebugger('TemplateBuilder', 'calculateRelatedListTable', error, 'warn');
        }
    }

    setHeaderFooterMaxHeight(note, event){
        try {
            if(note.selector == 'headerEditor' || note.selector == 'footerEditor'){
                const page = note.noteEditorFrame?.querySelector('.note-editable');
                page.scrollTop = 0;
                const pageRect = page.getBoundingClientRect();

                if(event){
                    let selection
                    if (typeof window !== 'undefined') {   
                        selection = window?.getSelection();
                    }
                    const cursorNode = selection?.anchorNode;
                    const cursorNodeRect = cursorNode && cursorNode.nodeName !== "#text" ? cursorNode.getBoundingClientRect() : null;
                    if(cursorNodeRect?.bottom > pageRect.bottom){
                        event.preventDefault();
                    }
                }
                else{
                    const content = page.querySelectorAll('*');
                    content?.forEach(ele => {
                        const eleRect = ele.getBoundingClientRect();
                        if(eleRect.top > pageRect.bottom){
                            ele.remove();
                        }
                    })
                }

            }
        } catch (error) {
          errorDebugger('TemplateBuilder', 'setHeaderFooterMaxHeight', error, 'warn');
        }
    }

    restrictLargeImageInsert(note){
        try {
            const page = note.noteEditorFrame?.querySelector('.note-editable');
            const images = page?.querySelectorAll('img');
            images?.forEach(ele => {
                if(ele.src.startsWith('data:image/')){
                    const base64 = ele.src.split(',')[1];
                    const imageSize = base64.length * 3 / 4; 
                    if(imageSize > this.maxImageSize){
                        ele.remove();
                        this.showMessageToast('error', 'Image size larger than 3 MB', 'You can only insert image upto 3 MB.')
                    }
                }
            })
        } catch (error) {
          errorDebugger('TemplateBuilder', 'restrictLargeImageInsert', error, 'warn');
        }
    }

    togglePageConfigPopover(){
        try {
            const pageConfigPopover = this.template.querySelector('.pageConfigPopover');
            const pageConfigs = this.template.querySelector('.pageConfigs');
            this.isPageSetup = !this.isPageSetup;
            this.setActivePageConfigs(this.isPageSetup);
            if(this.isPageSetup){
                pageConfigPopover.classList.remove('close');
                const pageConfigDiv = this.template.querySelector('.pageConfigDiv');
                pageConfigDiv.appendChild(pageConfigs);
                // this.setDummyPageSize();
            }
            else{
                pageConfigPopover.classList.add('close');
                const basicDetails_sub = this.template.querySelector('.basicDetails_sub');
                basicDetails_sub.appendChild(pageConfigs);
            }
            this.popConfigDiscard = JSON.parse(JSON.stringify(this.pageConfigRecord));
        } catch (error) {
            errorDebugger('TemplateBuilder', 'togglePageConfigPopover', error, 'warn');
        }
    }
    // === ==== ==== ==== ==== Method called from EditorConfig JS -- END --  === ==== ==== ==== ==== ====

    discardPageConfig(){
        this.pageConfigRecord = JSON.parse(JSON.stringify(this.popConfigDiscard));
        this.setPageConfigVariable();
        this.togglePageConfigPopover();
    }


    setActivePageConfigs(isOpen){
        if(isOpen){
            this.activePageConfigs = ['pageMarginConfig', 'pageSizeConfig', 'pageOrientationConfig'];
            // if(this.currentTab == 'contentTab'){
            //     this.activePageConfigs = ['pageMarginConfig', 'pageSizeConfig', 'pageOrientationConfig'];
            // }
            // else if(this.currentTab == 'headerTab'){
            //     this.activePageConfigs = ['pageHeaderConfig'];
            // }
            // else if(this.currentTab == 'footerTab'){
            //     this.activePageConfigs = ['pageFooterConfig'];
            // }
        }
        else{
            this.activePageConfigs = [];
        }
   }

    scrollToTop(note){
        try {
            if(note.selector == 'headerEditor'){
                const page = note.noteEditorFrame.querySelector('.'+note.selector);
                page && (page.scrollTop = 0);
            }
            else if(note.selector == 'footerEditor'){
                const page = note.noteEditorFrame.querySelector('.'+note.selector);
                page && (page.scrollTop = 0);
            }
        } catch (error) {
            errorDebugger('TemplateBuilder', 'scrollToTop', error, 'warn');
        }
    }

    // === ==== ==== Extract Mapping Methods -- START -- ==== ==== ====
    extractMappingKeys(){
        try {
            const innerHTML = this.headerData + this.bodyData + this.footerData;
        
            // const objectFields = this.extractedKeys(innerHTML, /{{#(.*?)}}/g);
            // const generalFields = this.extractedKeys(innerHTML, /{{Doc.(.*?)}}/g);
            // const mergeTempKeys = this.extractedKeys(innerHTML, /{{Temp.(.*?)}}/g);
            // const signatureKeys = this.extractedKeys(innerHTML, /{{Sign.(.*?)}}/g)
            
            const objectFields = this.extractedKeys(innerHTML, /\{\{#([^{}]+)\}\}/g);
            const generalFields = this.extractedKeys(innerHTML, /\{\{Doc.([^{}]+)\}\}/g);
            const mergeTempKeys = this.extractedKeys(innerHTML, /\{\{Temp.([^{}]+)\}\}/g);
            const signatureKeys = this.extractedKeys(innerHTML, /\{\{Sign.([^{}]+)\}\}/g)
            const childRecordTables = this.extractChildRecordTables();
            const sfImages = this.extractSalesforceImages();

            const signatureKey = '{{Sign.DocGenius *Signature Key*}}';

            return  {
                        'objectFields' : objectFields, 
                        'generalFields' : generalFields, 
                        'mergeTempKeys' : mergeTempKeys, 
                        'childRecordTables' : childRecordTables,
                        'signatureKeys' : signatureKeys,
                        'salesforceImages' : sfImages,
                        'signatureImage' : innerHTML.includes(signatureKey) ? signatureKey : null,
                    }

        } catch (error) {
            errorDebugger('TemplateBuilder', 'extractMappingKeys', error, 'warn');
        }
    }

    extractedKeys(innerText, pattern){
        const extractedKeys = new Set();

        let matcher;
        while(((matcher = pattern.exec(innerText)) !== null)){
            extractedKeys.add(matcher[0]);
        }

         return Array.from(extractedKeys);
    }

    extractChildRecordTables(){
        try {
            const childRecordTables = [];
            if (typeof window !== 'undefined') {
                const bodyEle = document?.createElement('div');
                bodyEle.innerHTML = $(this.contentEditor).summernote('code');
                bodyEle.querySelectorAll(`[data-name="childRecords"]`)?.forEach(ele => {
                    const childTableInfo = this.extractChildTableInfo(ele);
                    if(childTableInfo?.tableHTML && childTableInfo?.keyRow && childTableInfo?.infoRow){
                        childRecordTables.push(childTableInfo);
                    }
                });
                
                const headerEle = document.createElement('div');
                headerEle.innerHTML = $(this.headerEditor).summernote('code');
                headerEle.querySelectorAll(`[data-name="childRecords"]`)?.forEach(ele => {
                    const childTableInfo = this.extractChildTableInfo(ele);
                    if(childTableInfo?.tableHTML && childTableInfo?.keyRow && childTableInfo?.infoRow){
                        childRecordTables.push(childTableInfo);
                    }
                });
                
                const footerEle = document.createElement('div');
                footerEle.innerHTML = $(this.footerEditor).summernote('code');
                footerEle.querySelectorAll(`[data-name="childRecords"]`)?.forEach(ele => {
                    const childTableInfo = this.extractChildTableInfo(ele);
                    if(childTableInfo?.tableHTML && childTableInfo?.keyRow && childTableInfo?.infoRow){
                        childRecordTables.push(childTableInfo);
                    }
                });
            }
            return childRecordTables;

        } catch (error) {
            errorDebugger('TemplateBuilder', 'extractChildRecordTables', error, 'warn');
            return [];
        }
    }

    extractChildTableInfo(ele){
        try {
            const childTableWrapper = {
                tableHTML : '', 
                keyRow : '', 
                infoRow : '', 
                mappingFields : [],
            };
            
            childTableWrapper.tableHTML = ele?.outerHTML;

            const keyRow = ele?.querySelector(`[data-name="keyRow"]`);
            childTableWrapper.keyRow = keyRow?.outerHTML;

            childTableWrapper.mappingFields = this.extractedKeys(keyRow?.innerText,/\{\{!([^{}]+)\}\}/g);

            const infoRow = ele?.querySelector(`[data-name="infoRow"]`);
            childTableWrapper.infoRow = infoRow?.outerHTML;

            return childTableWrapper;
        } catch (error) {
            errorDebugger('TemplateBuilder', 'extractChildTableInfo', error, 'warn');
            return {};
        }
    }

    extractSalesforceImages(){
        try {
            const extractedSfImages = new Set();
            const innerHTML = this.headerData + this.bodyData + this.footerData;

            let div;
            if (typeof window !== 'undefined') {   
                div = document.createElement('div');
                div.innerHTML = innerHTML;
            }

            const images = div.querySelectorAll('img');
            images?.forEach(ele => {
                if(ele.dataset.origin == 'sf' || ele.src.includes('sfc/servlet.shepherd/version/download')){
                    extractedSfImages.add(ele.src);
                }
            })

            return Array.from(extractedSfImages);
        } catch (error) {
            errorDebugger('TemplateBuilder', 'extractSalesforceImages', error, 'warn');
            return [];
        }
    }
    // === ==== ==== Extract Mapping Methods -- END --- ==== ==== ====


    // ==== ==== ==== Watermark -- START -- ==== ==== ====
    setWatermarkOptsTab(event){
        try {
            Object.keys(this.watermarkOptsTabs).forEach((ele) => {
                if(ele === event.currentTarget.dataset.name){
                    this.template.querySelector(`[data-name="${ele}"]`)?.classList.add('selected');
                    this.watermarkOptsTabs[ele] = true;
                }
                else{
                    this.template.querySelector(`[data-name="${ele}"]`)?.classList.remove('selected');
                    this.watermarkOptsTabs[ele] = false;
                }
            })
        } catch (error) {
            errorDebugger('TemplateBuilder', 'setWatermarkOptsTab', error, 'warn');
        }
    }

    setWatermarkImageUpload(event){
        try {
            const file = event.target.files[0];
            const reader = new FileReader();
            reader.readAsDataURL(file);
            reader.onload = () => {
                this.watermark.image.src = reader.result;
                this.setWatermarkPreview();
            }
        } catch (error) {
            errorDebugger('TemplateBuilder', 'setWatermarkImageUpload', error, 'warn');
        }
    }

    setWatermarkImage(event){
        try {
            this.watermark.image[event.currentTarget.dataset.name] = event.target.value;
            this.setWatermarkPreview();
        } catch (error) {
            errorDebugger('TemplateBuilder', 'setWatermarkImage', error, 'warn');
        }

    }

    setWatermarkText(event){
        if(event.target.type === 'checkbox'){
            this.watermark.text[event.currentTarget.dataset.name] = event.target.checked;
        }
        else{
            this.watermark.text[event.currentTarget.dataset.name] = event.target.value;
        }

        this.setWatermarkPreview();
    }

    setWatermarkTextSize(event){
        if(event.target.dataset.name === 'minus'){
            this.watermark?.text?.size > 0 && (this.watermark.text.size = this.watermark.text.size - 1);
        }
        else if(event.target.dataset.name === 'plus'){
            this.watermark?.text?.size < 100 && (this.watermark.text.size = this.watermark.text.size + 1);
        }
        else{
            (event.target.value === '' || event.target.value === null) && (event.target.value = 10) && (this.watermark.text.size = 10)
        }

        this.setWatermarkPreview();

    }

    setWatermarkShowHideOpt(event){
        this.pageConfigs['watermark']['show'] = event.target.checked;
        this.pageConfigRecord.MVDG__Show_Watermark__c = event.target.checked;
    }

    setWatermarkPreview(){
        try {
            const watermarkImage = this.template.querySelector('[data-name="watermarkPreviewImage"]');
            watermarkImage && (watermarkImage.style = `
                                    top : ${this.watermark.image.top}%;
                                    left : ${this.watermark.image.left}%;
                                    transform : translate(-${this.watermark.image.left}%, -${this.watermark.image.top}%) rotate(${this.watermark.image.rotate}deg);
                                    width : ${this.watermark.image.size}%;
                                    opacity : ${this.watermark.image.opacity/100};
                                    `);
            
            const watermarkText = this.template.querySelector('[data-name="watermarkPreviewText"]');
            watermarkText && (watermarkText.style = `
                                    ${this.watermark.text.bold ? 'font-weight : bold;' : ''}
                                    ${this.watermark.text.italic ? 'font-style : italic;' : ''}
                                    ${this.watermark.text.underline ? 'text-decoration : underline;' : ''}
                                    ${this.watermark.text.strikethrough ? 'text-decoration : line-through;' : ''}
                                    ${this.watermark.text.strikethrough & this.watermark.text.underline ? 'text-decoration : underline line-through;' : ''}
                                    font-size : ${this.watermark.text.size}px;
                                    font-family : ${this.watermark.text.fontFamily};
                                    color : ${this.watermark.text.color};
                                    top : ${this.watermark.text.top}%;
                                    left : ${this.watermark.text.left}%;
                                    transform : translate(-${this.watermark.text.left}%, -${this.watermark.text.top}%) rotate(${this.watermark.text.rotate}deg);
                                    opacity : ${this.watermark.text.opacity/100};
                                    `);
        } catch (error) {
            errorDebugger('TemplateBuilder', 'setWatermarkPreview', error, 'warn');
        }
    }
    // ==== ==== ==== Watermark -- END -- ==== ==== ====

    customTimeoutMethod = (event) =>{
        event.target.classList.remove('dummyAnimation');
        // this.isPreview = true;
    }

    handleMsgPopConfirmation(event){
        try {
            if(this.noTemplateFound){
                /**
                 * ... Popup message show WHEN Editor fail to initialize... 
                 * OR
                 * ... Popup message show WHEN Template Id Not Found...
                 */
                this.closeEditTemplate();
            }
            else if(!this.isLoadedSuccessfully){
                window?.globalThis?.location.reload();
            }
            else if(!this.templateRecord.MVDG__Template_Name__c && !this.noTemplateFound){
                // ... Popup Message Appear when user try to save without filling template name...
                this.currentTab = 'basicTab';
                this.setActiveTab();
            }
            else if(this.isCloseConfirmation){
                //... Popup message show WHEN User click on close button select YES...
                if(event.detail){
                    this.closeEditTemplate();
                }
                this.isCloseConfirmation = false;
            }
        } catch (error) {
            errorDebugger('TemplateBuilder', 'handleMsgPopConfirmation', error, 'warn');
        }
    }

    handleSpinnerClose(){
        try {
            if(this.spinnerFor == 'preview'){
                this.isPreview = true;
                this.spinnerFor = null;
            }
        } catch (error) {
            errorDebugger('TemplateBuilder', 'handleSpinnerClose', error, 'warn');
        }
    }
    
    moveToBasicDetail(){
        this.currentTab = 'basicTab';
        this.setActiveTab();
    }

    updateTemplateStatus(){
        // Update Template in Backend...
        if(!this.templateRecord.MVDG__Template_Status__c){
            updateTemplate({ templateId : this.templateRecord.Id, isActive : true})
            .then(result => {
                if(result === 'updated'){
                    this.templateRecord['MVDG__Template_Status__c'] = true;
                    this.tempRecordSaved = JSON.parse(JSON.stringify(this.templateRecord));
                }
                else{
                    this.showMessageToast('error', 'Something Went Wrong!', 'we are facing issue to update template status.')
                }
            })
            .catch(error => {
                errorDebugger('TemplateBuilder', 'updateTemplateStatus', error, 'warn', 'error in apex method updateTemplate');
            })
        }
    }


    // ====== ======= ======== ======= ======= ====== GENERIC Method ====== ======= ======== ======= ======= ======
     // Generic Method to test Message Popup and Toast
        showMessagePopup(Status, Title, Message, doneBtnLabel){
            const messageContainer = this.template.querySelector('c-message-popup')
            if(messageContainer){
                messageContainer.showMessagePopup({
                    status: Status,
                    title: Title,
                    message : Message,
                    doneButtonLabel : doneBtnLabel,
                });
            }
        }

        showMessageToast(Status, Title, Message, Duration){
            const messageContainer = this.template.querySelector('c-message-popup')
            if(messageContainer){
                messageContainer.showMessageToast({
                    status: Status,
                    title: Title,
                    message : Message,
                    duration : Duration
                });
            }
        }

        navigateToComp(componentName, paramToPass){
            try {
                let cmpDef;
                if(paramToPass && Object.keys(paramToPass).length > 0){
                    cmpDef = {
                        componentDef: `${nameSpace}:${componentName}`,
                        attributes: paramToPass
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
            } catch (error) {
                errorDebugger('TemplateBuilder', 'navigateToComp', error, 'warn');
            }
        }

        eventStopPropagation(event){
            event.stopPropagation();
        }
}