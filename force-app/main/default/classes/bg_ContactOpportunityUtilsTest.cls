/********************************************************************
*				bg_ContactOpportunityUtilsTest
*
* Author:       Kieran Maguire
* Company:      BrightGen
* Date:         18/11/2014
* Description:  Test class for the Contact Opportunity junction object    
* Changes:    
 ********************************************************************/
@isTest
public class bg_ContactOpportunityUtilsTest 
{
	
	private static testMethod void testCloneContactOpportunities() 
	{
		//Test method for cloneContactOpportunities
		Account account1 = bg_UnitTestHelper.GetAccount('Account');
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		Opportunity opportunity2 = bg_UnitTestHelper.GetOpportunity(account1);
		Contact contact1 = bg_UnitTestHelper.GetContact('Test');
		Contact_Opportunity__c contactOpp = bg_UnitTestHelper.GetContactOpportunity(opportunity1.id, contact1.id);
		
		test.startTest();
			system.assertEquals(1, bg_ContactOpportunityUtils.GetCloneContactRoles(opportunity1.id).size());
			system.assertEquals(0, bg_ContactOpportunityUtils.GetCloneContactRoles(opportunity2.id).size());
			insert bg_ContactOpportunityUtils.CloneContactOpportunities(opportunity1.id, opportunity2.id);		
			system.assertEquals(1, bg_ContactOpportunityUtils.GetCloneContactRoles(opportunity1.id).size());
			system.assertEquals(1, bg_ContactOpportunityUtils.GetCloneContactRoles(opportunity2.id).size());
		test.stopTest();
	}

}