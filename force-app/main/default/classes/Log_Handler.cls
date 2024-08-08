public class Log_Handler {


    public static void store_Exception(Exception e,String classname, String methodname) {
        try{
            MVDG__Exception_Logs__c error = new MVDG__Exception_Logs__c();

            //Governer Limit of executingQuery 
            String queryLimit = '1. SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
            String dMLimit = '2. Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
            String dMLState = '3. Number of DML statements used so far / Number allowed: ' +  Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();   
            String cPUTime = '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();
            String calloutLimit = '5. Number of callouts used so far / Number allowed: ' + Limits.getCallouts() + '/' + Limits.getLimitCallouts();
            String heapSize = '6. Amount of Heap size used so far / Heap usage allowed:' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize();
        
            error.MVDG__Governer_Limits__c = String.format('{0}\n{1}\n{2}\n{3}\n{4}\n{5}',new List<string>{queryLimit, dMLimit,dMLState,cPUTime,calloutLimit,heapSize});
            error.MVDG__Exception_Message__c = e.getMessage();
            error.MVDG__Exception_Type__c = e.getTypeName();
            error.MVDG__Exception_Line_Numer__c = e.getLineNumber();
            error.MVDG__Exception_Stack_Trace__c = e.getStackTraceString();
            error.MVDG__Class_Name__c = classname;
            error.MVDG__Method_Name__c = methodname;
        
            if(Schema.sObjectType.MVDG__Exception_Logs__c.isCreateable()){
                insert error;
            }
            
        } 
        catch (Exception error) {
            system.debug('error in Store_Exception >> '+ error);
        }
    } 
    
}