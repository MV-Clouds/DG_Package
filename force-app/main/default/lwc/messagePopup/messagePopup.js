import { LightningElement, api, track, wire } from "lwc";
import { CloseActionScreenEvent } from 'lightning/actions';
export default class MessagePopup extends LightningElement {
    @track type;
    @track status;
    @track title;
    @track message;
    @track duration;

    @track showPopup = false;
    designCurveColor = '#00ffee5c';
    statusIconColor = '#007ca0';

    CSSvalues = {
        success : {designCurveColor : '#3dd06c33', statusIconColor : '#2E844A'},
        error: {designCurveColor : '#FF000033', statusIconColor : '#FF0000'},
        warning : {designCurveColor : '#FEF7D1', statusIconColor : '#d8a835'},
        info : {designCurveColor : '#68CEFE', statusIconColor : '#03a5f1'}
    }

    get isPopupType(){
        if(this.type == 'popup'){
            return true;
        }
        else{
            return false;
        }
    }

    get isSuccess(){
       return this.status.toLowerCase() == 'success' ? true : false;
    }

    get isError(){
        return this.status.toLowerCase() == 'error' ? true : false;
    }

    get isWarning(){
        return this.status.toLowerCase() == 'warning' ? true : false;
    }

    get showDoneBtn(){
        return this.status.toLowerCase() != 'warning' ? true : false;
    }

    get loadStyle(){
        if(this.status.toLowerCase() == 'success'){
            this.designCurveColor = this.CSSvalues.success.designCurveColor;
            this.statusIconColor = this.CSSvalues.success.statusIconColor;
        }
        else if(this.status.toLowerCase() == 'error'){
            this.designCurveColor = this.CSSvalues.error.designCurveColor;
            this.statusIconColor = this.CSSvalues.error.statusIconColor;
        }
        else if(this.status.toLowerCase() == 'warning'){
            this.designCurveColor = this.CSSvalues.warning.designCurveColor;
            this.statusIconColor = this.CSSvalues.warning.statusIconColor;
        }
        else{
            this.designCurveColor = this.CSSvalues.info.designCurveColor;
            this.statusIconColor = this.CSSvalues.info.statusIconColor;
        }
        return `
            --designCurveColor : ${this.designCurveColor};
            --statusIconColor : ${this.statusIconColor};
        `;
    }

    get loadDuration(){
        return `--duration : ${this.duration/1000}s`;
    }

    isInitial = true;
    renderedCallback(){
        try {

            
            
        } catch (error) {
            console.error('error in renderedCallback : ', error.stack);
        }
    }

    @api
    showMessagePopup(messageData){
        try {
            this.type = 'popup';
            this.status = messageData['status'] ? messageData['status'] : 'warning';
            this.title = messageData.title ? messageData.title : '';
            this.message = messageData.message ? messageData.message : '';
            this.showPopup = true;
        } catch (error) {
            console.error('error in showPopup poupMessgae : ', error.stack);
        }
    }

    @api
    showMessageToast(messageData){
        try {
            this.showPopup = true;

            this.type = 'toast';
            this.status = messageData['status'] ? messageData['status'].toLowerCase() : 'warning';
            this.title = messageData.title ? messageData.title : '';
            this.message = messageData.message ? messageData.message : '';
            const duration = messageData.duration ? messageData.duration : 5000;

            this.template.host.style.setProperty('--duration', duration + 'ms');

            setTimeout(() => {
                this.showPopup = false;
            }, duration);
            
        } catch (error) {
            console.error('error in showToast poupMessgae : ', error.stack);
        }
    }

    closeToast = () => {
        this.showPopup = false;
    }

    // @track toastMessages = [];

    // @api
    // showMessageToast(messageData){
    //     try {

    //         if(this.toastMessages?.length < 5){
    //             const toastInstance = {};
    //             toastInstance.id = new Date().valueOf() + this.toastMessages.length;
    //             toastInstance.status = messageData['status'] ? messageData['status'].toLowerCase() : 'warning';
    //             toastInstance.title = messageData.title ? messageData.title + this.toastMessages.length : '';
    //             toastInstance.message = messageData.message ? messageData.message : '';
    //             toastInstance.duration = messageData.duration ? messageData.duration : 5000;
    //             toastInstance.isSuccess = toastInstance.status === 'success';
    //             toastInstance.isError = toastInstance.status === 'error';
    //             toastInstance.isWarning = toastInstance.status === 'warning';
    //             toastInstance.showDoneBtn = toastInstance.status === 'warning';
            
    //             this.toastMessages.unshift(toastInstance);

    //             setTimeout(() => {
    //                 const currentToastEle = this.template.querySelector(`[data-toast="${toastInstance.id}"]`);
    //                 currentToastEle && (currentToastEle.style = `--duration : ${toastInstance.duration}ms`);
    //                 currentToastEle?.addEventListener('animationend', this.closeToastMessage)
    //                 console.log('currentToastEle : ', toastInstance.id);
    //             }, 500);
    //         }

            
    //     } catch (error) {
    //         console.log('error in showMessageToast bulk', error.stack);
    //     }
    // }

    // closeToastMessage = (event) => {
    //     console.log('close toast id : ', event.currentTarget.dataset.toast);
    //     const currentToastEle = this.template.querySelector(`[data-toast="${event.currentTarget.dataset.toast}"]`);
    //     currentToastEle?.removeEventListener('animationend', null)
    //     this.removeElement(event.currentTarget.dataset.toast)
    // }

    // closeToast(event){
    //     this.removeElement(event.currentTarget.dataset.id)
    // }

    removeElement(id){
        this.toastMessages = this.toastMessages.filter((toast) => { 
            return toast.id !== Number(id);
        });
    }

    closeModal(event){
        try {
            this.dispatchEvent(new CustomEvent('confirmation'));
            this.showPopup = false;
            this.status = '';
            this.title = '';
            this.message = '';
            this.duration = '';
            this.type = '';
        } catch (error) {
            console.error('error in closeModal poupMessgae', error.stack);
        }
    }

    handleConfirmation(event){
        try {
            event.preventDefault();
            var conform = event.currentTarget.dataset.name == 'conform' ? true : false;

            // Send data to parent compoent...
            this.dispatchEvent(new CustomEvent('confirmation',{
                detail : conform
            }));

            this.closeModal();
            
        } catch (error) {
            console.error('error in handleConfirmation poupMessgae : ', error.stack);
        }
    }

}