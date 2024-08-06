@isTest
public class CloneTemplateDataControllerTest {
    
    @testSetup
    static void setup() {
        // Insert sample data to be used in the test methods

        Template__c templateRecord = new Template__c();
        templateRecord.Template_Name__c = 'Test Template';
        templateRecord.Template_Type__c = 'Simple Template';
        templateRecord.Object_API_Name__c = 'Account';
        templateRecord.Template_Status__c = true;
        insert templateRecord;

        Template__c templateRecord2 = new Template__c();
        templateRecord2.Template_Name__c = 'Test Template';
        templateRecord2.Template_Type__c = 'CSV Template';
        templateRecord2.Object_API_Name__c = 'Account';
        templateRecord2.Template_Status__c = true;
        insert templateRecord2;

        Template_Page__c page = new Template_Page__c();
        page.Template__c = templateRecord.Id;
        page.Page_Number__c = 1;
        page.Page_Margin__c = '1;1;1;1';
        page.Page_Oriantation__c = 'portrait';
        page.Page_Size__c = 'a4';
        page.unit_of_page_configs__c = 'inch';
        insert page;

        Template_Page__c page2 = new Template_Page__c();
        page2.Template__c = templateRecord2.Id;
        page2.Page_Number__c = 1;
        page2.Page_Margin__c = '1;1;1;1';
        page2.Page_Oriantation__c = 'portrait';
        page2.Page_Size__c = 'a4';
        page2.unit_of_page_configs__c = 'inch';
        insert page2;

        Template_Data__c templateDataRecord = new Template_Data__c();
        templateDataRecord.Template__c = templateRecord.Id;
        templateDataRecord.Order_No_Simple__c =1;
        insert templateDataRecord;

        Template_Data__c templateDataRecord2 = new Template_Data__c();
        templateDataRecord2.Template__c = templateRecord2.Id;
        templateDataRecord2.Order_No_Simple__c =1;
        insert templateDataRecord2;
    }

    
    @isTest
    static void testCloneTempData_SimpleTemplate() {
        // Fetch the template record inserted in the test setup
        Template__c templateRecord = [SELECT Id, Template_Name__c, Description__c FROM Template__c WHERE Template_Type__c = 'Simple Template' LIMIT 1];
        
        // Create a JSON string for dataMap
        String jsonData = '{"templateType":"Simple Template","templateBody":"true","watermark":"true","header":"true","pageConfiguration":"true","footer":"true"}';
        
        
        // Call the method to be tested
        CloneTemplateDataController.newTempleatData result = CloneTemplateDataController.cloneTempData(
            templateRecord.Id,
            templateRecord.Template_Name__c,
            templateRecord.Description__c,
            jsonData
        );
        System.debug('->'+result);
        // Verify the cloned template data
        Template__c clonedTemplate = [SELECT Id, Template_Name__c, Description__c FROM Template__c WHERE Id = :result.tempId];
        System.assertEquals('Test Template', clonedTemplate.Template_Name__c);
    }
    
    @isTest
    static void testCloneTempData_CSVTemplate() {
        // Fetch the template record inserted in the test setup
        Template__c templateRecord = [SELECT Id FROM Template__c WHERE Template_Type__c=:'CSV Template' LIMIT 1];
        
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
        Template__c clonedTemplate = [SELECT Id, Template_Name__c, Description__c FROM Template__c WHERE Id = :result.tempId];
        System.assertEquals('ClonedTemplateName', clonedTemplate.Template_Name__c);
        System.assertEquals('ClonedTemplateDescription', clonedTemplate.Description__c);
        
        // Verify the cloned template data records
        List<Template_Data__c> clonedTemplateData = [SELECT Id FROM Template_Data__c WHERE Template__c = :result.tempId];
        System.assertNotEquals(0, clonedTemplateData.size());
    }

}