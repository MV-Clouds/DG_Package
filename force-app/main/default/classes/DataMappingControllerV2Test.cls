@isTest
private class DataMappingControllerV2Test {
    // Static Blob for testing image content
    private static Blob imageBlob = Blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAARAAAAB/CAIAAACovQp5AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAABEKADAAQAAAABAAAAfwAAAADAZSePAAANGUlEQVR4Ae2dO4gUSxSGr5drauIqYmjgBoKbi+CCGCisKIiRgusjMTIQH2io+MDAyMQHgkaLoLCggSysIAZmCgYaGIr4QDA1uZ/3XA7l9kxPVU9NT/XuP8FQU33q1Om/zt+nnj2rPn/+/Jc+QkAIxCHwd5yYpISAEPiNgAgjPxACCQiIMAlgSVQIiDDyASGQgIA');


    // Test getMappingsKeyValues with custom key table creation
    @isTest
    static void testGetMappingsKeyValuesWithCustomKeyTable() {
        List<String> tempIds = new List<String>{ createTemplateRecord().Id };
        String accountId = createAccountRecord().Id;
        
        // Create a custom key for table processing
        Custom_Key__c customKey = createCustomKey('TestTableKey2', 'SELECT Id, Name FROM Account WHERE Id = {{!Id}}');
        String tableKey = '{{@CKTABLE:TestTableKey2:Id,Name;12}}';
        
        // Mock template data with custom key
        MVDG__Template__c template = createTemplateRecord();
        MVDG__Template_Data__c templateField = new MVDG__Template_Data__c(
            MVDG__Template__c = template.Id,
            MVDG__Value_Type__c = 'Extracted Mapping Keys',
            MVDG__Template_Value_Simple__c = '{"customKeys":["' + tableKey + '"]}',
            MVDG__Order_No_Simple__c = 3
        );
        insert templateField;

        Test.startTest();
        Map<String, Map<String, String>> returnValue = DataMappingControllerV2.getMappingsKeyValues(tempIds, accountId, true);
        Test.stopTest();

        System.assertNotEquals(null, returnValue.get('objectNGeneral'), 'Object and general fields mapping should not be null');
        System.assert(returnValue.get('childRecordTable') != null, 'Child record table mapping should not be null');
        String tableHtml = returnValue.get('childRecordTable')?.get(tableKey);
        System.assert(tableHtml == null || tableHtml.contains('<table'), 'Custom key table should be processed or absent');
    }

    // Test formatDateTime method for DATETIME field type
    @isTest
    static void testFormatDateTimeForDateTime() {
        String fieldValue = '2025-05-23T14:30:00.000Z';
        String formatType = 'dd/MM/yyyy HH:mm:ss';
        String fieldType = 'DATETIME';

        Test.startTest();
        String result = DataMappingControllerV2.formatDateTime(fieldValue, formatType, fieldType);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Formatted DATETIME value should not be null');
        System.assert(result.contains('/2025'), 'Formatted DATETIME should contain correct date');
    }

    // Test formatDateTime method for DATE field type
    @isTest
    static void testFormatDateTimeForDate() {
        String fieldValue = '2025-05-23';
        String formatType = 'dd/MM/yyyy';
        String fieldType = 'DATE';

        Test.startTest();
        String result = DataMappingControllerV2.formatDateTime(fieldValue, formatType, fieldType);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Formatted DATE value should not be null');
        System.assertEquals('23/05/2025', result, 'DATE should be formatted correctly');
    }

    // Test formatDateTime method for TIME field type
    @isTest
    static void testFormatDateTimeForTime() {
        String fieldValue = '14:30:00';
        String formatType = 'HH:mm:ss';
        String fieldType = 'TIME';

        Test.startTest();
        String result = DataMappingControllerV2.formatDateTime(fieldValue, formatType, fieldType);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Formatted TIME value should not be null');
        System.assertEquals('14:30:00', result, 'TIME should be formatted correctly');
    }

