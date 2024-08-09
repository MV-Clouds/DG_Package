global class AwsUploader implements Database.Batchable<SObject>, Database.AllowsCallouts {
    global static String key = '';
    global static String secret = '';
    global static String bucket = '';
    global static string namedCredential = '';
    global static string awsFileName = '';
    global static string awsFullFileName;
    global Id contentVersionId;


    global AwsUploader(Id cvid) {
        this.contentVersionId = cvid;
    }

    global Database.QueryLocator start(Database.BatchableContext bC) {
        // Query for ContentVersion records
        return Database.getQueryLocator([
            SELECT Id, VersionData, Title, ContentDocumentId, FileExtension, ContentSize 
            FROM ContentVersion 
            WHERE Id = :contentVersionId
        ]);
    }

    global void execute(Database.BatchableContext bC, List<ContentVersion> scope) {
        try {
            MVDG__AwsAuthProviderSettings__c settings = MVDG__AwsAuthProviderSettings__c.getOrgDefaults();
            String bucketName = settings.MVDG__BucketName__c;
            String awsKey = settings.MVDG__ClientId__c;
            String awsSecret = settings.MVDG__ClientSecret__c;
            String methodName = 'PUT';
            String namedCredentialApiName = settings.MVDG__NamedCredential__c;
            if(namedCredentialApiName != null){
                namedCredential = namedCredentialApiName;
            }
            else if( awsKey != null && awsSecret != null && bucketName != null){
                bucket = bucketName;
                key = awsKey;
                secret = awsSecret;
            }

            for (ContentVersion attach : scope) {
                String fileName = attach.Title;
                Integer fileSize = attach.ContentSize;
                awsFullFileName = attach.Title+'.'+attach.FileExtension;
                String contentType = contentType(attach.FileExtension);
                Decimal lengthOfFile = getLengthOfFile(attach.VersionData);

                Integer maxSize = (10*1024*1024);

                if (Test.isRunningTest()) {
                    maxSize = 800;
                }

                if (fileSize < maxSize) {
                    System.debug('Uploading small file');
                    uploadObject(fileName, attach.FileExtension, attach.VersionData);
                } else {
                    if(namedCredential != ''){
                    System.debug('Uploading large file');
                    String formattedDate = DateTime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
                    // String payloadHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
                    String timestamp = DateTime.now().format('yyyyMMddHHmmss');
                    awsFileName = filename.replace(' ', '%20') + '_' + timestamp + '.' + attach.fileExtension;
                    String authHeader;
                    String endpoint;

                    
                    
                    HttpRequest req = new HttpRequest();
                    endpoint = 'callout:'+ namedCredential +'/'+ awsFileName+'?uploads';
                    req.setMethod('POST');
                    req.setEndpoint(endpoint);

                    Http http = new Http();
                    HTTPResponse res = http.send(req);

                    System.debug('phase 2');

                    if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                        String uploadId = '';
                        String responseBody = res.getBody();
                        if (responseBody != null && responseBody.contains('UploadId')) {
                            uploadId = responseBody.substringBetween('<UploadId>', '</UploadId>');
                        }
                        UploadMultipartDetails multipartDetail = new UploadMultipartDetails();
                        multipartDetail.uploadId = uploadId;
                        multipartDetail.lengthOfFile = lengthOfFile;
                        multipartDetail.filename = fileName;
                        multipartDetail.fileExtension = attach.FileExtension;
                        multipartDetail.attach = attach;

                        uploadMultipart(multipartDetail);
                    } else {
                        Response_Handler.store_Callout_Response(res, 'AwsUploader', 'execute');
                        mailMessage(res.getStatusCode());
                        System.debug('Error during large file upload initiation: ' + res.getStatusCode());
                        System.debug('Error during large file upload initiation: ' + res.getBody());

                    }
                }
                }
            }
        } catch (Exception e) {
            System.debug('Something went wrong: ' + e);
        }
    }

    global void finish(Database.BatchableContext bC) {
        // Optionally perform any final actions after batch execution
        System.debug('It is final');
    }


    public static string contentType(string fileType) {
        Switch on fileType.toLowerCase() {
            when 'csv' {
                return 'application/vnd.ms-excel';
            }
            when 'docx' {
                return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            }
            when 'wav' {
                return 'audio/wav';
            }
            when 'pdf' {
                return 'application/pdf';
            }
            when 'png' {
                return 'image/png';
            }
            when 'xls' {
                return 'application/vnd.ms-excel';
            }
            when else {
                return 'image/jpeg';
            }
        }
    }

    @AuraEnabled
    public static void emailUser(String message) {
        User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String subject = 'Issue in uploading file to AWS';
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { currentUser.Email });
        mail.setSubject(subject);
        mail.setPlainTextBody(message);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    public static void mailMessage(Integer code){
        System.debug('This is status code --->'+code);
        if (code == 400) {
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have noticed an issue while attempting to upload the file ' + awsFullFileName + ' to AWS.\n\n' +
                   'To resolve this issue, please ensure that your credentials are correct. If the problem persists, try the following steps:\n\n' +
                   '1. Remove the existing AWS connection.\n' +
                   '2. Reconnect to AWS.\n\n' +
                   'These steps should help resolve the issue. If you continue to experience difficulties, please feel free to contact our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 401) {
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have noticed an issue while attempting to upload the file ' + awsFullFileName + ' to AWS.\n\n' +
                   'To resolve this issue, please follow these steps to reconnect:\n\n' +
                   '1. Remove the existing AWS connection.\n' +
                   '2. Reconnect to AWS.\n\n' +
                   'These steps should help re-establish the connection. If you continue to experience difficulties, please don\'t hesitate to reach out to our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 403){
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We encountered an issue while attempting to upload the file ' + awsFullFileName + ' to AWS. ' +
                   'It appears that you do not have the necessary permissions to complete this upload.\n\n' +
                   'To resolve this issue, please check the following:\n\n' +
                   '1. Ensure that you have the correct permissions to upload files to the specified AWS folder.\n' +
                   '2. Verify that your AWS account has the appropriate access rights.\n\n' +
                   'If you face any issue you can use NAMED CREDENTIAL. \n'+
                   'If you continue to experience difficulties, please don\'t hesitate to reach out to our support team for further assistance.\n\n' +
                   'Thank you for your attention to this matter.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
        else if (code == 404){
            String emailBody = 'Dear ' + UserInfo.getName() + ',\n\n' +
                   'We have encountered a connection error (404 - File Not Found) while attempting to access your AWS.\n\n' +
                   'This error indicates that the file or resource you are trying to access may not exist or could not be found. To resolve this issue, please try the following steps:\n\n' +
                   '1. Verify that the file or resource exists in your AWS.\n' +
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
                   'We have encountered a server error (500 - Internal Server Error) while attempting to upload your file '+ awsFullFileName +' to AWS. This error typically indicates a problem with our server or the service.\n\n' +
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
                   'We have encountered error with code: '+ code + 'while attempting to upload your file '+ awsFullFileName +' to AWS. This error typically indicates a problem with our server or the service.\n\n' +
                   'To resolve this issue, please try the following:\n\n' +
                   '1. Remove the existing AWS connection.\n' +
                   '2. Reconnect to AWS.\n\n' +
                   'If the problem persists after following these steps, please feel free to contact our support team for further assistance.\n\n' +
                   'Thank you for your cooperation.\n\n' +
                   'Best regards,\n' +
                   'DocGenius';

            emailUser(emailBody);
        }
    }


    public static string createAuthHeader(SignatureDetails parameters) {
        System.debug('sign input-->'+ parameters.contentType + parameters.filename + parameters.formatedDateString + parameters.fileExtension + parameters.methodName + parameters.bucketName + parameters.awsKey + parameters.awsSecret);
        string auth;
        string stringToSign = parameters.methodName + '\n\n' + contentType(parameters.fileExtension) + '\n' + parameters.formatedDateString + '\n/' + parameters.bucketName + '/' + parameters.filename.toLowerCase() + '.' + parameters.fileExtension.toLowerCase();
        Blob mac = Crypto.generateMac('HMACSHA1', Blob.valueOf(stringToSign), Blob.valueOf(parameters.awsSecret));
        string sig = EncodingUtil.base64Encode(mac);
        auth = 'AWS' + ' ' + parameters.awsKey + ':' + sig;
        // System.debug('This is signature -->'+auth);
        return auth;
    }

    public static Integer getLengthOfFile(Blob versionDataBlob) {
        return EncodingUtil.base64Encode(versionDataBlob).length();
    }

    public static void uploadObject( String filename, String fileExtension, Blob body) {
        try {
            String formatedDateString = DateTime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss z');
            String endpoint;
            String authHeader;
            String timestamp = DateTime.now().format('yyyyMMddHHmmss');
            String uniqueFilename = filename.replace(' ', '%20') + '_' + timestamp + '.' + fileExtension;
            if(namedCredential != ''){
                System.debug('Named');
                 endpoint = 'callout:'+ namedCredential +'/'+ uniqueFilename;
            }
            else{
                SignatureDetails sigDetail = new SignatureDetails();
                sigDetail.contentType = '';
                sigDetail.filename = filename.replace(' ', '%20') + '_' + timestamp;
                sigDetail.formatedDateString = formatedDateString;
                sigDetail.fileExtension = fileExtension;
                sigDetail.methodName = 'PUT';
                sigDetail.bucketName = bucket;
                sigDetail.awsKey = key;
                sigDetail.awsSecret = secret;
                 authHeader = createAuthHeader(sigDetail);
                 endpoint = 'https://' + bucket + '.s3.amazonaws.com/' + uniqueFilename;
            }

            HttpRequest reqObj = new HttpRequest();
            reqObj.setMethod('PUT');
            reqObj.setBodyAsBlob(body);
            reqObj.setEndpoint(endpoint);
            System.debug(endpoint);
            reqObj.setHeader('Date', formatedDateString);
            reqObj.setHeader('Content-Type', contentType(fileExtension.toLowerCase()));
            if(namedCredential == ''){
                System.debug('checkpoint of named credential');
                reqObj.setHeader('Host', bucket + '.' + 's3.amazonaws.com');
                reqObj.setHeader('Authorization', authHeader);
                reqObj.setHeader('Connection', 'keep-alive');
                reqObj.setHeader('ACL', 'public-read');
            }
            Http httpObj = new Http();
            HTTPResponse resObj = httpObj.send(reqObj);

            if (resObj.getStatusCode() == 200 || resObj.getStatusCode() == 201) {
                System.debug('Successfully uploaded to AWS');
            } else {
                Response_Handler.store_Callout_Response(resObj, 'AwsUploader', 'uploadObject');
                mailMessage(resObj.getStatusCode());
                System.debug('Error during small file upload initiation: ' + resObj.getBody());
            }
        } catch (Exception e) {
            System.debug('In the catch block of uploadObject: ' + e.getMessage());
            System.debug('Line number: ' + e.getLineNumber());
            System.debug(e);
        }
    }

    public static void uploadMultipart( UploadMultipartDetails parameters) {
        try {
            Integer chunkSize = 10000000; // 10 MB
            Integer totalChunks = Integer.valueOf(Math.ceil(parameters.lengthOfFile.divide(chunkSize, 10)));
            String presignedUrl = '';
            Integer partNumber = 1;
            
            

            for (Integer i = 0; i < totalChunks; i++) {
                
                Integer chunkStart = i * chunkSize;
                Integer chunkEnd = Math.min((i + 1) * chunkSize - 1, Integer.valueOf(parameters.lengthOfFile) - 1);
                Integer chunkLength = chunkEnd - chunkStart + 1;

                Blob chunkBlob = decodingUtilMethod(parameters.attach.VersionData, chunkStart, chunkSize);
                String formattedDate = DateTime.now().formatGMT('EEE, dd MMM yyyy HH:mm:ss') + ' GMT';
                presignedUrl = 'callout:' + namedCredential + '/' + awsFileName + '?partNumber=' + partNumber + '&uploadId=' + parameters.uploadId;
                ChunkDetails chunkDetail = new ChunkDetails();
                    chunkDetail.url = presignedUrl;
                    chunkDetail.start = chunkStart;
                    chunkDetail.ending = chunkEnd;
                    chunkDetail.body = chunkBlob;
                    chunkDetail.partNumber = partNumber;
                    chunkDetail.fileName = parameters.filename;
                    chunkDetail.fileExtension = parameters.fileExtension;
                    chunkDetail.uploadId = parameters.uploadId;

                if (i == (totalChunks - 1)) {
                    chunkDetail.isLastPart = true;
                    subMethod(chunkDetail);
                } else {
                    chunkDetail.isLastPart = false;
                    subMethod(chunkDetail);
                }
                partNumber++;
            }
        } catch (Exception e) {
            System.debug(e);
            System.debug(e.getLineNumber());
        }
    }

    public static void subMethod(ChunkDetails parameters) {
        HttpRequest request = new HttpRequest();
        request.setMethod('PUT');
        request.setEndpoint(parameters.url);
        request.setBodyAsBlob(parameters.body);
        request.setHeader('Content-Type', 'application/octet-stream');
        // request.setHeader('Date', formattedDate);
        Http http = new Http();
        HTTPResponse response = http.send(request);

        if (response.getStatusCode() == 200 ||response.getStatusCode() == 201) {
            if (parameters.isLastPart) {
                ChunkDetails completeDetail = new ChunkDetails();
                completeDetail.fileName = parameters.fileName;
                completeDetail.fileExtension = parameters.fileExtension;
                completeDetail.uploadId = parameters.uploadId;
                completeDetail.maxPart = String.valueOf(parameters.partNumber);
                completeFile(completeDetail);
            }
        } else {
            Response_Handler.store_Callout_Response(response, 'AwsUploader', 'subMethod');
            mailMessage(response.getStatusCode());
            System.debug('Error during multipart upload: ' + response.getStatus());
        }
    }

    public static Blob decodingUtilMethod(Blob versionDataBlob, Integer chunkStart, Integer chunkSize) {
        return EncodingUtil.base64Decode(encodingUtilMethod(versionDataBlob, chunkStart, chunkSize));
    }

    public static String encodingUtilMethod(Blob versionDataBlob, Integer chunkStart, Integer chunkSize) {
        return EncodingUtil.base64Encode(versionDataBlob).mid(chunkStart, chunkSize);
    }

    public static void completeFile(ChunkDetails parameters) {
        String timestamp = DateTime.now().format('yyyyMMddHHmmss');
        String uniqueFilename = parameters.filename.replace(' ', '%20') + '_' + timestamp + '.' + parameters.fileExtension;
        HttpRequest reqLs = new HttpRequest();
        reqLs.setMethod('GET');
        reqLs.setEndpoint('callout:' + namedCredential + '/' + awsFileName + '?uploadId=' + parameters.uploadId + '&max-parts=' + parameters.maxPart + '&part-number-marker=0');
        

        Http httpLs = new Http();
        HTTPResponse resLs = httpLs.send(reqLs);
        String responseBody = resLs.getBody();

        String etagListStr = '';
        if (responseBody != null && responseBody.contains('UploadId')) {
            etagListStr = responseBody.substringBetween('</IsTruncated>', '</ListPartsResult>');
        }

        Boolean tracker = true;
        Map<String, String> eTagMap = new Map<String, String>();
        while (tracker) {
            String refPartString = etagListStr.substringBetween('<Part>', '</Part>');
            if (refPartString != null && refPartString != '') {
                eTagMap.put(refPartString.substringBetween('<PartNumber>', '</PartNumber>'), refPartString.substringBetween('<ETag>&quot;', '&quot;</ETag>'));
                etagListStr = etagListStr.replace('<Part>' + refPartString + '</Part>', '');
            } else {
                tracker = false;
            }
        }

        HttpRequest reqCmp = new HttpRequest();
        reqCmp.setMethod('POST');
        reqCmp.setEndpoint('callout:' + namedCredential + '/' + awsFileName + '?uploadId=' + parameters.uploadId);
        

        String body = '<CompleteMultipartUpload>';
        for (String i : eTagMap.keySet()) {
            body += '<Part><PartNumber>' + i + '</PartNumber><ETag>' + eTagMap.get(i) + '</ETag></Part>';
        }
        body += '</CompleteMultipartUpload>';
        reqCmp.setBody(body);

        Http httpCmp = new Http();
        HTTPResponse resCmp = httpCmp.send(reqCmp);

        if (resCmp.getStatusCode() == 200 || resCmp.getStatusCode() == 201) {
            System.debug('Multipart upload completed successfully');
        } else {
            Response_Handler.store_Callout_Response(resCmp, 'AwsUploader', 'completeFile');
            mailMessage(resCmp.getStatusCode());
            System.debug('Error completing multipart upload: ' + resCmp.getStatus());
            System.debug('Error completing multipart upload: ' + resCmp.getBody());

        }
    }

    public class SignatureDetails {
        @AuraEnabled public String contentType { get; set; }
        @AuraEnabled public String filename { get; set; }
        @AuraEnabled public String formatedDateString { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public String methodName { get; set; }
        @AuraEnabled public String bucketName { get; set; }
        @AuraEnabled public String awsKey { get; set; }
        @AuraEnabled public String awsSecret { get; set; }
    }

    public class UploadMultipartDetails {
        @AuraEnabled public String uploadId { get; set; }
        @AuraEnabled public Decimal lengthOfFile { get; set; }
        @AuraEnabled public String filename { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public ContentVersion attach { get; set; }
    }

    public class ChunkDetails {
        @AuraEnabled public String url { get; set; }
        @AuraEnabled public Integer start { get; set; }
        @AuraEnabled public Integer ending { get; set; }
        @AuraEnabled public Blob body { get; set; }
        @AuraEnabled public Integer partNumber { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public Boolean isLastPart { get; set; }
        @AuraEnabled public String uploadId { get; set; }
        @AuraEnabled public String maxPart { get; set; }

    }
}