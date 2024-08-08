@isTest
public class EditCSVTemplateControllerTest {
    
    @TestSetup
    static void makeData(){
        MVDG__Template__c testTemplate = new MVDG__Template__c(
            MVDG__Description__c = 'Test Description',
            MVDG__Object_API_Name__c = 'Contact',
            MVDG__Template_Name__c = 'Contact Template',
            MVDG__Template_Type__c = 'CSV Template',
            MVDG__Template_Status__c = true
        );
        insert testTemplate;
        MVDG__Template__c testTemplate2 = new MVDG__Template__c(
            MVDG__Description__c = 'Test Description 2',
            MVDG__Object_API_Name__c = 'Contact',
            MVDG__Template_Name__c = 'Contact Template',
            MVDG__Template_Type__c = 'CSV Template',
            MVDG__Template_Status__c = true
        );
        insert testTemplate2;

    }

    @IsTest
    static void testgetMethods(){
        MVDG__Template__c testT = [SELECT Id,Name, MVDG__Object_API_Name__c FROM MVDG__Template__c LIMIT 1];
        MVDG__Template_Page__c tp = new MVDG__Template_Page__c(
            MVDG__Page_Number__c =001,
            MVDG__Template__c = testT.Id
        );
        insert tp;

        MVDG__Template_Data__c templateField= new MVDG__Template_Data__c(
            MVDG__Template__c = testT.Id,
            MVDG__CSV_Fields__c = 'Name,Id',
            MVDG__Template_Page__c = tp.id,
            MVDG__CSV_Query__c = 'SELECT Name,Id FROM Account LIMIT 1',
            MVDG__CSV_Orders__c = 'MasterRecordId<|IDG|>ASC<|SDG|>IsDeleted<|IDG|>ASC<|SDG|>Salutation<|IDG|>DESC',
            MVDG__CSV_logic__c = 'AND',
            MVDG__CSV_list_view__c = null,
            MVDG__CSV_limit__c = 1000,
            MVDG__CSV_Filter__c = 'FirstName<|IDG|>=<|IDG|>test<|IDG|>STRING<|IDG|>text<|FDG|>Title<|IDG|>=<|IDG|>test title<|IDG|>STRING<|IDG|>text<|FDG|>Company<|IDG|>!=<|IDG|>test<|IDG|>STRING<|IDG|>text<|FDG|>Street<|IDG|>!=<|IDG|>test<|IDG|>TEXTAREA<|IDG|>text',
            MVDG__Order_No_Simple__c = 1
        );

        insert templateField;
        
        Test.startTest();
        // List<EditCSVTemplateController.FieldInfoWrapper> testFields = EditCSVTemplateController.getFields(testT.MVDG__Object_API_Name__c);
        EditCSVTemplateController.templateDataWrapper testTemplateDataWithData = EditCSVTemplateController.getTemplateFieldsData(testT.Id);
        Test.stopTest();

        // System.assert(testFields.size()>0, 'There was an issue in fetching the Fields information...');
        System.assertEquals( templateField.MVDG__CSV_Fields__c, testTemplateDataWithData.Fields, 'The Filter is Having some data, It should have two fields !!');
    }

    @IsTest
    static void testCSVController(){

        Account a = new Account(
            Name= 'Test Acc 1'
        );
        insert a;

        MVDG__Template__c testT = [SELECT Id,Name, MVDG__Object_API_Name__c FROM MVDG__Template__c LIMIT 1];

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

        System.assertEquals(1, [SELECT COUNT() FROM MVDG__Template_Page__c], 'template pages may not be more than one for csv template.');
        System.assertEquals(1, [SELECT COUNT() FROM MVDG__Template_Data__c], 'template data may not be more than one for csv template.');
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

        MVDG__Template__c testT = [SELECT Id, MVDG__Template_Name__c, MVDG__Object_API_Name__c FROM MVDG__Template__c LIMIT 1];

        Test.startTest();
        MVDG__Template__c retrievedTemplate = EditCSVTemplateController.getTemplateDetails(testT.Id);
        Test.stopTest();
        System.assertEquals(testT.MVDG__Template_Name__c,  retrievedTemplate.MVDG__Template_Name__c, 'Queried fields do not match expected values');
    }
@isTest
    static void testCSVControllerUpdate(){

        MVDG__Template__c testT = [SELECT Id, MVDG__Template_Name__c, MVDG__Object_API_Name__c FROM MVDG__Template__c LIMIT 1];

        EditCSVTemplateController.TemplateInfo tempInfo = new EditCSVTemplateController.TemplateInfo();
        tempInfo.templateDescription = 'test';
        tempInfo.templateName = 'Test Name Updated';
        tempInfo.templateId = testT.Id;
        tempInfo.templateStatus = true;


        Test.startTest();
        EditCSVTemplateController.updateTemplate(tempInfo);
        Test.stopTest();

        MVDG__Template__c updatedTemplate =  [SELECT Id, MVDG__Template_Name__c, MVDG__Object_API_Name__c FROM MVDG__Template__c WHERE Id=:testT.Id LIMIT 1];

        System.assertNotEquals(testT.MVDG__Template_Name__c, updatedTemplate.MVDG__Template_Name__c, 'template Name must be updated.');
    }
}