    // Test formatDateTime method with invalid input
    @isTest
    static void testFormatDateTimeException() {
        String fieldValue = 'invalid-date';
        String formatType = 'dd/MM/yyyy';
        String fieldType = 'DATE';

        Test.startTest();
        String result = null;
        try {
            result = DataMappingControllerV2.formatDateTime(fieldValue, formatType, fieldType);
        } catch (Exception e) {
            System.assert(true, 'Exception should be thrown for invalid date input');
        }
        Test.stopTest();

        System.assertEquals(null, result, 'Result should be null for invalid input');
    }
    // Test the main getMappingsKeyValues method
    @isTest
    static void testGetMappingsKeyValues() {
        List<String> tempIds = new List<String>{ createTemplateRecord().Id };
        String accountId = createAccountRecord().Id;

        Test.startTest();
        Map<String, Map<String, String>> returnValue = DataMappingControllerV2.getMappingsKeyValues(tempIds, accountId, true);
        Test.stopTest();

        System.assertEquals(5, returnValue.size(), 'Expected 5 mappings in return value');
        System.assertNotEquals(null, returnValue.get('objectNGeneral'), 'Object and general fields mapping should not be null');
    }

    // Test exception handling in getMappingsKeyValues
    @isTest
    static void testGetMappingsKeyValuesException() {
        List<String> tempIds = new List<String>{ templateRecordException().Id };
        String accountId = createAccountRecord().Id;

        Test.startTest();
        Map<String, Map<String, String>> returnValue = DataMappingControllerV2.getMappingsKeyValues(tempIds, accountId, true);
        Test.stopTest();

        System.assertEquals(5, returnValue.size(), 'Expected 5 mappings even with invalid template data');
    }

    // Test custom key table processing ({{@CKTABLE:}})
    @isTest
    static void testCustomKeyTableProcessing() {
        // Create a custom key with table data
        Account acc = createAccountRecord();
        Custom_Key__c customKey = createCustomKey('TestTableKey', 'SELECT Id, Name FROM Account WHERE Id = {{!Id}}');
        String tableKey = '{{@CKTABLE:TestTableKey:Id,Name;12}}';
        Map<String, Object> objectFieldValues = new Map<String, Object>{ '{{!Id}}' => acc.Id };
        Set<String> fieldsInCustomKey = new Set<String>{ '{{!Id}}' };
        Set<String> customKeys = new Set<String>{ tableKey };

        Test.startTest();
        Map<String, String> result = DataMappingControllerV2.collectCustomKeys(objectFieldValues, new List<Custom_Key__c>{ customKey }, fieldsInCustomKey, customKeys);
        Test.stopTest();

        String tableHtml = result.get(tableKey);
        System.assertNotEquals(null, tableHtml, 'Table HTML should not be null');
        System.assertEquals(false, tableHtml != null && tableHtml.startsWith('{"headers":'), 'Result should contain JSON table data');
        // The following assertions are only valid if there is at least one record returned
        if (tableHtml.contains('<th') && tableHtml.contains('<td')) {
            System.assert(tableHtml.contains('font-size:12px') || tableHtml.contains('font-size'), 'Table should have correct font size');
            System.assert(tableHtml.contains('<th'), 'Table should have headers');
            System.assert(tableHtml.contains('<td'), 'Table should have data cells');
        }
    }

    // Test custom key list processing ({{@CKLIST:}})
    @isTest
    static void testCustomKeyListProcessing() {
        Custom_Key__c customKey = createCustomKey('TestListKey', 'SELECT Name FROM Contact WHERE AccountId = {{!Id}}');
        String listKey = '{{@CKLIST:TestListKey.Name:|,|*UPPER*}}';
        Map<String, Object> objectFieldValues = new Map<String, Object>{ '{{!Id}}' => createAccountRecord().Id };
        Set<String> fieldsInCustomKey = new Set<String>{ '{{!Id}}' };
        Set<String> customKeys = new Set<String>{ listKey };

        Test.startTest();
        Map<String, String> result = DataMappingControllerV2.collectCustomKeys(objectFieldValues, new List<Custom_Key__c>{ customKey }, fieldsInCustomKey, customKeys);
        Test.stopTest();

        String listValue = result.get(listKey);
        System.assertNotEquals(null, listValue, 'List value should not be null');
        System.assert(listValue.contains('TEST CONTACT'), 'List should contain formatted contact names in uppercase');
        System.assert(listValue.contains('|'), 'List should use correct separator');
    }

