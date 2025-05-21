@isTest
public class RelatedListControllerTest {
    @isTest
    static void testGetRelatedRecords() {
        // Create test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con1 = new Contact(FirstName = 'Test', LastName = 'Contact1', AccountId = acc.Id);
        Contact con2 = new Contact(FirstName = 'Test', LastName = 'Contact2', AccountId = acc.Id);
        insert new List<Contact>{con1, con2};

        Test.startTest();
        // Call the method with known relationship details
        List<SObject> relatedContacts = RelatedListController.getRelatedRecords(
            acc.Id,               // Parent Record ID
            'Account',            // Parent Object API Name
            'Contacts'            // Child Relationship Name (as per relationship API name)
        );
        Test.stopTest();

        // Assert that 2 related contacts are returned
        System.assertNotEquals(null, relatedContacts, 'Related records should not be null');
        System.assertEquals(2, relatedContacts.size(), 'Expected 2 related Contact records');
        
        for (SObject sObj : relatedContacts) {
            Contact c = (Contact)sObj;
            System.assertNotEquals(null, c.Id, 'Each related contact must have an Id');
        }
    }

    @isTest
    static void testWithInvalidRelationship() {
        Account acc = new Account(Name = 'Invalid Test');
        insert acc;

        Test.startTest();
        // Intentionally pass wrong relationship name to test exception handling
        List<SObject> result = RelatedListController.getRelatedRecords(acc.Id, 'Account', 'InvalidRelation');
        Test.stopTest();

        // Should return null due to exception
        System.assertEquals(null, result, 'Should return null for invalid relationship');
    }
}
