/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         09/11/2011
* Description:  Apex Component that displays all the past activities of
*				a given object as a redable simple text list.
*
*       
**/
public with sharing class ActivityHistoryController {
	
	public transient List<Task> 	history		= null;
	public String		objectID	{get; set;}
	public String		taskID		{get; set;}
 	
	public List<Task> getHistory() {
		if (history == null) {
			// Query for all related tasks
 			history = 	[SELECT Id, Subject, Description, Type, ActivityDate, OwnerId, Owner.Name FROM Task 
					 	WHERE ((WhatId =:objectID AND WhatId <> null ) OR (WhoId =:objectID AND WhoId <> null) OR (AccountId =:objectID AND AccountId <> null)) 
					 	AND (ActivityDate <=:Date.today() OR isClosed = true) AND Id <>:taskID  
					 	order by ActivityDate desc];	 				 	
        } 

		return history;
	}
	
	public ActivityHistoryController() {
		//showList = true;
	} 
}