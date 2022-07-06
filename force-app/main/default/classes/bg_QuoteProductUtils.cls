/********************************************************************
 * bg_QuoteProductUtils
 *
 * Utility methods for quote products
 * 
 * Test class: bg_QuoteProductUtilsTest
 * 
 * Author: Chris Bacon
 * Created: 24-07-2017
 * Changes: 
 *	CPE 07-09-2017	Added null exception prevention into getConfiguredQuoteProductsByOpportunitySiteIds
 *					to manage the oppSiteIds parameter being null
 *  RC 28/09/2017   Added new method to handle group number changes on projects.
 ********************************************************************/
public with sharing class bg_QuoteProductUtils {


	/*
	*	Rematches a group number with a phase after the project group number has changed.
	*/
	public static void MatchPhaseWithProjectGroupNumber(Set<Id> qpIds)
	{
		List<Quote_Product__c> qpGroupNumberChanged = [Select id, 
														Project__c, GroupNumber__c 
														FROM Quote_Product__c WHERE ID IN : qpIds];

		Set<Id> projectIds = new Set<Id>();

		Map<Id, Decimal> projectMap = new Map<Id, Decimal>();

		for(Quote_Product__c quoteProduct : qpGroupNumberChanged)
		{
			projectIds.add(quoteProduct.Project__c);
			projectMap.put(quoteProduct.Project__c, quoteProduct.GroupNumber__c);
		}

		//get a list of phases associated to the projects
		List<Quote_Product__c> qpPhasesToUpdate = [Select id, GroupNumber__c, Project__c FROM Quote_Product__c 
													 WHERE Project__c IN : projectIds 
													 AND Is_Project_Phase__c=true 
													 AND ID NOT IN : qpGroupNumberChanged];
		//update to the correct group number
		for(Quote_Product__C qp :qpPhasesToUpdate)
		{
			qp.GroupNumber__c = projectMap.get(qp.Project__c);

		}

		if(!qpPhasesToUpdate.isEmpty())
		{
			update qpPhasesToUpdate;
		}	
	}

	/* 
		Returns quote products by opp site id for a set of opp site ids
		By design this method ensure that all supplied Opportunity_Site__c Id's are included in the 
		resulting map, even if no Quote_Product__c records exist
	*/
	public static Map<Id, List<Quote_Product__c>> getConfiguredQuoteProductsByOpportunitySiteIds(Set<Id> oppSiteIds)
	{
		Map<Id, List<Quote_Product__c>> quoteProductsByOppSiteId = new Map<Id, List<Quote_Product__c>>();
		if (oppSiteIds != null)
		{
			for(Id oppSiteId : oppSiteIds)
			{
				quoteProductsByOppSiteId.put(oppSiteId, new List<Quote_Product__c>());
			}
			
			for(Quote_Product__c configuredQuoteProduct : [SELECT Id,
																  Opportunity_Site__c
														   FROM Quote_Product__c
														   WHERE Opportunity_Site__c IN : oppSiteIds
														   AND Configuration_Complete__c = true])
			{
				quoteProductsByOppSiteId.get(configuredQuoteProduct.Opportunity_Site__c).add(configuredQuoteProduct);
			}
		}
		return quoteProductsByOppSiteId;
	}

	// return all quote products for a set of opportuniuty site ids
	public static List<Quote_Product__c> getQuoteProductsForOpportunitySiteIds(Set<Id> opportuntiySiteIds)
	{
		return [SELECT Id,
					   Opportunity_Site__c
				FROM Quote_Product__c
				WHERE Opportunity_Site__c IN : opportuntiySiteIds];
	}
}