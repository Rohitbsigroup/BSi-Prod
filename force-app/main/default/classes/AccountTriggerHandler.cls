/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         10/01/2012
* Description:  Handler class for Account Trigger.
*
* Changes		IB - 29-08-2017 - removed createHQSite() for PS implementation UAT #PS - 001
*
*       
**/
public with sharing class AccountTriggerHandler {
	
	private Boolean isExecuting = false;
	private Integer BatchSize = 0;
	private static List<Territory__c> territories {get; set;}
	
	// CONSTRUCTOR
	public AccountTriggerHandler(Boolean isExecuting, Integer size){
		isExecuting = isExecuting;
		BatchSize = size;
	}

	private static List<Territory__c> fetchTerritories()
	{
		system.debug('fetchterritories: '+territories);
		if(null==territories || territories.isEmpty())
		{
			territories = new List<Territory__c>([SELECT Country__c, PostZipCode__c FROM Territory__c]);
		}
		system.debug('postfetchterritories: '+territories);
		return territories;
	}
	
	// BEFORE INSERT
	public void OnBeforeInsert(Account[] newAccounts){
		if (!Utility.lockassignTerritory) assignTerritory(newAccounts);
	}
		
	// AFTER INSERT
	public void OnAfterInsert(Account[] newAccounts, Map<Id,Account> newMapAcc) {
		// 20170629 BG-MJ Process Builder now creates the HQ Site
        //if (!Utility.lockcreateHQSite) createHQSite(newAccounts,newMapAcc);
	}
	
	// BEFORE UPDATE
	public void OnBeforeUpdate(Account[] updatedAccounts){
		if (!Utility.lockassignTerritory) assignTerritory(updatedAccounts);
	}
	
	// ACCOUNT TERRITORY ASSIGNMENT
	public void assignTerritory(Account[] accounts) {
		territories = fetchTerritories();
		System.debug('territories = ' + territories);
		Map<String,Id> postcodeMap = Utility.getTerritoryMap(territories);
		
		system.debug('postcodeMap: ' + postcodeMap);
		
		if (!postCodeMap.keySet().isEmpty()) {
			for (Account curr : accounts) {
				curr.BillingPostalCode = Utility.cleanPostcode(curr.BillingPostalCode);
				
				if (bg_StringUtils.IsBlank(curr.BillingPostalCode) && postcodeMap.get(curr.BillingCountry) != null) {
					curr.Territory__c = postcodeMap.get(curr.BillingCountry);
				} else if (!bg_StringUtils.IsBlank(curr.BillingPostalCode) && postcodeMap.get(curr.BillingCountry+'#'+Utility.formtZipCode(curr.BillingPostalcode, curr.BillingCountry)) != null) {
					curr.Territory__c = postcodeMap.get(curr.BillingCountry+'#'+Utility.formtZipCode(curr.BillingPostalcode, curr.BillingCountry));
				} else if (!bg_StringUtils.IsBlank(curr.BillingState) && postcodeMap.get(curr.BillingCountry+'#'+curr.BillingState) != null) {
					curr.Territory__c = postcodeMap.get(curr.BillingCountry+'#'+curr.BillingState);
				} else if (!bg_StringUtils.IsBlank(curr.BillingPostalCode) && postcodeMap.get(curr.BillingCountry+'#'+Utility.formtZipCode(curr.BillingPostalcode, curr.BillingCountry)) == null) {
					curr.Territory__c = postcodeMap.get(curr.BillingCountry);
				} else {
					curr.Territory__c = null; // No match found - blank the field
				}

				system.debug('curr.Name: ' + curr.Name);
				system.debug('curr.Territory__c: ' + curr.Territory__c);
			}
		}
	}
	
	/* removed for PS implementation UAT #PS - 001
	private boolean shouldHaveHQSite(Account acc) {
		//
		//an account will only have an HQ site if it
		//has a country and postcode or street
		//
		if (acc==null) return false;
		if (acc.BillingStreet!=null || acc.BillingPostalCode!=null) {
			return true;
		} else {
			return false;
		}
	}
	

	// HQ SITE AUTOMATIC CREATION
	public void createHQSite(Account[] accs,Map<Id,Account> accMap) {
		List<Site__c> hqSites = new List<Site__c>();
		for (Account curr : accs) {
			if (shouldHaveHQSite(curr)) {
				hqSites.add(Utility.setHQSite(curr));
			}
		}

		if (!hqSites.isEmpty()) {
			// Allowing partial saving
			List<Database.SaveResult> results = Database.insert(hqSites,false);
			Integer index = 0;
			for (Database.SaveResult curr : results) {
	    		if(!curr.isSuccess()) {
	    			accs.get(index).addError(curr.getErrors().get(0).getMessage());
	    		}
	    		index ++;
	    	}
		}
	}
	*/
	
}