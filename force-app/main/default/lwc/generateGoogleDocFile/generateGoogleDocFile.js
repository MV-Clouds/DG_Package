import { api, track, LightningElement } from "lwc";
import copyGoogleDoc from "@salesforce/apex/GoogleDocPreview.copyGoogleDoc";
import doPreview from "@salesforce/apex/GoogleDocPreview.doPreview";
import mapFieldValues from "@salesforce/apex/GoogleDocPreview.mapFieldValues";

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

            copyGoogleDoc({ templateId: this.templateid })
                .then((result) => {
                    console.log(result);
                    this.signatureSize = result.width !== null ? result.width : 50;
                    if (this.signatureSize > 100) {
                        this.signatureSize = 100;
                    } else if (this.signatureSize <= 0) {
                        this.signatureSize = 1;
                    }

                    if (result.document) {
                        this.responseBody = JSON.parse(result.document);
                        console.log("this.responseBody==>", this.responseBody);

                        this.documentId = this.responseBody.documentId;
                        this.docPageSize.pageSize = this.responseBody.documentStyle.pageSize;
                        this.docPageSize.marginLeft = this.responseBody.documentStyle.marginLeft;
                        this.docPageSize.marginRight = this.responseBody.documentStyle.marginRight;

                        console.log(this.docPageSize);
                        this.dispatchEvent(new CustomEvent("changespinnerlabel"));
                        this.formatContent(this.responseBody);
                    } else if (result.error) {
                        let errorList = result.error.split(":");
                        console.log(errorList);
                        this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: errorList[0], message: errorList[2] } }));
                    }
                })
                .catch((error) => {
                    console.log("error in copyGoogleDoc - LWC", error);
                    this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: "Error in Generating Template. Please try again." } }));
                });
        } catch (error) {
            console.log("Error in generateDocument:", error);
        }
    }

    formatContent(body) {
        var content = body.body.content;
        var objectDetails = [];
        var fieldSet = new Set();
        var generalFieldSet = new Set();
        var signatureImage = new Set();
        var tableNo = 1;
        try {
            console.log("content \n", content);
            content.forEach((element) => {
                if (element.table) {
                    let object = {};
                    let matcher, pattern;
                    let stringBody = JSON.stringify(element);
                    let fieldName = new Set();

                    // get table fields
                    pattern = /{{!(.*?)}}/g;
                    while ((matcher = pattern.exec(stringBody)) != null) {
                        fieldName.add(matcher[1]);
                    }
                    if (fieldName.size > 0) {
                        object.fieldName = Array.from(fieldName);
                    }

                    // get table details
                    pattern = /\$([^:]+):([^$]+)\$/g;
                    while ((matcher = pattern.exec(stringBody)) != null) {
                        if (matcher[1] === "limit") {
                            object.queryLimit = matcher[2];
                        } else {
                            object[matcher[1]] = matcher[2];
                        }
                    }

                    if (object.objApi && object.childRelation && object.fieldName.length > 0) {
                        object.tableNo = tableNo;
                        objectDetails.push(object);
                        tableNo++;
                    }
                }
            });

            let matcher, pattern;
            let stringBody = JSON.stringify(content);

            // Get object fields
            pattern = /{{#(.*?)}}/g;
            while ((matcher = pattern.exec(stringBody)) != null) {
                fieldSet.add(matcher[0]);
            }
            objectDetails.push({ objApi: this.objectname, fieldName: Array.from(fieldSet) });

            // Get general fields
            pattern = /{{Doc.(.*?)}}/g;
            while ((matcher = pattern.exec(stringBody)) != null) {
                generalFieldSet.add(matcher[0]);
            }
            objectDetails.push({ objApi: "General Fields", fieldName: Array.from(generalFieldSet) });

            // Get Signature Image
            pattern = /{{Sign.DocGenius *Signature Key*}}/g;
            while ((matcher = pattern.exec(stringBody)) != null) {
                signatureImage.add(matcher[0]);
            }
            objectDetails.push({ objApi: "Signature Image", fieldName: Array.from(signatureImage) });

            console.log("objectDetails \n", objectDetails);
            this.mapFieldValues(content, objectDetails);
        } catch (error) {
            console.log("error in formatContent - LWC", error);
            this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: "Error in previewing result. Please try again" } }));
        }
    }

    // Make apex call to get the map and create requests
    mapFieldValues(content, objectDetails) {
        var tableNo = 1;
        try {
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
                            let resultElement = stringBody.includes(this.signatureKey);
                            if (resultElement) {
                                this.processSignatureImage(element, signatureImageValues);
                            }
                        } else if (element.table) {
                            // Process table one by one
                            let stringBody = JSON.stringify(element);
                            if (stringBody.match(/{{!(.*?)}}/g)) {
                                let tableLocation = element.startIndex; //table's start index
                                let tableEndIndex = element.table.tableRows[0].endIndex; // End of first row's index of the table

                                tableLocation = tableLocation + this.tableOffset;
                                tableEndIndex = tableEndIndex + this.tableOffset;
                                let fieldName = this.substringBetween(stringBody, "$objApi:", "$");
                                let IndexedFieldName = "";

                                // Insert empty rows
                                if (fieldName && fieldName !== "") {
                                    IndexedFieldName = fieldName + tableNo;
                                    let childFieldValues = this.resultSet.find((el) => el[IndexedFieldName] != null);
                                    let objFields = objectDetails.find((el) => el.objApi === fieldName && el.tableNo === tableNo);
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
                                            // Insert indexing for the table
                                            if (stringBody.includes("{{No.Index}}")) {
                                                tableEndIndex = tableEndIndex + 2;
                                                this.tableOffset = this.tableOffset + 2;
                                                this.createRowUpdateRequest(tableEndIndex, "{{No.Index}}", { "{{No.Index}}": i.toString() });
                                                tableEndIndex++;
                                                this.tableOffset++;
                                            }

                                            // eslint-disable-next-line no-loop-func
                                            objFields.fieldName.forEach((e) => {
                                                if (stringBody.includes("{{!" + e + "}}")) {
                                                    tableEndIndex = tableEndIndex + 2;
                                                    this.tableOffset = this.tableOffset + 2;
                                                    this.createRowUpdateRequest(tableEndIndex, e, recordMap);
                                                    if (recordMap[e] != null) {
                                                        tableEndIndex = tableEndIndex + recordMap[e].toString().length;
                                                        this.tableOffset = this.tableOffset + recordMap[e].toString().length;
                                                    } else {
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

                    console.log("this.changeRequests==>", this.changeRequests);
                    this.doPreview();
                })
                .catch((error) => {
                    console.log("error in mapFieldValues==>", error);
                    this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: "Error in previewing result. Please try again" } }));
                });
        } catch (error) {
            console.log("Error in mapFieldValues:", error);
        }
    }

    processSignatureImage(element, signatureImageValues) {
        let startIndex = this.tableOffset + element.startIndex;
        let endIndex = this.tableOffset + element.endIndex - 1;

        if (signatureImageValues && signatureImageValues["Signature Image"] && signatureImageValues["Signature Image"][0].ContentDownloadUrl) {
            let imageLink = signatureImageValues["Signature Image"][0].ContentDownloadUrl;
            let originalPageWidth = this.docPageSize.pageSize.width.magnitude - (this.docPageSize.marginLeft.magnitude + this.docPageSize.marginRight.magnitude);
            let width = originalPageWidth * (this.signatureSize / 100);

            this.deleteContentRequest(startIndex, endIndex);
            this.insertImageRequest(startIndex, imageLink, width);
            this.tableOffset -= this.signatureKey.length - 1;
        } else {
            this.deleteContentRequest(startIndex, endIndex);
            this.tableOffset -= this.signatureKey.length;
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
            console.log("Error in createReplaceRequest:", error);
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
            console.log("Error in createRowInsertRequest:", error);
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
            console.log("Error in createRowDeleteRequest:", error);
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
            console.log("Error in createRowUpdateRequest", error);
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
            console.log("Error in deleteContentRequest", error);
        }
    }

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
            console.log("Error in insertImageRequest:", error);
        }
    }

    // Preview the result - make apex call to get body blob
    doPreview() {
        try {
            doPreview({ googleDocId: this.documentId, requests: this.changeRequests, format: this.format })
                .then((res) => {
                    if (!res.startsWith("error")) {
                        this.dispatchEvent(new CustomEvent("complete", { detail: { blob: res } }));
                    } else {
                        let splitList = res.split(":");
                        this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: splitList[2] } }));
                        console.log("Cannot Preview the result is null");
                        // this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: "Error in previewing result. Please try again" } }));
                    }
                })
                .catch((error) => {
                    console.log("error in doPreview - LWC", error);
                    this.dispatchEvent(new CustomEvent("internalerror", { detail: { title: "Error", message: "Error in previewing result. Please try again" } }));
                });
        } catch (error) {
            console.log("Error in doPreview:", error);
        }
    }

    substringBetween(input, startDelim, endDelim) {
        try {
            const startIndex = input.indexOf(startDelim);
            if (startIndex === -1) return ""; // Return empty string if start delimiter not found

            const endIndex = input.indexOf(endDelim, startIndex + startDelim.length);
            if (endIndex === -1) return ""; // Return empty string if end delimiter not found

            return input.substring(startIndex + startDelim.length, endIndex);
        } catch (error) {
            console.log("Error in substringBetween:", error);
        }
        return -1;
    }
}
