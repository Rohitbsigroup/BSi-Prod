/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         10/11/2011
* Description:  TEST CLASS: ActivityHistoryController
*
* ------------------
* TESTING:		100%
* ------------------
*       
**/
@isTest
private class ActivityHistoryControllerTest {
	
	// Testing the WhoId CASE (Lead, Contact)
    static testMethod void testHistoryWho() {
        // Set up test data
        Lead l = TestData.getTestLead();
        insert l;
        Task t = TestData.getTestTask();
        t.WhoId = l.Id;
        insert t;
        
        // Testing the controller (WhoId CASE)
        ActivityHistoryController controller = new ActivityHistoryController();
        controller.objectID = l.Id;
        controller.getHistory();
        
        // Testing expected result (WhoId CASE)
        System.assertEquals(controller.history.size(), 1);
    }
    
    // Testing the WhatId CASE (Account, Opportunity,...)
    static testMethod void testHistoryWhat() {
        // Set up test data
        Account a = TestData.getTestAccount();
        insert a;
        Opportunity o = TestData.getTestOpty();
        o.AccountId = a.Id;
        insert o;
        List<Task> ts = new List<Task>();
        Task t1 = TestData.getTestTask();
        t1.WhatId = o.Id;
        ts.add(t1);
        Task t2 = TestData.getTestTask();
        t2.WhatId = a.Id;
        ts.add(t2);
        insert ts;
        
        // Testing the controller (WhatId CASE - Account)
        ActivityHistoryController controller = new ActivityHistoryController();
        controller.objectID = a.Id;
        controller.getHistory();
        
        // Testing expected result (WhatId CASE - Account)
        System.assertEquals(controller.history.size(),2);
        
        // Testing the controller (WhatId CASE - Opportunity)
        ActivityHistoryController controllerO = new ActivityHistoryController();
        controllerO.objectID = o.Id;
        controllerO.getHistory();
        
        // Testing expected result (WhatId CASE - Opportunity)
        System.assertEquals(controllerO.history.size(),1);
        
    }
}