import { LightningElement, track , api} from 'lwc';
import getTemplateDetails from '@salesforce/apex/EditCSVTemplateController.getTemplateDetails';
import getFieldMappingKeys from '@salesforce/apex/KeyMappingController.getFieldMappingKeys';
import saveTemplateFields from '@salesforce/apex/EditCSVTemplateController.saveTemplateFields';
import getTemplateFieldsData from '@salesforce/apex/EditCSVTemplateController.getTemplateFieldsData';
import validateRelatedObject from '@salesforce/apex/EditCSVTemplateController.validateRelatedObject';
import getListViews from '@salesforce/apex/EditCSVTemplateController.getListViews';
import getSessionId from '@salesforce/apex/GenerateDocumentController.getSessionId';
import updateTemplate from '@salesforce/apex/EditCSVTemplateController.updateTemplate';
import {NavigationMixin} from 'lightning/navigation';
import {navigationComps, nameSpace} from 'c/globalProperties';


export default class EditCSVTemplate extends NavigationMixin(LightningElement) {

    // -=-=- the values we got from the Home page/new template popup -=-=-
    @api objectName;
    @api templateId;
    @api isNew;

    //-=-=- to Show/hide the Spinner -=-=-
    @track showSpinner;

    @track showBasicDetailTab = false;
    @track showEditTemplateTab = true;
    @track showDefaultsTab = false;

    //to handle the confirmation message
    @track isListViewUpdate = false;
    @track isClose = false;
    @track isTemplateUpdate = false;
    @track isCancelTemplate = false;
    @track isReset = false;
    @track isClear = false;


    //-=-=- To run a function only once, when we want in rendered callback -=-=-
    initialRender = true;
    initialFilters = true;
    initialSorts = true;

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

    get loadFlexDivStyle(){
        return this.isChild ? 'height : 100% !important' : '';
    }

    get selectFieldLabel(){
        return this.isChild ? 'Select Fields to Add in Table' : 'Column Selection';
    }

    get filterLabel(){
        return this.isChild ? 'Apply Filter on Record\'s Field' : 'Apply Filter';
    }

    get orderByLabel(){
        return this.isChild ? 'Select Ordering of Records' : 'Order By';
    }

    get limitLabel(){
        return this.isChild ? 'Set Maximum Number of Row(Record) to Add in Table' : 'Limit';
    }

    get saveBtnLabel(){
        return this.isChild ? 'Generate Table' : 'Save'
    }
    // ===== ===== ===== ===== ===== CHANGES TO USED AS CHILD OBJECT SELECTION -- END ---- ==== ===== =====

    //-=-=- Filter/Sort/Logic Selection -=-=-
    separatedData = '';
    generatedQuery = '';
    filtersCount = 0;
    sortsCount = 0;
    @track limit = 1000000;   
    @track childMaxLimit = 50;
    @track fieldsForFilters = [];
    @track allOperatorOptions = [
        //String
        { label: 'Equals to', value: '=', type: 'default, string,textarea, id, number, phone, date, datetime, email, currency, boolean, multipicklist' },
        { label: 'Not Equals to', value: '!=', type: 'default, string,textarea, id, number, phone, date, datetime, email, currency, boolean, multipicklist' },
        { label: 'Contains', value: 'LIKE', type: 'string, textarea, email, picklist' },
        { label: 'Does not contain', value: 'notLIKE', type: 'string, textarea, email, picklist' },
        { label: 'Starts with', value: 'startLIKE', type: 'string, textarea, phone, picklist' },
        { label: 'Ends with', value: 'endLIKE', type: 'string, textarea, email, phone, picklist' },
        { label: 'Include', value: 'IN', type: 'multipicklist, picklist, string' },
        { label: 'Exclude', value: 'notIN', type: 'multipicklist, picklist, string' },
        { label: 'Greater Than', value: '>', type: 'number, currency, picklist, string, date, datetime' },
        { label: 'Less Than', value: '<', type: 'number, currency, picklist, string, date, datetime' },
        { label: 'Greater or equal', value: '>=', type: 'number, currency, picklist, string, date, datetime' },
        { label: 'Less or equal	', value: '<=', type: 'number, currency, picklist, string, date, datetime' },
        // { label: 'Before', value: '<', type: 'date, datetime' },
        // { label: 'After', value: '>', type: 'date, datetime' },
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
        
        this.fieldOptions = this.fieldOptions.slice().sort((a, b) => a.apiName.localeCompare(b.apiName));  
        let optionsNotSelected = this.fieldOptions.filter(option =>
            !this.selectedFields.some(p => p.apiName === option.apiName)
        );

        let alreadySelectedRemainingOptions;
        let fieldOptionsUpdated;

        
        if (!this.searchKey) {
            return optionsNotSelected;
        }
        fieldOptionsUpdated =  optionsNotSelected.filter(option => option.apiName.toLowerCase().includes(this.searchKey.toLowerCase()));
        alreadySelectedRemainingOptions = this.toAddSelected.filter(option =>
            !fieldOptionsUpdated.some(p => p.apiName === option.apiName)
        );

        // Combine the prioritized fields and the remaining fields
        let updatedFieldOptions = [...fieldOptionsUpdated, ...alreadySelectedRemainingOptions]
        return fieldOptionsUpdated.length ===0 ? optionsNotSelected : updatedFieldOptions ;
    }

//-=-=- Specially to show Index from 1, instead of 0 for the Sorts -=-=-
    get adjustedSorts() {
        return this.sorts?.map((sort, index) => {
            return {...sort, displayIndex: index + 1};
        });
    }

    get adjustedFilters() {
        return this.filters?.map((filter, index) => {

            // console.log('This filter is :::' , index);
            this.template.querySelectorAll('.operator-select')[index]?.classList.add('dont-display-div');
            this.template.querySelectorAll('.value-select-div')[index]?.classList.add('dont-display-div');
            if(this.filters.length==1 && !filter.fieldName){
                this.template.querySelectorAll('.filter-field-select')[index]?.classList.remove('error-in-custom-combobox');
            }
            if(filter.fieldName){
                this.template.querySelectorAll('.operator-select')[index]?.classList.remove('dont-display-div');
                this.template.querySelectorAll('.operator-select')[index]?.classList.remove('error-in-custom-combobox');
                // console.log('There is Field Name');
            }else{
                filter.operator = '';
                filter.value = '';
                this.template.querySelectorAll('.operator-select')[index]?.classList.add('dont-display-div');
                this.template.querySelectorAll('.value-select-div')[index]?.classList.add('dont-display-div');
                // console.log('No field Selected');
            }
            if(filter.operator){
                this.template.querySelectorAll('.value-select-div')[index]?.classList.remove('dont-display-div')
                // console.log('There is Operator');
            }else{
                filter.value = '';
                this.template.querySelectorAll('.value-select-div')[index]?.classList.add('dont-display-div');
                // console.log('There is no operator');
            }
            return {...filter, displayIndex: index + 1, isPicklist: ['PICKLIST' , 'MULTIPICKLIST' , 'BOOLEAN'].includes(filter.type) , isMultiple: filter.operator == 'IN' || filter.operator == 'notIN' || filter.type =='MULTIPICKLIST'};
        });
    }

    get selectedAvailableFields(){
        return this.toAddSelected.length ? this.toAddSelected.length : this.toRemoveSelected.length;
    }
    
    promises = [];
    _resolvedPromise = 0;
    get resolvedPromise(){ return this._resolvedPromise;}
    set resolvedPromise(value){
        let totalProcess = this.isChild ? 1 : 4;
        (value == totalProcess) && (this.showSpinner = false);
        this._resolvedPromise = value;
    }

    connectedCallback() {
        try {
            this.showSpinner = true;

            this.limit = this.isChild ? this.childMaxLimit : 1000000;
            this.existingLimit = this.limit;

            !this.isChild && this.fetchTemplateDetails();
            !this.isChild && this.fetchListViews();
            this.fetchFields();
            !this.isChild && this.fetchTemplateFieldsData();
        } catch (e) {
            console.error('Error in connectedCallback:', e.stack);
        }
    }
    testLoading(){
        console.log('Content loaded !!!');
    }
    fetchTemplateDetails(){
        try {
            getTemplateDetails({ templateId: this.templateId })
            .then((data) => {
                this.existingTemplateData = JSON.parse(JSON.stringify(data));
                this.newTemplateData = JSON.parse(JSON.stringify(this.existingTemplateData));
                this.resolvedPromise++;
                console.log('Template Details ::', this.newTemplateData);
            })
            .catch(e => {
                this.resolvedPromise++;
                console.log('Error in getTemplateDetails ::', e.message);
            })
        } catch (error) {
            this.resolvedPromise++;
            this.handleError('Error fetching details from template:', error.stack);
        }
    }
    
    fetchListViews() {
        try {
            getListViews({ objName: this.objectName })
            .then(data => {
                this.allListViews = data.map(listView => ({ label: listView.Name, value: listView.Id }));
                this.showListViewPopup = this.isNew && this.allListViews.length>0 ?  true : false;
                this.resolvedPromise++;
                console.log('All the List Views Are::', this.allListViews);
            })
            .catch(e => {
                this.resolvedPromise++;
                console.log('Error in getListViews ::', e.message);
            })
        } catch (err) {
            this.resolvedPromise++;
            this.handleError('Error fetching list views:', err);
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
                        obj.fieldMappings = obj.fieldMappings.map(({ isFormatReq, label, name, type, key, ...rest }) => {
                            const thisField ={
                                ...rest,
                                fieldType: type,
                                apiName: name,
                                fieldName: obj.label.includes('>') ? obj.label.split(' > ')[1] + ' > ' + label : label
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
                    console.log('All Related Objects Are ::', this.relatedObjects);
                    console.log('All Fields Are ::', this.allRetrievedFields);
                    
                }
                else{
                    this.resolvedPromise++;
                    this.showToast('Error', 'Error While Fetching Field Mapping Data', result.returnMessage);
                }
            })
            .catch(error => {
                this.resolvedPromise++;
                console.log('error in getTemplateData apex callout : ', {error});
            })
        } catch (error) {
            this.resolvedPromise++;
            console.log('error in templateBuilder > getFieldMappingKeys ', error.stack);
        }
    }

