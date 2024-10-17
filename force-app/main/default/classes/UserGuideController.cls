public without sharing class UserGuideController {



    @AuraEnabled
    public static List<Knowledge__kav> getAllUserGuides(){
        try {
            Id userGuideRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('DocGenius User Guide').getRecordTypeId();
            List<Knowledge__kav> userGuides = [SELECT Id, Title, UrlName, User_Guide_Content__c,User_Guide_Logo__c ,User_Guide_Category__c FROM Knowledge__kav WHERE RecordTypeId =: userGuideRecordTypeId AND PublishStatus = 'Online' ORDER BY User_Guide_Category__c, Title LIMIT 50000];
            
            return userGuides;
        } catch (Exception e) {
            // System.debug('exception in getTempalaterecords : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }
    
}