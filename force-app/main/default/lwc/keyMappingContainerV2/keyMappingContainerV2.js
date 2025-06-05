import { LightningElement, api, track } from 'lwc';
import getFieldMappingKeys from '@salesforce/apex/KeyMappingController.getFieldMappingKeys';
import getGeneralFields from '@salesforce/apex/KeyMappingController.getGeneralFields';
import getMerginTemplateKeys from '@salesforce/apex/KeyMappingController.getMerginTemplateKeys';
import getAllContentVersionImgs from '@salesforce/apex/KeyMappingController.getAllContentVersionImgs';
import getChildObjects from '@salesforce/apex/KeyMappingController.getChildObjects';
import formattingFieldKeys from '@salesforce/apex/KeyMappingController.formattingFieldKeys';
import getSignatureInfo from '@salesforce/apex/KeyMappingController.getSignatureInfo';
import updateSignatureInfo from '@salesforce/apex/KeyMappingController.updateSignatureInfo';
import getCustomKeys from '@salesforce/apex/KeyMappingController.getCustomKeys';
import { errorDebugger } from 'c/globalPropertiesV2';

export default class KeyMappingContainerV2 extends LightningElement {

    @api objectName;
    @api saveButtonLabel;
    @api cancelButtonLabel;
    @api previewButtonLabel;
    @api templateType = 'Simple Template';

    tempId;
    @api get templateId(){return this.tempId};
    set templateId(value){ this.tempId = value };

    hideMergeTemplatesFor = ['Google Doc Template'];
    showFullHeightButtonFor = ['Simple Template'];
    showMaxSizeLimit = ['Simple Template'];
    // copyBase64AvailableFor = ['Google Doc Template'];
    copyBase64AvailableFor = [];

    @track field_Vs_KeyList = [];
    @track selectedObjectName;

    @track isMappingOpen = false;
    @track isMappingContainerExpanded;
    @track isMappingTabExpanded;

    @track searchFieldValue = '';

    @track relatedChildObjects = [];
    @track selectedChildObjectName;
    @track selectedCustomKey;
    @track selectedCustomKeyType = 'Field';
    @track selectedCustomKeyListField = '';
    @track selectedCustomKeyTableFields = [];
    @track selectedConditionalOperator = 'NV';
    @track isInverseCondition = false;
    @track selectedChildObjAPI;

    conditionalOperators = [
        { label: 'Not Void', value: 'NV' },
        { label: 'Equals', value: 'EQ' },
        { label: 'Not Equals', value: 'NE' },
        { label: 'Greater Than', value: 'GT' },
        { label: 'Greater Than or Equal To', value: 'GE' },
        { label: 'Less Than', value: 'LT' },
        { label: 'Less Than or Equal To', value: 'LE' }
    ];

    mappingTypeTabs = [
        {   label: 'Object Fields',        name: 'objectFields',
            helpText : 'Insert Base Object and Lookup (Related) Object\'s Fields in Template.',
            showCombobox : true, comboboxPlaceholder : 'Select Object...', showDescription : false,
            showSearchbar : true, searchBarPlaceHolder : 'Search Fields...', selected : true,
        },
        {   label: 'Custom Keys',     name: 'customKeys',
            helpText : 'Add Data From The Custom Keys Into The Template.',
            showCombobox : true, comboboxPlaceholder : 'Select Custom Key...', showDescription : true,
            showSearchbar : true, searchBarPlaceHolder : 'Search Custom Key Field...', selected : false,
        },
        {   label: 'Related Lists',  name: 'relatedListFields',
            helpText : 'Insert Related Lists (Child Object Records) In Template as a Table Format.',
            showCombobox : true, comboboxPlaceholder : 'Select Object...', showDescription : true , selected : false,
        },
        {   label: 'General Fields',        name: 'generalFields',
            helpText : 'Insert & Add Document Creation Date, Document Creation User Info, Organization Info, etc... In Template',
            showCombobox : true, comboboxPlaceholder : 'Select Object...',  showDescription : false,
            showSearchbar : true, searchBarPlaceHolder : 'Search General Fields...', selected : false,
        },
        {   label: 'Conditional Data',     name: 'conditionalData',
            helpText : 'Add Conditions into your template to display data dynamically based on conditions.', selected : false,
        },
        {   label: 'Merge Templates',      name: 'mergeTemplates',
            helpText : 'Merge Other Templates Into The Current Template',
            showSearchbar : true, searchBarPlaceHolder : 'Search Templates by Name...', selected : false,
        },
        {   label: 'Salesforce Images',     name: 'sfImages',
            helpText : 'Add Salesforce images Into The Template.',
            showSearchbar : true, searchBarPlaceHolder : 'Search Salesforce Images...', selected : false,
            showRefresh : true,
        },
        {   label: 'Signature',     name: 'signature',
            helpText : 'Add Signature into Your file by Mapping Signature Key in The Template.', selected : false,
        }
    ];

    @track activeMappingTabName = 'objectFields';
    @track selectedMappingType = this.mappingTypeTabs.find(ele =>  ele.name == this.activeMappingTabName);
    @track generalFieldTypes = [];
    @track selectedGeneralFieldType;
    @track generalFieldsToDisplay = [];
    @track otherActiveTempList = [];
    @track contentVersionImages = [];
    @track keysOfAllObjectsForTemplate = [];
    @track allCustomKeys = [];
    @track customKeysToDisplay = [];
    @track customKeyListOrTable = "";
    @track customKeyListSeparator = ', ';
    @track showIndexForTable = true;
    @track selectedFontSize = 12;
    @track cvIdVsImageSRC = {};
    @track contentVersionToDisplay = [];
    @track isExceedRelatedListLimit = false;
    maxRelatedLIstTableLimit = 10;
    @track isDataRefreshing = false;

    // Variables used for "Formatting Option"
    @track showFormatKeys = false;
    @track formatDefault = {};
    @track clickedFieldType;
    @track clickedFieldName;
    @track dateFormatKeys = [];
    @track timeFormatKeys = [];
    @track textFormatKeys = [];
    @track primeFormatKeys = [];
    @track subFormatKeys = [];
    @track isSubFormat = false;
    @track chosenFormat = {};
    @track trueValueReplacer = '';
    @track falseValueReplacer = '';
    @track disableRoundMode = false;
    toggleBtn = false;
    numberFormat = {}

    signatureAnyWhereLink = "https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000FguvFUAR";
    @track signatureSize;
    savedSignatureSize = this.signatureSize;
    customTimeout;

    dragIndex;
    lastGapTarget;
    lastPosition;

    /**
     * boolean to set showFulbrightButtonFor based on template type.
     */
    get showFullHeightButton(){ 
        return this.showFullHeightButtonFor.includes(this.templateType);
    };

    /**
     * Set Boolean for showFulbrightButtonFor based on template type.
     */
    get hideMergeTemplates(){ 
        return this.hideMergeTemplatesFor.includes(this.templateType);
    };

    /**
     * Set Tab Area based on Tab Selection By user..
     */
    get mappingTypeTabArea(){
        return {
            objectFields        :   this.activeMappingTabName == 'objectFields' ? true : false,
            relatedListFields   :   this.activeMappingTabName == 'relatedListFields' ? true : false,
            generalFields       :   this.activeMappingTabName == 'generalFields' ? true : false,
            mergeTemplates      :   this.activeMappingTabName == 'mergeTemplates' ? true : false,
            sfImages            :   this.activeMappingTabName == 'sfImages' ? true : false,
            signature           :   this.activeMappingTabName == 'signature' ? true : false,
            customKeys          :   this.activeMappingTabName == 'customKeys' ? true : false,
            conditionalData     :   this.activeMappingTabName == 'conditionalData' ? true : false,
        }
    }

