/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         11/11/2011
* Description:  Main Trigger that handles all events for Lead.
*       
**/
trigger LeadTrigger on Lead (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	LeadTriggerHandler handler = new LeadTriggerHandler(Trigger.isExecuting, Trigger.size);
	
	// BEFORE INSERT
	if(Trigger.isInsert && Trigger.isBefore){
		handler.OnBeforeInsert(Trigger.new);
	}
	// AFTER INSERT
	else if(Trigger.isInsert && Trigger.isAfter){
		handler.OnAfterInsert(Trigger.new);
	}
	// BEFORE UPDATE
	else if(Trigger.isUpdate && Trigger.isBefore){
		handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.newMap, Trigger.oldMap);
	}
	// AFTER UPDATE
	else if(Trigger.isUpdate && Trigger.isAfter){
		handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.newMap);
	// AFTER DELETE	
	}
	else if(Trigger.isDelete && Trigger.isAfter){
		handler.OnAfterDelete(Trigger.old, Trigger.oldMap);	
	}

}