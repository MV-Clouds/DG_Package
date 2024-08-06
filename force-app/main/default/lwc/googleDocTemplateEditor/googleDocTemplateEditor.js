import { LightningElement, track, api } from "lwc";

import getAllData from "@salesforce/apex/GoogleDocTemplateEditorController.getAllData";

import saveTemplateData from "@salesforce/apex/GoogleDocTemplateEditorController.saveTemplateData";
import editTemplate from "@salesforce/apex/GoogleDocTemplateEditorController.editTemplate";

import new_template_bg from "@salesforce/resourceUrl/new_template_bg";
import homePageImgs from "@salesforce/resourceUrl/homePageImgs";
import { NavigationMixin } from "lightning/navigation";

export default class GoogleDocTemplateEditor extends NavigationMixin(LightningElement) {
    @api templateId;
    @api objectName;

    @track templateRecord = {};
    @track previousTemplateData = {};

    objectlabel;

    isSpinner = true;
    loaderLabel = null;
    selectedTemplate;
    showPopup = false;
    webViewLink;
    documentName;

    @track templates;
    @track allTemplates;
    @track serachString = "";
    @track profile;

    templateBg = new_template_bg;

    initialRender = true;
    isPreview = false;

    @track isMappingOpen = false;
    @track isMappingContainerExpanded = false;

    get showTempDetail() {
        return Object.keys(this.templateRecord).length ? true : false;
    }
    get generateDocument() {
        // this.isSpinner = true;
        return this.activeTabName === "defaultValues";
    }
    get showBasicDetails() {
        // this.isSpinner = true;
        return this.activeTabName === "basicTab";
    }
    get showTemplateEditor() {
        // this.isSpinner = true;
        return this.activeTabName === "contentTab";
    }

    connectedCallback() {
        try {
            console.log('Connected Callback');
            
            // Added for keyMappingContainer...
            // window.addEventListener("resize", this.resizeFunction());
            window.addEventListener("resize", this.resizeFunction);
            this.getAllRelatedData();
        } catch (error) {
            console.log("Error connectedCallBack==> ", error.stack);
        }
    }

    renderedCallback() {
        try {
            console.log("renderedCallback");

            this.template.host.style.setProperty("--background-image-url", `url(${new_template_bg})`);
            this.template.host.style.setProperty("--main-background-image-url", `url(${homePageImgs}/HomBg.png)`);
            if (this.initialRender && this.template.querySelector("c-key-mapping-container")) {
                this.resizeFunction();
                this.initialRender = false;
            }
        } catch (error) {
            console.error("Error in renderedCallback", error);
        }
    }

    getAllRelatedData() {
        try {
            console.log('this.getAllRelatedData');
            
            this.isSpinner = true;
            getAllData({ templateId: this.templateId, objectName: this.objectName })
                .then((result) => {
                    console.log("result==>", result);

                    if (result.error) {
                        console.log("Error in getAllRelatedData : ", result.error);
                        return;
                    }

                    if (result.template) {
                        this.templateRecord = JSON.parse(result.template); // Template
                        this.previousTemplateData = JSON.parse(result.template);
                    }

                    if (result.objectLabel) {
                        this.objectlabel = result.objectLabel; // getting object Label
                    }

                    if (result.profileData) {
                        this.profile = JSON.parse(result.profileData); // get username and icon
                    }

                    // Get all templates
                    if (result.docList) {
                        this.allTemplates = JSON.parse(result.docList);
                        if (this.allTemplates && this.allTemplates.length > 0) {
                            this.setDateAndSize();
                            this.templates = this.allTemplates;
                        }
                    }

                    // Template Data
                    if (result.templateData) {
                        let templateData = JSON.parse(result.templateData);
                        this.webViewLink = templateData.MVDG__Google_Doc_WebViewLink__c;
                        this.Google_Doc_Template_Id__c = templateData.MVDG__Google_Doc_Template_Id__c;
                        this.documentName = templateData.MVDG__Google_Doc_Name__c;
                    } else {
                        this.isSpinner = false;
                        if (this.profile == null && result.templateData == null && this.allTemplates == null) {
                            this.showPopup = false;
                            const popup = this.template.querySelector("c-message-popup");
                            popup.showMessagePopup({
                                title: "No Google Integration Found",
                                message: "To create a new template, Google Drive integration is neccessary.",
                                status: "error"
                            });
                        } else {
                            this.showPopup = true;
                        }
                    }
                })
                .catch((error) => {
                    console.log("Error in getAllData:", error);
                    this.isSpinner = false;
                });
        } catch (error) {
            console.log("Error in getAllRelatedData:", error);
        }
    }

    resizeFunction = () => {
        // Added for keyMappingContainer...
        console.log("OUTPUT : resizeFunction1");
        // To Open/close keyMapping Container...
        if (window.innerWidth > 1435) {
            this.template.querySelector("c-key-mapping-container")?.toggleMappingContainer(false);
        } else {
            this.template.querySelector("c-key-mapping-container")?.toggleMappingContainer(true);
        }
    };

    closePopup() {
        console.log('this.closePopup');
        
        this.showPopup = false;
    }

    openPopup() {
        console.log('this.openPopup');
        this.showPopup = true;
    }

    handleTemplateClick(event) {
        try {
            console.log('handleTemplateClick');
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
            console.error("handleTemplateClick", error);
        }
    }

    refreshDocs() {
        try {
            console.log('this.refreshDocs');
            this.isSpinner = true;
            this.getAllRelatedData();
        } catch (error) {
            console.error("refreshDocs", error);
        }
    }

