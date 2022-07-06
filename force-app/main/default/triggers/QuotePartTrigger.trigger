/********************************************************************
 * QuotePartTrigger
 *
 * Main Trigger that handles all events for QuotePart.
 * 
 * 
 * Author: Richard Jimenez
 * Created: 04-12-2013
 * Changes: NF 03-11-2014: Added after insert and after update 
 						   handler calls
 ********************************************************************/
trigger QuotePartTrigger on Quote_Part__c (before insert, before update, after delete, after insert, after update) {
	
	QuotePartTriggerHandler handler = new QuotePartTriggerHandler(Trigger.isExecuting, Trigger.size);
	
	// AFTER INSERT
	if(Trigger.isInsert && Trigger.isAfter){
		handler.OnAfterInsert(Trigger.new, Trigger.newMap);
	} 
	// AFTER DELETE
	//else if(Trigger.isDelete && Trigger.isAfter){
	//	handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
		//system.debug('QuotePartTrigger:OnAfterDelete: ' + Trigger.old);
	//}
	// AFTER UPDATE
	else if(Trigger.isUpdate && Trigger.isAfter){
		handler.OnAfterUpdate(Trigger.new, Trigger.oldMap);
	}
	// BEFORE INSERT
	//else 
	else if(Trigger.isInsert && Trigger.isBefore){
		handler.OnBeforeInsert(Trigger.new);
	}
	// BEFORE UPDATE
	else if(Trigger.isUpdate && Trigger.isBefore){
		handler.OnBeforeUpdate(Trigger.new, Trigger.oldMap);
	}
}