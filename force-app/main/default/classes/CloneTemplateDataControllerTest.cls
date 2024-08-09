@isTest
public class CloneTemplateDataControllerTest {
    
    @testSetup
    static void setup() {
        // Insert sample data to be used in the test methods

        // Simple Template setup
        MVDG__Template__c templateRecord = new MVDG__Template__c();
        templateRecord.MVDG__Template_Name__c = 'Test Simple Template';
        templateRecord.MVDG__Template_Type__c = 'Simple Template';
        templateRecord.MVDG__Object_API_Name__c = 'Account';
        templateRecord.MVDG__Template_Status__c = true;
        insert templateRecord;

        // CSV Template setup
        MVDG__Template__c templateRecord2 = new MVDG__Template__c();
        templateRecord2.MVDG__Template_Name__c = 'Test CSV Template';
        templateRecord2.MVDG__Template_Type__c = 'CSV Template';
        templateRecord2.MVDG__Object_API_Name__c = 'Account';
        templateRecord2.MVDG__Template_Status__c = true;
        insert templateRecord2;

        // Template Pages
        MVDG__Template_Page__c page = new MVDG__Template_Page__c();
        page.MVDG__Template__c = templateRecord.Id;
        page.MVDG__Page_Number__c = 1;
        page.MVDG__Page_Margin__c = '1;1;1;1';
        page.MVDG__Page_Orientation__c = 'portrait';
        page.MVDG__Page_Size__c = 'a4';
        page.MVDG__Unit_of_Page_Configs__c = 'inch';
        insert page;

        MVDG__Template_Page__c page2 = new MVDG__Template_Page__c();
        page2.MVDG__Template__c = templateRecord2.Id;
        page2.MVDG__Page_Number__c = 1;
        page2.MVDG__Page_Margin__c = '1;1;1;1';
        page2.MVDG__Page_Orientation__c = 'portrait';
        page2.MVDG__Page_Size__c = 'a4';
        page2.MVDG__Unit_of_Page_Configs__c = 'inch';
        insert page2;

        // Template Data
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
        System.debug('templateRecord *** : '+templateRecord);
        
        // Create a JSON string for dataMap
        String jsonData = '{"templateType":"Simple Template","templateBody":"true","header":"true","pageConfiguration":"true","footer":"true"}';
        
        // Call the method to be tested
        CloneTemplateDataController.newTempleatData result = CloneTemplateDataController.cloneTempData(
            templateRecord.Id,
            templateRecord.MVDG__Template_Name__c,
            templateRecord.MVDG__Description__c,
            jsonData
        );
        
        // Verify the cloned template data
        MVDG__Template__c clonedTemplate = [SELECT Id, MVDG__Template_Name__c, MVDG__Description__c FROM MVDG__Template__c WHERE Id = :result.tempId];
        System.assertEquals(templateRecord.MVDG__Template_Name__c, clonedTemplate.MVDG__Template_Name__c);
        System.assertNotEquals(templateRecord.Id, clonedTemplate.Id, 'Cloned template should have a different ID');
        
        // Verify the cloned template page data
        List<MVDG__Template_Page__c> clonedTemplatePages = [SELECT Id FROM MVDG__Template_Page__c WHERE MVDG__Template__c = :result.tempId];
        System.assertEquals(1, clonedTemplatePages.size(), 'One page should be cloned');
    }
    
    @isTest
    static void testCloneTempData_CSVTemplate() {
        // Fetch the template record inserted in the test setup
        MVDG__Template__c templateRecord = [SELECT Id FROM MVDG__Template__c WHERE MVDG__Template_Type__c = 'CSV Template' LIMIT 1];
        System.debug('templateRecord *** : '+templateRecord);
        
        // Create a JSON string for dataMap
        String jsonData = '{"templateType":"CSV Template","newSelectedFields":"true","newFieldsFilters":"true","newFieldOrderBy":"true","newFieldLimit":"true"}';
        
        // Call the method to be tested
        CloneTemplateDataController.newTempleatData result = CloneTemplateDataController.cloneTempData(
            templateRecord.Id,
            'Cloned CSV Template Name',
            'Cloned CSV Template Description',
            jsonData
        );
        
        // Verify the cloned template data
        MVDG__Template__c clonedTemplate = [SELECT Id, MVDG__Template_Name__c, MVDG__Description__c FROM MVDG__Template__c WHERE Id = :result.tempId];
        System.assertEquals('Cloned CSV Template Name', clonedTemplate.MVDG__Template_Name__c);
        System.assertEquals('Cloned CSV Template Description', clonedTemplate.MVDG__Description__c);
        
        // Verify the cloned template data records
        List<MVDG__Template_Data__c> clonedTemplateData = [SELECT Id FROM MVDG__Template_Data__c WHERE MVDG__Template__c = :result.tempId];
        System.assertNotEquals(0, clonedTemplateData.size(), 'Template data records should be cloned');
    }
}
