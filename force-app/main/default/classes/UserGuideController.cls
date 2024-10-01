public without sharing class UserGuideController {



    @AuraEnabled
    public static List<Knowledge__kav> getAllUserGuides(){
        try {
            List<Knowledge__kav> faqs = [SELECT Id, Title, UrlName, User_Guide_Content__c,User_Guide_Logo__c ,User_Guide_Category__c FROM Knowledge__kav WHERE RecordType.Name = 'User Guide' ORDER BY User_Guide_Category__c LIMIT 50000];
            
            return faqs;
        } catch (Exception e) {
            system.debug('exception in getTempalaterecords : ' +  e.getMessage() +'\n'+ 'Line Number : ' + e.getLineNumber());
            return null;
        }
    }
    
}