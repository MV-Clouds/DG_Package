public with sharing class DeleteContentDocumentController implements Schedulable{
    private String cvIDToDelete;

    public DeleteContentDocumentController(String cvID) {
        cvIDToDelete = cvID;
    }

    public void execute(SchedulableContext ctx) {
        try{
            List<ContentDocument> contentDocuments = new List<ContentDocument>();
            contentDocuments = [SELECT id FROM ContentDocument WHERE LatestPublishedVersionId =: cvIDToDelete WITH SECURITY_ENFORCED];
            if(contentDocuments.size() > 0){
                delete contentDocuments[0];
                database.emptyRecycleBin(contentDocuments[0]); 
            }
        }catch(Exception e){
            Log_Handler.store_Exception(e, 'DeleteContentDocumentController', 'execute');
        }
    }
}