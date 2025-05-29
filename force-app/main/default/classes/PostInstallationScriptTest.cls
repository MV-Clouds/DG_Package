@isTest
public class PostInstallationScriptTest { 
    @TestSetup
    static void setupTestData() { 
        PermissionSet ps = new PermissionSet(
            Name = 'DocGenius_Admin_Permissions',
            Label = 'DocGenius Admin Permissions'
        );
        insert ps;
 
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;
    }

    @IsTest
    static void testOnInstallAndExecuteMethod() { 
        Test.startTest();
 
        PostInstallationScript pis = new PostInstallationScript();
 
        Test.testInstall(pis, new Version(1, 0)); 
        SchedulableContext sc = null;
        pis.execute(sc);
 
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'DocGenius_Admin_Permissions' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        List<PermissionSetAssignment> psaList = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE AssigneeId = :testUser.Id AND PermissionSetId = :ps.Id
            WITH SECURITY_ENFORCED
        ];
 
        System.assertEquals(1, psaList.size(), 'Expected one PermissionSetAssignment to be created');
 
        List<WebLink> listViewButtons = [
            SELECT Name
            FROM WebLink
            WHERE PageOrSobjectType = 'Account' AND Name = 'DG_Basic_Print'
            WITH SECURITY_ENFORCED
        ];
        System.assertNotEquals(null, listViewButtons, 'WebLink query should return a non-null result');

        Test.stopTest();
    }

    @IsTest
    static void testUninstallMethod() {
        Test.startTest();
        PostInstallationScript pis = new PostInstallationScript();
 
        Test.testUninstall(pis);
        Test.stopTest();
    }
}