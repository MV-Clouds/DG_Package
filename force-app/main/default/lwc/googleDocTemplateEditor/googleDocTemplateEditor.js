import { LightningElement, track, api } from "lwc";

import getAllData from "@salesforce/apex/GoogleDocTemplateEditorController.getAllData";
import saveTemplateData from "@salesforce/apex/GoogleDocTemplateEditorController.saveTemplateData";
import editTemplate from "@salesforce/apex/GoogleDocTemplateEditorController.editTemplate";
import createNewDocument from "@salesforce/apex/GoogleDocTemplateEditorController.createNewDocument";

import new_template_bg from "@salesforce/resourceUrl/new_template_bg";

import homePageImgs from "@salesforce/resourceUrl/homePageImgs";
import { NavigationMixin } from "lightning/navigation";
import { errorDebugger, nameSpace } from 'c/globalProperties';

export default class GoogleDocTemplateEditor extends NavigationMixin(LightningElement) {
    @api templateId;
    @api objectName;

    @track templateRecord = {};
    @track previousTemplateData = {};

    objectlabel;

    isSpinner = true;
    loaderLabel = null;
    selectedTemplate = {};
    showPopup = false;
    webViewLink;

    @track templates;
    @track allTemplates;
    @track searchString = "";
    @track profile;
    @track warning = '';

    templateBg = new_template_bg;

    initialRender = true;
    isPreview = false;

    @track isMappingOpen = false;
    @track isMappingContainerExpanded = false;

    get generateDocument() {
        return this.activeTabName === "defaultValues";
    }
    get showBasicDetails() {
        return this.activeTabName === "basicTab";
    }
    get showTemplateEditor() {
        return this.activeTabName === "contentTab";
    }
    get showNoSearchResults() {
        return this.templates && this.templates.length == 0 && this.allTemplates && this.allTemplates.length > 0;
    }
    get showNoDocumentFiles() {
        return this.allTemplates && this.allTemplates.length == 0;
    }

    get disableNextButton() {
        return (this.selectedTemplate.id == null) || (this.selectedTemplate.id != null && !this.templates.some(temp => temp.id == this.selectedTemplate.id));
    }

    connectedCallback() {
        try {
            

            // Added for keyMappingContainer...
            // window.addEventListener("resize", this.resizeFunction());
            window?.globalThis?.addEventListener("resize", this.resizeFunction);
            this.getAllRelatedData();
        } catch (error) {
            errorDebugger("googleDocTemplateEditor", 'connectedCallback', error, 'error', 'Error in connectedCallback. Please try again later');
        }
    }

    renderedCallback() {
        try {
            

            if (this.selectedTemplate && this.selectedTemplate.id) {
                let template = this.template.querySelector(`[data-id='${this.selectedTemplate.id}']`);
                

                if (template) {
                    template.classList.add("selected");
                    template.classList.remove("hover-effect");
                }
            }

            this.template.host.style.setProperty("--background-image-url", `url(${homePageImgs}/HomBg.png)`);
            this.template.host.style.setProperty("--main-background-image-url", `url(${homePageImgs}/HomBg.png)`);
            if (this.initialRender && this.template.querySelector("c-key-mapping-container")) {
                this.resizeFunction();
                this.initialRender = false;
            }

            let templateDetails = this.template.querySelector(".templateDetails");

            if (templateDetails) {
                let styleEle = window?.globalThis?.document?.createElement('style');
                styleEle.innerText = `
                    .slds-input {
                        box-shadow: none;
                    }
                    .slds-input:focus {
                        --slds-c-input-shadow: none;
                    }
                    .slds-has-error {
                        border-color: red;
                    }`;

                templateDetails.appendChild(styleEle);
            }

        } catch (error) {
            errorDebugger('googleDocTemplateEditor', 'renderedCallback', error, 'error', 'Error in renderedCallback. Please try again later');
        }
    }

