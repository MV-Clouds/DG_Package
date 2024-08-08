import { LightningElement, api, track } from 'lwc';
import getFieldMappingKeys from '@salesforce/apex/KeyMappingController.getFieldMappingKeys';
import getGeneralFields from '@salesforce/apex/KeyMappingController.getGeneralFields';
import getMerginTemplateKeys from '@salesforce/apex/KeyMappingController.getMerginTemplateKeys';
import getAllContentVersionImgs from '@salesforce/apex/KeyMappingController.getAllContentVersionImgs';
import getChildObjects from '@salesforce/apex/KeyMappingController.getChildObjects';
import formattingFieldKeys from '@salesforce/apex/KeyMappingController.formattingFieldKeys';
import getSignatureInfo from '@salesforce/apex/KeyMappingController.getSignatureInfo';
import updateSignatureInfo from '@salesforce/apex/KeyMappingController.updateSignatureInfo';

export default class KeyMappingContainer extends LightningElement {

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
    // copyBase64AvailableFor = ['Google Doc Template'];
    copyBase64AvailableFor = [];

    @track field_Vs_KeyList = [];
    @track selectedObjectName;

    @track isMappingOpen = false;
    @track isMappingContainerExpanded;
    @track isMappingTabExpanded;

    @track relatedChildObjects = [];
    @track selectedChildObjectName;
    @track selectedChildObjAPI;

    mappingTypeTabs = [
        {   label: 'Object Fields',        name: 'objectFields',
            helpText : 'Insert Base Object and Lookup (Related) Object\'s Fields Int Template.',
            showCombobox : true, comboboxPlaceholder : 'Select Object...', showDescription : false,
            showSearchbar : true, searchBarPlaceHolder : 'Search Fields...',
        },
        {   label: 'Related List Fields',  name: 'relatedListFields',
            helpText : 'Insert Related List (Child Object) Field In Template as a Table Format.',
            showCombobox : true, comboboxPlaceholder : 'Select Object...', showDescription : true,
        },
        {   label: 'General Fields',        name: 'generalFields',
            helpText : 'Insert & Add Document Creation Date, Document Creation User Info, Organization Info, etc... In Template',
            showCombobox : true, comboboxPlaceholder : 'Select Object...',  showDescription : false,
            showSearchbar : true, searchBarPlaceHolder : 'Search General Fields...',
        },
        {   label: 'Merge Templates',      name: 'mergeTemplates',
            helpText : 'Merge Other Templates Into The Current Template',
            showSearchbar : true, searchBarPlaceHolder : 'Search Templates by Name...',
        },
        {   label: 'Salesforce Images',     name: 'sfImages',
            helpText : 'Add Salesforce images Into The Template.',
            showSearchbar : true, searchBarPlaceHolder : 'Search Salesforce Images...',
            showRefresh : true,
        },
        {   label: 'Signature',     name: 'signature',
            helpText : 'Add Signature into Your file by Mapping Signature Key in The Template.',
        },
    ];

    @track activeMappingTabName = 'objectFields';
    @track selectedMappingType = this.mappingTypeTabs.find(ele =>  ele.name == this.activeMappingTabName);
    @track generalFieldTypes = [];
    @track selectedGeneralFieldType;
    @track generalFieldsToDisplay = [];
    @track otherActiveTempList = [];
    @track contentVersionImages = [];
    @track cVIdVsDownloadUrl = {};
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

    get showFullHeightButton(){ 
        return this.showFullHeightButtonFor.includes(this.templateType);
    };

    get hideMergeTemplates(){ 
        return this.hideMergeTemplatesFor.includes(this.templateType);
    };

    get mappingTypeTabArea(){
        return {
            objectFields        :   this.activeMappingTabName == 'objectFields' ? true : false,
            relatedListFields   :   this.activeMappingTabName == 'relatedListFields' ? true : false,
            generalFields       :   this.activeMappingTabName == 'generalFields' ? true : false,
            mergeTemplates      :   this.activeMappingTabName == 'mergeTemplates' ? true : false,
            sfImages            :   this.activeMappingTabName == 'sfImages' ? true : false,
            signature           :   this.activeMappingTabName == 'signature' ? true : false,
        }
    }

    get showCombobox(){
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.showCombobox;
    }

    get showSearchBar(){
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.showSearchbar;
    }

    get showRefreshButton(){
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.showRefresh;
    }

    get objectComboPlaceHolder(){
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.comboboxPlaceholder;
    }

