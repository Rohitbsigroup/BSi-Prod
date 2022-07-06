/********************************************************************
 * bg_AccountUtilsTest
 *
 * Test class for bg_AccountUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 24-10-2013
 * Changes: 
 * 
 ********************************************************************/
@isTest
private class bg_AccountUtilsTest {

	private static testMethod void testGetAccountBSIMembership() {

		// Create account & set BSI Membership fields
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT-ACCOUNTUTILS-ACC');
		acc.BSIMembershipNo__c = 'ABCDEF123';
		acc.BSIMembershipExpiryDate__c = date.today();
		update acc;

		test.startTest();
			Account testAcc = bg_AccountUtils.GetAccountBSIMembership(acc.Id);
		test.stopTest();

		system.assertEquals(acc.BSIMembershipNo__c, testAcc.BSIMembershipNo__c);
		system.assertEquals(acc.BSIMembershipExpiryDate__c, testAcc.BSIMembershipExpiryDate__c);
	}	

	private static testMethod void testGetAccountFunction() 
	{
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT-ACCOUNTUTILS-ACC');

		test.startTest();
		Account accGet =  bg_AccountUtils.GetAccount(acc.Id);
		test.stopTest();

		//check to see that they are the same account
		System.assertEquals(acc.Id, accGet.Id);
	}
}