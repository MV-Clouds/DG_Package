@isTest
public class DynamicFieldDisplayControllerTest {
    @TestSetup
    static void makeData(){
        Account testAccount = new Account(Name = 'Test Account');
        testAccount.BillingCity = 'Sydney';
        insert testAccount;
    }
    @isTest
    static void testDynamicFieldDisplayController() {
        Account testAccount = new Account();
        testAccount = [SELECT Id FROM Account];
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.setCurrentPage(Page.UserSessionIdPage);
        ApexPages.currentPage().getParameters().put('id', testAccount.Id);
        
        Test.startTest();
        DynamicFieldDisplayController controller = new DynamicFieldDisplayController();
        System.assertEquals(testAccount.Id, controller.recordId, 'ids does not match');
        System.assertEquals('Account', controller.objectName, 'Object name does not match');

        System.assertNotEquals(0, controller.fieldSections.size(), 'Field sections should not be empty.');
        Test.stopTest();
    }
    
    @IsTest
    static void testWrapperClasses(){
        
        Test.startTest();
        DynamicFieldDisplayController.ChildRelationshipInfo childRelationshipInfo = new DynamicFieldDisplayController.ChildRelationshipInfo();
        DynamicFieldDisplayController.RelatedList relatedList = new DynamicFieldDisplayController.RelatedList();

        Test.stopTest();
        
    }

    

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{ "size": 1, "totalSize": 1, "done": true, "queryLocator": null, "entityTypeName": "Account", "records": [ { "attributes": { "type_Z": "LayoutRecord", "url": "/services/data/vXX.X/tooling/sobjects/LayoutRecord/00N1I00000EXAMPLE" }, "Layout": { "attributes": { "type_Z": "Layout", "url": "/services/data/vXX.X/tooling/sobjects/Layout/00N1I00000EXAMPLE" }, "Name": "Account Layout" } } ] }');
            res.setStatusCode(200);
            return res;
        }
    }
}