    get searchBarPlaceHolder(){
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.searchBarPlaceHolder;
    }

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
        return [];
    }

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
        return null;
    }

    get childTableLimitErrorMsg(){
        // return 'Related List Table Limit Exceed. You Can Not Insert More Then 10 Related List Tables.';
        return this.isExceedRelatedListLimit ? `Related List Table Limit Exceeded. You Can Not Insert More Then ${this.maxRelatedLIstTableLimit} Related List Tables.` : ''
    }

    get showComboDescription(){
        return this.mappingTypeTabs?.find(ele => ele.name === this.activeMappingTabName)?.showDescription;
    }


    get formateOptions(){
        return {
            isPrimaryFormateCombobox : this.clickedFieldType === 'DATETIME' || this.clickedFieldType === 'DATE' || this.clickedFieldType === 'TIME',
            isCheckboxFormate : this.clickedFieldType === 'CHECKBOX',
            isTextFormate  : this.clickedFieldType === 'TEXT' ,
            isNumberFormat : this.clickedFieldType === 'CURRENCY' || this.clickedFieldType === 'NUMBER' ,
        }
    }

    get formatHelpText(){
        if(this.clickedFieldType == 'DATE'){
            return 'Select format for your Date Field';
        }
        else if(this.clickedFieldType == 'DATETIME'){
            return 'Select Date and Time Format for your DateTime Field';
        }
        else if(this.clickedFieldType == 'TIME'){
            return 'Select format for your Time Field'
        }
        else if(this.clickedFieldType == 'CHECKBOX'){
            return 'Set Display text based on checkbox status';
        }  
        else if(this.clickedFieldType == 'TEXT'){
            return 'Set Text Length by Character Number';
        }
        else if(this.clickedFieldType == 'CURRENCY' || this.clickedFieldType == 'NUMBER' || this.clickedFieldType == 'PERCENTAGE'){
            return `Format Options for ${this.clickedFieldType} field`;
        }
    }

    get setSelectChildObj(){
            return (this.selectedChildObjectName && !this.isExceedRelatedListLimit) ? false : true;
    }

    get isSignatureSetBtn(){
        return this.savedSignatureSize === this.signatureSize;
    }

    connectedCallback(){
        try {
            this.fetchFieldMapping();
            this.fetchChildObjects();
            this.fetchGeneralFields();
            this.fetchAllContentVersionImages();
            this.fetchFormatMappingKeys();
            this.fetchSignatureInfo();
            window.addEventListener('resize', this.resizeFunction);

            if(this.hideMergeTemplates){
                const index = this.mappingTypeTabs.indexOf(this.mappingTypeTabs.find(ele => ele.name == 'mergeTemplates'));
                if(index !== -1) this.mappingTypeTabs.splice(index, 1);
            }
            else{
                this.fetchAllActiveTemps()
            }
        } catch (error) {
            console.log('error in FieldMappingKey.connectedCallback : ', error.stack);
        }
    }

    renderedCallback(){
        if(this.isInit){
            this.resizeFunction();
            this.isInit = false;
        }
    }

    // Use Arrow Function...
    resizeFunction = () => {

    };

    fetchFieldMapping(){
        try {
            getFieldMappingKeys({sourceObjectAPI : this.objectName, getParentFields : true})
            .then(result => {
                this.isDataRefreshing = false;
                console.log('getFieldMappingKeys result  : ', result);
                    if(result.isSuccess){
                        // Set... Base Object, Related Parent Object and It's Fields with mapping key
                        this.object_Label = result.objectLabelAPI.label;
                        var relatedObjectList = [];
                        var fielMappingKeysList = [];
                        result.fieldMappingsWithObj.forEach(obj => {
                            relatedObjectList.push({label : obj.label, value: obj.name});
                            if(!obj.label.includes('>')){
                                this.objectName = obj.name;
                            }
                            obj.fieldMappings.forEach(ele => {
                                fielMappingKeysList.push(ele.name);
                            })
                        });
                        this.relatedObjectList = JSON.parse(JSON.stringify(relatedObjectList));
                        console.log('this.relatedObjectList : ', this.relatedObjectList);
                        this.fieldMappingsWithObj = result.fieldMappingsWithObj;
                        this.setFieldForMapping();
                        this.setMappingTab();
                        // this.isSpinner = this.successCount == 2 ? false : this.successCountPlus();

                        // setFieldMappingKeyisConfig(fielMappingKeysList);
                    }
                    else{
                        // this.isSpinner = this.successCount == 2 ? false : this.successCountPlus();
                        this.showMessagePopup('Error', 'Error While Fetching Field Mapping Data', result.returnMessage);
                    }
            })
            .catch(error => {
                this.isDataRefreshing = false;
                // this.isSpinner = this.successCount == 2 ? false : this.successCountPlus();
                console.log('error in getTemplateData apex callout : ', {error});
            })
        } catch (error) {
            console.log('error in templateBuilder > getFieldMappingKeys ', error.stack);
            
        }
    }

    fetchChildObjects(){
        try {
            getChildObjects({sourceObjectAPI : this.objectName})
            .then(result =>{
                this.isDataRefreshing = false;
                console.log('getChildObjects result  : ', result);
                if(result.isSuccess){
                    result.fieldMappingsWithObj.forEach(ele =>{
                        this.relatedChildObjects.push({label : ele.label, value : ele.name, description : ele.additionalInfo, childObjApi : ele.objectAPI});
                    });
                }
            })
        } catch (error) {
            console.log('error in fetchChildObjects');
        }
    }

    fetchGeneralFields(){
        try {
            getGeneralFields()
            .then(result => {
                this.isDataRefreshing = false;
                console.log('getGeneralFields result => ', result);
                var generalFieldTypes_temp = [];
                if(result.isSuccess == true && result.fieldMappingsWithObj){
                    result.fieldMappingsWithObj.forEach(ele => {
                        generalFieldTypes_temp.push({label : ele.label, value : ele.name, fieldMappings : ele.fieldMappings})
                    })
                    this.generalFieldTypes = JSON.parse(JSON.stringify(generalFieldTypes_temp));
                    this.setGeneralFieldsToDisplay();
                    console.log('generalFieldTypes : ', JSON.parse(JSON.stringify(this.generalFieldTypes)));
                }
            })
            .catch(error => {
                this.isDataRefreshing = false;
                console.log('error in getGeneralFields => ', error.message);
            })
        } catch (error) {
            console.log('error in fetchGeneralFields : ', error.stack);
        }
    }

    fetchAllActiveTemps(){
        try {
            getMerginTemplateKeys({sourceObjectAPI : this.objectName})
            .then(result => {
                this.isDataRefreshing = false;
                if(result.isSuccess == true){
                    console.log('result : ', result);
                    if(result.fieldMappingsWithObj){
                        this.otherActiveTempList = result.fieldMappingsWithObj[0].fieldMappings;
                        this.setOtherMappingTemplates();
                    }
                    else{
                        console.log(result.returnMessage);
                    }
                }
            })
        } catch (error) {
            console.log('error in fetchAllActiveTemps : ', error.stack);
        }
    }

    fetchAllContentVersionImages(){
        try {
            getAllContentVersionImgs()
            .then(result => {
                this.isDataRefreshing = false;
                console.log('getAllContentVersionImgs result => ', result);
                if(result.isSuccess == true){
                    this.contentVersionImages = result.cvImages;
                    this.cVIdVsDownloadUrl = result.cvIdVsDownloadUrl;
                    this.contentVersionImages.forEach(ele => {
                        ele['fileSize'] = ele.ContentSize + ' Bytes';
                         if (ele.ContentSize < 1000000) {  
                            ele['fileSize'] =  (ele.ContentSize / 1000).toFixed(2) + ' KB';  
                        } else if (ele.ContentSize < 1000000000) {  
                            ele['fileSize'] = (ele.ContentSize / 1000000).toFixed(2) + ' MB';  
                        } else {  
                            ele['fileSize'] = (ele.ContentSize / 1000000000).toFixed(2) + ' GB';  
                        } 
                        ele.publicUrl = this.cVIdVsDownloadUrl[ele.Id];
                    });
                    console.log('this.contentVersionImages  : ', this.contentVersionImages );
                    this.setContVerImgToDisplay();
                }
            })
            .catch(error => {
                this.isDataRefreshing = false;
                console.log('getAllContentVersionImgs error => ', error);
            })
        } catch (error) {
            console.log('error in fetchAllContentVersionImages : ', error.stack);
        }
    }

    fetchFormatMappingKeys(){
        try {
            formattingFieldKeys()
            .then(result => {
                this.isDataRefreshing = false;
                console.log('formattingFieldKeys result => ', result);
                if(result.isSuccess == true){
                    if(result.fieldFormatting && result.fieldFormatting.length){
                        this.dateFormatKeys = result.fieldFormatting.find(ele => ele.formatType == 'DATE').fieldMappings;
                        this.timeFormatKeys = result.fieldFormatting.find(ele => ele.formatType == 'TIME').fieldMappings;
                        this.signatureKey = result.signatureKey;
                    }
                }
            })
            // .catch(error => {
            //     console.log('formattingFieldKeys error => ', error.stack);
            // })
        } catch (error) {
            console.log('error in fetchFormatMappingKeys : ', error.stack);
        }
    }

    fetchSignatureInfo(){
        try {
            getSignatureInfo({templateId : this.templateId})
            .then(result => {
                this.isDataRefreshing = false;
                this.signatureSize = result;
                this.savedSignatureSize = result;
            })
        } catch (error) {
            console.warn('error in fetchSignatureInfo : ', error.message);
        }
    }

    setMappingTab(event){
        try {
            if(event && event.currentTarget){
                this.activeMappingTabName = event.currentTarget.dataset.name;
            }
            
            var tabSelection = this.template.querySelectorAll('.tabSelection');
            if(tabSelection){
                tabSelection.forEach(ele => {
                    if(ele.dataset.name == this.activeMappingTabName){
                        ele.classList.add('selected');
                        this.searchFieldValue = null;
                    }
                    else if(ele.classList.contains('selected')){
                        ele.classList.remove('selected');
                    }
                });
            };
            
            var index = this.mappingTypeTabs.indexOf(this.mappingTypeTabs.find(ele => ele.name == this.activeMappingTabName));
            this.selectedMappingType = this.mappingTypeTabs[index];

            this.handleKeySearch();

        } catch (error) {
            console.log('error in setMappingTab : ', error.stack);
        }
    }

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
        } catch (error) {
            console.log('error in templateBuilder.handleOptionSelect : ', error.stack);
        }
    }

    handleRelatedObjSelect(event){
        try {
            if(event.detail.length){
                this.selectedObjectName = event.detail[0];
            }
            else{
                this.selectedObjectName = null;
            }
            this.setFieldForMapping();
        } catch (error) {
            console.log('error in templateBuilder.handleRelatedObjSelect : ', error.stack);
        }
    }

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
            console.log('error in handleChildObjSelection : ', error.stack);
        }
    }

    handleGeneralFieldTypeSelection(event){
        try {
            this.selectedGeneralFieldType = event.detail[0];
            this.setGeneralFieldsToDisplay();
        } catch (error) {
            console.log('error in handleGeneralFieldTypeSelection : ', error.stack);
        }
    }

    handleKeySearch(event){
        try {
            this.searchFieldValue = event ? event.target.value : null;
            if(this.activeMappingTabName == 'objectFields'){
                this.setFieldForMapping();
            }
            else if(this.activeMappingTabName == 'relatedListFields'){
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
            console.log('error in templateBuilder.handleKeySearch : ', error.stack);
        }
    }

    refreshData(){
        try {
            this.isDataRefreshing = true;
            if(this.activeMappingTabName === 'sfImages' ){
                this.fetchAllContentVersionImages()
            }
        } catch (error) {
            console.warn('error in refreshData : ', error.stack);
        }
    }

    setFieldForMapping(){
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

        } catch (error) {
            console.log('error in templateBuilder.setFieldForMapping : ', error.stack)
        }
    }

    setGeneralFieldsToDisplay(){
        try {
            this.generalFieldsToDisplay = this.selectedGeneralFieldType ? this.generalFieldTypes.find(ele => ele.value == this.selectedGeneralFieldType).fieldMappings : this.generalFieldTypes[0].fieldMappings;

            if(this.searchFieldValue){
                this.generalFieldsToDisplay = this.generalFieldsToDisplay.filter((ele) => {
                    return ele.label.toLowerCase().includes(this.searchFieldValue) || ele.key.toLowerCase().includes(this.searchFieldValue);
                });
            }
        } catch (error) {
            console.log('error in templateBuilder.setGeneralFieldsToDisplay : ', error.stack);
        }
    }

    setOtherMappingTemplates(){
        try {
            this.otherActiveTempToDisplay = this.otherActiveTempList;
            if(this.searchFieldValue){
                this.otherActiveTempToDisplay = this.otherActiveTempList.filter((ele) => {
                    return ele.label.toLowerCase().includes(this.searchFieldValue) || ele.key.toLowerCase().includes(this.searchFieldValue);
                })
            }
        } catch (error) {
            console.log('error in setOtherMappingTemplates : ', error.stack);
        }
    }

    setContVerImgToDisplay(){
        try {
            this.contentVersionToDisplay = this.contentVersionImages;

            if(this.searchFieldValue){
                this.contentVersionToDisplay = this.contentVersionImages.filter((ele) => {
                    return ele.Title.toLowerCase.includes(this.searchFieldValue) || ele.FileType.toLowerCase.includes(this.searchFieldValue)
                })
            }
        } catch (error) {
            console.log('error in setContVerImgToDisplay : ', error.stack);
            
        }
    }

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
            console.log('error in toggleMappingTableHeight : ', error.stack);
        }
    }

    showHideMappingContainer(){
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
    }

    @api toggleMappingContainer(state){
        console.log('is floating  : ', state);
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
    }

    // Method to show/hide toggle button
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

    toggleMappingContainerHeight(){
        this.isMappingContainerExpanded = !this.isMappingContainerExpanded
        this.dispatchEvent(new CustomEvent('fullheight'));
    }

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
                    setTimeout(() => {
                        ele.classList.remove('copied');
                    }, 1001);
                }
                else{
                    ele.classList.remove('copied');
                }
            });

        } catch (error) {
            console.log('error in templateBuilder.handleCopyFieldKey : ', error.stack);
        }
    }
    

    // ==== ==== ==== Field Formatting Methods -- START -- ==== ==== ====
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
            }
            
            this.chosenFormat = JSON.parse(JSON.stringify(this.formatDefault));           // for Deep clone...

            console.log('this.primeFormatKeys : ', this.primeFormatKeys);

        } catch (error) {
            console.log();  
        }
    }

    handlePrimeFormat(event){
        try {
            if(event.detail && event.detail.length){
                this.chosenFormat = JSON.parse(JSON.stringify(this.primeFormatKeys.find(ele => ele.value == event.detail[0])));
                console.log('chosenFormat : ', this.chosenFormat);
            }
            else{
                this.chosenFormat = JSON.parse(JSON.stringify(this.formatDefault));
            }

            if(this.isSubFormat){
                this.updateChosenFormat();
            }
        } catch (error) {
            console.log('error in handlePrimeFormat : ', error.stack);
        }
    }

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
            console.log('error in handleSubFormat : ', error.stack);
        }
    }

    updateChosenFormat(){
        // Update format key in case of sub formatting (i.e. Date and Time)
        try {
            if(this.chosenFormat.key.includes('*')){
                // Update format key when key includes format key
                if(this.chosenSubFormat){
                    this.chosenFormat.key = this.chosenFormat.key.replace(/(?<=\*)(.*?)(?=\*)/g, this.chosenFormat.value +' '+ this.chosenSubFormat);
                }
                else{
                    // remove chosenSubFormat from format key when user remove sub format key...
                    this.chosenFormat.key = this.chosenFormat.key.replace(/(?<=\*)(.*?)(?=\*)/g, this.chosenFormat.value);
                }
            }
        } catch (error) {
            console.log('error in updateChosenFormat : ', error.stack);
        }
    }

    setCheckBoxFormat(event){
        try {
            this.trueValueReplacer = event.currentTarget.dataset.name == 'true' ? event.target.value : this.trueValueReplacer;
            this.falseValueReplacer = event.currentTarget.dataset.name == 'false' ? event.target.value : this.falseValueReplacer;

            if(this.trueValueReplacer != '' || this.falseValueReplacer != ''){
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
                console.log('this.formatDefault : ', this.formatDefault);
                // when user clear both input.. set format to default one...
                if(this.chosenFormat.key.includes('*')){
                    this.chosenFormat.key = this.formatDefault.key;
                }
            }
        } catch (error) {
            console.log('error in setCheckBoxFormat : ', error.stack);
        }
    }

    setTextFormat(event){
        try {
            
            if(event.target.value <= 0){
                event.target.value = '';
            }

            if(event.target.value != '' && event.target.value != null){
                if(this.chosenFormat.key.includes('*')){
                    this.chosenFormat.key = this.chosenFormat.key.replace(/(?<=\*)(.*?)(?=\*)/g,  `L:${event.target.value}`);
                }
                else{
                    this.chosenFormat.key = this.chosenFormat.key.replace(this.chosenFormat.name, this.chosenFormat.name + ` *L:${event.target.value}*`);
                }
            }
            else if(this.chosenFormat.key.includes('*')){
                this.chosenFormat.key = this.formatDefault.key;
            }
        } catch (error) {
            console.log('error in setTextFormat : ', error.stack);
        }
    }

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

                // Enable / Disable round Mode option based on decimal places value...
                const roundMode = this.template.querySelector(`[data-action="roundMode"]`);
                const roundModeText = this.template.querySelector('[data-text="roundMode"]');

                if(event.target.value != '' && event.target.value != null){
                    this.numberFormat['dP'] = event.target.value;

                    if(roundMode){
                        roundMode.removeAttribute('disabled');
                        roundModeText.classList.remove('roundMode');

                        // add round Mode with decimal places if rM value is not available and value is not none...
                        if(!this.numberFormat.hasOwnProperty('rM') && roundMode.value != 'none'){
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
            console.log('error in setNumberFormat : ', error.stack);
        }
    }

    closeKeyPopover(event){
        try {
            event.stopPropagation();
            this.primeFormatKeys = null;
            this.showFormatKeys = false;
            this.isSubFormat = false;
            this.numberFormat = {};
            this.chosenFormat = {};

        } catch (error) {
            console.log('error in closeKeyPopover : ',error.stack);
        }
    }
    // ==== ==== ==== Field Formatting Methods -- END -- ==== ==== ====

    stopPropagation(event){
        event.stopPropagation();
    }

    copySFImgAsHTMl(event){
        try {
            event.stopPropagation();

            const imgId = event.currentTarget.dataset.id;
 
            const ImgUrl = this.contentVersionImages.find(ele => ele.Id == imgId)?.publicUrl;

            this.copyImage(ImgUrl, imgId);

        } catch (error) {
            console.log('error in copySFImgAsHTMl : ', error.stack);
        }
    }

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
                    setTimeout(() => {
                        ele.classList.remove('copied');
                    }, 1001);
                }
                else{
                    ele.classList.remove('copied');
                }
            });
        } catch (error) {
            console.log('error in copyImage : ', error.stack);
        }
    }

    getArrayBuffer(data){
        var len = data.length,
        ab = new ArrayBuffer(len),
        u8 = new Uint8Array(ab);

        while (len--) u8[len] = data.charCodeAt(len);
        return ab;
    };

    openChildSelection(){
        this.dispatchEvent(new CustomEvent('opengenchildtable', {detail : {
            relationshipName : this.selectedChildObjectName,
            childObjAPI : this.selectedChildObjAPI,
            label : this.relatedChildObjects.find(ele => ele.value == this.selectedChildObjectName)?.label,
        }}));
    }

    // Set Section Over TExt On Field Key Div....
    handleSetSection(event){
        try {
            // Add section on Field Key Div text...
            var range = document.createRange();
            range.selectNode(event.target);
            window.getSelection().removeAllRanges();
            window.getSelection().addRange(range);
        } catch (error) {
            console.log('error in templateBuilder.handleSetSection : ', error.stack);
            
        }
    }

    // Signature Size Methods
    setSignatureSize(event){
        this.signatureSize = event.target.value;
    }

    updateSignatureSize(){
        try {
            this.savedSignatureSize = this.signatureSize;
            updateSignatureInfo({templateId : this.templateId, signatureSize : this.signatureSize});
        } catch (error) {
            console.warn('error in KeyMappingContainer.savedSignatureSize', error.message) 
        }
    }

    handleClose(){
        this.dispatchEvent(new CustomEvent('close'));
    }

    handlePreview(){
        this.dispatchEvent(new CustomEvent('preview'));
        this.updateSignatureSize();
    }

    handleSave(){
        this.dispatchEvent(new CustomEvent('save'));
        this.updateSignatureSize();
    }

    handleDisableTabClick(event){
        event.stopPropagation();
        event.preventDefault();
    }

    @api
    relatedListTableLimitExceed(isExceed){
        try {
            this.isExceedRelatedListLimit = isExceed;
        } catch (error) {
            console.log('error in childTableLimitExceed : ', error.stack);
        }
    }

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

            this.otherActiveTempList.map(ele => {
                objectKeys.mergeTemps.push(ele.name);
            });

            return objectKeys;
        } catch (error) {
            console.log('error in getAllMappingKeys : ', error.stack);
            return null;
        }
    }

}