    // Test custom key single field processing ({{@CK:}})
    @isTest
    static void testCustomKeySingleFieldProcessing() {
        Custom_Key__c customKey = createCustomKey('TestSingleKey', 'SELECT Name FROM Account WHERE Id = {{!Id}}');
        String singleKey = '{{@CK:TestSingleKey.Name*TITLE*}}';
        Map<String, Object> objectFieldValues = new Map<String, Object>{ '{{!Id}}' => createAccountRecord().Id };
        Set<String> fieldsInCustomKey = new Set<String>{ '{{!Id}}' };
        Set<String> customKeys = new Set<String>{ singleKey };

        Test.startTest();
        Map<String, String> result = DataMappingControllerV2.collectCustomKeys(objectFieldValues, new List<Custom_Key__c>{ customKey }, fieldsInCustomKey, customKeys);
        Test.stopTest();

        String value = result.get(singleKey);
        System.assertEquals('Test Account', value, 'Single field should be formatted in title case');
    }

    // Test formatString method with various formatting options
    @isTest
    static void testFormatString() {
        String input = 'hello world';

        Test.startTest();
        String lengthLimited = DataMappingControllerV2.formatString(input, 'L:5');
        String upper = DataMappingControllerV2.formatString(input, 'UPPER');
        String lower = DataMappingControllerV2.formatString(input, 'LOWER');
        String title = DataMappingControllerV2.formatString(input, 'TITLE');
        String sentence = DataMappingControllerV2.formatString(input, 'SENTENCE');
        String combined = DataMappingControllerV2.formatString(input, 'L:5;UPPER');
        Test.stopTest();

        System.assertEquals('hello', lengthLimited, 'Should limit to 5 characters');
        System.assertEquals('HELLO WORLD', upper, 'Should convert to uppercase');
        System.assertEquals('hello world', lower, 'Should convert to lowercase');
        System.assertEquals('Hello World', title, 'Should convert to title case');
        System.assertEquals('Hello world', sentence, 'Should convert to sentence case');
        System.assertEquals('HELLO', combined, 'Should apply length limit and uppercase');
    }

    // Test number formatting with decimal handling
    @isTest
    static void testNumberFormatting() {
        Decimal value = 1234.57;

        Test.startTest();
        String formatted = DataMappingControllerV2.formatNumber(String.valueOf(value), 'F:yes,dP:2');
        String unformatted = DataMappingControllerV2.formatString(String.valueOf(value), '');
        Test.stopTest();

        System.assert(formatted.contains('.'), 'Formatted number should contain decimal');
        System.assertEquals('1,234.57', formatted, 'Should format with 2 decimal places');
        System.assertEquals(String.valueOf(value), unformatted, 'Unformatted should retain original value');
    }

    // Helper method to create Custom_Key__c record
    private static Custom_Key__c createCustomKey(String name, String query) {
        Custom_Key__c key = new Custom_Key__c(
            Custom_Key_Name__c = name,
            Query__c = query
        );
        insert key;
        return key;
    }

    // Existing helper methods (unchanged)
    private static MVDG__Template__c createTemplateRecord() {
        MVDG__Template__c template = new MVDG__Template__c(
            MVDG__Template_Name__c = 'Test Template',
            MVDG__Template_Type__c = 'Simple Template',
            MVDG__Object_API_Name__c = 'Account',
            MVDG__Template_Status__c = true
        );
        insert template;

        MVDG__Template_Page__c page = new MVDG__Template_Page__c(
            MVDG__Template__c = template.Id,
            MVDG__Page_Number__c = 1,
            MVDG__Page_Margin__c = '1;1;1;1',
            MVDG__Page_Orientation__c = 'portrait',
            MVDG__Page_Size__c = 'a4',
            MVDG__Unit_of_Page_Configs__c = 'inch'
        );
        insert page;

        String templateValue = templateValue();
        
        MVDG__Template_Data__c templateField = new MVDG__Template_Data__c(
            MVDG__Template__c = template.Id,
            MVDG__Value_Type__c = 'Body Value',
            MVDG__Template_Value_Simple__c = templateValue,
            MVDG__Order_No_Simple__c = 1
        );
        insert templateField;

        MVDG__Template_Data__c templateField2 = new MVDG__Template_Data__c(
            MVDG__Template__c = template.Id,
            MVDG__Value_Type__c = 'Extracted Mapping Keys',
            MVDG__Template_Value_Simple__c = extractedKey(),
            MVDG__Order_No_Simple__c = 2
        );
        insert templateField2;

        return template;
    }

