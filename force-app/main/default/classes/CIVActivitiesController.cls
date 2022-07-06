/********************************************************************
 * CIVActivitiesController
 *
 * Controller class for CIV Activities component
 * 
 * 
 * Author: Richard Jimenez
 * Created: 10-09-2014
 * Changes: 
 ********************************************************************/
public with sharing class CIVActivitiesController {

	public sObject record {get; set;}

	public string AccountId {get; set;}
	public string ContactId {get; set;}

	public boolean showLeadActivities {get; set;}
	public boolean showContactActivities {get; set;}
	public boolean showAccountActivities {get; set;}
	public boolean showOpportunityActivities {get; set;}
	
	public boolean showTasks {get; set;}
	public boolean showEvents {get; set;}

	private integer totalRecords {get; set;}
	public final static integer MAX_ROWS = 5; 
	public integer pageNumber = 1;

	private string orderBy;
	public boolean orderAsc {get; set;}

	public integer lastDays {get; set;}
	
	public CIVActivitiesController() {
		if(!isInitialised) { Initialise(); }
	}
	
	private boolean isInitialised = false;
	private void Initialise() {
		showTasks = true;
		showEvents = true;

        orderAsc = false;
        orderBy = bg_CIVUtils.SORTCOL_DUEDATE;
        sortColumnName = orderBy;
		showLeadActivities = false;
		showAccountActivities = false;		
		showContactActivities = true;
		showOpportunityActivities = false;		
		lastDays = 7;

		isInitialised = true;		
	}

	public list<bg_CIVUtils.ActivityWrapper> getRecords() {
		if(!isInitialised) { Initialise(); }
		list<bg_CIVUtils.ActivityWrapper> activitiyRecords = new list<bg_CIVUtils.ActivityWrapper>();

		integer objectCount = 0;
		if(showEvents) { objectCount++; }
		if(showTasks) { objectCount++; }

		// Calculate record limit
		integer recordLimit = objectCount * pageNumber * MAX_ROWS;

		set<Id> parentIds = new set<Id>();
		parentIds.add(record.Id);
		
		if(showLeadActivities) {
			parentIds.addAll(bg_CIVLinkUtils.GetLinkMap(record.Id, Lead.getSObjectType().getDescribe().getName()).keySet());
		}
		if(showContactActivities) {
			parentIds.addAll(bg_CIVLinkUtils.GetLinkMap(record.Id, Contact.getSObjectType().getDescribe().getName()).keySet());
		}
		if(showAccountActivities) {
			parentIds.addAll(bg_CIVLinkUtils.GetLinkMap(record.Id, Account.getSObjectType().getDescribe().getName()).keySet());
		}
		if(showOpportunityActivities) {
			parentIds.addAll(bg_CIVLinkUtils.GetLinkMap(record.Id, Opportunity.getSObjectType().getDescribe().getName()).keySet());
		}
				
		// Activities in the last 7 days
		date startDate = (lastDays<0?date.today().addDays(lastDays):date.today());
		date endDate = (lastDays<0?date.today():date.today().addDays(lastDays));
		
		system.debug('parentIds: ' + parentIds);
		system.debug('showTasks: ' + showTasks);
		
		if(showTasks) {
			list<Task> tasks = bg_CIVUtils.GetTasks(recordLimit, parentIds, startDate, endDate);
			system.debug('tasks: ' + tasks);
			for(Task t : tasks) {
				activitiyRecords.add(bg_CIVUtils.CreateActivityWrapper(t, orderBy, orderAsc));
			}
		}

		if(showEvents) {
			list<Event> events = bg_CIVUtils.GetEvents(recordLimit, parentIds, startDate, endDate);
			for(Event e : events) {
				activitiyRecords.add(bg_CIVUtils.CreateActivityWrapper(e, orderBy, orderAsc));
			}
		}

		list<bg_CIVUtils.ActivityWrapper> activitiyRecordsTmp = new list<bg_CIVUtils.ActivityWrapper>();
		integer startPos = (MAX_ROWS * (pageNumber-1));
		integer endPos = (MAX_ROWS * pageNumber);
		totalRecords = activitiyRecords.size();

		activitiyRecords.sort();
		for(integer i = startPos ; i < endPos; i++) {
			if(i >= totalRecords) { break; }
			activitiyRecordsTmp.add(activitiyRecords.get(i));
		}

		return activitiyRecordsTmp;
	}

    // returns the previous page of records
    public PageReference previous() {
		pageNumber--;
        return null;
    }

	public boolean hasPrevious {
		get {
			return (pageNumber > 1);
		}
	}
	
	public boolean hasNext {
		get {
			return (totalRecords > (MAX_ROWS * pageNumber));
		}
	}
	
    // returns the next page of records
    public PageReference next() {
		pageNumber++;
        return null;
    }
    
    public PageReference Refresh() {
		pageNumber = 1;
        return null;
    }

    public string sortColumnName {get; set;}
    public PageReference sortResults() {
    	if(sortColumnName == orderBy) {
    		orderAsc = !orderAsc;
    	} else {
    		orderBy = sortColumnName;
    		orderAsc = true;
    	}
        return null;
    }      	
}