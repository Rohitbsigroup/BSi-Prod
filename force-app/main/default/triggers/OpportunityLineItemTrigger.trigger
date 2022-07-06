/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         07/12/2011
* Description:  Main Trigger that handles all events for OpportunityLineItem.
*       
**/
trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert, after update, after delete, after undelete, before delete) {
	
	OpportunityLineItemTriggerHandler handler = new OpportunityLineItemTriggerHandler(Trigger.isExecuting, Trigger.size);
	
	bg_OpportunityUtils.CalculateEventRevenue(trigger.oldMap,trigger.newMap,Trigger.isDelete,Trigger.isUpdate);

	// AFTER INSERT
	if(Trigger.isInsert && Trigger.isAfter){
		handler.OnAfterInsert(Trigger.new);
	}

	// AFTER UPDATE
	if(Trigger.isUpdate && Trigger.isAfter){
		handler.onAfterUpdate(Trigger.oldMap, Trigger.newMap);
	}

	// AFTER DELETE
	else if(Trigger.isDelete && Trigger.isAfter){
		handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
	}
	
	// BEFORE DELETE
	if (Trigger.isDelete && Trigger.isBefore) {
		handler.OnBeforeDelete(Trigger.old);
	}	
}