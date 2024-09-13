public with sharing class DeleteGoogleDocument implements Schedulable{
    public String templateId;
    public String documentId;
    public static MVDG__AuthProviderSettings__c authProvider;


    public DeleteGoogleDocument(String templateId, String documentId) {
        this.templateId = templateId;
        this.documentId = documentId;
    }

    public void execute(SchedulableContext sc) {
        try {
            System.debug('Schedule class run');
            System.debug('TemplateId: ' + templateId);
            System.debug('DocumentId: ' + documentId);
            deleteDocument(documentId);

        } catch (Exception e) {
            Log_Handler.store_Exception(e, 'DeleteGoogleDocument', 'execute');
        }

    }

    @Future(callout=true)
    public static void deleteDocument(String googleDocId) {
        try {
            authProvider = getAuthProviderSettings();
            String endpoint = 'https://www.googleapis.com/drive/v3/files/' + googleDocId;
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('DELETE');
            request.setHeader('Authorization', 'Bearer ' + authProvider.MVDG__access_token__c);
            Http http = new Http();
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 204) {
                //document deleted
                System.debug('ResponseBody of delete google doc=>' + response.getStatusCode());
            } else if (response.getStatusCode() == 401) {
                refreshAccessToken();
                deleteDocument(googleDocId);
            }
            System.debug('ResponseBody of delete google doc=>' + response.getStatusCode());

        } catch (Exception e) {
            
            System.debug('Error In deleteGoogleDoc ==> ' + e.getMessage() + e.getLineNumber());
        } finally {
            if(authProvider.SetupOwnerId == UserInfo.getOrganizationId()){
                authProvider.SetupOwnerId = UserInfo.getOrganizationId();
                if (Schema.sObjectType.MVDG__AuthProviderSettings__c.isCreateable() && Schema.sObjectType.MVDG__AuthProviderSettings__c.isUpdateable()) {
                    upsert authProvider;
                }
            } else {    
                if (Schema.sObjectType.MVDG__AuthProviderSettings__c.isUpdateable()) {
                    update authProvider;
                }
            }
        }
    }

    public static String refreshAccessToken() {
        try {
            List<AuthProviderSetup__mdt> mdata = AuthProviderSetup__mdt.getAll().values();
            System.debug('Refresh Access token');
            String endpoint = 'https://oauth2.googleapis.com/token';
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            // request.setBody('refresh_token=' + authProvider.MVDG__refresh_token__c + '&client_id=' + authProvider.MVDG__ClientId__c + '&client_secret=' + authProvider.MVDG__ClientSecret__c + '&grant_type=refresh_token');
            request.setBody('refresh_token=' + authProvider.MVDG__refresh_token__c + '&client_id=' + mdata[0].CID__c + '&client_secret=' + mdata[0].CSEC__c + '&grant_type=refresh_token');
            Http http = new Http();
            HttpResponse response = http.send(request);
            System.debug('Response of refreshAccessToken: ' + response.getBody());
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String newToken = (String) jsonResponse.get('access_token');
                if (newToken != null) {
                    authProvider.MVDG__access_token__c = newToken;
                }
                return newToken;
            }
            System.debug('Token refresh failed. Status Code: ' + response.getStatusCode());
        } catch (Exception e) {
            System.debug('Error In refreshAccessToken ==> ' + e.getMessage() + e.getLineNumber());
        }
        return null;
    }

    public static MVDG__AuthProviderSettings__c getAuthProviderSettings() {
        List<MVDG__AuthProviderSettings__c> aps = new List<MVDG__AuthProviderSettings__c>();
        aps = [SELECT Id, IsDeleted, Name, SetupOwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, MVDG__ClientId__c, MVDG__ClientSecret__c, MVDG__LinkedDate__c, MVDG__WorkingStatus__c, MVDG__access_token__c, MVDG__email__c, MVDG__photolink__c, MVDG__refresh_token__c, MVDG__username__c FROM MVDG__AuthProviderSettings__c WHERE SetupOwnerId =: UserInfo.getUserId()];
        if (aps.size() > 0) {
            System.debug('Inside user');
            return aps[0];
        }
        System.debug('Inside org');
        return MVDG__AuthProviderSettings__c.getOrgDefaults();
    }
}