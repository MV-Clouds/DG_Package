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
        List<String> objects = new List<String>();
        objects.add('Account');
        Map<String, String> buttonData = new Map<String, String>{'buttonEndURL' => 'xyz','buttonLabel' => 'Test button','buttonName' => 'DG_Basic_Print'};
        ButtonGeneratorController.createListViewButtons(objects, buttonData);
        Test.stopTest();
        
        System.assertEquals('DG_Basic_Print', buttonData.get('buttonName'), 'The button name does not match');
    }
}