    setSelectionFields(){
        try {
            this.fieldOptions = this.fieldMappingsWithObj.find(ele =>  ele.name == this.selectedRelatedObject).fieldMappings ;
        } catch (error) {
            console.log('error in templateBuilder.setSelectionFields : ', error.stack)
        }
    }

    setFilterFields(){
        try{
            this.fieldsForFilters = this.allRetrievedFields
                .filter(option => option.isSearchable)
                .map(option => ({ label: option.fieldName, value: option.apiName, type: option.fieldType }));
        }catch(e){
            console.log('Error in setFilterFields');
        }
    }
    
    fetchTemplateFieldsData() {
        try {
            getTemplateFieldsData({ templateId: this.templateId })
            .then(data => {
                if (data) {
                    this.separatedData = data;
                    this.parseFilterString();
                }
                this.resolvedPromise++;
                console.log('Template Fields Data::', this.separatedData);
                
            })
            .catch(e => {
                this.resolvedPromise++;
                console.log('Error in getTemplateFieldsData ::', e.message);
            })
        } catch (err) {
            this.resolvedPromise++;
            this.handleError('Error fetching template field data values:', err);
        }
    }
    
    handleError(message, error) {
        this.showSpinner = false;
        console.error(message, error);
        this.showToast('error', 'Oops! Something went wrong', message, 5000);
    }

// -=-=- To override the style of the standard Input fields and the comboboxes -=-=-
// -=-=- To Process the existing fields and sorts -=-=-
    renderedCallback(){
        try {
            if(this.initialRender){
                // To OverRider standard slds css properties...
                let mainFilterDiv = this.template.querySelector('.main-div');
                let styleEle = document.createElement('style');
                styleEle.innerText = `
                            .main-div .slds-input{
                                height: 2.5rem;
                                border-radius: 0.5rem;
                                border: 0.0625rem solid var(--slds-c-input-color-border);
                                box-shadow: none;
                            } 
                            .main-div .slds-textarea{
                                height: 3.5rem;
                                border-radius: 0.5rem 0.5rem 0 0.5rem;
                                border: 0.0625rem solid var(--slds-c-input-color-border);
                                box-shadow: none;
                            } 
                            .main-div .fix-slds-input_faux{
                                height: 2.5rem;
                                border-radius: 0.5rem;
                                border: 0.0625rem solid var(--slds-c-input-color-border);
                            }
                            .main-div.slds-input:focus{
                                border-color: #00aeff;
                                box-shadow: none;
                            } 
                            .main-div .slds-combobox__input:focus{
                                border-color: #00aeff;
                                box-shadow: none;
                            }
                            .main-div .fix-slds-input_faux{
                                display: flex;
                                align-items: center;
                            }
                            .main-div .slds-form-element__label:empty {
                                margin: 0;
                                padding: 0;
                            }

                            .slds-form-element__help {
                                display: none;
                            }

                            .simple-input-div .slds-input__icon.slds-input__icon_right {
                                pointer-events: all;
                                z-index: 12;
                            }

                            .simple-input-div .slds-button:hover, .simple-input-div .slds-button:focus{
                                color: #00aeff;
                            }

                            .simple-input-div .slds-icon-text-default:hover, .simple-input-div .slds-icon-text-default:focus {
                                --slds-c-icon-color-foreground: #00aeff;
                                cursor: pointer;
                            }
                `;
                if(mainFilterDiv){
                    mainFilterDiv.appendChild(styleEle);
                    this.initialRender = false;
                }
    
            }
            if(this.initialFilters){
                if (this.template.querySelector('.filter-div') && this.filtersCount==this.filters?.length) { // Check if all filters are rendered
                    // console.log('rendered filters' + this.filters.length );
                    if(this.filtersCount>0){
                        this.showSpinner = true;
                        for(let i =0; i<this.filters?.length; i++) {
                            this.updateOperatorOptions(i);
                        }
                        this.initialFilters = false;
                        this.showSpinner = false;
                    }else{
                        this.initialFilters = false;
                    }
                }
            }
            if(this.initialSorts){
                if (this.template.querySelector('.sort-div') && this.sortsCount==this.sorts?.length) { // Check if all sorts are rendered
                    // console.log('rendered sorts' + this.sorts.length );
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
        } catch (error) {
            console.log('Error in Rendered Callback ::' , error.stack);
        }

    }


    activeTab(event){
         try {
             let activeTabName = event.currentTarget.dataset.name;
             if(activeTabName === 'editTab'){
                this.showSpinner = true;
                this.showBasicDetailTab = false;
                this.showEditTemplateTab = true;
                this.showDefaultsTab = false;
                this.initialFilters = true;
                this.filtersCount = this.filters?.length;
            }else if(activeTabName === 'basicTab'){
                this.showBasicDetailTab = true;
                this.showEditTemplateTab = false;
                this.showDefaultsTab = false;
            }else if(activeTabName === 'defaultsTab'){
                this.showDefaultsTab = true;
                this.showBasicDetailTab = false;
                this.showEditTemplateTab = false;
            }
            this.setActiveTab(activeTabName);
        } catch (error) {
            console.log('error in activating the tab : ', error.stack);
        }
    }

    setActiveTab(activeTabName){
        try{
            // console.log('activeTabName : ', activeTabName);
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
            console.log('Error in Setting Active tab :: ', e.stack);
        }
    }

    handleRelatedObjectChange(event){
        try {
            this.selectedRelatedObject = event.detail[0];
            this.toAddSelected = [];
            // console.log('The Selected Object is :' , this.selectedRelatedObject);
            this.setSelectionFields();
        } catch (error) {
            console.log('Error in handleRelatedObjectChange ::: ' , error.stack);
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
            // console.log('toAddSelected : ', this.toAddSelected[0].apiName);
            }
        } catch (error) {
            console.error('An error occurred:', error.stack);
        }
    }

// -=-=- To add the selected fields from the Selected section of the Field Selection -=-=-
    handleSelectedClick(event){
        try{
            this.toAddSelected = [];
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
            // console.log('toRemoveSelected : ', this.toRemoveSelected[0].apiName);
            }
        } catch (error) {
            console.error('An error occurred:', error.message);
        }
    }

// -=-=- To Move selected fields Up by one index -=-=-
    handleUp(){
        try{
            this.reorderList();
            for(let i = 0;i<this.toRemoveSelected.length;i++){
                let index;
                for(let j = 0;j<this.selectedFields.length;j++){
                    if (this.selectedFields[j].apiName == this.toRemoveSelected[i].apiName){
                        index = j;
                        break;
                    }
                }
                if(index<=0){
                    break;
                }
                this.selectedFields = this.swapElements(this.selectedFields,index,index-1);
            }
            this.isEditTabChanged = true;
        } catch (error) {
            console.error('An error occurred:', error.message);
        }
    }

// -=-=- To move the selected fields down by one index-=-=-
    handleDown(){
        try{
            this.reorderList();
            for(let i = this.toRemoveSelected.length-1;i>=0;i--){
                let index;
                for(let j = 0;j<this.selectedFields.length;j++){
                    if (this.selectedFields[j].apiName == this.toRemoveSelected[i].apiName){
                        index = j;
                        break;
                    }
                }
                if(index>=this.selectedFields.length-1){
                    break;
                }
                this.selectedFields = this.swapElements(this.selectedFields,index,index+1);
            }
            this.isEditTabChanged = true;
        } catch (error) {
            console.error('An error occurred:', error.message);
        }
    }

    handleTop(){
        try{
            this.reorderList();
            for(let i = this.toRemoveSelected.length-1;i>=0;i--){
                let index;
                for(let j = 0;j<this.selectedFields.length;j++){
                    if (this.selectedFields[j].apiName == this.toRemoveSelected[i].apiName){
                        index = j;
                        break;
                    }
                }
                // console.log('Index ::' , index);
                this.selectedFields.splice(index, 1);
                this.selectedFields.unshift(this.toRemoveSelected[i]);
            }
        this.isEditTabChanged = true;
        } catch (error) {
            console.error('An error occurred:', error.message);
        }
    }

