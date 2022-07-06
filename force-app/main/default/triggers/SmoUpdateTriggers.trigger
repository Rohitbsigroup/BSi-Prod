trigger SmoUpdateTriggers on SMO_Update__c (after insert, after update)
// Not currently handling after delete, after undelete, before delete, before insert, before update
{
	// Instantiate handler
	SmoUpdateTriggerHandler handler = new SmoUpdateTriggerHandler(Trigger.isExecuting, Trigger.size);

	// Before insert 
 	//if(Trigger.isInsert && Trigger.isBefore)
 	//{
  	//	handler.OnBeforeInsert(Trigger.new);
 	//}

	// After insert
 	if(Trigger.isInsert && Trigger.isAfter)
 	{
  		handler.OnAfterInsert(Trigger.new, Trigger.newMap);
 	}
 
 	// Before update
 	//else if(Trigger.isUpdate && Trigger.isBefore)
 	//{
  	//	handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.newMap);
 	//}
 
 	// After update
 	else if(Trigger.isUpdate && Trigger.isAfter)
 	{
  		handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.newMap);
 	}
 
 	// Before delete
 	//else if(Trigger.isDelete && Trigger.isBefore)
 	//{
  	//	handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
 	//}
 	
 	// After delete
 	//else if(Trigger.isDelete && Trigger.isAfter)
 	//{
  	//	handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
 	//}
 
 	// After undelete
	//else if(Trigger.isUnDelete)
	//{
  	//	handler.OnUndelete(Trigger.new); 
 	//}
}