    /**
     * Getter for determining if the combobox should be shown based on the active mapping tab.
     */
    get showCombobox() {
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.showCombobox;
    }

    /**
     * Getter for determining if the search bar should be shown based on the active mapping tab.
     */
    get showSearchBar(){
        let isNotCustomKeyField = this.activeMappingTabName == 'customKeys' && !this.customKeyType.isField ? false : true;
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.showSearchbar && isNotCustomKeyField;
    }

    /**
     * Getter for determining if the refresh button should be shown based on the active mapping tab.
     */
    get showRefreshButton(){
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.showRefresh;
    }

    /**
     * Getter for determining if the combobox placeholder based on the active mapping tab.
     */
    get objectComboPlaceHolder(){
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.comboboxPlaceholder;
    }

    /**
     * Getter for determining if the search bar placeholder based on the active mapping tab.
     */
    get searchBarPlaceHolder(){
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.searchBarPlaceHolder;
    }

    /**
     * Getter for determining if the combobox options based on the active mapping tab.
     */
    get comboBoxOptions(){
        if(this.activeMappingTabName == 'objectFields'){
            return this.relatedObjectList;
        }
        else if(this.activeMappingTabName == 'relatedListFields'){
            return this.relatedChildObjects;
        }
        else if(this.activeMappingTabName == 'generalFields'){
            return this.generalFieldTypes;
        }
        else if(this.activeMappingTabName == 'customKeys'){
            return this.customKeysToDisplay;
        }
        return [];
    }

    /**
     * Getter for determining if the selectedValue based on the active mapping tab to display on ui.
     */
    get selectedValue(){
        if(this.activeMappingTabName == 'objectFields'){
            return this.selectedObjectName;
        }
        else if(this.activeMappingTabName == 'relatedListFields'){
            return this.selectedChildObjectName;
        }
        else if(this.activeMappingTabName == 'generalFields'){
            return this.selectedGeneralFieldType;
        }
        else if(this.activeMappingTabName == 'customKeys'){
            return this.selectedCustomKey;
        }
        return null;
    }

    /**
     * Getter to set child table limit error message
     */
    get childTableLimitErrorMsg(){
        // return 'Related List Table Limit Exceed. You Can Not Insert More Then 10 Related List Tables.';
        return this.isExceedRelatedListLimit ? `Related List Table Limit Exceeded. You Can Not Insert More Then ${this.maxRelatedLIstTableLimit} Related List Tables.` : ''
    }

    /**
     * Getter to determine to show or not in combo box based on the active mapping tab.
     */
    get showComboDescription(){
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.showDescription;
    }


    /**
     * Getter to set format option based on clicked field type
     */
    get formateOptions(){
        return {
            isPrimaryFormateCombobox : this.clickedFieldType === 'DATETIME' || this.clickedFieldType === 'DATE' || this.clickedFieldType === 'TIME',
            isCheckboxFormate : this.clickedFieldType === 'CHECKBOX',
            isTextFormate  : this.clickedFieldType === 'TEXT' ,
            isNumberFormat : this.clickedFieldType === 'CURRENCY' || this.clickedFieldType === 'NUMBER' ,
        }
    }

    /**
     * Getter to set format help text based on clicked field type
     */
    get formatHelpText(){
        if(this.clickedFieldType == 'DATE'){
            return 'Select format for your Date Field';
        }
        else if(this.clickedFieldType == 'DATETIME'){
            return 'Select Date and Time Format for your DateTime Field';
        }
        else if(this.clickedFieldType == 'TIME'){
            return 'Select format for your Time Field';
        }
        else if(this.clickedFieldType == 'CHECKBOX'){
            return 'Set Display text based on checkbox status';
        }  
        else if(this.clickedFieldType == 'TEXT'){
            return 'Set Text Length and Text Case';
        }
        else if(this.clickedFieldType == 'CURRENCY' || this.clickedFieldType == 'NUMBER' || this.clickedFieldType == 'PERCENTAGE'){
            return `Format Options for ${this.clickedFieldType} field`;
        }
        return null;
    }

    /**
     * Getter to Enable / Disable Child Object table generation based on generated table number
     */
    get isChildObjTableDisable(){
        return (this.selectedChildObjectName && !this.isExceedRelatedListLimit) ? false : true;
    }

    /**
     * Getter to Enable/Disable signature update button
     */
    get isSignatureSetBtn(){
        return this.savedSignatureSize === this.signatureSize;
    }

    /**
     * Getter to show/hide image max size limit info
     */
    get isImgMaxSizeLimit(){
        return this.showMaxSizeLimit.includes(this.templateType);
    }


    get isGoogleDocTemplate(){
        return this.templateType === 'Google Doc Template';
    }

    get customKeyFields(){
        let keysToDisplay = this.customKeysToDisplay.find(ele => ele.value == this.selectedCustomKey)?.queriedFields || [];
        if(!this.selectedCustomKeyListField) this.selectedCustomKeyListField = keysToDisplay ? keysToDisplay[0]?.value : '';
        if(!this.selectedCustomKeyTableFields.length) this.selectedCustomKeyTableFields = keysToDisplay ? keysToDisplay.map(ele => ele.value) : [];
        let searchKey =  this.customKeyType.isField ? this.searchFieldValue?.trim().toLowerCase() : '';
        return searchKey ? keysToDisplay.filter(ele => ele?.name?.toLowerCase()?.includes(searchKey) || ele?.label?.toLowerCase()?.includes(searchKey)) : keysToDisplay;
    }

    get customKeyType(){
        return {
            isField: this.selectedCustomKeyType === 'Field' ? true : false,
            isList: this.selectedCustomKeyType === 'List' ? true : false,
            isTable: this.selectedCustomKeyType === 'Table' ? true : false
        }
    }

    get customKeyListField(){
        return `{{@CKLIST:${this.selectedCustomKey}.${this.selectedCustomKeyListField}:${this.customKeyListSeparator}}}`;
    }

    get customKeyTableField(){
        let fields = this.showIndexForTable ? ['INDEX'] : [];
        let fontSizeString = !isNaN(this.selectedFontSize) && this.selectedFontSize > 0 && !this.isGoogleDocTemplate ? `;${parseInt(this.selectedFontSize)}` : '';
        fields.push([...this.selectedCustomKeyTableFields]);
        return `{{@CKTABLE:${this.selectedCustomKey}:${fields.join(',')}${fontSizeString}}}`;
    }

    get conditionalDataKey(){
        return `{{@IF:${this.isInverseCondition ? '!' : ''}${this.selectedConditionalOperator}(${this.selectedConditionalOperator == 'NV' ? '[Value To Check]' : '[Value To Check],[Expected Value]'})|#|[Value If True]|#|[Value If False]}}`;
    }

