/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         25/11/2011
* Description:  Handler class for Site Trigger.
* Changes:      08-12-2017 - ADS - Case 34308 - Site Creation Process
*       
**/
public class SiteTriggerHandler {
	
	private Boolean isExecuting = false;
	private Integer BatchSize = 0;
	private SystemSetting__c ss = SystemSetting__c.getInstance();

	private static Map<String,Id> rtypeMap {get; set;}
	
	// CONSTRUCTOR
	public SiteTriggerHandler(Boolean isExecuting, Integer size){
		isExecuting = isExecuting;
		BatchSize = size;
	}

	private static Map<String,Id> GetRecordTypesSites()
	{
		if(rtypeMap==null)
		{
			return rtypeMap = Utility.getRecordTypes('Site__c');
		}
		else
		{
			return rtypeMap;
		}
	}
	
	// BEFORE INSERT 
	public void OnBeforeInsert(Site__c[] newSites) {
		rtypeMap = GetRecordTypesSites();
		
		// Check dupes only on Named sites
		List<Site__c> dupecheck = new List<Site__c>();
		for (Site__c curr : newSites) {
			if (curr.RecordTypeId == rtypeMap.get(Utility.RTNAME_NAMED))
				dupecheck.add(curr);
		}
		if(!ss.SkipSiteDupeCheck__c) checkDuplicateSites(dupecheck);
		
		if (!Utility.lockassignTerritory) assignTerritory(dupecheck);
		/*checkUniqueHQ_Bulk(newSites);
		checkUnique(newSites,rtypeMap.get(Utility.RTNAME_TRANSIENT),'Transient');
		checkUnique(newSites,rtypeMap.get(Utility.RTNAME_NETWORK),'Network');*/
	}
	
	// BEFORE UPDATE
	public void OnBeforeUpdate(Site__c[] updatedSites,  Map<ID, Site__c> oldSiteMap) {
		rtypeMap = GetRecordTypesSites();
		
		// Check dupes only on Named sites
		List<Site__c> dupecheck = new List<Site__c>();
		for (Site__c curr : updatedSites) {
			if (curr.RecordTypeId == rtypeMap.get(Utility.RTNAME_NAMED))
				dupecheck.add(curr);
		}
		if(!ss.SkipSiteDupeCheck__c) checkDuplicateSites(dupecheck);
		
		if (!Utility.lockassignTerritory) assignTerritory(dupecheck);
		/*checkUniqueHQ_Bulk(updatedSites);
		checkUnique(updatedSites,rtypeMap.get(Utility.RTNAME_TRANSIENT),'Transient');
		checkUnique(updatedSites,rtypeMap.get(Utility.RTNAME_NETWORK),'Network');*/
	}
	
	// AFTER INSERT
	public void OnAfterInsert(Site__c[] newSites) {
		numberOfSites(newSites,false);
	}
	
	// AFTER UPDATE
	public void OnAfterUpdate(Site__c[] updatedSites,  Map<ID, Site__c> oldSiteMap) {
		// Handle the update on Lead Conversion 
		// (the site already exist but will be related to the Account instead of the Lead)
		List<Site__c> toUpdate = new List<Site__c>();
		for (Site__c curr :updatedSites) {
			if (curr.Account__c != oldSiteMap.get(curr.Id).Account__c)
				toUpdate.add(curr);			
		}
		numberOfSites(updatedSites,false);
	}
	
	// AFTER DELETE
	public void OnAfterDelete(Site__c[] deletedSites, Map<ID, Site__c> siteMap){
		numberOfSites(deletedSites,true);
	}
	
	// -------- BUSINESS LOGIC ----------
	
