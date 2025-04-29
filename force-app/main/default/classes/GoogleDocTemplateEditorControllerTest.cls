@isTest
public class GoogleDocTemplateEditorControllerTest {
    @TestSetup
    static void makeData(){
        Google_Credentials__c authProvider = new Google_Credentials__c();
        authProvider.SetupOwnerId = UserInfo.getUserId();
        authProvider.ClientId__c = 'dummyClientId';
        authProvider.ClientSecret__c = 'dummyClientSecret';
        authProvider.access_token__c = 'dummyAccessToken';
        authProvider.refresh_token__c = 'dummyRefreshToken';
        authProvider.WorkingStatus__c = true;
        insert authProvider;

        MVDG__Template__c template = new MVDG__Template__c();
        template.MVDG__Template_Type__c = 'Google Doc Template';
        template.MVDG__Template_Name__c = 'Test Template';
        template.MVDG__Description__c = 'Test Template Description';
        template.MVDG__Template_Status__c = true;
        template.MVDG__Object_API_Name__c = 'Account';
        insert template;

        MVDG__Template_Data__c templateData = new MVDG__Template_Data__c();
        templateData.MVDG__Template__c = template.Id;
        templateData.MVDG__Google_Doc_Template_Id__c = 'dummyDocumentId';
        templateData.MVDG__Google_Doc_WebViewLink__c = 'https://docs.google.com/document/d/dummyDocumentId/edit?usp=drivesdk';
        templateData.MVDG__Order_No_Simple__c = 1;
        insert templateData;
    }
    
    @isTest
    public static void testAllMethods() {
        MVDG__Template__c temp = new MVDG__Template__c();
        temp = [SELECT Id FROM MVDG__Template__c];

        MVDG__Template_Data__c tempData = new MVDG__Template_Data__c();
        tempData = [SELECT Id FROM MVDG__Template_Data__c WHERE MVDG__Template__c = :temp.Id];

        Test.setMock(HttpCalloutMock.class, new TemplateEditerMock());
        Test.startTest();
        
        GoogleDocTemplateEditorController.createNewDocument();
        GoogleDocTemplateEditorController.getAllDocs();

        String endpoint = 'https://docs.googleapis.com/v1/documents';
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        GoogleDocTemplateEditorController.refreshAccessToken(Google_Credentials__c.getInstance(), request);

        GoogleDocTemplateEditorController.ResponseWrapper response = new GoogleDocTemplateEditorController.ResponseWrapper();
        response = GoogleDocTemplateEditorController.getAllData(temp.Id, 'Account');
        System.assertEquals('Account', response.objectLabel);
        
        GoogleDocTemplateEditorController.editTemplate(JSON.serialize(temp));
        GoogleDocTemplateEditorController.editTemplate(JSON.serialize(tempData));
        
        GoogleDocTemplateEditorController.saveTemplateData(temp.Id, 'googleDocId', 'webViewLink');
        GoogleDocTemplateEditorController.updateAuthProviderSettings();

        GoogleDocTemplateEditorController.responseList.put('first', new HttpResponse());
        GoogleDocTemplateEditorController.insertRestResponses();
        Test.stopTest();
    } 

    @IsTest
    static void testAllResponses(){

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NoResponseClass());
        String res = GoogleDocTemplateEditorController.createNewDocument();
        System.assertEquals(null, res);
        GoogleDocTemplateEditorController.getAllDocs();

        Test.stopTest();
    }

    @IsTest
    static void testAllResponses2(){
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NotFoundResponseClass());
        String res = GoogleDocTemplateEditorController.createNewDocument();
        System.assertEquals(null, res);
        GoogleDocTemplateEditorController.getAllDocs();
        Test.stopTest();
    }

    @isTest
    public static void testCatchBlocks() {

        Test.startTest();
        List<Google_Credentials__c> authprovider = new List<Google_Credentials__c>();
        authprovider.add(Google_Credentials__c.getInstance());
        GoogleDocTemplateEditorController.authProvider = authprovider;
        GoogleDocTemplateEditorController.updateAuthProviderSettings();
        String endpoint = 'https://docs.googleapis.com/v1/documents';
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        GoogleDocTemplateEditorController.refreshAccessToken(Google_Credentials__c.getInstance(), request);
        String res = GoogleDocTemplateEditorController.createNewDocument();
        System.assertEquals(null, res);
        GoogleDocTemplateEditorController.getAllDocs();


        delete authprovider;
        GoogleDocTemplateEditorController.getAllData('temp.Id', 'Account');
        test.stopTest();
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
            } else if (endpoint == 'https://docs.googleapis.com/v1/documents') {
                res.setBodyAsBlob(Blob.valueOf('{"kind":"drive#file","id":"dummyDocumentId","name":"dummyDocumentName","mimeType":"application/vnd.google-apps.document"}'));
                res.setStatusCode(200);
            } else if (endpoint.contains('https://www.googleapis.com/drive/v3/files')) {
                res.setBody('{"files": {"kind":"drive#file","id":"dummyDocumentId","name":"dummyDocumentName","mimeType":"application/vnd.google-apps.document"}}');
                res.setStatusCode(200);
            }
            return res;
        }
    }

    public class NoResponseClass implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(401);
            return res;
        }
    }
    
    public class NotFoundResponseClass implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(404);
            return res;
        }
    }
}