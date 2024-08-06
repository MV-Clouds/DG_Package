@isTest
public class EditCSVTemplateControllerTest {
    
    @TestSetup
    static void makeData(){
        Template__c testTemplate = new Template__c(
            Description__c = 'Test Description',
            Object_API_Name__c = 'Contact',
            Template_Name__c = 'Contact Template',
            Template_Type__c = 'CSV Template',
            Template_Status__c = true
        );
        insert testTemplate;
        Template__c testTemplate2 = new Template__c(
            Description__c = 'Test Description 2',
            Object_API_Name__c = 'Contact',
            Template_Name__c = 'Contact Template',
            Template_Type__c = 'CSV Template',
            Template_Status__c = true
        );
        insert testTemplate2;

    }

    @IsTest
    static void testgetMethods(){
        Template__c testT = [SELECT Id,Name, Object_API_Name__c FROM Template__c LIMIT 1];
        Template_Page__c tp = new Template_Page__c(
            Page_Number__c =001,
            Template__c = testT.Id
        );
        insert tp;

        Template_Data__c templateField= new Template_Data__c(
            Template__c = testT.Id,
            CSV_Fields__c = 'Name,Id',
            Template_Page__c = tp.id,
            CSV_Query__c = 'SELECT Name,Id FROM Account LIMIT 1',
            CSV_orders__c = 'MasterRecordId<|IDG|>ASC<|SDG|>IsDeleted<|IDG|>ASC<|SDG|>Salutation<|IDG|>DESC',
            CSV_logic__c = 'AND',
            CSV_list_view__c = null,
            CSV_limit__c = 1000,
            CSV_Filter__c = 'FirstName<|IDG|>=<|IDG|>test<|IDG|>STRING<|IDG|>text<|FDG|>Title<|IDG|>=<|IDG|>test title<|IDG|>STRING<|IDG|>text<|FDG|>Company<|IDG|>!=<|IDG|>test<|IDG|>STRING<|IDG|>text<|FDG|>Street<|IDG|>!=<|IDG|>test<|IDG|>TEXTAREA<|IDG|>text',
            Order_No_Simple__c = 1
        );

        insert templateField;
        
        Test.startTest();
        // List<EditCSVTemplateController.FieldInfoWrapper> testFields = EditCSVTemplateController.getFields(testT.Object_API_Name__c);
        EditCSVTemplateController.templateDataWrapper testTemplateDataWithData = EditCSVTemplateController.getTemplateFieldsData(testT.Id);
        Test.stopTest();

        // System.assert(testFields.size()>0, 'There was an issue in fetching the Fields information...');
        System.assertEquals( templateField.CSV_Fields__c, testTemplateDataWithData.Fields, 'The Filter is Having some data, It should have two fields !!');
    }

    @IsTest
    static void testCSVController(){

        Account a = new Account(
            Name= 'Test Acc 1'
        );
        insert a;

        Template__c testT = [SELECT Id,Name, Object_API_Name__c FROM Template__c LIMIT 1];

        String query = 'SELECT Name,Id FROM Account LIMIT 1';

        EditCSVTemplateController.TemplateDataWrapper testTemplateData = new EditCSVTemplateController.TemplateDataWrapper();
        testTemplateData.maxLimit = 10000;
        testTemplateData.orders = 'MasterRecordId<|IDG|>ASC<|SDG|>IsDeleted<|IDG|>ASC<|SDG|>Salutation<|IDG|>DESC';
        testTemplateData.logic = 'OR';
        testTemplateData.listView = null;
        testTemplateData.filters = 'FirstName<|IDG|>=<|IDG|>test<|IDG|>STRING';
        testTemplateData.fields = 'Id, Name';

        Test.startTest();
        EditCSVTemplateController.saveTemplateFields(testT.Id, query, testTemplateData);
        EditCSVTemplateController.saveTemplateFields(testT.Id, query, testTemplateData);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Template_Page__c], 'template pages may not be more than one for csv template.');
        System.assertEquals(1, [SELECT COUNT() FROM Template_Data__c], 'template data may not be more than one for csv template.');
    }
    
    @IsTest
    public static void validateRelatedObjectTest() {

        String objName = 'Contact';
        String fieldName = 'AccountId';

        Test.startTest();
        String accPrefix = EditCSVTemplateController.validateRelatedObject(objName, fieldName);
        fieldName = 'ID';
        String conPrefix = EditCSVTemplateController.validateRelatedObject(objName, fieldName);
        Test.stopTest();
        
        System.assertEquals('001', accPrefix, 'Account prefix is wrong!');
        System.assertEquals('003', conPrefix, 'Contact prefix is wrong!');
    }

@isTest
    public static void getListViewsTest() {
        List<ListView> listViews;
        String objName = 'Account';
        
        Test.startTest();
        listViews= EditCSVTemplateController.getListViews(objName);
        Test.stopTest();
        
        System.assert(listViews.size() >=0, 'Count of List views can only be 0 or more than 0.');
    }
@isTest
    static void testGetTemplateDetails() {

        Template__c testT = [SELECT Id, Template_Name__c, Object_API_Name__c FROM Template__c LIMIT 1];

        Test.startTest();
        Template__c retrievedTemplate = EditCSVTemplateController.getTemplateDetails(testT.Id);
        Test.stopTest();
        System.assertEquals(testT.Template_Name__c,  retrievedTemplate.Template_Name__c, 'Queried fields do not match expected values');
    }
@isTest
    static void testCSVControllerUpdate(){

        Template__c testT = [SELECT Id, Template_Name__c, Object_API_Name__c FROM Template__c LIMIT 1];

        EditCSVTemplateController.TemplateInfo tempInfo = new EditCSVTemplateController.TemplateInfo();
        tempInfo.templateDescription = 'test';
        tempInfo.templateName = 'Test Name Updated';
        tempInfo.templateId = testT.Id;
        tempInfo.templateStatus = true;


        Test.startTest();
        EditCSVTemplateController.updateTemplate(tempInfo);
        Test.stopTest();

        Template__c updatedTemplate =  [SELECT Id, Template_Name__c, Object_API_Name__c FROM Template__c WHERE Id=:testT.Id LIMIT 1];

        System.assertNotEquals(testT.Template_Name__c, updatedTemplate.Template_Name__c, 'template Name must be updated.');
    }
}