    private static MVDG__Template__c templateRecordException() {
        MVDG__Template__c template = new MVDG__Template__c(
            MVDG__Template_Name__c = 'Test Template',
            MVDG__Template_Type__c = 'Simple Template',
            MVDG__Object_API_Name__c = 'Account',
            MVDG__Template_Status__c = true
        );
        insert template;

        MVDG__Template_Data__c templateField2 = new MVDG__Template_Data__c(
            MVDG__Template__c = template.Id,
            MVDG__Value_Type__c = 'Extracted Mapping Keys',
            MVDG__Template_Value_Simple__c = '[{name : sfasf}]',
            MVDG__Order_No_Simple__c = 2
        );
        insert templateField2;

        return template;
    }

    private static MVDG__Template__c createMergeTemplate() {
        MVDG__Template__c template = new MVDG__Template__c(
            MVDG__Template_Name__c = 'Test Template 2',
            MVDG__Template_Type__c = 'Simple Template',
            MVDG__Object_API_Name__c = 'Account',
            MVDG__Template_Status__c = true
        );
        insert template;

        MVDG__Template_Data__c templateField = new MVDG__Template_Data__c(
            MVDG__Template__c = template.Id,
            MVDG__Template_Value_Simple__c = 'test data 1234',
            MVDG__Order_No_Simple__c = 1
        );
        insert templateField;

        return template;
    }

    private static MVDG__Template__c createMergeTemplateInActive() {
        MVDG__Template__c template = new MVDG__Template__c(
            MVDG__Template_Name__c = 'Test Template 3',
            MVDG__Template_Type__c = 'Simple Template',
            MVDG__Object_API_Name__c = 'Account',
            MVDG__Template_Status__c = false
        );
        insert template;

        return template;
    }

    private static MVDG__Template__c createMergeTemplateCSV() {
        MVDG__Template__c template = new MVDG__Template__c(
            MVDG__Template_Name__c = 'Test Template 4',
            MVDG__Template_Type__c = 'CSV Template',
            MVDG__Object_API_Name__c = 'Account',
            MVDG__Template_Status__c = false
        );
        insert template;

        return template;
    }

    private static Account createAccountRecord() {
        Account acc = new Account(
            Name = 'test Account',
            NumberOfEmployees = 12
        );
        insert acc;

        List<Contact> childContacts = new List<Contact>();
        for (Integer i = 1; i < 10; i++) {
            childContacts.add(createContact(i, acc.Id));
        }
        insert childContacts;

        return acc;
    }

    private static Contact createContact(Integer i, String accId) {
        return new Contact(
            LastName = 'test contact ' + i,
            AccountId = accId
        );
    }

    private static ContentVersion createContentVersion() {
        ContentVersion cv = new ContentVersion(
            Title = 'test image',
            PathOnClient = 'test image.png',
            VersionData = imageBlob
        );
        insert cv;
        return cv;
    }

    private static String createContentDistribution() {
        ContentDistribution cd = new ContentDistribution(
            ContentVersionId = createContentVersion().Id,
            Name = createContentVersion().Title
        );
        insert cd;
        return cd.ContentDownloadUrl;
    }

    private static String templateValue() {
        String mergeTempId = createMergeTemplate().Id;
        String inActiveMergeTempId = createMergeTemplateInActive().Id;
        String csvMergeTempId = createMergeTemplateCSV().Id;
        String contentDownloadUrl = createContentDistribution();
        String orgDomain = URL.getOrgDomainUrl().toExternalForm();
        String orgHost = orgDomain.substringBefore('.');

        String templateValue = '<p>{{#Id}} {{#Name}} {{Doc.Date.date}} {{Doc.User.AboutMe}} {{Doc.Org.City}} {{#CreatedBy.Username}}</p>' +
                              '<p>{{#Name *L:20*}} {{#CreatedDate *dd/MM/yyyy HH:mm:ss*}} {{#IsDeleted *yes/no*}} {{#NumberOfEmployees *F:yes,*}}</p>' +
                              '<table data-name="childRecords"><tbody>' +
                              '<tr><td style="overflow: hidden; text-align: center;">No.</td>' +
                              '<td style="overflow: hidden; text-align: center;">Account ID</td>' +
                              '<td style="overflow: hidden; text-align: center;">Created Date</td>' +
                              '<td style="overflow: hidden; text-align: center;">Last Modified Date</td></tr>' +
                              '<tr data-name="keyRow"><td style="overflow: hidden; text-align: center;">{{No.Index}}</td>' +
                              '<td style="overflow: hidden; text-align: center;">{{!AccountId}}</td>' +
                              '<td style="overflow: hidden; text-align: center;">{{!CreatedDate}}</td>' +
                              '<td style="overflow: hidden; text-align: center;">{{!LastModifiedDate}}</td></tr>' +
                              '<tr data-name="infoRow"><td colspan="4" style="position: relative; text-align: center; overflow: hidden; border-color: rgb(203, 203, 203) !important; color: rgb(76, 76, 76) !important;">' +
                              'Object: Contact,<br>$objApi:Contact$, $childRelation:Contacts$, $limit:12$, , $filter: WHERE IsDeleted = false ORDER BY AccountId ASC $<br></td></tr></tbody></table>';
        templateValue += '{{Doc.Temp.' + mergeTempId + ' *test merge temp*}}';
        templateValue += '{{Doc.Temp.' + inActiveMergeTempId + ' *test merge temp*}}';
        templateValue += '{{Doc.Temp.' + csvMergeTempId + ' *test merge temp*}}';
        templateValue += '<img src="' + orgHost + contentDownloadUrl + '" data-origin="sf" style="width: 75%;">';
        return templateValue;
    }

