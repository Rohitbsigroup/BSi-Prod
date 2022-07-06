/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         25/11/2011
* Description:  Main Trigger that handles all events for Site.
*       
**/
trigger SiteTrigger on Site__c (before insert, before update, after delete, after insert, after update) {
	
	SiteTriggerHandler handler = new SiteTriggerHandler(Trigger.isExecuting, Trigger.size);
	
	// AFTER INSERT
	if(Trigger.isInsert && Trigger.isAfter){
		handler.OnAfterInsert(Trigger.new);
	} 
	// AFTER DELETE
	else if(Trigger.isDelete && Trigger.isAfter){
		handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
	}
	// AFTER UPDATE
	else if(Trigger.isUpdate && Trigger.isAfter){
		handler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
	}
	// BEFORE INSERT
	else if(Trigger.isInsert && Trigger.isBefore){
		handler.OnBeforeInsert(Trigger.new);
	}
	// BEFORE UPDATE
	else if(Trigger.isUpdate && Trigger.isBefore){
		handler.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
	}
}