    getAllRelatedData() {
        try {
            

            this.isSpinner = true;
            getAllData({ templateId: this.templateId, objectName: this.objectName })
                .then((result) => {
                    

                    if (result.error) {
                        let errorList = result.error.split(":");
                        
                        const popup = this.template.querySelector("c-message-popup");
                        popup.showMessagePopup({
                            title: "Error",
                            message: errorList[2],
                            status: "error"
                        });
                        this.isSpinner = false;
                        return;
                    }

                    if (result.template && Object.keys(result.template).length) {
                        this.templateRecord = JSON.parse(result.template); // Template
                        this.previousTemplateData = JSON.parse(result.template);
                    } else {
                        this.isSpinner = false;
                        const popup = this.template.querySelector("c-message-popup");
                        popup.showMessagePopup({
                            title: "No Template Found",
                            message: "No template found for the given object. Please try again.",
                            status: "error"
                        });
                        return;
                    }

                    if (result.objectLabel) {
                        this.objectlabel = result.objectLabel; // getting object Label
                    }

                    if (result.profileData) {
                        this.profile = JSON.parse(result.profileData); // get username and icon
                    }

                    // Get all templates
                    if (result.docList != null) {

                        this.allTemplates = JSON.parse(result.docList);
                        if (this.allTemplates && this.allTemplates.length > 0) {
                            this.setDateAndSize();
                        }
                        this.templates = this.allTemplates;
                    }

                    // Template Data
                    if (result.templateData) {
                        let templateData = JSON.parse(result.templateData);
                        this.webViewLink = templateData.MVDG__Google_Doc_WebViewLink__c;
                        this.MVDG__Google_Doc_Template_Id__c = templateData.MVDG__Google_Doc_Template_Id__c;
                    }

                    // Showing the popup when the template is not selected
                    if (this.allTemplates != null && this.profile != null && result.templateData == null) {
                        this.isSpinner = false;
                        this.showPopup = true;
                    }

                    // Showing error
                    if (result.templateData == null && this.allTemplates == null) {
                        this.isSpinner = false;
                        const popup = this.template.querySelector("c-message-popup");
                        popup.showMessagePopup({
                            title: "No Google Integration Found",
                            message: "To create a new template, Google Drive integration is neccessary.",
                            status: "error"
                        });
                    }

                })
                .catch((error) => {
                    
                    this.isSpinner = false;
                });
        } catch (error) {
            errorDebugger('googleDocTemplateEditor', 'getAllRelatedData', error, 'error', 'Error in getAllRelatedData. Please try again later');
        }
    }

    resizeFunction = () => {
        // Added for keyMappingContainer...
        
        // To Open/close keyMapping Container...
        if (window.innerWidth > 1435) {
            this.template.querySelector("c-key-mapping-container")?.toggleMappingContainer(false);
        } else {
            this.template.querySelector("c-key-mapping-container")?.toggleMappingContainer(true);
        }
    };

    closePopup() {
        
        this.showPopup = false;
    }

    openPopup() {
        
        this.showPopup = true;
    }

    handleTemplateClick(event) {
        try {
            
            let selected = this.template.querySelector(".selected");
            if (selected) {
                selected.classList.remove("selected");
                selected.classList.add("hover-effect");
            }
            const templateId = event.currentTarget.dataset.id;
            this.selectedTemplate = this.templates.find((template) => template.id === templateId);
            let template = event.currentTarget;
            template.classList.add("selected");
            template.classList.remove("hover-effect");

            if (!selected) {
                const next = this.template.querySelector(".next");
                next.removeAttribute("disabled");
            }
        } catch (error) {
            errorDebugger('googleDocTemplateEditor', 'handleTemplateClick', error, 'error', 'Error in handleTemplateClick. Please try again later');
        }
    }

    refreshDocs() {
        try {
            
            this.isSpinner = true;
            this.getAllRelatedData();
        } catch (error) {
            errorDebugger('googleDocTemplateEditor','refreshDocs', error, 'error', 'Error in refreshDocs. Please try again later');
        }
    }

