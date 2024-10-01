import { LightningElement, track } from 'lwc';
import docGeniusLogoSvg from "@salesforce/resourceUrl/docGeniusLogoSvg";
import { errorDebugger } from 'c/globalProperties';
import getAllUserGuides from '@salesforce/apex/UserGuideController.getAllUserGuides';

export default class UserGuide_Site extends LightningElement {
    docGeniusLogoSvg = docGeniusLogoSvg;

    @track userGuides = [];
    @track contentToDisplay = '';
    
    @track selectedImage;

    @track isOpen = true;
    @track showModal = false;

    connectedCallback(){
        try {
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
    }

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
            event.preve
            const targetedGuide = event.currentTarget.dataset.guide;
            let contentToDisplay = '';

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
        if(this.isOpen) {
            this.closeTab();
        } else if (!this.isOpen) {
            this.openTab();
        }
    }

    openTab() {
        this.template.querySelector('.svg-arrow').style.transform = 'rotate3d(0, 1, 0, 180deg)';
        this.template.querySelector('.left-section').style = '';
        // this.template.querySelector('.container').style.gap = '20px';
        this.isOpen = true;
    } 
    
    closeTab() {
        this.template.querySelector('.svg-arrow').style.transform = 'rotate3d(0, 0, 0, 180deg)';
        this.template.querySelector('.left-section').style.width = '0';
        this.template.querySelector('.left-section').style.paddingInline = '0';
        // this.template.querySelector('.container').style.gap = '0';
        this.isOpen = false;
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