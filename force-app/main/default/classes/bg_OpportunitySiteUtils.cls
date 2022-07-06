/********************************************************************
 * bg_OpportunitySiteUtils
 *
 * Utility methods to support Opportunity Site functions
 *
 * 
 * Author: Richard Jimenez
 * Created: 31-07-2014
 * Changes: 
 *	11-11-2014	KM	Added CloneOpportunitySites
 * CPE 05/09/2017	Removal of UpdateQuoteHQSite method as no longer utilised
 * CPE 14/09/2017	Moved new methods created for PS delivery verifyDeletionOfOpportunitySites & deleteRelatedQuoteProducts
 *					from OpportunitySiteTriggerHandler and added null pointer exception protection
 *
 *********************************************************************/
public with sharing class bg_OpportunitySiteUtils {

    public class OpportunitySiteException extends Exception {}

    public static OpportunitySite__c getOpportunitySite(Id oppSiteId)
    {
        OpportunitySite__c retVal = null;
        List<OpportunitySite__c> opportunitySites = getOpportunitySites(new Set<Id>{oppSiteId});
        if(!opportunitySites.isEmpty())
        {
            retVal = opportunitySites[0]; 
        }
        return retVal;
    }

    public static List<OpportunitySite__c> getOpportunitySites(Set<Id> oppSiteIds)
    {
        Map<Id, OpportunitySite__c> opportunitySitesById = getOpportunitySiteMapById(oppSiteIds);
        return opportunitySitesById.values();
    }

    public static Map<Id, OpportunitySite__c> getOpportunitySiteMapById(Set<Id> oppSiteIds)
    {
        return new Map<Id, OpportunitySite__c>([SELECT Id, 
                                                       Site__c, 
                                                       Site__r.Name, 
                                                       Site__r.City__c, 
                                                       Site__r.Street__c, 
                                                       Site__r.Postcode__c, 
                                                       HQ__c,
                                                       Site__r.Country__c, 
                                                       Site__r.RecordType.DeveloperName, 
                                                       Site__r.Type__c, 
                                                       Site__r.Industry__c, 
                                                       Site__r.TCodeDescr__c,
                                                       Site__r.TypeIcon__c, 
                                                       Site__r.State__c, 
                                                       ProposedScope__c, 
                                                       SitePrimaryContact__c, 
                                                       Site__r.NumberEmployees__c  
                                                FROM OpportunitySite__c
                                                WHERE Id IN :oppSiteIds]);
    }

	/*
		Method to obtain all OpportunitySite__c records for the supplied Opportunity Ids
		The resulting map (by design) will always contain the supplied Opportunity Ids even
		if there are no OpportunitySite__c records associated to the Opportunity
	*/
    public static Map<Id, List<OpportunitySite__c>> getOpportunitySiteMapByOppId(Set<Id> oppIds)
    {
        Map<Id, List<OpportunitySite__c>> opportunitySitesByOppId = new Map<Id, List<OpportunitySite__c>>();
        for(Id oppId : oppIds)
        {
            if(!opportunitySitesByOppId.containsKey(oppId))
            {
                opportunitySitesByOppId.put(oppId, new List<OpportunitySite__c>());
            }
        }
        for(OpportunitySite__c oppSite : [SELECT Id, 
                                                    Site__c,
                                                    Site__r.Name,
                                                    Site__r.City__c,
                                                    Site__r.Street__c,
                                                    Site__r.Postcode__c,
                                                    HQ__c,
                                                    Site__r.Country__c,
                                                    Site__r.RecordType.DeveloperName,
                                                    Site__r.Type__c,
                                                    Site__r.Industry__c,
                                                    Site__r.TCodeDescr__c,
                                                    Site__r.TypeIcon__c, 
                                                    Site__r.State__c, 
                                                    ProposedScope__c, 
                                                    SitePrimaryContact__c, 
                                                    Site__r.NumberEmployees__c,
                                                    Opportunity__c                                           
                                             FROM OpportunitySite__c
                                             WHERE Opportunity__c IN :oppIds
                                             ORDER BY Opportunity__c])
        {
            opportunitySitesByOppId.get(oppSite.Opportunity__c).add(oppSite);
        }
        return opportunitySitesByOppId;
    }

     
    public static List<OpportunitySite__c> GetCloneOpportunitySites (Id oppId) {
    	/*
    		Return all fields of sites on an opportunity
    	*/
    	return new List<OpportunitySite__c> ([	SELECT 	SiteEmployees__c, SiteCity__c, SiteCountry__c, SiteCountryCode__c, 
	   													CreatedById, CreatedDate, CurrencyIsoCode, IsDeleted, HQ__c, Industry__c, 
	   													LastModifiedById, LastModifiedDate, Opportunity__c, Name, OwnerId, ProposedScope__c, 
	   													Id, Site__c, SitePrimaryContact__c, SiteRT__c, SiteTCode__c, SiteType__c, 
	   													SiteName__c, SiteStateCounty__c, SiteStreet__c, SystemModstamp, TCodeDescr__c, 
   														Template_Address__c, Type__c, SiteZipPostalCode__c 
   												FROM 	OpportunitySite__c
   												WHERE	Opportunity__c = :oppId]);
    }

	public static Map<Id, OpportunitySite__c> CloneOpportunitySites (Id oldOppId, Id newOppId) {
    	/*
    		Clones all sites part of the old opportunity
    		The new sites point at the new opportunity
    		Returns a mapping from old sites to new sites
    	*/
   		Map<Id, OpportunitySite__c> oldSiteToNew = new Map<Id, OpportunitySite__c>();
   		List<OpportunitySite__c> oldSites = GetCloneOpportunitySites(oldOppId);
   		
   		//Clone old sites, change the parent opportunity and create a mapping
   		for(OpportunitySite__c oldSite: oldSites) {
			OpportunitySite__c newSite = oldSite.clone(false, true);
			newSite.Opportunity__c = newOppId;
			oldSiteToNew.put(oldSite.id, newSite);
   		}
 		
   		return oldSiteToNew;
    }


	// return a collection of opportunity sites which can be deleted, adderror will stop the dml via the UI however we need to handle bulk api operations
	public static Map<Id, OpportunitySite__c> verifyDeletionOfOpportunitySites(Map<Id, OpportunitySite__c> optySiteMap)
	{
		// collection of verified records to delete
		Map<Id, OpportunitySite__c> verifiedOppSitesToDeleteById = new Map<Id, OpportunitySite__c>();
		if (optySiteMap != null)
		{
			// get a collection of configured quote products by opp site id
			Map<Id, List<Quote_Product__c>> configuredQuoteProductsByOppSiteId = bg_QuoteProductUtils.getConfiguredQuoteProductsByOpportunitySiteIds(optySiteMap.KeySet());
			for(OpportunitySite__c oppSite : optySiteMap.Values())
			{
				// should always contain a key, have defended incase bg_QuoteProductUtils.getConfiguredQuoteProductsByOpportunitySiteIds method changes later down the line and does not always include a key
				if(configuredQuoteProductsByOppSiteId.containsKey(oppSite.Id))
				{
					// process the map and check for any configured quote products for this opportunity site
					if(configuredQuoteProductsByOppSiteId.get(oppSite.Id).Size() > 0)
					{
						// this opportunity site is related to at least 1 configured quote product and cannot be deleted
						oppSite.addError('This opportunity site is related to a configured product and cannot be deleted fropm here, please remove the product from the quote builder for the relevant quote');			
					}
					else
					{
						// opp site is not related to a configured quote product and can be deleted
						verifiedOppSitesToDeleteById.put(oppSite.Id,oppSite);
					}
				}
				// bullet proofing, if the opp site id is not in the map as a key we will assume there is no configured quote products
				else
				{
					verifiedOppSitesToDeleteById.put(oppSite.Id,oppSite);
				}
			}
		}
		// return the records to operate on in the rest of the delete trigger
		return verifiedOppSitesToDeleteById;
	}

	// we have already checked the opp sites are not related to configured quote products, we need to delete any quote products this opp site is related too
	public static void deleteRelatedQuoteProducts(Set<Id> deletedOptySiteIds)
	{
		List<Quote_Product__c> quoteProductsForOppSites = bg_QuoteProductUtils.getQuoteProductsForOpportunitySiteIds(deletedOptySiteIds);
		delete quoteProductsForOppSites;
	}


      
}