    handleBottom(){
        try {
            this.reorderList();
            for(let i = 0; i < this.toRemoveSelected.length; i++) {
                let index;
                for(let j = 0; j < this.selectedFields.length; j++) {
                    if (this.selectedFields[j].apiName == this.toRemoveSelected[i].apiName) {
                        index = j;
                        break;
                    }
                }
                this.selectedFields.splice(index, 1);
                this.selectedFields.push(this.toRemoveSelected[i]); 
            }
        this.isEditTabChanged = true;
        } catch (error) {
            console.error('An error occurred:', error.message);
        }
    }

// -=-=- It works as the Helper function for the handleUp and handleDown Processes -=-=-
    reorderList(){
        try{
            // console.log('ToRemoveSelected :: ' , this.toRemoveSelected);
            let reorderedElements = this.selectedFields.map(field => this.toRemoveSelected.find(el => el.apiName === field.apiName));
            this.toRemoveSelected = [];
            for (let i = 0; i < reorderedElements.length; i++) {
                const element = reorderedElements[i];
                if(element){
                    this.toRemoveSelected.push(element);
                }
            }
            // console.log('ToRemoveSelected :: ' + this.toRemoveSelected);

        } catch (error) {
            console.error('An error occurred:', error.message);
        }
    }

// -=-=- It works as the Helper function for the handleUp and handleDown Processes to swap fields as index passed -=-=-
    swapElements(arr, index1, index2) {
        try{
            const updatedArray = [...arr];
            const temp = updatedArray[index1];
            updatedArray[index1] = updatedArray[index2];
            updatedArray[index2] = temp;
        
            return updatedArray;
        } catch (error) {
            console.error('An error occurred:', error.message);
            return null;
        }
    }

// -=-=- To move the Selected fields form the Selected section to the Available Section and remove from the Selected section -=-=-
    handleLeft(){
        try{
            for(let i=0;i<this.toRemoveSelected.length;i++){
                this.selectedFields = this.selectedFields.filter((field) => {
                    return field.apiName != this.toRemoveSelected[i].apiName;
                });
                this.fieldOptions.push(this.toRemoveSelected[i]);

                let uniqueMap = new Map();
                this.fieldOptions.forEach(item => uniqueMap.set(item.apiName, item));
                this.fieldOptions = Array.from(uniqueMap.values());
            }
            this.toRemoveSelected = [];
            this.isEditTabChanged = true;
        } catch (error) {
            console.error('An error occurred:', {error});
        }
    }

// -=-=- To move the Selected fields form the Available section to the Selected Section and remove from the Available section -=-=-
    handleRight(){
        try{
            for(let i=0;i<this.toAddSelected.length;i++){
                this.fieldOptions = this.fieldOptions.filter((field) => {
                    return field.apiName != this.toAddSelected[i].apiName;
                });
                this.selectedFields.push(this.toAddSelected[i]);
            }
            this.toAddSelected = [];
            this.isEditTabChanged = true;
        } catch (error) {
            console.error('An error occurred:', error.message);
        }
    }

// -=-=- To add One empty filter object to the filters list -=-=-
    addFilter() {
        try{
            if(this.filters && this.filters?.length != 0){
                let index = this.filters.length-1;
                let filter = this.filters[index];
                this.template.querySelectorAll('.filter-field-select')[index].classList.remove('error-in-custom-combobox');
                this.template.querySelectorAll('.operator-select')[index].classList.remove('error-in-custom-combobox');
                this.template.querySelectorAll('.value-select-div')[index].classList.remove('error-in-custom-combobox');
                if(!filter.fieldName){
                    this.template.querySelectorAll('.filter-field-select')[index].classList.add('error-in-custom-combobox');
                    return;
                }else if(!filter.operator){
                    this.template.querySelectorAll('.operator-select')[index].classList.add('error-in-custom-combobox');
                    return;
                }else if(!filter.value){
                    this.template.querySelectorAll('.value-select-div')[index].classList.add('error-in-value-input');
                    return;
                }
            }else{
                this.filters = [];
            }
            this.filters.push({
                fieldName: null,
                operator: null,
                value: null,
                type:null,
                inputType: null,
                operators : []
            });
            this.initialFilters = true;
            this.filtersCount = this.filters.length;
        }catch(e){
            console.log('Error in adding a new filter , ', e.stack);
        }
    }

// -=-=- To add One empty Sort object to the Sorts list -=-=-
    addSort() {
        try{
            let sort = this.sorts[this.sorts.length-1];
            if(this.sorts.length!=0){
                this.template.querySelectorAll('.sort-field-select')[this.sorts.length-1].classList.remove('error-in-custom-combobox');
                if(this.sorts.length != 0 && !sort.field){
                    this.template.querySelectorAll('.sort-field-select')[this.sorts.length-1].classList.add('error-in-custom-combobox');
                    // this.showToast('error', 'Something went wrong!', 'Please fill the previous sort details..');
                    return;
                }
            }
            this.sorts.push({
                field:'',
                order:''
            });
        }catch(e){
            console.log('Error in adding a sort , ' , e.stack);
        }
    }
    
// -=-=- To remove clicked filter from the filters list -=-=-
    removeFilter(event){
        try {
            const index = event.target.dataset.index;
            // console.log('What is index to delete: ' + index);
            let filters_temp = JSON.parse(JSON.stringify(this.filters));
            if(filters_temp.length >1){
                filters_temp.splice(index, 1);
            }else if(filters_temp.length ==1){
                filters_temp[0].fieldName = null;
                filters_temp[0].operator = null;
                filters_temp[0].value = null;
                filters_temp[0].operators = [];
                filters_temp[0].type = null;
                filters_temp[0].inputType = null;
                this.template.querySelectorAll('.filter-index-div')[0].classList.remove('error-in-row');
            }

            for(let i = 0; i < filters_temp.length ; i++){
                this.updateOperatorOptions(i);
            }
            
            this.filters = filters_temp;
            this.isEditTabChanged = true;
            // console.log('this.filters : ' , this.filters);
        } catch (error) {
            console.log('Error in  Remove  Filters :: ', error.stack);
        }

    }

// -=-=- To remove clicked sort from the sorts list -=-=-
    removeSort(event){
        try{
            const index = event.target.dataset.index;
            // console.log('What is index: ' + index);
            if(this.sorts.length >1){
                this.sorts.splice(index, 1);
            }else if(this.sorts.length ==1){
                this.sorts[0].field = '';
                this.sorts[0].order = '';
                this.template.querySelectorAll('.sort-index-div')[0].classList.remove('error-in-row');
                this.template.querySelectorAll('.asc-btn')[0].classList.remove('selected-sort-order');
                this.template.querySelectorAll('.desc-btn')[0].classList.remove('selected-sort-order');
                this.template.querySelectorAll('.sort-field-select').forEach( ele => {
                    ele.classList.remove('error-in-custom-combobox');
                });
            }
            this.isEditTabChanged = true;
        }catch(e){
            console.log('Error in removing the sort ', e.stack);
        }
    }

// -=-=- To validate duplicate sort field and make sort order ASC -=-=- 
    handleSortFieldChange(event){
        try {
            const index = event.target.dataset.index;
            let selectedSortFields = [];
            const ascBtn = this.template.querySelectorAll('.asc-btn')[index];
            const descBtn = this.template.querySelectorAll('.desc-btn')[index];
            for(let sort of this.sorts){
                selectedSortFields.push(sort.field);
                // console.log('Sort Selected Fields :: ' + sort.field);
            }
            if(!event.detail[0] && this.sorts.length > 1){
                ascBtn.classList.remove('selected-sort-order');
                descBtn.classList.remove('selected-sort-order');
                this.sorts[index].field = '';
                this.sorts[index].order = '';
                this.template.querySelectorAll('.sort-field-select')[index].classList.add('error-in-custom-combobox');
                console.log('removed the order', this.sorts[index]);
                return;
            }
            this.template.querySelectorAll('.sort-field-select')[index].classList.remove('error-in-custom-combobox');
            // console.log( 'Is duplicate ? ', selectedSortFields.includes(event.detail[0]));
            if(selectedSortFields.includes(event.detail[0]) && event.detail[0]!=this.sorts[index].field){
                this.sorts[index].field = null;
                this.showToast('error', 'Oops! Duplicate detected!', 'You can only sort by a field once..', 5000);
            }else{
                this.sorts[index].field = event.detail[0];
                // console.log('this sort is :: ' , this.sorts[index]);
                if(this.sorts[index].order == ''){
                    this.sorts[index].order = 'ASC';
                    ascBtn.classList.add('selected-sort-order');
                    descBtn.classList.remove('selected-sort-order');
                    // console.log('Set order to : ' + this.sorts[index].order);
                }
                this.template.querySelectorAll('.sort-index-div')[index].classList.remove('error-in-row');
        
                // console.log('this Field value :: ' + this.sorts[index].field);
            }
            this.isEditTabChanged = true;
        } catch (error) {
            // console.log('Error in updating the sort field ::' , error.stack);
        }
    }

// -=-=- To make clicked sort Ascending -=-=-
    handleAscending(event){
        try{
            // console.log('Sorting ascending');
            const index = event.target.dataset.index;
            const ascBtn = this.template.querySelectorAll('.asc-btn')[index];
            const descBtn = this.template.querySelectorAll('.desc-btn')[index];
            this.sorts[index].order = 'ASC';
            // console.log('Set order to : ' + this.sorts[index].order);
            ascBtn.classList.add('selected-sort-order');
            descBtn.classList.remove('selected-sort-order');
            this.isEditTabChanged = true;
        }catch(e){
            console.log('Error on click ascending :: ' , e.stack);
        }

    }

// -=-=- To make clicked sort Descending -=-=-
    handleDescending(event){
        try{
            // console.log('Sorting descending');
            const index = event.target.dataset.index;
            const ascBtn = this.template.querySelectorAll('.asc-btn')[index];
            const descBtn = this.template.querySelectorAll('.desc-btn')[index];
            this.sorts[index].order = 'DESC';
            // console.log('Set order to : ' + this.sorts[index].order);
            descBtn.classList.add('selected-sort-order');
            ascBtn.classList.remove('selected-sort-order');
            this.isEditTabChanged = true;
        }catch(e){
            console.log('Error on click descending :: ' , e.stack);
        }
    }

// -=-=- Update the Operators based on the Selected Fields -=-=-
    handleFieldNameChange(event) {
        try {
            const index = event.target.dataset.index;
            if (event.detail[0]){
                this.filters[index].fieldName = event.detail[0];
                // this.filters[index].fieldName = event.target.value;
        
                // console.log('Field Name : ' +   this.filters[index].fieldName );
                // console.log('Field type from main ::  ' + this.fieldsForFilters.filter(field => field.value == this.filters[index].fieldName)[0].type);
                this.filters[index].type = this.fieldsForFilters.filter(field => field.value == this.filters[index].fieldName)[0].type;
                this.filters[index].value = '';
                this.validateCurrentFilter(index);
                this.updateOperatorOptions(index);
                this.template.querySelectorAll('.filter-field-select')[index].classList.remove('error-in-custom-combobox');
            }else{
                this.template.querySelectorAll('.filter-field-select')[index].classList.add('error-in-custom-combobox');
                this.filters[index].fieldName = null;
                this.filters[index].value = '';
                this.filters[index].operators = '';
            }

            this.initialFilters = true;
            this.filtersCount = this.filters.length;
            this.isEditTabChanged = true;
            
        } catch (error) {
            console.log('error in handleFieldNameChange : ', error.stack);
        }
        // console.log('This index :: ' + event.target.dataset.index);
    }

// -=-=- to validate the Filter on-the-go real-time -=-=-
    validateCurrentFilter(i){
        try {
            // console.log('validating filter no. ' , i);
            let filter = this.filters[i];
            const filterIndexDiv = this.template.querySelectorAll('.filter-index-div')[i];
            if(((filter.fieldName && filter.operator && filter.value) || this.filters.length==1)){
                filterIndexDiv.classList.remove('error-in-row');
            // }else if((!filter.fieldName || !filter.operator || !filter.value)){
                // filterIndexDiv.classList.add('error-in-row');
            }else if(filter.value.trim() == "NULL" && filter.operator && !["=", "!="].includes(filter.operator)){
                filter.operator = null;
                filter.value = null;
                // filterIndexDiv.classList.add('error-in-row');
                this.showToast('error', 'Oops! It\'s a Wrong move!', 'Please Select "Equal To"/"Not Equal to" operator to check NULL.', 5000);
            }
        } catch (error) {
            console.log('Error in validating current filter :: ' , error.stack);
        }
    }

// -=-=- to handle Operator field selection -=-=-
    handleOperatorChange(event){
        try{
            const index = event.target.dataset.index;
            // console.log('This value :: ' + event.target.value);
            // this.filters[index].operator = event.target.value;
            this.filters[index].operator = event.detail[0];
            this.filters[index].operator ? this.template.querySelectorAll('.operator-select')[index].classList.remove('error-in-custom-combobox'):this.template.querySelectorAll('.operator-select')[index].classList.add('error-in-custom-combobox');
            this.validateCurrentFilter(index);
            this.isEditTabChanged = true;
            // console.log('Operator changed to: ' + this.filters[index].operator);
        }catch(e){
            console.log('Error in changing the operator ::  ', e.stack);
        }
    }

// -=-=- to handle Value change -=-=-
    handleValueChange(event){
        try{
            const index = event.target.dataset.index;
            this.filters[index].value = event.target.value.trim();
            this.filters[index].value ? this.template.querySelectorAll('.value-select-div')[index].classList.remove('error-in-value-input'): this.template.querySelectorAll('.value-select-div')[index].classList.add('error-in-value-input');
            // console.log('Value changed to: ' + this.filters[index].value);
            this.validateCurrentFilter(index);
            this.isEditTabChanged = true;
        }catch(e){
            console.log('Error in updating the Value ::  ', e.stack);
        }
    }

