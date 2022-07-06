/**
* ******************* Change Log *******************
*  PC K2           31-08-18    re-activated the trigger to use before insert and before update 
**/

trigger TrainingEventTriggers on Training_Event__c (before insert, before update){

    // Instantiate handler
    TrainingEventTriggerHandler handler = new TrainingEventTriggerHandler(Trigger.isExecuting, Trigger.size);

    // Before insert 
    if(Trigger.isInsert && Trigger.isBefore){
        handler.onBeforeInsert(Trigger.new);
    }

    // After insert moved to bg_Training_Event_AI
 
    // Before update
    if(Trigger.isUpdate && Trigger.isBefore){
        handler.onBeforeUpdate(Trigger.old, Trigger.oldMap, Trigger.new, Trigger.newMap);
    }
 
    // After update moved to bg_Training_Event_AU
}