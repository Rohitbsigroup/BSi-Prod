/********************************************************************
 * bg_TaskUtils
 *
 * Utility methods to support Task functions
 * 
 * Author: Kieran Maguire
 * Created: 19/11/2014
 * Changes: 
 *
 ********************************************************************/
public class bg_TaskUtils {
	
	public static List<Task> GetCloneTasksByOpportunity(Id opportunityId)
	/*
		Returns a list of all fields of all clone task for that opportunity
	*/
	{	
		return new List<Task>([	SELECT AccountId, Id, IsArchived, OwnerId, CallDurationInSeconds, CallObject, CallDisposition, CallType, IsClosed, WhoId, IsRecurrence, CreatedById, CreatedDate, 
									CurrencyIsoCode, DecisionMakingProcess__c, IsDeleted, Description, Directions__c, ActivityDate, RecurrenceEndDateOnly,
									LastModifiedById, LastModifiedDate, MeetingStatus__c, Opportunity_Owner__c, WhatId, ParkingArrangements__c, 
									Priority, IsVisibleInSelfService, RecurrenceActivityId, RecurrenceDayOfMonth, RecurrenceDayOfWeekMask, RecurrenceInstance, RecurrenceInterval, RecurrenceMonthOfYear, 
									RecurrenceTimeZoneSidKey, RecurrenceType, ReminderDateTime, IsReminderSet, RecurrenceStartDateOnly, Status, SubType__c, Subject, SystemModstamp, 
									Type__c, Type, WhoWillBeAtTheMeeting__c 
								FROM Task
								WHERE WhatId = :opportunityId]);
	}
	
	public static List<Task> CloneTasks(Id oldOppId, Id newOppId) 
	/*
		Clones tasks from the old opportunity to the new one 
	*/
	{ 
		List<Task> clonedTasks = new List<task>();
		for(Task task : GetCloneTasksByOpportunity(oldOppId))
		{
			Task cloneTask = task.clone(false, true);
			cloneTask.WhatId = newOppId;
			clonedTasks.add(cloneTask);
		}
		return clonedTasks;
	}

}