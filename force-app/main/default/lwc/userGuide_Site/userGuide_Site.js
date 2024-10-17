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
    @track showImageModal = false;
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
        if (this.showImageModal) {
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

            console.log('this.userGuides : ', this.userGuides);
            

            setTimeout(() => {
                // Set first  user guide content to display...
                const guide1 = this.userGuides[0];
                this.setContentToDisplay(guide1?.guides[0].content);

                // Open first category accordion and select first user guide tab...
                this.openGuideTypesHelper(this.userGuides[0]?.category);
            }, 500);

        } catch (error) {
            errorDebugger("userGuide", 'setUserGuideStructure', error, 'error');
        }
    }

    handleKeyPress = (event) => {
        if (event.key == 'Escape') {
            this.closeImageModal();
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
                    this.setContentToDisplay(ele.content);
                }
                else{
                    ele.selected = false;
                }
            });

            // const guideContent = this.template.querySelector('.tab-content');
            // guideContent && (guideContent.innerHTML = this.contentToDisplay);

        } catch (error) {
            errorDebugger("userGuide", 'handleTabSelection', error, 'error');
        }
    }

    setContentToDisplay(content){
        try {
            const richTextDiv = this.template.querySelector(`[data-name="richText"]`);
            if(richTextDiv){
                richTextDiv && (richTextDiv.innerHTML = content);
    
                const scrollContent = this.template.querySelector('.white-background');
                if(scrollContent) scrollContent.scrollTop = 0;
    
                this.addEventListenerToImages();
            }
            else{
                // if richTextDiv not rendered, call this method again...
                this.setContentToDisplay(content);
            }
        } catch (error) {
            errorDebugger("userGuide", 'setContentToDisplay', error, 'error', 'Error in changing tabs. Please try again later');
        }
    }

    /**
     * Add event listener to Images when user change user guide tab
     */
    addEventListenerToImages(){
        try{
            const content = this.template.querySelector('.content')
            const contentImages = content?.querySelectorAll('img');
            contentImages.forEach(ele => {
                // ...First remove existing Eventlistener to avoid any conflict...
                ele.removeEventListener('click', null);
                ele.addEventListener('click', this.openImagesModal);
            })
        }
        catch(error){
            errorDebugger("userGuide", 'addEventListenerToImages', error, 'error');
        }
    }

    /**
     * To Open Content Image in popup
     */
    openImagesModal = (event) => {
        console.log('open image in popup : ', event.target.src);
        this.showImageModal = true;
        this.selectedImage = event.target.src;
    }

    closeImageModal() {
        this.showImageModal = false;
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
            
            // ... For Single accordion opening ...

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
            errorDebugger("userGuide", 'openGuideTypesHelper', error, 'error');
        }
    }


}