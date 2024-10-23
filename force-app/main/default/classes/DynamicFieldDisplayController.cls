public with sharing class DynamicFieldDisplayController {    
    public String recordId { get; set; }
    public String NameSpace { get; set; }
    public String objectName { get; set; }
    public String objectID {get;set;}
    public String layoutName { get; set; }
    public string RecordTypeId { get; set;}
    public List<FieldSection> fieldSections { get; set; }

    public DynamicFieldDisplayController() {
        this.recordId = ApexPages.currentPage().getParameters().get('id');
        if(this.recordId != null){
            this.objectName = getObjectNameFromRecordId(this.recordId);
            this.NameSpace = getNameSpace(this.objectName);
            this.objectID = getObjectIdByApiName(this.objectName);
            this.RecordTypeId = getRecordTypeId(this.recordId, this.objectName);
            this.layoutName = getObjectLayout(this.objectID, this.RecordTypeId)[0]; // Change this to the desired layout
            this.fieldSections = new List<FieldSection>();
            fetchRecordFieldValues();
        }
    }

    public String getObjectNameFromRecordId(String recordId) {
        String objectName = '';
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        String prefix = String.valueOf(recordId).substring(0, 3);
        for (Schema.SObjectType objType : globalDescribeMap.values()) {
            if (objType.getDescribe().getKeyPrefix() == prefix) {
                objectName = objType.getDescribe().getName();
                break;
            }
        }
        return objectName;
    }

    public string getNameSpace(String objectApiName){
        if(Schema.sObjectType.EntityDefinition.Fields.NamespacePrefix.isAccessible() && Schema.sObjectType.EntityDefinition.Fields.QualifiedApiName.isAccessible()){
            if( objectApiName != null){
                EntityDefinition objectInfo = [SELECT NamespacePrefix FROM EntityDefinition WHERE QualifiedApiName = :objectApiName WITH SECURITY_ENFORCED LIMIT 1];
                return objectInfo != null ? objectInfo.NamespacePrefix : null;
            }
        }
        return null;
    }

    public void fetchRecordFieldValues() {
        try {

            // Get Fields with value...
            Map<String, FieldInfo> fieldDetails = getRecordFieldValues(recordId, objectName, layoutName, NameSpace);

            Map<Integer, FieldSection> sectionsMap = new Map<Integer, FieldSection>();
            Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
            
            for (FieldInfo fieldDetail : fieldDetails.values()) {

                // Get Fields Label...
                fieldDetail.fieldLabel = fieldsMap?.containsKey(fieldDetail?.fieldName) ? String.valueOf(fieldsMap?.get(fieldDetail?.fieldName).getDescribe().getLabel()) : fieldDetail?.fieldName;

                // Remove ID label from refrence field label...
                if(fieldDetail?.isRefrenceField){
                    fieldDetail.fieldLabel = fieldDetail?.fieldLabel?.replace('ID', '');
                    fieldDetail.fieldLabel = fieldDetail?.fieldLabel?.replace('Id', '');
                    fieldDetail.fieldLabel = fieldDetail?.fieldLabel?.replace('id', '');
                }

                if (!sectionsMap?.containsKey(fieldDetail?.sectionIndex)) {
                    sectionsMap?.put(fieldDetail?.sectionIndex, new FieldSection(fieldDetail?.sectionIndex, fieldDetail?.sectionName));
                }

                FieldSection section = sectionsMap?.get(fieldDetail?.sectionIndex);
                if (fieldDetail?.columnIndex == 0) {
                    section?.leftColumn.add(fieldDetail);
                } else if (fieldDetail?.columnIndex == 1) {
                    section?.rightColumn.add(fieldDetail);
                }
            }
            // Convert map to list
            this.fieldSections = sectionsMap?.values();
        } catch (Exception e) {
            // throw new AuraHandledException('Unable to fetch record field values.'+ e);
        }
    }

    private static String formatAddress(Address address) {
        List<String> addressParts = new List<String>();
        if (address.getStreet() != null) addressParts.add(address.getStreet());
        if (address.getCity() != null) addressParts.add(address.getCity());
        if (address.getState() != null) addressParts.add(address.getState());
        if (address.getPostalCode() != null) addressParts.add(address.getPostalCode());
        if (address.getCountry() != null) addressParts.add(address.getCountry());
        return String.join(addressParts, ', ');
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getObjectLayout(String objectId, String recordTypeId) {
        return getLayoutNameForObject(objectId, recordTypeId);
    }

    @AuraEnabled
    public static String getSessionId(){
        if (!Test.isRunningTest()) {
            return Page.UserSessionIdPage.getContent().toString();
        }
        return 'mockSessionId';
    }
    
    public static String toolingAPISOQL(String query) {
        String instanceUrl = System.URL.getOrgDomainUrl().toExternalForm();
        String baseURL = instanceUrl+'/services/data/v61.0/tooling/query?';
        String sid = getSessionId();
        return restGet(baseURL + 'q=' + (query.replace(' ', '+')), 'GET', sid);
    } 

    public static String getRecordTypeId(String recordId, String objectType) {
        // Dynamic query to fetch RecordTypeId
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(objectType).getDescribe().fields.getMap();
        boolean isRecordID = fields.containsKey('RecordTypeId');
        if(isRecordID){
            String query = 'SELECT RecordTypeId FROM ' + String.escapeSingleQuotes(objectType) + ' WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\'';
            SObject record = Database.query(String.escapeSingleQuotes(query));
            if (record != null) {
                return (String) record.get('RecordTypeId');
            }
            return null;
        }
        else{
            return null;
        }
    }

    
    static List<String> getLayoutNameForObject(String objectId, String recordTypeId) {
        String soql;
        if (recordTypeId != null) {
        // Query to get layout for specific record type
            soql = 'SELECT Layout.Name FROM ProfileLayout WHERE RecordTypeId=\'' + recordTypeId + '\' AND TableEnumOrId=\'' + objectId + '\'';
        } else {
            // Query to get default layout
            soql = 'SELECT Layout.Name FROM ProfileLayout WHERE TableEnumOrId=\'' + objectId + '\'';
        }
        String body = toolingAPISOQL(soql);
        if (String.isNotBlank(body)) {
            LayoutRecord data = LayoutRecord.parse(body);
            
            // Get only layout name
            List<String> layouts = new List<String>();
            for (LayoutRecord.Record record : data.records) {
                if (!layouts.contains(record.Layout.Name)) {
                    layouts.add(String.valueOf(record.Layout.Name));
                }
            }
            return layouts;
        }
        return null;
    }

    public static String getObjectIdByApiName(String objectApiName) {
        // String cleanApiName = objectApiName.endsWith('__c') ? objectApiName.substring(0, objectApiName.length() - 3) : objectApiName;
        // String objectApiNameQuery = objectApiName.endsWith('__c') ? objectApiName : objectApiName + '__c';
        if(Schema.sObjectType.EntityDefinition.Fields.DurableId.isAccessible() && Schema.sObjectType.EntityDefinition.Fields.QualifiedApiName.isAccessible()){
            if( objectApiName != null){
            EntityDefinition objectInfo = [SELECT DurableId FROM EntityDefinition WHERE QualifiedApiName = :objectApiName WITH SECURITY_ENFORCED LIMIT 1];
            return objectInfo != null ? objectInfo.DurableId : null;
            }
        }
        return null;
    }


    @AuraEnabled(cacheable=true)
    public static Map<String, FieldInfo> getRecordFieldValues(String recordId, String objectName, String layout, String NameSpace) {
        Map<String, FieldInfo> fieldDetails = new Map<String, FieldInfo>();
        try {

            // Get Fields From the page layout...
            fieldDetails = getFields(objectName, layout, NameSpace);
            
            Set<String> fieldNames = new Set<String>();
            Set<String> refrenceFields = new Set<String>();
            fieldNames.add('Id');
            for (FieldInfo fieldDetail : fieldDetails.values()) {
                if(fieldDetail?.fieldName != null){
                    fieldNames.add(fieldDetail?.fieldName);
                }

                if(fieldDetail?.isRefrenceField){
                    fieldNames.add(fieldDetail?.refrenceField);
                }
            }

            // Query Field...
            String soql = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM ' + String.escapeSingleQuotes(objectName) + ' WHERE Id = \''+ String.escapeSingleQuotes(recordId) +'\'';
            SObject record = Database.query(soql);

            // Convert sObejct in Map...
            Map<String, Object> recordAsMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(record));

            // create baseURL for refrence Fields...
            String baseUrl = 'https://'+URL.getOrgDomainUrl().getHost()+'/';
            
            Map<String, FieldInfo> recordFieldValues = new Map<String, FieldInfo>();

            // append and Set FieldValue, refrenceFieldValue & refrenceURL...
            for(FieldInfo fieldDetail : fieldDetails.values()){
                String fieldName = fieldDetail?.fieldName;
                FieldInfo field = new FieldInfo();
                fieldDetail.fieldValue = '';
                if(fieldDetail?.isRefrenceField){
                    Map<String, Object> parentObj = (Map<String, Object>) recordAsMap?.get(fieldDetail?.refrenceField.substringBefore('.'));
                    fieldDetail.fieldValue = (String) String.valueOf(parentObj?.get(fieldDetail?.refrenceField.substringAfter('.')));
                    fieldDetail.fieldValue = fieldDetail?.fieldValue != null ? fieldDetail.fieldValue : '';
                    string refrenceId = String.valueOf(recordAsMap?.get(fieldName));
                    fieldDetail.refrenceURL = baseUrl+refrenceId;
                }
                else{
                    // Format Field value...
                    Object fieldValue = recordAsMap?.get(fieldName);
                    String formattedFieldValue = '';
                    if (fieldValue instanceof Address) {
                        Address address = (Address) fieldValue;
                        formattedFieldValue = formatAddress(address);
                    }else if(string.valueOf(fieldValue) == 'null'){
                        formattedFieldValue = ' ';
                    } else if (fieldValue != null) {
                        formattedFieldValue = String.valueOf(fieldValue);
                    } else {
                        formattedFieldValue = ' ';
                    }

                    fieldDetail.fieldValue = formattedFieldValue;
                }
                recordFieldValues.put(fieldName, fieldDetail);
            }
            
            return recordFieldValues;
        } catch (Exception e) {
            // throw new AuraHandledException('Unable to fetch record field values.');
            return fieldDetails;
        }

    }
    
    @AuraEnabled
    public static Map<String, FieldInfo> getFields(String objectName, String layout, String NameSpace) {
        Map<String, FieldInfo> fieldDetails = new Map<String, FieldInfo>();
        try {
            // Adjust layout name based on whether the object is namespaced
            String layoutName;
            if (NameSpace != null) {
                layoutName = objectName + '-' + NameSpace + '__' + layout;
            } else {
                layoutName = String.format('{0}-{1}', new String[]{objectName, layout});
            }

            Map<String, FieldInfo> objectFields = getFieldInfo(objectName);

            List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String>{layoutName});

            // Check if layouts list is null or empty before casting
            if (layouts != null && layouts.size() > 0 && layouts.get(0) != null) {
                Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
                
                Integer sectionIndex = 0;
                for (Metadata.LayoutSection section : layoutMd.layoutSections) {
                    Integer columnIndex = 0;
                    String sectionLabel = section.label != null ? section.label : 'Section ' + sectionIndex;

                    for (Metadata.LayoutColumn column : section.layoutColumns) {
                        if (column.layoutItems != null) {
                            for (Metadata.LayoutItem item : column.layoutItems) {
                                String field = item.field;
                                String refrenceField = '';
                                Boolean isRefrenceField = objectFields.get(field)?.isRefrenceField;
                                if(isRefrenceField){
                                    refrenceField = objectFields.get(field)?.referenceObjNameField;
                                }
                                FieldInfo fieldDetail = new FieldInfo();
                                fieldDetail.fieldName = field;
                                fieldDetail.refrenceField = refrenceField;
                                fieldDetail.isRefrenceField = isRefrenceField;
                                fieldDetail.fieldType = String.valueOf(objectFields.get(field)?.fieldType);
                                fieldDetail.sectionName = sectionLabel;
                                fieldDetail.sectionIndex = sectionIndex;
                                fieldDetail.columnIndex = columnIndex;
                                // System.debug('fieldDetail : ' + fieldDetail);
                                fieldDetails.put(field, fieldDetail);
                            }
                        }
                        columnIndex++;
                    }
                    sectionIndex++;
                }
            }
            return fieldDetails;
        } catch (Exception e) {
            return fieldDetails;
            // throw new AuraHandledException('Unable to fetch record field values.'+e);
        }
    }


    public static String restGet(String endPoint, String method, String sid) {
        try
        {
            Http h = new Http();
            HttpRequest hr = new HttpRequest();
            hr.setHeader('Authorization', 'Bearer ' + sid);
            hr.setTimeout(60000);
            hr.setEndpoint(endPoint);
            hr.setMethod(method);
            HttpResponse r = h.send(hr);
            return r.getBody();
        }
        catch(Exception ex)
        {
            return ex.getMessage();
        }
    }

    public static Map<String, FieldInfo> getFieldInfo(string objectApiName){
        Map<String, FieldInfo> fields = new Map<String, FieldInfo>();
        try {
            Schema.SObjectType sobjType = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeSObjectResult r = sobjType.getDescribe();
            Map<String, Schema.SObjectField> mapOfFields = r.fields.getMap();
            List<String> fieldsList = new List<String>(mapOfFields.keySet());
            fieldsList.sort();
            
            
            for(String fieldName : fieldsList){
                Schema.SObjectField f = mapOfFields.get(fieldName);
                Schema.DescribeFieldResult field = f.getDescribe();

                FieldInfo fieldInfo = new FieldInfo();
                fieldInfo.fieldName = (String) String.valueOf(field.getName());
                fieldInfo.fieldType = (String) String.valueOf(field.getType());

                if(field.getType() == Schema.DisplayType.REFERENCE){
                    fieldInfo.isRefrenceField = true;
                    String refrenceObjName = string.valueOf(field.getReferenceTo()[0]);
                    String refrnceObjRelationshipName = field.getRelationshipName();
                    fieldInfo.referenceObjName = refrenceObjName;
                    fieldInfo.referenceObjNameField = getObjectNameField(refrenceObjName,refrnceObjRelationshipName );
                }
                else{
                    fieldInfo.isRefrenceField = false;
                }
                fields.put(fieldInfo.fieldName, fieldInfo);
            }

            return fields;
        } catch (Exception e) {
            // System.debug('exception in getFieldInfo : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return fields;
        }
    }

    public static String getObjectNameField(String refernceObjName, String relationshipName){
        String nameField = 'Id';

        Schema.SObjectType sobjType = Schema.getGlobalDescribe().get(refernceObjName);
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> mapOfFields = r.fields.getMap();

        for(Schema.SObjectField field : mapOfFields.values()){
            if(field.getDescribe().isNameField()){
                nameField = relationshipName +'.'+ field.getDescribe().getName();
            }
        }

        return nameField;
    }

    public class FieldSection {
        public String sectionName { get; set; }
        public Integer sectionIndex { get; set; }
        public List<FieldInfo> leftColumn { get; set; }
        public List<FieldInfo> rightColumn { get; set; }

        public FieldSection(Integer sectionIndex, String sectionName) {
            this.sectionIndex = sectionIndex;
            this.sectionName = sectionName;
            this.leftColumn = new List<FieldInfo>();
            this.rightColumn = new List<FieldInfo>();
        }
    }

    public class FieldInfo{
        public string fieldName { get; set; }
        public string fieldLabel { get; set; }
        public string fieldType { get; set; }
        public Boolean isRefrenceField { get; set; }
        public string refrenceField { get; set; }
        public string refrenceFieldValue { get; set; }
        public string referenceObjName { get; set; }
        public string referenceObjNameField { get; set; }
        public string fieldValue { get; set; }
        public string refrenceURL { get; set; }
        public string sectionName { get; set; }
        public Integer sectionIndex { get; set; }
        public Integer columnIndex { get; set; }
    }

}