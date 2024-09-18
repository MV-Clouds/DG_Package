import { LightningElement, track , api} from 'lwc';
import getFieldMappingKeys from '@salesforce/apex/KeyMappingController.getFieldMappingKeys';
import saveTemplateFields from '@salesforce/apex/EditCSVTemplateController.saveTemplateFields';
import getCombinedData from '@salesforce/apex/EditCSVTemplateController.getCombinedData';
import getSessionId from '@salesforce/apex/GenerateDocumentController.getSessionId';
import updateTemplate from '@salesforce/apex/EditCSVTemplateController.updateTemplate';
import {NavigationMixin} from 'lightning/navigation';
import {navigationComps, nameSpace, errorDebugger} from 'c/globalProperties';


export default class EditCSVTemplate extends NavigationMixin(LightningElement) {

    // -=-=- the values we got from the Home page/new template popup -=-=-
    @api objectName;
    @api templateId;

    //-=-=- to Show/hide the Spinner -=-=-
    @track showSpinner;

    @track showBasicDetailTab = false;
    @track showDefaultsTab = false;
    @track showPreview = false;

    //to handle the confirmation message
    @track isListViewUpdate = false;
    @track isClose = false;
    @track isCancelTemplate = false;
    @track isReset = false;
    @track isClear = false;


    //-=-=- To run a function only once, when we want in rendered callback -=-=-
    initialRender = true;
    initialFilters = true;
    initialSorts = true;
    filtersCount = 0;
    sortsCount = 0;
    isUpdateOnlyLastFilter = false;

    //-=-=- Field Selection -=-=-
    @track fieldOptions = [];
    @track allRetrievedFields = [];
    @track fieldMappingsWithObj;
    @track relatedObjects = [];
    @track selectedRelatedObject = this.objectName;
    searchKey = '';
    @track SearchFieldOptions = [];
    @track selectedFields = [];
    @track toAddSelected = [];
    @track toRemoveSelected = [];

    @track isEditTabChanged = false;
    @track isBasicTabChanged = false;

    // ===== ===== ===== ===== ===== CHANGES TO USED AS CHILD OBJECT SELECTION -- START -- ==== ===== =====

    _isChild;
    @api get isChild() { return this._isChild};
    set isChild(value){ this._isChild = (value == 'true' || value == true) ? true : false}

    get isTabSection(){
        return !this.isChild ? true : false;
    }

    get saveBtnLabel(){
        return this.isChild ? 'Generate Table' : 'Save'
    }
    // ===== ===== ===== ===== ===== CHANGES TO USED AS CHILD OBJECT SELECTION -- END ---- ==== ===== =====

    //-=-=- Filter/Sort/Logic Selection -=-=-
    separatedData = {
        fields : null,
        filters : null,
        listView : null,
        logic : null,
        orders : null,
        maxLimit : null
    };
    generatedQuery = '';
    @track limit = 1000000;   
    @track childMaxLimit = 50;
    @track fieldsForFilters = [];
    @track allOperatorOptions = [
        //String
        { label: 'Equals to', value: '=', type: 'default, url, string, textarea, id, number, percent, double, integer, phone, date, datetime, time, email, currency, boolean, multipicklist' },
        { label: 'Not Equals to', value: '!=', type: 'default, url, string, textarea, id, number, percent, double, integer, phone, date, datetime, time, email, currency, boolean, multipicklist' },
        { label: 'Contains', value: 'LIKE', type: ', url, string, textarea, email, picklist' },
        { label: 'Does not contain', value: 'notLIKE', type: ', url, string, textarea, email, picklist' },
        { label: 'Starts with', value: 'startLIKE', type: ', url, string, textarea, email, phone, picklist' },
        { label: 'Ends with', value: 'endLIKE', type: ', url, string, textarea, email, phone, picklist' },
        { label: 'Include', value: 'IN', type: 'multipicklist, picklist, string' },
        { label: 'Exclude', value: 'notIN', type: 'multipicklist, picklist, string' },
        { label: 'Greater Than', value: '>', type: 'number, percent, double, integer, currency, picklist, url, string, date, datetime, time' },
        { label: 'Less Than', value: '<', type: 'number, percent, double, integer, currency, picklist, url, string, date, datetime, time' },
        { label: 'Greater or equal', value: '>=', type: 'number, percent, double, integer, currency, picklist, url, string, date, datetime, time' },
        { label: 'Less or equal	', value: '<=', type: 'number, percent, double, integer, currency, picklist, url, string, date, datetime, time' },
    ];

    operatorMap = new Map([
        ['equals', '='],
        ['notEquals', '!='],
        ['lessThan', '<'],
        ['greaterThan', '>'],
        ['lessThanOrEqualTo', '<='],
        ['greaterThanOrEqualTo', '>='],
        ['like', 'LIKE'],
        ['notLike', 'notLIKE'],
    ]);
    @track logicOperators = [
        { label: 'AND', value: 'AND'},
        { label: 'OR', value: 'OR'},
        { label: 'Custom', value: 'Custom'}
    ];
    @track customLogicString ='';
    @track isCustomLogic = false;
    isCustomLogicValid = true;
    @track selectedLogic = 'AND';
    @track showLimitInput = false;
    @track filters = [{
        fieldName: '',
        operator: '',
        value: '',
        type :'',
        inputType : '',
        operators : []
    }];
    @track allPreDefinedValues = ["NULL","TODAY","YESTERDAY","TOMORROW","THIS WEEK","THIS MONTH","THIS QUARTER","THIS YEAR","THIS FISCAL YEAR","THIS FISCAL QUARTER","NEXT YEAR","NEXT WEEK","NEXT QUARTER","NEXT MONTH","NEXT FISCAL YEAR","NEXT FISCAL QUARTER","LAST YEAR","LAST WEEK","LAST QUARTER","LAST MONTH","LAST FISCAL YEAR","LAST FISCAL QUARTER"];
    @track preDefinedValues = [...this.allPreDefinedValues];
    @track sorts = [{
        field: '',
        order: ''
    }]

    //-=-=- For list view selection -=-=-
    @track showListViewPopup;
    @track allListViews =[];
    tempListView;
    @track selectedListView;
    @track isListViewUpdated = false;

    @track existingTemplateData = {};
    @track newTemplateData = {};

    @track listViewSearchKey = '';
    @track noListViewFound = false;


    //-=-=- To Hold all previous value -=-=-
    @track existingFields = [];
    @track existingFilters = [{
        fieldName: '',
        operator: '',
        value: '',
    }];
    @track existingSorts = [{
        field: '',
        order: ''
    }];
    @track existingLimit= this.limit;
    @track existingShowLimitInput = false;
    @track existingLogic = this.selectedLogic;
    @track existingCustomLogicString=this.customLogicString;


    //-=-=- to reset the sections
    @track resetSection;
    @track clearSection;
    

    get updatedAllListViews(){
        let searchedListViews = this.allListViews.filter(lv => lv.label.toUpperCase().includes(this.listViewSearchKey.toUpperCase()));
        this.noListViewFound = searchedListViews.length <1 ? true : false;
        if(!this.listViewSearchKey){
            return this.allListViews;
        }
        return searchedListViews;
    }

    get fieldOptionsToShow(){
        this.fieldOptions = this.fieldOptions.filter(op => !this.selectedFields.some(p => p.apiName === op.apiName)).slice().sort((a, b) => a.fieldName.localeCompare(b.fieldName));
        let fieldOptionsUpdated;        
        if (!this.searchKey) {
            return this.fieldOptions.map(option => {
                return { ...option, isSelected: this.toAddSelected.some(p => p.apiName === option.apiName) };
            });
        }

        fieldOptionsUpdated =  this.fieldOptions.filter(option => option.fieldName.toLowerCase().includes(this.searchKey.toLowerCase())).map(option => {
            return { ...option, isSelected: this.toAddSelected.some(p => p.apiName === option.apiName) };
        });
        return fieldOptionsUpdated;
    }

//-=-=- Specially to show Index from 1, instead of 0 for the Sorts -=-=-
    get adjustedSorts() {
        return this.sorts?.map((sort, index) => {
            return {...sort, displayIndex: index + 1};
        });
    }

    get adjustedFilters() {
        return this.filters?.map((filter, index) => {
            this.template.querySelectorAll('.operator-select')[index]?.classList.add('dont-display-div');
            this.template.querySelectorAll('.value-select-div')[index]?.classList.add('dont-display-div');
            if(this.filters.length==1 && !filter.fieldName){
                this.template.querySelectorAll('.filter-field-select')[index]?.classList.remove('error-in-custom-combobox');
            }
            if(filter.fieldName){
                this.template.querySelectorAll('.operator-select')[index]?.classList.remove('dont-display-div');
            }else{
                filter.operator = '';
                filter.value = '';
                this.template.querySelectorAll('.operator-select')[index]?.classList.remove('error-in-custom-combobox');
                this.template.querySelectorAll('.operator-select')[index]?.classList.add('dont-display-div');
                this.template.querySelectorAll('.value-select-div')[index]?.classList.add('dont-display-div');
            }
            if(filter.operator){
                this.template.querySelectorAll('.value-select-div')[index]?.classList.remove('dont-display-div');
            }else{
                filter.value = '';
                this.template.querySelectorAll('.value-select-div')[index]?.classList.add('dont-display-div');
            }
            return {...filter,step : '0.0001', maxLImit:filter.inputType === 'number' ? '19' : ['id','reference'].includes(filter.type?.toLowerCase()) ? '18' : filter.type?.toLowerCase() === 'phone' ? '40' : '255', displayIndex: index + 1, isPicklist: ['PICKLIST' , 'MULTIPICKLIST' , 'BOOLEAN'].includes(filter.type) , isMultiple: filter.operator == 'IN' || filter.operator == 'notIN' || filter.type =='MULTIPICKLIST'};
        });
    }

    get selectedAvailableFields(){
        return this.toAddSelected.length ? this.toAddSelected.length : this.toRemoveSelected.length;
    }
    
    promises = [];
    _resolvedPromise = 0;
    get resolvedPromise(){ return this._resolvedPromise;}
    set resolvedPromise(value){
        let totalProcess = this.isChild ? 1 : 2;
        (value == totalProcess) && (this.showSpinner = false);
        this._resolvedPromise = value;
    }

    connectedCallback() {
        try {
            this.showSpinner = true;

            this.limit = this.isChild ? this.childMaxLimit : 1000000;
            this.existingLimit = this.limit;

            this.fetchFields();
            !this.isChild && this.fetchCombinedData();
        }catch(e) {
            errorDebugger('editCSVTemplate', 'connectedCallback', e, 'warn');
        }
    }

// -=-=- To override the style of the standard Input fields and the comboboxes, update dom for filters and sorts -=-=-
    renderedCallback(){
        try {
            this.handleInitialStyle();
            this.handleInitialFilters();
            this.handleInitialSorts();
        }catch(e) {
            errorDebugger('editCSVTemplate', 'renderedCallback', e, 'warn');
        }
    }

