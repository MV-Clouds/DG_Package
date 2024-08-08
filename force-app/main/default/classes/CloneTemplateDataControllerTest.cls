@isTest
public class CloneTemplateDataControllerTest {
    
    @testSetup
    static void setup() {
        // Insert sample data to be used in the test methods

        MVDG__Template__c templateRecord = new MVDG__Template__c();
        templateRecord.MVDG__Template_Name__c = 'Test Template';
        templateRecord.MVDG__Template_Type__c = 'Simple Template';
        templateRecord.MVDG__Object_API_Name__c = 'Account';
        templateRecord.MVDG__Template_Status__c = true;
        insert templateRecord;

        MVDG__Template__c templateRecord2 = new MVDG__Template__c();
        templateRecord2.MVDG__Template_Name__c = 'Test Template';
        templateRecord2.MVDG__Template_Type__c = 'CSV Template';
        templateRecord2.MVDG__Object_API_Name__c = 'Account';
        templateRecord2.MVDG__Template_Status__c = true;
        insert templateRecord2;

        MVDG__Template_Page__c page = new MVDG__Template_Page__c();
        page.MVDG__Template__c = templateRecord.Id;
        page.MVDG__Page_Number__c = 1;
        page.MVDG__Page_Margin__c = '1;1;1;1';
        page.MVDG__Page_Oriantation__c = 'portrait';
        page.MVDG__Page_Size__c = 'a4';
        page.MVDG__unit_of_page_configs__c = 'inch';
        insert page;

        MVDG__Template_Page__c page2 = new MVDG__Template_Page__c();
        page2.MVDG__Template__c = templateRecord2.Id;
        page2.MVDG__Page_Number__c = 1;
        page2.MVDG__Page_Margin__c = '1;1;1;1';
        page2.MVDG__Page_Oriantation__c = 'portrait';
        page2.MVDG__Page_Size__c = 'a4';
        page2.MVDG__unit_of_page_configs__c = 'inch';
        insert page2;

        MVDG__Template_Data__c templateDataRecord = new MVDG__Template_Data__c();
        templateDataRecord.MVDG__Template__c = templateRecord.Id;
        templateDataRecord.MVDG__Order_No_Simple__c = 1;
        insert templateDataRecord;

        MVDG__Template_Data__c templateDataRecord2 = new MVDG__Template_Data__c();
        templateDataRecord2.MVDG__Template__c = templateRecord2.Id;
        templateDataRecord2.MVDG__Order_No_Simple__c = 1;
        insert templateDataRecord2;
    }

    @isTest
    static void testCloneTempData_SimpleTemplate() {
        // Fetch the template record inserted in the test setup
        MVDG__Template__c templateRecord = [SELECT Id, MVDG__Template_Name__c, MVDG__Description__c FROM MVDG__Template__c WHERE MVDG__Template_Type__c = 'Simple Template' LIMIT 1];
        
        // Create a JSON string for dataMap
        String jsonData = '{"templateType":"Simple Template","templateBody":"true","watermark":"true","header":"true","pageConfiguration":"true","footer":"true"}';
        
        // Call the method to be tested
        CloneTemplateDataController.newTempleatData result = CloneTemplateDataController.cloneTempData(
            templateRecord.Id,
            templateRecord.MVDG__Template_Name__c,
            templateRecord.MVDG__Description__c,
            jsonData
        );
        System.debug('->' + result);
        // Verify the cloned template data
        MVDG__Template__c clonedTemplate = [SELECT Id, MVDG__Template_Name__c, MVDG__Description__c FROM MVDG__Template__c WHERE Id = :result.tempId];
        System.assertEquals('Test Template', clonedTemplate.MVDG__Template_Name__c);
    }
    
    @isTest
    static void testCloneTempData_CSVTemplate() {
        // Fetch the template record inserted in the test setup
        MVDG__Template__c templateRecord = [SELECT Id FROM MVDG__Template__c WHERE MVDG__Template_Type__c = 'CSV Template' LIMIT 1];
        
        // Create a JSON string for dataMap
        String jsonData = '{"templateType":"CSV Template","newSelectedFields":"true","newFieldsFilters":"true","newFieldOrderBy":"true","newFieldLimit":"true"}';
        
        // Call the method to be tested
        CloneTemplateDataController.newTempleatData result = CloneTemplateDataController.cloneTempData(
            templateRecord.Id,
            'ClonedTemplateName',
            'ClonedTemplateDescription',
            jsonData
        );
        
        // Verify the cloned template data
        MVDG__Template__c clonedTemplate = [SELECT Id, MVDG__Template_Name__c, MVDG__Description__c FROM MVDG__Template__c WHERE Id = :result.tempId];
        System.assertEquals('ClonedTemplateName', clonedTemplate.MVDG__Template_Name__c);
        System.assertEquals('ClonedTemplateDescription', clonedTemplate.MVDG__Description__c);
        
        // Verify the cloned template data records
        List<MVDG__Template_Data__c> clonedTemplateData = [SELECT Id FROM MVDG__Template_Data__c WHERE MVDG__Template__c = :result.tempId];
        System.assertNotEquals(0, clonedTemplateData.size());
    }
}