    next() {
        try {
            console.log('this.next');
            this.webViewLink = this.selectedTemplate.webViewLink;
            this.Google_Doc_Template_Id__c = this.selectedTemplate.id;
            this.documentName = this.selectedTemplate.name;
            this.isSpinner = true;

            this.closePopup();
            this.save();
        } catch (error) {
            console.error("next", error);
        }
    }

    cancel() {
        console.log('this.cancel');
        
        this.closePopup();
        this.navigateToComp("homePage", {});
    }

    setDateAndSize() {
        try {
            console.log('this.setDateAndSize');
            this.allTemplates = this.allTemplates.map((template) => {
                template.createdTime = template.createdTime.split("T")[0];
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
            console.error("error in setDateAndSize", error);
        }
    }

    handleSearch(event) {
        try {
            console.log('handleSearch');
            if (this.templates) {
                this.serachString = event.target.value;
                if (this.serachString) {
                    this.templates = this.allTemplates.filter((template) => {
                        return template.name.toLowerCase().includes(this.serachString.toLowerCase());
                    });
                } else {
                    this.templates = this.allTemplates;
                }
            }
        } catch (error) {
            console.error("handleSearch", error);
        }
    }

    save() {
        try {
            console.log('save');
            saveTemplateData({
                templateId: this.templateId,
                googleDocId: this.selectedTemplate.id,
                webViewLink: this.selectedTemplate.webViewLink,
                documentName: this.selectedTemplate.name
            })
                .then((response) => {
                    if (response === "success") {
                        console.log("Template Data Saved");
                    }
                })
                .catch((error) => {
                    console.log("Error saving template data ==> ", error);
                });
        } catch (error) {
            console.log("Error in save:", error);
        }
    }

    // -=-=- Used to navigate to the other Components -=-=-
    navigateToComp(componentName, paramToPass) {
        try {
            console.log("navigateToComp : ", componentName, paramToPass);
            let nameSpace = "c";
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
            console.log("encodedDef : ", encodedDef);
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: "/one/one.app#" + encodedDef
                }
            });
        } catch (error) {
            console.log("error in navigateToComp : ", error.stack);
        }
    }

    handlePreview() {
        console.log('this.handlePreview');
        this.isPreview = true;
    }

    handleClose() {
        console.log('this.handleClose');
        this.navigateToComp("homePage", {});
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
    //         console.log("error in showHideMappingContainer : ", error.stack);
    //     }
    // }

    openGenChildTablePopup(event) {

        const childObjectTableBuilder = this.template.querySelector("c-child-object-table-builder");
        console.log("event==>", event);
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
        console.log('this.activeTab');
        
        try {
            if (event) {
                this.activeTabName = event.currentTarget.dataset.name;
                if (this.activeTabName === "contentTab") {
                    this.isSpinner = true;
                }
            }
            this.setActiveTab();
        } catch (error) {
            console.log("error in templateBuilder.activeTab : ", error.stack);
        }
    }

    setActiveTab() {
        try {
            console.log("activeTabName : ", this.activeTabName);
            this.templateRecord = JSON.parse(JSON.stringify(this.previousTemplateData));

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
            console.log("error in setActive Tab : ", error.stack);
        }
    }

    iframeLoaded() {
        this.isSpinner = false;
    }

    closeTemplatePreview() {
        this.isPreview = false;
    }

    handleEditDetail(event) {
        try {
            console.log('this.handleEditDetail');
            
            const targetInput = event.currentTarget.dataset.name;
            if (targetInput === "MVDG__Template_Name__c") {
                const next = this.template.querySelector(".next");
                if (!event.target.value) {
                    event.currentTarget.classList.add("error-border");
                    next.setAttribute("disabled", true);
                } else {
                    event.currentTarget.classList.remove("error-border");
                    next.removeAttribute("disabled");
                }
            }

            if (event.target.type !== "checkbox") {
                this.templateRecord[targetInput] = event.target.value;
            } else {
                console.log("Status=>" + event.target.checked);
                this.templateRecord[targetInput] = !event.target.checked;
            }
        } catch (error) {
            console.log("error in handleEditDetail : ", error.stack);
        }
    }

    editTemplateDetails() {
        try {
            console.log('editTemplateDetails');
            this.isSpinner = true;
            this.loaderLabel = "Saving Your Data";
            editTemplate({ templateRecord: JSON.stringify(this.templateRecord) })
                .then(() => {
                    console.log("Details Edited");
                    this.isSpinner = false;
                    this.previousTemplateData = JSON.parse(JSON.stringify(this.templateRecord));
                    const popup = this.template.querySelector("c-message-popup");
                    popup.showMessageToast({
                        title: "Template Data Saved",
                        message: "Template data saved to backend succesfully.",
                        status: "success"
                    });
                })
                .catch((error) => {
                    console.log("Error in editTemplateDetails==> ", error);
                });
        } catch (error) {
            console.log("Error in editTemplateDetails: ", error);
        }
    }

    cancelEditTemplate() {
        try {
            console.log('cancelEditTemplate');
            this.isSpinner = true;
            console.log(this.previousTemplateData);
            console.log(this.templateRecord);

            this.template.querySelector(".next").removeAttribute("disabled");
            this.template.querySelector(`lightning-input[data-name="MVDG__Template_Name__c"]`).classList.remove("error-border");
            this.activeTabName = "contentTab";
            this.setActiveTab();
        } catch (error) {
            console.log("Error in cancelEditTemplate");
        }
    }
}
