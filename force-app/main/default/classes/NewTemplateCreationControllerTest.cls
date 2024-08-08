@IsTest
public with sharing class NewTemplateCreationControllerTest {
    @IsTest
    public static void testNewTemplate(){
        Map<String, String> testObj = new Map<String, String>{'templateName' => 'Test Template','templateDescription' => 'Test Description','sourceObject' => 'Account','templateType' => 'Simple Template'};
        Test.startTest();
        
        List<NewTemplateCreationController.ObjectInfo> objects = NewTemplateCreationController.getObjects();

        List<String> types = NewTemplateCreationController.getTemplateTypes();

        NewTemplateCreationController.saveTemplate(testObj);

        Test.stopTest();


        System.assert(objects.size() > 0, 'There are no Objects Returned by the class!!!!');
        System.assert(types.size() > 0, 'There are no Types Returned by the class!!!!');

        MVDG__Template__c template = [SELECT Id, MVDG__Template_Name__c FROM MVDG__Template__c LIMIT 1];

        System.assertEquals(testObj.get('templateName'), template.MVDG__Template_Name__c , 'The Template name is different than assigned!!');
    }

    @isTest
    static void testIsGoogleIntegrated() {
        Test.startTest();
            Boolean isIntegrated = NewTemplateCreationController.isGoogleIntegrated();
        Test.stopTest();
        System.assertNotequals(null, isIntegrated, 'true or false was expected');
    }
}