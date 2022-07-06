@isTest
private class CiFeedbackControllerTest
{
    static testMethod void myUnitTest()
    {
		// Setup test data
		CI_Account__c acc = CiTestUtility.createTestAccount('100');
		
		// Start the processing
		Test.startTest();

		// Simulate call
		PageReference sitesPage = Page.CI_Email_Feedback;
		Test.setCurrentPageReference(sitesPage);
     	ApexPages.currentPage().getParameters().put('retUrl', '');

		// Try the constructor with no parameter
		CiFeedbackController ctrl = new CiFeedbackController();
		System.assert(ctrl.isLocked == true);
				
		// Try the constructor with a parameter
     	ApexPages.currentPage().getParameters().put('Id', acc.Id);
		ctrl = new CiFeedbackController();
		System.assert(ctrl.isLocked == false);
		
		// Send with a blank field
		ctrl.emailBody = '';
		PageReference result = ctrl.send();
		
		// Send with a value in field
		ctrl.emailBody = 'Testing';
		result = ctrl.send();

		// Try cancel
		result = ctrl.cancel();		

		// Stop the processing
		Test.stopTest();
    }
}