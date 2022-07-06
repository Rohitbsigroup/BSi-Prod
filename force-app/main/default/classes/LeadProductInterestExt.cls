/********************************************************************
 * LeadProductInterestExt
 *
 * Lead Product Interest Extension Controller
 * 
 * Author: Rob Earey
 * Created: 03/09/2013
 * Changes: 23/09/2013 Richard Jimenez 
 *            - Added saving of multiple Portfolio / Area interests
 ********************************************************************/
public with sharing class LeadProductInterestExt {

	// public variables
    public Lead leadExt {get; set;} 
	public boolean editMode {get; set;} // currently always in editMode

    public LeadProductInterestExt(ApexPages.StandardController controller) {
    	/*
    		Controller Constructor
    	*/    	
		leadExt = (Lead)controller.getRecord();	// store reference to lead
		editMode = true; 
    }
}