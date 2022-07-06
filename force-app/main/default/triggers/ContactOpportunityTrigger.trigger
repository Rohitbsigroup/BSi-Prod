/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         05/01/2012
* Description:  Main Trigger that handles all events for ContactOpportunity (Custom Contact Roles).
*       
**/
trigger ContactOpportunityTrigger on Contact_Opportunity__c (before delete, before insert, before update) {
	
	ContactOpportunityTriggerHandler handler = new ContactOpportunityTriggerHandler(Trigger.isExecuting, Trigger.size);
	
	// BEFORE INSERT
	if (Trigger.isInsert && Trigger.isBefore) {
		handler.OnBeforeInsert(Trigger.new);
	} 
	// BEFORE UPDATE
	else if (Trigger.isUpdate && Trigger.isBefore) {
		handler.OnBeforeUpdate(Trigger.new,Trigger.oldMap);
	}
	// BEFORE DELETE
	else if (Trigger.isDelete && Trigger.isBefore){
		handler.OnBeforeDelete(Trigger.old,Trigger.oldMap);
	}
}