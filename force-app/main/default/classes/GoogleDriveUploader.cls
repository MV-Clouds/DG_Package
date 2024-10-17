global with sharing class GoogleDriveUploader implements Database.Batchable < SObject > , Database.AllowsCallouts{

    global string contentVersionId;
    global static string googleDriveAccessToken;
    global static string googleFileName;
    global string activity;
    global static List<MVDG__Generate_Document_Activity__c> listMessage = new List<MVDG__Generate_Document_Activity__c>();
    private static List<HttpResponse> responseList = new List<HttpResponse>();

/*
*********************************************************
@description     : constructor to define values
@param           : cvid{Id} - ContentVersionId
@param           : activityId{Id} - ActivityId
********************************************************
*/
    global GoogleDriveUploader(Id cvid, Id activityId) {
        this.contentVersionId = cvid;
        this.activity = activityId;
    }

    global GoogleDriveUploader(Id cvid) {
        this.contentVersionId = cvid;
    }

    global static void updateActivityMessage(MVDG__Generate_Document_Activity__c record){
        if (listMessage == null) {
            listMessage = new List<MVDG__Generate_Document_Activity__c>();
        }
        listMessage.add(record);
    }

    global Database.QueryLocator start(Database.BatchableContext bC) {
        try {
            if(contentVersionId != null){
                return Database.getQueryLocator([
                    SELECT Id, VersionData, Title, ContentSize, FileExtension
                    FROM ContentVersion
                    WHERE Id =: contentVersionId with SECURITY_ENFORCED
                ]);
            }
            return null;    
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GoogleDriveUploader', 'batch start', activity);
            MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
            obj.MVDG__Google_Drive__c = 'Failure '+ e.getMessage();
            obj.Id = activity; 
            updateActivityMessage(obj);
            return null;
        }
    }


    global void execute(Database.BatchableContext bC, List < ContentVersion > scope) {
        try {
            String acctoken = getToken(activity);
            if (!scope.isEmpty()) {
                ContentVersion cv = scope[0];
                String fileName = cv.Title;
                googleFileName = cv.Title+'.'+cv.fileExtension;
                Integer fileSize = cv.ContentSize;
                String contentType = contentType(cv.FileExtension);
                Integer fileSizeEncoded = getLengthOfFile(cv.VersionData);
                List<String> fileDetails = new List<String>();
                fileDetails.add(contentType);
                fileDetails.add(activity);
                if(acctoken != null){
                    googleDriveAccessToken = acctoken;

                    Integer maxSize = 5 * 1024 * 1024;
                    if (Test.isRunningTest()) {
                        maxSize = 800;
                    } 
                    if (fileSize < maxSize) { // 5 MB threshold
                        Boolean result = uploadToGoogleDrive(cv, fileName, fileDetails);

                    } else {
                        Boolean result = uploadLargeFileInChunks(cv, fileSizeEncoded, fileDetails);
                    }
                }
            }
        } catch (System.LimitException e) {
            Log_Handler.store_Exception(e, 'GoogleDriveUploader', 'execute batch', activity);
            MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
            obj.MVDG__Google_Drive__c = 'Failure '+ e.getMessage();
            obj.Id = activity; 
            updateActivityMessage(obj);
            emailUser('File size too large. Try uploading file with smaller size.\n\n Or Download it and then upload file manually.');
        }
        if (!listMessage.isEmpty()) {
            if(Schema.sObjectType.MVDG__Generate_Document_Activity__c.fields.MVDG__AWS__c.isAccessible() && Schema.sObjectType.MVDG__Generate_Document_Activity__c.fields.MVDG__AWS__c.isUpdateable()){
                update as user listMessage[0];
            }
        }
    }



    global void finish(Database.BatchableContext bC) {
    }


/*
*********************************************************
@description     : Method is used to get access token
@param           : isOrg {Boolean} - Let them know if the access token is for org wide or user wide
@return          : {String} - return Token if successful
********************************************************
*/

@deprecated
global static String getToken(){
    // try {
    //     List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();
    //     MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
    //     String endpoint = 'https://oauth2.googleapis.com/token';
    //     HttpRequest request = new HttpRequest();
    //     request.setEndpoint(endpoint);
    //     request.setMethod('POST');
    //     request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    //     request.setBody('refresh_token=' + settings.MVDG__refresh_token__c +
    //                     '&client_id=' + mdata[0].MVDG__CID__c +
    //                     '&client_secret=' + mdata[0].MVDG__CSEC__c +
    //                     '&grant_type=refresh_token');

    //     Http http = new Http();
    //     HttpResponse response = http.send(request);

    //     if (response.getStatusCode() == 200) {
    //         Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    //         String newToken = (String) jsonResponse.get('access_token');
    //         return newToken;
    //     }
    //     else{
    //         Response_Handler.store_Callout_Response(response, 'GoogleDriveUploader', 'getToken');
    //         mailMessage(response.getStatusCode());
    //     }
    // } catch (Exception e) {
    //     Log_Handler.store_Exception(e, 'GoogleDriveUploader', 'getToken');
    // }
    return null;
}

    global static String getToken(String activity){
        try {
            List<MVDG__AuthProviderSetup__mdt> mdata = MVDG__AuthProviderSetup__mdt.getAll().values();
            MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
            String endpoint = 'https://oauth2.googleapis.com/token';
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setBody('refresh_token=' + settings.MVDG__refresh_token__c +
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
                MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
                    obj.MVDG__Google_Drive__c = 'Failure '+ response.getStatusCode() + response.getBody();
                    obj.Id = activity; 
                    updateActivityMessage(obj);
                mailMessage(response.getStatusCode());
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GoogleDriveUploader', 'getToken', activity);
            MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
                obj.MVDG__Google_Drive__c = 'Failure '+ e.getMessage();
                obj.Id = activity; 
                updateActivityMessage(obj);
        }
        return null;
    }


/*
*********************************************************
@description     : Method is used to upload small files
@param           : fileDetails{List<String>} - File MimeType and activity which is needed
@param           : Content{Contentversion} - File contentversion which needs to be upload
@param           : filName{String} - Name of the file which needs to be upload
@return          : Boolean - success or not
********************************************************
*/
    @AuraEnabled
    public static Boolean uploadToGoogleDrive(ContentVersion content, String fileName, List<String> fileDetails) {
        try {
            if (content != null) {
                MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
                HttpRequest req = createGoogleDriveRequest(content, settings);
    
                HttpResponse resp = sendHttpRequest(req);
                
                if (resp.getStatusCode() == 200) {
                    MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
                        obj.MVDG__Google_Drive__c = 'Success';
                        obj.Id = fileDetails[1]; 
                        updateActivityMessage(obj);
                    return true;
                } else {
                    Response_Handler.store_Callout_Response(resp, 'GoogleDriveUploader', 'uploadToGoogleDrive');
                    MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
                        obj.MVDG__Google_Drive__c = 'Failure '+ resp.getStatusCode() + resp.getBody();
                        obj.Id = fileDetails[1]; 
                        updateActivityMessage(obj);
                    mailMessage(resp.getStatusCode());
                    return false; // Retry after token refresh
                }
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GoogleDriveUploader', 'uploadToGoogleDrive', fileDetails[1]);
            MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
                obj.MVDG__Google_Drive__c = 'Failure '+ e.getMessage();
                obj.Id = fileDetails[1]; 
                updateActivityMessage(obj);
        }
        
        
        return false;
    }


/*
*********************************************************
@description     : Method is used to create httpRequest for google drive upload
@param           : Content{Contentversion} - File contentversion which needs to be upload
@param           : settings{MVDG__AuthProviderSettings__c} - Custom setting containing accesstoken
@return          : HttpRequest - create httpRequest for google drive upload
********************************************************
*/
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


/*
*********************************************************
@description     : Method is used to create multipart request for google drive upload
@param           : Content{Contentversion} - File contentversion which needs to be upload
@return          : String - returns body
********************************************************
*/
    private static String createMultipartRequestBody(ContentVersion content) {
        String fileN = content.Title;
        String fileExtension = content.FileExtension;
        String contentType = content.FileExtension;
        String body = '--foo_bar_baz\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n {"title": "' + fileN + '", "mimeType": "'+contentType(contentType)+'"}\r\n\r\n--foo_bar_baz\r\nContent-Transfer-Encoding: base64\r\nContent-Type: "Image/' + contentType(contentType) + '"\r\n\r\n' + EncodingUtil.base64Encode(content.VersionData) + '\r\n--foo_bar_baz--';
        return body;
    }


/*
*********************************************************
@description     : Method is used to create multipart request for google drive upload
@param           : req{HttpRequest} - Sends request to google
@return          : HttpResponse - returns response recieved from google
********************************************************
*/
    private static HttpResponse sendHttpRequest(HttpRequest req) {
        Http h = new Http();
        req.setTimeout(60000);
        return h.send(req);
    }


/*
*********************************************************
@description     : Method is used to upload large file in chunks
@param           : contentVersion{ContentVersion} - Content version which needs to be uploaded
@param           : fileSize{Integer} - File size in bytes
@param           : fileDetails{List<String>} - List of file details containing file type and activity
@return          : none
********************************************************
*/
    private static Boolean uploadLargeFileInChunks(ContentVersion contentVersion, Integer fileSize, List<String> fileDetails) {
        try {
            String result = initiateUploadSession(fileDetails[0], contentVersion, fileDetails[1]);
            if (result != 'failure') {
                Decimal filesizedec = Decimal.valueOf(fileSize);
                Integer offset;
    
    
                Integer chunkSize = 2097152; // 2 MB chunks
                Integer totalChunks = Integer.valueOf(Math.ceil(filesizedec.divide(chunkSize, 3)));
    
    
                for (Integer i = 0; i < totalChunks; i++) {
                    Integer start = i * chunkSize;
                    Integer ending = Math.min((i + 1) * 1572864 - 1, Integer.valueOf(contentVersion.VersionData.size()) - 1);
                    Blob chunkBlob = getFileData(contentVersion.VersionData, start, chunkSize);
                    offset = Integer.valueOf(Math.floor(start / 1.3333333333));
                    if (start != 0) {
                        start = start - (i * 524288);
                    }
                    ChunkDetails chunkDetail = new ChunkDetails();
                    chunkDetail.chunk = chunkBlob;
                    chunkDetail.start = start;
                    chunkDetail.ending = ending;
                    chunkDetail.offset = offset;
                    chunkDetail.fileExtension = fileDetails[0];
                    chunkDetail.fileSize = contentVersion.VersionData.size();
                    chunkDetail.result = result;
                    chunkDetail.activity = fileDetails[1];
                    uploadChunk(chunkDetail);
                    chunkBlob = null;
                }
                Response_Handler.store_All_Callout_Response(responseList, 'GoogleDriveUploader', 'uploadChunk');
            }
            return true;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GoogleDriveUploader', 'uploadLargeFileInChunks', fileDetails[1]);
            MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
                obj.MVDG__Google_Drive__c = 'Failure '+ e.getMessage();
                obj.Id = fileDetails[1]; 
                updateActivityMessage(obj);
        }
        return false;
    }


/*
*********************************************************
@description     : Method is used to send email to user
@param           : code(Integer)
@return          : none
********************************************************
*/
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


/*
*********************************************************
@description     : Method is used to initiate upload session to upload in chunks
@param           : contentType (String) - MimeType of the file
@param           : cv (ContentVersion) - ContentVersion of the file
@param           : fileName (String) - Name of the file
@return          : String - return url to upload file in chunks
********************************************************
*/
    public static string initiateUploadSession(String contentType, ContentVersion cv, String activity) {
        try {
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
                return (String) res.getHeader('Location');
            } else {
                Response_Handler.store_Callout_Response(res, 'GoogleDriveUploader', 'initiateUploadSession');
                MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
                obj.MVDG__Google_Drive__c = 'Failure '+ res.getBody();
                obj.Id = activity; 
                updateActivityMessage(obj);
                mailMessage(res.getStatusCode());
                return 'failure';
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'GoogleDriveUploader', 'initiateUploadSession', activity);
            MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
                obj.MVDG__Google_Drive__c = 'Failure '+ e.getMessage();
                obj.Id = activity; 
                updateActivityMessage(obj);
                return 'failure';
        }
    }


/*
*********************************************************
@description     : Method is used to upload small chunks
@param           : parameters (ChunkDetails) - wrapper class containing details of chunks to be uploaded
@return          : none
********************************************************
*/
    private static void uploadChunk(ChunkDetails parameters) {
        try {
            
            if( parameters.result != null){
                
            String contentRange = 'bytes ' + parameters.start + '-' + parameters.ending + '/' + parameters.fileSize;

            MVDG__AuthProviderSettings__c settings = MVDG__AuthProviderSettings__c.getOrgDefaults();
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


            if (res.getStatusCode() == 201 || res.getStatusCode() == 202 || res.getStatusCode() == 308) {
            }
            else if(res.getStatusCode() == 200){
                MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
                obj.MVDG__Google_Drive__c = 'Success';
                obj.Id = parameters.activity; 
                updateActivityMessage(obj);
            } else {
                responseList.add(res);
                MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
                obj.MVDG__Google_Drive__c = 'Failure '+ res.getBody();
                obj.Id = parameters.activity; 
                updateActivityMessage(obj);
                mailMessage(res.getStatusCode());
                throw new AuraHandledException('exception' + res);
            }
            }
        } catch (Exception e) {
            MVDG__Generate_Document_Activity__c obj = new MVDG__Generate_Document_Activity__c();
                obj.MVDG__Google_Drive__c = 'Failure '+ e.getMessage();
                obj.Id = parameters.activity; 
                updateActivityMessage(obj);
                throw new AuraHandledException(''+e);
        }
    }

    private static Blob getFileData(Blob versionDataBlob, Integer chunkStart, Integer chunkSize) {
        return EncodingUtil.base64Decode(encodingUtilMethod(versionDataBlob, chunkStart, chunkSize));
    }

/*
*@description: Method is used to return blob in string form
*@parameters: versionData{Blob} - file which needs to be upload
*@parameters: chunkStart{Integer} - start of chunk
*@parameters: chunkSize{Integer} - size of chunk
*@return: String - base64 encoded chunk
*/
    public static String encodingUtilMethod(Blob versionDataBlob, Integer chunkStart, Integer chunkSize) {
        return EncodingUtil.base64Encode(versionDataBlob).mid(chunkStart, chunkSize);
    }


    public static Integer getLengthOfFile(Blob versionDataBlob) {
        return EncodingUtil.base64Encode(versionDataBlob).length();
    }

/*
*********************************************************
@description     : Method is used to send email to user if uploading fails
@param           : message{String} - message of the error
@return          : none
********************************************************
*/
    @AuraEnabled
    public static void emailUser(String message) {
        // User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String subject = 'Issue in uploading file to google drive';
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String userEmail = UserInfo.getUserEmail();
        if (userEmail != null && userEmail.contains('@')) {
            mail.setToAddresses(new List<String>{userEmail});
        }
        mail.setSubject(subject);
        mail.setPlainTextBody(message);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }


/*
*********************************************************
@description     : Method is used to return mime Type according to the external storage
@param           : fileType{String} - file type of the attachment
@return          : String return mimeType of the file
********************************************************
*/
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

    /*
    *@description: WrapperClass to return chunk details
    *@parameters: chunk{Blob} - file chunk
    *@parameters: start{Integer} - start bytes
    *@parameters: ending{Integer} - Ending bytes
    *@parameters: offset{Integer} - offset
    *@parameters: fileExtension{String} - file extension
    *@parameters: fileSize{Integer} - file size
    *@parameters: result{String} - result
    *@parameters: activity{String} - activity
    */
    public class ChunkDetails {
        @AuraEnabled public Blob chunk { get; set; }
        @AuraEnabled public Integer start { get; set; }
        @AuraEnabled public Integer ending { get; set; }
        @AuraEnabled public Integer offset { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public Integer fileSize { get; set; }
        @AuraEnabled public String result { get; set; }
        @AuraEnabled public String activity { get; set; }
    }

}