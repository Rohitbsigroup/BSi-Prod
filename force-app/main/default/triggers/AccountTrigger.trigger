/**
*
* Author:       Carmine Barbuto
* Company:      Tquila
* Date:         10/01/2012
* Description:  Main Trigger that handles all events for Account.
*       
**/
trigger AccountTrigger on Account (after insert, before insert, before update) {
    
    AccountTriggerHandler handler = new AccountTriggerHandler(Trigger.isExecuting, Trigger.size);
    
    // BEFORE INSERT
    if (Trigger.isInsert && Trigger.isBefore) {
        handler.OnBeforeInsert(Trigger.new);
    }
    // AFTER INSERT
    if (Trigger.isInsert && Trigger.isAfter) {
        handler.OnAfterInsert(Trigger.new, Trigger.newMap);
    }  
    // BEFORE UPDATE
    else if (Trigger.isUpdate && Trigger.isBefore) {
        if (!Utility.lockAccountTrigger) handler.OnBeforeUpdate(Trigger.new);
    }
}