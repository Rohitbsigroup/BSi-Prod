/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         25/11/2011
* Description:  Main Trigger that handles all events for OpportunitySite.
* Changes:      31/07/14 RJ - Added After Update event       
**/
trigger OpportunitySiteTrigger on OpportunitySite__c (before insert, before update, after insert, after update, after delete) {

	OpportunitySiteTriggerHandler handler = new OpportunitySiteTriggerHandler(Trigger.isExecuting, Trigger.size);

	// AFTER INSERT
	if(Trigger.isInsert && Trigger.isAfter){
		handler.OnAfterInsert(Trigger.new);
	} 
	// AFTER UPDATE
	else if(Trigger.isUpdate && Trigger.isAfter){
		handler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
	}
	// AFTER DELETE
	else if(Trigger.isDelete && Trigger.isAfter){
		handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
	}
	// BEFORE INSERT
	else if(Trigger.isInsert && Trigger.isBefore){
		handler.BeforeInsert(Trigger.new);
	}
	// BEFORE UPDATE
	else if(Trigger.isUpdate && Trigger.isBefore){
		handler.BeforeUpdate(Trigger.new, Trigger.oldMap);
	}
}