	// ACCOUNT TERRITORY ASSIGNMENT
	public void assignTerritory(Site__c[] sites) {
		List<Territory__c> territories = [SELECT Country__c, PostZipCode__c FROM Territory__c];
		Map<String,Id> postcodeMap = Utility.getTerritoryMap(territories);
		if (!postCodeMap.keySet().isEmpty()) {
			for (Site__c curr : sites) {
				curr.Postcode__c = Utility.cleanPostcode(curr.Postcode__c);
				if (curr.PostCode__c == null && postcodeMap.get(curr.Country__c) != null) {
					curr.Territory__c = postcodeMap.get(curr.Country__c);
				} else if (curr.PostCode__c != null && postcodeMap.get(curr.Country__c+'#'+Utility.formtZipCode(curr.PostCode__c, curr.Country__c)) != null) {
					curr.Territory__c = postcodeMap.get(curr.Country__c+'#'+Utility.formtZipCode(curr.PostCode__c, curr.Country__c));
				} else if (curr.State__c != null && postcodeMap.get(curr.Country__c+'#'+curr.State__c) != null) {
					curr.Territory__c = postcodeMap.get(curr.Country__c+'#'+curr.State__c);
				} else if (curr.PostCode__c != null && postcodeMap.get(curr.Country__c+'#'+Utility.formtZipCode(curr.PostCode__c, curr.Country__c)) == null) {
					curr.Territory__c = postcodeMap.get(curr.Country__c);
				} else {
					curr.Territory__c = null; // No match found - blank the field
				}
			}
		}
	}
	
	// Update the number of sites related to the Account
	public void numberOfSites(Site__c[] newSites,Boolean isDelete) {
		// Only NAMED site must be counted
		rtypeMap = GetRecordTypesSites();
		List<Site__c> namedSites = new List<Site__c>();
		for (Site__c curr : newSites) {
			if (curr.RecordTypeId == rtypeMap.get('NAMED') || curr.RecordTypeId == rtypeMap.get('Default')) {
				namedSites.add(curr);
			}
		}
		
		// Get the number of sites for each opty
		Map<String,Integer> siteNumberMap = new Map<String,Integer>();
		for (Site__c s :namedSites) {
			/*if (siteNumberMap.containsKey(s.Account__c)) {
				Integer newNumber = siteNumberMap.get(s.Account__c) + 1;
				siteNumberMap.put(s.Account__c,newNumber);
			} else {
				siteNumberMap.put(s.Account__c,1);
			}*/
			siteNumberMap.put(s.Account__c,1);
		}
		
		// Update the current number of site
		Map<Id, Account> accsList = new Map<Id, Account>([SELECT Id, SiteNumber__c FROM Account WHERE Id IN :siteNumberMap.keySet()]);
		List<Site__c> siteList = [SELECT Id, Country_Code__c, Account__c FROM Site__c WHERE Account__c = :accsList.keySet()];
		
		List<Account> accs = accsList.values();
		for (Account a :accs) {
			/*if (isDelete) 
				a.SiteNumber__c = a.SiteNumber__c - siteNumberMap.get(a.Id);
			else 
				a.SiteNumber__c = a.SiteNumber__c + siteNumberMap.get(a.Id);*/
			a.SiteNumber__c = 0;	
			Set<String> countryCode = new Set<String>();
			
			for(Site__c s: siteList){
				// Update number of sites
				if(a.Id == s.Account__c){
					a.SiteNumber__c++;
					countryCode.add(s.Country_Code__c);
				}
				
				// Update number of unique countries for the account, used in reporting
				if(countryCode != null)
					a.Number_of_Countries__c = countryCode.size();
			}
			
		}
		Utility.lockAccountTrigger = true;
		update accs;
		Utility.lockAccountTrigger = false;	
	}
	
