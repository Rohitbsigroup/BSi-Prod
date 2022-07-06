/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         25/11/2011
* Description:  TEST CLASS: EventTriggerHandler
*
* ------------------
* TESTING:		100%
* ------------------
* TRIGGER:		100%
* ------------------      
**/
@isTest
private class EventTriggerHandlerTest {
	
	// Testing email sent to Owner when inserted from different User 
	static testMethod void sendEmailToOwner() {
		//Set up data
		Event event 	= TestData.getTestEvent();
		event.OwnerId 	= UserInfo.getUserId();
		
		// Insert the Event as a different user	
	    User user = TestData.getTestStandardUser('System Administrator');
    	System.runAs(user) {
			insert event;
      	}
	}
}