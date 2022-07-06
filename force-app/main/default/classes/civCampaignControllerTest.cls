/********************************************************************
 * civCampaignControllerTest
 *
 * Test class for civCampaignController
 * 
 * 
 * Author: Richard Jimenez
 * Created: 15-09-2014
 * Changes: 
 ********************************************************************/
@isTest
private class civCampaignControllerTest {

	private static testMethod void testController1() {
		/*
			Test civCampaignController method
		*/

		bg_UnitTestHelper.SetupCustomSettings();
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) 	
		{
			// create lead
			Lead newLead = bg_UnitTestHelper.GetLead();			
			Campaign c = bg_UnitTestHelper.GetCampaign('UT-CAMPAIGN');

			test.startTest();
				// create civCampaignController
				civCampaignController con = new civCampaignController();

				// Set controller param
				con.record = newLead;
				con.accountId = newLead.Existing_Customer_Account__c;
				con.contactId = newLead.Contact__c;

				// Check no activities are returned
				system.assertEquals(0, con.getRecords().size());

				CampaignMember cm = new CampaignMember();
				cm.LeadId = newLead.Id;
				cm.CampaignId = c.Id;
				insert cm;

				// Check no activities are returned
				system.assertEquals(1, con.getRecords().size());

				system.assertEquals(false, con.hasPrevious);
				system.assertEquals(false, con.hasNext);
				system.assertEquals(null, con.previous());
				system.assertEquals(null, con.Refresh());
				system.assertEquals(null, con.next());   
				
				system.assertEquals(null, con.sortResults());
				con.sortColumnName = bg_CIVUtils.SORTCOL_OBJECTTYPE;
				con.orderAsc = true;
				system.assertEquals(null, con.sortResults());  	
				 				
			test.stopTest();
		}
	}

}