global with sharing class GoogleDriveUploader implements Database.Batchable < SObject > , Database.AllowsCallouts{

    global string contentVersionId;
    global static string googleDriveAccessToken;
    global static string googleFileName;


    global GoogleDriveUploader(Id cvid) {
        this.contentVersionId = cvid;
    }

    

    global Database.QueryLocator start(Database.BatchableContext bC) {
        return Database.getQueryLocator([
            SELECT Id, VersionData, Title, ContentSize, FileExtension
            FROM ContentVersion
            WHERE Id =: contentVersionId
        ]);
    }


    global void execute(Database.BatchableContext bC, List < ContentVersion > scope) {
        for (ContentVersion cv: scope) {
            try {
                String fileName = cv.Title;
                googleFileName = cv.Title+'.'+cv.fileExtension;
                String acctoken = getToken();
                Integer fileSize = cv.ContentSize;
                String contentType = contentType(cv.FileExtension);
                System.debug('--------' + contentType);
                Integer fileSizeEncoded = getLengthOfFile(cv.VersionData);
                if(acctoken != null){
                    googleDriveAccessToken = acctoken;

                    Integer maxSize = 5 * 1024 * 1024;
                    if (Test.isRunningTest()) {
                        maxSize = 800;
                    } 
                    if (fileSize < maxSize) { // 5 MB threshold
                        System.debug('Uploading small file directly to googledrive');
                        uploadToGoogleDrive(cv, fileName, contentType);
                    } else {
                        System.debug('Uploading large file in chunks to googledrive');
                        uploadLargeFileInChunks(cv, fileSizeEncoded, contentType);
                    }
                }
            } catch (System.LimitException e) {
                emailUser('File size too large. Try uploading file with smaller size.\n\n Or Download it and then upload file manually.');
                System.debug('Error during Dropbox file upload: heap size issue' + e.getMessage());
            }
        }
    }



    global void finish(Database.BatchableContext bC) {
        System.debug('GoogleDrive file upload batch finished');
    }

    global static String getToken(){
        List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();
            System.debug('This is client id'+mdata[0].MVDG__CID__c);
            System.debug('This is client secret'+mdata[0].MVDG__CSEC__c);
        AuthProviderSettings__c settings = AuthProviderSettings__c.getOrgDefaults();
        String endpoint = 'https://oauth2.googleapis.com/token';
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody('refresh_token=' + settings.refresh_token__c +
                        '&client_id=' + mdata[0].MVDG__CID__c +
                        '&client_secret=' + mdata[0].MVDG__CSEC__c +
                        '&grant_type=refresh_token');

        Http http = new Http();
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String newToken = (String) jsonResponse.get('access_token');
            return newToken;
        }
        else{
            Response_Handler.store_Callout_Response(response, 'GoogleDriveUploader', 'getToken');
            mailMessage(response.getStatusCode());
        }
        return null;
    }

    @AuraEnabled
    public static Boolean uploadToGoogleDrive(ContentVersion content, String fileName, String contentType) {

        if (content != null) {
            MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
            HttpRequest req = createGoogleDriveRequest(content, settings);

            HttpResponse resp = sendHttpRequest(req);
            
            if (resp.getStatusCode() == 200) {
                return true;
            } else {
                Response_Handler.store_Callout_Response(resp, 'GoogleDriveUploader', 'uploadToGoogleDrive');
                mailMessage(resp.getStatusCode());
                return false; // Retry after token refresh
            }
        }
        
        
        return false;
    }

    private static HttpRequest createGoogleDriveRequest(ContentVersion content, MVDG__AuthProviderSettings__c settings) {
        HttpRequest req = new HttpRequest();
        String fileN = content.Title;
        String fileExtension = content.FileExtension;
        String contentType = content.FileExtension;
        String body = createMultipartRequestBody(content);
        
        req.setEndpoint('https://www.googleapis.com/upload/drive/v2/files?uploadType=multipart');
        req.setHeader('Authorization', 'Bearer ' + googleDriveAccessToken);
        req.setHeader('Content-Type', 'multipart/related; boundary=foo_bar_baz');
        req.setHeader('Content-Length', String.valueOf(Blob.valueOf(body).size()));
        req.setMethod('POST');
        req.setBodyAsBlob(content.VersionData);
        req.setBody(body);

        return req;
    }

    private static String createMultipartRequestBody(ContentVersion content) {
        String fileN = content.Title;
        String fileExtension = content.FileExtension;
        String contentType = content.FileExtension;
        String body = '--foo_bar_baz\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n {"title": "' + fileN + '", "mimeType": "'+contentType(contentType)+'"}\r\n\r\n--foo_bar_baz\r\nContent-Transfer-Encoding: base64\r\nContent-Type: "Image/' + contentType(contentType) + '"\r\n\r\n' + EncodingUtil.base64Encode(content.VersionData) + '\r\n--foo_bar_baz--';
        return body;
    }

    private static HttpResponse sendHttpRequest(HttpRequest req) {
        Http h = new Http();
        req.setTimeout(60000);
        return h.send(req);
    }

    private static void uploadLargeFileInChunks(ContentVersion contentVersion, Integer fileSize, String fileExtension) {
        String result = initiateUploadSession(fileExtension, contentVersion);
        if (result != 'failure') {
            System.debug('Initiated successfully');
            Decimal filesizedec = Decimal.valueOf(fileSize);
            Integer offset;


            Integer chunkSize = 2097152; // 9 MB chunks
            Integer totalChunks = Integer.valueOf(Math.ceil(filesizedec.divide(chunkSize, 3)));


            for (Integer i = 0; i < totalChunks; i++) {
                // System.debug(Limits.getHeapSize());
                Integer start = i * chunkSize;
                Integer ending = Math.min((i + 1) * 1572864 - 1, Integer.valueOf(contentVersion.VersionData.size()) - 1);
                System.debug('Chunk Start Byte: ' + start);
                // System.debug('Chunk End Byte: ' + ending);
                // System.debug('file size-->' + fileSize);
                Blob chunkBlob = getFileData(contentVersion.VersionData, start, chunkSize);
                offset = Integer.valueOf(Math.floor(start / 1.3333333333));
                if (start != 0) {
                    start = start - (i * 524288);
                }
                System.debug('Chunk Offset: ' + offset);
                ChunkDetails chunkDetail = new ChunkDetails();
                chunkDetail.chunk = chunkBlob;
                chunkDetail.start = start;
                chunkDetail.ending = ending;
                chunkDetail.offset = offset;
                chunkDetail.fileExtension = fileExtension;
                chunkDetail.fileSize = contentVersion.VersionData.size();
                chunkDetail.result = result;
                uploadChunk(chunkDetail);
                // System.debug('Uploaded chunk ' + (i + 1) + '/' + totalChunks + ': Start Byte: ' + start + ', End Byte: ' + ending + ', Offset: ' + offset);
                // System.debug(Limits.getHeapSize());
                chunkBlob = null;
                System.debug(Limits.getHeapSize());
            }
        }

    }

    public static void mailMessage(Integer code){
        if (code == 400) {
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have noticed an issue while attempting to upload the file ' + googleFileName + ' to Google Drive.\n\n' +
                   'To resolve this issue, please ensure that your credentials are correct. If the problem persists, try the following steps:\n\n' +
                   '1. Remove the existing Google Drive connection.\n' +
                   '2. Reconnect to Google Drive.\n\n' +
                   'These steps should help resolve the issue. If you continue to experience difficulties, please feel free to contact our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 401) {
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have noticed an issue while attempting to upload the file ' + googleFileName + ' to Google Drive.\n\n' +
                   'To resolve this issue, please follow these steps to reconnect:\n\n' +
                   '1. Remove the existing Google Drive connection.\n' +
                   '2. Reconnect to Google Drive.\n\n' +
                   'These steps should help re-establish the connection. If you continue to experience difficulties, please don\'t hesitate to reach out to our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 403){
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We encountered an issue while attempting to upload the file ' + googleFileName + ' to Google Drive. ' +
                   'It appears that you do not have the necessary permissions to complete this upload.\n\n' +
                   'To resolve this issue, please check the following:\n\n' +
                   '1. Ensure that you have the correct permissions to upload files to the specified Google Drive folder.\n' +
                   '2. Verify that your Google Drive account has the appropriate access rights.\n\n' +
                   'If you continue to experience difficulties, please don\'t hesitate to reach out to our support team for further assistance.\n\n' +
                   'Thank you for your attention to this matter.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 404){
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have encountered a connection error (404 - File Not Found) while attempting to access your Google Drive.\n\n' +
                   'This error indicates that the file or resource you are trying to access may not exist or could not be found. To resolve this issue, please try the following steps:\n\n' +
                   '1. Verify that the file or resource exists in your Google Drive.\n' +
                   '2. Ensure that the file\'s name and path are correct.\n' +
                   '3. Check that you have the necessary permissions to access the file.\n\n' +
                   'If the problem persists after following these steps, please feel free to contact our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 500){
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have encountered a server error (500 - Internal Server Error) while attempting to upload your file to Google Drive. This error typically indicates a problem with our server or the service.\n\n' +
                   'To resolve this issue, please try the following:\n\n' +
                   '1. Wait for a few minutes and try uploading the file again.\n' +
                   '2. If the issue persists, it may be due to temporary server problems on google\'s end.\n\n' +
                   'If the problem persists after following these steps, please feel free to contact our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else {
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have encountered error with code: '+ code + 'while attempting to upload your file to Google Drive. This error typically indicates a problem with our server or the service.\n\n' +
                   'To resolve this issue, please try the following:\n\n' +
                   '1. Remove the existing Google Drive connection.\n' +
                   '2. Reconnect to Google Drive.\n\n' +
                   'If the problem persists after following these steps, please feel free to contact our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
    }

    public static string initiateUploadSession(String contentType, ContentVersion cv) {
        MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://www.googleapis.com/upload/drive/v2/files?uploadType=resumable');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + googleDriveAccessToken);
        req.setHeader('accept', '*/*');
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        String body = '{"title":"' + cv.Title + '", "mimeType":"' + contentType + '"}';
        req.setBody(body);


        Http http = new Http();
        HttpResponse res = http.send(req);


        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            System.debug(res.getHeader('Location'));
            return (String) res.getHeader('Location');
        } else {
            Response_Handler.store_Callout_Response(res, 'GoogleDriveUploader', 'initiateUploadSession');
            mailMessage(res.getStatusCode());
            System.debug('Error initiating upload session: ' + res.getStatusCode() + res.getHeader('Location'));
            return 'failure';
        }
    }


    private static void uploadChunk(ChunkDetails parameters) {
            if( parameters.result != null){
                
            String contentRange = 'bytes ' + parameters.start + '-' + parameters.ending + '/' + parameters.fileSize;

            // System.debug('upload url' + result);
            MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
            // System.debug('Content-Length' + String.valueof(chunk.size()));
            // System.debug('Content-Range' + contentRange);
            HttpRequest req2 = new HttpRequest();
            req2.setEndpoint(parameters.result);
            req2.setMethod('PUT');
            req2.setHeader('Content-Range', contentRange);
            req2.setHeader('Content-Length', String.valueof(parameters.chunk.size()));
            req2.setHeader('Content-Type', 'application/octet-stream');
            req2.setHeader('accept', '*/*');
            req2.setHeader('Connection', 'keep-alive');
            req2.setBodyAsBlob(parameters.chunk);

            Http http = new Http();
            HttpResponse res = http.send(req2);
            // System.debug('getting status code while uploading chunk-->' + res.getStatusCode());


            if (res.getStatusCode() == 200 || res.getStatusCode() == 201 || res.getStatusCode() == 202 || res.getStatusCode() == 308) {
                System.debug('Everything was success' + res.getStatusCode() + res.getBody() + res.getHeader('Range'));
            } else {
                Response_Handler.store_Callout_Response(res, 'GoogleDriveUploader', 'uploadChunk');
                mailMessage(res.getStatusCode());
            }
        }
    }

    private static Blob getFileData(Blob versionDataBlob, Integer chunkStart, Integer chunkSize) {
        // System.debug('Error -->' + EncodingUtil.base64Decode(encodingUtilMethod(versionDataBlob, chunkStart, chunkSize)));
        return EncodingUtil.base64Decode(encodingUtilMethod(versionDataBlob, chunkStart, chunkSize));
    }


    public static String encodingUtilMethod(Blob versionDataBlob, Integer chunkStart, Integer chunkSize) {
        return EncodingUtil.base64Encode(versionDataBlob).mid(chunkStart, chunkSize);
    }


    public static Integer getLengthOfFile(Blob versionDataBlob) {
        return EncodingUtil.base64Encode(versionDataBlob).length();
    }

    @AuraEnabled
    public static void emailUser(String message) {
        if(Schema.sObjectType.User.fields.Email.isAccessible()){
        User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String subject = 'Issue in uploading file to google drive';
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { currentUser.Email });
        mail.setSubject(subject);
        mail.setPlainTextBody(message);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    public static string contentType(string fileType) {
        switch on fileType.toLowerCase() {
            when 'docx' {
                return 'application/vnd.google-apps.file';
            }
            when 'csv' {
                return 'text/csv';
            }
            when 'png' {
                return 'image/png';
            }
            when 'pdf' {
                return 'application/pdf';
            }
            when 'txt' {
                return 'text/plain';
            }
            when 'ppt'{
                return 'application/vnd.google-apps.presentation';
            }
            when 'xls' {
                return 'application/vnd.ms-excel';
            }
            when
            else {
                return 'image/jpeg';
            }
        }
    }

    public class ChunkDetails {
        @AuraEnabled public Blob chunk { get; set; }
        @AuraEnabled public Integer start { get; set; }
        @AuraEnabled public Integer ending { get; set; }
        @AuraEnabled public Integer offset { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public Integer fileSize { get; set; }
        @AuraEnabled public String result { get; set; }
    }

}