	// There must be only one HQ Site
	public void checkUniqueHQ_Bulk(List<Site__c> sites) {
		// Check only if the user is inserting-updating HQ
		List<Site__c> hqs 			= new List<Site__c>();
		Set<Id> accountIds 			= new Set<Id>();
		Set<Id> leadIds		 		= new Set<Id>();
		Map<Id,Integer> mapCurrent  = new Map<Id,Integer>();
		
		SiteSetting__c setting = SiteSetting__c.getInstance();
		for (Site__c curr : sites) {
			if (curr.Type__c == setting.HQLabel__c) {
				hqs.add(curr);
				if (curr.Account__c!=null) {
					accountIds.add(curr.Account__c);
					if (mapCurrent.get(curr.Account__c) == null) mapCurrent.put(curr.Account__c,1);
					else mapCurrent.put(curr.Account__c, mapCurrent.get(curr.Account__c) + 1);
				}
				else if (curr.Lead__c!=null) {
					System.debug('$$$ SETUP: ' + curr.Lead__c + ' ' + curr.Type__c);
					leadIds.add(curr.Lead__c);
					if (mapCurrent.get(curr.Lead__c) == null) mapCurrent.put(curr.Lead__c,1);
					else mapCurrent.put(curr.Lead__c, mapCurrent.get(curr.Lead__c) + 1);
					System.debug('$$$ COUNT: ' + mapCurrent.get(curr.Lead__c));
				}
			}
		}
		
		//hq sites have been inserted
		if (hqs.size() > 0) {
			
			//query to find hq sites already agsint the lead/account
			List<Site__c> hqSites = [SELECT Name, Lead__c, Account__c
								FROM Site__c 
								WHERE Type__c =:setting.HQLabel__c 
								AND (Account__c IN :accountIds OR Lead__c IN :leadIds)
								AND Id NOT IN :sites];
			
			//if we get some then we need to present the error	
			// Check against existing sites				
			if (!hqSites.isEmpty()) {
				Map<Id, Site__c> dupeSiteMap = new Map<Id, Site__c>();

				for (Site__c hqSite:hqSites) {
					if (hqSite.Lead__c!=null) {
						dupeSiteMap.put(hqSite.Lead__c, hqSite);
					}
					
					if (hqSite.Account__c!=null) {
						dupeSiteMap.put(hqSite.Account__c, hqSite);
					}
				}
				
				for (Site__c hqSite : sites) {
					Site__c dupeSite;
					if (hqSite.Lead__c!=null) {
						if (dupeSite==null) dupeSite = dupeSiteMap.get(hqSite.Lead__c);
					}
					if (hqSite.Account__c!=null) {
						if (dupeSite==null) dupeSite = dupeSiteMap.get(hqSite.Account__c);
					}
					
					if (dupeSite!=null) {
						//String hqlink = '<a href="/'+ dupeSite.Id +'/e?retURL=/' + dupeSite.Id + '" style="color:red;"> ' + dupeSite.Name + '</a>';
						String hqlink = Utility.hoverHref(dupesite.Id, dupeSite.Name);
						// Show nice error only on standard detail page UI (record = 1 and not a Visualforce page)
						if (!Utility.isVisualforce && sites.size() == 1) {					
							hqSite.addError(Utility.niceErrorMessage('An HQ Site has already been defined','Site','Please update your HQ site information if you want to change it: ' + hqlink), false);
						} else {
							hqSite.addError('An HQ Site has already been defined. Please update your HQ site information if you want to change it.');
						}
					}
				}
			}
			// Check against current trigger batch 
			else {
				for (Site__c curr : sites) {
					System.debug('$$$ CHECK: ' + curr.Lead__c + ' ' + curr.Type__c);
					System.debug('$$$ COUNT: ' + mapCurrent.get(curr.Lead__c));
					if (curr.Account__c != null && mapCurrent.get(curr.Account__c) > 1)
						curr.addError('You can not insert more than one HQ Site');
					else if (curr.Lead__c != null && mapCurrent.get(curr.Lead__c) > 1)
						curr.addError('You can not insert more than one HQ Site');	
				}
			}
		}
	}
	