    handleInitialStyle(){
        try {
            if(this.initialRender){
                // To OverRider standard slds css properties...
                let mainFilterDiv = this.template.querySelector('.main-div');
                let styleEle;
                if (!import.meta.env.SSR) {
                    styleEle = document.createElement('style');
                }
                styleEle.innerText = `
                    .override-css-from-js .slds-input:not(c-custom-combobox .slds-input){
                        height: calc( 2.5rem - 2px );
                        border-radius: 0.43rem;
                        border: 1px solid var(--slds-c-input-color-border);
                        box-shadow: none;
                    }

                    .basic-detail-div .slds-input:not(c-custom-combobox .slds-input):focus, .limit-div .slds-input:not(c-custom-combobox .slds-input):focus{
                        border: 1px solid #00aeff;
                    }

                    .override-css-from-js .slds-input[disabled]{
                        border: none !important;
                    }

                    .override-css-from-js .slds-textarea{
                        height: 3.5rem;
                        border-radius: 0.5rem;
                        border: 1px solid var(--slds-c-input-color-border);
                        box-shadow: none !important;
                    }

                    .override-css-from-js .slds-textarea:focus{
                        border: 1px solid #00aeff !important;
                    }
                    
                    .override-css-from-js .fix-slds-input_faux{
                        height: 2.5rem;
                        border-radius: 0.5rem;
                        border: 1px solid var(--slds-c-input-color-border);
                    }

                    .override-css-from-js .fix-slds-input_faux{
                        display: flex;
                        align-items: center;
                    }
                    .override-css-from-js .slds-form-element__label:empty {
                        margin: 0;
                        padding: 0;
                    }

                    .slds-form-element__help {
                        display: none;
                    }

                    .simple-input-div .slds-input__icon.slds-input__icon_right {
                        pointer-events: all;
                        z-index: 10;
                    }

                    .simple-input-div:has(lightning-datepicker) lightning-timepicker {
                        border-left: 2px solid #d5ebff;
                    }

                    .simple-input-div:not(:has(lightning-datepicker)) lightning-timepicker {
                        display : block;
                    }

                    .simple-input-div .slds-form-element_compound .slds-form-element{
                        width : 100%;
                        padding : 0;
                    }
                    
                    .simple-input-div .slds-form-element_compound .slds-form-element__row{
                        background-color : white;
                        border-radius : 0.5rem;
                        margin : 0;
                    }

                    .simple-input-div .slds-button:hover, .simple-input-div .slds-button:focus{
                        color: #00aeff;
                    }

                    .simple-input-div .slds-icon-text-default:hover, .simple-input-div .slds-icon-text-default:focus {
                        --slds-c-icon-color-foreground: #00aeff;
                        cursor: pointer;
                    }

                    .limit-div .slds-checkbox_toggle .slds-checkbox_faux{
                        box-shadow : none !important;
                    }
                `;
                if(mainFilterDiv){
                    mainFilterDiv.appendChild(styleEle);
                    this.initialRender = false;
                }
            }
        } catch (e) {
            errorDebugger('editCSVTemplate', 'handleInitialStyle', e, 'warn');
        }
    }

    handleInitialFilters(){
        try {
            if(this.initialFilters){
                if (this.template.querySelector('.filter-div') && this.filtersCount==this.filters?.length) { // Check if all filters are rendered
                    if(this.filtersCount>0){
                        this.showSpinner = true;
                        if(this.isUpdateOnlyLastFilter){
                            this.updateOperatorOptions(this.filtersCount-1);
                        }else{
                            for(let i =0; i<this.filters?.length; i++) {
                                this.updateOperatorOptions(i);
                            }
                        }
                        this.initialFilters = false;
                        this.showSpinner = false;
                        this.isUpdateOnlyLastFilter = false;
                    }else{
                        this.initialFilters = false;
                    }
                }
            }
        } catch (e) {
            errorDebugger('editCSVTemplate', 'handleInitialFilters', e, 'warn');
        }
    }

    handleInitialSorts(){
        try {
            if(this.initialSorts){
                if (this.template.querySelector('.sort-div') && this.sortsCount==this.sorts?.length) { // Check if all sorts are rendered
                    if(this.sortsCount>0){
                        this.showSpinner = true;
                        for(let i =0; i<this.sorts?.length; i++) {
                            this.updateSelectedSort(i);
                        }
                        this.initialSorts = false;
                        this.showSpinner = false;
                    }else{
                        this.initialSorts = false;
                    }
                }
            }
        } catch (e) {
            errorDebugger('editCSVTemplate', 'handleInitialSorts', e, 'warn');
        }
    }

    fetchCombinedData(){
        try {
            getCombinedData({templateId: this.templateId, objName: this.objectName})
            .then((combinedData) => {
                if(combinedData.isSuccess){
                    combinedData.template ? this.setupTemplateDetails(combinedData.template) : undefined;
                    combinedData.templateData ? this.setupTemplateDataDetails(combinedData.templateData) : undefined;
                    combinedData.listViews ? this.setUpListViews(combinedData.listViews) : undefined;
                    this.showListViewPopup = !this.selectedFields?.length>0 && this.allListViews?.length>0 ?  true : false;
                }else{
                    this.showWarningPopup('error','Something went wrong!', 'Couldn\'t fetch the required data for this template, please try again...');
                    this.isClose = true;
                }
            })
            .catch((e) => {
                errorDebugger('editCSVTemplate', 'fetchCombinedData > getCombinedData', e, 'warn');
                this.showWarningPopup('error','Something went wrong!', 'Couldn\'t fetch the required data for this template, please try again...');
                this.isClose = true;
            })
            .finally(()=>{
                this.resolvedPromise++;
            })
        }catch(e) {
            errorDebugger('editCSVTemplate', 'fetchCombinedData', e, 'warn');
            this.showWarningPopup('error','Something went wrong!', 'Couldn\'t fetch the required data for this template, please try again...');
            this.isClose = true;
        }
    }
    setupTemplateDetails(data){
        try {
            this.existingTemplateData = JSON.parse(JSON.stringify(data));
            this.newTemplateData = JSON.parse(JSON.stringify(this.existingTemplateData));
        }catch(e) {
            this.showSpinner = false;
            this.showToast('error', 'Something went wrong!', 'Error fetching details from template.', 5000);
            errorDebugger('editCSVTemplate', 'setupTemplateDetails', e, 'warn');
        }
    }

    setupTemplateDataDetails(data) {
        try {
            this.separatedData = data;
            this.parseFilterString();
        }catch(e) {
            this.showSpinner = false;
            this.showToast('error', 'Something went wrong!', 'Error setting up template field data values.', 5000);
            errorDebugger('editCSVTemplate', 'setupTemplateDataDetails', e, 'warn');
        }
    }
    
    setUpListViews(data) {
        try {
            this.allListViews = data.map(listView => ({ label: listView.Name, value: listView.Id }));  
        }catch(e) {
            this.showSpinner = false;
            this.showToast('error', 'Something went wrong!', 'Error setting up list views.', 5000);
            errorDebugger('editCSVTemplate', 'setUpListViews', e, 'warn');
        }
    }
    
    fetchFields(){
        try {
            let getParents = !this.isChild      // if isChild object is true dont get parent objects
            getFieldMappingKeys({sourceObjectAPI : this.objectName, getParentFields : getParents})
            .then(result => {
                if(result.isSuccess){
                    let allFields = [];
                    let relatedObjectList = [];
                    result.fieldMappingsWithObj.slice().sort((a, b) => a.label.localeCompare(b.label)).forEach(obj => {
                        let allFieldsForThisObject = [];
                        relatedObjectList.push({label : obj.label, value: obj.name});
                        if(!obj.label.includes('>')){
                            this.selectedRelatedObject = obj.name;
                        }
                        obj.fieldMappings = obj.fieldMappings.map(({ label, name, type, isSearchable, picklistValues}) => {
                            const thisField ={
                                fieldType: type,
                                apiName: name,
                                fieldName: obj.label.includes('>') ? obj.label.split(' > ')[1] + ' > ' + label : label,
                                isSearchable : isSearchable,
                            }
                            if(picklistValues){
                                thisField.picklistValues = picklistValues;
                            }
                            allFieldsForThisObject.push(thisField);
                            return thisField;
                        });
                        allFieldsForThisObject.slice().sort((a, b) => a.fieldName.localeCompare(b.fieldName));
                        allFields.push(...allFieldsForThisObject);
                    });
                    this.allRetrievedFields = [...allFields];
                    this.relatedObjects = JSON.parse(JSON.stringify(relatedObjectList));
                    this.fieldMappingsWithObj = [...result.fieldMappingsWithObj];
                    this.setSelectionFields();
                    this.setFilterFields();
                    this.resolvedPromise++;
                }
                else{
                    this.resolvedPromise++;
                    this.showToast('Error', 'Error While Fetching Field Mapping Data', result.returnMessage);
                }
            })
            .catch(e => {
                this.resolvedPromise++;
                errorDebugger('editCSVTemplate', 'fetchFields > getFieldMappingKeys', e, 'warn');
            })
        }catch(e) {
            this.resolvedPromise++;
            errorDebugger('editCSVTemplate', 'fetchFields', e, 'warn');
        }
    }

    setSelectionFields(){
        try {
            if(this.selectedRelatedObject) this.fieldOptions = this.fieldMappingsWithObj.find(ele =>  ele.name == this.selectedRelatedObject).fieldMappings;
        }catch(e) {
            errorDebugger('editCSVTemplate', 'setSelectionFields', e, 'warn');
        }
    }

    setFilterFields(){
        try{
            this.fieldsForFilters = this.allRetrievedFields
                .filter(option => option.isSearchable)
                .map(option => ({ label: option.fieldName, value: option.apiName, type: option.fieldType }));
        }catch(e){
            errorDebugger('editCSVTemplate', 'setFilterFields', e, 'warn');
        }
    }

    activeTab(event){
         try {
             let activeTabName = event.currentTarget.dataset.name;
             if(activeTabName === 'editTab'){
                this.showSpinner = true;
                this.showBasicDetailTab = false;
                this.template.querySelector('.main-flex-div').style.display = 'flex';
                this.showDefaultsTab = false;
                this.initialFilters = true;
                this.filtersCount = this.filters?.length;
            }else if(activeTabName === 'basicTab'){
                this.showBasicDetailTab = true;
                this.template.querySelector('.main-flex-div').style.display = 'none';
                this.showDefaultsTab = false;
            }else if(activeTabName === 'defaultsTab'){
                this.showDefaultsTab = true;
                this.showBasicDetailTab = false;
                this.template.querySelector('.main-flex-div').style.display = 'none';
            }
            this.setActiveTab(activeTabName);
        }catch(e) {
            errorDebugger('editCSVTemplate', 'activeTab', e, 'warn');
        }
    }

    setActiveTab(activeTabName){
        try{
            const activeTabBar = this.template.querySelector(`.active-tab-bar`);
            const tabS = this.template.querySelectorAll('.tab');
    
            tabS.forEach(ele => {
                if(ele.dataset.name === activeTabName){
                    ele.classList.add('active-tab');
                    activeTabBar.style = ` transform: translateX(${ele.offsetLeft}px);
                                    width : ${ele.clientWidth}px;`;
                }
                else{
                    ele.classList.remove('active-tab');
                }
            })
        }catch(e){
            errorDebugger('editCSVTemplate', 'setActiveTab', e, 'warn');
        }
    }

