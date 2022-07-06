/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         11/11/2011
* Description:  TEST CLASS: LogACallController
*
* ------------------
* TESTING:		100%
* ------------------
*       
**/
@isTest
private class LogACallControllerTest {
	
	// Testing the WhoId CASE (Lead, Contact)
	static testMethod void logACallWho() {
		// Set up test data
        Lead l = TestData.getTestLead();
        insert l;
        
        Test.setCurrentPage(Page.logACall);
        ApexPages.currentPage().getParameters().put('rotype', 'Lead');
        ApexPages.currentPage().getParameters().put('roid', l.Id);
        
        LogACallController controller = new LogACallController();
        controller.followUp();
        
        // Check URL - saveAll()
        System.assertEquals('/' + l.Id, controller.saveAll().getURL());
        
        // Check saved tasks (CASE with followup)
        List<Task> ts = [SELECT Id FROM Task WHERE WhoId =:l.Id];
        System.assertEquals(ts.size(), 2);
        
        // Check URL - back()
        System.assertEquals('/' + l.Id, controller.back().getURL());
	}
	
	// Testing the WhatId CASE (Account, Opportunity)
	static testMethod void logACallWhat() {
		// Set up test data
        Account a = TestData.getTestAccount();
        insert a;
        
        Test.setCurrentPage(Page.logACall);
        ApexPages.currentPage().getParameters().put('rotype', 'Account');
        ApexPages.currentPage().getParameters().put('roid', a.Id);
        
        LogACallController controller = new LogACallController();
        
        // Check URL - saveAll()
        System.assertEquals('/' + a.Id, controller.saveAll().getURL());
        
        // Check saved tasks (CASE without followup)
        List<Task> ts = [SELECT Id FROM Task WHERE WhatId =:a.Id];
        System.assertEquals(ts.size(), 1);
	}
	
	// Testing negative case (FAILURE: saveAll())
	static testMethod void noTaskSaved() {
		// Set up test data
        Lead l = TestData.getTestLead();
        insert l;
        
        Test.setCurrentPage(Page.logACall);
        ApexPages.currentPage().getParameters().put('rotype', 'Lead');
        ApexPages.currentPage().getParameters().put('roid', l.Id);
        
        LogACallController controller = new LogACallController();
		controller.mainTask.Status = null; 
		
		// Check URL - saveAll()
        System.assertEquals(null, controller.saveAll());
        
	}
}