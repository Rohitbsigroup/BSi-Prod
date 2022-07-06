/********************************************************************
 * QuoteTrigger
 *
 * Main Trigger that handles all events for Quote.
 *
 *
 * Author: Richard Jimenez
 * Created: 13-12-2013
 * Changes:
           25/07/16 JA - Changed bu to take old and new map as arguments
 ********************************************************************/
trigger QuoteTrigger on Quote__c (before insert, before update) {
	QuoteTriggerHandler handler = new QuoteTriggerHandler(Trigger.isExecuting, Trigger.size);

	// BEFORE INSERT
	if (Trigger.isInsert && Trigger.isBefore) {
		handler.OnBeforeInsert(Trigger.new);
	}
	// BEFORE UPDATE
	else if (Trigger.isUpdate && Trigger.isBefore) {
		handler.OnBeforeUpdate(Trigger.newMap, Trigger.oldMap);
	}
}