    handleSimpleInputFocus(event){
        try {
            console.log('Event is now ::', event.target);
            const index = event.target.dataset.index;
            // console.log(this.filters[index].operator != "=" && this.filters[index].operator != "!=" && (this.filters[index].type.toUpperCase() !== 'DATETIME' || this.filters[index].type.toUpperCase() !=='DATE'));
            if((['ID','REFERENCE'].includes(this.filters[index].type.toUpperCase())) || this.filters[index].operator != "=" && this.filters[index].operator != "!=" && !['DATETIME', 'DATE'].includes(this.filters[index].type.toUpperCase())){
                return;
            }
            if(this.filters[index].type !== 'DATETIME' && this.filters[index].type !== 'DATE'){
                this.preDefinedValues = ['NULL'];
            }else{
                this.preDefinedValues = [...this.allPreDefinedValues];
            }
            event.currentTarget.nextElementSibling.classList.remove('dont-display-div');
            const backDrop = this.template.querySelector('.backDrop');
            if(backDrop){
                backDrop.style = 'display : block';
            }

        } catch (error) {
            console.log('Error Opening the Pre-defined Options ::' , error.stack);
        }
    }

    handleSimpleInputBlur(){
        try {
            this.template.querySelectorAll('.select-predefined-option').forEach((element)=>{
                element.classList.add('dont-display-div');
            })
            const backDrop = this.template.querySelector('.backDrop');
            if(backDrop){
                backDrop.style = 'display : none'
            }
        } catch (error) {
            console.log('Error Closing the Pre-defined Options ::' , error.stack);
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
            this.filters[index].value ? this.template.querySelectorAll('.value-select-div')[index].classList.remove('error-in-value-input'): this.template.querySelectorAll('.value-select-div')[index].classList.add('error-in-value-input');
            const backDrop = this.template.querySelector('.backDrop');
            if(backDrop){
                backDrop.style = 'display : none'
                // console.log('preDefined value changed to : ' , this.filters[index].value);
            }
            this.validateCurrentFilter(index);
        }catch(e){
            console.log('Error in handlePreDefinedClick ::', e.message);
        }
    }

    handleValueFromComboBox(event){
        try{
            const index = event.target.dataset.index;
            // console.log('Value from combo changed to: ' ,typeof event.detail, event.detail);
            if(event.detail.length <1){
                this.filters[index].value= null;
            }else if(event.detail.length ==1){
                this.filters[index].value= event.detail[0];
            }else{
                this.filters[index].value = event.detail;
            }
            this.filters[index].value ? this.template.querySelectorAll('.value-select-div')[index].classList.remove('error-in-value-input') : this.template.querySelectorAll('.value-select-div')[index].classList.add('error-in-value-input');
            this.validateCurrentFilter(index);
            this.isEditTabChanged = true;
        }catch(e){
            console.log('Error in changing the value from combobox ::  ', e.stack);
        }
    }

//-=-=- To Update the operators that can be used for a selected field -=-=-
    updateOperatorOptions(index) {
        this.showSpinner = true;
        try{
            let filter = this.filters[index];
            const fieldType = filter.type?.toLowerCase();
            // this.template.querySelectorAll('.sort-index')[index].innerText = index+1;
            // console.log('Field type: ' + fieldType);
            filter.operators = this.allOperatorOptions.filter(option => option.type.includes(fieldType));
    
            if(filter.operators.length<=0 && filter.fieldName){
                filter.operators = this.allOperatorOptions.filter(option => option.type.includes('default'));
            }
            if(fieldType != 'picklist' && fieldType != 'multipicklist' && fieldType != 'boolean'){
                if((fieldType == 'phone' || fieldType == 'number' || fieldType == 'currency') && !this.allPreDefinedValues.includes(filter.value.trim())){
                    filter.inputType = 'number';
                }else if(fieldType == 'date' && !this.allPreDefinedValues.includes(filter.value.trim())){
                    filter.inputType = 'date';
                // }else if(fieldType == 'boolean'){
                //     filter.inputType = 'toggle';
                //     // console.log('this is a boolean field' + index);
                //     this.template.querySelectorAll('.value-select-for-toggle')[index].checked = (filter.value=='true' ? true : false);
                }else if(fieldType == 'datetime' && !this.allPreDefinedValues.includes(filter.value.trim())){
                    filter.inputType = 'datetime';
                }else if(fieldType == 'email' && !this.allPreDefinedValues.includes(filter.value.trim())){
                    filter.inputType = 'email';
                }else if(fieldType == 'url' && !this.allPreDefinedValues.includes(filter.value.trim())){
                    filter.inputType = 'url';
                }else{
                    filter.inputType = 'text';
                }
            }else{
                // console.log('This Field type ::', fieldType);
                if(fieldType == 'picklist' || fieldType == 'multipicklist'){
    
                    // console.log('this field is :::  ' , this.allRetrievedFields.filter((option) => option.apiName==filter.fieldName)[0].picklistValues[0]);
                    filter.inputType = [];
                    for(let option of this.allRetrievedFields.filter((item) => item.apiName==filter.fieldName)[0].picklistValues){
                        // console.log('this Option :: ' , {label:option, value:option});
                        filter.inputType.push({label:option, value:option});
                    }
                }else if(fieldType == 'boolean'){
                    filter.inputType = [
                        {label: 'TRUE', value: 'true'},
                        {label: 'FALSE', value: 'false'}
                    ];
                }
            }
        }catch(e){
            console.log('Error setting up the filter :: ' , e.stack);
        }

        this.showSpinner = false;
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
            console.log('Error in updating the selected sorts ::  ', e.stack);
        }
    }
    
