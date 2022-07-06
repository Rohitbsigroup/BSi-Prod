/**
*
* Author:       Carmine Barbuto
* Company:      Tquila
* Date:         23/02/2012
* Description:  Main Trigger that handles all events for Contact.
*       
**/
trigger ContactTrigger on Contact (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
	
	ContactTriggerHandler handler = new ContactTriggerHandler(Trigger.isExecuting, Trigger.size);
    
    // BEFORE INSERT
    if (Trigger.isInsert && Trigger.isBefore) {
        handler.OnBeforeInsert(Trigger.new);
    }
    // BEFORE UPDATE
    else if (Trigger.isUpdate && Trigger.isBefore) {
        handler.OnBeforeUpdate(Trigger.new);
    }
    
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}