    handleRelatedObjectChange(event){
        try {
            this.selectedRelatedObject = event.detail[0];
            this.toAddSelected = [];
            this.setSelectionFields();
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleRelatedObjectChange', e, 'warn');
        }
    }

// -=-=- To Handle Search functionality from the search key -=-=-
    handleFieldSearch(event){
        this.searchKey = event.target.value.trim();
    }

// -=-=- To add the Selected fields from the Available section of the Field Selection -=-=-
    handleAvailableClick(event){
        try{
            this.toRemoveSelected = [];
            this.template.querySelectorAll(".field-li-to-selected").forEach(element => element.classList.remove("selected-item"));
            let currentField = event.currentTarget.dataset.value;
            let currentAPI = event.currentTarget.dataset.api;
            const isCtrlPressed = event.ctrlKey || event.metaKey;
            if (!Array.isArray(this.toAddSelected)) {
                this.toAddSelected = [];
            }
            const index = this.toAddSelected.findIndex(item => item.apiName === currentAPI);
        
            if (isCtrlPressed) {
                if (index !== -1) {
                    this.toAddSelected.splice(index, 1);
                    event.currentTarget.classList.remove("selected-item");
                } else {
                    this.toAddSelected.push({ fieldName: currentField, apiName: currentAPI});
                    event.currentTarget.classList.add("selected-item");
                }
            } else {
                this.toAddSelected = [];
                this.template.querySelectorAll("li").forEach(element => element.classList.remove("selected-item"));
                event.currentTarget.classList.toggle("selected-item"); // Toggle styling
                this.toAddSelected.push({ fieldName: currentField, apiName: currentAPI}); // Add to array
            }
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleAvailableClick', e, 'warn');
        }
    }

// -=-=- To add the selected fields from the Selected section of the Field Selection -=-=-
    handleSelectedClick(event){
        try{
            this.toAddSelected = [];
            this.template.querySelectorAll(".field-li-to-select").forEach(element => element.classList.remove("selected-item"));
            const currentField = event.currentTarget.dataset.value;
            const currentAPI = event.currentTarget.dataset.api;
            const isCtrlPressed = event.ctrlKey || event.metaKey;
            if (!Array.isArray(this.toRemoveSelected)) {
            this.toRemoveSelected = [];
            }
            const index = this.toRemoveSelected.findIndex(item => item.apiName === currentAPI);
        
            if (isCtrlPressed) {
            if (index !== -1) {
                this.toRemoveSelected.splice(index, 1);
                event.currentTarget.classList.remove("selected-item");
            } else {
                this.toRemoveSelected.push({ fieldName: currentField, apiName: currentAPI});
                event.currentTarget.classList.add("selected-item");
            }
            } else {
            this.toRemoveSelected = [];
            this.template.querySelectorAll("li").forEach(element => element.classList.remove("selected-item"));
            event.currentTarget.classList.toggle("selected-item"); // Toggle styling
            this.toRemoveSelected.push({ fieldName: currentField, apiName: currentAPI}); // Add to array
            }
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleSelectedClick', e, 'warn');
        }
    }

// -=-=- To Move selected fields Up by one index -=-=-
    handleUp(){
        try{
            this.reorderList();
            for(let i = 0;i<this.toRemoveSelected.length;i++){
                let index = this.selectedFields.findIndex(obj => obj.apiName === this.toRemoveSelected[i].apiName);
                if(index<=0){
                    break;
                }
                [this.selectedFields[index], this.selectedFields[index-1]] = [this.selectedFields[index-1], this.selectedFields[index]]
            }
            this.isEditTabChanged = true;
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleUp', e, 'warn');
        }
    }

// -=-=- To move the selected fields down by one index-=-=-
    handleDown(){
        try{
            this.reorderList();
            for(let i = this.toRemoveSelected.length-1;i>=0;i--){
                let index = this.selectedFields.findIndex(obj => obj.apiName === this.toRemoveSelected[i].apiName);
                if(index>=this.selectedFields.length-1){
                    break;
                }
                [this.selectedFields[index], this.selectedFields[index+1]] = [this.selectedFields[index+1], this.selectedFields[index]]
            }
            this.isEditTabChanged = true;
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleDown', e, 'warn');
        }
    }

    handleTop(){
        try{
            this.moveFieldsToPosition('top');
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleTop', e, 'warn');
        }
    }

    handleBottom(){
        try {
            this.moveFieldsToPosition('bottom');
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleBottom', e, 'warn');
        }
    }

// -=-=- It works as the Helper function for the handleUp and handleDown Processes -=-=-
    reorderList(){
        try{
            const toRemoveMap = new Map(this.toRemoveSelected.map(el => [el.apiName, el]));
            this.toRemoveSelected = this.selectedFields.map(field => toRemoveMap.get(field.apiName)).filter(el => el);
        }catch(e) {
            errorDebugger('editCSVTemplate', 'reorderList', e, 'warn');
        }
    }

// Move selected fields to a specific position (top or bottom)
    moveFieldsToPosition(position) {
        try {
            this.reorderList();
            const selectedApiNames = new Set(this.toRemoveSelected.map(item => item.apiName));
            const remainingFields = this.selectedFields.filter(field => !selectedApiNames.has(field.apiName));
            this.selectedFields = position === 'top' ? [...this.toRemoveSelected, ...remainingFields] : [...remainingFields, ...this.toRemoveSelected];
            this.isEditTabChanged = true;
        } catch (e) {
            errorDebugger('editCSVTemplate', 'moveFieldsToPosition', e, 'warn');
        }
    }

// -=-=- To move the Selected fields form the Selected section to the Available Section and remove from the Selected section -=-=-
    handleLeft(){
        try{
            this.toRemoveSelected.forEach(item => {
                this.selectedFields = this.selectedFields.filter(field => field.apiName !== item.apiName);
            });
            let uniqueFieldOptions = new Set([...this.fieldOptions, ...this.toRemoveSelected]);
            this.fieldOptions = Array.from(uniqueFieldOptions);
            this.toRemoveSelected = [];
            this.isEditTabChanged = true;
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleLeft', e, 'warn');
        }
    }

// -=-=- To move the Selected fields form the Available section to the Selected Section and remove from the Available section -=-=-
    handleRight(){
        try{
            this.toAddSelected.forEach(item => {
                this.fieldOptions = this.fieldOptions.filter(field => field.apiName !== item.apiName);
                this.selectedFields.push(item);
            });
            this.toAddSelected = [];
            this.isEditTabChanged = true;
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleRight', e, 'warn');
        }
    }

// -=-=- To add One empty filter object to the filters list -=-=-
    addFilter() {
        try {
            let hasError = false;
            const filterFieldSelects = this.template.querySelectorAll('.filter-field-select');
            const operatorSelects = this.template.querySelectorAll('.operator-select');
            const valueSelectDivs = this.template.querySelectorAll('.value-select-div');

            if (this.filters && this.filters.length !== 0) {
                this.filters.forEach((filter, i) => {
                    filterFieldSelects[i].classList.remove('error-in-custom-combobox');
                    operatorSelects[i].classList.remove('error-in-custom-combobox');
                    valueSelectDivs[i].classList.remove('error-in-value-input');

                    if (!filter.fieldName) {
                        filterFieldSelects[i].classList.add('error-in-custom-combobox');
                        hasError = true;
                        return;
                    } 
                    if (!filter.operator) {
                        operatorSelects[i].classList.add('error-in-custom-combobox');
                        hasError = true;
                        return;
                    } 
                    if (!filter.value) {
                        valueSelectDivs[i].classList.add('error-in-value-input');
                        hasError = true;
                        return;
                    }
                });
                if (hasError) return;
            } else {
                this.filters = [];
            }
            this.filters.push({
                fieldName: null,
                operator: null,
                value: null,
                type: null,
                inputType: null,
                operators: []
            });
            this.filtersCount = this.filters.length;
            this.isUpdateOnlyLastFilter = true;
            this.initialFilters = true;
        } catch (e) {
            errorDebugger('editCSVTemplate', 'addFilter', e, 'warn');
        }
    }

// -=-=- To add One empty Sort object to the Sorts list -=-=-
    addSort() {
        try{
            let hasError = false;
            if(this.sorts && this.sorts?.length != 0){
                let sortFields = this.template.querySelectorAll('.sort-field-select');
                this.sorts.forEach((sort, i) => {
                    sortFields[i].classList.toggle('error-in-custom-combobox', !sort.field);
                    if(!sort.field){
                        hasError = true;
                        return;
                    }
                    return;
                })
                if(hasError) return;
            }
            this.sorts.push({
                field:'',
                order:''
            });
        }catch(e){
            errorDebugger('editCSVTemplate', 'addSort', e, 'warn');
        }
    }
    
// -=-=- To remove clicked filter from the filters list -=-=-
    removeFilter(event){
        try {
            const index = event?.target?.dataset?.index;
            if(this.filters.length >1){
                this.filters.splice(index, 1);
            }else if(this.filters.length ==1){
                Object.assign(this.filters[0], {
                    fieldName: null,
                    operator: null,
                    value: null,
                    operators: [],
                    type: null,
                    inputType: null,
                });
                this.template.querySelectorAll('.filter-index-div')[0].classList.remove('error-in-row');
            }
            this.isEditTabChanged = true;

            this.filtersCount = this.filters.length;
            this.initialFilters = true;
            
            let fields = this.template.querySelectorAll('.filter-field-select');
            let operators = this.template.querySelectorAll('.operator-select');
            let values = this.template.querySelectorAll('.value-select-div');
            this.filters.forEach((filter, i) => {
                fields[i].classList.toggle('error-in-custom-combobox', !filter.fieldName);
                operators[i].classList.toggle('error-in-custom-combobox', filter.fieldName && !filter.operator);
                values[i].classList.toggle('error-in-value-input', filter.fieldName && filter.operator && !filter.value);
            })
        }catch(e) {
            errorDebugger('editCSVTemplate', 'removeFilter', e, 'warn');
        }
    }

// -=-=- To remove clicked sort from the sorts list -=-=-
    removeSort(event){
        try{
            const index = event.target.dataset.index;
            if(this.sorts.length >1){
                this.sorts.splice(index, 1);
            }else if(this.sorts.length ===1){
                this.sorts[0].field = '';
                this.sorts[0].order = '';
                this.template.querySelector('.sort-index-div').classList.remove('error-in-row');
                this.template.querySelector('.asc-btn').classList.remove('selected-sort-order');
                this.template.querySelector('.desc-btn').classList.remove('selected-sort-order');
                this.template.querySelector('.sort-field-select').classList.remove('error-in-custom-combobox');
            }
            this.isEditTabChanged = true;

            this.sorts.forEach((sort, i) => {
                this.handleSortFieldChange({detail:[sort.field],target:{dataset:{index:i}}});
            })
        }catch(e){
            errorDebugger('editCSVTemplate', 'removeSort', e, 'warn');
        }
    }

// -=-=- To validate duplicate sort field and make sort order ASC -=-=- 
    handleSortFieldChange(event){
        try {
            const index = event.target.dataset.index;
            let selectedSortFields = this.sorts.map((sort) => {return sort.field});
            const currentSortField = event.detail[0];
            const ascBtn = this.template.querySelectorAll('.asc-btn')[index];
            const descBtn = this.template.querySelectorAll('.desc-btn')[index];
            const sortField = this.template.querySelectorAll('.sort-field-select')[index];
            if(!currentSortField){
                this.sorts[index].field = '';
                this.sorts[index].order = '';
                ascBtn.classList.remove('selected-sort-order');
                descBtn.classList.remove('selected-sort-order');
                if(this.sorts.length > 1){
                    sortField.classList.add('error-in-custom-combobox');
                }
                return;
            }
            sortField.classList.remove('error-in-custom-combobox');
            if(selectedSortFields.includes(currentSortField) && currentSortField!=this.sorts[index].field){
                this.sorts[index].field = null;
                this.showToast('error', 'Oops! Duplicate detected!', 'You can only sort by a field once..', 5000);
            }else{
                this.sorts[index].field = currentSortField;
                if(this.sorts[index].order == ''){
                    this.sorts[index].order = 'ASC';
                    ascBtn.classList.add('selected-sort-order');
                    descBtn.classList.remove('selected-sort-order');
                }else if(this.sorts[index].order == 'ASC'){
                    ascBtn.classList.add('selected-sort-order');
                    descBtn.classList.remove('selected-sort-order');
                }else if(this.sorts[index].order == 'DESC'){
                    descBtn.classList.add('selected-sort-order');
                    ascBtn.classList.remove('selected-sort-order');
                }
                this.template.querySelectorAll('.sort-index-div')[index].classList.remove('error-in-row');
            }
            this.isEditTabChanged = true;
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleSortFieldChange', e, 'warn');
        }
    }

// -=-=- To make clicked sort Ascending -=-=-
    handleAscending(event){
        try{
            const index = event.target.dataset.index;
            if(this.sorts[index].field){
                this.sorts[index].order = 'ASC';
                this.template.querySelectorAll('.asc-btn')[index].classList.add('selected-sort-order');
                this.template.querySelectorAll('.desc-btn')[index].classList.remove('selected-sort-order');
                this.isEditTabChanged = true;
            }else{
                this.template.querySelectorAll('.sort-field-select')[index].classList.add('error-in-custom-combobox');
            }
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleAscending', e, 'warn');
        }

    }

// -=-=- To make clicked sort Descending -=-=-
    handleDescending(event){
        try{
            const index = event.target.dataset.index;
            if(this.sorts[index].field){
                this.sorts[index].order = 'DESC';
                this.template.querySelectorAll('.desc-btn')[index].classList.add('selected-sort-order');
                this.template.querySelectorAll('.asc-btn')[index].classList.remove('selected-sort-order');
                this.isEditTabChanged = true;
            }else{
                this.template.querySelectorAll('.sort-field-select')[index].classList.add('error-in-custom-combobox');
            }
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleDescending', e, 'warn');
        }
    }

// -=-=- Update the Operators based on the Selected Fields -=-=-
    handleFieldNameChange(event) {
        try {
            const index = event.target.dataset.index;
            this.filters[index].fieldName = event.detail[0] || null;
            this.filters[index].value = '';
            if (event.detail[0]){
                this.filters[index].type = this.fieldsForFilters.find(field => field.value == this.filters[index].fieldName).type;
                this.validateCurrentFilter(index);
                this.updateOperatorOptions(index);                
            }else{
                this.filters[index].type = '';
                this.filters[index].operators = '';
            }
            this.template.querySelectorAll('.filter-field-select')[index].classList.toggle('error-in-custom-combobox', !event.detail[0]);
            this.initialFilters = true;
            this.isUpdateOnlyLastFilter = true;
            this.filtersCount = this.filters.length;
            this.isEditTabChanged = true;
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleFieldNameChange', e, 'warn');
        }
    }

// -=-=- to validate the Filter on-the-go real-time -=-=-
    validateCurrentFilter(i){
        try {
            let filter = this.filters[i];
            const filterIndexDiv = this.template.querySelectorAll('.filter-index-div')[i];
            if(((filter.fieldName && filter.operator && filter.value) || this.filters.length==1)){
                filterIndexDiv.classList.remove('error-in-row');
            }else if(filter.value?.trim() == "NULL" && filter.operator && !["=", "!="].includes(filter.operator)){
                filter.operator = null;
                filter.value = null;
                this.showToast('error', 'Oops! It\'s a Wrong move!', 'Please Select "Equal To"/"Not Equal to" operator to check NULL.', 5000);
            }
        }catch(e) {
            errorDebugger('editCSVTemplate', 'validateCurrentFilter', e, 'warn');
        }
    }

// -=-=- to handle Operator field selection -=-=-
    handleOperatorChange(event){
        try{
            const index = event.target.dataset.index;
            this.filters[index].operator = event.detail[0];
            this.validateCurrentFilter(index);
            this.template.querySelectorAll('.operator-select')[index].classList.toggle('error-in-custom-combobox', !this.filters[index].operator);;
            this.isEditTabChanged = true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleOperatorChange', e, 'warn');
        }
    }

// -=-=- to handle Value change -=-=-
    handleValueChange(event){
        try{
            const index = event.target.dataset.index;
            this.filters[index].value = event.target.value?.trim();
            this.validateCurrentFilter(index);
            this.template.querySelectorAll('.value-select-div')[index].classList.toggle('error-in-value-input', !this.filters[index].value);
            this.isEditTabChanged = true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleValueChange', e, 'warn');
        }
    }

