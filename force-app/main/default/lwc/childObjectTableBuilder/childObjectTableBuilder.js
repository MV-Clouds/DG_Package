import { LightningElement, track, api, wire } from 'lwc';
import { errorDebugger } from 'c/globalProperties';

export default class ChildObjectTableBuilder extends LightningElement {

    @track toggleGenChildTablePopup; 
    @track childRelationName;
    @track childObjAPI;
    @track childObjectLabel;

    @track childTableQuery;
    @track selectedFieldList;
    @track childTableData;
    @track showIndex;

    /**
     * Getter method to identify any child table generated or not to show info message.
     */
    get noChildTable(){
        return this.childTableQuery ? false : true;
    }

     /**
      * API Method to oped child object table generation popup(screen)
      * this method call from parent component.
      * @param {*} event 
      */
    @api
    openPopup(event){
        this.childRelationName = event.detail?.relationshipName;
        this.childObjAPI = event.detail?.childObjAPI;
        this.childObjectLabel = event.detail?.label;
        this.toggleGenChildTablePopup = true;
    }

    /**
     * API Method to close child object table generation popup(screen).
     * this method call from parent component.
     */
    @api
    closePopup(){
        this.childTableQuery =  null;
        this.selectedFieldList = null;
        this.childTableData = null;
        this.showIndex = null;
        this.toggleGenChildTablePopup = false;
    }

    /**
     * Method to handle table insert operation on button click.
     * @param {*} event 
     */
    handleTableInsert(event){
        this.childTableQuery =  event.detail?.query;
        this.selectedFieldList = event.detail?.selectedFields;
        this.childTableData = event.target?.generatedData;
        this.generateTable();
    }

    /**
     * Method to show-hide toggle index column in table.
     * @param {*} event 
     */
    toggleIndexColumn(event){
        this.showIndex = event.target.checked
        this.generateTable();
    }
    
    /**
     * Main method to perform table generation based on multiple scenarios.
     */
    generateTable(){
        try {
            var filters;
            var limit;
            if(this.childTableQuery.includes('WHERE')){
                if(this.childTableQuery.includes('LIMIT')){
                    const whereIndex  = this.childTableQuery.indexOf('WHERE');
                    const limitIndex  = this.childTableQuery.indexOf('LIMIT') + 5;
                    limit = this.childTableQuery.substring(limitIndex, this.childTableQuery.length).trim();
                    filters = this.childTableQuery.substring(whereIndex, limitIndex - 5);
                }
                else {
                    filters = this.childTableQuery.substring(whereIndex, this.childTableQuery.length);
                }
            } else if (this.childTableQuery.includes('ORDER BY')) {
                if(this.childTableQuery.includes('LIMIT')){
                    const orderbyIndex  = this.childTableQuery.indexOf('ORDER BY');
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
            
            if(this.selectedFieldList && this.selectedFieldList.length){
                const childTBody = this.template.querySelector('[data-name="childTBody"]');
                childTBody.innerHTML = '';

                const tdCSS = `   border: 1px solid #808080;
                                    padding: 5px 3px;
                                    overflow: hidden;
                                    text-align : center;
                `

                // ... Add label and info row into table ...
                const labelRow = document.createElement('tr');
                const keyRow = document.createElement('tr');
                keyRow.setAttribute('data-name', "keyRow");
                const infoRow = document.createElement('tr');
                infoRow.setAttribute('data-name', "infoRow");

                if(this.showIndex){
                    // ... Add index Column ...
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
                infoRow.appendChild(infoTd);

                childTBody.appendChild(labelRow);
                childTBody.appendChild(keyRow);
                childTBody.appendChild(infoRow);
            }
        } catch (error) {
            errorDebugger('ChildObjectTableBuilder', 'generateTable', error, 'warn');
        }
    }

    /**
     * Method to handle copy generated table to clipboard.
     * @param {*} event 
     */
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
                    // 'text/plain': new Blob([textarea.value], { type: 'text/plain' })
                })
            ]);

            // ...Show animation on copy...
            const copyBtn = event.currentTarget;
            copyBtn.classList.add('copied');
            setTimeout(() => {
                copyBtn.classList.remove('copied');
            }, 1001);

            document.body.removeChild(table); 

        } catch (error) {
            errorDebugger('ChildObjectTableBuilder', 'copyTable', error, 'warn');
        }
    }
}