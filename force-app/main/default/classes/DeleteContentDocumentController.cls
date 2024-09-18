/*
*********************************************************
Apex Class Name    : DeleteContentDocumentController
@description       : This class is used to delete the created content document if only external storages are selected or no more use for the content document after the document is uploaded in all the external storages
@author            : Kevin Suvagiya
@last Modified     : Kevin Suvagiya - 17 Sep, 2024
*********************************************************
*/
public with sharing class DeleteContentDocumentController implements Schedulable{
    private String cvIDToDelete;

    public DeleteContentDocumentController(String cvID) {
        cvIDToDelete = cvID;
    }
/*
*********************************************************
@description     : This scheduled method is used to delete content document after 10 min of upload initiated
@param           : cvIDToDelete {String} - Id of the ContentVersion to be deleted
@return          : none
********************************************************
*/
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