/********************************************************************
 * civCampaignController
 *
 * Controller class for CIV Campaign component
 * 
 * 
 * Author: Richard Jimenez
 * Created: 10-09-2014
 * Changes: 
 ********************************************************************/
public with sharing class civCampaignController {
	    
	public sObject record {get; set;}
	public string AccountId {get; set;}
	public string ContactId {get; set;}

	public boolean showLeadCampaigns {get; set;}
	public boolean showContactCampaigns {get; set;}
	
	private integer totalRecords {get; set;}
	public integer pageNumber = 1;

	private string orderBy;
	public boolean orderAsc {get; set;}

	private boolean isInitialised = false;
	private void Initialise() {
		/*
			Initialise class variables
		*/
        orderAsc = true;
        orderBy = bg_CIVUtils.SORTCOL_NAME;
        sortColumnName = orderBy;
		showLeadCampaigns = false;
		showContactCampaigns = true;
		isInitialised = true;	
	}
		
	public list<bg_CIVUtils.CampaignMemberWrapper> getRecords() {
		/*
			Get Records
		*/
		
		if(!isInitialised) { Initialise(); }
				
		list<bg_CIVUtils.CampaignMemberWrapper> campaignMemberRecords = new list<bg_CIVUtils.CampaignMemberWrapper>();

		set<Id> parentIds = new set<Id>();
		parentIds.add(record.Id);
		
		if(showLeadCampaigns) {
			parentIds.addAll(bg_CIVLinkUtils.GetLinkMap(record.Id, Lead.getSObjectType().getDescribe().getName()).keySet());
		}
		if(showContactCampaigns) {
			parentIds.addAll(bg_CIVLinkUtils.GetLinkMap(record.Id, Contact.getSObjectType().getDescribe().getName()).keySet());
		}

		integer recordLimit = bg_CIVUtils.MAX_ROWS + 1;
		integer recordOffset = (bg_CIVUtils.MAX_ROWS * (pageNumber-1));
		hasNext = false;
		string sourceObjectType = record.getSObjectType().getDescribe().getName();
		
		list<CampaignMember> campaignMembers = bg_CIVUtils.GetCampaignMembers(recordLimit, recordOffset, parentIds);
		for(CampaignMember cm : campaignMembers) {
			if(campaignMemberRecords.size() == bg_CIVUtils.MAX_ROWS) {
				hasNext = true;
				break;
			}
			campaignMemberRecords.add(bg_CIVUtils.CreateCampaignMemberWrapper(cm, sourceObjectType));
		}
		return campaignMemberRecords;
	}

    public PageReference previous() {
		// returns the previous page of records
		pageNumber--;
        return null;
    }

	public boolean hasPrevious {
		get {
			return (pageNumber > 1);
		}
	}

	public boolean hasNext {get; set;}
		
    public PageReference next() {
	    // returns the next page of records
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