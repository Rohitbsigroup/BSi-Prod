/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         25/11/2011
* Description:  Handler class for OpportunitySite Trigger.
*       
* CPE 14/09/2017	Moved new methods created for PS delivery verifyDeletionOfOpportunitySites & deleteRelatedQuoteProducts
*					to bg_OpportunitySiteUtils
**/
public class OpportunitySiteTriggerHandler {
	
	public static boolean allowDeletionOfOpportunitySites = false;
	private Boolean lt_isExecuting = false;
	private Integer BatchSize = 0;
	
	// CONSTRUCTOR
	public OpportunitySiteTriggerHandler(Boolean isExecuting, Integer size){
		lt_isExecuting = isExecuting;
		BatchSize = size;
	}
	
	// AFTER INSERT
	public void OnAfterInsert(OpportunitySite__c[] newOptySites){
		//numberOfSites(newOptySites,false);
		// set quote Hq site
		//bg_OpportunitySiteUtils.UpdateQuoteHQSite(newOptySites, null);
	}

	public void OnAfterUpdate(OpportunitySite__c[] updatedOppSites, map<Id, OpportunitySite__c> oldOppSiteMap){
		// set quote Hq site
		//bg_OpportunitySiteUtils.UpdateQuoteHQSite(updatedOppSites, oldOppSiteMap);
		//numberOfSites(updatedOppSites, false);
	}

	
	// AFTER DELETE
	public void OnAfterDelete(OpportunitySite__c[] deletedOptySites, Map<ID, OpportunitySite__c> optySiteMap){
		// have put this in to support bulk api operations and to support partial success
		Map<Id, OpportunitySite__c> verifiedOppSitesToDeletebyId = bg_OpportunitySiteUtils.verifyDeletionOfOpportunitySites(optySiteMap);
		//numberOfSites(verifiedOppSitesToDeletebyId.Values(),true);
		bg_OpportunitySiteUtils.deleteRelatedQuoteProducts(verifiedOppSitesToDeletebyId.KeySet());
	}
	
	// -------- BUSINESS LOGIC ----------
	
	// Update the number of sites related to the Opportunity
	public void numberOfSites(OpportunitySite__c[] newOptySites,Boolean isDelete) {
		// Only NAMED Site must be counted
		Map<String,Id> rtypeMap = Utility.getRecordTypes('Site__c');
		List<OpportunitySite__c> namedSites = new List<OpportunitySite__c>();
		for (OpportunitySite__c curr : newOptySites) {
			if (curr.SiteRT__c == rtypeMap.get('NAMED')) {
				namedSites.add(curr);
			}
		}
		
		// Get the number of sites for each opty
		Map<String,Integer> siteNumberMap = new Map<String,Integer>();
		for (OpportunitySite__c os :namedSites) {
			if (siteNumberMap.containsKey(os.Opportunity__c)) {
				Integer newNumber = siteNumberMap.get(os.Opportunity__c) + 1;
				siteNumberMap.put(os.Opportunity__c,newNumber);
			} else {
				siteNumberMap.put(os.Opportunity__c,1);
			}
		}
		
		// Update the current number of site
		List<Opportunity> optys = [SELECT Id, SiteNumber__c FROM Opportunity WHERE Id IN :siteNumberMap.keySet()];
		for (Opportunity o :optys) {
			if (isDelete) 
				o.SiteNumber__c = o.SiteNumber__c - siteNumberMap.get(o.Id);
			else 
				o.SiteNumber__c = o.SiteNumber__c + siteNumberMap.get(o.Id);
				
			// Update number of unique countries for the account, used in reporting	
			List<OpportunitySite__c> sitesList = [SELECT SiteCountryCode__c FROM OpportunitySite__c WHERE Opportunity__c = :o.Id];
			if(sitesList != null){
				Set<String> countries = new Set<String>();
				for(OpportunitySite__c site: sitesList)
					countries.add(site.SiteCountryCode__c);
				o.Number_of_Countries__c = countries.size();
			}
		}
		update optys;
			
	}
	
	// -------- BUSINESS LOGIC END ----------
	
	public void BeforeInsert(OpportunitySite__c[] newOptySites){
		populateRegion(newOptySites);
	}
	
	public void BeforeUpdate(OpportunitySite__c[] updatedOppSites, map<Id, OpportunitySite__c> oldOppSiteMap){
		populateRegion(updatedOppSites);
	}
	
	public void populateRegion(OpportunitySite__c[] optySites){
		
		Set<String> siteIds = new Set<String>();
		for(OpportunitySite__c optySite: optySites){
			siteIds.add(optySite.Site__c);
		}
		
		Map<Id, Site__c> oppSites = new Map<Id, Site__c>([SELECT Id, Country_Code__c FROM Site__c WHERE Id IN :siteIds]);
		List<Discount_Region__c> regions = [SELECT Id, Country_Code__c, Region__c FROM Discount_Region__c];
		
		for(OpportunitySite__c optySite: optySites){
			if(oppSites.get(optySite.Site__c) != null) {
				for(Discount_Region__c dc : regions){
					if(oppSites.get(optySite.Site__c).Country_Code__c == dc.Country_Code__c)
						optySite.Discount_Region__c = dc.Id;
				}
			}
		}
	}
}