    handleSimpleInputFocus(event){
        try {
            const index = event.target.dataset.index;
            let filter = this.filters[index];
            if(filter.operator != "=" && filter.operator != "!=" && !['DATETIME', 'DATE'].includes(filter.type.toUpperCase())){
                return;
            }
            if(['ownerid', 'createdbyid', 'lastmodifiedbyid'].includes(filter.fieldName.toLowerCase())){
                this.preDefinedValues = ['CURRENT_USER'];
            }else if(filter.type !== 'DATETIME' && filter.type !== 'DATE'){
                this.preDefinedValues = ['NULL'];
            }else{
                this.preDefinedValues = [...this.allPreDefinedValues];
            }
            event.currentTarget.nextElementSibling.classList.remove('dont-display-div');
            const backDrop = this.template.querySelector('.backDropPredefined');
            if(backDrop) backDrop.style.display = 'block';
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleSimpleInputFocus', e, 'warn');
        }
    }

    handleSimpleInputBlur(){
        try {
            this.template.querySelectorAll('.select-predefined-option').forEach((element)=>{
                element.classList.add('dont-display-div');
            })
            const backDrop = this.template.querySelector('.backDropPredefined');
            if(backDrop) backDrop.style.display = 'none';
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleSimpleInputBlur', e, 'warn');
        }
    }

    handlePreDefinedClick(event){
        try{
            const index = event.target.dataset.index;
            this.filters[index].inputType = 'text';
            this.filters[index].value = event.currentTarget.innerText.trim();
            this.template.querySelectorAll('.select-predefined-option').forEach((element)=>{
            element.classList.add('dont-display-div');
            })
            this.template.querySelectorAll('.value-select-div')[index].classList.toggle('error-in-value-input', !this.filters[index].value);
            const backDrop = this.template.querySelector('.backDropPredefined');
            if(backDrop){
                backDrop.style.display = 'none';
            }
            this.validateCurrentFilter(index);
        }catch(e){
            errorDebugger('editCSVTemplate', 'handlePreDefinedClick', e, 'warn');
        }
    }

    handleValueFromComboBox(event){
        try{
            const index = event.target.dataset.index;
            if(event.detail.length <1){
                this.filters[index].value= null;
            }else if(event.detail.length ==1){
                this.filters[index].value= event.detail[0];
            }else{
                this.filters[index].value = event.detail;
            }
            this.template.querySelectorAll('.value-select-div')[index].classList.toggle('error-in-value-input', !this.filters[index].value);
            this.validateCurrentFilter(index);
            this.isEditTabChanged = true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleValueFromComboBox', e, 'warn');
        }
    }

//-=-=- To Update the operators that can be used for a selected field -=-=-
    updateOperatorOptions(index) {
        this.showSpinner = true;
        try {
            const filter = this.filters[index];
            const fieldType = filter.type?.toLowerCase();
            filter.operators = this.allOperatorOptions.filter(option => option.type.includes(fieldType));

            if (filter.operators.length === 0 && filter.fieldName) filter.operators = this.allOperatorOptions.filter(option => option.type.includes('default'));
            if (!['picklist', 'multipicklist', 'boolean'].includes(fieldType)) {
                const isValueValid = !this.allPreDefinedValues.includes(filter.value.trim());

                if (['number', 'percent', 'double', 'integer', 'currency'].includes(fieldType) && isValueValid) {
                    filter.inputType = 'number';
                } else if (fieldType === 'date' && !filter.value.includes('_') && isValueValid) {
                    filter.inputType = 'date';
                } else if (fieldType === 'datetime' && !filter.value.includes('_') && isValueValid) {
                    filter.inputType = 'datetime';
                } else if (fieldType === 'time' && isValueValid) {
                    filter.inputType = 'time';
                } else if (fieldType === 'email' && isValueValid) {
                    filter.inputType = 'email';
                } else {
                    filter.inputType = 'text';
                }
            } else {
                if (['picklist', 'multipicklist'].includes(fieldType)) {
                    filter.inputType = this.allRetrievedFields.find(item => item.apiName === filter.fieldName)?.picklistValues.map(option => ({
                        label: option,
                        value: option
                    })) || [];
                } else if (fieldType === 'boolean') {
                    filter.inputType = [
                        { label: 'TRUE', value: 'true' },
                        { label: 'FALSE', value: 'false' }
                    ];
                }
            }
        } catch (e) {
            errorDebugger('editCSVTemplate', 'updateOperatorOptions', e, 'warn');
        } finally {
            this.showSpinner = false;
        }
    }

// -=-=- To Update the ASC and DESC for the Existing Sorts -=-=-
    updateSelectedSort(index){
        try{
            this.showSpinner = true;
            const ascBtn = this.template.querySelectorAll('.asc-btn')[index];
            const descBtn = this.template.querySelectorAll('.desc-btn')[index];
            if(this.sorts[index].order == 'ASC'){
                ascBtn.classList.add('selected-sort-order');
                descBtn.classList.remove('selected-sort-order');
            }else if(this.sorts[index].order == 'DESC'){
                descBtn.classList.add('selected-sort-order');
                ascBtn.classList.remove('selected-sort-order');
            }
            this.showSpinner = false;
        }catch(e){
            errorDebugger('editCSVTemplate', 'updateSelectedSort', e, 'warn');
        }
    }
    
// -=-=- To select the logic operator and show or hide the custom logic div if Custom logic is selected -=-=-
    handleLogicUpdate(event){
        try{
            this.selectedLogic = event.detail[0] || null;
            if(event.detail[0]){
                this.selectedLogic == 'Custom' ? this.isCustomLogic = true : this.isCustomLogic = false;
                this.customLogicString = '';
            }
            this.template.querySelector('.logic-select').classList.toggle('error-in-custom-combobox', !event.detail[0]);
            this.isEditTabChanged = true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleLogicUpdate', e, 'warn');
        }
    }

    handleCustomLogicUpdate(event){
        try{
            this.customLogicString = event.target.value.toUpperCase();
            this.isCustomLogicValid = this.validateOnEachCharacter();
            if(this.isCustomLogicValid){
                this.template.querySelector('.logic-string-input').classList.toggle('error-in-input', !this.customLogicString.trim());
            }
            this.isEditTabChanged = true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleCustomLogicUpdate', e, 'warn');
        }
    }

