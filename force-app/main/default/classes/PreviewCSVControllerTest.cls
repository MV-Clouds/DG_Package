@isTest
public with sharing class PreviewCSVControllerTest {

    @isTest
    static void testFetchPreviewData() {
        MVDG__Template__c template = new MVDG__Template__c(
            MVDG__Template_Name__c = 'test template',
            MVDG__Template_Type__c = 'CSV Template',
            MVDG__Object_API_Name__c = 'Account',
            MVDG__Description__c = 'Test Description',
            MVDG__Template_Status__c = true
        );
        insert template;

        Account a = new Account(
            Name= 'Test account'
        );
        insert a;

        MVDG__Template_Data__c td= new MVDG__Template_Data__c(
            MVDG__Template__c = template.Id,
            MVDG__CSV_Query__c = 'SELECT Id FROM Account LIMIT 12',
            MVDG__CSV_Fields__c = 'Id, Name'
        );
        insert td;


        Test.startTest();
        PreviewCSVController.PreviewDataWrapper result = PreviewCSVController.fetchPreviewData(template.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.records, 'Records should not be null');
        System.assertNotEquals(null, result.templateData.MVDG__CSV_Fields__c, 'Fields should not be null');
        System.assertNotEquals(null, result.templateData.MVDG__Template__r.MVDG__Template_Name__c, 'TemplateName should not be null');
        System.assertNotEquals(null, result.templateData.MVDG__Template__r.MVDG__Object_API_Name__c, 'TemplateObject should not be null');
    }
}