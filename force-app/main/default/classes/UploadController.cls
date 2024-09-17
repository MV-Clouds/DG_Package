public with sharing class UploadController {

    @AuraEnabled
    public static void uploadToGoogleDrive(Id cvid, Id activityId) {
        Database.executeBatch(new GoogleDriveUploader(cvid, activityId));
    }

    @AuraEnabled
    public static void uploadToAWS(Id cvid, Id activityId) {
        Database.executeBatch(new AwsUploader(cvid, activityId));
    }

    @AuraEnabled
    public static void uploadToOneDrive(Id cvid, Id activityId) {
        Database.executeBatch(new OneDriveUploader(cvid, activityId));
    }

    @AuraEnabled
    public static void uploadToDropBox(Id cvid, Id activityId) {
        Database.executeBatch(new DropboxUploader(cvid, activityId));
    }
}