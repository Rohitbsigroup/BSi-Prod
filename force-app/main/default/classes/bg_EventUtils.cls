/********************************************************************
 * bg_EventUtils
 *
 * Utility methods to support event functions
 * 
 * Author: Kieran Maguire
 * Created: 20/11/2014
 * Changes: 
 *
 ********************************************************************/
public class bg_EventUtils 
{
	public static List<Event> GetCloneEventsByOpportunity(Id oppId)
		/*
			Returns a list of all fields from events on an opportunity
		*/
	{
		return new List<Event> ([SELECT AccountId, CurrencyIsoCode, Id, IsAllDayEvent, IsArchived, OwnerId, WhoId, IsRecurrence, CreatedById, CreatedDate, DecisionMakingProcess__c, 
								IsDeleted, Directions__c, ActivityDate, ActivityDateTime, DurationInMinutes, RecurrenceEndDateOnly, EndDateTime, 
								GroupEventType, IsChild, IsGroupEvent, LastModifiedById, LastModifiedDate, Location, Description, MeetingStatus__c, Opportunity_Owner__c, WhatId, 
								ParkingArrangements__c, IsPrivate, IsVisibleInSelfService, RecurrenceActivityId, RecurrenceDayOfMonth, RecurrenceDayOfWeekMask, RecurrenceInstance, RecurrenceInterval, 
								RecurrenceMonthOfYear, RecurrenceTimeZoneSidKey, RecurrenceType, ReminderDateTime, IsReminderSet, 
								ShowAs, RecurrenceStartDateTime, StartDateTime, SubType__c, Subject, SystemModstamp, Type, Type__c, WhoWillBeAtTheMeeting__c 
							FROM Event
							WHERE WhatId = :oppId]);
	}
	
	public static List<Event> CloneEvents(Id oldOppId, Id newOppId)
		/*
			Clones and reparents events from one opportunity to another
		*/
	{	
		List<Event> clonedEvents = new List<Event>();
		for(Event event : GetCloneEventsByOpportunity(oldOppId)){
			Event cloneEvent = event.clone(false, true);
			cloneEvent.WhatId = newOppId;
			clonedEvents.add(cloneEvent);
		}
		return clonedEvents;
	}
}