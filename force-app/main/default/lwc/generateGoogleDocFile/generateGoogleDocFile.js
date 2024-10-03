import { api, track, LightningElement } from "lwc";
import copyGoogleDoc from "@salesforce/apex/GoogleDocPreview.copyGoogleDoc";
import doPreview from "@salesforce/apex/GoogleDocPreview.doPreview";
import mapFieldValues from "@salesforce/apex/GoogleDocPreview.mapFieldValues";
import { errorDebugger } from "c/globalProperties";

export default class GenerateGoogleDocFile extends LightningElement {
    @api objectlabel;
    @api usedFrom;
    @api googleDocId;

    @track signatureKey = "{{Sign.DocGenius *Signature Key*}}";
    @track templateid;
    @track objectname;
    @track recordId;
    @track format;

    @track tableOffset;
    @track changeRequests;
    @track allFields;
    @track responseBody;
    @track resultSet;

    @track documentId;
    @track docPageSize = {};
    @track signatureSize;

    @api generateDocument(templateid, objectname, recordId, format) {
        try {
            
            this.templateid = templateid;
            this.objectname = objectname;
            this.recordId = recordId;
            this.format = format;

            this.tableOffset = 0;
            this.changeRequests = [];
            this.allFields = [];
            console.log("Called when the preview button is pressed");

            // Make apex callout to copy the document and get the JSON of the Google Document
            copyGoogleDoc({ templateId: this.templateid })
                .then((result) => {

                    // Setting the signature size according to the page width
                    this.signatureSize = result.width !== null ? result.width : 50;
                    if (this.signatureSize > 100) {
                        this.signatureSize = 100;
                    } else if (this.signatureSize <= 0) {
                        this.signatureSize = 1;
                    }

                    if (result.document) {

                        // Get the field values from the record
                        this.responseBody = JSON.parse(result.document);
                        console.log("this.responseBody==>", this.responseBody);

                        this.documentId = this.responseBody.documentId;
                        this.docPageSize.pageSize = this.responseBody.documentStyle.pageSize;
                        this.docPageSize.marginLeft = this.responseBody.documentStyle.marginLeft;
                        this.docPageSize.marginRight = this.responseBody.documentStyle.marginRight;

                        this.dispatchEvent(new CustomEvent("changespinnerlabel"));
                        this.formatContent(this.responseBody);
                    } else if (result.error) {
                        
                        // If the callout fails, show toast
                        let errorList = result.error.split(":");
                        this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: 'Error', message: errorList[3], desc: errorList[2] } }));
                        errorDebugger("generateGoogleDocFile", "generateDocument", errorList, 'Error', errorList[2]);
                    }
                })
                .catch((error) => {
                    console.log("error in copyGoogleDoc - LWC", error);
                    this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: error , desc: "Something went wrong. Please refresh the page and try again." } }));
                });
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "generateDocument", error, 'Error', "Error in generating template. Please try again.");
            this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: error , desc: "Something went wrong. Please refresh the page and try again." } }));
        }
    }

    formatContent(body) {
        var content = body.body.content;
        var objectDetails = [];
        var tableNo = 0;
        try {
            console.log("content \n", content);
            content.forEach((element) => {
                if (element.table) {
                    let object = {};
                    let matcher, pattern;
                    let stringBody = JSON.stringify(element);

                    // get table fields
                    pattern = /{{!(.*?)}}/g;
                    object.fieldName = [];
                    if (stringBody.match(pattern)) {
                        let secondRow = element.table.tableRows[1];
                        let fieldsNameUsingParsing = [];
                        secondRow.tableCells.forEach((cell) => {
                            let content = cell.content;
                            content.forEach(element => {
                                let contentElement = element.paragraph.elements;
                                contentElement.forEach(e => {
                                    let fieldValue = e.textRun.content;
                                    let elm = fieldValue.match(pattern);
                                    if (elm) {
                                        object.fieldName.push(...elm);
                                    }
                                    
                                    let obj = {
                                        startIndex: e.startIndex,
                                        fieldName: fieldValue
                                    }
                                    fieldsNameUsingParsing.push(obj);
                                    
                                });
                            });       
                        });
                        object.fieldArray = fieldsNameUsingParsing;
                    }

                    // get table details
                    pattern = /\$([^:]+):([^$]+)\$/g;
                    while ((matcher = pattern.exec(stringBody)) != null) {
                        if (matcher[1] === "limit") {
                            object.queryLimit = matcher[2].trim();
                        } else {
                            object[matcher[1]] = matcher[2].trim();
                        }
                    }

                    // Send table for apex processing only when all fields are present
                    if (object.objApi && object.childRelation && object.fieldName && object.fieldName.length > 0) {
                        tableNo++;
                        object.tableNo = tableNo;
                        objectDetails.push(object);
                    }
                }
            });

            let matcher, pattern;
            let stringBody = JSON.stringify(content);

            // Get object fields
            let objectFieldSet = new Set();
            pattern = /{{#(.*?)}}/g;
            while ((matcher = pattern.exec(stringBody)) != null) {
                objectFieldSet.add(matcher[0]);
            }
            objectDetails.push({ objApi: this.objectname, fieldName: Array.from(objectFieldSet) });

            // Get general fields
            let generalFieldSet = new Set();
            pattern = /{{Doc.(.*?)}}/g;
            while ((matcher = pattern.exec(stringBody)) != null) {
                generalFieldSet.add(matcher[0]);
            }
            objectDetails.push({ objApi: "General Fields", fieldName: Array.from(generalFieldSet) });

            // Get Signature Image
            let signatureImage = new Set();
            pattern = /{{Sign.DocGenius *Signature Key*}}/g;
            while ((matcher = pattern.exec(stringBody)) != null) {
                signatureImage.add(matcher[0]);
            }
            objectDetails.push({ objApi: "Signature Image", fieldName: Array.from(signatureImage) });

            console.log("objectDetails \n", objectDetails);
            this.mapFieldValues(content, objectDetails);

        } catch (error) {
            errorDebugger("generateGoogleDocFile", "generateDocument", error, 'Error', "Error in formatting template. Please try again.");
            this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: error , desc: "Something went wrong. Please refresh the page and try again" } }));
        }
    }

    // Make apex call to get the map and create requests
    mapFieldValues(content, objectDetails) {
        var tableNo = 1;
        try {
            // Gets all the key value for present in the document from apex
            mapFieldValues({ queryObject: JSON.stringify(objectDetails), objectApiName: this.objectname, recordId: this.recordId })
                .then((result) => {
                    this.resultSet = result;
                    console.log("this.resultSet==>", this.resultSet);

                    let signatureImageValues = this.resultSet.find((el) => el["Signature Image"] != null);
                    console.log("signatureImageValues==>", signatureImageValues);
                    content.forEach((element) => {
                        if (element.paragraph) {
                            // Replace all the signature anywhere texts with the content document image
                            let stringBody = JSON.stringify(element);
                            if (stringBody.includes(this.signatureKey)) {
                                element.paragraph.elements.forEach(e => {
                                    let stringElement = JSON.stringify(e);
                                    if (stringElement.includes(this.signatureKey)) {
                                        let content = this.substringBetween(stringElement, '"content":"', '",');
                                        let startIndex = content.indexOf(this.signatureKey);
                                        this.processSignatureImage(Number(e.startIndex) + Number(startIndex), signatureImageValues);
                                        stringBody = stringBody.replace(this.signatureKey, ' ');
                                    } 
                                });
                            }
                        } else if (element.table) {
                            // Process table one by one
                            let stringBody = JSON.stringify(element);

                            // Checks for fields inside the table with keys
                            if (stringBody.match(/{{!(.*?)}}/g)) {
                                let tableLocation = element.startIndex; //table's start index
                                let tableEndIndex = element.table.tableRows[0].endIndex; // End of first row's index of the table
                                tableLocation = tableLocation + this.tableOffset;
                                tableEndIndex = tableEndIndex + this.tableOffset;

                                // Deletes the whole table when the tables exceed 10
                                if (tableNo > 10) {
                                    this.deleteContentRequest(tableLocation, element.endIndex + this.tableOffset);
                                    this.tableOffset -= element.endIndex - element.startIndex;
                                    return;
                                }

                                let fieldName = this.substringBetween(stringBody, "$objApi:", "$");
                                fieldName = fieldName.trim();
                                let objFields = objectDetails.find((el) => el.objApi === fieldName && el.tableNo === tableNo);
                                let IndexedFieldName = "";

                                if (fieldName && fieldName !== "") {
                                    
                                    // Insert empty rows
                                    IndexedFieldName = fieldName + tableNo;
                                    let childFieldValues = this.resultSet.find((el) => el[IndexedFieldName] != null);
                                    if (childFieldValues != null && childFieldValues[IndexedFieldName] != null) {
                                        for (let i = 1; i <= childFieldValues[IndexedFieldName].length; i++) {
                                            this.createRowInsertRequest(tableLocation, i);
                                        }
                                    }

                                    // Delete 2nd row of table - all fields with {{!...}}
                                    this.createRowDeleteRequest(tableLocation, 1);
                                    this.tableOffset = this.tableOffset - (element.table.tableRows[1].endIndex - element.table.tableRows[1].startIndex);

                                    // Delete last row of table - contains details like objAPI, filters
                                    if (childFieldValues != null && childFieldValues[IndexedFieldName] != null) {
                                        this.createRowDeleteRequest(tableLocation, childFieldValues[IndexedFieldName].length + 1);
                                    } else {
                                        this.createRowDeleteRequest(tableLocation, 1);
                                    }
                                    this.tableOffset = this.tableOffset - (element.table.tableRows[2].endIndex - element.table.tableRows[2].startIndex);

                                    // Insert the table data
                                    if (childFieldValues != null && childFieldValues[IndexedFieldName] != null) {
                                        for (let i = 1; i <= childFieldValues[IndexedFieldName].length; i++) {
                                            let recordMap = childFieldValues[IndexedFieldName][i - 1];

                                            // inserts value for the table
                                            objFields.fieldArray.forEach((e) => {
                                                tableEndIndex += 2;
                                                this.tableOffset += 2;
                                                let fieldName = e.fieldName.replace('\n', '');
                                                if (fieldName == '{{No.Index}}') {
                                                    // For Index Number
                                                    this.createRowUpdateRequest(tableEndIndex, "{{No.Index}}", { "{{No.Index}}": i.toString() });
                                                    tableEndIndex += i.toString().length;
                                                    this.tableOffset += i.toString().length;
                                                } else if (fieldName.includes('{{!') && fieldName.includes('}}')) {
                                                    // For Merge Fields
                                                    let fieldNameWithoutQuotes = this.substringBetween(e.fieldName, '{{!', '}}');
                                                    this.createRowUpdateRequest(tableEndIndex, fieldNameWithoutQuotes, recordMap);
                                                    if (recordMap[fieldNameWithoutQuotes]) {
                                                        tableEndIndex += recordMap[fieldNameWithoutQuotes].toString().length;
                                                        this.tableOffset += recordMap[fieldNameWithoutQuotes].toString().length;
                                                    } else {
                                                        tableEndIndex++;
                                                        this.tableOffset++;
                                                    }
                                                } else {
                                                    // For any other text
                                                    if (fieldName.includes(this.signatureKey)) {
                                                        if (signatureImageValues && signatureImageValues["Signature Image"] && signatureImageValues["Signature Image"][0].ContentDownloadUrl) {
                                                            let imageLink = signatureImageValues["Signature Image"][0].ContentDownloadUrl;
                                                            let originalPageWidth = this.docPageSize.pageSize.width.magnitude - (this.docPageSize.marginLeft.magnitude + this.docPageSize.marginRight.magnitude);
                                                            let width = originalPageWidth * (this.signatureSize / 100);
                                                            this.insertImageRequest(tableEndIndex, imageLink, width);
                                                            this.tableOffset++;
                                                            tableEndIndex++;
                                                        }
                                                    }else if (fieldName != '') {   
                                                        let obj = {};
                                                        obj[fieldName] = fieldName;
                                                        this.createRowUpdateRequest(tableEndIndex, fieldName, obj);
                                                        tableEndIndex += fieldName.toString().length;
                                                        this.tableOffset += fieldName.toString().length;
                                                    } else {
                                                        this.createRowUpdateRequest(tableEndIndex, 'space', {space: ' '});
                                                        tableEndIndex++;
                                                        this.tableOffset++;
                                                    }
                                                }
                                            });
                                            tableEndIndex++;
                                            this.tableOffset++;
                                        }
                                    }
                                    tableNo++;
                                }
                            } else {
                                // Checks for the signature key inside the table
                                let matchedBody = JSON.stringify(element);
                                if (matchedBody.includes(this.signatureKey)) {
                                    let splitMatchedBody = matchedBody.split(this.signatureKey);
                                    for (let i = 0; i < splitMatchedBody.length - 1; i++) {
                                        const element = splitMatchedBody[i];
                                        if (element.includes('"startIndex"')) {   
                                            let smallBody = element.substring(element.lastIndexOf('"startIndex":')) + this.signatureKey + '",';
                                            let startIndex = this.substringBetween(smallBody, '"startIndex":', ",");
                                            let content = this.substringBetween(smallBody, '"content":"', '",');
                                            startIndex = Number(startIndex) + content.indexOf(this.signatureKey);
                                            this.processSignatureImage(startIndex, signatureImageValues);
                                        }
                                    }
                                }   
                            }
                        }
                    });

                    let actualStringBody = JSON.stringify(content);

                    let parentFieldvalues = this.resultSet.find((el) => el[this.objectname] != null);
                    let generalFieldvalues = this.resultSet.find((el) => el["General Fields"] != null);
                    // Replace all the object and general fields
                    if (parentFieldvalues) {
                        this.createReplaceRequest(actualStringBody, /{{#(.*?)}}/g, parentFieldvalues[this.objectname]);
                    }
                    if (generalFieldvalues) {
                        this.createReplaceRequest(actualStringBody, /{{Doc.(.*?)}}/g, generalFieldvalues["General Fields"]);
                    }
                    this.SignatureKeyReplaceRequest();

                    console.log("this.changeRequests==>", this.changeRequests);
                    this.doPreview();
                })
                .catch((error) => {
                    console.log("error in mapFieldValues==>", error);
                    this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: error, desc: "Something went wrong. Please refresh the page and try again" } }));
                });
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "mapFieldValues", error, 'Error', "Error in mapFieldValues. Please try again.");
            this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: error, desc: "Something went wrong. Please refresh the page and try again" } }));
        }
    }

    // Replaces the image with the signature image
    processSignatureImage(element, signatureImageValues) {
        try {
            let startIndex = this.tableOffset + Number(element);
            let endIndex = startIndex + this.signatureKey.length;
            
            // Ompy process if the public URL is available
            if (signatureImageValues && signatureImageValues["Signature Image"] && signatureImageValues["Signature Image"][0].ContentDownloadUrl) {
                let imageLink = signatureImageValues["Signature Image"][0].ContentDownloadUrl;
                let originalPageWidth = this.docPageSize.pageSize.width.magnitude - (this.docPageSize.marginLeft.magnitude + this.docPageSize.marginRight.magnitude);
                let width = originalPageWidth * (this.signatureSize / 100);
                
                this.deleteContentRequest(startIndex, endIndex);
                this.insertImageRequest(startIndex, imageLink, width);
                this.tableOffset -= this.signatureKey.length - 1;
            }
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "processSignatureImage", error, 'Error', "Error in processSignatureImage. Please try again later");
        }
    }
    // Creates find and replace requests
    createReplaceRequest(stringBody, regex, fieldMap) {
        try {
            let matcher;
            while ((matcher = regex.exec(stringBody)) != null) {
                let replaceText = fieldMap[matcher[0]] ? fieldMap[matcher[0]] : " ";
                if (!this.allFields.includes(matcher[0])) {
                    let tabrequest = {
                        replaceAllText: {
                            containsText: {
                                text: matcher[0],
                                matchCase: true
                            },
                            replaceText: replaceText
                        }
                    };
                    this.allFields.push(matcher[0]);
                    this.changeRequests.push(tabrequest);
                }
            }
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "createReplaceRequest", error, 'Error', "Error in createReplaceRequest. Please try again.");
        }
    }
    // Creates new table rows - empty
    createRowInsertRequest(index, rowIndex) {
        try {
            let tabInsertRequest = {
                insertTableRow: {
                    tableCellLocation: {
                        tableStartLocation: {
                            segmentId: "",
                            index: index
                        },
                        rowIndex: rowIndex,
                        columnIndex: 0
                    },
                    insertBelow: true
                }
            };
            this.changeRequests.push(tabInsertRequest);
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "createRowInsertRequest", error, 'Error', "Error in createRowInsertRequest. Please try again.");
        }
    }

    // Deletes table rows
    createRowDeleteRequest(index, rowIndex) {
        try {
            let tabDeleteRequest = {
                deleteTableRow: {
                    tableCellLocation: {
                        tableStartLocation: {
                            segmentId: "",
                            index: index
                        },
                        rowIndex: rowIndex,
                        columnIndex: 0
                    }
                }
            };
            this.changeRequests.push(tabDeleteRequest);
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "createRowDeleteRequest", error, 'Error', "Error in createRowDeleteRequest. Please try again.");
        }
    }

    // Enters the data in the table rows
    createRowUpdateRequest(index, field, arrList) {
        try {
            let tabValueRequest = {
                insertText: {
                    location: {
                        segmentId: "",
                        index: index
                    },
                    text: arrList[field] != null ? arrList[field].toString() : " "
                }
            };
            this.changeRequests.push(tabValueRequest);
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "createRowUpdateRequest", error, 'Error', "Error in createRowUpdateRequest. Please try again.");
        }
    }

    // Used to delete the text
    deleteContentRequest(startIndex, endIndex) {
        try {
            let contentDeleteRequest = {
                deleteContentRange: {
                    range: {
                        segmentId: "",
                        startIndex: startIndex,
                        endIndex: endIndex
                    }
                }
            };
            this.changeRequests.push(contentDeleteRequest);
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "deleteContentRequest", error, 'Error', "Error in deleteContentRequest. Please try again.");
        }
    }

    // Used to insert the image
    insertImageRequest(index, link, width) {
        try {
            let insertImageRequest = {
                insertInlineImage: {
                    uri: link,
                    objectSize: {
                        width: {
                            magnitude: width,
                            unit: "PT"
                        }
                    },
                    location: {
                        segmentId: "",
                        index: index
                    }
                }
            };
            this.changeRequests.push(insertImageRequest);
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "insertImageRequest", error, 'Error', "Error in insertImageRequest. Please try again.");
        }
    }

    // Removes signatureKey tags if there is no signature for the object
    SignatureKeyReplaceRequest() {
        try {
            let removeSignatureKeyRequest = {
                replaceAllText: {
                    containsText: {
                        text: this.signatureKey,
                        matchCase: true
                    },
                    replaceText: " "
                }
            };
            this.changeRequests.push(removeSignatureKeyRequest);
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "SignatureKeyReplaceRequest", error, 'Error', "Error in SignatureKeyReplaceRequest. Please try again.");
        }
    }

    // Preview the result - make apex call to get body blob
    doPreview() {
        try {
            doPreview({ googleDocId: this.documentId, requests: this.changeRequests, format: this.format })
                .then((res) => {
                    if (!res.startsWith("error")) {
                        // Process complete
                        this.dispatchEvent(new CustomEvent("complete", { detail: { blob: res } }));
                    } else {
                        // An error occured in recieving / make change requests
                        let splitList = res.split(":");
                        this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: splitList[3], desc: splitList[2] } }));
                        errorDebugger("generateGoogleDocFile", "doPreview", splitList, 'Error', splitList[2])
                    }
                })
                .catch((error) => {
                    console.log("error in doPreview - LWC", error);
                    this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: error, desc: "Something went wrong. Please refresh the page and try again" } }));
                });
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "doPreview", error, 'Error', "Error in doPreview. Please try again.");
        }
    }

    // Used to find the substring between two strings
    substringBetween(input, startDelim, endDelim) {
        try {
            const startIndex = input.indexOf(startDelim);
            if (startIndex === -1) return ""; // Return empty string if start delimiter not found

            const endIndex = input.indexOf(endDelim, startIndex + startDelim.length);
            if (endIndex === -1) return ""; // Return empty string if end delimiter not found

            return input.substring(startIndex + startDelim.length, endIndex);
        } catch (error) {
            errorDebugger("generateGoogleDocFile", "substringBetween", error, 'Error', "Error in substringBetween. Please try again.");
        }
        return -1;
    }
}