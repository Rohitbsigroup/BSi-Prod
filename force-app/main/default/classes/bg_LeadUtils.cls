/********************************************************************
 * bg_LeadUtils
 *
 * Lead Utility methods to support lead functions
 * 
 * 
 * Author: Rob Earey
 * Created: 24-09-2013
 * Changes:
 *		Alexis Ligenreux - 23/09/2014 - Adding methods and classes
 *										for lead conversion page
 *      Richard Jimenez - 15/12/2014  - Added methods for Existing 
 *										Customer Services support
 *      Richard Jimenez - 01/01/2015  - Removal of Sales Consultant and Existing CS
 *		James Thornton	- 21/11/2016  - Modified CheckForCompletedCalls to get lead setting from bg_CustomSettingsUtils
 ********************************************************************/
public with sharing class bg_LeadUtils {

	public static final integer NO_CALLS_REQUIRED = 5;

    public class RecordWrapper implements comparable {
        public String id {get; set;}
        public String name {get; set;}
        public Set<String> reasons {get; set;}
        public Boolean createNew {get; set;}
        public Boolean checked {get; set;}
        public Integer order {get; set;}
        public Boolean linked {get; set;}
        public String address {get; set;}
        public String email {get; set;}
        public String phone {get; set;}
        public String type {get; set;}
        public Contact contact {get; set;}

        public RecordWrapper() {
            reasons = new Set<String>();
            createNew = false;
            linked = false;
        }

        public integer compareTo(Object compareTo) {
            RecordWrapper compareToWrapper = (RecordWrapper)compareTo;
            if (order < compareToWrapper.order) return 0;
            if (order > compareToWrapper.order) return 1;
            return -1;
        }

    }

	
	public static void MergeLeads(List<Lead> deletedLeads, Map<Id, Lead> leadMap)
	{
		Map<Id, set<String>> leadSourcesMap = new Map<Id, set<String>>();
		Map<Id, set<String>> subSourcesMap = new Map<Id, set<String>>();
		Map<Id, set<String>> leadDescriptionMap = new Map<Id, set<String>>();
		Map<Id, set<Id>> leadOwnersMap = new Map<Id, set<Id>>();
		Map<Id, set<DateTime>> leadCreateDateMap = new Map<Id, set<DateTime>>();
		map<Id, integer> mergeLeadCountMap = new map<Id, integer>();
		
		Set<id> leadOwnerSet = new Set<Id>();
		
		system.debug('**** Deleted Leads List = ' + deletedLeads);
		
		leadSourcesMap = bg_LeadUtils.GetMergeLeadSources(deletedLeads);
		
		system.debug('**** lead Source Map = ' + leadSourcesMap);
		
		subSourcesMap = bg_LeadUtils.GetMergeLeadSubsrcs(deletedLeads);
		
		leadDescriptionMap = bg_LeadUtils.GetMergeLeadDesc(deletedLeads);
		
		leadOwnersMap = bg_LeadUtils.GetMergeLeadOwners(deletedLeads);
		
		leadCreateDateMap = bg_LeadUtils.GetMergeLeadCreateDates(deletedLeads);

		mergeLeadCountMap = bg_LeadUtils.GetMergeLeadCount(deletedLeads);
		
  		// for each deleted Lead object add lead owner to set
		for (Lead deletedLead : deletedLeads)
		{	
  			leadOwnerSet.add(deletedLead.OwnerId); 	
		}  
		
		// Build list of Master Leads using keyset from leadSources map
		List<Lead> leadsToUpdate = [SELECT Id, Name, Description, LeadSource, Source_Sub_Category__c, Original_Lead_Create_Date__c, 
										   Merged_Lead_Source__c, Merged_Source_Sub_category__c, Merged_Lead_Owners__c, CreatedDate,
										   Merge_Count__c, MasterRecordId
								from Lead 
								where Id in : leadSourcesMap.keySet()];
		System.debug('*** Leads To Update List without updates = ' + leadsToUpdate);
		Map<Id, User> userMap = new Map<Id, User> ([SELECT Id, Name from User 
													WHERE Id in :leadOwnerSet]); 
													
		Map<Id, Group> groupMap = new Map<Id, Group> ([SELECT Id, Name from Group 
													   WHERE Id in :leadOwnerSet]);										
		
		// Add any merged lead sources,sub-sources and create dates from master leads into maps
		for (Lead masterLead: leadsToUpdate)
		{
  			// Add any merged lead sources
  			if (!bg_StringUtils.IsBlank(masterLead.Merged_Lead_Source__c))
  			{
   				set<string> sources = leadSourcesMap.get(masterLead.Id); 
   				sources.addAll(masterLead.Merged_Lead_Source__c.split(';'));     				
  			}
  			// Add any merged lead subsources
  			if (!bg_StringUtils.IsBlank(masterLead.Merged_Source_Sub_category__c))
  			{
   				set<string> subSources = subSourcesMap.get(masterLead.Id); 
   				subSources.addAll(masterLead.Merged_Source_Sub_category__c.split(';'));     				
  			}
  			// Add the master lead original lead create date to the set
  			if (masterLead.Original_Lead_Create_Date__c != null)
  			{
  				set<DateTime> leadCreateDates = leadCreateDateMap.get(masterLead.Id);
  				leadCreateDates.add(masterLead.Original_Lead_Create_Date__c);
  			}
  			
  			// update merge count
			if(masterLead.Merge_Count__c == null) { masterLead.Merge_Count__c = 0; }
			masterLead.Merge_Count__c += mergeLeadCountMap.get(masterLead.Id) + 1;
		}
		
		// Add lead sources, descriptions and owners from maps to lead objects list
		leadsToUpdate = bg_LeadUtils.UpdateLeadMergeFields(leadsToUpdate, leadSourcesMap, subsourcesMap, LeadDescriptionMap, 
										   leadOwnersMap, leadCreateDateMap, userMap, groupMap);
		
		System.debug('*** Leads To Update List with updates = ' + leadsToUpdate);
		
		// update lead objects from list (if any present)
		if (!leadsToUpdate.isempty())
		{
			update leadsToUpdate;	
		}
	
		
	} 
	public static map<Id, set<String>> GetMergeLeadSources(list<Lead> Leads)	
	{
		/*
			Create a map containing lead sources keyed by MasterRecordId (winning lead in merge operation)
		*/
		Map<Id, set<String>> leadSourcesMap = new Map<Id, set<String>>();
		
		for (Lead workLead : Leads)
		{
    		// Add lead source and any merged lead sources to map by master lead Id
    		if (!leadSourcesMap.containsKey(workLead.MasterRecordId))
    		{
    			leadSourcesMap.put(workLead.MasterRecordId, new set<string>());
    		}	
			
			set<string> sources = leadSourcesMap.get(workLead.MasterRecordId);      			      	
  			sources.add(workLead.LeadSource);
  			if (!bg_StringUtils.IsBlank(workLead.Merged_Lead_Source__c))
  			{
   				sources.addAll(workLead.Merged_Lead_Source__c.split(';'));	   				
  			}
		}	
		// return list of lead sources
		return leadSourcesMap;
	}
	
	public static map<Id, set<String>> GetMergeLeadSubsrcs(list<Lead> Leads)	
	{
		/*
			Create a map containing lead subsources keyed by MasterRecordId (winning lead in merge operation)
		*/
		Map<Id, set<String>> subSourcesMap = new Map<Id, set<String>>();
		
		for (Lead workLead : Leads)
		{
    		// Add lead subsource and any merged lead subsources to map by master lead Id
    		if (!subSourcesMap.containsKey(workLead.MasterRecordId))
    		{
    			subSourcesMap.put(workLead.MasterRecordId, new set<string>());
    		}	
			
			set<string> subsources = subSourcesMap.get(workLead.MasterRecordId);
			
			if (!bg_StringUtils.IsBlank(workLead.Source_Sub_Category__c))
  			{
  				subSources.add(workLead.Source_Sub_Category__c);
  			}
  			
  			if (!bg_StringUtils.IsBlank(workLead.Merged_Source_Sub_category__c))	
  			{
   				subSources.addAll(workLead.Merged_Source_Sub_category__c.split(';'));     				
  			}
		}
		// return list of lead sub sources
		return subSourcesMap;
	}
	
	public static map<Id, set<String>> GetMergeLeadDesc(list<Lead> Leads)	
	{
		/*
			Create a map containing lead descriptions keyed by MasterRecordId (winning lead in merge operation)
		*/
		Map<Id, set<String>> leadDescriptionMap = new Map<Id, set<String>>();
		
		for (Lead workLead : Leads)
		{
    		// Add lead subsource and any merged lead subsources to map by master lead Id
    		if (!leadDescriptionMap.containsKey(workLead.MasterRecordId))
    		{
    			leadDescriptionMap.put(workLead.MasterRecordId, new set<string>());
    		}	
			
			set<string> leadDescription = leadDescriptionMap.get(workLead.MasterRecordId);
			
			if (!bg_StringUtils.IsBlank(workLead.Description))
  			{
  				leadDescription.add(workLead.Description);
  			}
		}	
		// return list of lead sub sources
		return leadDescriptionMap;
	}
	
	public static map<Id, set<Id>> GetMergeLeadOwners(list<Lead> Leads)	
	{
		/*
			Create a map containing lead descriptions keyed by MasterRecordId (winning lead in merge operation)
		*/
		Map<Id, set<Id>> leadOwnersMap = new Map<Id, set<Id>>();
		
		for (Lead workLead : Leads)
		{
    		// Add lead subsource and any merged lead subsources to map by master lead Id
    		if (!leadOwnersMap.containsKey(workLead.MasterRecordId))
    		{
    			leadOwnersMap.put(workLead.MasterRecordId, new set<Id>());
    		}	
			
			set<Id> leadOwners = leadOwnersMap.get(workLead.MasterRecordId);
			
			leadOwners.add(workLead.OwnerId);
		}	
		// return list of lead sub sources
		return leadOwnersMap;
	}
	
	public static map<Id, set<DateTime>> GetMergeLeadCreateDates(list<Lead> Leads)	
	{
		/*
			Create a map containing lead descriptions keyed by MasterRecordId (winning lead in merge operation)
		*/
		Map<Id, set<DateTime>> leadCreateDatesMap = new Map<Id, set<DateTime>>();
		
		for (Lead workLead : Leads)
		{
    		// Add lead create date and any merged create date to map by master lead Id
    		if (!leadCreateDatesMap.containsKey(workLead.MasterRecordId))
    		{
    			leadCreateDatesMap.put(workLead.MasterRecordId, new set<DateTime>());
    		}	
			
			set<DateTime> leadCreateDates = leadCreateDatesMap.get(workLead.MasterRecordId);
			
			leadCreateDates.add(date.valueof(workLead.CreatedDate));
			if (workLead.Original_Lead_Create_Date__c != null)
			{
				leadCreateDates.add(workLead.Original_Lead_Create_Date__c);
			}
		}	
		// return list of lead sub sources
		return leadCreateDatesMap;
	}
	
	public static map<Id, integer> GetMergeLeadCount(list<Lead> Leads)	
	{
		/*
			Create a map containing lead descriptions keyed by MasterRecordId (winning lead in merge operation)
		*/
		map<Id, integer> leadMergeCountMap = new map<Id, integer>();
		for (Lead workLead : Leads) {
    		if (!leadMergeCountMap.containsKey(workLead.MasterRecordId)) {
    			leadMergeCountMap.put(workLead.MasterRecordId, 0);
    		}	
			
			if(workLead.Merge_Count__c != null && workLead.Merge_Count__c > 0) {
				integer mergeCount = leadMergeCountMap.get(workLead.MasterRecordId) + (integer)workLead.Merge_Count__c;
				leadMergeCountMap.put(workLead.MasterRecordId, mergeCount);
			}
		}	

		return leadMergeCountMap;
	}
	
	public static List<Lead> UpdateLeadMergeFields(list<Lead> leads2Update, map<id, set<string>> sourcesMap, 
														 map<id, set<string>> subsourcesMap, map<id, set<string>> descriptionsMap,
														 map<id, set<id>> ownersMap, map<id, set<DateTime>> createDateMap, map<Id, User> userMap, map<id, Group> groupMap)	
	{
		// Add lead sources, descriptions and owners from maps to lead objects and update
		for (Lead updateLead: leads2Update)
		{
			// set merge creation date and blank source and subsource merge fields
			updateLead.Merge_Created_Date__c = date.today();
			updateLead.Merged_Lead_Source__c = '';
			updateLead.Merged_Source_Sub_category__c = '';
			// add merge sources from map
			updateLead.Merged_Lead_Source__c = bg_StringUtils.ConvertToPicklistValue(SourcesMap.get(updateLead.Id));
			// add merge sub sources from map
			updateLead.Merged_Source_Sub_category__c = bg_StringUtils.ConvertToPicklistValue(subSourcesMap.get(updateLead.Id));
			// add descriptions from map
			for (string description: DescriptionsMap.get(updateLead.Id))
			{
				if (!bg_StringUtils.IsBlank(updateLead.Description))
				{
					updateLead.Description += '; ';
				}
				updateLead.Description += description;
			}
			// add oldest lead create date to Original Lead Create Date
			list<DateTime> createDateList = new list<DateTime>();
			createDateList.addAll(createDateMap.get(updateLead.Id));
			System.debug('*** Created Date List = ' + createDateList);
			createDateList.sort();
			System.debug('*** Sorted Created Date List = ' + createDateList);
			updateLead.Original_Lead_Create_Date__c = createDateList[0];
			
			// add owners from map and indicate where queue names are used
			for (Id leadOwners: OwnersMap.get(updateLead.Id))
			{
				if (!bg_StringUtils.IsBlank(updateLead.Merged_Lead_Owners__c))
				{
					updateLead.Merged_Lead_Owners__c += '; ';	
				}
				else
				{
					updateLead.Merged_Lead_Owners__c = '';	
				}
				if (userMap.containsKey(leadOwners))
				{
					updateLead.Merged_Lead_Owners__c += userMap.get(leadOwners).Name;
				}
				else
				{
					updateLead.Merged_Lead_Owners__c += groupMap.get(leadOwners).Name;
					updateLead.Merged_Lead_Owners__c += ' (Queue)';
				}	
			}	
		}

		// pass control back
		system.debug('*** Leads to Update (II) = ' + leads2update);
		return leads2Update;
	}
	
	public static void SaveLead(Lead updLead) {
		/*
			Method to Save Lead
		*/
		SaveLeads(new list<Lead>{updLead});	
	}

	public static void SaveLeads(list<Lead> updLeads) {
		/*
			Method to Save Lead
		*/
		upsert updLeads;	
	}

	public static void CheckForCompletedCalls(list<Lead> updatedLeads, map<Id, Lead> newleadMap, map<Id, Lead> oldleadMap) {
		/*
			Method to Block Lead Status to not converted
		*/
		
		// Unit test fix
		LeadSetting__c ls = bg_CustomSettingsUtils.GetLeadSettings();
		ActivitySetting__c ts 	= ActivitySetting__c.getInstance();
		
		// Filtering only the Leads with Status changed to 'Contacted' or 'Not Converted'
		list<Lead> contacted = new list<Lead>();
		list<Lead> closing = new list<Lead>();
		set<Id> scopedLeadIds = new set<Id>();
		
		// Scope leads to check
		for(Lead l : updatedLeads) {
			
			// build list of leads that have been contacted, or closed but not with the five calls
			if((l.Status == ls.StatusContacted__c) ||
				(l.Status == ls.StatusNotConverted__c
					&& l.ReasonClosed__c != ls.FiveCalls__c 
					&& l.ReasonClosed__c != ls.ProcessedSF__c 
					&& l.ReasonClosed__c != ls.DuplicateReason__c
					&& l.DetailedReasonClosed__c != ls.InsufficientDetailsReason__c)) { 
				contacted.add(l);
				scopedLeadIds.add(l.Id);

			// build list of lead that are closed with 5 calls closed reason
			} else if(l.Status == ls.StatusNotConverted__c 
						&& l.ReasonClosed__c == ls.FiveCalls__c 
						&& oldleadMap.get(l.Id).ReasonClosed__c != ls.FiveCalls__c) {
				closing.add(l);
				scopedLeadIds.add(l.Id);
			}
		}

		if(!scopedLeadIds.isEmpty()) {
			// Get list of completed and attempted tasks
			list<Task> tasks = [SELECT Id, whoId, status 
										FROM Task 
										WHERE WhoId IN :scopedLeadIds 
											AND (status = :ts.StatusComplete__c OR Status = :ts.StatusAttempted__c)];
	
			// Lead task maps
			map<Id, list<Task>> leadTasksC = new map<Id, list<Task>>(); // Completed Tasks
			map<Id, list<Task>> leadTasksA = new map<Id, list<Task>>(); // Attempted Tasks
			map<Id, list<Task>> leadTasks = new map<Id, list<Task>>();  // Completed + Attempted Tasls
			
			// loop through task populating the lead task maps
			for(Task t : tasks) {
				AddTaskToLeadMap(leadTasks, t); // All lead tasks map
				if (t.Status == ts.StatusComplete__c) {
					AddTaskToLeadMap(leadTasksC, t); // Completed lead tasks map
				} else if(t.Status == ts.StatusAttempted__c) {
					AddTaskToLeadMap(leadTasksA, t); // Attempted lead tasks map
				}
			}
	
			// flag the lead as having a completed call against it
			for(Lead l : contacted) {
				l.HasCompletedTask__c = leadTasksC.containsKey(l.Id);			
			}
	
			for(Lead l : closing) {
				// check lead has the required completed calls
				if(!leadTasks.containsKey(l.Id) || leadTasks.get(l.Id).size() < NO_CALLS_REQUIRED) {				
					// calculate call attempts left
					integer attemptLeft = NO_CALLS_REQUIRED;
					if(leadTasks.containsKey(l.Id)) {
						attemptLeft = NO_CALLS_REQUIRED - leadTasks.get(l.Id).size();
					}
					// Add error message
					string errorMessage = string.format(Label.CloseLeadWarningMessage1, new list<string>{string.valueOf(NO_CALLS_REQUIRED), l.Status, string.valueOf(attemptLeft)});
					l.addError(errorMessage);
				}
			}
		}
	}

	private static void AddTaskToLeadMap(map<Id, list<Task>> leadTaskMap, Task t) {
		/* Add task to lead task map */
		if(!leadTaskMap.containsKey(t.WhoId)) {
			leadTaskMap.put(t.WhoId, new list<Task>());
		}
		leadTaskMap.get(t.WhoId).add(t);
	}

	// lead conversion
	public static RecordWrapper createRecord(String id, string name, Boolean checked) {
		RecordWrapper rw = new RecordWrapper();
		rw.id = id;
		rw.name = name;
		rw.checked = checked;
		rw.order = 1;
		return rw;
	}

	public static String buildAddress(String street, String city, String state, String postcode, String country) {
		String address = '';
        Integer counter = 0;
		if (!bg_StringUtils.IsBlank(street)) {
            address += street;
            counter++;
        }
		if (!bg_StringUtils.IsBlank(city)) {
            if (counter != 0) {
                address += ',';
            }
            address += city;
            counter++;
        }
		if (!bg_StringUtils.IsBlank(state)) {
            if (counter != 0) {
                address += ',';
            }
            address += state;
            counter++;
        }
		if (!bg_StringUtils.IsBlank(postcode)) {
            if (counter != 0) {
                address += ',';
            }
            address += postcode;
            counter++;
        }
		if (!bg_StringUtils.IsBlank(country)) {
            if (counter != 0) {
                address += ',';
            }
            address += country;
        }
		return address;
	}

    public static String getReason (String siteName, String sitePostcode, String accountName, String accountPostcode, Lead convLead) {
        String reason = '';
        if (siteName.contains(convLead.Company) || sitePostcode == convLead.PostalCode ) {
            reason = 'Account has a site matching name / postcode';
        } else if (accountName.contains(convLead.Company) || accountPostcode == convLead.PostalCode) {
            reason = 'Account matches on name / postcode';
        }
        return reason;
    }

    public static Map<Site__c,Site__c> checkDuplicateSitesV2(List<Site__c> sites) {

        Map<Site__c,Site__c> returnedSites = new Map<Site__c,Site__c>();

        Set<Id> updateIds = new Set<Id>();

        //set the dupecheck id field
        for (Site__c site:sites) {
            site.DupeCheckID__c = setDupeCheckIdV2(site);
            system.debug('site.DupeCheckID__c... ' + site.DupeCheckID__c);
            if (site.Id!=null) updateIds.add(site.Id); 
        }

        //check that the dupecheck id field does not already exist in batch
        Map<String, Site__c> newSiteByDupeRefMap = new Map<String, Site__c>();
        for (Site__c site:sites) {
            system.debug('site.DupeCheckID__c... ' + site.DupeCheckID__c);

            if (site.DupeCheckID__c!=null && site.DupeCheckID__c != '') {
                Site__c batchDupe = newSiteByDupeRefMap.get(site.DupeCheckID__c);

                if (batchDupe==null) {
                    newSiteByDupeRefMap.put(site.DupeCheckID__c, site);
                } else {
                    returnedSites.put(site, batchDupe);
                }
            }
        }

        if (!newSiteByDupeRefMap.isEmpty()) {

            List<Site__c> existingSites = [SELECT Id, Name, DupeCheckID__c, SkipDupeChecker__c
                 FROM Site__c
                 WHERE DupeCheckID__c IN :newSiteByDupeRefMap.keyset()
                 AND Id NOT IN :updateIds ];

            Map<String, Site__c> existingSiteByDupeRefMap = new Map<String, Site__c>();
            for (Site__c existingSite:existingSites) {
                existingSiteByDupeRefMap.put(existingSite.DupeCheckID__c, existingSite);
            }

            for (Site__c newSite:newSiteByDupeRefMap.values()) {
                Site__c existingSite=existingSiteByDupeRefMap.get(newSite.DupeCheckID__c);

                if (existingSite==null) continue;

                system.debug('newSite...' + newSite);
                system.debug('existingSite...' + existingSite);
                
                if (!newSite.SkipDupeChecker__c) {
                    returnedSites.put(newSite,existingSite);
                }
            }
        }
        return returnedSites;
    }

    // Dupechecker for Sites (based on Postcode or Street)
    private static string setDupeCheckIdV2(Site__c site) {
        /*
        sets the dupeid to be matched against 
        as the lead/acc Id + post code or first 6 chars of street1
        */
        
        string dupeId = '';
        string postCode=site.PostCode__c;
        string street=site.Street__c;
        if (!site.SkipDupeChecker__c) {
            if (postCode!=null) {
                postCode=postCode.replace(' ', '').toLowerCase();
                
                if (site.Account__c!=null) {
                    dupeId=site.Account__c+postCode;
                } else if (site.Lead__c!=null) {
                    dupeId=site.Lead__c+postCode;
                }
            } else if (street!=null) {
                street=street.replace(' ', '').toLowerCase();
                if (street.length()>=6) street=street.substring(0,6);
                
                if (site.Account__c!=null) {
                    dupeId=site.Account__c+street;
                } else if (site.Lead__c!=null) {
                    dupeId=site.Lead__c+street;
                }
            }
        }
        return dupeId;
    }

    /*
		Return List existing certifications
	*/
/*	01/08/15 RJ: Removed GetExistingCustomerServices requested by BSI
	public static list<ExistingCustomerServices__c> GetExistingCustomerServices(Id recordId) 
	{
		//if(recordId) 
	        return [SELECT Id, Lead__c, Account__c
	        		FROM ExistingCustomerServices__c 
	        		WHERE Lead__c = :recordId];
		//}
	}
*/

	/*
		Transfer Existing Customer Services to Account
	*/
/*	01/08/15 RJ: Removed GetExistingCustomerServices requested by BSI	
	public static void TransferExistingCustomerServiceToAccount(list<ExistingCustomerServices__c> ecsList, Id accountId) {
        for(ExistingCustomerServices__c ecs : ecsList) {
			ecs.Account__c = accountId;
        }
	}
*/
/*
	/*
		Transfer Existing Sales Consultants To Opportunity
	*/
/*	01/08/15 RJ: Removed GetExistingCustomerServices requested by BSI	
	public static void TransferExistingSalesConsultantsToOpportunity(list<Sales_Consultant__c> salesConsultantList, Id oppId) {
        for(Sales_Consultant__c sc : salesConsultantList) {
			sc.Opportunity__c = oppId;
        }
	}
*/	
}