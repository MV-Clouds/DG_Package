public with sharing class UploadController {

    @AuraEnabled
    public static void uploadToGoogleDrive(Id cvid) {
        Database.executeBatch(new GoogleDriveUploader(cvid));
    }

    @AuraEnabled
    public static void uploadToAWS(Id cvid) {
        Database.executeBatch(new AwsUploader(cvid));
    }

    @AuraEnabled
    public static void uploadToOneDrive(Id cvid) {
        Database.executeBatch(new OneDriveUploader(cvid));
    }

    @AuraEnabled
    public static void uploadToDropBox(Id cvid) {
        Database.executeBatch(new DropboxUploader(cvid));
    }
}