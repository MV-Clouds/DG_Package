
/*
*********************************************************
Apex Class Name    : Log_Handler
@description       : This class is used for logging the errors and exceptions occurs within the DocGenius App
@author            : Nirbhay Navik
@last Modified     : Kevin Suvagiya - 20 Sep, 2024
*********************************************************
*/
public with sharing class Log_Handler {

/*
*********************************************************
@description     : Method is used to create a exception log record without activity id
@param           : e - {Exception} - the actual exception
@param           : classname - {String} - name of the class in which the error occured
@param           : methodname - {String} - name of the method in which the error occured
@return          : none
********************************************************
*/
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
        
            insert as user error;
            
        } 
        catch (Exception error) {
            store_Exception(error, 'Log_Handler', 'store_Exception');
        }
    } 

/*
*********************************************************
@description     : Method is used to create a exception log record with activity id
@param           : e - {Exception} - the actual exception
@param           : classname - {String} - name of the class in which the error occured
@param           : methodname - {String} - name of the method in which the error occured
@param           : activityId - {String} - Id of the generate document activity Id having information about generation results
@return          : none
********************************************************
*/
    public static void store_Exception(Exception e,String classname, String methodname, String activityId) {
        try{
            MVDG__Exception_Logs__c ex = new MVDG__Exception_Logs__c();
            //Governer Limit of executingQuery 
            String queryLimit = '1. SOQL Queries used / SOQL Queries allowed: ' + Limits.getQueries() + '/' + Limits.getLimitQueries();
            String dMLimit = '2. Number of records queried so far /  Number allowed: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows();
            String dMLState = '3. Number of DML statements used so far / Number allowed: ' +  Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements();   
            String cPUTime = '4. Amount of CPU time (in ms) used so far / CPU usage time (in ms) allowed: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime();
            String calloutLimit = '5. Number of callouts used so far / Number allowed: ' + Limits.getCallouts() + '/' + Limits.getLimitCallouts();
            String heapSize = '6. Amount of Heap size used so far / Heap usage allowed:' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize();
        
            ex.MVDG__Governer_Limits__c = String.format('{0}\n{1}\n{2}\n{3}\n{4}\n{5}',new List<string>{queryLimit, dMLimit,dMLState,cPUTime,calloutLimit,heapSize});
            ex.MVDG__Exception_Message__c = e.getMessage();
            ex.MVDG__Exception_Type__c = e.getTypeName();
            ex.MVDG__Exception_Line_Numer__c = e.getLineNumber();
            ex.MVDG__Exception_Stack_Trace__c = e.getStackTraceString();
            ex.MVDG__Class_Name__c = classname;
            ex.MVDG__Method_Name__c = methodname;
            ex.MVDG__Generate_Document_Activity__c	= activityId;
        
            insert as user ex;
            
        } 
        catch (Exception error) {
            store_Exception(error, 'Log_Handler', 'store_Exception');
        }
    }
    
}