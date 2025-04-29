@isTest
public class GoogleDocPreviewTest {

    public class GetDocumentMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();
            if (endpoint == 'https://oauth2.googleapis.com/token') {
                // refresh token
                res.setStatusCode(200);
                res.setBody('{"access_token": "dummyNewAccessToken"}');
            } else if (endpoint == 'https://docs.googleapis.com/v1/documents/dummyDocumentId') {
                // get document
                res.setStatusCode(200);
                res.setBody('{ "title": "dummyTitle", "body": { "content": [ { "endIndex": 1, "sectionBreak": { "sectionStyle": { "columnSeparatorStyle": "NONE", "contentDirection": "LEFT_TO_RIGHT", "sectionType": "CONTINUOUS" } } }, { "startIndex": 1, "endIndex": 26, "paragraph": { "elements": [ { "startIndex": 1, "endIndex": 15, "textRun": { "content": "Account Name: ", "textStyle": {} } }, { "startIndex": 15, "endIndex": 26, "textRun": { "content": " {{#Name}}", "textStyle": { "bold": true } } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } }, { "startIndex": 26, "endIndex": 27, "paragraph": { "elements": [ { "startIndex": 26, "endIndex": 27, "textRun": { "content": "", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } }, { "startIndex": 27, "endIndex": 238, "table": { "rows": 3, "columns": 5, "tableRows": [ { "startIndex": 28, "endIndex": 80, "tableCells": [ { "startIndex": 29, "endIndex": 34, "content": [ { "startIndex": 30, "endIndex": 34, "paragraph": { "elements": [ { "startIndex": 30, "endIndex": 34, "textRun": { "content": "No.", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 34, "endIndex": 46, "content": [ { "startIndex": 35, "endIndex": 46, "paragraph": { "elements": [ { "startIndex": 35, "endIndex": 46, "textRun": { "content": "Account ID", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 46, "endIndex": 58, "content": [ { "startIndex": 47, "endIndex": 58, "paragraph": { "elements": [ { "startIndex": 47, "endIndex": 58, "textRun": { "content": "First Name", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 58, "endIndex": 69, "content": [ { "startIndex": 59, "endIndex": 69, "paragraph": { "elements": [ { "startIndex": 59, "endIndex": 69, "textRun": { "content": "Full Name", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 69, "endIndex": 80, "content": [ { "startIndex": 70, "endIndex": 80, "paragraph": { "elements": [ { "startIndex": 70, "endIndex": 80, "textRun": { "content": "Last Name", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} } ], "tableRowStyle": { "minRowHeight": { "magnitude": 23.25, "unit": "PT" } } }, { "startIndex": 80, "endIndex": 153, "tableCells": [ { "startIndex": 81, "endIndex": 95, "content": [ { "startIndex": 82, "endIndex": 95, "paragraph": { "elements": [ { "startIndex": 82, "endIndex": 95, "textRun": { "content": "{{No.Index}}", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 95, "endIndex": 111, "content": [ { "startIndex": 96, "endIndex": 111, "paragraph": { "elements": [ { "startIndex": 96, "endIndex": 111, "textRun": { "content": "{{!AccountId}}", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 111, "endIndex": 127, "content": [ { "startIndex": 112, "endIndex": 127, "paragraph": { "elements": [ { "startIndex": 112, "endIndex": 127, "textRun": { "content": "{{!FirstName}}", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 127, "endIndex": 138, "content": [ { "startIndex": 128, "endIndex": 138, "paragraph": { "elements": [ { "startIndex": 128, "endIndex": 138, "textRun": { "content": "{{!Name}}", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": { "rowSpan": 1 } }, { "startIndex": 138, "endIndex": 153, "content": [ { "startIndex": 139, "endIndex": 153, "paragraph": { "elements": [ { "startIndex": 139, "endIndex": 153, "textRun": { "content": "{{!LastName}}", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} } ], "tableRowStyle": { "minRowHeight": { "magnitude": 23.25, "unit": "PT" } } }, { "startIndex": 153, "endIndex": 237, "tableCells": [ { "startIndex": 154, "endIndex": 229, "content": [ { "startIndex": 155, "endIndex": 172, "paragraph": { "elements": [ { "startIndex": 155, "endIndex": 172, "textRun": { "content": "Object: Contact,", "textStyle": { "foregroundColor": { "color": { "rgbColor": { "red": 0.29803923, "green": 0.29803923, "blue": 0.29803923 } } } } } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } }, { "startIndex": 172, "endIndex": 229, "paragraph": { "elements": [ { "startIndex": 172, "endIndex": 229, "textRun": { "content": "$objApi:Contact$, $childRelation:Contacts$, $limit:20$, ", "textStyle": { "foregroundColor": { "color": { "rgbColor": { "red": 0.29803923, "green": 0.29803923, "blue": 0.29803923 } } } } } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 229, "endIndex": 231, "content": [ { "startIndex": 230, "endIndex": 231, "paragraph": { "elements": [ { "startIndex": 230, "endIndex": 231, "textRun": { "content": "", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 233, "endIndex": 235, "content": [ { "startIndex": 234, "endIndex": 235, "paragraph": { "elements": [ { "startIndex": 234, "endIndex": 235, "textRun": { "content": "", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 235, "endIndex": 237, "content": [ { "startIndex": 236, "endIndex": 237, "paragraph": { "elements": [ { "startIndex": 236, "endIndex": 237, "textRun": { "content": "", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} } ], "tableRowStyle": { "minRowHeight": { "magnitude": 36.75, "unit": "PT" } } } ], "tableStyle": { "tableColumnProperties": [ { "widthType": "FIXED_WIDTH", "width": { "magnitude": 74.25, "unit": "PT" } }, { "widthType": "FIXED_WIDTH", "width": { "magnitude": 84, "unit": "PT" } }, { "widthType": "FIXED_WIDTH", "width": { "magnitude": 84, "unit": "PT" } }, { "widthType": "FIXED_WIDTH", "width": { "magnitude": 61.5, "unit": "PT" } }, { "widthType": "FIXED_WIDTH", "width": { "magnitude": 82.5, "unit": "PT" } } ] } } }, { "startIndex": 238, "endIndex": 239, "paragraph": { "elements": [ { "startIndex": 238, "endIndex": 239, "textRun": { "content": "", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } } ] } }');
            } else if (endpoint == 'https://www.googleapis.com/drive/v3/files/dummyDocumentId/copy') {
                // copy document
                res.setStatusCode(200);
                res.setBody('{"id": "dummyDocumentId", "title": "dummyTitle", "body": { "content": [ { "endIndex": 1, "sectionBreak": { "sectionStyle": { "columnSeparatorStyle": "NONE", "contentDirection": "LEFT_TO_RIGHT", "sectionType": "CONTINUOUS" } } }, { "startIndex": 1, "endIndex": 26, "paragraph": { "elements": [ { "startIndex": 1, "endIndex": 15, "textRun": { "content": "Account Name: ", "textStyle": {} } }, { "startIndex": 15, "endIndex": 26, "textRun": { "content": " {{#Name}}", "textStyle": { "bold": true } } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } }, { "startIndex": 26, "endIndex": 27, "paragraph": { "elements": [ { "startIndex": 26, "endIndex": 27, "textRun": { "content": "", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } }, { "startIndex": 27, "endIndex": 238, "table": { "rows": 3, "columns": 5, "tableRows": [ { "startIndex": 28, "endIndex": 80, "tableCells": [ { "startIndex": 29, "endIndex": 34, "content": [ { "startIndex": 30, "endIndex": 34, "paragraph": { "elements": [ { "startIndex": 30, "endIndex": 34, "textRun": { "content": "No.", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 34, "endIndex": 46, "content": [ { "startIndex": 35, "endIndex": 46, "paragraph": { "elements": [ { "startIndex": 35, "endIndex": 46, "textRun": { "content": "Account ID", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 46, "endIndex": 58, "content": [ { "startIndex": 47, "endIndex": 58, "paragraph": { "elements": [ { "startIndex": 47, "endIndex": 58, "textRun": { "content": "First Name", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 58, "endIndex": 69, "content": [ { "startIndex": 59, "endIndex": 69, "paragraph": { "elements": [ { "startIndex": 59, "endIndex": 69, "textRun": { "content": "Full Name", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 69, "endIndex": 80, "content": [ { "startIndex": 70, "endIndex": 80, "paragraph": { "elements": [ { "startIndex": 70, "endIndex": 80, "textRun": { "content": "Last Name", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} } ], "tableRowStyle": { "minRowHeight": { "magnitude": 23.25, "unit": "PT" } } }, { "startIndex": 80, "endIndex": 153, "tableCells": [ { "startIndex": 81, "endIndex": 95, "content": [ { "startIndex": 82, "endIndex": 95, "paragraph": { "elements": [ { "startIndex": 82, "endIndex": 95, "textRun": { "content": "{{No.Index}}", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 95, "endIndex": 111, "content": [ { "startIndex": 96, "endIndex": 111, "paragraph": { "elements": [ { "startIndex": 96, "endIndex": 111, "textRun": { "content": "{{!AccountId}}", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 111, "endIndex": 127, "content": [ { "startIndex": 112, "endIndex": 127, "paragraph": { "elements": [ { "startIndex": 112, "endIndex": 127, "textRun": { "content": "{{!FirstName}}", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 127, "endIndex": 138, "content": [ { "startIndex": 128, "endIndex": 138, "paragraph": { "elements": [ { "startIndex": 128, "endIndex": 138, "textRun": { "content": "{{!Name}}", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": { "rowSpan": 1 } }, { "startIndex": 138, "endIndex": 153, "content": [ { "startIndex": 139, "endIndex": 153, "paragraph": { "elements": [ { "startIndex": 139, "endIndex": 153, "textRun": { "content": "{{!LastName}}", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} } ], "tableRowStyle": { "minRowHeight": { "magnitude": 23.25, "unit": "PT" } } }, { "startIndex": 153, "endIndex": 237, "tableCells": [ { "startIndex": 154, "endIndex": 229, "content": [ { "startIndex": 155, "endIndex": 172, "paragraph": { "elements": [ { "startIndex": 155, "endIndex": 172, "textRun": { "content": "Object: Contact,", "textStyle": { "foregroundColor": { "color": { "rgbColor": { "red": 0.29803923, "green": 0.29803923, "blue": 0.29803923 } } } } } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } }, { "startIndex": 172, "endIndex": 229, "paragraph": { "elements": [ { "startIndex": 172, "endIndex": 229, "textRun": { "content": "$objApi:Contact$, $childRelation:Contacts$, $limit:20$, ", "textStyle": { "foregroundColor": { "color": { "rgbColor": { "red": 0.29803923, "green": 0.29803923, "blue": 0.29803923 } } } } } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "alignment": "CENTER", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 229, "endIndex": 231, "content": [ { "startIndex": 230, "endIndex": 231, "paragraph": { "elements": [ { "startIndex": 230, "endIndex": 231, "textRun": { "content": "", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 233, "endIndex": 235, "content": [ { "startIndex": 234, "endIndex": 235, "paragraph": { "elements": [ { "startIndex": 234, "endIndex": 235, "textRun": { "content": "", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} }, { "startIndex": 235, "endIndex": 237, "content": [ { "startIndex": 236, "endIndex": 237, "paragraph": { "elements": [ { "startIndex": 236, "endIndex": 237, "textRun": { "content": "", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } } ], "tableCellStyle": {} } ], "tableRowStyle": { "minRowHeight": { "magnitude": 36.75, "unit": "PT" } } } ], "tableStyle": { "tableColumnProperties": [ { "widthType": "FIXED_WIDTH", "width": { "magnitude": 74.25, "unit": "PT" } }, { "widthType": "FIXED_WIDTH", "width": { "magnitude": 84, "unit": "PT" } }, { "widthType": "FIXED_WIDTH", "width": { "magnitude": 84, "unit": "PT" } }, { "widthType": "FIXED_WIDTH", "width": { "magnitude": 61.5, "unit": "PT" } }, { "widthType": "FIXED_WIDTH", "width": { "magnitude": 82.5, "unit": "PT" } } ] } } }, { "startIndex": 238, "endIndex": 239, "paragraph": { "elements": [ { "startIndex": 238, "endIndex": 239, "textRun": { "content": "", "textStyle": {} } } ], "paragraphStyle": { "namedStyleType": "NORMAL_TEXT", "direction": "LEFT_TO_RIGHT" } } } ] } }');
            } else if (endpoint == 'https://docs.googleapis.com/v1/documents/dummyDocumentId/:batchUpdate') {
                // update document
                res.setStatusCode(200);
                res.setBody('Successful');
            } else if (endpoint.contains('https://www.googleapis.com/drive/v3/files/dummyDocumentId/export')) {
                // get pdf
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/pdf');
                String blobBody = 'PDF blob';
                res.setBodyAsBlob(Blob.valueOf(blobBody));
            } else if (endpoint == 'https://www.googleapis.com/drive/v3/files/dummyDocumentId') {
                // delete document
                res.setStatusCode(204);
            } else {
                res.setStatusCode(404);
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
    
    @TestSetup
    static void createTemplate(){
        Google_Credentials__c authProvider = new Google_Credentials__c();
        authProvider.SetupOwnerId = UserInfo.getOrganizationId();
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

        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Phone = '+912345678901';
        insert acc;

        Contact con = new Contact();
        con.FirstName = 'Test Contact';
        con.LastName = 'Test Contact';
        con.AccountId = acc.Id;
        insert con;

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Signature-abcd';
        cv.PathOnClient = 'Signature-abcd.png';
        cv.VersionData = Blob.valueOf('a'.repeat(400));
        cv.FirstPublishLocationId = acc.Id;
        insert cv;
    }

    @IsTest
    static void testDoPreview(){
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new getDocumentMock());
        GoogleDocPreview.authProvider = Google_Credentials__c.getOrgDefaults();
        String res = GoogleDocPreview.doPreview('dummyDocumentId', '.pdf', new List<String>{'String'});
        System.assertEquals(EncodingUtil.base64Encode(Blob.valueOf('PDF blob')), res);

        GoogleDocPreview.doPreview('dummyDocumentId', '.pdf', new List<String>{'String'});
        Test.stopTest();
        
    }

