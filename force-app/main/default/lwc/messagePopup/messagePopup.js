import { LightningElement, api, track } from "lwc";
import { errorDebugger } from "c/globalProperties";

// import { CloseActionScreenEvent } from 'lightning/actions';
export default class MessagePopup extends LightningElement {
    @track type;
    @track status;
    @track title;
    @track message;
    @track duration;
    timeoutInstance

    @track doneButtonLabel = 'Okay'

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

    customTimeout;
    renderedCallback(){
        if(!this.customTimeout){
            this.customTimeout = this.template.querySelector('c-custom-timeout');
        }
    }

    @api
    showMessagePopup(messageData){
        try {
            this.type = 'popup';
            this.status = messageData['status'] ? messageData['status'] : 'warning';
            this.title = messageData.title ? messageData.title : '';
            this.message = messageData.message ? messageData.message : '';
            this.doneButtonLabel = messageData?.doneButtonLabel ? messageData.doneButtonLabel : 'Okay';
            this.showPopup = true;
        } catch (error) {
            errorDebugger('MessagePopup', 'showMessagePopup', error, 'warn');
        }
    }

    @api
    showMessageToast(messageData){
        try {

            clearTimeout(this.timeoutInstance)

            this.type = 'toast';
            this.status = messageData['status'] ? messageData['status'].toLowerCase() : 'warning';
            this.title = messageData.title ? messageData.title : '';
            this.message = messageData.message ? messageData.message : '';
            const duration = messageData.duration ? messageData.duration : 5000;

            this.template.host.style.setProperty('--duration', duration + 'ms');

            this.showPopup = true;
            // this.timeoutInstance = setTimeout(() => {
            //     this.showPopup = false;
            // }, duration);

            this.customTimeout?.setCustomTimeoutMethod(() => {
                this.showPopup = false;
			}, duration);
            
        } catch (error) {
            errorDebugger('MessagePopup', 'showMessageToast', error, 'warn');
        }
    }

    closeToast = () => {
        this.showPopup = false;
    }

    removeElement(id){
        this.toastMessages = this.toastMessages.filter((toast) => { 
            return toast.id !== Number(id);
        });
    }

    handleConfirmation(event){
        try {
            event.preventDefault();
            var conform = event.currentTarget.dataset.name == 'conform' ? true : false;

            // Send data to parent compoent...
            // this.dispatchEvent(new CustomEvent('confirmation',{
            //     detail : conform
            // }));

            this.closeModal(conform);
            
        } catch (error) {
            errorDebugger('MessagePopup', 'handleConfirmation', error, 'warn');
        }
    }

    handleCloseModal(event){
        const conform = event.currentTarget.dataset.type === 'popup' ? true : false;
        this.closeModal(conform);
    }

    closeModal(conform){
        try {
            this.showPopup = false;
            this.status = '';
            this.title = '';
            this.message = '';
            this.duration = '';
            this.type = '';
            this.dispatchEvent(new CustomEvent('confirmation',{
                detail : conform
            }));

        } catch (error) {
            errorDebugger('MessagePopup', 'closeModal', error, 'warn');
        }
    }

    handleTimeout(event){
		try {
			if(event?.detail?.function){
				event?.detail?.function();
			}
		} catch (error) {
			errorDebugger('DocumentLoader', 'handleTimeout', error, 'warn')
		}
	}

}
