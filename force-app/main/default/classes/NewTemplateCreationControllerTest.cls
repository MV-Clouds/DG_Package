@IsTest
public with sharing class NewTemplateCreationControllerTest {
    @IsTest
    public static void testNewTemplate(){
        Map<String, String> testObj = new Map<String, String>{'templateName' => 'Test Template','templateDescription' => 'Test Description','sourceObject' => 'Account','templateType' => 'Simple Template'};
        Test.startTest();

        NewTemplateCreationController.CombinedData combinedData = NewTemplateCreationController.getCombinedData();

        NewTemplateCreationController.saveTemplate(testObj);
        testObj.put('templateType', 'test');
        NewTemplateCreationController.saveTemplate(testObj);

        Test.stopTest();

        System.assert(combinedData.templateTypes.size() > 0, 'There are no Types Returned by the class!!!!');

        MVDG__Template__c template = [SELECT Id, MVDG__Template_Name__c FROM MVDG__Template__c LIMIT 1];

        System.assertEquals(testObj.get('templateName'), template.MVDG__Template_Name__c , 'The Template name is different than assigned!!');
    }
}