import { LightningElement } from 'lwc';
import Userguide from "@salesforce/resourceUrl/Userguide";


export default class UserGuide extends LightningElement {
    get aws1(){
        return Userguide + '/aws1.png';
    }

    get aws2(){
        return Userguide + '/aws2.png';
    }

    get aws3(){
        return Userguide + '/aws3.png';
    }

    get aws4(){
        return Userguide + '/aws4.png';
    }
    get aws5(){
        return Userguide + '/aws5.png';
    }

    get aws6(){
        return Userguide + '/aws6.png';
    }

    get aws7(){
        return Userguide + '/aws7.png';
    }

    get aws8(){
        return Userguide + '/aws8.png';
    }
    activeSections = [];

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
    }

    renderedCallback(){
        // const el = document.querySelectorAll('lightning-accordion-section');
        // const shadowRoot = el.attachShadow({mode: 'open'});
        // shadowRoot.style = 'border-radius: 5px';
    }
}