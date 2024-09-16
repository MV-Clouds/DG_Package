global with sharing class OneDriveUploader implements Database.Batchable < SObject > , Database.AllowsCallouts {
    global string contentVersionId;
    global static string oneDriveAccessToken;
    global static string fullFileName;
    global string activity;

    //Generating New Access Token for each upload
    public static String getToken(String activity){
        try {
            MVDG__OneDriveAuthProviderSettings__c settings = MVDG__OneDriveAuthProviderSettings__c.getOrgDefaults();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://login.microsoftonline.com/common/oauth2/v2.0/token');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            request.setBody('refresh_token=' + settings.MVDG__refresh_token__c + settings.MVDG__refresh_token1__c +
                '&client_id=' + settings.MVDG__ClientId__c +
                '&client_secret=' + settings.MVDG__ClientSecret__c +
                '&grant_type=refresh_token');
            Http http1 = new Http();
            HttpResponse response1 = http1.send(request);
            Map < String, String > result1 = new Map < String, String > ();
            if (response1.getStatusCode() == 200) {
                Map < String, Object > jsonResponse = (Map < String, Object > ) JSON.deserializeUntyped(response1.getBody());
                String newtoken = (String) jsonResponse.get('access_token');
                return newtoken;
            }
            else {
                Response_Handler.store_Callout_Response(response1, 'OneDriveUploader', 'getToken');
                Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Failure '+ response1.getStatusCode() + response1.getBody();
                obj.Id = activity; 
                update obj;
                mailMessage(response1.getStatusCode());
                return null;
            }
        }catch(Exception e){
            Log_Handler.store_Exception(e, 'OneDriveUploader', 'getToken', activity);
            Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Failure '+ e.getMessage();
                obj.Id = activity; 
                update obj;
                return null;
        }
    }

    global OneDriveUploader(Id cvid, Id activityId) {
        System.debug(activity);
        this.contentVersionId = cvid;
        this.activity = activityId;  //activity will be used to send mail
    }


    global Database.QueryLocator start(Database.BatchableContext bC) {
        try {
            if(contentVersionId != null){
                return Database.getQueryLocator([
                    SELECT Id, VersionData, Title, ContentSize, FileExtension
                    FROM ContentVersion
                    WHERE Id =: contentVersionId WITH SECURITY_ENFORCED
                ]);
            }
            return null;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveUploader', 'batch start', activity);
            Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
            obj.One_Drive__c = 'Failure '+ e.getMessage();
            obj.Id = activity; 
            update obj;
            return null;
        }
    }


    global void execute(Database.BatchableContext bC, List < ContentVersion > scope) {
        for (ContentVersion cv: scope) {
            try {
                String fileName = cv.Title;
                Integer fileSize = cv.ContentSize;
                fullFileName = cv.Title +'.'+ cv.fileExtension;
                String contentType = contentTypeForOneDrive(cv.FileExtension);
                System.debug(activity);
                
                String acctoken = getToken(activity);
                Integer fileSizeEncoded = getLengthOfFile(cv.VersionData);
                Integer maxSize = (8 * 1024 * 1024);  // 8 MB chunk factor
                if (Test.isRunningTest()) {
                    maxSize = 800;
                }
                if(acctoken != null){
                    oneDriveAccessToken = acctoken;
                    if (fileSize < maxSize) { // 8 MB threshold
                        uploadToOneDrive(cv, fileName, contentType, activity);
                    } else {
                        uploadLargeFileInChunks(cv, fileName, fileSizeEncoded, contentType, activity);
                    }
                }
            } catch (Exception e) {
                Log_Handler.store_Exception(e, 'OneDriveUploader', 'batch execute', activity);
                Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Failure '+ e.getMessage();
                obj.Id = activity; 
                update obj;
                System.debug('Error during Dropbox file upload: ' + e.getMessage());
            }
        }
    }


    global void finish(Database.BatchableContext bC) {
        System.debug('Dropbox file upload batch finished');
    }




    @AuraEnabled
    public static Boolean uploadToOneDrive(ContentVersion content, String fileName, String contentType, String activity) {
        try {
            MVDG__OneDriveAuthProviderSettings__c settings = MVDG__OneDriveAuthProviderSettings__c.getOrgDefaults();
            String emailid = settings.MVDG__email__c;
            string endpointUrl = 'https://graph.microsoft.com/v1.0/users/me/drive/items/root:/{file}:/content';
            string file = EncodingUtil.URLENCODE(fileName, 'UTF-8').replace('+', '%20');
            endpointUrl = endpointUrl.replace('{file}', file + '.' + content.FileExtension);
            HttpRequest req = new HttpRequest();
            req.setHeader('Authorization', 'Bearer ' + oneDriveAccessToken);
            req.setEndpoint(endpointUrl);
            req.setMethod('PUT');
            req.setHeader('Content-type', contentType);
            req.setHeader('Content-Encoding', 'UTF-8');
            req.setHeader('accept', 'application/json');
            req.setBodyAsBlob(content.VersionData);
            req.setTimeout(120000);
            Http h = new Http();
            HttpResponse resp = h.send(req);
            System.debug(resp.getStatusCode());
            System.debug(resp.getBody());
            if (resp.getStatusCode() == 200 || resp.getStatusCode() == 201) {
                System.debug(resp.getBody());
                System.debug('activity'+activity);
                Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Success';
                obj.Id = activity; 
                update obj;
                return true;
            } else {
                Response_Handler.store_Callout_Response(resp, 'OneDriveUploader', 'uploadToOneDrive');
                Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Failure '+ resp.getStatusCode() + resp.getBody();
                obj.Id = activity; 
                update obj;
                mailMessage(resp.getStatusCode());
                System.debug('Something went wrong');
                return false;
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveUploader', 'uploadToOneDrive', activity);
            Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Failure '+ e.getMessage();
                obj.Id = activity; 
                update obj;
                return false;
        }
    }

    public static void mailMessage(Integer code){
        if (code == 400) {
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have noticed an issue while attempting to upload the file ' + fullFileName + ' to One Drive.\n\n' +
                   'To resolve this issue, please ensure that your credentials are correct. If the problem persists, try the following steps:\n\n' +
                   '1. Remove the existing One Drive connection.\n' +
                   '2. Reconnect to One Drive.\n\n' +
                   'These steps should help resolve the issue. If you continue to experience difficulties, please feel free to contact our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 401) {
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have noticed an issue while attempting to upload the file ' + fullFileName + ' to One Drive.\n\n' +
                   'To resolve this issue, please follow these steps to reconnect:\n\n' +
                   '1. Remove the existing One Drive connection.\n' +
                   '2. Reconnect to One Drive.\n\n' +
                   'These steps should help re-establish the connection. If you continue to experience difficulties, please don\'t hesitate to reach out to our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 403){
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We encountered an issue while attempting to upload the file ' + fullFileName + ' to One Drive. ' +
                   'It appears that you do not have the necessary permissions to complete this upload.\n\n' +
                   'To resolve this issue, please check the following:\n\n' +
                   '1. Ensure that you have the correct permissions to upload files to the specified One Drive folder.\n' +
                   '2. Verify that your One Drive account has the appropriate access rights.\n\n' +
                   'If you continue to experience difficulties, please don\'t hesitate to reach out to our support team for further assistance.\n\n' +
                   'Thank you for your attention to this matter.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 404){
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have encountered a connection error (404 - File Not Found) while attempting to access your One Drive.\n\n' +
                   'This error indicates that the file or resource you are trying to access may not exist or could not be found. To resolve this issue, please try the following steps:\n\n' +
                   '1. Verify that the file or resource exists in your One Drive.\n' +
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
                   'We have encountered a server error (500 - Internal Server Error) while attempting to upload your file to One Drive. This error typically indicates a problem with our server or the service.\n\n' +
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
                   'We have encountered error with code: '+ code + 'while attempting to upload your file to One Drive. This error typically indicates a problem with our server or the service.\n\n' +
                   'To resolve this issue, please try the following:\n\n' +
                   '1. Remove the existing One Drive connection.\n' +
                   '2. Reconnect to One Drive.\n\n' +
                   'If the problem persists after following these steps, please feel free to contact our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
    }


    public static void uploadLargeFileInChunks(ContentVersion contentVersion, String fileName, Integer fileSize, String fileExtension,String activity) {
        try {
            String result = initiateUploadSession(fileExtension, contentVersion, activity);
            if (result != 'failure') {
                System.debug('Initiated successfully');
                Decimal filesizedec = Decimal.valueOf(fileSize);
                Integer offset;
        
        
                Integer chunkSize = 1500000; // approx 1.5 MB chunk size
                Integer totalChunks = Integer.valueOf(Math.ceil(filesizedec.divide(chunkSize, 3)));
        
        
                for (Integer i = 0; i < totalChunks; i++) {
                    Integer start = i * chunkSize;
                    Integer ending = Math.min((i + 1) * 1125000 - 1, Integer.valueOf(contentVersion.VersionData.size()) - 1);
                    transient Blob chunkBlob = getFileData(contentVersion.VersionData, start, chunkSize);
                    offset = Integer.valueOf(Math.floor(start / 1.3333333333));
                    if (start != 0) {
                        start = start - (i * 375000);
                    }
                    ChunkDetails chunkdetail = new ChunkDetails();
                    chunkdetail.chunk = chunkBlob;
                    chunkdetail.start = start;
                    chunkdetail.ending = ending;
                    chunkdetail.offset = offset; 
                    chunkdetail.fileExtension = fileExtension;
                    chunkdetail.fileSize = contentVersion.VersionData.size();
                    chunkdetail.result = result;
                    chunkdetail.activity = activity;
                    uploadChunk(chunkdetail);
                }
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveUploader', 'uploadLargeFileInChunks', activity);
            Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Failure '+ e.getMessage();
                obj.Id = activity; 
                update obj;
        }

    }


    @AuraEnabled
    public static void emailUser(String message) {
            String subject = 'Issue in uploading file to One drive';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String userEmail = UserInfo.getUserEmail();
            if (userEmail != null && userEmail.contains('@')) {
                mail.setToAddresses(new List<String>{userEmail});
            } else {
                // Handle the case when email is null or invalid
                System.debug('Invalid user email: ' + userEmail);
            }
            mail.setSubject(subject);
            mail.setPlainTextBody(message);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }


    public static string initiateUploadSession(String contentType, ContentVersion cv, String activity) {
        try {       
            MVDG__OneDriveAuthProviderSettings__c settings = MVDG__OneDriveAuthProviderSettings__c.getOrgDefaults();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://graph.microsoft.com/v1.0/me/drive/root:/' + EncodingUtil.URLENCODE(fullFileName, 'UTF-8').replace('+', '%20') + ':/createUploadSession');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + oneDriveAccessToken);
            req.setHeader('accept', 'application/json');
            req.setHeader('Content-Type', contentType);
            req.setBody('');
    
            Http http = new Http();
            HttpResponse res = http.send(req);
    
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map < String, Object > responseMap = (Map < String, Object > ) JSON.deserializeUntyped(res.getBody());
                return (String) responseMap.get('uploadUrl');
            } else {
                Response_Handler.store_Callout_Response(res, 'OneDriveUploader', 'initiateUploadSession');
                Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Failure'+ res.getStatusCode() + res.getBody();
                obj.Id = activity; 
                update obj;
                mailMessage(res.getStatusCode());
                System.debug('Error initiating upload session: ' + res.getStatusCode() + res.getBody());
                return 'failure';
            }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveUploader', 'initiateUploadSession', activity);
            Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Failure '+ e.getMessage();
                obj.Id = activity; 
                update obj;
                return 'failure';
        }
    }


    private static void uploadChunk(chunkDetails parameters) {
        System.debug('Upload chunk Invoked');
        try {
            if( parameters.result != null){
                
            String contentRange = 'bytes ' + parameters.start + '-' + parameters.ending + '/' + parameters.fileSize;
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
            System.debug(res.getStatusCode());

            if (res.getStatusCode() == 200 || res.getStatusCode() == 202) {
                System.debug('Half was success' + res.getStatusCode() + res.getBody());
            }
            else if(res.getStatusCode() == 201){
                System.debug('Everything was success' + res.getStatusCode() + res.getBody());
                Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Success';
                obj.Id = parameters.activity; 
                update obj;
            }else {
                System.debug('Everything was in else' + res.getStatusCode() + res.getBody());
                Response_Handler.store_Callout_Response(res, 'OneDriveUploader', 'uploadChunk');
                Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Failure'+ res.getStatusCode() + res.getBody();
                obj.Id = parameters.activity; 
                update obj;
                mailMessage(res.getStatusCode());
            }
        }
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'OneDriveUploader', 'uploadChunk', parameters.activity);
            Generate_Document_Activity__c obj = new Generate_Document_Activity__c();
                obj.One_Drive__c = 'Failure '+ e.getMessage();
                obj.Id = parameters.activity; 
                update obj;
        }
    }


    public static String contentTypeForOneDrive(String fileType) {
        switch on fileType.toLowerCase() {
            when 'docx' {
                return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            }
            when 'csv' {
                return 'application/vnd.ms-excel';
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
            when 'xls' {
                return 'application/vnd.ms-excel';
            }
            when
            else {
                return 'image/jpeg';
            }
        }
    }


    private static Blob getFileData(Blob versionDataBlob, Integer chunkStart, Integer chunkSize) {
        return EncodingUtil.base64Decode(EncodingUtilMethod(versionDataBlob, chunkStart, chunkSize));
    }


    public static String encodingUtilMethod(Blob versionDataBlob, Integer chunkStart, Integer chunkSize) {
        return EncodingUtil.base64Encode(versionDataBlob).mid(chunkStart, chunkSize);
    }


    public static Integer getLengthOfFile(Blob versionDataBlob) {
        return EncodingUtil.base64Encode(versionDataBlob).length();
    }

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