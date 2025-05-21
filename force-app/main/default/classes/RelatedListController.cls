public with sharing class RelatedListController {
    @AuraEnabled
    public static List<SObject> getRelatedRecords(Id RelatedRecordId, String objectname, String relationshipName) {
        try {
            
            System.debug(relationshipName);
            System.debug(objectname);
            System.debug(RelatedRecordId);
            String query = 'SELECT (SELECT Id, Name FROM '+ relationshipName + ') FROM '+ objectname +' WHERE ID = \'' + RelatedRecordId + '\' WITH USER_MODE';
            List<SObject> records = Database.query(query);

            if (!records.isEmpty()) {
                SObject parentRecord = records[0];
                List<SObject> children = parentRecord.getSObjects(relationshipName);
                if (children != null) {
                    return (List<SObject>)children;
                }
            }
    
            return null;
        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'RelatedListController', 'getRelatedRecords');
            return null;
        }
    }
}
