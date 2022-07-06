trigger OpportunityTrigger on Opportunity (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

	OpportunityTriggerHandler handler = new OpportunityTriggerHandler(Trigger.isExecuting, Trigger.size);
	
	// BEFORE INSERT
	if (Trigger.isInsert && Trigger.isBefore) {
		handler.OnBeforeInsert(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
	}
	
	// BEFORE UPDATE
	if (Trigger.isUpdate && Trigger.isBefore) {
		handler.OnBeforeUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
	}
	
	// AFTER UPDATE
	if (Trigger.isUpdate && Trigger.isAfter) {
		handler.OnAfterUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
	}
	
	// before UPDATE
	if (Trigger.isDelete && Trigger.isBefore) {
		handler.OnBeforeDelete(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
	}
}