import { LightningElement, api, track } from "lwc";
import pdfLibs from "@salesforce/resourceUrl/pdfLibs";
import { loadScript } from "lightning/platformResourceLoader";
import { errorDebugger } from "c/globalProperties";

export default class PreviewGoogleDocumentV2 extends LightningElement {
    @api templateid;
    @api objectname;
    @api objectlabel;
    @api recordId;
    @api usedFrom;
    @api googleDocId;

    @track isPreview = true;
    @track spinnerLabel = "Fetching records... Please wait";
    @track isSpinner;

    @track blobFile;
    @track currentPage = 1;

    isExecuting = false;
    fieldMap = new Map();

    initalLoad = true;
    zoomLevel = 100;
    pdfPages = 1;

    renderedCallback() {
        try {
            loadScript(this, pdfLibs + "/pdfJS/web/pdf.js").then(() => {
                
            });

            if (this.initalLoad) {
                this.content = this.template.querySelector(".content");
                this.content_sub = this.template.querySelector(".content_sub");
                this.pdf_content = this.template.querySelector(".pdf_content");

                this.pageToSet = this.template.querySelector('[data-name="pageToSet"]');
                this.pagePlus = this.template.querySelector('[data-name="pagePlus"]');
                this.pageMinus = this.template.querySelector('[data-name="pageMinus"]');

                if (this.content) {
                    this.initalLoad = false;
                }
            }
        } catch (error) {
            errorDebugger("PreviewGoogleDocument", "renderedCallback", error, 'error', 'Error in rendered Callback. Please try again later');
        }
    }

    @api previewDocument() {
        try {
            this.isPreview = true;
            this.pdf_content.replaceChildren();

            let generator = this.template.querySelector("c-generate-google-doc-file");
            
            if (generator) {
                this.spinnerLabel = "Fetching records... Please wait";
                this.isSpinner = true;
                generator.generateDocument(this.templateid, this.objectname, this.recordId, ".pdf");
            } else {
                // console.error("Error in getting files");
                errorDebugger('CustomRecordPicker', 'setCustomTimeoutMethod', {message : 'Error in getting files'}, 'warn');

            }
        } catch (error) {
            errorDebugger("PreviewGoogleDocument", "previewDocument", error, 'error', 'Error in preview Document. Please try again later');
        }
    }

    @api downloadFile() {
        this.isSpinner = true;
        try {
            if (this.blobFile) {
                let len = this.blobFile.length;
                let bytes = new Uint8Array(len);
                for (let i = 0; i < len; i++) {
                    bytes[i] = this.blobFile.charCodeAt(i);
                }
                let blob = new Blob([bytes], { type: "application/octet-stream" });

                let link = document.createElement("a");
                link.href = URL.createObjectURL(blob);
                link.download = this.objectname;

                document.body.appendChild(link);
                link.click();
                this.isSpinner = false;
            } else {
                this.isPreview = false;
                let generator = this.template.querySelector("c-generate-google-doc-file");
                generator.generateDocument(this.templateid, this.objectname, this.recordId, ".pdf");
                // this.handleError({ detail: { title: 'Error', message: 'Unable to load the document.' } })
            }
        } catch (error) {
            this.isSpinner = false;
            this.handleError({ detail: { title: "Error", message: error } });
            errorDebugger("PreviewGoogleDocument", "handleError", error, 'error', 'Error in handleError. Please try again later');
        }
    }

    handleSpinnerLabelUpdate() {
        this.spinnerLabel = "Please wait.. We are generating the document.";
    }

    handleError(event) {
        try {
            
            
            this.isSpinner = false;
            let messagePopup = this.template.querySelector("c-message-popup");
            messagePopup?.showMessagePopup({
                status: "error",
                title: event.detail.title,
                message: event.detail.desc
            });

            
        } catch (error) {
            errorDebugger("PreviewGoogleDocument", "handleError", error, 'error', 'Error in handleError. Please try again later');
        }
    }

    handleFileProcess(event) {
        try {
            
            let file = event.detail.blob;
            this.blobFile = atob(file);

            if (this.isPreview) {
                this.displayPDF(this.blobFile);
            } else {
                this.downloadFile();
                this.isPreview = true;
            }
        } catch (error) {
            errorDebugger("PreviewGoogleDocument", "handleFileProcess", error, 'error', 'Error in handleFileProcess. Please try again later');
        }
    }

