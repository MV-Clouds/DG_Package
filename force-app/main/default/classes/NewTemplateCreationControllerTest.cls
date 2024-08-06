@IsTest
public with sharing class NewTemplateCreationControllerTest {
    @IsTest
    public static void testNewTemplate(){
        NewTemplateCreationController.TemplateData testObj = new NewTemplateCreationController.TemplateData();
        testObj.templateName = 'Test Template';
        testObj.templateDescription = 'Test Description';
        testObj.sourceObject = 'Account';
        testObj.templateType = 'Simple Template';
        
        Test.startTest();
        
        List<NewTemplateCreationController.ObjectInfo> objects = NewTemplateCreationController.getObjects();

        List<String> types = NewTemplateCreationController.getTemplateTypes();

        NewTemplateCreationController.saveTemplate(testObj);

        Test.stopTest();


        Assert.isTrue(objects.size() > 0, 'There are no Objects Returned by the class!!!!');
        Assert.isTrue(types.contains('CSV Template'), 'There are more than 3 types of the Template !!!!');

        Template__c template = [SELECT Id, Template_Name__c FROM Template__c LIMIT 1];

        Assert.areEqual(testObj.templateName, template.Template_Name__c , 'The Template name is different than assigned!!');
        
        
    }

    @isTest
    static void testIsGoogleIntegrated() {
        Test.startTest();
            Boolean isIntegrated = NewTemplateCreationController.isGoogleIntegrated();
        Test.stopTest();
        System.assertNotequals(null, isIntegrated, 'true or false was expected');
    }
}