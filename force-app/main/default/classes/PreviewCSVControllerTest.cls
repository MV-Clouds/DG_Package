@isTest
public with sharing class PreviewCSVControllerTest {

    @isTest
    static void testFetchPreviewData() {
        Template__c template = new Template__c(
            Template_Name__c = 'test template',
            Template_Type__c = 'CSV Template',
            Object_API_Name__c = 'Account',
            Description__c = 'Test Description',
            Template_Status__c = true
        );
        insert template;

        Account a = new Account(
            Name= 'Test account'
        );
        insert a;

        Template_Page__c tp = new Template_Page__c(
            Page_Number__c =001,
            Template__c = template.Id
        );
        insert tp;
        Template_Data__c td= new Template_Data__c(
            Template__c = template.Id,
            Template_Page__c = tp.Id,
            CSV_Query__c = 'SELECT Id FROM Account',
            CSV_Fields__c = 'Id, Name'
        );
        insert td;


        Test.startTest();
        PreviewCSVController.PreviewDataWrapper result = PreviewCSVController.fetchPreviewData(template.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.records, 'Records should not be null');
        System.assertNotEquals(null, result.fields, 'Fields should not be null');
        System.assertNotEquals(null, result.templateName, 'TemplateName should not be null');
        System.assertNotEquals(null, result.templateObject, 'TemplateObject should not be null');
    }
}