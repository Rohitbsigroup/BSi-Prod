/********************************************************************
 * CIVMainControllerTest
 *
 * Test class for CIVMainController
 * 
 * 
 * Author: Richard Jimenez
 * Created: 15-09-2014
 * Changes: 
 ********************************************************************/
@isTest
private class CIVMainControllerTest {

	private static testMethod void testController1() {
		/*
			Test CIVMainController method
		*/

		bg_UnitTestHelper.SetupCustomSettings();
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) 	
		{
			// create lead
			Lead newLead = bg_UnitTestHelper.GetLead();
			newLead.firstname = 'Test Lead';
 			newLead.lastname =  'Lead';
			newLead.company = 'Test Ltd'; 
			newLead.email = 'TestLead@email.com'; 
			newLead.postalcode = 'CM7 YUT'; 
			newLead.phone = '01234 123 123'; 
			newLead.Existing_Customer_Account__c = null;
			newLead.Contact__c = null;

			test.startTest();
				// create CIVMainController
				CIVMainController con = new CIVMainController();
				
				// Set controller param
				con.record = newLead;
				con.recordNameValue = newLead.name; 
				con.recordCompanyValue = newLead.company;
				con.recordEmailValue = newLead.email;
				con.recordPostcodeValue = newLead.postalcode;
				con.recordPhoneValue = newLead.phone;
				con.recordAccountId = newLead.Existing_Customer_Account__c;
				con.recordContactId = newLead.Contact__c;

				// No test required, controller is a pass-through for other components
				// See: CIVMatchesControllerTest, CIVLinkedControllerTest, 
				//      CIVActivitiesControllerTest, CIVCampaignsControllerTest
			test.stopTest();
		}
	}
}