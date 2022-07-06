/********************************************************************
 * bg_CampaignUtils
 *
 * Campaign Utility class
 * 
 * 
 * Author: Rob Earey
 * Created: 16-10-2013
 * Changes: 
 ********************************************************************/
public with sharing class bg_CampaignUtils 
{
	public static void UpdateParentRollupFields(List<Campaign> newCampaign, List<Campaign> oldCampaign, boolean isInsert,
                      boolean isUpdate, boolean isDelete)
	{
		List<Campaign> CampaignsToUpdate = new List<Campaign>();
  		List<ID> parentIDs = new List<ID>();
  
  		//Take out a list of all parent campaign IDs
  		//if delete trigger, then take out old IDs 
  		if(isInsert || isUpdate)
  		{
    		for (Campaign c : newCampaign)
    		{
      			if(c.ParentId!=null)
      			{
        			parentIDs.add(c.ParentId);
      			}
    		} 
  		}
  		else
  		{
    		for (Campaign c : oldCampaign)
    		{	
      			if(c.ParentId!=null)
      			{
        			parentIDs.add(c.ParentId);
      			}
    		}
  		}

  		//take out all parent campaigns and fill them in a hash-map 
  		if(parentIDs.size()>0)
  		{
    		Campaign[] parentCampaigns =  [select id, name,  ParentId,  Expected_Leads__c, ExpectedRevenue, ExpectedResponse, 
        								  	BudgetedCost, ActualCost, (select id, Expected_Leads__c, ExpectedRevenue, ExpectedResponse, 
        								  	BudgetedCost, ActualCost from ChildCampaigns)
       										from Campaign where id in :parentIDs];
    
    		List<Campaign> updateCampaigns = new  List<Campaign>();
    
    		for( Campaign parentCampaign: parentCampaigns)
    		{
      			try
      			{
        			Double RollupExpectedLeads = 0;
              		Decimal RollupExpectedRevenue =0;
              		Decimal RollupExpectedResponse = 0;
              		Decimal RollupBudgetedCost = 0;
              		Decimal RollupActualCost = 0;
        			for(Campaign childCampaign: parentCampaign.ChildCampaigns)
        			{
	            		RollupExpectedLeads = RollupExpectedLeads  + bg_Utilities.getDecimal(childCampaign.Expected_Leads__c);
	                    RollupExpectedRevenue = RollupExpectedRevenue + bg_Utilities.getDecimal(childCampaign.ExpectedRevenue);
	                    RollupExpectedResponse = RollupExpectedResponse + bg_Utilities.getDecimal(childCampaign.ExpectedResponse);
	                    RollupBudgetedCost = RollupBudgetedCost + bg_Utilities.getDecimal(childCampaign.BudgetedCost);
	                    RollupActualCost = RollupActualCost + bg_Utilities.getDecimal(childCampaign.ActualCost);
	        		}
	          		RollupExpectedLeads = RollupExpectedLeads + bg_Utilities.getDecimal(parentCampaign.Expected_Leads__c) ;
	              	RollupExpectedRevenue  = RollupExpectedRevenue+ bg_Utilities.getDecimal(parentCampaign.ExpectedRevenue);
	              	RollupExpectedResponse = RollupExpectedResponse+ bg_Utilities.getDecimal(parentCampaign.ExpectedResponse);
	              	RollupBudgetedCost  = RollupBudgetedCost + bg_Utilities.getDecimal(parentCampaign.BudgetedCost);
	              	RollupActualCost  = RollupActualCost + bg_Utilities.getDecimal(parentCampaign.ActualCost);

          
	          		Campaign tCampaign = new Campaign(id=parentCampaign.id);

	          		tCampaign.Total_Expected_Leads__c = RollupExpectedLeads   ;
	              	tCampaign.Total_Expected_Revenue__c  = RollupExpectedRevenue ;
	              	tCampaign.Average_Expected_Response__c = RollupExpectedResponse/(parentCampaign.ChildCampaigns.size()+1);
	              	tCampaign.Total_Budgeted_Cost__c  = RollupBudgetedCost  ;
	              	tCampaign.Total_Actual_Cost__c  = RollupActualCost  ;
	              	
	        		campaignsToUpdate.add(tCampaign);
	      		}
	      		catch(Exception e)
	      		{
	        		System.debug(e.getMessage());
	        		throw e;
	        		parentCampaign.addError(e.getMessage());
	      		}
	    	}
	    	try
	    	{
	      		Database.update(campaignsToUpdate);
	    	}
	    	catch(Exception e)
	    	{
	      		System.debug(e.getMessage());
	      		throw e;
	    	}
		}
	}
	
	public static void UpdateCampaignRollup(List<Campaign> newCampaign, Map<Id,Campaign> newCampaignMap)
	{
		List<Campaign> CampaignsToUpdate = new List<Campaign>();
  		List<ID> parentIDs = new List<ID>();
  
  		//Take out a list of all parent campaign IDs
  		//if delete trigger, then take out old IDs 
    	for (Campaign cam: newCampaign)
    	{
       		parentIDs.add(cam.id);
    	} 

  		//take out all parent campaigns and fill them in a hash-map 
  		if(parentIDs.size()>0)
  		{
    		Campaign[] parentCampaigns =  [select id, name,  ParentId,  Expected_Leads__c, ExpectedRevenue, ExpectedResponse, 
        								BudgetedCost, ActualCost, (select id, Expected_Leads__c, ExpectedRevenue, ExpectedResponse, 
        								BudgetedCost, ActualCost from ChildCampaigns)
       									from Campaign where id in :parentIDs];
    
    		List<Campaign> updateCampaigns = new  List<Campaign>();
    
    		for( Campaign parentCampaign: parentCampaigns)
    		{
      
      			try
      			{
        			Double RollupExpectedLeads = 0;
              		Decimal RollupExpectedRevenue =0;
              		Decimal RollupExpectedResponse = 0;
              		Decimal RollupBudgetedCost = 0; 
              		Decimal RollupActualCost = 0;
        			for(Campaign childCampaign: parentCampaign.ChildCampaigns)
        			{
          
            			RollupExpectedLeads = RollupExpectedLeads  + Utility.getDecimal(childCampaign.Expected_Leads__c);
                    	RollupExpectedRevenue = RollupExpectedRevenue + Utility.getDecimal( childCampaign.ExpectedRevenue);
                    	RollupExpectedResponse = RollupExpectedResponse + Utility.getDecimal(childCampaign.ExpectedResponse);
                    	RollupBudgetedCost = RollupBudgetedCost + Utility.getDecimal(childCampaign.BudgetedCost);
                    	RollupActualCost = RollupActualCost + Utility.getDecimal(childCampaign.ActualCost);
          
        			}
         			Campaign newCamp = newCampaignMap.get(parentCampaign.id);
          			newCamp.Total_Expected_Leads__c = RollupExpectedLeads + Utility.getDecimal(newCamp.Expected_Leads__c );
              		newCamp.Total_Expected_Revenue__c  = RollupExpectedRevenue+ Utility.getDecimal(newCamp.ExpectedRevenue);
              		newCamp.Average_Expected_Response__c = (RollupExpectedResponse+Utility.getDecimal(newCamp.ExpectedResponse))/(parentCampaign.ChildCampaigns.size()+1);
              		newCamp.Total_Budgeted_Cost__c  = RollupBudgetedCost + Utility.getDecimal(newCamp.BudgetedCost);
              		newCamp.Total_Actual_Cost__c  = RollupActualCost + Utility.getDecimal(newCamp.ActualCost);
      			}
      			catch(Exception e)
      			{
        			throw e;
        			System.debug('ErrorError==' + e.getMessage());
        			//parentCampaign.addError(e.getMessage());
      			}
    		}
  
  		} 	
	}	 	                
}