	// There must be only one Site of the given type
	public void checkUnique(List<Site__c> sites, String rtypeId, String rtypeName) {
		
		// Check only if the user is inserting-updating given type
		List<Site__c> rts 			= new List<Site__c>();
		Set<Id> accountIds 			= new Set<Id>();
		Map<Id,Integer> mapCurrent 	= new Map<Id,Integer>();
		for (Site__c curr : sites) {
			if (curr.RecordTypeId == rtypeId) {
				rts.add(curr);
				if (curr.Account__c != null) accountIds.add(curr.Account__c);
				if (mapCurrent.get(curr.Account__c) == null) {
					mapCurrent.put(curr.Account__c,1);
				} else {
					Integer i = mapCurrent.get(curr.Account__c) + 1;
					mapCurrent.put(curr.Account__c, i);
				}
			}
		}

		if (!rts.isEmpty()) {
			// Queryfor existing sites
			List<Site__c> matchingSite = [SELECT Name, Account__c 
										 FROM Site__c 
										 WHERE RecordTypeId =:rtypeId 
										 //AND Account__c =:rts.get(0).Account__c 
										 AND Account__c IN :accountIds
										 AND Id NOT IN :sites];
			
			// Create a map Account Id-Matching Site (should be only one)
			Map<Id,Site__c> mapDupeSites = new Map<Id,Site__c>();
			for (Site__c s : matchingSite) {
				mapDupeSites.put(s.Account__c, s);
			}
			
			// Check against existing sites							 				
			if (!matchingSite.isEmpty()) {
				for (Site__c curr : sites) {
					if (mapDupeSites.get(curr.Account__c) != null) {
						//String rtlink = '<a href="/'+ mapDupeSites.get(curr.Account__c).Id +'/e?retURL=/' +mapDupeSites.get(curr.Account__c).Id + '" style="color:red;"> ' + mapDupeSites.get(curr.Account__c).Name + '</a>';
						String rtlink = Utility.hoverHref(mapDupeSites.get(curr.Account__c).Id, mapDupeSites.get(curr.Account__c).Name);
						if (!Utility.isVisualforce && sites.size() == 1) {					
							curr.addError(Utility.niceErrorMessage('A '+ rtypeName + ' Site has already been defined','Site','Please update your site information if you want to change it: ' + rtlink), false);
						} else {
							curr.addError('A ' + rtypeName + ' Site has already been defined. Please update your site information if you want to change it.');
						}
					}
					
				}
			} 
			// Check against current trigger batch
			else {
				for (Site__c curr : sites) {
					if (mapCurrent.get(curr.Account__c) > 1)
						curr.addError('You can not insert more than one ' + rtypeName + ' Site');
				}
			}										 
		}								 
	}
	
	// Dupechecker for Sites (based on Postcode or Street)
	private string setDupeCheckId(Site__c site) {
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
					dupeId=site.Account__c+postCode+site.Type__c;
				} else if (site.Lead__c!=null) {
					dupeId=site.Lead__c+postCode+site.Type__c;
				}
			} else if (street!=null) {
				street=street.replace(' ', '').toLowerCase();
				if (street.length()>=6) street=street.substring(0,6);
				
				if (site.Account__c!=null) {
					dupeId=site.Account__c+street+site.Type__c;
				} else if (site.Lead__c!=null) {
					dupeId=site.Lead__c+street+site.Type__c;
				}
			}
		}
		return dupeId;
	}
	
	// BLOCK DUPLICATE SITES - DOES NOT WORK IF YOU BULK IMPORT SITES FOR DIFFERENT ACCOUNT IN THE SAME TRANSACTION
	public void checkDuplicateSites(List<Site__c> sites) {
		
		Set<Id> updateIds = new Set<Id>();
		
		//set the dupecheck id field
		for (Site__c site:sites) {
			
			site.DupeCheckID__c=setDupeCheckId(site);
			system.debug('site.DupeCheckID__c...' + site.DupeCheckID__c);

			if (site.Id!=null) updateIds.add(site.Id); 
		}
		
		//check that the dupecheck id field does not already exist in batch
		Map<String, Site__c> newSiteByDupeRefMap = new Map<String, Site__c>();
		for (Site__c site:sites) {
			system.debug('site.DupeCheckID__c...' + site.DupeCheckID__c);
			
			if (site.DupeCheckID__c!=null && site.DupeCheckID__c != '') {
				Site__c batchDupe=newSiteByDupeRefMap.get(site.DupeCheckID__c);
				if (batchDupe==null) {
					newSiteByDupeRefMap.put(site.DupeCheckID__c, site);
				} else {
					site.addError('A duplicate site zip/postcode has been detected.');
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
					String rtlink = Utility.hoverHref(existingSite.Id, existingSite.Name);
					if (!utility.isVisualforce) {
						newSite.addError(newSite.Name + ' already exists as ' + existingSite.Name + ' at this postcode.  If this duplicate has been identified incorrectly please edit and add manually selecting the \'Skip Duplicate Check\' checkbox.');	
					} else {
						newSite.addError(Utility.niceErrorMessage(newSite.Name + ' already exists as ' + rtlink + ' at this postcode.',
										'Site',
										'If this duplicate has been identified incorrectly then select the \'Skip Duplicate Check\' checkbox.'), false);
					}
				}
			}	
		}			 
	}
	
	
	// -------- BUSINESS LOGIC END ----------
}