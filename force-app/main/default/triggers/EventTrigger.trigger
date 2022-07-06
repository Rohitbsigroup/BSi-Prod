/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         28/11/2011
* Description:  Main Trigger that handles all events for Event.
*       
**/
trigger EventTrigger on Event (after insert) {
	
	EventTriggerHandler handler = new EventTriggerHandler(Trigger.isExecuting, Trigger.size);
	
	// AFTER INSERT
	if(Trigger.isInsert && Trigger.isAfter){
		handler.OnAfterInsert(Trigger.new);
	} 
}