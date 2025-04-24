@isTest
public class DeleteGoogleDocumentTest {
    @testSetup
    static void setup() {
        MVDG__Google_Credentials__c authProvider = new MVDG__Google_Credentials__c();
        authProvider.MVDG__access_token__c = 'mock_access_token';
        authProvider.MVDG__refresh_token__c = 'mock_refresh_token';
        authProvider.MVDG__ClientId__c = 'mock_client_id';
        authProvider.MVDG__ClientSecret__c = 'mock_client_secret';
        insert authProvider;
    }

    @isTest
    static void testExecute() {
        String templateId = 'mock_template_id';
        String documentId = 'mock_document_id';

        DeleteGoogleDocument deleteGoogleDoc = new DeleteGoogleDocument(templateId, documentId);

        String jobId = System.schedule('Test DeleteGoogleDocument', '0 0 0 1 1 ?', deleteGoogleDoc);

        System.assertNotEquals(null, jobId, 'The job was not scheduled');

        // Test.startTest();
        // Test.stopTest();

    }

    @isTest
    static void testDeleteDocument() {
        String googleDocId = 'mock_google_doc_id';

        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(204);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        DeleteGoogleDocument.deleteDocument(googleDocId);
        System.assertEquals(1, Limits.getAsyncCalls());
        Test.stopTest();

    }

    @isTest
    static void testRefreshAccessToken() {
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"access_token":"new_mock_access_token"}');

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        Test.startTest();
        DeleteGoogleDocument.authProvider = MVDG__Google_Credentials__c.getOrgDefaults();
        String newToken = DeleteGoogleDocument.refreshAccessToken();
        Test.stopTest();

        System.assertEquals('new_mock_access_token', newToken, 'Access token is invalid');

        // MVDG__Google_Credentials__c authProvider = MVDG__Google_Credentials__c.getInstaxnce();
        // System.assertEquals('new_mock_access_token', authProvider.MVDG__access_token__c);
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse response;

        public MockHttpResponseGenerator(HttpResponse response) {
            this.response = response;
        }

        public HTTPResponse respond(HTTPRequest req) {
            return response;
        }
    }
}