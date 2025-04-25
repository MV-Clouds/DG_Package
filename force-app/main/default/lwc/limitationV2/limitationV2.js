import { LightningElement, track } from 'lwc';

export default class LimitationV2 extends LightningElement {
    @track activeTab = 'text0';
    @track isStorage = false;
    @track isTemplate = true;
    @track isDocument = false;

    handleSetActive(event){
        const tabName = event.currentTarget.dataset.name;
        if(this.activeTab != tabName){
            this.isSpinner = true;
            this.activeTab = tabName;
            this.isStorage = false;
            this.isTemplate = false;
            this.isDocument = false;
            const button = this.template.querySelectorAll('.button');
            button?.forEach(ele => {
                if(ele.dataset.name == tabName){
                    ele.classList.add('enable');
                    if(tabName == 'text0'){
                        this.isTemplate = true;
                        this.isSpinner = false;
                    }
                    else if(tabName == "text1"){
                        this.isStorage  = true;
                        this.isSpinner = false;
                    }
                    else if(tabName == "text2"){
                        this.isDocument = true;
                        this.isSpinner = false;
                    }
                }
                else{
                    ele.classList.remove('enable');
                }
            })
        }
    }
}