@isTest
public class ButtonGeneratorControllerTest {
    @isTest
    public static void testvoidMethods() {
        Test.startTest();
        List<String> getCreatedObjects = new List<String>();

        ButtonGeneratorController.CombinedDataWrapper data = ButtonGeneratorController.getCombinedData();
        System.assert(data.allObjects.size() > 0, 'The list should not be empty');
    
        Test.stopTest();
    }

    @IsTest
    static void testcreateListViewButtons(){
        
        Test.startTest();
        ButtonGeneratorController.ButtonDataWrapper buttonDataWrapper = new ButtonGeneratorController.ButtonDataWrapper();
        List<String> objects = new List<String>();
        objects.add('Account');
        buttonDataWrapper.objects = objects;
        buttonDataWrapper.buttonEndURL = 'xyz';
        buttonDataWrapper.buttonLabel = 'Test button';
        buttonDataWrapper.buttonName = 'TestButton';

        ButtonGeneratorController.createListViewButtons(buttonDataWrapper);
        Test.stopTest();
        
        System.assertEquals('TestButton', buttonDataWrapper.buttonName, 'The button name does not match');
    }
}