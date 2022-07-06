/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         15/11/2011
* Description:  TEST CLASS: LeadTriggerHandler
*
* ------------------
* TESTING:		 85%
* ------------------
* TRIGGER:		100%
* ------------------      
* Changes: RJ 11/08/15 Added runAS user to contactedNoTask Test
**/
@isTest
private class LeadTriggerHandlerTest {
	
	private static ActivitySetting__c 	ts = ActivitySetting__c.getInstance();
	private static LeadSetting__c 		ls = LeadSetting__c.getInstance();
		
	// Testing lead status update to Contacted with no completed activities
    static testMethod void contactedNoTask() {

		User u = bg_UnitTestHelper.GetUser('BG_APU1@brightgen.com.test', 'BG_APU1@brightgen.com.test', 'tstuserx1');
	
		system.runAs(u)
		{
	    	// Prepare bulk test data
	        List<Lead> leads = new List<Lead>();
	        for (Integer i = 0; i <= 20; i++) {
	        	Lead l = TestData.getTestLead();
	        	leads.add(l);
	        }
	        insert leads;
	        
	        // DML to start the trigger
	        for (Lead curr :leads) {
	        	curr.Status = ls.StatusContacted__c;
	        }
	        
	        Test.startTest();
	        try {update leads;} catch (Exception ex) {}      
	        Test.stopTest();
	        
	        // Check expected result
	        leads = [SELECT Id, Status FROM Lead WHERE Id IN :leads];
	        for (Lead curr :leads) {
	        	System.assertNotEquals(curr.Status, ls.StatusContacted__c);
	        }
		}
    }
    
    // Testing lead status update to Contacted with completed activities
    static testMethod void contactedCompletedTask() {
    	// Prepare bulk test data
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 20; i++) {
        	Lead l = TestData.getTestLead();
        	leads.add(l);
        }
        insert leads;
        List<Task> done = new List<Task>();
        for (Lead curr :leads) {       	
        	Task t = TestData.getTestTask();
        	t.WhoId = curr.Id;
        	t.Status = ts.StatusComplete__c;
        	done.add(t);	
        }       
        insert done;
        
        // DML to start the trigger
        for (Lead curr :leads) {
        	curr.Status = ls.StatusContacted__c;
        }
        
        Test.startTest();
        try {update leads;} catch (Exception ex) {}      
        Test.stopTest();
        
        // Check expected result
        leads = [SELECT Id, Status FROM Lead WHERE Id IN :leads];
        for (Lead curr :leads) {
        	System.assertEquals(curr.Status, ls.StatusContacted__c);
        }   
    }
    
    // Testing lead status update to NOT CONVERTED  with mixed cases:
    // 1) not enough attempted calls
    // 2) enough attempted calls
    // 3) one completed task
    // 4) wrong reason specified (5 calls)
    static testMethod void closingLead() {
    	// Prepare bulk test data
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i <= 20; i++) {
        	Lead l = TestData.getTestLead();
        	leads.add(l);
        }
        insert leads;
        List<Task> done = new List<Task>();
        // CASE 1 - not enough attempted calls
        for (Lead curr :leads) {       	
        	Task t = TestData.getTestTask();
        	t.WhoId = curr.Id;
        	t.Status = ts.StatusAttempted__c;
        	done.add(t);	
        }  
        // CASE 2 - enough attempted calls
        for (Integer i = 0;i <= 5; i++) {
        	Task t = TestData.getTestTask();
        	t.WhoId = leads.get(2).Id;
        	t.Status = ts.StatusAttempted__c;
        	done.add(t);
        }
        // CASE 3 - one completed task
        Task t3 = TestData.getTestTask();
        t3.WhoId = leads.get(3).Id;
        t3.Status = ts.StatusComplete__c;
        done.add(t3);
        // CASE 4 - wrong reason specified (5 calls) 
        Task t4 = TestData.getTestTask();
        t4.WhoId = leads.get(4).Id;
        t4.Status = ts.StatusComplete__c;
        done.add(t4);    
        insert done;
        
        // DML to start the trigger
        for (Lead curr :leads) {
        	curr.Status = ls.StatusNotConverted__c;
        }
        leads.get(4).ReasonClosed__c = ls.FiveCalls__c;
        
        Test.startTest();        
        try {update leads;} catch (Exception ex) {}      
        Test.stopTest();
 
    }
}