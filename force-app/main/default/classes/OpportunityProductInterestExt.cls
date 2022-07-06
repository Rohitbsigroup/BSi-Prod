/********************************************************************
 * OpportunityProductInterestExt
 *
 * Opportunity Product Interest Extension Controller
 * 
 * Author: Rob Earey
 * Created: 14/10/2013
 * Changes: 
 *
 ********************************************************************/
public with sharing class OpportunityProductInterestExt 
{
	// public variables
    public Opportunity oppExt {get; set;} 
	public boolean editMode {get; set;} // currently always in editMode

    public OpportunityProductInterestExt(ApexPages.StandardController controller) 
    {
    	/*
    		Controller Constructor
    	*/    	
		oppExt = (Opportunity)controller.getRecord();	// store reference to Opportunity
		editMode = true; 
    }	
}