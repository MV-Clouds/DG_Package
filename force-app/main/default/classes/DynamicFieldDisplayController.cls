public with sharing class DynamicFieldDisplayController {    
    public String recordId { get; set; }
    public String objectName { get; set; }
    public String objectID {get;set;}
    public String layoutName { get; set; }
    public string RecordTypeId { get; set;}
    public List<FieldSection> fieldSections { get; set; }
    public List<RelatedList> relatedLists { get; set; }

    public DynamicFieldDisplayController() {
        this.recordId = ApexPages.currentPage().getParameters().get('id');
        if(this.recordId != null){
            this.objectName = getObjectNameFromRecordId(this.recordId);
            this.objectID = getObjectIdByApiName(this.objectName);
            this.RecordTypeId = getRecordTypeId(this.recordId, this.objectName);
            System.debug('obj-->'+this.objectName);
            this.layoutName = getObjectLayout(this.objectID, this.RecordTypeId)[0]; // Change this to the desired layout
            System.debug('layout-->'+this.layoutName);
            this.fieldSections = new List<FieldSection>();
            this.relatedLists = new List<RelatedList>();
            fetchRecordFieldValues();
            // fetchRelatedLists(this.objectName, this.layoutName, this.recordId);
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

    public void fetchRecordFieldValues() {
        try {
            Map<String, Object> recordFieldValues = getRecordFieldValues(recordId, objectName, layoutName);
            List<Map<String, Object>> fieldDetails = getFields(objectName, layoutName);

            Map<Integer, FieldSection> sectionsMap = new Map<Integer, FieldSection>();
            Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();


            for (Map<String, Object> fieldDetail : fieldDetails) {
                String sectionName = (String) fieldDetail.get('sectionName');
                Integer sectionIndex = (Integer) fieldDetail.get('sectionIndex');
                Integer columnIndex = (Integer) fieldDetail.get('columnIndex');
                String fieldName = (String) fieldDetail.get('field');
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
                    section.leftColumn.add(new Field(fieldName, formattedFieldValue, fieldLabel));
                } else if (columnIndex == 1) {
                    section.rightColumn.add(new Field(fieldName, formattedFieldValue, fieldLabel));
                }
            }

            // Convert map to list
            this.fieldSections = sectionsMap.values();
        } catch (Exception e) {
            System.debug('Error in fetchRecordFieldValues: ' + e.getMessage());
            throw new AuraHandledException('Unable to fetch record field values.');
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

   

public class ChildRelationshipInfo {
    public String childObjectName { get; set; }
    public String relationshipName { get; set; }
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

        public Field(String fieldName, String fieldValue, String fieldLabel) {
            this.fieldName = fieldName;
            this.fieldValue = fieldValue;
            this.fieldLabel = fieldLabel;
        }
    }

    public class RelatedList {
        public String sObjectType { get; set; }
        public String sObjectName { get; set; }
        public List<String> sObjectLabel { get; set; }

        public List<SObject> records { get; set; }
        
        public RelatedList() {
            this.records = new List<SObject>();
            this.sObjectLabel = new List<String>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getObjects(boolean shouldGetStandard) {
        List<String> sObjectList = new List<String>();
        
        System.debug('shouldGetStandard:' + shouldGetStandard);
        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().values()){
            String name = objTyp.getDescribe().getName();
            if(shouldGetStandard) {
                sObjectList.add(name); 
            }
            if((!name.containsIgnoreCase('history') && !name.containsIgnoreCase('tag') &&
                !name.containsIgnoreCase('share') && !name.containsIgnoreCase('feed')) && 
               name.toLowerCase().right(3) ==  '__c'){      
                   sObjectList.add(name);
               }
        }
        System.debug('sObjectList:' + sObjectList);
        return sObjectList;
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
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getLayoutFields(String objectName, String layout) {
        return getFields(objectName, layout);
    }
    
    public static String toolingAPISOQL(String query) {
        String instanceUrl = System.URL.getOrgDomainUrl().toExternalForm();
        System.debug('instance-->'+instanceUrl);
        String baseURL = instanceUrl+'/services/data/v61.0/tooling/query?';
        String sid = getSessionId();
        return restGet(baseURL + 'q=' + (query.replace(' ', '+')), 'GET', sid);
    } 

    public static String getRecordTypeId(String recordId, String objectType) {
    // Dynamic query to fetch RecordTypeId
    Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(objectType).getDescribe().fields.getMap();
    boolean isRecordID = fields.containsKey('RecordTypeId');
    if(isRecordID){
        String query = 'SELECT RecordTypeId FROM ' + objectType + ' WHERE Id = \'' + recordId + '\'';
        System.debug('query1-->'+query);
        SObject record = Database.query(query);
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
        System.debug('id-->'+objectId);
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
            System.debug(layouts);
            return layouts;
        }
        return null;
    }

    public static String getObjectIdByApiName(String objectApiName) {
        // String cleanApiName = objectApiName.endsWith('__c') ? objectApiName.substring(0, objectApiName.length() - 3) : objectApiName;
    // String objectApiNameQuery = objectApiName.endsWith('__c') ? objectApiName : objectApiName + '__c';
        if(Schema.sObjectType.EntityDefinition.Fields.DurableId.isAccessible() && Schema.sObjectType.EntityDefinition.Fields.QualifiedApiName.isAccessible() && objectApiName != null){
            EntityDefinition objectInfo = [SELECT DurableId FROM EntityDefinition WHERE QualifiedApiName = :objectApiName LIMIT 1];
            return objectInfo != null ? objectInfo.DurableId : null;
        }
    }


      @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRecordFieldValues(String recordId, String objectName, String layout) {
        try {
            List<Map<String, Object>> fieldDetails = getFields(objectName, layout);
            
            List<String> fieldNames = new List<String>();
            for (Map<String, Object> fieldDetail : fieldDetails) {
                if(fieldDetail.get('field') != null){
                    System.debug('field-->'+fieldDetail.get('field'));
                    fieldNames.add((String)fieldDetail.get('field'));
                }
            }

            String soql = 'SELECT Id, ' + String.join(fieldNames, ', ') + ' FROM ' + objectName + ' WHERE Id = \''+recordId+'\'';
            System.debug('soql-->'+soql);
            SObject record = Database.query(soql);
            
            Map<String, Object> recordFieldValues = new Map<String, Object>();
            for (String fieldName : fieldNames) {
                System.debug('sol-->'+fieldName);
                System.debug(record.get(fieldName));
                recordFieldValues.put(fieldName, record.get(fieldName) != null ? record.get(fieldName) : 'null');
                System.debug(recordFieldValues);
            }
            
            return recordFieldValues;
        } catch (Exception e) {
            System.debug('Error in getRecordFieldValues: ' + e.getMessage());

            throw new AuraHandledException('Unable to fetch record field values.');
        }
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> getFields(String objectName, String layout) {
        String layoutName = String.format('{0}-{1}', new String[]{objectName, layout});
        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {layoutName});

        List<Map<String, Object>> fieldDetails = new List<Map<String, Object>>();
        Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
        Integer sectionIndex = 0;
        for (Metadata.LayoutSection section : layoutMd.layoutSections) {
            Integer columnIndex = 0;
            String sectionLabel = section.label != null ? section.label : 'Section ' + sectionIndex;  // Use label if available, else default to index
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                System.debug(column.layoutItems);
                if (column.layoutItems != null) {
                    for (Metadata.LayoutItem item : column.layoutItems) {
                        Map<String, Object> fieldDetail = new Map<String, Object>();
                        fieldDetail.put('field', item.field);
                        System.debug('item'+item.field);
                        fieldDetail.put('sectionName', sectionLabel);  // Assign section label here
                        System.debug('sectionname-->'+sectionLabel);
                        fieldDetail.put('sectionIndex', sectionIndex);
                        fieldDetail.put('columnIndex', columnIndex);
                        fieldDetails.add(fieldDetail);
                    }
                }
                columnIndex++;
            }
            sectionIndex++;
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
            System.debug('body-->'+r.getBody());
            return r.getBody();
        }
        catch(Exception ex)
        {
            system.debug('Exception in tooling API Call:'+ ex.getMessage());
            return ex.getMessage();
        }
    }
}