// -=-=- To select the logic operator and show or hide the custom logic div if Custom logic is selected -=-=-
    handleLogicUpdate(event){
        try{
            if(event.detail[0]){
                this.selectedLogic = event.detail[0] ? event.detail[0] : null;
                // console.log('Selected Logic: ' + this.selectedLogic);
                this.selectedLogic == 'Custom' ? this.isCustomLogic = true : this.isCustomLogic = false;
                this.customLogicString = '';
                this.template.querySelector('.logic-select').classList.remove('error-in-custom-combobox');
            }else{
                this.selectedLogic = null;
                this.template.querySelector('.logic-select').classList.add('error-in-custom-combobox');
            }
            this.isEditTabChanged = true;
        }catch(e){
            console.log('Error in changing the Logic Operator ::  ', e.stack);
        }
    }

    handleCustomLogicUpdate(event){
        try{
            this.customLogicString = event.target.value;
            this.customLogicString = this.customLogicString.toUpperCase();
            this.isCustomLogicValid = this.validateOnEachCharacter();
            if(this.isCustomLogicValid){
                const logicStringInput = this.template.querySelector('.logic-string-input');
                // console.log('The Logic Seems to be true!!');
                // console.log('Custom Logic String: ' + this.customLogicString);
                // const validationRegex = /^(\d+|\(|\)|[ANDOR]|\s+)+$/;
                // console.log('IS validated :: ' + validationRegex.test(this.customLogicString));
                this.customLogicString.trim() ? 
                logicStringInput.classList.remove('error-in-input'):
                logicStringInput.classList.add('error-in-input');
            }
            this.isEditTabChanged = true;
        }catch(e){
            console.log('Error in changing the Custom logic String ::  ', e.stack);
        }
    }


    validateOnEachCharacter(){
        try{
            if(this.customLogicString){
                // console.log('custom logic in validate each :: '  + this.customLogicString);
                const checkCharactersRegex = /^[ANDor\d()\s]*$/i;
                const regex = /\d+/g;
                const logicStringInput = this.template.querySelector('.logic-string-input');
                const errorString =  this.template.querySelector('.error-text');
                // console.log('is true: ' , checkCharactersRegex.test(this.customLogicString));
                if(!checkCharactersRegex.test(this.customLogicString)){
                    // console.log('The Logic Seems to be false!!');
                    logicStringInput.classList.add('error-in-input');
                    errorString.innerText = 'Oops!, invalid characters found!';
                    return false;
                }
                const numbers = this.customLogicString.match(regex);
                // console.log('numbers ::' + numbers);
                if(numbers){
                    for (const num of numbers) {
                        if (num > this.filters.length || num < 1) {
                            // console.log(num , ' Number is greater than ', this.filters.length);
                            logicStringInput.classList.add('error-in-input');
                            errorString.innerText ='Um, Filter-'+ num + ' does not exist!';
                            return false;
                        }
                    }
                }
                logicStringInput.classList.remove('error-in-input');
                // errorString.innerText = 'Great!, everything looks good!';
                errorString.innerText = '';
                return true;
            }
        }catch(e){
            console.log('Error in validating custom logic on each character ::  ', e.stack);
        }

        return false;
    }

    validateCustomLogic(){
        try{
            // console.log('custom logic in blur :: '  + this.customLogicString);
            const logicStringInput = this.template.querySelector('.logic-string-input');
            const errorString =  this.template.querySelector('.error-text');
            logicStringInput.classList.remove('error-in-input');
            if(!this.customLogicString){
                errorString.innerText = 'Seems so empty!!';
                // console.log('Custom Logic is ::: ' + this.isCustomLogicValid);
                logicStringInput.classList.add('error-in-input');
                this.showErrorMessage('Please Enter a Custom Logic Formula.');
                this.isCustomLogicValid = false;
                return;
            }
            const regex = /\d+/g;
            const numbers = this.customLogicString.match(regex);
            // console.log('numbers ::' + numbers);
            if(numbers){
                for (const num of numbers) {
                    if (num > this.filters.length  || num <1) {
                        // console.log(num , ' Number is greater than ', this.filters.length);
                        this.isCustomLogicValid = false;
                        this.showErrorMessage('Um, Filter-'+ num + ' does not exist!');
                        return;
                    }else if(!this.filters[num-1].fieldName){
                        // console.log('Nothing entered in filter ' + num);
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
                    // console.log('the opening Count :: ' + count);
                    newString[i] = count;
                    // console.log('New String :: ' + newString);
                } else if (char === ')') {
                    // console.log('the closing Count :: ' + count);
                    newString[i] = count;
                    if(newString.includes(count)){
                        let startIndex = newString.indexOf(count);
                        // console.log(startIndex);
                        // console.log(newString.slice(startIndex+1,i).join(''));
                        newString[startIndex] = 't';
                        newString[i] = 't';
                        if(startIndex>0 && i< newString.length && (newString[startIndex-1]== '&' || newString[startIndex-1]=='|') && (newString[i+1]== '&' || newString[i+1]=='|') ){
                            if(newString[startIndex-1] == newString[i+1]){
                                // console.log('corresponding bracket has good match !!');
                            }else{
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

            // console.log('the string generated : ' + logicString);
            // console.log('Is Converted String Valid?? ' , validatorAfterConversion.test(logicString));
            if(validatorAfterConversion.test(logicString)){
                if(!isValidBrackets){
                    this.showErrorMessage('There are unmatched brackets in the logic..');
                    this.isCustomLogicValid = false;
                    logicStringInput.classList.add('error-in-input');
                    // console.log('Please enter a valid brackets');
                    return;
                }else if(logicString.length == 2){
                    this.isCustomLogicValid = false;
                    this.showErrorMessage('Try these patterns : "1 OR 2"');
                    // console.log('Cant be two characters in a logic string!!' + logicString);
                    return;
                }else if(logicString.length == 1 && logicString == 'N'){
                    // console.log('Only one number selected' + logicString);
                }else if(logicString.length == 3){
                    // console.log('In three !!');
                    if((logicString[0]== '(' && logicString[1]=='N' && logicString[2]==')') || (logicString[0]== 'N' && (logicString[1]=='&' || logicString[1]=='|')  && logicString[2]=='N')){
                        // console.log('The  Character is : (N) ');
                    }else{
                        this.isCustomLogicValid = false;
                        this.showErrorMessage('Try this patterns: "(1)" or "1 AND/OR 2".');
                        return;
                    }
                }else if(!((logicString[0] == '(' || logicString[0] == 'N') && (logicString[logicString.length-1] == ')' || logicString[logicString.length-1] == 'N'))){
                    this.isCustomLogicValid = false;
                    logicStringInput.classList.add('error-in-input');
                    this.showErrorMessage('You can Start and end logic only with number or brackets.');
                    // console.log('Please enter a valid character');
                    return;
                }else{
                    // console.log('that is what needed!!');
                    // console.log('Length of Logic String :: ' + logicString.length);
                    if(logicString.length > 3){
                        for(let i=0; i<logicString.length-1; i++){
                            if(logicString[i] == '('){
                                // console.log('The '+ i +' Character is : (' );
                                if(logicString[i+1] == '('){
                                    // console.log('The '+ +i+1 +' Character is : (');
                                    // if(logicString[i+2] == 'N'){
                                    //     // console.log('The '+ +i+2 +' Character is : N ');
                                    // }else{
                                    //     this.isCustomLogicValid = false;
                                    //     console.log('The '+ +i+2 +' Character Should be : N');
                                    //     break;
                                    // }
                                }else if(logicString[i+1] == 'N'){
                                    // console.log('The '+ +i+1 +' Character is : N ');
                                    if(logicString[i+2] == '&' || logicString[i+2] == '|'){
                                        // console.log('The '+ +i+2 +' Character is : & / | ');
                                    }else{
                                        this.isCustomLogicValid = false;
                                        this.showErrorMessage('There should be operator after the Number.');
                                        // console.log('The '+ +i+2 +' Character Should be :  & / |');
                                        return;
                                    }
                                }else{
                                    // console.log('The '+ +i+1 +' Character Should be : N');
                                    this.isCustomLogicValid = false;
                                    this.showErrorMessage('Please add a number or another "(" after a "(".')
                                    return;
                                }
                                
                            }else if(logicString[i] == 'N'){
                                // console.log('The '+ i +' Character is : N ');
                                if(logicString[i+1] == ')' || logicString[i+1] == '&' || logicString[i+1] == '|'){
    
                                    // console.log('The '+ +i+1 +' Character is : ) / & / | ');
                                }else{
                                    this.isCustomLogicValid = false;
                                    this.showErrorMessage('There should be an Operator or a ")" after a number.');
                                    console.log('The '+ +i+1 +' Character Should be : ) / & / | ');
                                    return;
                                }
                                
                            }else if(logicString[i] == '&'){
                                // console.log('The '+ i +' Character is : & ');
                                if(logicString[i+1] == '('){
                                    // console.log('The '+ +i+1 +' Character is : ( ');
                                }else if(logicString[i+1] == 'N' ){
                                    // console.log('The '+ +i+1 +' Character is : N  ');
                                    if(logicString.length == i+2 || (logicString[i+2] == '&' || logicString[i+2] == ')')){
                                        // console.log('The '+ +i+2 +' Character is : & / )');
                                    }else{
                                        this.isCustomLogicValid = false;
                                        this.showErrorMessage('Try these patterns : "1 AND 2 AND 3" or "1 AND (2 OR 3)".');
                                        console.log('The '+ +i+2 +' Character Should be : &');
                                        return;
                                    }
                                }else{
                                    this.isCustomLogicValid = false;
                                    this.showErrorMessage('There should be an number or a "(" after an operator.');
                                    console.log('The '+ +i+1 +' Character Should be : ) N ');
                                    return;
                                }
                                
                            }else if(logicString[i] == '|'){
                                // console.log('The '+ i +' Character is : | ');
                                if(logicString[i+1] == '('){
                                    // console.log('The '+ +i+1 +' Character is : ( ');
                                }else if(logicString[i+1] == 'N'){
                                    // console.log('The '+ +i+1 +' Character is : N/ ( ');
                                    if(logicString.length == i+2 || logicString[i+2] == '|' || logicString[i+2] == ')'){
                                        // console.log('The '+ +i+2 +' Character is : | / )');
                                    }else{
                                        this.isCustomLogicValid = false;
                                        this.showErrorMessage('Try these patterns : "1 AND 2 AND 3" or "1 OR (2 AND 3)".');
                                        // console.log('The '+ +i+2 +' Character Should be : |');
                                        return;
                                    }
                                }else{
                                    this.isCustomLogicValid = false;
                                    this.showErrorMessage('There should be a number or a "(" after an operator.');
                                    // console.log('The '+ +i+1 +' Character Should be : N / (');
                                    return;
                                }
                                
                            }else if(logicString[i]== ')'){
                                // console.log('The '+ i +' Character is : ) ');
                                if(logicString[i+1] == ')'){
                                    // console.log('The '+ +i+1 +' Character is : ) / & / |  ');
                                }else if(logicString[i+1] == '&' || logicString[i+1] == '|'){
                                    
                                }else{
                                    this.isCustomLogicValid = false;
                                    this.showErrorMessage('There should be an operator or another ")" after an ")".');
                                    // console.log('The '+ +i+1 +' Character Should be : ) / & / | ');
                                    return;
                                }
                                
                            }
                        }
                    }
                }
            }else{
                errorString.innerText = 'Oops! Please check spelling of \'AND\' and \'OR\'';
                this.showErrorMessage('It seems to be spelling mistake of "AND" and "OR".');
                this.isCustomLogicValid = false;
                // console.log('That was unexpected!!');
                return;
            }
            // console.log('Replaced String :: ' + logicString);
            
            logicStringInput.classList.remove('error-in-input');
            // console.log('Custom Logic is ::: ' + this.isCustomLogicValid);
            if(this.isCustomLogicValid){
                // errorString.innerText = 'Great!, everything looks good!';
                errorString.innerText = '';
                // this.showToast('success', 'Woohoo! A valid Logic!', 'The created logic seems just right to us!', 5000);
            }else{
                logicStringInput.classList.add('error-in-input');
                this.showToast('error', 'Please enter valid Logic!', 'there was an error in the custom logic!', 5000);
            }
        }catch(e){
            console.log('Error in validating the custom logic ::  ', e.stack);
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
            console.log('Error in showing  the error message ::  ', e.stack);
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
            console.log('Error in changing the Limit ::  ', e.message);
        }
    }

    handleLimitToggleChange(event){
        try{
            // console.log('Is Checked ::::::::::: ' , event.target.checked);
            this.showLimitInput = event.target.checked;
            let maxLimit = this.isChild ? this.childMaxLimit : 1000000;
            let shownLimit = this.isChild ? this.childMaxLimit : 50000;
            // let shownLimit = 50;
            // this.isChild ? shownLimit = this.childMaxLimit : shownLimit= 50000;
            this.limit = this.showLimitInput ? shownLimit : maxLimit;
            console.log('this.limit : ', this.limit);
            this.isEditTabChanged = true;
        }catch(e){
            console.log('Error in toggling the limit input.');
        }
    }
    generateFilterString() {
        try{
            // <|MDG|> - for separating the Sort values --- Filter Values (Main Separator) --- custom logic --- limit --- List View
            // <|SDG|> - for separating the sorting field and sorting order
            // <|FDG|> - for separating the filters
            // <|LDG|> - for separating the Logic values if Custom Logic Selected
            // <|IDG|> - for separating the inner filter values
            // this.separatedData = '';
    
            //Save the Sorts

            let selectedApiNames = [];
                this.selectedFields.forEach(field => {
                    selectedApiNames.push(field.apiName);
                });
            this.separatedData.fields = selectedApiNames.join(',');

            if (this.sorts.length > 0) {
                this.separatedData.orders =  this.sorts.map((sort) => {
                    if (sort.field && sort.order) {
                        const sortParts = [sort.field, sort.order];
                        return sortParts.join('<|IDG|>'); // Join sort values with separator
                    }
                }).join('<|SDG|>'); // Join individual Sorts with separator
            }
            // this.separatedData += '<|MDG|>';
    
    
            //Save the Filters
            if (this.filters.length > 0) {
                this.separatedData.filters =  this.filters.map((filter) => {
                    if (filter.fieldName && filter.operator && filter.value && filter.type) {
                        typeof filter.value === 'object' ? filter.value = filter.value.join('<|CS|>') : undefined;
                        const filterParts = [filter.fieldName, filter.operator, filter.value, filter.type];
                        filter.value.includes('<|CS|>') ? filter.value= filter.value.split('<|CS|>') : undefined;
                        return filterParts.join('<|IDG|>'); // Join filter values with separator
                    }
                }).join('<|FDG|>'); // Join individual filters with separator
            }
    
            // console.log('String is :: ' + this.separatedData);
    
            // this.separatedData += '<|MDG|>';
    
            //Save the Logic
            if(this.selectedLogic){
                if (this.isCustomLogic && this.customLogicString.trim()) {
                    this.separatedData.logic = this.selectedLogic + '<|LDG|>' + this.customLogicString.trim();
                }else{
                    this.separatedData.logic = this.selectedLogic;
                }
            }
    
            // this.separatedData += '<|MDG|>';
    
            this.separatedData.maxLImit = this.limit;
            this.separatedData.listView = this.selectedListView;
            // console.log('data is is :: ' , this.separatedData);
        }catch(e){
            console.log('Error in generating the filter string ::  ', e.stack);
        }

    }

    parseFilterString(){
        try{
            // console.log('Separated data::', this.separatedData);
            if (this.separatedData) {
            
                // console.log('String is :: ' , this.separatedData);
                // const parts = this.separatedData.split('<|MDG|>'); // Split at main separator
                if (this.separatedData.fields) {
                    let preSelectedApiNames = this.separatedData.fields.split(',');
                    let seenApiNames = {};
                    for (let i = 0; i < preSelectedApiNames?.length; i++) {
                        seenApiNames[preSelectedApiNames[i].trim()] = i;
                    }
                    this.selectedFields = this.allRetrievedFields.filter(field =>
                        seenApiNames.hasOwnProperty(field.apiName)
                    ).sort((field1, field2) => seenApiNames[field1.apiName] - seenApiNames[field2.apiName]);
                    this.existingFields = [...this.selectedFields];
                }
    
                const oldSorts = this.separatedData.orders?.split('<|SDG|>')?.map((sortPart) => {
                    if(sortPart?.length >0){
                        // console.log('into the Sort part String ...');
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
    

                // if(this.separatedData.logic){
                //     if (!this.separatedData.logic.includes('OR') && !this.separatedData.logic.includes('AND')) {
                //         console.log('Is a Custom logic');
                //         this.isCustomLogic = true;
                //         this.customLogicString = this.separatedData.logic;
                //         this.selectedLogic = 'Custom';
                        // this.selectedLogic = parts[2].split('<|LDG|>')[0];
                        // this.customLogicString = parts[2].split('<|LDG|>')[1];
                if(this.separatedData.logic){
                    if (this.separatedData.logic?.includes('<|LDG|>')) {
                        this.selectedLogic = this.separatedData.logic.split('<|LDG|>')[0];
                        this.customLogicString = this.separatedData.logic.split('<|LDG|>')[1];
                        this.isCustomLogic = true;
                    }else{
                        console.log('Is not custom logic');
                        this.selectedLogic = this.separatedData.logic;
                    }
                }
                // console.log('THe Custom Logic :::  ' + this.customLogicString);
                
                for(let i =0; i<oldFilters?.length; i++) {
                    // console.log('type of the filter :: ', oldFilters[i].type);
                    const fieldType = oldFilters[i].type.toLowerCase();
                    // console.log('Field type: ' + fieldType);
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
                    // this.template.querySelector('.toggle-limit').checked = this.showLimitInput;
                    // console.log('TO show input limit or not :: ' + this.showLimitInput);
                    // this.limit = this.separatedData.maxLimit.split('<|LDG|>')[1];
                }

                if(this.separatedData.listView){
                    this.selectedListView = this.separatedData.listView;
                }
    
                this.filters = oldFilters;
                // console.log('sorts length ::: ' + oldSorts.length);
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
                // console.log('Length of sorts :: ' + this.sortsCount);


                this.existingFilters = this.filters ? JSON.parse(JSON.stringify(this.filters)) : undefined;
                this.existingSorts = this.sorts ? JSON.parse(JSON.stringify(this.sorts)) : undefined;
                this.existingLogic = this.selectedLogic;
                this.existingCustomLogicString = this.customLogicString;
                this.existingShowLimitInput = this.showLimitInput;
                this.existingLimit = this.limit;
    
            }
            this.showSpinner = false;
        }catch(e){
            console.log('Error in parsing the fetched data ::  ', e.stack);
        }
    }

    generateQuery(){
        try{
            this.generatedQuery = 'SELECT ';
            let selectedApiNames = [];
            this.selectedFields.forEach(field => {
                selectedApiNames.push(field.apiName);
            });
            if(selectedApiNames){
                this.generatedQuery += selectedApiNames?.join(', ');
            }else{
                this.generatedQuery += ' Id ';
            }
            this.generatedQuery+= ' FROM '+ this.objectName ;
    
            const conditions = [];
            this.filters.forEach(filter => {
                // console.log('Field Name : ', filter.fieldName + ' Operator :: ' + filter.operator + ' Operators :: ' + filter.operators + ' Type ::: ' + filter.type + ' Input Type ::: ' + filter.inputType);
                typeof filter.value === 'object' ? filter.value = filter.value?.join('<|CS|>') : undefined;
                if (filter.fieldName && filter.operator && filter.value && filter.type) {
                    // console.log('Field Name : ', filter.fieldName + ' Operator :: ' + filter.operator + ' Operators :: ' + filter.operators + ' Type ::: ' + filter.type + ' Input Type ::: ' + filter.inputType);
                    let condition = '';
                    // console.log('Filter type :: ' + filter.type);
                    if (filter.type.toUpperCase() == 'MULTIPICKLIST'){
                        if(["=","!="].includes(filter.operator)){
                            console.log('Actual Value ::' , filter.value);
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
                        // console.log('Filter is LIKE');
                        condition =  filter.fieldName + ' LIKE \'%' + filter.value + '%\' ';
                    }else if (filter.operator == 'startLIKE') {
                        // console.log('Filter is starts LIKE');
                        condition =  filter.fieldName + ' LIKE \'' + filter.value + '%\' ';
                    }else if (filter.operator == 'endLIKE') {
                        // console.log('Filter is ends LIKE');
                        condition =  filter.fieldName + ' LIKE \'%' + filter.value + '\' ';
                    }else if (filter.operator == 'notLIKE') {
                        // console.log('Filter is not LIKE');
                        condition =  '( NOT ' + filter.fieldName + ' LIKE \'%' + filter.value + '%\' )';
                    }else if(filter.type.toUpperCase() == 'NUMBER' || filter.type.toUpperCase() == 'CURRENCY' || filter.type.toUpperCase() == 'DATE' || filter.type.toUpperCase() == 'BOOLEAN' || filter.type.toUpperCase() == 'DATETIME' ||  this.allPreDefinedValues.includes(filter.value)){
                        // console.log('Filter is non quote');
                        condition = filter.fieldName + ' ' + filter.operator + ' ' + filter.value + ' ';
                    }else if(filter.operator == 'IN'){
                        // console.log('Filter is IN');
                        let newValue = filter.value.split('<|CS|>').map(item => item.trim());
                        newValue = "'" + newValue?.join("','") + "'";
                        condition =  filter.fieldName +' IN (' + newValue + ') ';
                    }else if(filter.operator == 'notIN'){
                        // console.log('Filter is notIN');
                        let newValue = filter.value.split('<|CS|>').map(item => item.trim());
                        newValue = "'" + newValue?.join("','") + "'";
                        condition =  filter.fieldName +' NOT IN (' + newValue + ') ';
                    }else{
                        // console.log('Filter is quote');
                        condition =  filter.fieldName + ' ' + filter.operator + ' \'' + filter.value + '\' ';
                    }
                    conditions.push(condition);
    
                }
                filter.value.includes('<|CS|>') ? filter.value= filter.value.split('<|CS|>') : undefined;
            });
            // console.log('Conditions length: ' + conditions.length);
            if(this.isCustomLogic===false && conditions.length >0){
                this.generatedQuery += ' WHERE ' + conditions?.join(' '+ this.selectedLogic +' ');
            }else if(conditions.length >0){
                try{
                    const regex = /\d+/g;
                    this.generatedQuery += ' WHERE ' +this.customLogicString.replace(regex, match => {
                        // We are doing -1 because we are showing them from 1 and index starts from 0 for the same filter
                        return ' '+conditions[parseInt(match)-1] + ' ';
                    });
    
                }catch(error){
                    console.log('Error in custom Logic ' + error.message);
                }
            
                // Replace numbers with conditions using a regular expression
            }
    
            let orderBy = [];
            for(let sort of this.sorts){
                if(sort.field && sort.order){
                    orderBy.push(sort.field +' '+ sort.order);
                }
            }
            if(orderBy.length >0){
                this.generatedQuery += ' ORDER BY '+  orderBy?.join(', ');
            }
    
            if(this.limit){
                this.generatedQuery += ' LIMIT '+ this.limit;
            }
            // console.log('Generated this.generatedQuery : ' + this.generatedQuery);
        }catch(e){
            console.log('Error in creating the query ::  ', e.stack);
        }
    }

    validateData(){
        try{
            let invalidData = {
                type: '',
                message: '',
                description: '',
                duration: 5000
            };
            let foundError = false;
            // console.log('Generated Query is ::: ' + this.generatedQuery.length);
            // console.log('Validating data limit : ' + this.limit , "is", this.limit <0 || this.limit > 50000);
            if(this.selectedFields.length <=0){
                // console.log('Validated selected fields');
                if(!foundError){
                    invalidData = {type: 'error', message: 'Oops! You missed to select Fields!', description:'Please Select at least one field!', duration:5000};
                    foundError = true;
                }
                // this.showToast('error','Oops! You missed to select Fields!', 'Please Select at least one field!', 5000);
            }
    
            if(this.sorts){
                const sortIndexDiv = this.template.querySelectorAll('.sort-index-div');
                for (let i = 0; i < this.sorts.length; i++) {
                    sortIndexDiv[i]?.classList.remove('error-in-row');
                    let sort = this.sorts[i];
                    if(this.sorts.length!==0){
                        // console.log('Sorts length not 0 :: ' , this.sorts.length);
                        this.template.querySelectorAll('.sort-field-select')[i]?.classList.remove('error-in-custom-combobox');
                        if(this.sorts.length !== 1){
                            // console.log('Sorts length not 1 :: ' , this.sorts.length);
                            if(!sort.field){
                                // console.log('error in ', i);
                                this.template.querySelectorAll('.sort-field-select')[i]?.classList.add('error-in-custom-combobox');
                                this.showSpinner = false;
                                sortIndexDiv[i]?.classList.add('error-in-row');
                                if(!foundError){
                                    invalidData = {type: 'error', message: 'Oops! You missed to fill data!', description:'Please fill the valid data to sort records..', duration:5000};
                                    foundError = true;
                                }
                            }
                        }
                    }
                }
            }
    
            if(!this.selectedLogic){
                // console.log('Validated Selected Logic');
                // invalidData = true;
                if(!foundError){
                    invalidData = {type: 'error', message: 'Oops! You missed to select Logic!', description:'Please select a logic you want to apply!', duration:5000};
                    foundError = true;
                }
            }
    
            if(this.isCustomLogic){
                const logicStringInput = this.template.querySelector('.logic-string-input');
                logicStringInput?.classList.remove('error-in-input');
                if(!this.customLogicString.trim()){
                    // console.log('Validated Custom Logic');
                    // invalidData = true;
                    if(!foundError){
                        invalidData = {type: 'error', message: 'Oops! You missed to select Fields!', description:'Please enter a valid Custom Logic!', duration:5000};
                        foundError = true;
                    }
                    // this.showToast('error', 'Oops! You missed to fill data!','Please enter a valid Custom Logic!', 5000);
                    logicStringInput?.classList.add('error-in-input');
                    // console.log(logicStringInput?.classList);
                }
                if(!this.isCustomLogicValid){
                    // console.log('Custom Logic is ::: ' + this.isCustomLogicValid);
                    logicStringInput?.classList.add('error-in-input');
                    // console.log('Validated Custom Logic');
                    // invalidData = true;
                    if(!foundError){
                        invalidData = {type: 'error', message: 'Oops! Custom logic is invalid!', description:'Please Validate the Custom Logic!!', duration:5000};
                        foundError = true;
                    }
                }
            // }else
            }
            if(this.showLimitInput){
                const limitInput = this.template.querySelector('.input-limit');
                limitInput?.classList.remove('error-in-input');
                let maxLimit = this.isChild ? this.childMaxLimit : 1000000;
                if(this.limit <1 || this.limit > maxLimit){
                        // console.log('validated Limit');
                        // invalidData = true;
                        if(!foundError){
                            let maxLImit = this.isChild ? this.childMaxLimit : 1000000;
                            invalidData = {type: 'error', message: 'Oops! You entered wrong limit!', description:'Please enter a limit between 0 and '+maxLImit, duration:5000};
                            foundError = true;
                        }
                        // this.showToast('error', 'Oops! You entered wrong limit!', 'Please enter a limit between 0 and 50000!', 5000);
            
                        limitInput?.classList.add('error-in-input');
                        // console.log(limitInput?.classList);
                }
            }
            let filterValidationPromises = [];
            if (this.filters) {
                const filterIndexDiv = this.template.querySelectorAll('.filter-index-div');
                for (let i = 0; i < this.filters.length; i++) {
                    filterIndexDiv[i]?.classList.remove('error-in-row');
                    let filter = this.filters[i];
                    if ((!filter.fieldName || !filter.operator || !filter.value) && this.filters.length != 1) {
                        if (this.filters.length !== 0) {
                            this.template.querySelectorAll('.filter-field-select')[i]?.classList.remove('error-in-custom-combobox');
                            this.template.querySelectorAll('.operator-select')[i]?.classList.remove('error-in-custom-combobox');
                            this.template.querySelectorAll('.value-select-div')[i]?.classList.remove('error-in-custom-combobox');
                            if (!filter.fieldName) {
                                this.template.querySelectorAll('.filter-field-select')[i]?.classList.add('error-in-custom-combobox');
                            } else if (!filter.operator) {
                                this.template.querySelectorAll('.operator-select')[i]?.classList.add('error-in-custom-combobox');
                            } else if (!filter.value) {
                                this.template.querySelectorAll('.value-select-div')[i]?.classList.add('error-in-value-input');
                            }
                        }
                        this.showSpinner = false;
                        filterIndexDiv[i]?.classList.add('error-in-row');
                        if (!foundError) {
                            invalidData = {type: 'error', message: 'Oops! You missed to fill data!', description: 'Please fill the valid data to filter records..', duration: 5000};
                            foundError = true;
                        }
                    } else if (filter.fieldName && filter.operator && (filter.type.toUpperCase() === 'REFERENCE' || filter.type.toUpperCase() === 'ID')) {
                        let promise = validateRelatedObject({ objName: this.objectName, apiName: filter.fieldName.toUpperCase() })
                        .then(objPrefix => {
                            if (!(objPrefix && filter.value.slice(0, 3) === objPrefix && (filter.value.length === 15 || filter.value.length === 18))) {
                                filterIndexDiv[i]?.classList.add('error-in-row');
                                if (!foundError) {
                                    invalidData = {type: 'error', message: 'Oops! You Filled Incorrect data!', description: 'Please correct the id in the record ID fields..', duration: 5000};
                                    foundError = true;
                                }
                            }
                        })
                        filterValidationPromises.push(promise);
                    }
                }
            }
            Promise.all([...filterValidationPromises])
            .then(() => {
                if(this.generatedQuery.length > 1000000){
                    if(!foundError){
                        invalidData = {type: 'error', message: 'Oops! It\'s Our fault!', description:'Try removing some of the filters..', duration:5000};
                        foundError = true;
                    }
                }
        
                if(!foundError){
                    let selectedApiNames = [];
                    this.selectedFields.forEach(field => {
                        selectedApiNames.push(field.apiName);
                    });
                    let fields = selectedApiNames.join(',');
                    if(this.isChild){
                        this.showSpinner = false;
                        this.dispatchEvent(new CustomEvent('save', {detail : {selectedFields: this.selectedFields , query: this.generatedQuery, generatedData : {fields : fields, filters :this.separatedDat }}}));
                    }
                    else{
                        saveTemplateFields({templateId : this.templateId, query: this.generatedQuery, configData : this.separatedData})
                        .then(()=>{
                            // console.log('Template Fields saved successfully');
                            this.showToast('success', 'Yay! Everything worked!', 'The template fields were saved successfully', 5000);
                            this.existingFields = JSON.parse(JSON.stringify(this.selectedFields));
                            this.existingFilters = JSON.parse(JSON.stringify(this.filters));
                            this.existingSorts = JSON.parse(JSON.stringify(this.sorts));
                            this.existingLogic = this.selectedLogic;
                            this.existingShowLimitInput = this.showLimitInput;
                            this.existingLimit = this.limit;
                            this.existingCustomLogicString = this.customLogicString;
                            this.isEditTabChanged = false;
                        })
                        .catch(error=> {
                            console.log('Error in saveTemplateFields ::', error);
                            const eMessage = this.selectedFields ? 'Something went wrong, Please try again!!' : 'Please Select at least one field!';
                            this.showToast('error', 'Oops! Something went wrong', eMessage, 5000);
                        });
                    }
                }else{
                    // console.log('Invalid data found!' , foundError);
                    this.showToast(invalidData.type, invalidData.message, invalidData.description, invalidData.duration);
                    this.showSpinner = false;
                }
            })
            .catch(e => {
                console.log('Error in after validations ::', e.message);
            })
        }catch(e){
            this.showSpinner = false;
            this.showToast('error','Something went wrong!', 'We Couldn\'t save template, please try again.', 5000)
            console.log('Error in validating the data ::  ', e.message, e.line);
        }
    }

    handleSave(){
        try{
            this.showSpinner = true;
            console.log('In Save!');
            this.generateFilterString();
            console.log('Generated the Filter String!!');
            this.generateQuery();
            console.log('Generated the Query String!!');
            if(this.isCustomLogic){
                this.validateCustomLogic();
            }
            console.log('Custom Logic is Validated!!');
            this.validateData();
        }catch(e){
            console.log('Error in handleSave ::  ', e.stack);
        }
    }
    

    handleClose(){
        try {
            if(this.isChild){
                this.dispatchEvent(new CustomEvent('close'));
            }
            else{
                if(this.isEditTabChanged || this.isBasicTabChanged){
                    this.isClose = true;
                    this.showWarningPopup('warning', 'Are you sure, you want to close?', 'Your changes may not be saved.');
                    return;
                }
                this.navigateToComp(navigationComps.home);
            }
        } catch (error) {
            console.log('Error handleClose :' + error.message);
        }
    }

    handleConfirmation(event){
        try {            
            console.log('Got Event Details::', event.detail);
            
            if(event.detail){
                if(this.isClose){
                    this.navigateToComp(navigationComps.home);
                }else if(this.isListViewUpdate){
                    this.isListViewUpdated = true;
                }else if(this.isTemplateUpdate){
                    this.handleUpdateTemplate();
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
            this.isTemplateUpdate = false;
            this.isCancelTemplate = false;
            this.isReset = false;
            this.isClear = false;
        } catch (e) {
            console.error('Error in handleConfirmation:', e.message);
        }
    }

    handleClear(event){
        try{
            this.clearSection = event.target.dataset.name; 
            this.isClear = true;
            this.showWarningPopup('warning', 'Clear '+ this.clearSection + ' Section!', 'Are you sure you want to Clear '+ this.clearSection + '?');
        }catch(e){
            console.log('Error in handleClear ::  ', e.stack);
        }
    }

    handleReset(event){
        try{
            this.resetSection = event.target.dataset.name; 
            this.isReset = true;
            this.showWarningPopup('warning', 'Reset '+ this.resetSection + ' Section!', 'Are you sure you want to reset '+ this.resetSection + '?');            
        }catch(e){
            console.log('Error in handleReset ::  ', e.stack);
        }

    }

    handleClearSection(){
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
    }

    handleResetSection(){
        if(this.resetSection === "fields"){
            this.toRemoveSelected.push(...this.selectedFields);
            this.handleLeft();
            this.toRemoveSelected = [];
            this.selectedFields = JSON.parse(JSON.stringify(this.existingFields));
        }else if(this.resetSection === "filters"){
            this.filters = JSON.parse(JSON.stringify(this.existingFilters));
            this.filtersCount = this.filters.length;
            this.initialFilters = true;
            this.selectedLogic = this.existingLogic;
            this.isCustomLogic = this.selectedLogic=='Custom' ? true : false;
            this.customLogicString = this.existingCustomLogicString;
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
    }

    handleCustom(){
        this.showListViewPopup = false;
    }

    //Basic Details Tab

    handleChangeStatus(event){
        this.newTemplateData.MVDG__Template_Status__c = event.target.checked;
        this.isBasicTabChanged = true;
        // console.log('template is set to' , event.target.checked);
    }
    handleTemplateNameChange(event){
        try{
            this.newTemplateData.MVDG__Template_Name__c = event.target.value;
            this.isBasicTabChanged = true;
        }catch(e){
            console.log('Error in handleTemplateNameChange :: ' , e.stack);
        }
    }
        
    handleDescriptionChange(event){
        this.newTemplateData.MVDG__Description__c = event.target.value;
        this.isBasicTabChanged = true;
        // console.log('Description Updated to , ' , this.newTemplateData.MVDG__Description__c);
    }

    handleListViewChange(event){
        if(this.isNew && !this.showBasicDetailTab){
            this.selectedListView = event.currentTarget.dataset.value;
            this.newTemplateData.selectedListView = this.selectedListView;
            this.isListViewUpdated = true;
            // console.log('Selected list view ::: ' + this.selectedListView);
            this.handleListView();
            return;
        }
        this.tempListView = this.selectedListView;
        this.selectedListView = event.detail[0];
        !this.selectedListView ? this.isListViewUpdated = false : undefined;
        if(this.selectedListView && this.tempListView!==this.selectedListView){
            this.showWarningPopup('warning', 'Are you sure to change list view?', 'Changing the list view may override the current changes.');
        }
        this.isListViewUpdate = true;
        this.isBasicTabChanged = true;

        console.log('Is List view Updated ?? ::', this.isListViewUpdated);
    }

    handleListViewSearch(event){
        this.listViewSearchKey = event.target.value;
        // console.log('Searched List view ::: ' + this.listViewSearchKey);
    }

    handleDetailsCancel(){
        try {
            if (this.isBasicTabChanged){
                this.showWarningPopup('warning', 'Cancel Template Changes!', 'Are you sure you want to cancel the changes?');
                this.isCancelTemplate = true;
                return;
            }
            this.handleCancelChanges();
        } catch (error) {
            console.log('Error in handleDetailsCancel' , error.stack);
        }
    }

    handleDetailsSave(){
        try {
            // console.log('this new template data : ' , this.newTemplateData);
            if(!this.newTemplateData.MVDG__Template_Name__c.trim()){
                this.showToast('error', 'Oops! Missed to fill the data!', 'Please enter the valid name for the template.',5000);
                return;
            }
            if (this.isBasicTabChanged){
                this.showWarningPopup('warning', 'Update Template Details!', 'Are you sure you want to update template details?');
                this.isTemplateUpdate = true;
            }
        } catch (error) {
            console.log('Error in handleDetailsSave ' , error.stack);
        }
    }

    handleCancelChanges(){
        this.newTemplateData.MVDG__Template_Name__c = this.existingTemplateData.MVDG__Template_Name__c ;
        this.newTemplateData.MVDG__Template_Status__c =this.existingTemplateData.MVDG__Template_Status__c;
        this.newTemplateData.MVDG__Description__c = this.existingTemplateData.MVDG__Description__c;
        this.selectedListView = this.existingTemplateData.MVDG__List_View__c;
        this.showBasicDetailTab = false;
        this.showEditTemplateTab = true;
        this.initialFilters = true;
        this.filtersCount = this.filters.length;
        this.showBasicDetailTab = false;
        this.isBasicTabChanged = false;
        this.setActiveTab('editTab');
    }

    handleUpdateTemplate(){
        try {
            if (this.isBasicTabChanged){
                this.showSpinner = true;
                if(this.selectedListView){
                    this.handleListView();
                    this.isBasicTabChanged = false;
                }
                let templateData = {
                    templateId : this.newTemplateData.Id,
                    templateName : this.newTemplateData.MVDG__Template_Name__c,
                    templateDescription : this.newTemplateData.MVDG__Description__c,
                    templateStatus : this.newTemplateData.MVDG__Template_Status__c,
                    listView : this.selectedListView
                }
                updateTemplate({templateInfo : templateData})
                .then(() => {
                    this.existingTemplateData.MVDG__Template_Name__c = this.newTemplateData.MVDG__Template_Name__c;
                    this.existingTemplateData.MVDG__Template_Status__c = this.newTemplateData.MVDG__Template_Status__c;
                    this.existingTemplateData.MVDG__Description__c = this.newTemplateData.MVDG__Description__c;
                    this.existingTemplateData.MVDG__List_View__c = this.selectedListView;
                    this.isBasicTabChanged = false;
                    this.showToast('success', 'Woohoo! Changes been saved!' , 'The template details been updated successfully.', 5000);
                })
                .catch((e)=>{
                    console.log('Error updating the existing template :' , e.message);
                    this.showToast('error', 'Oops! Couldn\'t save changes!' , 'Please try updating the data again...', 5000);
                })
            }
        } catch (e) {
            console.log('Error in handleUpdateTemplate , ', e.stack);
        }
    }
    
    getAllConditions(conditions) {
        let allConditions = [];
        try{
            this.selectedLogic = 'AND';
            for (const condition of conditions) {
                const currentCondition = {
                    fieldName: condition.field || "",
                    operator: "",
                    value: "",
                    type: "",
                    inputType: "",
                    operators: [],
                };
                if (condition.hasOwnProperty('conditions')) {
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
            }
        }catch(e){
            console.log('Error fetching conditions :: '  + e.message);
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
    
                try{
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
                        // console.log('URL : ' +window.location.origin );
                        let domainURL = window.location.origin;
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
                            // console.log('Selected : ' , this.selectedFields , ' Available : ' , this.fieldOptions);
                            fetchedColumns.forEach((column) => {
                                if(!column.hidden){
                                    const selectedApiName = column.fieldNameOrPath;
                                    this.selectedFields.push({ fieldName: this.fieldOptions.filter(option => option.apiName == selectedApiName)[0]?.fieldName, apiName: selectedApiName });
                                }
                            });
    
                            this.existingFields = JSON.parse(JSON.stringify(this.selectedFields));
                            // console.log('Selected : ' + this.selectedFields.length + ' Available : ' + this.fieldOptions.length);
                            this.showSpinner = false;
            
                            // console.log('fetched filters :: ', fetchedFilters );
                            if (!Array.isArray(fetchedFilters)) {
                                fetchedFilters = [fetchedFilters];
                            }
    
                            this.filters = this.getAllConditions(fetchedFilters);
                            // console.log('Filters before all ::', this.filters);
                            // to combine similar field, operator filters, but not so useful, because it can mis-interpret the original filters
                            // this.filters = this.combineSameFilters();
    
                            // console.log('Filters after all ::', this.filters);
            
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
            
                            // console.log('repeated ::: ' + repeatedIndices);
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
                            this.sortsCount == 0? this.addSort() : undefined;
    
                            this.existingFilters = JSON.parse(JSON.stringify(this.filters));
                            this.existingSorts = JSON.parse(JSON.stringify(this.sorts));
            
                            if(this.isNew){
                                this.showToast('success', 'Woohoo! List view updated!', 'All data from the list view has been imported.');
                            }
                            this.handleSave();
                        })
                        .catch(e => {
                            console.log('Error in list view data fetch ::', e.message);
                        })
                    })
                    .catch(e => {
                        console.log('Error in getSessionId ::', e.message);
                    })
                } catch(error){
                    this.showSpinner = false;
                    this.showToast('error', 'Oops, a technical issue!', 'We couldn\'t fetch the list view data, please try again..');
                    console.log('Error fetching records : ' + error.message);
                }
            }
        }catch(e){
            console.log('Error in changing the list View ::  ', e.stack);
        }
    }

    combineSameFilters() {
        const combinedData = {};
        for (const obj of this.filters) {
            const { fieldName, operator, value, type } = obj;
            // Check for LIKE or notLIKE operators and same field and operator
            if (["LIKE", "notLIKE"].includes(operator)) {
                const key = `${fieldName}-${operator}`;
                if (combinedData.hasOwnProperty(key)) {
                    combinedData[key].value = `${combinedData[key].value},${value}`;
                    combinedData[key].operator = operator.replace('LIKE', 'IN');
                } else {
                    combinedData[key] = { ...obj };
                }
            } else {
                combinedData[`${fieldName}-${operator}`] = obj;
            }
        }
        return Object.values(combinedData);
    }

    handleObjectChange(event){
        this.objectName = event.detail[0];
        // console.log('Updated Object is :: ', this.objectName);
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