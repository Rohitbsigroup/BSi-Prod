/**
*
* Author 		: Prasad J N
* Date			: 22 May 2018 
* Description	: Apex trigger to create c-code profile when a user is created
*
*/
trigger emq_UserTrigger on User (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    
    emq_UserTriggerHandler handler = new emq_UserTriggerHandler();
    
    if(Trigger.isInsert && Trigger.isAfter){
      handler.OnAfterInsert(Trigger.new);
    }
  
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isUpdate && Trigger.isBefore){
        handler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isInsert && Trigger.isBefore){
        handler.onBeforeInsert(Trigger.new, Trigger.oldMap);
    }
}