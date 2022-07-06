/********************************************************************
 * CIVLinkedController
 *
 * Controller class for CIV Linked component
 * 
 * 
 * Author: Richard Jimenez
 * Created: 10-09-2014
 * Changes: 
 ********************************************************************/
public with sharing class CIVLinkedController {

	public sObject record {get; set;}
	public string sourceObjectType {get; set;}	
	public string AccountId {get; set;}
	public string ContactId {get; set;}

	private integer totalRecords {get; set;}
	public boolean showLeads {get; set;}
	public boolean showAccounts {get; set;}
	public boolean showContacts {get; set;}
	public boolean showOpportunities {get; set;}
	
	public integer pageNumber = 1;

	public string selectedObjectType {get; set;}
	public string selectedrecordId {get; set;}
    public boolean refreshPage {get; set;}
	public string selectedAction {get; set;}

	private string orderBy;
	public boolean orderAsc {get; set;}

	private boolean isInitialised = false;
	private void Initialise() {
		/*
			Initialise class variables
		*/
		showLeads = true;
		showAccounts = true;
		showContacts = true;
		showOpportunities = true;
		sourceObjectType = record.getSObjectType().getDescribe().getName();

        orderAsc = true;
        orderBy = bg_CIVUtils.SORTCOL_NAME;
        sortColumnName = orderBy;

		isInitialised = true;	
	}
	
	public list<bg_CIVUtils.LinkedWrapper> getRecords() {
		/*
			Get Records
		*/		
		if(!isInitialised) { Initialise(); }
		
		// Initiase variables
		list<bg_CIVUtils.LinkedWrapper> linkedRecords = new list<bg_CIVUtils.LinkedWrapper>();
		
		// Count objects selected
		integer objectCount = 0;
		if(showAccounts) 		{ objectCount++; }
		if(showContacts) 		{ objectCount++; }
		if(showLeads)    		{ objectCount++; }
		if(showOpportunities)	{ objectCount++; }		

		set<Id> Ids = new set<Id>{contactId, accountId};

		// Calculate record limit
		integer recordLimit = (objectCount * pageNumber * bg_CIVUtils.MAX_ROWS) + 1;
			
		// Get Accounts
		if(showAccounts) {
			map<Id, CIV_Link__c> linkMap = bg_CIVLinkUtils.GetLinkMap(record.Id, Account.getSObjectType().getDescribe().getName());
			set<Id> accountIds = new set<Id>();
			accountIds.addAll(linkMap.keySet());
			accountIds.add(accountId);
			
			list<Account> accounts = bg_CIVUtils.GetLinkedAccounts(record.Id, recordLimit, accountIds);
			for(Account a : accounts) {
				linkedRecords.add(bg_CIVUtils.CreateLinkedWrapper(a, sourceObjectType, Ids, orderby, orderAsc));
			}
		}
		
		// Get Contacts
		if(showContacts) {
			map<Id, CIV_Link__c> linkMap = bg_CIVLinkUtils.GetLinkMap(record.Id, Contact.getSObjectType().getDescribe().getName());
			set<Id> contactIds = new set<Id>();
			contactIds.addAll(linkMap.keySet());
			contactIds.add(contactId);
			
			list<Contact> contacts = bg_CIVUtils.GetLinkedContacts(record.Id, recordLimit, contactIds);
			for(Contact c : contacts) {
				linkedRecords.add(bg_CIVUtils.CreateLinkedWrapper(c, sourceObjectType, Ids, orderby, orderAsc));
			}
		}

		// Get Leads
		if(showLeads) {
			map<Id, CIV_Link__c> linkMap = bg_CIVLinkUtils.GetLinkMap(record.Id, Lead.getSObjectType().getDescribe().getName());
			set<Id> leadIds = new set<Id>();
			leadIds.addAll(linkMap.keySet());
			
			list<Lead> leads = bg_CIVUtils.GetLinkedLeads(record.Id, recordLimit, accountId, contactId, leadIds);
			
			for(Lead l : leads) {
				linkedRecords.add(bg_CIVUtils.CreateLinkedWrapper(l, sourceObjectType, Ids, orderby, orderAsc));
			}
		}
	
		// Get Opportunities
		if(showOpportunities) {
			map<Id, CIV_Link__c> linkMap = bg_CIVLinkUtils.GetLinkMap(record.Id, Opportunity.getSObjectType().getDescribe().getName());
			set<Id> oppIds = new set<Id>();
			oppIds.addAll(linkMap.keySet());

			list<Opportunity> opps = bg_CIVUtils.GetLinkedOpportunities(record.Id, recordLimit, accountId, contactId, oppIds);
			for(Opportunity o : opps) {
				linkedRecords.add(bg_CIVUtils.CreateLinkedWrapper(o, sourceObjectType, Ids, orderby, orderAsc));
			}
		}
		
		// sort results - by last modified
		linkedRecords.sort();

		// get results window
		list<bg_CIVUtils.LinkedWrapper> linkedRecordsTmp = new list<bg_CIVUtils.LinkedWrapper>();
		integer startPos = (bg_CIVUtils.MAX_ROWS * (pageNumber-1));
		integer endPos = (bg_CIVUtils.MAX_ROWS * pageNumber);
		totalRecords = linkedRecords.size();

		for(integer i = startPos ; i < endPos; i++) {
			if(i >= totalRecords) { break; }
			linkedRecordsTmp.add(linkedRecords.get(i));
		}

		return linkedRecordsTmp;	
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
			return (totalRecords > (bg_CIVUtils.MAX_ROWS * pageNumber));
		}
	}
	
    // returns the next page of records
    public PageReference next() {
		pageNumber++;
        return null;
    }


    public PageReference Unlink() {
		/* Remove link */
		string sourceObjectType = record.getSObjectType().getDescribe().getName();

		if(selectedAction == bg_CIVUtils.UNLINK_ACTION) {
			bg_CIVLinkUtils.RemoveLink(selectedrecordId, record.Id);
		
		} else if(selectedAction == bg_CIVUtils.UNSYNC_ACTION) {
			refreshPage = bg_CIVUtils.UnlinkRecord(record.Id, sourceObjectType, selectedrecordId, selectedObjectType);	
		}

		return null;
    }
    
     public PageReference Refresh() {
     	/* Refresh results */
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