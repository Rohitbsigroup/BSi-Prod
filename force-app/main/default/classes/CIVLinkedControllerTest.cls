/********************************************************************
 * CIVLinkedControllerTest
 *
 * Test class for CIVLinkedController
 * 
 * 
 * Author: Richard Jimenez
 * Created: 15-09-2014
 * Changes: 
 ********************************************************************/
@isTest
private class CIVLinkedControllerTest {

	private static testMethod void testController1() {
		/*
			Test CIVLinkedController method
		*/

		bg_UnitTestHelper.SetupCustomSettings();
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) 	
		{
			Account a = bg_UnitTestHelper.GetAccount('UT-CIV-ACC');
			Contact c = bg_UnitTestHelper.GetContact('UT-CIV-CON', a);

			// create lead
			Lead newLead = bg_UnitTestHelper.GetLead();
			newLead.Existing_Customer_Account__c = a.Id;
			newLead.Contact__c = c.Id;
			update newLead;

			Lead newLead2 = bg_UnitTestHelper.GetLead();
			newLead2.Existing_Customer_Account__c = a.Id;
			newLead2.Contact__c = c.Id;
			update newLead2;

			Opportunity newOpp = bg_UnitTestHelper.GetOpportunity(a);

			test.startTest();
				// create CIVLinkedController
				CIVLinkedController con = new CIVLinkedController();

				// Set controller param				
				con.record = newLead;
				con.accountId = newLead.Existing_Customer_Account__c;
				con.contactId = newLead.Contact__c;

				// Check 2 records are returned
				system.assertEquals(2, con.getRecords().size());
				
				// Check 3 records are returned
				con.showOpportunities = true;
				system.assertEquals(2, con.getRecords().size());

				// Unlink account
				con.selectedObjectType = bg_CIVUtils.ACCOUNT_OBJECT_TYPE_NAME;
				con.selectedRecordId = a.Id;
				con.Unlink();
				con.accountId = null;
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