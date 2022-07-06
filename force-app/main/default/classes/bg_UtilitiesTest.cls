/********************************************************************
 * bg_UtilitiesTest
 *
 * Test class for bg_Utilities 
 * 
 * 
 * Author : Rob Earey
 * Created: 22-10-2013
 * Changes: 
 ********************************************************************/
@isTest 
private class bg_UtilitiesTest 
{
	private static testMethod void testGetDecimal() {
		/*
			Test method for GetDecimal method
		*/
		system.assertEquals(1, bg_Utilities.getDecimal(1));
		system.assertEquals(0, bg_Utilities.getDecimal(null));
	}
	
	private static testMethod void testGetObjectFieldMap() {
		/*
			Test method for GetObjectFieldMap method
		*/
		test.startTest();
			system.assertNotEquals(null, bg_Utilities.GetObjectFieldMap('Account'));
			system.assertEquals(true, bg_Utilities.GetObjectFieldMap('Account').size() > 0);
		test.stopTest();
	}	
}