    @IsTest
    static void testAllMethods(){
        MVDG__Template__c template = new MVDG__Template__c();
        template = [SELECT Id FROM MVDG__Template__c];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new getDocumentMock());
        GoogleDocPreview.authProvider = Google_Credentials__c.getOrgDefaults();
        String res = GoogleDocPreview.refreshAccessToken();
        System.assertEquals('dummyNewAccessToken', res);

        // update
        List<Object> requests = new List<Object>();
        requests.add('String');
        GoogleDocPreview.updateGoogleDoc('dummyDocumentId', requests);

        // getPDF
        GoogleDocPreview.getPDF('dummyDocumentId', '.pdf');
        GoogleDocPreview.getPDF('dummyDocumentId', '.docx');

        // delete
        GoogleDocPreview.deleteGoogleDoc('dummyDocumentId');

        // copy
        GoogleDocPreview.copyGoogleDoc(template.Id);

        Test.stopTest();   
    }

    @IsTest
    static void testAllMethods2(){
        MVDG__Template__c template = new MVDG__Template__c();
        template = [SELECT Id FROM MVDG__Template__c];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NotFoundResponseClass());
        GoogleDocPreview.authProvider = Google_Credentials__c.getOrgDefaults();
        String res = GoogleDocPreview.refreshAccessToken();
        System.assertEquals(null, res);

        // get
        GoogleDocPreview.getDocument('dummyDocumentId', template.Id);

        // update
        List<Object> requests = new List<Object>();
        requests.add('String');
        GoogleDocPreview.updateGoogleDoc('dummyDocumentId', requests);

        // getPDF
        GoogleDocPreview.getPDF('dummyDocumentId', '.pdf');
        GoogleDocPreview.getPDF('dummyDocumentId', '.docx');

        // delete
        GoogleDocPreview.deleteGoogleDoc('dummyDocumentId');

        // copy
        GoogleDocPreview.copyGoogleDoc(template.Id);

        Test.stopTest();   
    }

    @IsTest
    static void testAllMethods3(){
        MVDG__Template__c template = new MVDG__Template__c();
        template = [SELECT Id FROM MVDG__Template__c];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NoResponseClass());
        GoogleDocPreview.authProvider = Google_Credentials__c.getOrgDefaults();
        String res = GoogleDocPreview.refreshAccessToken();
        System.assertEquals(null, res);

        // get
        GoogleDocPreview.getDocument('dummyDocumentId', template.Id);

        // update
        List<Object> requests = new List<Object>();
        requests.add('String');
        GoogleDocPreview.updateGoogleDoc('dummyDocumentId', requests);

        // getPDF
        GoogleDocPreview.getPDF('dummyDocumentId', '.pdf');
        GoogleDocPreview.getPDF('dummyDocumentId', '.docx');

        // delete
        GoogleDocPreview.deleteGoogleDoc('dummyDocumentId');

        // copy
        GoogleDocPreview.copyGoogleDoc(template.Id);

        Test.stopTest();   
    }

    @IsTest
    static void catchAllMethods(){
        
        Test.startTest();
        test.setMock(HttpCalloutMock.class, new getDocumentMock());
        GoogleDocPreview.authProvider = Google_Credentials__c.getOrgDefaults();
        GoogleDocPreview.updateAuthProvider();

        GoogleDocPreview.getDocument('dummyDocumentId', 'dummyTemplateId');
        GoogleDocPreview.updateGoogleDoc('dummyDocumentId', new List<Object>());
        Blob res = GoogleDocPreview.getPDF('dummyDocumentId', '.pdf');
        System.assertEquals(null, res);

        GoogleDocPreview.deleteGoogleDoc('dummyDocumentId');
        GoogleDocPreview.copyGoogleDoc('dummyTemplateId');

        MVDG__Template__c template = new MVDG__Template__c();
        template = [SELECT Id FROM MVDG__Template__c];
        GoogleDocPreview.copyGoogleDoc(template.Id);
        Test.stopTest();
    }

    @IsTest
    static void testMapFieldValues(){
        Account acc = new Account();
        acc = [SELECT Id, Name, Phone FROM Account];
        
        Test.startTest();
        String queryObject = '[ { "fieldName": [ "{{!AccountId}}", "{{!FirstName}}", "{{!LastName}}", "{{!Name}}" ], "fieldArray": [ { "startIndex": 62, "fieldName": "{{!AccountId}}" }, { "startIndex": 78, "fieldName": "{{!FirstName}}" }, { "startIndex": 94, "fieldName": "{{!LastName}}" }, { "startIndex": 109, "fieldName": "{{!Name}}" } ], "objApi": "Contact", "childRelation": "Contacts", "queryLimit": "20", "filter": "WHERE AccountId != NULL ORDER BY FirstName ASC ", "tableNo": 1 }, { "fieldName": [ "{{!AccountId}}", "{{!FirstName}}", "{{!LastName}}", "{{!Name}}" ], "fieldArray": [ { "startIndex": 311, "fieldName": "{{!AccountId}}" }, { "startIndex": 327, "fieldName": "{{!FirstName}}" }, { "startIndex": 343, "fieldName": "{{!LastName}}" }, { "startIndex": 358, "fieldName": "{{!Name}}" } ], "objApi": "Contact", "childRelation": "Contacts", "filter": "WHERE AccountId != NULL ORDER BY FirstName ASC ", "tableNo": 2 }, { "objApi": "Account", "fieldName": [ "{{#Name}}" ] }, { "objApi": "General Fields", "fieldName": [ "{{Doc.Date.date}}" ] }, { "objApi": "Signature Image", "fieldName": [] } ]';
        GoogleDocPreview.mapFieldValues(queryObject, 'Account', acc.Id);
        List<Object> res = new List<Object>();
        res = GoogleDocPreview.mapFieldValues('Hello', 'Account', acc.Id);
        System.assertEquals(false, res.contains('Error'));
        Test.stopTest();
        
    }
}