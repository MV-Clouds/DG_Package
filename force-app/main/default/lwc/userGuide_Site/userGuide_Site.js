import { LightningElement, track } from 'lwc';
import docGeniusLogoSvg from "@salesforce/resourceUrl/docGeniusLogoSvg";
import { errorDebugger } from 'c/globalProperties';
import getAllUserGuides from '@salesforce/apex/UserGuideController.getAllUserGuides';

export default class UserGuide_Site extends LightningElement {
    docGeniusLogoSvg = docGeniusLogoSvg;

    @track userGuides = [];
    @track contentToDisplay = '';
    
    @track selectedImage;

    @track isClose = false;
    @track isSmallScreen = false;
    @track showModal = false;
    initialRender = true;

    connectedCallback(){
        try {

            if (typeof window !== 'undefined') {   
                window?.addEventListener('resize', this.resizeFunction);
                this.resizeFunction();
            }

            getAllUserGuides()
            .then(result => {
                if(result){
                    // result.forEach((ele, index) => {
                    //     this.userGuides.push({
                    //         content : ele.User_Guide_Content__c,
                    //         name : ele.Title,
                    //         selected : index === 0,
                    //     });
                    // })
                    this.setUserGuideStructure(result);
                }
            })
        } catch (error) {
            console.log('error in connectedCallback : ', error.stack);
        }
    }

    renderedCallback() {
        if (this.showModal) {
            window.addEventListener('keydown', this.handleKeyPress);
        } else {
            window.removeEventListener('keydown', this.handleKeyPress);
        }

        if(this.initialRender){
    
            const mainDiv = this.template.querySelector('.mainDiv-userGuide');
            if(mainDiv){
                const style = document.createElement('style');
                style.innerText =  `
                        .slds-rich-text-editor__output img{
                            margin-bottom : 0px !important;
                        }
                `;
                mainDiv.appendChild(style);
                this.initialRender = false;
            }
        }


        
    }

    // Use Arrow Function...
    resizeFunction = () => {
        
        // resize screen from small screen to big screen... open selection bar
        if(window.innerWidth >= 1120 && this.isSmallScreen && this.isClose) this.isClose = false;

        // resize screen from big screen to small screen... close selection bar
        if(window.innerWidth < 1120 && !this.isSmallScreen && !this.isClose) this.isClose = true;

        this.isSmallScreen = window.innerWidth < 1120;
    };

    setUserGuideStructure(guides_temp){
        try {
            var guideCategory = new Set();
            guides_temp?.forEach(ele => {
                var cate = ele.User_Guide_Category__c ?? 'Other';
                guideCategory.add(cate);
            });

            guideCategory?.forEach((ele, index) => {
                this.userGuides.push({
                    'category' : ele,
                    'opened' : index === 0,
                    'guides' : []
                });
            });

            guides_temp?.forEach((ele, index) => {
                var cate = ele.User_Guide_Category__c ?? 'Other';
                var guide = this.userGuides.find(ele => ele.category === cate);
                guide?.guides?.push({
                    'name' : ele.Title,
                    'content' : ele.User_Guide_Content__c,
                    'guideLogo' : ele.User_Guide_Logo__c,
                    'selected' : index === 0,
                });
            });

            setTimeout(() => {
                this.openGuideTypesHelper(this.userGuides[0]?.category);
            }, 500);

        } catch (error) {
            console.log('error in setUserGuideStructure : ', error.stack);
        }
    }

    closeModal() {
        this.showModal = false;
    }
    openModal = (event) => {
        this.selectedImage = event.target.src;
        this.showModal = true;
    }

    handleKeyPress = (event) => {
        if (event.key == 'Escape') {
            this.closeModal();
        }
    }

    // Switch Tabs
    handleTabSelection(event) {
        try {
            event.preventDefault();
            const targetedGuide = event.currentTarget.dataset.guide;

            let userGuides = [];
            this.userGuides?.forEach(item => {
                userGuides = userGuides.concat(item.guides);
            });

            userGuides.forEach(ele => {
            // this.userGuides.forEach(ele => {
                if (ele.name === targetedGuide) {
                    ele.selected = true;
                    this.contentToDisplay = ele.content;
                }
                else{
                    ele.selected = false;
                }
            });

            const scrollContent = this.template.querySelector('.white-background');
            console.log('scrollContent : ', scrollContent?.scrollTop);
            if(scrollContent) scrollContent.scrollTop = 0;
            this.addEventListenerToImages();


            // const guideContent = this.template.querySelector('.tab-content');
            // guideContent && (guideContent.innerHTML = this.contentToDisplay);

        } catch (error) {
            errorDebugger("userGuide", 'handleTabSelection', error, 'error', 'Error in changing tabs. Please try again later');
        }
    }

    addEventListenerToImages(){
        try{
            const content = this.template.querySelector('.content');
            const contentImages = content.querySelectorAll('img');
            contentImages.forEach(ele => {
                ele.addEventListener('click', this.openImages);
            })
        }
        catch(error){
            console.log(`error in addEventListenerToImages : ${error.message}`);
        }
    }

    toggleTab() {
        this.isClose = !this.isClose;
    }  


    // ================ =============== ================= ================= ==================

    openGuideTypes(event){
        this.openGuideTypesHelper(event.currentTarget.dataset.category);
    }

    openGuideTypesHelper(targetCategory){
        try {
            const targetDiv = this.template.querySelector(`[data-tablist="${targetCategory}"]`);
            const targetedCate = this.userGuides?.find(ele => ele.category === targetCategory);
            const maxHeight = targetedCate.opened ? 0 : targetDiv?.scrollHeight;
            targetDiv.style = `--openedMaxHeight : ${maxHeight}px`;
            targetedCate.opened = !targetedCate.opened;
            
            // this.userGuides?.forEach(ele => {
            //     const targetDiv = this.template.querySelector(`[data-tablist="${ele.category}"]`);
            //     if(ele.category === targetCategory){
            //         const maxHeight = ele.opened ? 0 : targetDiv?.scrollHeight;
            //         targetDiv.style = `--openedMaxHeight : ${maxHeight}px`;
            //         ele.opened = !ele.opened;
            //     }
            //     else{
            //         targetDiv.style = ``
            //         ele.opened = false;
            //     }
            // })
            
        } catch (error) {
            console.log(`error in openGuideTypes : ${error.message}`);
        }
    }


}