    connectedCallback(){
        try {
            if(this.templateId){
                this.fetchFieldMapping();
                this.fetchChildObjects();
                this.fetchGeneralFields();
                this.fetchAllContentVersionImages();
                this.fetchFormatMappingKeys();
                this.fetchSignatureInfo();
            }
            if (typeof window !== 'undefined') {
                window.addEventListener('resize', this.resizeFunction);
            }

            if(this.hideMergeTemplates){
                const index = this.mappingTypeTabs.indexOf(this.mappingTypeTabs.find(ele => ele.name == 'mergeTemplates'));
                if(index !== -1) this.mappingTypeTabs.splice(index, 1);
            }
            else{
                this.fetchAllActiveTemps()
            }
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'connectedCallback', error, 'warn');
        }
    }

    renderedCallback(){
        if(this.isInit){
            this.resizeFunction();
            this.isInit = false;
        }

        if(!this.customTimeout){
            this.customTimeout = this.template.querySelector('c-custom-timeout');
        }
    }

    // Use Arrow Function...
    resizeFunction = () => {

    };

    /**
     * Fetches the field mapping data for the specified object.
     * 
     * This method makes an asynchronous call to retrieve field mapping keys for the given object.
     */
    fetchFieldMapping(){
        try {
            getFieldMappingKeys({sourceObjectAPI : this.objectName, getParentFields : true})
            .then(result => {
                this.keysOfAllObjectsForTemplate = result.fieldMappingsWithObj.flatMap(obj => obj.fieldMappings.map(field => field.key));
                this.isDataRefreshing = false;
                // console.log('getFieldMappingKeys result  : ', result);
                    if(result.isSuccess){
                        // Set... Base Object, Related Parent Object and It's Fields with mapping key
                        this.object_Label = result.objectLabelAPI.label;
                        var relatedObjectList = [];
                        var fieldMappingKeysList = [];
                        result.fieldMappingsWithObj.forEach(obj => {
                            relatedObjectList.push({label : obj.label, value: obj.name});
                            // if(!obj.label.includes('>')){
                            //     this.objectName = obj.name;
                            // }
                            obj.fieldMappings.forEach(ele => {
                                fieldMappingKeysList.push(ele.name);
                            })
                        });
                        this.relatedObjectList = JSON.parse(JSON.stringify(relatedObjectList));
                        this.fieldMappingsWithObj = result.fieldMappingsWithObj;
                        this.setMappingKeysForObjFields();
                        this.setMappingTab();
                    }
                    else{
                        errorDebugger('FieldMappingKeyV2', 'fetchFieldMapping', null, 'warn', `error in getFieldMappingKeys apex call : ${result.returnMessage}`);
                        this.showMessagePopup('Error', 'Error While Fetching Field Mapping Data', result.returnMessage);
                    }
                this.fetchCustomKeys();
            })
            .catch(error => {
                this.isDataRefreshing = false;
                errorDebugger('FieldMappingKeyV2', 'fetchFieldMapping', error, 'warn', `error in getFieldMappingKeys apex call `);
            })
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'fetchFieldMapping', error, 'warn');
        }
    }


    /**
     * Fetches child objects related to the source object.
     */
    fetchChildObjects(){
        try {
            getChildObjects({sourceObjectAPI : this.objectName})
            .then(result =>{
                this.isDataRefreshing = false;
                // console.log('getChildObjects result  : ', result);
                if(result.isSuccess){
                    result.fieldMappingsWithObj.forEach(ele =>{
                        this.relatedChildObjects.push({label : ele.label, value : ele.name, description : ele.additionalInfo, childObjApi : ele.objectAPI});
                    });
                    
                    this.relatedChildObjects.sort(function(a, b) {
                        if (a.label < b.label) return -1;
                        if (a.label > b.label) return 1;
                        return 0;
                    });
                }
                else{
                    errorDebugger('FieldMappingKeyV2', 'fetchChildObjects', null, 'warn', `error in getChildObjects apex call : ${result.returnMessage}`);
                }
            })
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'fetchChildObjects', error, 'warn');
        }
    }

    /**
     * Fetch General Field and its key
     * Creation Date, Creation user and organization keys are fetch throughout this apex call
     */
    fetchGeneralFields(){
        try {
            getGeneralFields()
            .then(result => {
                this.isDataRefreshing = false;
                var generalFieldTypes_temp = [];
                if(result.isSuccess == true && result.fieldMappingsWithObj){
                    result.fieldMappingsWithObj.forEach(ele => {
                        generalFieldTypes_temp.push({label : ele.label, value : ele.name, fieldMappings : ele.fieldMappings})
                    })
                    this.generalFieldTypes = JSON.parse(JSON.stringify(generalFieldTypes_temp));
                    this.setGeneralFieldsToDisplay();
                }
                else{
                    errorDebugger('FieldMappingKeyV2', 'fetchGeneralFields', null, 'warn', `error in fetchGeneralFields apex : ${result.returnMessage}`);
                }
            })
            .catch(error => {
                this.isDataRefreshing = false;
                errorDebugger('FieldMappingKeyV2', 'fetchGeneralFields', error, 'warn', `error in fetchGeneralFields apex `);
            })
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'fetchGeneralFields', error, 'warn');
        }
    }

    /**
     * Fetches all active templates and its key to merge other template into current template
     */
    fetchAllActiveTemps(){
        try {
            getMerginTemplateKeys({sourceObjectAPI : this.objectName, templateId : this.templateId})
            .then(result => {
                this.isDataRefreshing = false;
                if(result.isSuccess == true && result.fieldMappingsWithObj){
                        this.otherActiveTempList = result.fieldMappingsWithObj[0].fieldMappings;
                        this.setOtherMappingTemplates();
                }
                else{
                    errorDebugger('FieldMappingKeyV2', 'fetchAllActiveTemps', result, 'warn', `error in fetchAllActiveTemps apex  : ${result.returnMessage}`);
                }
            })
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'fetchAllActiveTemps', error, 'warn');
        }
    }

    /**
     * Fetch all Image from ContentVersion to add into template
     * Note : For Google Doc Template, we get ContentDownloadUrl from ContentDistribution as Google doc Only support public url
     * While : For Simple Template we get VersionDataUrl which is not public url
     */
    fetchAllContentVersionImages(){
        try {
            getAllContentVersionImgs({templateType : this.templateType})
            .then(result => {
                this.isDataRefreshing = false;
                // console.log('getAllContentVersionImgs result => ', result);
                if(result.isSuccess == true){
                    this.contentVersionImages = result.cdImages;
                    // this.cvIdVsImageSRC = result.cvIdVsImageSRC;
                    this.contentVersionImages.forEach(ele => {
                        ele['fileSize'] = ele.ContentVersion.ContentSize + ' Bytes';
                         if (ele.ContentVersion.ContentSize < 1000000) {  
                            ele['fileSize'] =  (ele.ContentVersion.ContentSize / 1000).toFixed(2) + ' KB';  
                        } else if (ele.ContentVersion.ContentSize < 1000000000) {  
                            ele['fileSize'] = (ele.ContentVersion.ContentSize / 1000000).toFixed(2) + ' MB';  
                        } else {  
                            ele['fileSize'] = (ele.ContentVersion.ContentSize / 1000000000).toFixed(2) + ' GB';  
                        } 
                        ele.Title = ele.ContentVersion.Title;
                        ele.FileExtension = ele.ContentVersion.FileExtension;
                        ele.FileType = ele.ContentVersion.FileType;
                        ele.ContentSize = ele.ContentVersion.ContentSize;
                        ele.imageSRC = ele.ContentDownloadUrl;
                    });
                    this.setContVerImgToDisplay();
                }
                else{
                    errorDebugger('FieldMappingKeyV2', 'fetchAllContentVersionImages', result, 'warn', `error in getAllContentVersionImgs Apex : ${result.returnMessage}`)
                }
            })
            .catch(error => {
                this.isDataRefreshing = false;
                errorDebugger('FieldMappingKeyV2', 'fetchAllContentVersionImages', error, 'warn')
            })
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'fetchAllContentVersionImages', error, 'warn')
        }
    }

    /**
     * Fetch all formatting field to set formatting for date, time , datetime, text, checkbox, number, currency and percentage field
     */
    fetchFormatMappingKeys(){
        try {
            formattingFieldKeys()
            .then(result => {
                this.isDataRefreshing = false;
                // console.log('formattingFieldKeys result => ', result);
                if(result.isSuccess == true){
                    if(result.fieldFormatting && result.fieldFormatting.length){
                        this.dateFormatKeys = result.fieldFormatting.find(ele => ele.formatType == 'DATE').fieldMappings;
                        this.timeFormatKeys = result.fieldFormatting.find(ele => ele.formatType == 'TIME').fieldMappings;
                        this.textFormatKeys = result.fieldFormatting.find(ele => ele.formatType == 'TEXT').fieldMappings;
                        this.signatureKey = result.signatureKey;
                    }
                }
                else{
                    errorDebugger('FieldMappingKeyV2', 'fetchFormatMappingKeys', null ,'warn', `Error in ${result.returnMessage}`);
                }
            })
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'fetchFormatMappingKeys', error ,'warn');
        }
    }

    /**
     * Method to fetch signature size stored in template record field.
     */
    fetchSignatureInfo(){
        try {
            getSignatureInfo({templateId : this.templateId})
            .then(result => {
                this.isDataRefreshing = false;
                this.signatureSize = Math.max(result, 1);               // To avoid value lesser than 1
                this.savedSignatureSize = this.signatureSize;
            })
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'fetchSignatureInfo', error ,'warn');
        }
    }

    /**
     * Method to fetch all the custom keys available
     */
    fetchCustomKeys(){
        try {
            getCustomKeys()
            .then(result => {
                this.allCustomKeys = result.map(item => ({
                    ...item,
                    label: item.MVDG__Custom_Key_Name__c,
                    value: item.MVDG__Custom_Key_Name__c,
                    description: item.MVDG__Description__c,
                    parentFieldKeys: item.MVDG__Parent_Keys__c?.replaceAll(' ', '')?.split(','),
                    queriedFields: item.MVDG__Queried_Fields__c?.split(',')
                        .map(field => {
                            let [label, name, type] = field?.split(':').map(s => s.trim());
                            let key = `{{@CK:${item.MVDG__Custom_Key_Name__c}.${name}}}`;
                            let value = name;
                            let description = name;
                            let isFormatReq = (['DATE','DATETIME','TIME','BOOLEAN','STRING','INTEGER','DOUBLE','CURRENCY','PERCENT'].includes(type)) ? true : false;
                            return { label, name, value, description, key, type, isFormatReq };
                        })
                }));
                this.customKeysToDisplay = this.allCustomKeys.filter(ck => !ck?.parentFieldKeys?.length || ck?.parentFieldKeys?.every(key => this.keysOfAllObjectsForTemplate.includes(key)));
            })
            .catch(error => {
                errorDebugger('FieldMappingKeyV2', 'fetchCustomKeys > getCustomKeys', error ,'warn');
            })
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'fetchCustomKeys', error ,'warn');
        }
    }

    /**
     * Sets the active mapping tab based on the user click triggered.
     * Adds 'selected' class to the active tab and removes it from other tabs to set Css of active tab.
     * Calls handleKeySearch method after updating the active tab.
     * 
     * @param {Event} event - The event object triggered by the user action.
     */
    setMappingTab(event){
        try {
            event?.stopPropagation();
            if(event && event.currentTarget && this.activeMappingTabName !== event.currentTarget.dataset.name){

                // clear combo-box search value
                this.template.querySelector('[data-combox="relatedObj"]')?.clearSearch();

                this.activeMappingTabName = event.currentTarget.dataset.name;

                // To set css Property of tab selector...
                this.mappingTypeTabs.forEach(ele => {
                    ele.selected = ele.name === this.activeMappingTabName;
                })
                
                var index = this.mappingTypeTabs.indexOf(this.mappingTypeTabs.find(ele => ele.name == this.activeMappingTabName));
                this.selectedMappingType = this.mappingTypeTabs[index];                 // To set label of selected tab...
    
                this.handleKeySearch();
            }
            

        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'setMappingTab', error ,'warn');
        }
    }

    handleCustomKeyToggle(event){
        try {
            this.selectedCustomKeyType = event.currentTarget.name;
        } catch (e) {
            errorDebugger('FieldMappingKeyV2', 'handleCustomKeyToggle', e ,'warn');
        }
    }

    handleCustomKeyListSeparator(){
        try {
            this.customKeyListSeparator = this.customKeyListSeparator ? this.customKeyListSeparator : ', ';
        } catch (e) {
            errorDebugger('FieldMappingKeyV2', 'handleCustomKeyListSeparator', e ,'warn');
        }
    }

    handleCustomKeyListField(event){
        try {
            let type = event?.currentTarget?.dataset?.type;
            if(type == 'field'){
                this.selectedCustomKeyListField = event?.detail[0];
            } else if( type == 'separator'){
                this.customKeyListSeparator = event?.currentTarget?.value;
            }
        } catch (e) {
            errorDebugger('FieldMappingKeyV2', 'handleCustomKeyListField', e ,'warn');
        }
    }

    handleCustomKeyTableField(event){
        try {
            let type = event?.currentTarget?.dataset?.type;
            let previousValue = this.selectedCustomKeyTableFields[0];
            if(type == 'field'){
                if(event?.detail?.length > 0){
                    this.selectedCustomKeyTableFields = event?.detail;
                }else{
                    this.selectedCustomKeyTableFields = [previousValue];
                    this.dispatchEvent(new CustomEvent('showtoast',{ detail: {
                        status: 'warning',
                        title: 'Table can\'t be empty!',
                        message: 'There should be at least one column to display in table.'
                    }}))
                }
            } else if( type == 'index'){
                this.showIndexForTable = event?.currentTarget?.checked;
            } else if( type == 'fontSize'){
                this.selectedFontSize = event?.currentTarget?.value;
            }
        } catch (e) {
            errorDebugger('FieldMappingKeyV2', 'handleCustomKeyTableField', e ,'warn');
        }
    }

    /**
     * Generic method to call when user select any option from Object fields, child objects or general Field,
     * Set Mapping keys to display based on selection
     * @param {*} event 
     */
    handleOptionSelect(event){
        try {
            if(this.activeMappingTabName == 'objectFields'){
                this.handleRelatedObjSelect(event);
            }
            else if(this.activeMappingTabName == 'relatedListFields'){
                this.handleChildObjSelection(event);
            }
            else if(this.activeMappingTabName == 'generalFields'){
                this.handleGeneralFieldTypeSelection(event);
            }
            else if(this.activeMappingTabName == 'customKeys'){
                this.handleCustomKeySelection(event);
            }
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'handleOptionSelect', error ,'warn');
        }
    }

    /**
     * Set mapping key to display when user select any source or its related object.
     * This Method call from 'handleOptionSelect',
     * @param {*} event 
     */
    handleRelatedObjSelect(event){
        try {
            if(event.detail.length){
                this.selectedObjectName = event.detail[0];
            }
            else{
                this.selectedObjectName = null;
            }
            this.setMappingKeysForObjFields();
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'handleRelatedObjSelect', error ,'warn');
        }
    }

    /**
     * Set selectedChildObjAPI and enable generate table button based on it to generate child object table
     * This Method call from 'handleOptionSelect'.
     * @param {*} event 
     */
    handleChildObjSelection(event){
        try {
            if(event.detail && event.detail.length){
                this.selectedChildObjectName = event.detail[0];
                this.selectedChildObjAPI = this.relatedChildObjects.find(ele => ele.value == event.detail[0]).childObjApi;
            }
            else{
                this.selectedChildObjectName = null;
                this.selectedChildObjAPI = null;
            }
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'handleChildObjSelection', error ,'warn');
        }
    }

    /**
     * Set mapping key to display when user select any general field type.
     * This Method call from 'handleOptionSelect'.
     * @param {*} event 
     */
    handleGeneralFieldTypeSelection(event){
        try {
            this.selectedGeneralFieldType = event.detail[0];
            this.setGeneralFieldsToDisplay();
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'handleGeneralFieldTypeSelection', error ,'warn');
        }
    }

    handleCustomKeySelection(event){
        try {
            this.selectedCustomKeyListField = null;
            this.selectedCustomKeyTableFields = [];
            this.selectedCustomKey = event.detail[0];
        } catch (e) {
            errorDebugger('FieldMappingKeyV2', 'handleCustomKeySelection', e ,'warn');
        }
    }

    handleConditionConfig(event){
        try {
            let type = event?.target?.dataset?.type;
            if(type == 'operator'){
                this.selectedConditionalOperator = event.detail[0] ?? this.selectedConditionalOperator;
            }else if(type == 'inverse'){
                this.isInverseCondition = event?.target?.checked;
            }
        } catch (e) {
            errorDebugger('FieldMappingKeyV2', 'handleConditionConfig', e ,'warn');
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
            const arr = [...this.selectedCustomKeyTableFields];
            const [moved] = arr.splice(from, 1);
            // adjust insertion index if we removed earlier in array
            const insertAt = (to > from) ? to - 1 : to;
            arr.splice(insertAt, 0, moved);
            this.selectedCustomKeyTableFields = arr;
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

    /**
     * Generic method which triggers when user search from searchbar.
     * this will for all tab on which search bar is available.
     * @param {*} event 
     */
    handleKeySearch(event){
        try {
            this.searchFieldValue = event ? event.target.value : null;
            if(this.activeMappingTabName == 'objectFields'){
                this.setMappingKeysForObjFields();
            }
            else if(this.activeMappingTabName == 'relatedListFields'){
                null;
            }
            else if(this.activeMappingTabName == 'generalFields'){
                this.setGeneralFieldsToDisplay();
            }
            else if(this.activeMappingTabName == 'mergeTemplates'){
                this.setOtherMappingTemplates()
            }
            else if(this.activeMappingTabName == 'sfImages'){
                this.setContVerImgToDisplay();
            }
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'handleKeySearch', error ,'warn');
        }
    }

    /**
     * refresh Data when click on button
     */
    refreshData(){
        try {
            this.isDataRefreshing = true;
            if(this.activeMappingTabName === 'sfImages' ){
                this.fetchAllContentVersionImages()
            }
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'refreshData', error ,'warn');
        }
    }

    /**
     * Method to organize list of mapping keys of source object's and its related object's fields to display on ui.
     * This method run each time when user search for field from 'Object Field' tab
     */
    setMappingKeysForObjFields(){
        try {
            this.field_Vs_KeyList = this.selectedObjectName ? 
                                    this.fieldMappingsWithObj.find(ele =>  ele.name === this.selectedObjectName).fieldMappings :
                                    this.fieldMappingsWithObj.find(ele =>  ele.name === this.objectName).fieldMappings ;

            // If Search value is not null, filter Field_Vs_KeysList based on search value...
            if(this.searchFieldValue !== undefined && this.searchFieldValue !== null && this.searchFieldValue != ''){
                this.field_Vs_KeyList = this.field_Vs_KeyList.filter((ele) => {
                    return ele.label.toLowerCase().includes(this.searchFieldValue.toLowerCase()) || ele.key.toLowerCase().includes(this.searchFieldValue.toLowerCase());
                })
            }

            this.field_Vs_KeyList = this.sortFormateKeys(this.field_Vs_KeyList, 'label');

        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'setMappingKeysForObjFields', error ,'warn');
        }
    }

    /**
     * Method to organize list of mapping keys of 'General Fields' to display on ui.
     * This method run each time when user search for field from 'General Field' tab
     */
    setGeneralFieldsToDisplay(){
        try {
            this.generalFieldsToDisplay = this.selectedGeneralFieldType ? this.generalFieldTypes.find(ele => ele.value == this.selectedGeneralFieldType).fieldMappings : this.generalFieldTypes[0].fieldMappings;

            if(this.searchFieldValue){
                this.generalFieldsToDisplay = this.generalFieldsToDisplay.filter((ele) => {
                    return ele.label.toLowerCase().includes(this.searchFieldValue?.toLowerCase()) || ele.key.toLowerCase().includes(this.searchFieldValue?.toLowerCase());
                });
            }

            this.generalFieldsToDisplay = this.sortFormateKeys(this.generalFieldsToDisplay, 'label');
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'setGeneralFieldsToDisplay', error ,'warn');
        }
    }


    /**
     * Method to organize list of mapping keys 'Merge Template Keys' to display on ui.
     * This method run each time when user search for keys from 'Merge Template' tab
     */
    setOtherMappingTemplates(){
        try {
            this.otherActiveTempToDisplay = this.otherActiveTempList;
            if(this.searchFieldValue){
                this.otherActiveTempToDisplay = this.otherActiveTempList.filter((ele) => {
                    return ele.label.toLowerCase().includes(this.searchFieldValue?.toLowerCase()) || ele.key.toLowerCase().includes(this.searchFieldValue?.toLowerCase());
                })
            }

            this.otherActiveTempToDisplay = this.sortFormateKeys(this.otherActiveTempToDisplay, 'label');

        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'setOtherMappingTemplates', error ,'warn');
        }
    }

    /**
     * Method to organize list of Salesforce Images to display on ui.
     * This method run each time when user search for salesforce images from 'Merge Template' tab
     */
    setContVerImgToDisplay(){
        try {
            this.contentVersionToDisplay = this.contentVersionImages;

            if(this.searchFieldValue){
                this.contentVersionToDisplay = this.contentVersionImages.filter((ele) => {
                    return ele.Title.toLowerCase().includes(this.searchFieldValue.toLowerCase()) || ele.FileType.toLowerCase().includes(this.searchFieldValue.toLowerCase())
                })
            }

            this.contentVersionToDisplay = this.sortFormateKeys(this.contentVersionToDisplay, 'Title');
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'setContVerImgToDisplay', error ,'warn');            
        }
    }

    /**
     * Method to Increase/Decrease height of Mapping key Area..
     */
    toggleMappingTableHeight(){
        try {
            const mergingTypeSelection = this.template.querySelector('.mergingTypeSelection');
            const selectedTab_Outer = this.template.querySelector('.selectedTab_Outer');
            const buttonSection = this.template.querySelector('.buttonSection');
            if(this.isMappingTabExpanded){
                this.isMappingTabExpanded = false;
                mergingTypeSelection.style = ``;
                selectedTab_Outer.style = ``;
                buttonSection.style = ``;
            }
            else{
                this.isMappingTabExpanded = true;
                mergingTypeSelection.style = `max-height : 0px; overflow : hidden;`;
                selectedTab_Outer.style = `margin-top : -2.25rem`;
                buttonSection.style = `margin : 0px; width : 100%; border-radius : 0px; max-height: 3.25rem;`;
            }
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'toggleMappingTableHeight', error ,'warn');            
        }
    }


    /**
     * Method to show/hide the Mapping container
     */
    showHideMappingContainer(){
        try {
            this.isMappingOpen = !this.isMappingOpen;
            var toggleFieldMapping =  this.template.querySelector('.toggleFieldMapping');
            if(toggleFieldMapping){
                toggleFieldMapping.style = this.isMappingOpen ? `width : 0px !important; padding: 0px; opacity : 0;` : '';
            }
    
            if(this.isMappingOpen){
                this.template.host.classList.add('openFieldMapping');
            }
            else{
                this.template.host.classList.remove('openFieldMapping');
            }
            // this.dispatchEvent(new CustomEvent('togglemapping'));
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'showHideMappingContainer', error ,'warn');            
        }
    }

    /**
     * API Method to Show/Hide Mapping container,
     * This method trigged from parent component to show and hide key Mapping Container based on state.
     * @param {*} state 
     */
    @api toggleMappingContainer(state){
        try {
            this.toggleBtn = state;
            var toggleFieldMapping =  this.template.querySelector('.toggleFieldMapping');
            toggleFieldMapping.style = this.isMappingOpen ? `width : 0px !important; padding: 0px; opacity : 0;` : '';
    
            // add and remove floating CSS for container as per requirement to make container slider....
            if(state){
                this.template.host.classList.add('floatContainer');
            }
            else{
                this.template.host.classList.remove('floatContainer');
            }
            this.setToggleBtnVisibility();
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'toggleMappingContainer', error ,'warn');            
        }
    }

    /**
     * Method to show/hide key Mapping Toggle button
     */
    setToggleBtnVisibility(){
        var toggleFieldMapping =  this.template.querySelector('.toggleFieldMapping');
        if(window.innerWidth > 1350){
            if(this.toggleBtn) toggleFieldMapping?.classList.add('show');
            else toggleFieldMapping.classList.remove('show');
        }
        else{
            toggleFieldMapping && toggleFieldMapping.classList.add('show');
        }
    }

    /**
     * Method to Increase/Decrease height of Mapping key container..
     */
    toggleMappingContainerHeight(){
        this.isMappingContainerExpanded = !this.isMappingContainerExpanded
        this.dispatchEvent(new CustomEvent('fullheight'));
    }

    /**
     * Method to copy mapping key and show animation on copy button click
     * @param {*} event 
     */
    handleCopyFieldKey(event){
        try {
            event.stopPropagation();
            var fieldName = event.currentTarget.dataset.fieldname;
            var fieldKey = event.currentTarget.dataset.fieldkey;

            const textarea = document.createElement('textarea');
            textarea.value = fieldKey;
            document.body.appendChild(textarea);
            textarea.select();

            navigator.clipboard.write([
                new ClipboardItem({
                    // 'text/html': new Blob([span.outerHTML], { type: 'text/html' }),
                    'text/plain': new Blob([textarea.value], { type: 'text/plain' })
                })
            ]);
            document.body.removeChild(textarea); 

            const fieldKeyTD = this.template.querySelectorAll(`[data-name="fieldTD"]`);
            fieldKeyTD.forEach(ele => {
                if(ele.dataset.fieldname == fieldName){
                    ele.classList.add('copied');
                    // setTimeout(() => {
                    //     ele.classList.remove('copied');
                    // }, 1001);

                    this.customTimeout?.setCustomTimeoutMethod(() => {
                        ele.classList.remove('copied');
                    }, 1001);
                }
                else{
                    ele.classList.remove('copied');
                }
            });

        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'handleCopyFieldKey', error ,'warn');            
        }
    }
    

    // ==== ==== ==== Field Formatting Methods -- START -- ==== ==== ====

    /**
     * Method Set formatting option based on field Type
     * @param {*} event 
     */
    setFormatKeyList(event){
        try {
            var fieldName = event.currentTarget.dataset.fieldname;
            var fieldType = event.currentTarget.dataset.fieldtype;
            var fieldKey = event.currentTarget.dataset.fieldkey;

            this.showFormatKeys = true;

            this.formatDefault = {label : 'Salesforce Default', name : fieldName, value : fieldName, key : fieldKey};

            // this.clickedFieldType = fieldType == 'BOOLEAN' ? 'CHECKBOX' : fieldType;
            switch(fieldType){
                case 'BOOLEAN': this.clickedFieldType = 'CHECKBOX';
                break;

                case 'STRING' : this.clickedFieldType = 'TEXT';
                break;

                case 'INTEGER' : this.clickedFieldType = 'NUMBER';
                break;

                case 'DOUBLE' : this.clickedFieldType = 'NUMBER';
                break;

                case 'PERCENT' : this.clickedFieldType = 'PERCENTAGE';
                break;

                default : this.clickedFieldType = fieldType;
            }

            if(this.clickedFieldType == 'DATE'){
                this.primeFormatKeys = JSON.parse(JSON.stringify(this.dateFormatKeys));
                this.primeFormatKeys.forEach(ele =>{
                    ele['value'] = ele.name;
                    ele.name = fieldName+' '+ele.formatKey;
                    ele['key'] = fieldKey.replace(fieldName, fieldName+' '+ele.formatKey);
                });
            }
            else if(this.clickedFieldType == 'DATETIME'){
                this.primeFormatKeys = JSON.parse(JSON.stringify(this.dateFormatKeys));
                // For DateTime Field Type... Set Date as prime Format
                this.primeFormatKeys.forEach(ele =>{
                    ele['value'] = ele.name;
                    ele.name = fieldName+' '+ele.formatKey;
                    ele['key'] = fieldKey.replace(fieldName, fieldName+' '+ele.formatKey);
                });

                // For DateTime Field Type... Set Time as sub Format
                this.subFormatKeys = JSON.parse(JSON.stringify(this.timeFormatKeys));
                this.subFormatKeys.forEach(ele =>{
                    ele['value'] = ele.name;
                });

                this.isSubFormat = true;
            }
            else if(this.clickedFieldType == 'TIME'){
                this.primeFormatKeys = JSON.parse(JSON.stringify(this.timeFormatKeys));
                this.primeFormatKeys.forEach(ele =>{
                    ele['value'] = ele.name;
                    ele.name = fieldName+' '+ele.formatKey;
                    ele['key'] = fieldKey.replace(fieldName, fieldName+' '+ele.formatKey);
                });
            }else if(this.clickedFieldType == 'TEXT'){
                this.primeFormatKeys = JSON.parse(JSON.stringify(this.textFormatKeys));
                this.primeFormatKeys.forEach(ele =>{
                    ele['value'] = ele.name;
                    ele.name = fieldName+' '+ele.formatKey;
                    ele['key'] = fieldKey.replace(fieldName, fieldName+' '+ele.formatKey);
                });
            }
            
            this.chosenFormat = JSON.parse(JSON.stringify(this.formatDefault));           // for Deep clone...

        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'setFormatKeyList', error ,'warn');            
        }
    }

    /**
     * Method to set Prime Format option 
     * @param {*} event 
     */
    handlePrimeFormat(event){
        try {
            if(event.detail && event.detail.length){
                this.chosenFormat = JSON.parse(JSON.stringify(this.primeFormatKeys.find(ele => ele.value == event.detail[0])));
            }
            else{
                this.chosenFormat = JSON.parse(JSON.stringify(this.formatDefault));
            }

            if(this.isSubFormat){
                this.updateChosenFormat();
            }
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'handlePrimeFormat', error ,'warn');            
        }
    }

    /**
     * Method to Set Sub Format option for data time field
     * @param {*} event 
     */
    handleSubFormat(event){
        try {
            if(event.detail && event.detail.length){
                this.chosenSubFormat = event.detail[0];
            }
            else{
                this.chosenSubFormat = null;
            }
            this.updateChosenFormat();
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'handleSubFormat', error ,'warn');            
        }
    }

    handleTextCase(event) {
        try {
            const caseVal = event.detail?.[0]?.trim();
            let key = this.chosenFormat.key;

            // Extract content between {{ and }}
            const match = key.match(/{{(.*?)}}/);
            if (!match) return;

            let inner = match[1];

            // Extract or prepare formatting block
            let innerParts = inner.split('*');
            let formatRaw = innerParts.length > 1 ? innerParts[1] : '';
            let formatParts = formatRaw.split(';').map(p => p.trim()).filter(p => !!p);

            // Remove any existing case formats (anything not starting with L:)
            formatParts = formatParts.filter(p => p.startsWith('L:'));

            if (caseVal) {
                formatParts.push(caseVal.toUpperCase());
            }

            // Build new key
            this.chosenFormat.key = key.split('}}')[0]?.split('*')[0] + (formatParts.join(';') ? `*${formatParts.join(';')}*}}` : '}}');

            if (this.isSubFormat) {
                this.updateChosenFormat();
            }

        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'handleTextCase', error, 'warn');
        }
    }

    /**
     * Once user select ay format type, update existing mapping key bases on formate type.
     */
    updateChosenFormat(){
        // Update format key in case of sub formatting (i.e. Date and Time)
        try {
            if(this.chosenFormat.key.includes('*')){
                // Update format key when key includes prime format key
                if(this.chosenSubFormat){
                    this.chosenFormat.key = this.chosenFormat.key.replace(/(?<=\*)(.*?)(?=\*)/g, this.chosenFormat.value +' '+ this.chosenSubFormat);
                }
                else{
                    // remove chosenSubFormat from format key when user remove sub format key...
                    this.chosenFormat.key = this.chosenFormat.key.replace(/(?<=\*)(.*?)(?=\*)/g, this.chosenFormat.value);
                }
            }
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'updateChosenFormat', error ,'warn');            
        }
    }

    /**
     * Set formatting into Mapping key for checkbox field.
     * @param {*} event 
     */
    setCheckBoxFormat(event){
        try {
            this.trueValueReplacer = event.currentTarget.dataset.name == 'true' ? event.target.value : this.trueValueReplacer;
            this.falseValueReplacer = event.currentTarget.dataset.name == 'false' ? event.target.value : this.falseValueReplacer;

            if(this.trueValueReplacer != '' || this.falseValueReplacer != ''){
                // if valueReplace is empty, set default true or false accordingly.
                var trueValueReplacer = this.trueValueReplacer != '' ? this.trueValueReplacer : 'true';
                var falseValueReplacer = this.falseValueReplacer != '' ? this.falseValueReplacer : 'false';
                if(this.chosenFormat.key.includes('*')){
                    this.chosenFormat.key = this.chosenFormat.key.replace(/(?<=\*)(.*?)(?=\*)/g,  trueValueReplacer +'/'+ falseValueReplacer)
                }
                else{
                    this.chosenFormat.key = this.chosenFormat.key.replace(this.chosenFormat.name, this.chosenFormat.name + ' *' + trueValueReplacer +'/'+ falseValueReplacer +'*')
                }
            }
            else{
                // when user clear both input.. set format to default one...
                if(this.chosenFormat.key.includes('*')){
                    this.chosenFormat.key = this.formatDefault.key;
                }
            }
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'setCheckBoxFormat', error ,'warn');            
        }
    }

    /**
     * Set formatting into mapping key  for Text field.
     * @param {*} event 
     */
    setTextFormat(event) {
        try {
            const length = event.target.value?.trim();
            let key = this.chosenFormat.key;

            // Extract content between {{ and }}
            const match = key.match(/{{(.*?)}}/);
            if (!match) return;

            let inner = match[1];

            // Extract or prepare formatting block
            let innerParts = inner.split('*');
            let formatRaw = innerParts.length > 1 ? innerParts[1] : '';
            let formatParts = formatRaw.split(';').map(p => p.trim()).filter(p => !!p);

            // Remove any previous L: format
            formatParts = formatParts.filter(p => !p.startsWith('L:'));

            if (length && parseInt(length) > 0) {
                formatParts.push(`L:${parseInt(length)}`);
            }

            // Build new key
            this.chosenFormat.key = key.split('}}')[0]?.split('*')[0] + (formatParts.join(';') ? `*${formatParts.join(';')}*}}` : '}}');
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'setTextFormat', error, 'warn');
        }
    }

    /**
     * Set Formatting key into mapping key for Number field.
     * @param {*} event 
     */
    setNumberFormat(event){
        try {
            const action = event.currentTarget.dataset.action;

            // ... When Method called from format toggle btn ...
            if(action == 'format'){
                if(event.target.checked == true){
                    this.numberFormat['F'] = 'yes';
                }
                else{
                    delete this.numberFormat['F'];
                }
            }
            // ... When Method called from Decimal Places Input  ...
            else if(action == 'decimalPlaces'){
                // SET negative value to Zero...
                if(event.target.value < 0){
                    event.target.value = 0;
                }
                else if(event.target.value > 32){
                    event.target.value = 32;
                }

                // ...Enable / Disable round Mode option based on decimal places value...
                const roundMode = this.template.querySelector(`[data-action="roundMode"]`);
                const roundModeText = this.template.querySelector('[data-text="roundMode"]');

                if(event.target.value != '' && event.target.value != null){
                    this.numberFormat['dP'] = event.target.value;

                    if(roundMode){
                        roundMode.removeAttribute('disabled');
                        roundModeText.classList.remove('roundMode');

                        // add round Mode with decimal places if rM value is not available and value is not none...
                        if(!Object.prototype.hasOwnProperty.call(this.numberFormat, 'rM') && roundMode.value != 'none'){
                            this.numberFormat['rM'] = roundMode.value;
                        }
                    }
                }
                else{
                    delete this.numberFormat['dP'];
                    delete this.numberFormat['rM'];        // remove round Mode if decimal places is null

                    if(roundMode){
                        // if decimal places is not zero... then disable round mode selection as we don't need round node in this case...
                        roundMode.setAttribute('disabled', 'true');
                        roundModeText.classList.add('roundMode');
                    }
                }
            }

            // ... When Method called from Round Mode selection ...
            else if(action == 'roundMode'){
                if(event.target.value != 'none' && event.target.value != '' && event.target.value != null){
                    this.numberFormat['rM'] = event.target.value;
                }
                else{
                    delete this.numberFormat['rM'];
                }
            }

            // ... Update mapping Key ...
            if(Object.keys(this.numberFormat).length){
                const str1 = JSON.stringify(this.numberFormat).replaceAll('"', '');
                const str2 = str1.replaceAll('{', '');
                const str3 = str2.replaceAll('}', ',');

                if(this.chosenFormat.key.includes('*')){
                    this.chosenFormat.key = this.chosenFormat.key.replace(/(?<=\*)(.*?)(?=\*)/g,  `${str3}`);
                }
                else{
                    this.chosenFormat.key = this.chosenFormat.key.replace(this.chosenFormat.name, this.chosenFormat.name + ` *${str3}*`);
                }
            }
            else{
                this.chosenFormat.key = this.formatDefault.key;
            }
            
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'setNumberFormat', error ,'warn');            
        }
    }

    /**
     * Close Key Popover on user action.
     * @param {*} event 
     */
    closeKeyPopover(event){
        try {
            event.stopPropagation();
            this.primeFormatKeys = null;
            this.showFormatKeys = false;
            this.isSubFormat = false;
            this.numberFormat = {};
            this.chosenFormat = {};

        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'closeKeyPopover', error ,'warn');            
        }
    }
    // ==== ==== ==== Field Formatting Methods -- END -- ==== ==== ====

    /**
     * generic method to stop event bubbling from child element to parent
     * @param {*} event 
     */
    stopPropagation(event){
        event.stopPropagation();
    }

    /**
     * Method to copy salesforce images as HTML tab
     * @param {*} event 
     */
    copySFImgAsHTMl(event){
        try {
            event.stopPropagation();

            const imgId = event.currentTarget.dataset.id;
 
            const ImgUrl = this.contentVersionImages.find(ele => ele.Id == imgId)?.imageSRC;

            this.copyImage(ImgUrl, imgId);

        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'copySFImgAsHTMl', error ,'warn');            
        }
    }

    /**
     * Copy Image using navigator clipboard.
     * @param {*} imgUrl 
     * @param {*} imgID 
     */
    copyImage(imgUrl, imgID){
        try {

            // ==> If template Type is set to copy image as base64...
            // if(this.copyBase64AvailableFor?.includes(this.templateType)){

            //     const imageBlob = new Blob([this.getArrayBuffer(atob(imgUrl))], { type: 'image/png' });

            //     navigator.clipboard.write([
            //         new ClipboardItem({
            //             'image/png' : imageBlob
            //         })
            //     ]);
            // }
            // ==> else copy image as url...
            // else{
                const img = document.createElement('img');
                img.style.width = '75%';
                img.setAttribute('src', imgUrl);
                img.setAttribute('data-origin', 'sf');
                document.body.appendChild(img);
                
                navigator.clipboard.write([
                    new ClipboardItem({
                        'text/html': new Blob([img.outerHTML], { type: 'text/html' }),
                    })
                ]);
                
                document.body.removeChild(img); 
            // }

            const mappingImgContainer = this.template.querySelectorAll(`.mappingImgContainer`);
            mappingImgContainer.forEach(ele => {
                if(ele.dataset.imgid == imgID){
                    ele.classList.add('copied');
                    // setTimeout(() => {
                    //     ele.classList.remove('copied');
                    // }, 1001);

                    this.customTimeout?.setCustomTimeoutMethod(() => {
                        ele.classList.remove('copied');
                    }, 1001);
                }
                else{
                    ele.classList.remove('copied');
                }
            });
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'copyImage', error ,'warn');            
        }
    }

    /**
     * Method to convert raw(encrypted binary) data into base64.
     * @param {*} data 
     * @returns 
     */
    getArrayBuffer(data){
        var len = data.length,
        ab = new ArrayBuffer(len),
        u8 = new Uint8Array(ab);

        while (len--) u8[len] = data.charCodeAt(len);
        return ab;
    };

    /**
     * Method to open child object table generation popup
     */
    openChildSelection(){
        this.dispatchEvent(new CustomEvent('opengenchildtable', {detail : {
            relationshipName : this.selectedChildObjectName,
            childObjAPI : this.selectedChildObjAPI,
            label : this.relatedChildObjects.find(ele => ele.value == this.selectedChildObjectName)?.label,
        }}));
    }

    /**
     * Set highted Selection color on mapping key element's text
     * @param {*} event 
     */
    setHighlightedSelection(event){
        try {
            // ASet highted Selection color on mapping key element's text
            var range = document.createRange();
            range.selectNode(event.target);
            window.getSelection().removeAllRanges();
            window.getSelection().addRange(range);
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'setHighlightedSelection', error ,'warn');            
        }
    }

    /**
     * Set Signature size into variable
     * @param {*} event 
     */
    setSignatureSize(event){
        this.signatureSize = event.target.value;
    }

    /**
     * Update Signature size in backed.
     */
    updateSignatureSize(){
        try {
            this.savedSignatureSize = this.signatureSize;
            updateSignatureInfo({templateId : this.templateId, signatureSize : this.signatureSize});
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'updateSignatureSize', error ,'warn');            
        }
    }

    /**
     * Dispatch & Trigger 'onclose' event into parent component when user click on close button
     */
    handleClose(){
        this.dispatchEvent(new CustomEvent('close'));
    }

    sortFormateKeys(list, orderBy){
        return list.sort((a, b) => {
            return a[orderBy]?.localeCompare(b[orderBy]);
        });
    }


    /**
     * Triggers a preview event using CustomEvent.
     * Also updates the signature size after triggering the event.
     */
    handlePreview(){
        this.dispatchEvent(new CustomEvent('preview'));
        this.updateSignatureSize();
    }
    

    /**
     * Dispatch & Trigger 'onsave' event into parent component when user click on save button.c/buttonGenerator.
     * Also updates the signature size after triggering the event.
     */
    handleSave(){
        this.dispatchEvent(new CustomEvent('save'));
        this.updateSignatureSize();
    }


    /**
     * API Method to Stop Generation.
     * Update 'isExceedRelatedListLimit' from parent to Stop Generation of child object table when user exceed maximum number of child object.
     * @param {*} isExceed 
     */
    @api
    relatedListTableLimitExceed(isExceed){
        try {
            this.isExceedRelatedListLimit = isExceed;
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'relatedListTableLimitExceed', error ,'warn');            
        }
    }

    /**
     * API Method to get object filed and its mapping key from parent object.
     */
    @api 
    getAllMappingFields(){
        try {
            const objectKeys = {};
            objectKeys.objectFieldKeys = [];
            objectKeys.generalFieldsKeys = [];
            objectKeys.mergeTemps = [];

            this.fieldMappingsWithObj.forEach(ele => {
                 ele.fieldMappings.forEach(item => {
                    objectKeys.objectFieldKeys.push(item.name);
                });
            });

            this.generalFieldTypes.forEach(ele => {
                ele.fieldMappings.forEach(item => {
                    objectKeys.generalFieldsKeys.push(item.name);
                });
            });

            this.otherActiveTempList.foreach(ele => {
                objectKeys.mergeTemps.push(ele.name);
            });

            return objectKeys;
        } catch (error) {
            errorDebugger('FieldMappingKeyV2', 'getAllMappingFields', error ,'warn');            
            return null;
        }
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

}