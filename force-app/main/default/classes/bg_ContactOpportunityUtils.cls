/********************************************************************
*				bg_ContactOpportunityUtils
*
* Author:       Kieran Maguire
* Company:      BrightGen
* Date:         11/11/2014
* Description:  Utility class for the Contact Opportunity junction object    
* Changes:    
 ********************************************************************/
public class bg_ContactOpportunityUtils {

	public static List<Contact_Opportunity__c> GetCloneContactRoles(Id oppId) 
	{
		/*
			Returns a list of all fields of all contact roles for that opportunity
		*/
		return new List<Contact_Opportunity__c> ([	SELECT 	ClientAccount__c, Contact__c, ContactAccount__c, Name, CreatedById, 
															CreatedDate, CurrencyIsoCode, IsDeleted, OppJobTitle__c, LastModifiedById, 
															LastModifiedDate, Opportunity__c, OwnerId, OppPrimary__c, Id, OppRole__c,
															SystemModstamp 
													FROM 	Contact_Opportunity__c
													WHERE	Opportunity__c = :oppId]);
	}


	public static List<Contact_Opportunity__c> CloneContactOpportunities(Id oldOppId, Id newOppId) 
	{
		/*
			Clones the contact roles on an opportunity and changes the opportunity id to the new opportunity id
		*/
		List<Contact_Opportunity__c> clonedContactOpps = new List<Contact_Opportunity__c>();
		
		for(Contact_Opportunity__c contactOpp: GetCloneContactRoles(oldOppId))
		{
			Contact_Opportunity__c newContactOpp = contactOpp.clone(false, true);
			newContactOpp.Opportunity__c = newOppId;
			clonedContactOpps.add(newContactOpp);
		}
		
		return clonedContactOpps;
	}

}