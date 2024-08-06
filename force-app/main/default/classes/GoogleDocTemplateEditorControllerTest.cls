@isTest
public class GoogleDocTemplateEditorControllerTest {
    @TestSetup
    static void makeData(){
        AuthProviderSettings__c authProvider = new AuthProviderSettings__c();
        authProvider.SetupOwnerId = UserInfo.getUserId();
        authProvider.ClientId__c = 'dummyClientId';
        authProvider.ClientSecret__c = 'dummyClientSecret';
        authProvider.access_token__c = 'dummyAccessToken';
        authProvider.refresh_token__c = 'dummyRefreshToken';
        insert authProvider;

        Template__c template = new Template__c();
        template.Template_Type__c = 'Google Doc Template';
        template.Template_Name__c = 'Test Template';
        template.Description__c = 'Test Template Description';
        template.Template_Status__c = true;
        template.Object_API_Name__c = 'Account';
        insert template;

        Template_Data__c templateData = new Template_Data__c();
        templateData.Template__c = template.Id;
        templateData.Google_Doc_Template_Id__c = 'dummyDocumentId';
        templateData.Google_Doc_WebViewLink__c = 'https://docs.google.com/document/d/dummyDocumentId/edit?usp=drivesdk';
        templateData.Order_No_Simple__c = 1;
        insert templateData;

        // Template_Data__c templateData2 = new Template_Data__c();
        // templateData2.Template__c = template.Id;
        // templateData2.Google_Doc_Template_Id__c = 'dummyDocumentId2';
        // templateData2.Google_Doc_WebViewLink__c = 'https://docs.google.com/document/d/dummyDocumentId2/edit?usp=drivesdk';
        // templateData2.Order_No_Simple__c = 2;
        // insert templateData2;
    }
    
    @isTest
    public static void testAllMethods() {
        Template__c temp = new Template__c();
        temp = [SELECT Id FROM Template__c];

        Template_Data__c tempData = new Template_Data__c();
        tempData = [SELECT Id FROM Template_Data__c WHERE Template__c = :temp.Id];

        Test.setMock(HttpCalloutMock.class, new TemplateEditerMock());
        Test.startTest();
        
        GoogleDocTemplateEditorController.getAllData(temp.Id, 'Account');
        googleDocTemplateEditorController.editTemplate(JSON.serialize(tempData));
        
        GoogleDocTemplateEditorController.saveTemplateData(temp.Id, 'googleDocId', 'webViewLink', 'documentName');

        Test.stopTest();

        GoogleDocTemplateEditorController googleDocTemplateEditorController = new GoogleDocTemplateEditorController();
    }

    public class TemplateEditerMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            String param1 = EncodingUtil.urlEncode('?q=(mimeType= "application/vnd.openxmlformats-officedocument.wordprocessingml.document" or mimeType= "application/vnd.google-apps.document") and (trashed=false)', 'UTF-8');
            String param2 = EncodingUtil.urlEncode('&fields=(mimeType= "files(id,name,webViewLink,createdTime,modifiedTime,size)', 'UTF-8');
            if (endpoint == 'https://oauth2.googleapis.com/token') {
                res.setBody('{"access_token":"dummyAccessToken","token_type":"Bearer","expires_in":3600,"refresh_token":"dummyRefreshToken","scope":"https://www.googleapis.com/authdrive","id_token":"dummyIdToken"}');
                res.setStatusCode(200);
            } else if (endpoint == 'https://www.googleapis.com/drive/v3/files/dummyDocumentId2/export') {
                res.setBodyAsBlob(Blob.valueOf('{"kind":"drive#file","id":"dummyDocumentId","name":"dummyDocumentName","mimeType":"application/vnd.google-apps.document"}'));
                res.setStatusCode(200);
            } else if (endpoint.contains('https://www.googleapis.com/drive/v3/files')) {
                res.setBody('{"files": {"kind":"drive#file","id":"dummyDocumentId","name":"dummyDocumentName","mimeType":"application/vnd.google-apps.document"}}');
                res.setStatusCode(401);
            }
            return res;
        }
    }
}