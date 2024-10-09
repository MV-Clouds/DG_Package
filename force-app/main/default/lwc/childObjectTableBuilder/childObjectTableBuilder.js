import { LightningElement, track, api } from 'lwc';
import { errorDebugger } from "c/globalProperties";

export default class ChildObjectTableBuilder extends LightningElement {

    @track toggleGenChildTablePopup;
    @track childRelationName;
    @track childObjAPI;
    @track childObjectLabel;

    @track childTableQuery;
    @track selectedFieldList;
    @track childTableData;
    @track showIndex;

    get noChildTable(){
        return this.childTableQuery ? false : true;
   }

   customTimeout;
   renderedCallback(){
       if(!this.customTimeout){
           this.customTimeout = this.template.querySelector('c-custom-timeout');
       }
   }

     // #Child Object Table Method....
     @api
     openPopup(event){
        this.childRelationName = event.detail?.relationshipName;
        this.childObjAPI = event.detail?.childObjAPI;
        this.childObjectLabel = event.detail?.label;
        this.toggleGenChildTablePopup = true;
    }

    // #Child Object Table Method....
    @api
    closePopup(){
        this.childTableQuery =  null;
        this.selectedFieldList = null;
        this.childTableData = null;
        this.showIndex = null;
        this.toggleGenChildTablePopup = false;
    }

    // #Child Object Table Method....
    handleTableInsert(event){
        this.childTableQuery =  event.detail?.query;
        this.selectedFieldList = event.detail?.selectedFields;
        this.childTableData = event.target?.generatedData;
        this.generateTable();
    }

    // #Child Object Table Method....
    regenerateTable(event){
        this.showIndex = event.target.checked
        this.generateTable();
    }
    
    // #Child Object Table Method....
    generateTable(){
        try {
            var filters;
            var limit;
            if(this.childTableQuery.includes('WHERE')){
                const whereIndex  = this.childTableQuery.indexOf('WHERE');
                if(this.childTableQuery.includes('LIMIT')){
                    const limitIndex  = this.childTableQuery.indexOf('LIMIT') + 5;
                    limit = this.childTableQuery.substring(limitIndex, this.childTableQuery.length).trim();
                    filters = this.childTableQuery.substring(whereIndex, limitIndex - 5);
                }
                else {
                    filters = this.childTableQuery.substring(whereIndex, this.childTableQuery.length);
                }
            } else if (this.childTableQuery.includes('ORDER BY')) {
                const orderbyIndex  = this.childTableQuery.indexOf('ORDER BY');
                if(this.childTableQuery.includes('LIMIT')){
                    const limitIndex  = this.childTableQuery.indexOf('LIMIT') + 5;
                    limit = this.childTableQuery.substring(limitIndex, this.childTableQuery.length).trim();
                    filters = this.childTableQuery.substring(orderbyIndex, limitIndex - 5);
                }
                else {
                    filters = this.childTableQuery.substring(orderbyIndex, this.childTableQuery.length);
                }
            } else if(this.childTableQuery.includes('LIMIT')){
                const limitIndex  = this.childTableQuery.indexOf('LIMIT') + 5;
                limit = this.childTableQuery.substring(limitIndex, this.childTableQuery.length).trim();
            }

            // console.log('filters : ', filters);
            // console.log('limit : ', limit);
            
            if(this.selectedFieldList && this.selectedFieldList.length){
                const childTBody = this.template.querySelector('[data-name="childTBody"]');
                childTBody.replaceChildren();

                const tdCSS = `   border: 1px solid #808080;
                                    padding: 5px 3px;
                                    overflow: hidden;
                                    text-align : center;
                `

                const labelRow = document.createElement('tr');
                const keyRow = document.createElement('tr');
                keyRow.setAttribute('data-name', "keyRow");
                const infoRow = document.createElement('tr');
                infoRow.setAttribute('data-name', "infoRow");


                if(this.showIndex){
                    const labelTd = document.createElement('td');
                    labelTd.style = tdCSS;
                    labelTd.textContent = 'No.';
                    const keyTd = document.createElement('td');
                    keyTd.style = tdCSS;
                    keyTd.textContent = '{{No.Index}}';
                    labelRow.appendChild(labelTd);
                    keyRow.appendChild(keyTd);
                }

                const selectedFieldList = this.selectedFieldList;
                for(var i = 0; i < selectedFieldList.length; i++){
                    let fieldInfo = selectedFieldList[i];
                    const labelTd = document.createElement('td');
                    labelTd.style = tdCSS;
                    const keyTd = document.createElement('td');
                    keyTd.style = tdCSS;
                    labelTd.textContent = fieldInfo.fieldName;
                    keyTd.textContent = `{{!${fieldInfo.apiName}}}`;
                    labelRow.appendChild(labelTd);
                    keyRow.appendChild(keyTd);
                }

                const infoTd = document.createElement('td');
                infoTd.setAttribute('colspan', this.showIndex ? (selectedFieldList.length + 1) : selectedFieldList.length);
                infoTd.style = `position : relative; padding: 5px 3px; border: 1px solid rgb(203, 203, 203) !important; color: rgb(76, 76, 76) !important; text-align: center; overflow : hidden;`;
                infoTd.innerText = `Object: ${this.childObjectLabel},
                                    $objApi:${this.childObjAPI}$, $childRelation:${this.childRelationName}$, $limit:${limit ? limit : '20'}$, ${filters ? `, $filter:${filters}$` : ``}
                                    `;

                // const overlay = document.createElement('div');
                // overlay.setAttribute('data-name', "overlay");
                // overlay.style = `position: absolute; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0); z-index: 9;`;
                // infoTd.appendChild(overlay);
                infoRow.appendChild(infoTd);

                childTBody.appendChild(labelRow);
                childTBody.appendChild(keyRow);
                childTBody.appendChild(infoRow);
            }
        } catch (error) {
            errorDebugger('HomePage', 'generateTable', error, 'warn');

        }
    }

    // #Child Object Table Method....
    copyTable(event){
        try {
            const table = document.createElement('table');
            table.setAttribute('data-name', "childRecords");            

            const childTBody = this.template.querySelector('[data-name="childTBody"]');

            let tableBody = null;
            childTBody && (tableBody = childTBody.cloneNode(true));
            tableBody && tableBody.removeAttribute('data-name');
            tableBody && tableBody.classList.remove('childTBody');

            table.appendChild(tableBody);
            document.body.appendChild(table);

            navigator.clipboard.write([
                new ClipboardItem({
                    'text/html': new Blob([table.outerHTML], { type: 'text/html' }),
                })
            ]);
            // 'text/plain': new Blob([textarea.value], { type: 'text/plain' })

            // Show animation on copy...
            const copyBtn = event.currentTarget;
            copyBtn.classList.add('copied');
            // setTimeout(() => {
            //     copyBtn.classList.remove('copied');
            // }, 1001);

            this.customTimeout?.setCustomTimeoutMethod(() => {
                copyBtn.classList.remove('copied');
			}, 1001)

            document.body.removeChild(table); 

        } catch (error) {
            errorDebugger('HomePage', 'copyTable', error, 'warn');

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