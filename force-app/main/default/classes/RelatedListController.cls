public with sharing class RelatedListController {
    @AuraEnabled
    public static List<SObject> getRelatedRecords(Id RelatedRecordId, String objectname, String relationshipName, List<String> fieldList) {
        try {
            
            System.debug(relationshipName);
            System.debug(objectname);
            System.debug(RelatedRecordId);
            System.debug(fieldList)
            if(fieldList == null || fieldList.isEmpty()) {
                fieldList = new List<String>{'Name'}; 
            }
            String subFields = String.join(fieldList, ', ');
            System.debug(subFields);
            // Construct dynamic query
            String query = 'SELECT (SELECT ' + subFields + ' FROM ' + relationshipName + ') ' +
                           'FROM ' + objectName + ' WHERE Id = \'' + relatedRecordId + '\' WITH USER_MODE';
                
            System.debug('Dynamic Query: ' + query);
            // Execute and return result
            List<SObject> result = Database.query(query);

            if (!result.isEmpty()) {
                SObject parentRecord = result[0];
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
