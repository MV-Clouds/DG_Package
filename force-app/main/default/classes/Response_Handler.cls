public with sharing class Response_Handler{
    public static void store_Callout_Response(HttpResponse res,String classname, String methodname) {
        try{
            MVDG__API_Responses__c response = new MVDG__API_Responses__c();
            response.MVDG__Response_Body__c = res.getBody();
            response.MVDG__Response_Status_Code__c = String.valueOf(res.getStatusCode());
            response.MVDG__Class_Name__c = classname;
            response.MVDG__Method_Name__c = methodname;
        
            if(Schema.sObjectType.MVDG__API_Responses__c.fields.MVDG__Response_Body__c.isCreateable() &&
                Schema.sObjectType.MVDG__API_Responses__c.fields.MVDG__Response_Status_Code__c.isCreateable() &&
                Schema.sObjectType.MVDG__API_Responses__c.fields.MVDG__Class_Name__c.isCreateable() &&
                Schema.sObjectType.MVDG__API_Responses__c.fields.MVDG__Method_Name__c.isCreateable() &&
                Schema.sObjectType.MVDG__API_Responses__c.fields.MVDG__Response_Body__c.isAccessible() &&
                Schema.sObjectType.MVDG__API_Responses__c.fields.MVDG__Response_Status_Code__c.isAccessible() &&
                Schema.sObjectType.MVDG__API_Responses__c.fields.MVDG__Class_Name__c.isAccessible() &&
                Schema.sObjectType.MVDG__API_Responses__c.fields.MVDG__Method_Name__c.isAccessible()
            ){
                insert response;
            }
            
        } 
        catch (Exception error) {
            Log_Handler.store_Exception(error, 'Response_Handler', 'store_Callout_Response');
        }
    } 

    public static void store_All_Callout_Response(List<HttpResponse> httpResponses,String classname, String methodname) {
        try{
            list<MVDG__API_Responses__c> allResponseList = new list<MVDG__API_Responses__c>();
            for (HttpResponse res : httpResponses) {   
                MVDG__API_Responses__c response = new MVDG__API_Responses__c();
                response.MVDG__Response_Body__c = res.getBody();
                response.MVDG__Response_Status_Code__c = String.valueOf(res.getStatusCode());
                response.MVDG__Class_Name__c = classname;
                response.MVDG__Method_Name__c = methodname;

                allResponseList.add(response);
            }
            
            insert as user allResponseList;
        } 
        catch (Exception error) {
            Log_Handler.store_Exception(error, 'Response_Handler', 'store_All_Callout_Response');
        }
    }

    public static void store_All_Callout_Response_Map(Map<String, HttpResponse> httpResponses,String classname) {
        try{

            list<MVDG__API_Responses__c> allResponseList = new list<MVDG__API_Responses__c>();
            for (String responseKey : httpResponses.keySet()) {
                HttpResponse res = httpResponses.get(responseKey);

                MVDG__API_Responses__c response = new MVDG__API_Responses__c();
                response.MVDG__Response_Body__c = res.getBody();
                response.MVDG__Response_Status_Code__c = String.valueOf(res.getStatusCode());
                response.MVDG__Class_Name__c = classname;
                response.MVDG__Method_Name__c = responseKey;

                allResponseList.add(response);
            }
            
            insert as user allResponseList;
        } 
        catch (Exception error) {
            Log_Handler.store_Exception(error, 'Response_Handler', 'store_All_Callout_Response_Map');
        }
    } 
    
}