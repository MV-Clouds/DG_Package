public class Response_Handler {
    public static void store_Callout_Response(HttpResponse res,String classname, String methodname) {
        try{
            MVDG__API_Responses__c response = new MVDG__API_Responses__c();
            response.MVDG__Response_Body__c = res.getBody();
            response.MVDG__Response_Status_Code__c = String.valueOf(res.getStatusCode());
            response.MVDG__Class_Name__c = classname;
            response.MVDG__Method_Name__c = methodname;
        
            if(Schema.sObjectType.MVDG__API_Responses__c.isCreateable()){
                insert response;
            }
            
        } 
        catch (Exception error) {
            system.debug('response in Store_Exception >> '+ error);
        }
    } 
    
}