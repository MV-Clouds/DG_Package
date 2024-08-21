global with sharing class DropboxUploader implements Database.Batchable < SObject > , Database.AllowsCallouts {
    global static String dropboxAccessToken;
    global Id contentVersionId;
    global String uploadSessionId;
    global static string dropFileName;


    public static String tokenPermanent() {
        MVDG__DropBoxAuthProviderSettings__c settings = MVDG__DropBoxAuthProviderSettings__c.getOrgDefaults();
        String refresh = settings.MVDG__refresh_token__c;
        String clientid = settings.MVDG__ClientId__c;
        String clientsecret = settings.MVDG__ClientSecret__c;
        String body =
            'grant_type=refresh_token' +
            '&refresh_token=' +
            EncodingUtil.urlEncode(refresh, 'UTF-8') +
            '&client_id=' +
            EncodingUtil.urlEncode(clientid, 'UTF-8') +
            '&client_secret=' +
            EncodingUtil.urlEncode(clientsecret, 'UTF-8');

        Http h = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://api.dropbox.com/oauth2/token');

        req.setHeader('Content-length', String.valueOf(body.length()));
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        req.setMethod('POST');

        req.setBody(body);
        HttpResponse res = h.send(req);
        // System.debug(res.getBody());

        Map < String, String > jsonvalues = new Map < String, String > ();
        jsonvalues = parseJSONToMap(res.getBody());

        return jsonvalues.get('access_token');
    }

    //  parser to json
    public static map < String, String > parseJSONToMap(String jsonValue) {
        JSONParser parser = JSON.createParser(jsonValue);
        map < string, string > jsonMap = new Map < string, string > ();
        string keyValue = '';
        string tempValue = '';
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                keyValue = parser.getText();
                parser.nextToken();
                tempValue = parser.getText();
                jsonMap.put(keyValue, tempValue);
            }
        }
        return jsonMap;
    }

    global DropboxUploader(Id cvid) {
        this.contentVersionId = cvid;
    }

    global Database.QueryLocator start(Database.BatchableContext bC) {
        if(contentVersionId != null){
            return Database.getQueryLocator([
                SELECT Id, VersionData, Title, ContentSize, FileExtension
                FROM ContentVersion
                WHERE Id =: contentVersionId
            ]);
        }
        return null;
    }

    global void execute(Database.BatchableContext bC, List < ContentVersion > scope) {
        for (ContentVersion cv: scope) {
            try {
                String fileName = cv.Title;
                Integer fileSize = cv.ContentSize;
                dropFileName = cv.Title+'.'+cv.fileExtension;
                String contentType = getContentType(cv.FileExtension);
                String acctoken = tokenPermanent();
                // Blob fileData = cv.VersionData;
                Integer fileSizeEncoded = getLengthOfFile(cv.VersionData);
                if(acctoken != null){
                    dropboxAccessToken = acctoken;
                    Integer maxSize = 8* 1024 * 1024;

                    if (Test.isRunningTest()) {
                        maxSize = 800;
                    }
                    if (fileSize < maxSize) { // 8 MB threshold
                        System.debug('Uploading small file directly to Dropbox');
                        uploadSmallFile(cv.VersionData, contentType);
                    } else {
                        System.debug('Uploading large file in chunks to Dropbox');
                        uploadLargeFileInChunks(cv, fileSizeEncoded);
                    }
                }
            } catch (Exception e) {
                System.debug('Error during Dropbox file upload: ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bC) {
        System.debug('Dropbox file upload batch finished');
    }

    public static void mailMessage(Integer code){
        if (code == 400) {
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have noticed an issue while attempting to upload the file ' + dropFileName + ' to Dropbox.\n\n' +
                   'To resolve this issue, please ensure that your credentials are correct. If the problem persists, try the following steps:\n\n' +
                   '1. Remove the existing Dropbox connection.\n' +
                   '2. Reconnect to Dropbox.\n\n' +
                   'These steps should help resolve the issue. If you continue to experience difficulties, please feel free to contact our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 401) {
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have noticed an issue while attempting to upload the file ' + dropFileName + ' to Dropbox.\n\n' +
                   'To resolve this issue, please follow these steps to reconnect:\n\n' +
                   '1. Remove the existing Dropbox connection.\n' +
                   '2. Reconnect to Dropbox.\n\n' +
                   'These steps should help re-establish the connection. If you continue to experience difficulties, please don\'t hesitate to reach out to our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 403){
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We encountered an issue while attempting to upload the file ' + dropFileName + ' to Dropbox. ' +
                   'It appears that you do not have the necessary permissions to complete this upload.\n\n' +
                   'To resolve this issue, please check the following:\n\n' +
                   '1. Ensure that you have the correct permissions to upload files to the specified Dropbox folder.\n' +
                   '2. Verify that your Dropbox account has the appropriate access rights.\n\n' +
                   'If you continue to experience difficulties, please don\'t hesitate to reach out to our support team for further assistance.\n\n' +
                   'Thank you for your attention to this matter.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 404){
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have encountered a connection error (404 - File Not Found) while attempting to access your Dropbox.\n\n' +
                   'This error indicates that the file or resource you are trying to access may not exist or could not be found. To resolve this issue, please try the following steps:\n\n' +
                   '1. Verify that the file or resource exists in your Dropbox.\n' +
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
                   'We have encountered a server error (500 - Internal Server Error) while attempting to upload your file to Dropbox. This error typically indicates a problem with our server or the service.\n\n' +
                   'To resolve this issue, please try the following:\n\n' +
                   '1. Wait for a few minutes and try uploading the file again.\n' +
                   '2. If the issue persists, it may be due to temporary server problems on One\'s end.\n\n' +
                   'If the problem persists after following these steps, please feel free to contact our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else {
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have encountered error with code: '+ code + 'while attempting to upload your file to Dropbox. This error typically indicates a problem with our server or the service.\n\n' +
                   'To resolve this issue, please try the following:\n\n' +
                   '1. Remove the existing Dropbox connection.\n' +
                   '2. Reconnect to Dropbox.\n\n' +
                   'If the problem persists after following these steps, please feel free to contact our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
    }

    private static void uploadSmallFile(Blob fileData, String contentType) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://content.dropboxapi.com/2/files/upload');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + dropboxAccessToken);
        req.setHeader('Dropbox-API-Arg', '{"path": "/' + dropFileName + '", "mode": "add", "autorename": true, "mute": false}');
        req.setHeader('Content-Type', 'application/octet-stream');
        req.setBodyAsBlob(fileData);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('Small file uploaded successfully to Dropbox');
        } else {
            Response_Handler.store_Callout_Response(res, 'DropboxUploader', 'uploadSmallFile');
            mailMessage(res.getStatusCode());
            System.debug('Error during small file upload to Dropbox: ' + res.getStatus());
            System.debug('Response body: ' + res.getBody());
        }
    }

    private static void uploadLargeFileInChunks(ContentVersion contentVersion, Integer fileSize) {
        String sessionId = initiateUploadSession();
        Decimal filesizedec = Decimal.valueOf(fileSize);
        Integer offset;

        Integer chunkSize = 4000000; // 9 MB chunks
        Integer totalChunks = Integer.valueOf(Math.ceil(filesizedec.divide(chunkSize, 3)));

        for (Integer i = 0; i < totalChunks; i++) {
            System.debug(Limits.getHeapSize());
            Integer start = i * chunkSize;
            Integer ending = Math.min((i + 1) * chunkSize - 1, Integer.valueOf(fileSize) - 1);
            System.debug('Chunk Start Byte: ' + start);
            System.debug('Chunk End Byte: ' + ending);
            System.debug('file size-->' + fileSize);
            Blob chunkBlob = getFileData(contentVersion.VersionData, start, chunkSize);

            // Compute the offset as the start byte of the chunk
            offset = Integer.valueOf(Math.floor(start / 1.3333333333));
            System.debug('Chunk Offset: ' + offset);

            uploadChunk(chunkBlob, sessionId, offset);
            System.debug('Uploaded chunk ' + (i + 1) + '/' + totalChunks + ': Start Byte: ' + start + ', End Byte: ' + ending + ', Offset: ' + offset);
            System.debug(Limits.getHeapSize());
            chunkBlob = null;
            System.debug(Limits.getHeapSize());

        }
        // After uploading all chunks, complete the upload session‸
        Blob lastChunk = getFileData(contentVersion.VersionData, (totalChunks - 1) * chunkSize, chunkSize);
        completeUploadSession(sessionId, lastChunk, offset);
    }


    private static String initiateUploadSession() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://content.dropboxapi.com/2/files/upload_session/start');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + dropboxAccessToken);
        req.setHeader('Dropbox-API-Arg', '{"close": false}');
        req.setHeader('Content-Type', 'application/octet-stream');
        req.setBodyAsBlob(Blob.valueOf(''));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map < String, Object > jsonResponse = (Map < String, Object > ) JSON.deserializeUntyped(res.getBody());
            return (String) jsonResponse.get('session_id');
        } else {
            Response_Handler.store_Callout_Response(res, 'DropboxUploader', 'initiateUploadSession');
            mailMessage(res.getStatusCode());
            throw new CalloutException('Error initiating Dropbox upload session: ' + res.getBody());
        }
    }

    private static void uploadChunk(Blob chunk, String sessionId, Integer offset) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://content.dropboxapi.com/2/files/upload_session/append_v2');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + dropboxAccessToken);
        req.setHeader('Dropbox-API-Arg', '{"cursor": {"session_id": "' + sessionId + '", "offset": ' + offset + '}, "close": false}');
        req.setHeader('Content-Type', 'application/octet-stream');
        req.setBodyAsBlob(chunk);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            Response_Handler.store_Callout_Response(res, 'DropboxUploader', 'uploadChunk');
            mailMessage(res.getStatusCode());
            throw new CalloutException('Error uploading Dropbox chunk: ' + res.getBody());
        }
    }

    private static void completeUploadSession(String sessionId, Blob lastChunk, Integer offset) {
        System.debug(lastChunk.size() + offset);
        Integer off = lastChunk.size() + offset;
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://content.dropboxapi.com/2/files/upload_session/finish');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + dropboxAccessToken);
        req.setHeader('Dropbox-API-Arg', '{"cursor": {"session_id": "' + sessionId + '", "offset": ' + off + '}, "commit": {"path": "/' + dropFileName + '", "mode": "add", "autorename": true, "mute": false}}');
        req.setHeader('Content-Type', 'application/octet-stream');
        req.setBodyAsBlob(lastChunk);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('Large file uploaded successfully to Dropbox');
        } else {
            Response_Handler.store_Callout_Response(res, 'DropboxUploader', 'completeUploadSession');
            mailMessage(res.getStatusCode());
            System.debug('Error during large file upload to Dropbox: ' + res.getStatus());
            System.debug('Response body: ' + res.getBody());
        }
    }

    private static Blob getFileData(Blob versionDataBlob, Integer chunkStart, Integer chunkSize) {
        System.debug('Error -->' + EncodingUtil.base64Decode(encodingUtilMethod(versionDataBlob, chunkStart, chunkSize)));
        return EncodingUtil.base64Decode(encodingUtilMethod(versionDataBlob, chunkStart, chunkSize));
    }

    public static String encodingUtilMethod(Blob versionDataBlob, Integer chunkStart, Integer chunkSize) {
        return EncodingUtil.base64Encode(versionDataBlob).mid(chunkStart, chunkSize);
    }

    private static String getContentType(String fileExtension) {
        // Add logic to determine content type based on file extension if necessary
        return 'application/octet-stream';
    }

    public static Integer getLengthOfFile(Blob versionDataBlob) {
        return EncodingUtil.base64Encode(versionDataBlob).length();
    }

    @AuraEnabled
    public static void emailUser(String message) {
        if(Schema.sObjectType.User.fields.Email.isAccessible()){
        User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String subject = 'Issue in uploading file to dropbox';
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { currentUser.Email });
        mail.setSubject(subject);
        mail.setPlainTextBody(message);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}