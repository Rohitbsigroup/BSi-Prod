/********************************************************************
 * bg_ApexPageUtils_Test.cls
 *
 * test class for bg_ApexPageUtils
 *
 * Author: Kieran Maguire
 * Created: 19-02-2016
 * Changes: 
 *          
 ********************************************************************/
@isTest
private class bg_ApexPageUtils_Test 
{
	//Tests that an error message is added to the page using the AddErrorMessage utility method
	private static testMethod void testAddErrorMessage()
	{
		String errorMessage = 'Test Error';

		test.StartTest();
			bg_ApexPageUtils.AddErrorMessageToPage(errorMessage);
		test.StopTest();

		List<ApexPages.Message> messages = ApexPages.getMessages();
		system.assertEquals(1, messages.size());
		ApexPages.Message message = messages.get(0);
		system.assertEquals(ApexPages.Severity.Error, message.getSeverity());
		system.assertEquals(errorMessage, message.getSummary());
	}

	//Tests than a message of a specific type adds to the page using the AddMessage utility method
	private static testMethod void testAddMessage()
	{
		String infoMessage = 'Information message should be added to the page';
		ApexPages.Severity infoSeverity = ApexPages.Severity.INFO;

		test.startTest();
			bg_ApexPageUtils.AddMessageToPage(infoSeverity, infoMessage);
		test.stopTest();

		List<ApexPages.Message> messages = ApexPages.getMessages();
		system.assertEquals(1, messages.size());
		ApexPages.Message message = messages.get(0);
		system.assertEquals(infoSeverity, message.getSeverity());
		system.assertEquals(infoMessage, message.getSummary());
	}
}