    displayPDF(pdfBlob) {
        var loadingTask = window.pdfjsDistBuildPdf.getDocument({ data: pdfBlob });
        try {
            
            loadingTask.promise.then((pdf) => {
                const totalPagesInput = this.template.querySelector('[data-name="totalPages"]');
                if (totalPagesInput) {
                    totalPagesInput.value = pdf.pdfInfo.numPages;
                }
                const pageToSetInut = this.template.querySelector('[data-name="this.pageToSet"]');
                if (pageToSetInut) {
                    pageToSetInut.value = this.currentPage;
                }

                this.pdfPages = pdf.pdfInfo.numPages;

                for (let i = 1; i <= pdf.pdfInfo.numPages; i++) {
                    pdf.getPage(i).then((page) => {
                        var scale = 1.5;
                        // Support HiDPI-screens.

                        var viewport = page.getViewport(scale);

                        var canvas = document.createElement("canvas");
                        this.pdf_content.appendChild(canvas);
                        let context = canvas.getContext("2d");

                        canvas.width = Math.floor(viewport.width);

                        canvas.height = Math.floor(viewport.height);
                        canvas.classList.add("canvasClass");
                        canvas.style = `aspect-ratio : ${viewport.width / viewport.height}; width: 100%; border-radius: 4px; box-shadow: rgb(0 0 0 / 35%) 0px 3px 6px, rgb(0 0 0 / 37%) 0px 3px 6px;`;

                        // var transform = outputScale !== 1 ? [Print_unit, 0, 0, Print_unit, 0, 0] : null;
                        // transform: transform,

                        // Render PDF page into canvas context
                        let renderContext = {
                            canvasContext: context,
                            viewport: viewport,
                            intent: "print"
                        };

                        page.render(renderContext);
                        
                    });
                }
                this.isSpinner = false;
            });
        } catch (error) {
            errorDebugger("PreviewGoogleDocument", "displayPDF", error, 'error', 'Error in displayPDF. Please try again later');
        }
    }

    // ************** Zoom ality Method -- START -- ***************
    setZoomLevel(event) {
        var zoomOffset = 10;
        try {
            
            const clickedButton = event.currentTarget.dataset.name;
            
            if (this.zoomLevel <= 25) {
                zoomOffset = clickedButton === "zoomIn" ? 0 : zoomOffset;
            }
            if (this.zoomLevel > 25 && this.zoomLevel < 50) {
                zoomOffset = 5;
            } else if (this.zoomLevel >= 50 && this.zoomLevel < 200) {
                zoomOffset = 10;
            } else if (this.zoomLevel >= 200 && this.zoomLevel < 500) {
                zoomOffset = 25;
            } else if (this.zoomLevel >= 500) {
                zoomOffset = clickedButton === "zoomOut" ? 0 : 25;
            }
            
            if (clickedButton === "zoomIn") {
                this.zoomLevel = this.zoomLevel - zoomOffset;
            } else if (clickedButton === "zoomOut") {
                this.zoomLevel = this.zoomLevel + zoomOffset;
            }
            
            this.content_sub.style = `--zoomLevel : ${this.zoomLevel}% !important;`;
            
            const zoomInfo = this.template.querySelector(".zoomInfo");
            zoomInfo.innerText = this.zoomLevel + "%";
        } catch (error) {
            errorDebugger("previewGoogleDocument", "setZoomLevel", error, 'error', 'Error in setZoomLevel. Please try again later');
        }
    }
        // ************** Zoom ality Method -- END -- ***************
        
        // ************** Page No. ality Method -- START -- ***************
        
        onscroll() {
            var previousPageNo = this.currentPage;
            try {
                
                const singlePageHeight = this.content.scrollHeight / this.pdfPages;
                
                this.currentPage = Math.floor(this.content.scrollTop / (singlePageHeight - 8) + 1);
                
                if (previousPageNo !== this.currentPage) {
                    const pageToSetInut = this.template.querySelector('[data-name="pageToSet"]');
                    pageToSetInut.value = this.currentPage;
                }
                
                const scrollToTopBtn = this.template.querySelector(".scrollTopBtn");
                if (this.content.scrollTop > 0) {
                    scrollToTopBtn.style = "display : block !important";
                } else {
                    scrollToTopBtn.style = "";
                }
                
                this.setPageBtnStatus();
            } catch (error) {
                errorDebugger("previewGoogleDocument", "onscroll", error, 'error', 'Error in onscroll. Please try again later');
            }
    }

    onPageChange(event) {
        
        
        var pageNoToSet = this.currentPage;
        try {
            const dataName = event.currentTarget.dataset.name;
            
            if (dataName === "pageToSet") {
                pageNoToSet = event.target.value;
            } else if (dataName === "pagePlus") {
                pageNoToSet = Number(this.currentPage) + 1;
            } else if (dataName === "pageMinus") {
                pageNoToSet = Number(this.currentPage) - 1;
            }
            
            if ((pageNoToSet > this.pdfPages || pageNoToSet <= 0) && pageNoToSet !== "") {
                this.pageToSet.value = this.currentPage;
            } else {
                if (pageNoToSet !== this.currentPage && pageNoToSet !== "") {
                    const singlePageHeight = this.content.scrollHeight / this.pdfPages;
                    this.content.scrollTop = singlePageHeight * (pageNoToSet - 1);
                    // this.currentPage = pageNoToSet;
                }
            }
            
            this.setPageBtnStatus();
        } catch (error) {
            errorDebugger("previewGoogleDocument", "onPageChange", error, 'error', 'Error in onPageChange. Please try again later');
        }
    }

    setPageBtnStatus() {
        try {
            if (this.currentPage <= 1) {
                this.pageMinus.setAttribute("disabled", "true");
            } else {
                this.pageMinus.removeAttribute("disabled");
            }
            
            if (this.currentPage >= this.pdfPages) {
                this.pagePlus.setAttribute("disabled", "true");
            } else {
                this.pagePlus.removeAttribute("disabled");
            }
        } catch (error) {
            errorDebugger("previewGoogleDocument", "setPageBtnStatus", error, 'error', 'Error in setPageBtnStatus. Please try again later');
            
        }
    }

    scrollToTop() {
        
        
        this.content.scrollTop = 0;
        this.onscroll();
    }

    // ======= ========= ======== ========= ==========
}