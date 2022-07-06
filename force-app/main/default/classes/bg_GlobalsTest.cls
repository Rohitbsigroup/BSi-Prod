/********************************************************************
 * bg_GlobalsTest
 *
 * Test class for bg_GlobalUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 17-12-2013
 * Changes: 
 ********************************************************************/
@isTest
private class bg_GlobalsTest {

	private static testMethod void testGlobals() {
		// Currency Code		
		system.assertEquals('USD', bg_Globals.CURRENCY_CODE_USD);
		system.assertEquals('GBP', bg_Globals.CURRENCY_CODE_GBP);
		system.assertEquals('EUR', bg_Globals.CURRENCY_CODE_EUR);

		// Lanuage Codes (e.g. used in templates)
		system.assertEquals('EN', bg_Globals.LANGUAGE_EN);

		// Global Regions
		system.assertEquals('EMEA', 	bg_Globals.REGION_EMEA);
		system.assertEquals('US', 		bg_Globals.REGION_US);
		system.assertEquals('ASIA-PAC', bg_Globals.REGION_ASIAPAC);
	}
}