    validateOnEachCharacter(){
        try{
            if(!this.customLogicString) return false;
            const checkCharactersRegex = /^[ANDOR\d()\s]*$/i;
            const regex = /\d+/g;
            const logicStringInput = this.template.querySelector('.logic-string-input');
            const errorString =  this.template.querySelector('.error-text');
            if(!checkCharactersRegex.test(this.customLogicString)){
                logicStringInput?.classList.add('error-in-input');
                if(errorString) errorString.innerText = 'Oops!, invalid characters found!';
                return false;
            }
            const numbers = this.customLogicString.match(regex);
            if(numbers){
                for (let i = 0; i < numbers.length; i++) {
                    const num = numbers[i];
                    if (num > this.filters.length || num < 1) {
                        logicStringInput?.classList.add('error-in-input');
                        if(errorString) errorString.innerText ='Um, Filter-'+ num + ' does not exist!';
                        return false;
                    }
                }
            }
            logicStringInput?.classList.remove('error-in-input');
            if(errorString) errorString.innerText = '';
            return true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'validateOnEachCharacter', e, 'warn');
        }
        return false;
    }

    validateCustomLogic(){
        try{
            this.isCustomLogicValid = this.validateOnEachCharacter();
            const logicStringInput = this.template.querySelector('.logic-string-input');
            const errorString =  this.template.querySelector('.error-text');
            logicStringInput?.classList.remove('error-in-input');
            if(!this.customLogicString){
                if(errorString) errorString.innerText = 'Seems so empty!!';
                logicStringInput?.classList.add('error-in-input');
                this.showErrorMessage('Please Enter a Custom Logic Formula.');
                this.isCustomLogicValid = false;
                return;
            }
            const regex = /\d+/g;
            const numbers = this.customLogicString.match(regex);
            if(numbers){
                for (let i=0; i<numbers.length ; i++) {
                    let num = numbers[i];
                    if (num > this.filters.length  || num <1) {
                        this.isCustomLogicValid = false;
                        this.showErrorMessage('Um, Filter-'+ num + ' does not exist!');
                        return;
                    }else if(!this.filters[num-1].fieldName){
                        this.isCustomLogicValid = false;
                        this.showErrorMessage('Um, Filter-'+ num + ' is seems to be empty!!');
                        return;
                    }
                }
            }
            let logicString = this.customLogicString.replaceAll('AND', '&').replaceAll('OR', '|').replaceAll(/\d+/g, 'N').split(' ').join('').trim();
            let isValidBrackets = false;
            const validatorAfterConversion =  /^[&|N()]*$/i;
            let count = 0;
            let newString = logicString.split('');
            for (let i = 0; i < logicString.length; i++) {
                let char = logicString[i];
                if (char === '(') {
                    count++;
                    newString[i] = count;
                } else if (char === ')') {
                    newString[i] = count;
                    if(newString.includes(count)){
                        let startIndex = newString.indexOf(count);
                        newString[startIndex] = 't';
                        newString[i] = 't';
                        if(startIndex>0 && i< newString.length && (newString[startIndex-1]== '&' || newString[startIndex-1]=='|') && (newString[i+1]== '&' || newString[i+1]=='|') ){
                            if(!(newString[startIndex-1] == newString[i+1])){
                                isValidBrackets = false;
                                break;
                            }
                        }
                    }
                    count--;
                    if (count < 0) {
                        isValidBrackets = false;
                        break;
                    }
                }
            }
            count === 0 ? isValidBrackets=true : isValidBrackets = false;

            if(validatorAfterConversion.test(logicString)){
                if(!isValidBrackets){
                    this.showErrorMessage('There are unmatched brackets in the logic..');
                    this.isCustomLogicValid = false;
                    logicStringInput?.classList.add('error-in-input');
                    return;
                }else if(logicString.length == 2){
                    this.isCustomLogicValid = false;
                    this.showErrorMessage('Try these patterns : "1 OR 2"');
                    return;
                }else if(logicString.length == 1 && logicString == 'N'){
                    null;
                }else if(logicString.length == 3){
                    if(!((logicString[0]== '(' && logicString[1]=='N' && logicString[2]==')') || (logicString[0]== 'N' && (logicString[1]=='&' || logicString[1]=='|')  && logicString[2]=='N'))){
                        this.isCustomLogicValid = false;
                        this.showErrorMessage('Try this patterns: "(1)" or "1 AND/OR 2".');
                        return;
                    }
                }else if(!((logicString[0] == '(' || logicString[0] == 'N') && (logicString[logicString.length-1] == ')' || logicString[logicString.length-1] == 'N'))){
                    this.isCustomLogicValid = false;
                    logicStringInput?.classList.add('error-in-input');
                    this.showErrorMessage('You can Start and end logic only with number or brackets.');
                    return;
                }else{
                    if(logicString.length > 3){
                        for(let i=0; i<logicString.length-1; i++){
                            if(logicString[i] == '('){
                                if(logicString[i+1] == '('){
                                    null;
                                }else if(logicString[i+1] == 'N'){
                                    if(!(logicString[i+2] == '&' || logicString[i+2] == '|')){
                                        this.isCustomLogicValid = false;
                                        this.showErrorMessage('There should be operator after the Number.');
                                        return;
                                    }
                                }else{
                                    this.isCustomLogicValid = false;
                                    this.showErrorMessage('Please add a number or another "(" after a "(".')
                                    return;
                                }
                                
                            }else if(logicString[i] == 'N'){
                                if(!(logicString[i+1] == ')' || logicString[i+1] == '&' || logicString[i+1] == '|')){
                                    this.isCustomLogicValid = false;
                                    this.showErrorMessage('There should be an Operator or a ")" after a number.');
                                    return;
                                }
                                
                            }else if(logicString[i] == '&'){
                                if(logicString[i+1] == '('){
                                    null;
                                }else if(logicString[i+1] == 'N' ){
                                    if(!(logicString.length == i+2 || (logicString[i+2] == '&' || logicString[i+2] == ')'))){
                                        this.isCustomLogicValid = false;
                                        this.showErrorMessage('Try these patterns : "1 AND 2 AND 3" or "1 AND (2 OR 3)".');
                                        return;
                                    }
                                }else{
                                    this.isCustomLogicValid = false;
                                    this.showErrorMessage('There should be an number or a "(" after an operator.');
                                    return;
                                }
                                
                            }else if(logicString[i] == '|'){
                                if(logicString[i+1] == '('){
                                    null;
                                }else if(logicString[i+1] == 'N'){
                                    if(!(logicString.length == i+2 || logicString[i+2] == '|' || logicString[i+2] == ')')){
                                        this.isCustomLogicValid = false;
                                        this.showErrorMessage('Try these patterns : "1 AND 2 AND 3" or "1 OR (2 AND 3)".');
                                        return;
                                    }
                                }else{
                                    this.isCustomLogicValid = false;
                                    this.showErrorMessage('There should be a number or a "(" after an operator.');
                                    return;
                                }
                                
                            }else if(logicString[i]== ')'){
                                if(!(logicString[i+1] == ')' || logicString[i+1] == '&' || logicString[i+1] == '|')){
                                    this.isCustomLogicValid = false;
                                    this.showErrorMessage('There should be an operator or another ")" after an ")".');
                                    return;
                                }   
                            }
                        }
                    }
                }
            }else{
                if(errorString) errorString.innerText = 'Oops! Please check spelling of \'AND\' and \'OR\'';
                this.showErrorMessage('It seems to be spelling mistake of "AND" and "OR".');
                this.isCustomLogicValid = false;
                return;
            }
            logicStringInput?.classList.remove('error-in-input');
            if(this.isCustomLogicValid){
                if(errorString) errorString.innerText = '';
            }else{
                logicStringInput?.classList.add('error-in-input');
                this.showToast('error', 'Please enter valid Logic!', 'there was an error in the custom logic!', 5000);
            }
        }catch(e){
            errorDebugger('editCSVTemplate', 'validateCustomLogic', e, 'warn');
        }
    }

    showErrorMessage(msg){
        try{
            this.isCustomLogicValid = false;
            const logicStringInput = this.template.querySelector('.logic-string-input');
            logicStringInput.classList.remove('error-in-input');
            logicStringInput.classList.add('error-in-input');
            const errorString =  this.template.querySelector('.error-text');
            errorString.innerText = msg;
            this.showSpinner = false;
        }catch(e){
            errorDebugger('editCSVTemplate', 'showErrorMessage', e, 'warn');
        }
    }

    handleLimitUpdate(event){
        try{
            this.limit = event.target.value;
            const limitInput = this.template.querySelector('.input-limit');
            let maxLimit = this.isChild ? this.childMaxLimit : 1000000;
            limitInput.classList.toggle('error-in-input', this.limit < 1 || this.limit > maxLimit);
            this.isEditTabChanged = true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleLimitUpdate', e, 'warn');
        }
    }

    handleLimitInputBlur(){
        try {
            this.limit = Math.ceil(this.limit);
            const limitInput = this.template.querySelector('.input-limit');
            let maxLimit = this.isChild ? this.childMaxLimit : 1000000;
            limitInput.classList.remove('slds-has-error');
            limitInput.classList.toggle('error-in-input', this.limit < 1 || this.limit > maxLimit);
        } catch (e) {
            errorDebugger('editCSVTemplate', 'handleLimitInputBlur', e, 'warn');
        }
    }

    handleLimitToggleChange(event){
        try{
            this.showLimitInput = event.target.checked;
            let maxLimit = this.isChild ? this.childMaxLimit : 1000000;
            let shownLimit = this.isChild ? this.childMaxLimit : 50000;
            this.limit = this.showLimitInput ? shownLimit : maxLimit;
            this.isEditTabChanged = true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleLimitToggleChange', e, 'warn');
        }
    }
    generateFilterString() {
        try{
            // <|SDG|> - Sort field and order separator
            // <|FDG|> - Filter separator
            // <|LDG|> - Logic values separator
            // <|IDG|> - Inner filter values separator
            this.separatedData.fields = this.selectedFields.map(field => {return field.apiName}).join(',');

            if (this.sorts.length > 0) {
                this.separatedData.orders =  this.sorts.filter(sort => sort.field && sort.order).map((sort) => {
                    return [sort.field, sort.order].join('<|IDG|>'); // Join sort values with separator
                }).join('<|SDG|>'); // Join individual Sorts with separator
            }

            if (this.filters.length > 0) {
                this.separatedData.filters =  this.filters.filter((filter) => filter.fieldName && filter.operator && filter.value && filter.type).map((filter) => {
                    if (Array.isArray(filter.value)) filter.value = filter.value.join('<|CS|>');
                    const filterParts = [filter.fieldName, filter.operator, filter.value, filter.type];
                    filter.value.includes('<|CS|>') ? filter.value= filter.value.split('<|CS|>') : undefined;
                    return filterParts.join('<|IDG|>'); // Join filter values with separator
                }).join('<|FDG|>'); // Join individual filters with separator
            }

            if(this.selectedLogic){
                if (this.isCustomLogic && this.customLogicString.trim()) {
                    this.separatedData.logic = this.selectedLogic + '<|LDG|>' + this.customLogicString.trim();
                }else{
                    this.separatedData.logic = this.selectedLogic;
                }
            }
    
            this.separatedData.maxLimit = this.limit;
            this.separatedData.listView = this.selectedListView;
        }catch(e){
            errorDebugger('editCSVTemplate', 'generateFilterString', e, 'warn');
        }

    }

    parseFilterString(){
        try{
            if (this.separatedData) {
                if (this.separatedData.fields) {
                    let preSelectedApiNames = this.separatedData.fields.split(',');
                    let seenApiNames = {};
                    for (let i = 0; i < preSelectedApiNames?.length; i++) {
                        seenApiNames[preSelectedApiNames[i].trim()] = i;
                    }
                    this.selectedFields = this.allRetrievedFields.filter(field =>
                        Object.prototype.hasOwnProperty.call(seenApiNames, field.apiName)
                    ).sort((field1, field2) => seenApiNames[field1.apiName] - seenApiNames[field2.apiName]);
                    this.existingFields = [...this.selectedFields];
                }

                const oldSorts = this.separatedData.orders?.split('<|SDG|>')?.map((sortPart) => {
                    if(sortPart?.length >0){
                        const sortValues = sortPart.split('<|IDG|>');
                        return {
                        field: sortValues[0],
                        order: sortValues[1]
                        };
                    }
                    return null;
                })
                .filter((sort) => sort != null);

                const oldFilters = this.separatedData.filters?.split('<|FDG|>')?.map((filterPart) => {
                    if(filterPart?.length >0){
                        const filterValues = filterPart.split('<|IDG|>');
                        filterValues[2].includes('<|CS|>') ? filterValues[2] = filterValues[2].split('<|CS|>') : undefined;
                        return {
                        fieldName: filterValues[0],
                        operator: filterValues[1],
                        value: filterValues[2],
                        type: filterValues[3],
                        inputType: filterValues[4],
                        operators: []
                        };
                    }
                    return null;
                })
                .filter((filter) => filter !== null);

                if(this.separatedData.logic){
                    if (this.separatedData.logic?.includes('<|LDG|>')) {
                        this.selectedLogic = this.separatedData.logic.split('<|LDG|>')[0];
                        this.customLogicString = this.separatedData.logic.split('<|LDG|>')[1];
                        this.isCustomLogic = true;
                    }else{
                        this.selectedLogic = this.separatedData.logic;
                    }
                }

                for(let i =0; i<oldFilters?.length; i++) {
                    const fieldType = oldFilters[i].type.toLowerCase();
                    oldFilters[i].operators = this.allOperatorOptions.filter(option => option.type.includes(fieldType));
    
                    if(oldFilters[i].operators?.length<=0 && oldFilters[i].fieldName){
                        oldFilters[i].operators = this.allOperatorOptions.filter(option => option.type.includes('default'));
                    }
                }

                if(this.separatedData.maxLimit){
                    if(this.separatedData.maxLimit == 1000000){
                        this.showLimitInput = false;
                    }else{
                        this.limit = this.separatedData.maxLimit;
                        this.showLimitInput = true;
                    }
                }

                if(this.separatedData.listView){
                    this.selectedListView = this.separatedData.listView;
                }

                this.filters = oldFilters;
                if(oldSorts?.length >0){
                    this.sorts = oldSorts;
                }

                if(!this.sorts || this.sorts?.length == 0 ){
                    this.addSort();
                }

                if(!this.filters || this.filters?.length == 0){
                    this.addFilter();
                }

                this.filtersCount = this.filters?.length;
                this.sortsCount = this.sorts?.length;

                this.existingFilters = this.filters ? JSON.parse(JSON.stringify(this.filters)) : undefined;
                this.existingSorts = this.sorts ? JSON.parse(JSON.stringify(this.sorts)) : undefined;
                this.existingLogic = this.selectedLogic;
                this.existingCustomLogicString = this.customLogicString;
                this.existingShowLimitInput = this.showLimitInput;
                this.existingLimit = this.limit;
            }
            this.showSpinner = false;
        }catch(e){
            errorDebugger('editCSVTemplate', 'parseFilterString', e, 'warn');
        }
    }

    generateQuery(){
        try{
            this.generatedQuery = 'SELECT ';
            let selectedApiNames = this.selectedFields.map(field => field.apiName) || ['Id'];
            this.generatedQuery += selectedApiNames.join(', ');
            this.generatedQuery+= ' FROM '+ this.objectName ;
            const conditions = [];
            this.filters.forEach(filter => {
                typeof filter.value === 'object' ? filter.value = filter.value?.join('<|CS|>') : undefined;
                if (filter.fieldName && filter.operator && filter.value && filter.type) {
                    let condition = '';
                    if (filter.type.toUpperCase() == 'MULTIPICKLIST'){
                        if(["=","!="].includes(filter.operator)){
                            let newValue = filter.value.split('<|CS|>').map(item => item.trim());
                            newValue = newValue?.join(";");
                            condition =  filter.fieldName + ' ' + filter.operator + ' \'' + newValue + '\' ';
                        }else if(filter.operator == 'IN'){
                            let newValue = filter.value.split('<|CS|>').map(item => item.trim());
                            newValue = "'" + newValue?.join("','") + "'";
                            condition =  filter.fieldName +' INCLUDES (' + newValue + ') ';
                        }else if(filter.operator == 'notIN'){
                            let newValue = filter.value.split('<|CS|>').map(item => item.trim());
                            newValue = "'" + newValue?.join("','") + "'";
                            condition =  filter.fieldName +' EXCLUDES (' + newValue + ') ';
                        }
                    }else if (filter.operator == 'LIKE') {
                        condition =  filter.fieldName + ' LIKE \'%' + filter.value + '%\' ';
                    }else if (filter.operator == 'startLIKE') {
                        condition =  filter.fieldName + ' LIKE \'' + filter.value + '%\' ';
                    }else if (filter.operator == 'endLIKE') {
                        condition =  filter.fieldName + ' LIKE \'%' + filter.value + '\' ';
                    }else if (filter.operator == 'notLIKE') {
                        condition =  '( NOT ' + filter.fieldName + ' LIKE \'%' + filter.value + '%\' )';
                    }else if(filter.type.toUpperCase() == 'DOUBLE' || filter.type.toUpperCase() == 'INTEGER' || filter.type.toUpperCase() == 'NUMBER' || filter.type.toUpperCase() == 'PERCENT' || filter.type.toUpperCase() == 'CURRENCY' || filter.type.toUpperCase() == 'DATE' || filter.type.toUpperCase() == 'BOOLEAN' || filter.type.toUpperCase() == 'DATETIME' || filter.type.toUpperCase() == 'TIME' || this.allPreDefinedValues.includes(filter.value.toUpperCase())){
                        condition = filter.fieldName + ' ' + filter.operator + ' ' + filter.value + ' ';
                    }else if(filter.value.toUpperCase() === 'CURRENT_USER'){
                        condition = filter.fieldName + ' ' + filter.operator + ' \'' + filter.value.toUpperCase() + '\'  ';
                    }else if(filter.operator == 'IN'){
                        let newValue = filter.type.toUpperCase() == 'PICKLIST' ? filter.value.split('<|CS|>').map(item => item.trim()) : filter.value.split(',').map(item => item.trim());
                        newValue = "'" + newValue?.join("','") + "'";
                        condition =  filter.fieldName +' IN (' + newValue + ') ';
                    }else if(filter.operator == 'notIN'){
                        let newValue = filter.type.toUpperCase() == 'PICKLIST' ? filter.value.split('<|CS|>').map(item => item.trim()) : filter.value.split(',').map(item => item.trim());
                        newValue = "'" + newValue?.join("','") + "'";
                        condition =  filter.fieldName +' NOT IN (' + newValue + ') ';
                    }else{
                        condition =  filter.fieldName + ' ' + filter.operator + ' \'' + filter.value + '\' ';
                    }
                    conditions.push(condition);
    
                }
                filter.value.includes('<|CS|>') ? filter.value= filter.value.split('<|CS|>') : undefined;
            });
            if(this.isCustomLogic===false && conditions.length >0){
                this.generatedQuery += ' WHERE ' + conditions?.join(' '+ this.selectedLogic +' ');
            }else if(conditions.length >0){
                const regex = /\d+/g;
                this.generatedQuery += ' WHERE ' +this.customLogicString.replace(regex, match => {
                    // We are doing -1 because we are showing them from 1 and index starts from 0 for the same filter
                    return ' '+conditions[parseInt(match)-1] + ' ';
                });
            }
    
            let orderBy = this.sorts.filter(sort => sort.field && sort.order).map(sort => { return (sort.field +' '+ sort.order) });
            if(orderBy.length >0){
                this.generatedQuery += ' ORDER BY '+  orderBy?.join(', ');
            }
    
            if(this.limit) this.generatedQuery += ' LIMIT '+ this.limit;

            if(this.generatedQuery?.length > 16000){
                this.showToast('error', 'Something went wrong!', 'Generated Query is too long, please remove filter or order by.', 5000);
                return false;
            }
        }catch(e){
            errorDebugger('editCSVTemplate', 'generateQuery', e, 'warn');
        }
    }

    validateData(isPreview){
        try{
            let invalidData = {
                type: '',
                message: '',
                description: '',
                duration: 5000
            };
            let foundError = false;
            if(this.selectedFields.length <=0){
                if(!foundError){
                    invalidData = {type: 'error', message: 'Oops! You missed to select Fields!', description:'Please Select at least one field!', duration:5000};
                    foundError = true;
                }
            }
    
            if(this.sorts){
                const sortIndexDiv = this.template.querySelectorAll('.sort-index-div');
                const sortFieldSelects = this.template.querySelectorAll('.sort-field-select');
                for (let i = 0; i < this.sorts.length; i++) {
                    sortIndexDiv[i]?.classList.remove('error-in-row');
                    sortFieldSelects[i]?.classList.remove('error-in-custom-combobox');
                    if (this.sorts.length > 1 && !this.sorts[i].field) {
                        sortFieldSelects[i]?.classList.add('error-in-custom-combobox');
                        sortIndexDiv[i]?.classList.add('error-in-row');
                        this.showSpinner = false;
                        if(!foundError){
                            invalidData = {type: 'error', message: 'Oops! You missed to fill data!', description:'Please fill the valid data to sort records..', duration:5000};
                            foundError = true;
                        }
                    }
                }
            }
    
            if(!this.selectedLogic){
                if(!foundError){
                    invalidData = {type: 'error', message: 'Oops! You missed to select Logic!', description:'Please select a logic you want to apply!', duration:5000};
                    foundError = true;
                }
            }
    
            if(this.isCustomLogic){
                const logicStringInput = this.template.querySelector('.logic-string-input');
                logicStringInput?.classList.remove('error-in-input');
                if(!this.customLogicString.trim()){
                    if(!foundError){
                        invalidData = {type: 'error', message: 'Oops! You missed to fill data!', description:'Please enter a valid Custom Logic!', duration:5000};
                        foundError = true;
                    }
                    logicStringInput?.classList.add('error-in-input');
                }
                if(!this.isCustomLogicValid){
                    logicStringInput?.classList.add('error-in-input');
                    if(!foundError){
                        invalidData = {type: 'error', message: 'Oops! Custom logic is invalid!', description:'Please Validate the Custom Logic!!', duration:5000};
                        foundError = true;
                    }
                }
            }
            if(this.showLimitInput){
                const limitInput = this.template.querySelector('.input-limit');
                limitInput?.classList.remove('error-in-input');
                let maxLimit = this.isChild ? this.childMaxLimit : 1000000;
                if(this.limit <1 || this.limit > maxLimit){
                    if(!foundError){
                        let maxLImit = this.isChild ? this.childMaxLimit : 1000000;
                        invalidData = {type: 'error', message: 'Oops! You entered wrong limit!', description:'Please enter a limit between 0 and '+maxLImit, duration:5000};
                        foundError = true;
                    }
                    limitInput?.classList.add('error-in-input');
                }
            }
            if (this.filters) {
                const filterIndexDiv = this.template.querySelectorAll('.filter-index-div');
                const filterFieldSelects = this.template.querySelectorAll('.filter-field-select');
                const operatorSelects = this.template.querySelectorAll('.operator-select');
                const valueSelectDivs = this.template.querySelectorAll('.value-select-div');
                for (let i = 0; i < this.filters.length; i++) {
                    filterIndexDiv[i]?.classList.remove('error-in-row');
                    let filter = this.filters[i];
                    if(this.filters.length == 1 && !filter.fieldName) continue;
                    if ((!filter.fieldName || !filter.operator || !filter.value)) {
                        if (this.filters.length !== 0) {
                            filterFieldSelects[i]?.classList.remove('error-in-custom-combobox');
                            operatorSelects[i]?.classList.remove('error-in-custom-combobox');
                            valueSelectDivs[i]?.classList.remove('error-in-custom-combobox');
                            if (!filter.fieldName) {
                                filterFieldSelects[i]?.classList.add('error-in-custom-combobox');
                            } else if (!filter.operator) {
                                operatorSelects[i]?.classList.add('error-in-custom-combobox');
                            } else if (!filter.value) {
                                valueSelectDivs[i]?.classList.add('error-in-value-input');
                            }
                        }
                        this.showSpinner = false;
                        filterIndexDiv[i]?.classList.add('error-in-row');
                        if (!foundError) {
                            invalidData = {type: 'error', message: 'Oops! You missed to fill data!', description: 'Please fill the valid data to filter records..', duration: 5000};
                            foundError = true;
                        }
                    } else if (filter.fieldName && filter.operator && (((filter.type.toUpperCase() === 'REFERENCE' || filter.type.toUpperCase() === 'ID') && filter.value.toUpperCase()!=='NULL' && !['ownerid', 'createdbyid', 'lastmodifiedbyid'].includes(filter.fieldName.toLowerCase())) || (['ownerid', 'createdbyid', 'lastmodifiedbyid'].includes(filter.fieldName.toLowerCase()) && filter.value.toUpperCase() !== 'CURRENT_USER'))) {
                        if (!(filter.value.length === 15 || filter.value.length === 18)){
                            filterIndexDiv[i]?.classList.add('error-in-row');
                            valueSelectDivs[i]?.classList.add('error-in-value-input');
                            if (!foundError) {
                                invalidData = {type: 'error', message: 'Oops! You Filled Incorrect data!', description: 'Please correct the id in the record ID fields..', duration: 5000};
                                foundError = true;
                            }
                        }
                    }
                }
            }
            if(this.generatedQuery.length > 1000000){
                if(!foundError){
                    invalidData = {type: 'error', message: 'Oops! It\'s Our fault!', description:'Try removing some of the filters..', duration:5000};
                    foundError = true;
                }
            }
    
            if(!foundError){
                let fields = this.selectedFields.map(field => {return field.apiName}).join(',');
                if(this.isChild){
                    this.showSpinner = false;
                    if (!import.meta.env.SSR) this.dispatchEvent(new CustomEvent('save', {detail : {selectedFields: this.selectedFields , query: this.generatedQuery, generatedData : {fields : fields, filters :this.separatedData }}}));
                }
                else{
                    this.saveTemplate(isPreview);
                }
            }else{
                this.showToast(invalidData.type, invalidData.message, invalidData.description, invalidData.duration);
                this.showSpinner = false;
            }
        }catch(e){
            this.showSpinner = false;
            this.showToast('error','Something went wrong!', 'We Couldn\'t save template, please try again.', 5000)
            errorDebugger('editCSVTemplate', 'validateData', e, 'warn');
        }
    }

    saveTemplate(isPreview){
        try {
            saveTemplateFields({configData : {templateId: this.templateId , query: this.generatedQuery ,...this.separatedData}})
            .then((result)=>{
                if(result === 'success'){
                    this.existingFields = JSON.parse(JSON.stringify(this.selectedFields));
                    this.existingFilters = JSON.parse(JSON.stringify(this.filters));
                    this.existingSorts = JSON.parse(JSON.stringify(this.sorts));
                    this.existingLogic = this.selectedLogic;
                    this.existingShowLimitInput = this.showLimitInput;
                    this.existingLimit = this.limit;
                    this.existingCustomLogicString = this.customLogicString;
                    this.isEditTabChanged = false;
                    if(isPreview){
                        this.showSpinner = false;
                        this.showPreview = true;
                    }else{
                        this.showToast('success', 'Action Performed!', 'The template fields were saved successfully', 5000);
                    }
                }else{
                    errorDebugger('editCSVTemplate', 'saveTemplate > saveTemplateFields > failure', result, 'warn');
                    const eMessage = this.selectedFields ? 'Something went wrong, Please try again!!' : 'Please Select at least one field!';
                    this.showToast('error', 'Oops! Something went wrong', eMessage, 5000);
                }
            })
            .catch(e=> {
                errorDebugger('editCSVTemplate', 'saveTemplate > saveTemplateFields', e, 'warn');
                const eMessage = this.selectedFields ? 'Something went wrong, Please try again!!' : 'Please Select at least one field!';
                this.showToast('error', 'Oops! Something went wrong', eMessage, 5000);
            });
        } catch (e) {
            errorDebugger('editCSVTemplate', 'saveTemplate', e, 'warn');
        }
    }

    handleSave(event){
        try{
            let isPreview = event?.target.dataset.type === 'preview';
            this.showSpinner = true;
            this.generateFilterString();
            if(this.generateQuery() === false) return;
            if(this.isCustomLogic){
                this.validateCustomLogic();
            }
            this.validateData(isPreview);
        }catch(e){
            this.showSpinner = false;
            errorDebugger('editCSVTemplate', 'handleSave', e, 'warn');
        }
    }
    
    handleClose(){
        try {
            if(this.isChild){
                if (!import.meta.env.SSR) this.dispatchEvent(new CustomEvent('close'));
            }else if(this.isEditTabChanged || this.isBasicTabChanged){
                this.isClose = true;
                this.showWarningPopup('warning', 'Are you sure, you want to close?', 'Your unsaved changes will be discarded once you leave the this page.');
            }else{
                this.navigateToComp(navigationComps.home);
            }
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleClose', e, 'warn');
        }
    }

    closePreview(){
        this.showPreview = false;
    }

    handleConfirmation(event){
        try {
            if(event.detail){
                if(this.isClose){
                    this.navigateToComp(navigationComps.home);
                }else if(this.isListViewUpdate){
                    this.isListViewUpdated = true;
                }else if(this.isCancelTemplate){
                    this.handleCancelChanges();
                }else if(this.isReset){
                    this.handleResetSection();
                }else if(this.isClear){
                    this.handleClearSection();
                }
            }else{
                if(this.isListViewUpdate){
                    this.selectedListView = this.tempListView;
                }
            }
            this.isClose = false;
            this.isListViewUpdate = false;
            this.isCancelTemplate = false;
            this.isReset = false;
            this.isClear = false;
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleConfirmation', e, 'warn');
        }
    }

    handleClear(event){
        try{
            this.clearSection = event.target.dataset.name; 
            this.isClear = true;
            this.showWarningPopup('warning', 'Clear '+ this.clearSection + ' Section!', 'Are you sure you want to Clear '+ this.clearSection + '?');
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleClear', e, 'warn');
        }
    }

    handleReset(event){
        try{
            this.resetSection = event.target.dataset.name; 
            this.isReset = true;
            this.showWarningPopup('warning', 'Reset '+ this.resetSection + ' Section!', 'Are you sure you want to reset '+ this.resetSection + '?');            
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleReset', e, 'warn');
        }

    }

    handleClearSection(){
        try{
            if(this.clearSection === "fields"){
                this.toRemoveSelected = [];
                this.toRemoveSelected.push(...this.selectedFields);
                this.handleLeft();
            }else if(this.clearSection === "filters"){
                this.filters = [];
                this.addFilter();
                this.removeFilter();
                this.customLogicString = '';
                this.isCustomLogic = false;
                this.selectedLogic = 'AND';
                this.template.querySelector('.logic-select').classList.remove('error-in-custom-combobox');
                this.template.querySelectorAll('.filter-field-select').forEach( ele => {
                    ele.classList.remove('error-in-custom-combobox');
                });
            }else if(this.clearSection === "orders"){
                this.sorts = [];
                this.addSort();
                this.removeSort();
                this.template.querySelectorAll('.asc-btn')[0].classList.remove('selected-sort-order');
                this.template.querySelectorAll('.desc-btn')[0].classList.remove('selected-sort-order');
                this.template.querySelectorAll('.sort-field-select').forEach( ele => {
                    ele.classList.remove('error-in-custom-combobox');
                });
                this.template.querySelector('.sort-index-div').classList.remove('error-in-row');
            }else if(this.clearSection === "limit"){
                this.showLimitInput = false;
                this.limit = this.isChild ? this.childMaxLimit : 1000000;
            }
            this.clearSection = '';
            this.isEditTabChanged = true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleClearSection', e, 'warn');
        }
    }

    handleResetSection(){
        try{
            if(this.resetSection === "fields"){
                this.toRemoveSelected.push(...this.selectedFields);
                this.handleLeft();
                this.toRemoveSelected = [];
                this.selectedFields = JSON.parse(JSON.stringify(this.existingFields));
            }else if(this.resetSection === "filters"){
                this.filters = JSON.parse(JSON.stringify(this.existingFilters));
                const filterFieldSelects = this.template.querySelectorAll('.filter-field-select');
                const operatorSelects = this.template.querySelectorAll('.operator-select');
                const valueSelectDivs = this.template.querySelectorAll('.value-select-div');
                for(let i = 0; i < this.filters.length ; i++){
                    this.updateOperatorOptions(i);
                    filterFieldSelects[i]?.classList.toggle('error-in-custom-combobox', !this.filters[i].fieldName);
                    operatorSelects[i]?.classList.toggle('error-in-custom-combobox', this.filters[i].fieldName && !this.filters[i].operator);
                    valueSelectDivs[i]?.classList.toggle('error-in-value-input', this.filters[i].fieldName && this.filters[i].operator && !this.filters[i].value);
                }
                this.filtersCount = this.filters.length;
                this.initialFilters = true;
                this.selectedLogic = this.existingLogic;
                this.isCustomLogic = this.selectedLogic=='Custom' ? true : false;
                this.customLogicString = this.existingCustomLogicString;
                this.isCustomLogicValid = this.validateOnEachCharacter();
                this.template.querySelector('.logic-select')?.classList.remove('error-in-custom-combobox');
            }else if(this.resetSection === "orders"){
                this.sorts = JSON.parse(JSON.stringify(this.existingSorts));
                this.sortsCount = this.sorts.length;
                this.initialSorts = true;
            }else if(this.resetSection === "limit"){
                this.limit = this.existingLimit;
                this.showLimitInput = this.existingShowLimitInput;
            }
            this.resetSection = '';
            this.isEditTabChanged = true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleResetSection', e, 'warn');
        }
    }

    handleCustom(){
        this.showListViewPopup = false;
    }

    //Basic Details Tab

    handleChangeStatus(event){
        this.newTemplateData.MVDG__Template_Status__c = event.target.checked;
        this.isBasicTabChanged = true;
    }
    handleTemplateNameChange(event){
        try{
            this.newTemplateData.MVDG__Template_Name__c = event.target.value.trim();
            this.isBasicTabChanged = true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleTemplateNameChange', e, 'warn');
        }
    }
        
    handleDescriptionChange(event){
        this.newTemplateData.MVDG__Description__c = event.target.value;
        this.isBasicTabChanged = true;
    }

    handleListViewChange(event){
        try{
            if(!this.showBasicDetailTab && !this.isBasicTabChanged){
                this.selectedListView = event.currentTarget.dataset.value;
                this.newTemplateData.MVDG__List_View__c = this.selectedListView;
                this.existingTemplateData.MVDG__List_View__c = this.selectedListView;
                this.isListViewUpdated = true;
                this.handleListView();
                return;
            }
            this.tempListView = this.selectedListView;
            this.selectedListView = event.detail[0];
            if(!this.selectedListView){
                this.isListViewUpdated = true;
            }else if(this.selectedListView && this.tempListView!==this.selectedListView && ((this.filters?.length > 0 && this.filters[0].fieldName) || (this.sorts?.length > 0 && this.sorts[0].field) ||(this.selectedFields?.length > 0))){
                this.showWarningPopup('warning', 'Are you sure to change list view?', 'Changing the list view may override the current changes when you click \'Update\' button.');
                this.isListViewUpdate = true;
            }
            this.isBasicTabChanged = true;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleListViewChange', e, 'warn');
        }
    }

    handleListViewSearch(event){
        this.listViewSearchKey = event.target.value;
    }

    handleDetailsCancel(){
        try {
            if (this.isBasicTabChanged){
                this.showWarningPopup('warning', 'Cancel Template Changes!', 'Are you sure you want to cancel the changes?');
                this.isCancelTemplate = true;
                return;
            }
            this.handleCancelChanges();
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleDetailsCancel', e, 'warn');
        }
    }

    handleDetailsSave(){
        try {
            if(!this.newTemplateData.MVDG__Template_Name__c.trim()){
                this.showToast('error', 'Oops! Missed to fill the data!', 'Please enter the valid name for the template.',5000);
                return;
            }
            if (this.isBasicTabChanged){
                this.handleUpdateTemplate();
            }
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleDetailsSave', e, 'warn');
        }
    }

    handleCancelChanges(){
        try{
            this.newTemplateData.MVDG__Template_Name__c = this.existingTemplateData.MVDG__Template_Name__c ;
            this.newTemplateData.MVDG__Template_Status__c =this.existingTemplateData.MVDG__Template_Status__c;
            this.newTemplateData.MVDG__Description__c = this.existingTemplateData.MVDG__Description__c;
            this.selectedListView = this.existingTemplateData.MVDG__List_View__c;
            this.isListViewUpdated = false;
            this.initialFilters = true;
            this.filtersCount = this.filters.length;
            this.isBasicTabChanged = false;
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleCancelChanges', e, 'warn');
        }
    }

    handleUpdateTemplate(){
        try {
            if (this.isBasicTabChanged){
                this.showSpinner = true;
                let templateData = {
                    templateId : this.newTemplateData.Id,
                    templateName : this.newTemplateData.MVDG__Template_Name__c,
                    templateDescription : this.newTemplateData.MVDG__Description__c,
                    templateStatus : this.newTemplateData.MVDG__Template_Status__c,
                    listView : this.selectedListView
                }
                updateTemplate({templateInfo : templateData})
                .then((result) => {
                    if(result === 'success'){
                        this.existingTemplateData.MVDG__Template_Name__c = this.newTemplateData.MVDG__Template_Name__c;
                        this.existingTemplateData.MVDG__Template_Status__c = this.newTemplateData.MVDG__Template_Status__c;
                        this.existingTemplateData.MVDG__Description__c = this.newTemplateData.MVDG__Description__c;
                        this.existingTemplateData.MVDG__List_View__c = this.selectedListView;
                        this.isBasicTabChanged = false;
                    }else{
                        errorDebugger('editCSVTemplate', 'handleUpdateTemplate > updateTemplate > failure', result, 'warn');
                        this.showToast('error', 'Oops! Couldn\'t save changes!' , 'Please try updating the data again...', 5000);
                    }
                })
                .catch((e)=>{
                    errorDebugger('editCSVTemplate', 'handleUpdateTemplate > updateTemplate', e, 'warn');
                    this.showToast('error', 'Oops! Couldn\'t save changes!' , 'Please try updating the data again...', 5000);
                })
                .finally(()=>{
                    if(!this.selectedListView || !this.isListViewUpdated){
                        this.showSpinner = false;
                        this.showToast('success', 'Action Performed!', 'The Template Details are updated successfully!', 5000);
                        this.isBasicTabChanged = false;
                    }
                })
            }
            if(this.selectedListView){
                this.handleListView();
                this.isBasicTabChanged = false;
            }
        }catch(e) {
            errorDebugger('editCSVTemplate', 'handleUpdateTemplate', e, 'warn');
        }
    }
    
    getAllConditions(conditions) {
        let allConditions = [];
        try{
            this.selectedLogic = 'AND';
            conditions.forEach(condition =>{
                const currentCondition = {
                    fieldName: condition.field || "",
                    operator: "",
                    value: "",
                    type: "",
                    inputType: "",
                    operators: [],
                };
                if (Object.prototype.hasOwnProperty.call(condition, "conditions")) {
                    allConditions = allConditions.concat(this.getAllConditions(condition.conditions));
                } else {
                    let value = condition.values[0];
                    let operator  = this.operatorMap.get(condition.operator);
                    if((value.startsWith("'") && value.endsWith("'")) || (value.startsWith('"') && value.endsWith('"'))) { 
                        value =  value.slice(1, -1);
                    }
                    if(operator=='LIKE' || operator=='notLIKE'){
                        if(value.startsWith('%') && value.endsWith('%')){
                            value =  value.slice(1, -1);
                        }else if(operator=='LIKE' && value.endsWith('%')){
                            operator = 'startLIKE';
                            value = value.slice(0, -1);
                        }else if(operator=='LIKE' && value.startsWith('%')){
                            operator = 'endLIKE';
                            value = value.slice(1,);
                        }
                    }
                    currentCondition.operator = operator,
                    currentCondition.value = value,
                    currentCondition.type = this.fieldOptions.filter(option => option.apiName == condition.field)[0]?.fieldType
                    allConditions.push(currentCondition);
                }
            })
        }catch(e){
            errorDebugger('editCSVTemplate', 'getAllConditions', e, 'warn');
        }
        return allConditions;
    }
    
    handleListView(){
        try{
            if(!this.isListViewUpdated){
                return;
            }
            if(!this.selectedListView){
                this.showToast('error', 'Oops! No list view selected.', 'Please select a list view to proceed with a list view.', 5000);
            }else{
                //method calls 
                this.showSpinner = true;
                this.showListViewPopup=false;
                getSessionId()
                .then((sessionId) => {
                    if(!sessionId){
                        this.showToast('error', 'Oops, Something went wrong!.', 'There was a technical issue, please try again.');
                        return;
                    }
                    let queryURL = '/services/data/v58.0/sobjects/'+this.objectName+'/listviews/'+this.selectedListView+'/describe';
                    const myHeaders = new Headers();
                    let bearerString = "Bearer " + sessionId;
                    myHeaders.append("Authorization", bearerString);
            
                    const requestOptions = {
                    method: "GET",
                    headers: myHeaders,
                    redirect: "follow"
                    };
                    let domainURL;
                    if (!import.meta.env.SSR) {
                        domainURL = location?.origin;
                    }
                    if(!domainURL){
                        this.showToast('error', 'Something went wrong!', 'Some error occurred!, please try again.', 5000);
                    }
                    domainURL = domainURL.replace('lightning.force.com', 'my.salesforce.com');
            
                    fetch(encodeURI(domainURL + queryURL), requestOptions)
                    .then(response => {
                        if (!response.ok) {
                            this.showToast('error', 'Oops! Something went wrong!', 'There was an error connecting to the server, please try again.', 5000);
                            return Promise.reject('Network response was not ok');
                        }
                        return response.json();
                    })
                    .then(result => {
                        let fetchedColumns = result.columns;
                        let fetchedFilters = result.whereCondition;
                        let fetchedQuery = result.query;
                        let fetchedOrderBy = result.orderBy;
                        this.customLogicString = fetchedQuery.slice(fetchedQuery.indexOf('WHERE')+5 , fetchedQuery.indexOf('ORDER')).replaceAll("'", '').replaceAll('%','');
        
                        this.selectedFields = [];
                        this.fieldOptions = [...this.allRetrievedFields];
                        fetchedColumns.forEach((column) => {
                            if(!column.hidden){
                                const selectedApiName = column.fieldNameOrPath;
                                this.selectedFields.push({ fieldName: this.fieldOptions.filter(option => option.apiName == selectedApiName)[0]?.fieldName, apiName: selectedApiName });
                            }
                        });

                        this.existingFields = JSON.parse(JSON.stringify(this.selectedFields));
                        this.showSpinner = false;
        
                        if (!Array.isArray(fetchedFilters)) {
                            fetchedFilters = [fetchedFilters];
                        }
                        this.filters = this.getAllConditions(fetchedFilters);
                        let filterStrings = [];
                        let repeatedIndices = [];
                        for(let i=0;i<this.filters.length;i++){
                            let filterString = '';
                            if(this.filters[i].operator.toLowerCase().includes('not')){
                                let afterString = this.filters[i].operator.toLowerCase().slice(3,);
                                filterString = '(NOT '+ this.filters[i].fieldName+ ' ' + afterString+ ' ' +this.filters[i].value + ')';                            
                            }else if(this.filters[i].operator.toLowerCase().includes('like')){
                                filterString = this.filters[i].fieldName+ ' like ' +this.filters[i].value;
                            }else{
                                filterString = this.filters[i].fieldName+ ' ' + this.filters[i].operator+ ' ' +this.filters[i].value;
                            }
                            !filterStrings.includes(filterString) ? filterStrings.push(filterString) : repeatedIndices.push(i);
                            this.customLogicString  = this.customLogicString.replace(filterString, +filterStrings.indexOf(filterString)+1);
                        }
                        if(result.scope == 'mine'){
                            this.filters.push({
                                fieldName : 'OwnerId',
                                operator : '=',
                                value : 'CURRENT_USER',
                                type : 'REFERENCE',
                                inputType : 'text'
                            });
                            this.customLogicString = (this.filters.length - (repeatedIndices?.length||0)) + ' AND ( ' + this.customLogicString + ' )';
                        }
                        
                        if(this.customLogicString){
                            this.customLogicString = this.customLogicString.replaceAll('AND' , ' AND ').replaceAll('OR' , ' OR ');
                            if(!this.customLogicString.includes('AND')){
                                this.isCustomLogic = false;
                                this.selectedLogic = 'OR';
                            }else if(!this.customLogicString.includes('OR')){
                                this.isCustomLogic = false;
                                this.selectedLogic = 'AND';
                            }else{
                                this.selectedLogic = 'Custom';
                                this.isCustomLogic = true;
                            }
                        }
                        this.existingLogic = this.selectedLogic;
                        this.existingCustomLogicString = this.customLogicString;
        
                        repeatedIndices.sort((a, b) => b - a).forEach(index => {
                            this.filters.splice(index, 1);
                        });

                        this.filtersCount = this.filters.length;
                        this.initialFilters = true;
        
                        this.sorts = fetchedOrderBy.map(order => ({
                            field: order.fieldNameOrPath,
                            order: order.sortDirection == 'ascending' ? 'ASC' : 'DESC',
                        }));
        
                        this.sortsCount = this.sorts.length;
                        this.initialSorts = true;

                        this.filtersCount == 0 ? this.addFilter() : undefined;
                        this.sortsCount == 0 ? this.addSort() : undefined;

                        this.existingFilters = JSON.parse(JSON.stringify(this.filters));
                        this.existingSorts = JSON.parse(JSON.stringify(this.sorts));

                        this.showLimitInput = false;
                        this.limit = 1000000;
                        this.existingShowLimitInput = false;
                        this.existingLimit = 1000000;
        
                        this.setSelectionFields();
                        //To Save Template just after proceeding with list view
                        this.handleSave();
                    })
                    .catch(e => {
                        this.showToast('error', 'Something went wrong!', e.message == "Failed to fetch"? 'We Couldn\'t connect to server, make sure you have a trusted url...': 'We couldn\'t fetch the list view data, please try again..', 5000);
                        errorDebugger('editCSVTemplate', 'handleListView > fetch', e, 'warn');
                    })
                })
                .catch(e => {
                    this.showToast('error', 'Oops, a technical issue!', 'We couldn\'t fetch the list view data, please try again..');
                    errorDebugger('editCSVTemplate', 'handleListView > getSessionId', e, 'warn');
                })
            }
        }catch(e){
            errorDebugger('editCSVTemplate', 'handleListView', e, 'warn');
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

    showWarningPopup(status, title, message){
        this.showSpinner = false;
        const messageContainer = this.template.querySelector('c-message-popup')
        messageContainer.showMessagePopup({
            status: status,
            title: title,
            message : message,
        });
    }

// -=-=- Used to navigate to the other NavigationComps -=-=-
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
        }catch(e) {
            errorDebugger('editCSVTemplate', 'navigateToComp', e, 'warn');
        }
    }
}