/********************************************************************
 * CIVActivitiesControllerTest
 *
 * Test class for CIVActivitiesController
 * 
 * 
 * Author: Richard Jimenez
 * Created: 15-09-2014
 * Changes: 
 ********************************************************************/
@isTest
private class CIVActivitiesControllerTest {

	private static testMethod void testController1() {
		/*
			Test CIVActivitiesController method
		*/

		bg_UnitTestHelper.SetupCustomSettings();
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) 	
		{
			// create lead
			Lead newLead = bg_UnitTestHelper.GetLead();
			
			test.startTest();
				// create CIVActivitiesController
				CIVActivitiesController con = new CIVActivitiesController();
				
				// Set controller param
				con.record = newLead;
				con.accountId = newLead.Existing_Customer_Account__c;
				con.contactId = newLead.Contact__c;

				// Check no activities are returned
				system.assertEquals(0, con.getRecords().size());

				// Create Task
        		Task t = new Task();
				t.ActivityDate = Date.today();
				t.Subject = 'Test';
				t.Status = 'Not Started';
	        	t.WhoId = newLead.Id;
        		insert t;	

				// Create Event
        		Event e = new Event();
	        	e.ActivityDateTime = DateTime.now();
				e.Subject = 'Test';
	        	e.WhoId = newLead.Id;
	        	e.DurationInMinutes = 60;
        		insert e;	
        		
				// Check 1 activities are returned
				system.assertEquals(2, con.getRecords().size());
			test.stopTest();
		}
	}

	private static testMethod void testController2() {
		/*
			Test CIVActivitiesController method
		*/

		bg_UnitTestHelper.SetupCustomSettings();
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) 	
		{
			Account acc = bg_UnitTestHelper.GetAccount('UT-CIV-AC');
			
			// Create Task
    		Task t = new Task();
			t.ActivityDate = Date.today();
			t.Subject = 'Test';
			t.Status = 'Not Started';
        	t.WhatId = acc.Id;
    		insert t;	

			// create lead
			Lead newLead = bg_UnitTestHelper.GetLead();
			map<Id, CIV_Link__c> linkMap = bg_CIVLinkUtils.AddLink(newLead.Id, acc.Id);

			test.startTest();
				// create CIVActivitiesController
				CIVActivitiesController con = new CIVActivitiesController();

				// Set controller param				
				con.record = newLead;
				con.showAccountActivities = true;
				con.showTasks = true;

				// Check 1 activities are returned
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

	private static testMethod void testController3() {
		/*
			Test CIVActivitiesController method
		*/

		bg_UnitTestHelper.SetupCustomSettings();
		
		User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		System.runAs(user1) 	
		{
			Account a = bg_UnitTestHelper.GetAccount('UT-CIV-ACC');
			Contact c = bg_UnitTestHelper.GetContact('UT-CIV-CON', a);

			// Create Task
    		Task t = new Task();
			t.ActivityDate = Date.today();
			t.Subject = 'Test';
			t.Status = 'Not Started';
			t.WhatId = a.Id;
        	t.WhoId = c.Id;
    		insert t;	

			// create lead
			Lead newLead = bg_UnitTestHelper.GetLead();
			newLead.Existing_Customer_Account__c = a.Id;
			newLead.Contact__c = c.Id;
			update newLead;

			test.startTest();
				// create CIVActivitiesController
				CIVActivitiesController con = new CIVActivitiesController();

				// Set controller param				
				con.record = newLead;
				con.accountId = newLead.Existing_Customer_Account__c;
				bg_CIVLinkUtils.AddLink(newLead.Id, newLead.Existing_Customer_Account__c);	 
				con.contactId = newLead.Contact__c;
				bg_CIVLinkUtils.AddLink(newLead.Id, newLead.Contact__c);	 
				
				// Check 1 activities are returned
				system.assertEquals(1, con.getRecords().size());
			test.stopTest();	
		}
	}
}