    createNewDocument() {
        try {
            this.isSpinner = true;
            this.loaderLabel = 'Creating a new Document. Please wait...';
            createNewDocument()
                .then((result) => {
                    let document = JSON.parse(result);
                    let newTemplate = {};
                    newTemplate.webViewLink = 'https://docs.google.com/document/d/' + document.documentId + '/edit?usp=drivesdk';
                    newTemplate.id = document.documentId;

                    this.selectedTemplate = newTemplate;
                    this.next();
                })
                .catch((error) => {
                    this.isSpinner = false;
                    
                });
        } catch (error) {
            this.isSpinner = false;
            errorDebugger('googleDocTemplateEditor', 'newDocument', error, 'error', 'Error in newDocument. Please try again later');
        }
    }

    next() {
        try {
            
            this.loaderLabel = 'Loading... Please wait a while';
            this.webViewLink = this.selectedTemplate.webViewLink;
            this.MVDG__Google_Doc_Template_Id__c = this.selectedTemplate.id;
            this.isSpinner = true;

            this.closePopup();
            this.save();
        } catch (error) {
            errorDebugger('googleDocTemplateEditor', 'next', error, 'error', 'Error in next. Please try again later');
        }
    }

    handleConfirmation(event) {
        try {

            
            if (this.warning == 'cancel') {
                this.warning = '';
                if (event && event.detail) {
                    this.isSpinner = true;
                    this.templateRecord = JSON.parse(JSON.stringify(this.previousTemplateData));
                    this.template.querySelector(".next").removeAttribute("disabled");
                    this.activeTabName = "contentTab";
                    this.setActiveTab();
                }
            } else if(this.warning == 'home') {
                this.warning = '';
                if (event && event.detail) {
                    this.closePopup();
                    this.navigateToComp("homePage", {});
                } else if (event && event.detail === false) {
                    this.activeTabName = "basicTab";
                    this.setActiveTab();
                }
            } else if (this.warning == 'save') {
                // 
            } else {
                this.closePopup();
                this.navigateToComp("homePage", {});
            }
        } catch(error) {
            errorDebugger('googleDocTemplateEditor', 'handleConfirmation', error, 'error', 'Error in handleConfirmation. Please try again later');
        }
    }

    handleDefaultsClose() {
        this.activeTabName = "contentTab";
        this.setActiveTab();
    }

    changeTemplateStatus() {
        this.templateRecord.MVDG__Template_Status__c = true;
        this.previousTemplateData.MVDG__Template_Status__c = true;
    }

    // When user navigates to home page
    cancel() {
        
        if (this.previousTemplateData.MVDG__Template_Name__c != this.templateRecord.MVDG__Template_Name__c || this.previousTemplateData.MVDG__Description__c != this.templateRecord.MVDG__Description__c || 
            this.previousTemplateData.MVDG__Template_Status__c != this.templateRecord.MVDG__Template_Status__c) {
                const popup = this.template.querySelector("c-message-popup");
                popup.showMessagePopup({
                    title: "Do You Want to Leave?",
                    message: "Your unsaved changes will be discarded once you leave this page.",
                    status: "warning"
                });
                this.warning = 'home';
        } else {
            this.closePopup();
            this.navigateToComp("homePage", {});
        }
    }

    setDateAndSize() {
        try {
            
            this.allTemplates = this.allTemplates.map((template) => {

                let date = template.createdTime.split("T")[0];
                let [year, month, day] = date.split("-");
                template.createdTime = `${day}-${month}-${year}`;

                if (template.size < 1024) {
                    template.size = Math.round(template.size) + "Byte";
                } else if (template.size < 1024 * 1024) {
                    template.size = Math.round(template.size / 1024) + "KB";
                } else {
                    template.size = Math.round(template.size / (1024 * 1024)) + "MB";
                }
                return template;
            });
        } catch (error) {
            errorDebugger('googleDocTemplateEditor','setDateAndSize', error, 'error', 'Error in setDatAndSize. Please try again later');
        }
    }

