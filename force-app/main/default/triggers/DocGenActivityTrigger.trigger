trigger DocGenActivityTrigger on MVDG__Generate_Document_Activity__c (after update) {
    DocGenActivityTriggerHandler handler = new DocGenActivityTriggerHandler();
    if(trigger.isUpdate && trigger.isAfter){
        handler.onAfterUpdate(trigger.new);
    }
}