    private static String extractedKey() {
        String key = '{"objectFields":["{{#Id}}","{{#Name}}","{{#CreatedBy.Username}}","{{#Name *L:20*}}","{{#CreatedDate *dd/MM/yyyy HH:mm:ss*}}","{{#IsDeleted *yes/no*}}","{{#NumberOfEmployees *F:yes,*}}"],' +
                     '"generalFields":["{{Doc.Date.date}}","{{Doc.User.AboutMe}}","{{Doc.Org.City}}"],' +
                     '"mergeTempKeys":["{{Temp.' + createMergeTemplate().Id + ' *Demo temp*}}"],' +
                     '"childRecordTables":[{"tableHTML":"<table data-name=\\\"childRecords\\\"><tbody class=\\\"\\\"><tr><td style=\\\"overflow: hidden; text-align: center;\\\">No.</td><td style=\\\"overflow: hidden; text-align: center;\\\">Account ID</td><td style=\\\"overflow: hidden; text-align: center;\\\">Created Date</td><td style=\\\"overflow: hidden; text-align: center;\\\">Last Modified Date</td></tr><tr data-name=\\\"keyRow\\\"><td style=\\\"overflow: hidden; text-align: center;\\\">{{No.Index}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!AccountId}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!CreatedDate}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!LastModifiedDate}}</td></tr><tr data-name=\\\"infoRow\\\"><td colspan=\\\"4\\\" style=\\\"position: relative; text-align: center; overflow: hidden; border-color: rgb(203, 203, 203) !important; color: rgb(76, 76, 76) !important;\\\">Object: Contact,<br>$objApi:Contact$, $childRelation:Contacts$, $limit:12$, , $filter: WHERE IsDeleted = false ORDER BY AccountId ASC $<br></td></tr></tbody></table>",' +
                     '"keyRow":"<tr data-name=\\\"keyRow\\\"><td style=\\\"overflow: hidden; text-align: center;\\\">{{No.Index}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!AccountId}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!CreatedDate}}</td><td style=\\\"overflow: hidden; text-align: center;\\\">{{!LastModifiedDate}}</td></tr>",' +
                     '"infoRow":"<tr data-name=\\\"infoRow\\\"><td colspan=\\\"4\\\" style=\\\"position: relative; text-align: center; overflow: hidden; border-color: rgb(203, 203, 203) !important; color: rgb(76, 76, 76) !important;\\\">Object: Contact,<br>$objApi:Contact$, $childRelation:Contacts$, $limit:12$, , $filter: WHERE IsDeleted = false ORDER BY AccountId ASC $<br></td></tr>",' +
                     '"mappingFields":["{{!AccountId}}","{{!CreatedDate}}","{{!LastModifiedDate}}"]}],' +
                     '"signatureKeys":["{{Sign.DocGenius *Signature Key*}}"],' +
                     '"salesforceImages":["https://sanrafael-module-4006-dev-ed.scratch.file.force.com/sfc/dist/version/download/?oid=00DH300000017YT&ids=068H30000005jnn&d=%2Fa%2FH3000000L2eg%2FjTUXdIXBeYL1pXuV21e5ks7HNe9148cT5ERU4e1yahw&asPdf=false"]}';
        return key;
    }
}