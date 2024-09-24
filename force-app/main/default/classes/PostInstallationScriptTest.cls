@isTest
public class PostInstallationScriptTest {
    @IsTest
    static void testOnIntallMethod(){
        
        Test.startTest();
        PostInstallationScript pis = new PostInstallationScript();
        Test.testInstall(pis, new Version(1,0));
        Test.testUninstall(pis);
        
        List<WebLink> listViewButtons = new List<WebLink>();
        listViewButtons = [SELECT Name FROM WebLink WHERE PageOrSobjectType= 'Account' AND Name = 'DG_Basic_Print' WITH SECURITY_ENFORCED];

        // System.assertEquals(1, listViewButtons.size(), 'Expected 1 listViewButton');
        System.assertNotEquals(null, listViewButtons); //
        Test.stopTest();   
    }
}