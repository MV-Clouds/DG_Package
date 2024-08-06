import { LightningElement } from 'lwc';

export default class Limitation extends LightningElement {
    activeSections = [];

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;
    }
}