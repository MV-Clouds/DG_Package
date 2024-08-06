public class Response_Handler {
    public static void store_Callout_Response(HttpResponse res,String classname, String methodname) {
        try{
            API_Responses__c response = new API_Responses__c();
            response.Response_Body__c = res.getBody();
            response.Response_Status_Code__c = String.valueOf(res.getStatusCode());
            response.Class_Name__c = classname;
            response.Method_Name__c = methodname;
        
            if(Schema.sObjectType.API_Responses__c.isCreateable()){
                insert response;
            }
            
        } 
        catch (Exception error) {
            system.debug('response in Store_Exception >> '+ error);
        }
    } 
    
}