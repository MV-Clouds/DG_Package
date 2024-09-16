@isTest
public class EditCSVTemplateControllerTest {
    
    @TestSetup
    static void makeData(){
        MVDG__Template__c testTemplate = new MVDG__Template__c(
            MVDG__Description__c = 'Test Description',
            MVDG__Object_API_Name__c = 'Account',
            MVDG__Template_Name__c = 'Account Template',
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
        MVDG__Template__c testT = [SELECT Id, MVDG__Template_Name__c FROM MVDG__Template__c WHERE MVDG__Template_Name__c = 'Account Template' LIMIT 1];

        MVDG__Template_Data__c templateField= new MVDG__Template_Data__c(
            MVDG__Template__c = testT.Id,
            MVDG__CSV_Fields__c = 'Name,Id',
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
        EditCSVTemplateController.CombinedDataWrapper combinedData = EditCSVTemplateController.getCombinedData(testT.Id, 'Account');
        Test.stopTest();

        System.assertEquals(testT.MVDG__Template_Name__c, combinedData.template.MVDG__Template_Name__c, 'The template name should match!!');
    }

    @IsTest
    static void testCSVController(){

        Account a = new Account(
            Name= 'Test Acc 1'
        );
        insert a;

        MVDG__Template__c testT = [SELECT Id,Name, MVDG__Object_API_Name__c FROM MVDG__Template__c LIMIT 1];
        Map<String, String> testTemplateData = new Map<String,String> { 'templateId' => testT.Id, 'query' => 'SELECT Name,Id FROM Account LIMIT 1', 'maxLimit' => '10000', 'orders' => 'MasterRecordId<|IDG|>ASC<|SDG|>IsDeleted<|IDG|>ASC<|SDG|>Salutation<|IDG|>DESC', 'logic' => 'OR', 'listView' => null, 'filters' => 'FirstName<|IDG|>=<|IDG|>test<|IDG|>STRING', 'fields' => 'Id, Name'};

        Test.startTest();
        EditCSVTemplateController.saveTemplateFields(testTemplateData);
        testTemplateData.put('templateId', 'arg1');
        EditCSVTemplateController.saveTemplateFields(testTemplateData);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM MVDG__Template_Data__c], 'template data may not be more than one for csv template.');
    }

@isTest
    static void testCSVControllerUpdate(){

        MVDG__Template__c testT = [SELECT Id, MVDG__Template_Name__c, MVDG__Object_API_Name__c FROM MVDG__Template__c LIMIT 1];

        Map<String, String> tempInfo = new Map<String, String>{'templateDescription' => 'test','templateName' => 'Test Name Updated','templateId' => testT.Id,'templateStatus' => 'true'};
        Test.startTest();
        EditCSVTemplateController.updateTemplate(tempInfo);
        tempInfo.put('templateId', 'arg1');
        EditCSVTemplateController.updateTemplate(tempInfo);
        Test.stopTest();

        MVDG__Template__c updatedTemplate =  [SELECT Id, MVDG__Template_Name__c, MVDG__Object_API_Name__c FROM MVDG__Template__c WHERE Id=:testT.Id LIMIT 1];

        System.assertNotEquals(testT.MVDG__Template_Name__c, updatedTemplate.MVDG__Template_Name__c, 'template Name must be updated.');
    }
}