    handleSearch(event) {
        try {
            
            if (this.templates) {
                this.searchString = event.target.value;
                if (this.searchString) {
                    this.templates = this.allTemplates.filter((template) => {
                        return template.name.toLowerCase().includes(this.searchString.toLowerCase());
                    });
                } else {
                    this.templates = this.allTemplates;
                }
            }
        } catch (error) {
            errorDebugger('googleDocTemplateEditor', 'handleSearch', error, 'error', 'Error in handleSearch. Please try again later');
        }
    }

    save() {
        try {
            
            saveTemplateData({
                templateId: this.templateId,
                googleDocId: this.selectedTemplate.id,
                webViewLink: this.selectedTemplate.webViewLink,
            })
                .then((response) => {
                    if (response === "success") {
                        
                    }
                })
                .catch((error) => {
                    
                });
        } catch (error) {
            errorDebugger('googleDocTemplateEditor','save', error, 'error', 'Error in save. Please try again later');
        }
    }

    // -=-=- Used to navigate to the other Components -=-=-
    navigateToComp(componentName, paramToPass) {
        try {
            
            let cmpDef;
            if (paramToPass && Object.keys(paramToPass).length > 0) {
                cmpDef = {
                    componentDef: `${nameSpace}:${componentName}`,
                    attributes: paramToPass
                };
            } else {
                cmpDef = {
                    componentDef: `${nameSpace}:${componentName}`
                };
            }

            let encodedDef = btoa(JSON.stringify(cmpDef));
            
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: "/one/one.app#" + encodedDef
                }
            });
        } catch (error) {
            errorDebugger('googleDocTemplateEditor','navigateToComp', error, 'error', 'Error in navigateToComp. Please try again later');
        }
    }

    handlePreview() {
        
        this.isPreview = true;
    }

    // showHideMappingContainer() {
    //     try {
    //         this.isMappingOpen = !this.isMappingOpen;
    //         let fieldMappingContainer = this.template.querySelector('[data-name="fieldMappingContainer"]');
    //         if (fieldMappingContainer) {
    //             if (this.isMappingOpen) {
    //                 fieldMappingContainer.classList.add("openFieldMapping");
    //             } else {
    //                 fieldMappingContainer.classList.remove("openFieldMapping");
    //             }
    //         }
    //     } catch (error) {
    //         
    //     }
    // }

    openGenChildTablePopup(event) {

        const childObjectTableBuilder = this.template.querySelector("c-child-object-table-builder");
        
        if (childObjectTableBuilder) {
            childObjectTableBuilder.openPopup(event);
        }
    }

    closeGenChildTable() {
        const childObjectTableBuilder = this.template.querySelector("c-child-object-table-builder");
        if (childObjectTableBuilder) {
            childObjectTableBuilder.closePopup();
        }
    }

    // ==== Toggle Tab Methods - START - ========
    activeTabName = "contentTab";
    activeTab(event) {
        

        try {
            this.resizeFunction();
            if (event) {
                this.activeTabName = event.currentTarget.dataset.name;
                if (this.activeTabName === "contentTab") {
                    this.isSpinner = true;
                }
            }
            this.setActiveTab();
        } catch (error) {
            errorDebugger('googleDocTemplateEditor','activeTab', error, 'error', 'Error in activeTab. Please try again later');
        }
    }

    setActiveTab() {
        try {
            
            // this.templateRecord = JSON.parse(JSON.stringify(this.previousTemplateData));

            let activeTabBar = this.template.querySelector(`.activeTabBar`);

            let tabS = this.template.querySelectorAll(".tab");
            tabS.forEach((ele) => {
                if (ele.dataset.name === this.activeTabName) {
                    ele.classList.add("activeT");
                    activeTabBar.style = ` transform: translateX(${ele.offsetLeft}px); width : ${ele.clientWidth}px;`;
                } else {
                    ele.classList.remove("activeT");
                }
            });

            let sections = this.template.querySelectorAll(".tabArea");
            sections.forEach((ele) => {
                if (ele.dataset.section === this.activeTabName) {
                    ele.classList.remove("deactiveTabs");
                } else {
                    ele.classList.add("deactiveTabs");
                }
            });
        } catch (error) {
            errorDebugger('googleDocTemplateEditor','setActiveTab', error, 'error', 'Error in setActiveTab. Please try again later');
        }
    }

    iframeLoaded() {
        this.resizeFunction();
        this.isSpinner = false;
    }

    closeTemplatePreview() {
        this.isPreview = false;
    }

    handleEditDetail(event) {
        try {
            

            const targetInput = event.currentTarget.dataset.name;
            if (targetInput === "MVDG__Template_Name__c") {
                const next = this.template.querySelector(".next");
                if (!event.target.value || event.target.value.trim().length <= 0) {
                    // event.currentTarget.classList.add("slds-has-error");
                    next.setAttribute("disabled", true);
                } else {
                    // event.currentTarget.classList.remove("slds-has-error");
                    next.removeAttribute("disabled");
                }
            }

            if (event.target.type !== "checkbox") {
                this.templateRecord[targetInput] = event.target.value;
            } else {
                
                this.templateRecord[targetInput] = !event.target.checked;
            }
        } catch (error) {
            errorDebugger('googleDocTemplateEditor','handleEditDetail', error, 'error', 'Error in handleEditDetail. Please try again later');
        }
    }

    editTemplateDetails() {
        try {
            
            this.isSpinner = true;
            this.loaderLabel = "Saving Your Data";

            let saveRecord = {
                templateName: this.templateRecord.MVDG__Template_Name__c,
                templateDescription: this.templateRecord.MVDG__Description__c,
                templateStatus: this.templateRecord.MVDG__Template_Status__c,
                templateId: this.templateId,
            }
            editTemplate({ templateRecord: JSON.stringify(saveRecord) })
                .then((result) => {
                    
                    this.isSpinner = false;
                    this.loaderLabel = 'Loading... Please wait a while';
                    const popup = this.template.querySelector("c-message-popup");

                    if (result) {
                        this.previousTemplateData = JSON.parse(JSON.stringify(this.templateRecord));
                        popup.showMessageToast({
                            title: "Template Data Saved",
                            message: "Template data saved to backend succesfully.",
                            status: "success"
                        });
                        this.warning = 'save';
                    } else {
                        popup.showMessageToast({
                            title: "Error Saving Template",
                            message: "Error saving template data to backend. Please try again later.",
                            status: "error"
                        });
                    }
                })
                .catch((error) => {
                    this.isSpinner = false;
                    this.loaderLabel = 'Loading... Please wait a while';
                    const popup = this.template.querySelector("c-message-popup");
                    popup.showMessageToast({
                        title: "Error Saving Template",
                        message: "Error saving template data to backend. Please try again later.",
                        status: "error"
                    });
                    errorDebugger('googleDocTemplateEditor','editTemplateDetails', error, 'error', 'Error in editTemplateDetails. Please try again later');
                });
        } catch (error) {
            errorDebugger('googleDocTemplateEditor','editTemplateDetails', error, 'error', 'Error in editTemplateDetails. Please try again later');
        }
    }

    cancelEditTemplate() {
        try {
            this.warning = 'cancel';
            
            

            if (this.previousTemplateData.MVDG__Template_Name__c != this.templateRecord.MVDG__Template_Name__c || this.previousTemplateData.MVDG__Description__c != this.templateRecord.MVDG__Description__c || 
                this.previousTemplateData.MVDG__Template_Status__c != this.templateRecord.MVDG__Template_Status__c) {
                    const popup = this.template.querySelector("c-message-popup");
                    popup.showMessagePopup({
                        title: "Do You Want to Leave?",
                        message: "Your unsaved changes will be discarded once you leave this page.",
                        status: "warning"
                    });
            } else {
                this.handleConfirmation({detail: true});
            }
        } catch (error) {
            errorDebugger('googleDocTemplateEditor','cancelEditTemplate', error, 'error', 'Error in cancelEditTemplate. Please try again later');
        }
    }
}