public with sharing class DynamicFieldDisplayController {    
    public String recordId { get; set; }
    public String NameSpace { get; set; }
    public String objectName { get; set; }
    public String objectID {get;set;}
    public String layoutName { get; set; }
    public string RecordTypeId { get; set;}
    public List<FieldSection> fieldSections { get; set; }
    public string baseUrl { get; set; }


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
            baseUrl = URL.getOrgDomainUrl().getHost().split('.com')[0];
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
            Map<String, Object> recordFieldValues = getRecordFieldValues(recordId, objectName, layoutName, NameSpace);
            List<Map<String, Object>> fieldDetails = getFields(objectName, layoutName, NameSpace);



            Map<Integer, FieldSection> sectionsMap = new Map<Integer, FieldSection>();
            Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();


            for (Map<String, Object> fieldDetail : fieldDetails) {
                String sectionName = (String) fieldDetail.get('sectionName');
                Integer sectionIndex = (Integer) fieldDetail.get('sectionIndex');
                Integer columnIndex = (Integer) fieldDetail.get('columnIndex');
                String fieldName = (String) fieldDetail.get('field');
                String fieldType = (String) fieldDetail.get('fieldType');
                Object fieldValue = recordFieldValues.get(fieldName);
                String fieldLabel = fieldsMap.containsKey(fieldName) ? fieldsMap.get(fieldName).getDescribe().getLabel() : fieldName;


                String formattedFieldValue;
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

                if (!sectionsMap.containsKey(sectionIndex)) {
                    sectionsMap.put(sectionIndex, new FieldSection(sectionIndex, sectionName));
                }

                FieldSection section = sectionsMap.get(sectionIndex);
                if (columnIndex == 0) {
                    section.leftColumn.add(new Field(fieldName, formattedFieldValue, fieldLabel, fieldType));
                } else if (columnIndex == 1) {
                    section.rightColumn.add(new Field(fieldName, formattedFieldValue, fieldLabel, fieldType));
                }
            }

            // Convert map to list
            this.fieldSections = sectionsMap.values();
        } catch (Exception e) {
            throw new AuraHandledException('Unable to fetch record field values.'+ e);
        }
    }

    private String formatAddress(Address address) {
        List<String> addressParts = new List<String>();
        if (address.getStreet() != null) addressParts.add(address.getStreet());
        if (address.getCity() != null) addressParts.add(address.getCity());
        if (address.getState() != null) addressParts.add(address.getState());
        if (address.getPostalCode() != null) addressParts.add(address.getPostalCode());
        if (address.getCountry() != null) addressParts.add(address.getCountry());
        return String.join(addressParts, ', ');
    }



    public class FieldSection {
        public String sectionName { get; set; }
        public Integer sectionIndex { get; set; }
        public List<Field> leftColumn { get; set; }
        public List<Field> rightColumn { get; set; }

        public FieldSection(Integer sectionIndex, String sectionName) {
            this.sectionIndex = sectionIndex;
            this.sectionName = sectionName;
            this.leftColumn = new List<Field>();
            this.rightColumn = new List<Field>();
        }
    }

    public class Field {
        public String fieldName { get; set; }
        public String fieldValue { get; set; }
        public String fieldLabel { get; set; }
        public String fieldType { get; set; }

        public Field(String fieldName, String fieldValue, String fieldLabel, String fieldType) {
            this.fieldName = fieldName;
            this.fieldValue = fieldValue;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
        }
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
    public static Map<String, Object> getRecordFieldValues(String recordId, String objectName, String layout, String NameSpace) {
        try {
            List<Map<String, Object>> fieldDetails = getFields(objectName, layout, NameSpace);
            
            List<String> fieldNames = new List<String>();
            for (Map<String, Object> fieldDetail : fieldDetails) {
                if(fieldDetail.get('field') != null){
                    fieldNames.add((String)fieldDetail.get('field'));
                }
            }


            String soql = 'SELECT Id, ' + String.join(fieldNames, ', ') + ' FROM ' + String.escapeSingleQuotes(objectName) + ' WHERE Id = \''+ String.escapeSingleQuotes(recordId) +'\'';
            SObject record = Database.query(soql);
            
            Map<String, Object> recordFieldValues = new Map<String, Object>();
            for (String fieldName : fieldNames) {
                recordFieldValues.put(fieldName, record.get(fieldName) != null ? record.get(fieldName) : 'null');
            }
            
            return recordFieldValues;
        } catch (Exception e) {

            throw new AuraHandledException('Unable to fetch record field values.');
        }
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> getFields(String objectName, String layout, String NameSpace) {
        List<Map<String, Object>> fieldDetails = new List<Map<String, Object>>();
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
                                // System.debug('field : ' + field);
                                // System.debug('objectFields.get(field) : ' + objectFields.get(field));
                                // Boolean isRefrenceField = objectFields.get(field)?.isRefrenceField;
                                // if(isRefrenceField){
                                //     System.debug('referenceObjNameField : ' + objectFields.get(field)?.referenceObjNameField);
                                //     field = objectFields.get(field)?.referenceObjNameField;
                                // }
                                Map<String, Object> fieldDetail = new Map<String, Object>();
                                fieldDetail.put('field', field);
                                fieldDetail.put('fieldType', objectFields.get(field)?.fieldType);
                                fieldDetail.put('sectionName', sectionLabel);
                                fieldDetail.put('sectionIndex', sectionIndex);
                                fieldDetail.put('columnIndex', columnIndex);
                                System.debug('fieldDetail : ' + fieldDetail);
                                fieldDetails.add(fieldDetail);
                            }
                        }
                        columnIndex++;
                    }
                    sectionIndex++;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Unable to fetch record field values.'+e);
        }
        return fieldDetails;
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

        try {
            Schema.SObjectType sobjType = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeSObjectResult r = sobjType.getDescribe();
            Map<String, Schema.SObjectField> mapOfFields = r.fields.getMap();
            List<String> fieldsList = new List<String>(mapOfFields.keySet());
            fieldsList.sort();
            
            Map<String, FieldInfo> fields = new Map<String, FieldInfo>();
            
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
            System.debug('exception in getFieldInfo : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
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

    public class FieldInfo{
        public string fieldName; 
        public string fieldLabel; 
        public string fieldType; 
        public Boolean isRefrenceField;
        public string referenceObjName;
        public string referenceObjNameField;
    }
}