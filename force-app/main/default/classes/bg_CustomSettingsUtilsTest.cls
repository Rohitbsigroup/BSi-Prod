/********************************************************************
 * bg_CustomSettingsUtilsTest
 *
 * Test class for bg_CustomSettingsUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 17-10-2013
 * Changes:
 *	CPE 04/09/2017	Added new test method for GetBlueprintSettings 
 ********************************************************************/
@isTest
private class bg_CustomSettingsUtilsTest {

	private static testMethod void testGetDefaultCountrySettings() {
		/*
			Test GetDefaultCountrySettings method
		*/
		// setup default country setting
		bg_UnitTestHelper.GetDefaultCountrySetting();

		test.startTest();		
			system.assertNotEquals(null, bg_CustomSettingsUtils.GetDefaultCountrySettings());
		test.stopTest();
	}

	private static testMethod void testGetSiteSettings() {
		/*
			Test GetSiteSettings method
		*/
		system.assertNotEquals(null, bg_CustomSettingsUtils.GetSiteSettings());
	}
	
	private static testMethod void testGetSystemSettings() {
		/*
			Test GetSystemSettings method
		*/		
		system.assertNotEquals(null, bg_CustomSettingsUtils.GetSystemSettings());
	}
	
	private static testMethod void testGetCountryCurrencySettings() {
		/*
			Test GetCountryCurrencySettings method
		*/		
		system.assertNotEquals(null, bg_CustomSettingsUtils.GetCountryCurrencySettings());
	}

	private static testMethod void testGetQuoteSettings() {
		/*
			Test GetQuoteSettings method
		*/		
		system.assertNotEquals(null, bg_CustomSettingsUtils.GetQuoteSettings());
	}

	private static testMethod void testGetPermissionSettings() {
		/*
			Test GetPermissionSettings method
		*/		
		system.assertNotEquals(null, bg_CustomSettingsUtils.GetPermissionSettings());
	}	
	private static testMethod void GetLeadSettings() {
		/*
			Test GetLeadSettings method
		*/		
		system.assertNotEquals(null, bg_CustomSettingsUtils.GetLeadSettings());
	}
		

	/* 
		Test method for GetBlueprintSettings - No values
	*/
	static testMethod void testGetBlueprintSettingsNotSet()
	{
		BPSettings__c result;
		result = bg_CustomSettingsUtils.GetBlueprintSettings();
		system.assertEquals(result != null, true);
		system.assertEquals(result.Blueprint_Server_Path__c == null, true);
	}
	
	/* 
		Test method for GetBlueprintSettings -  values
	*/
	static testMethod void testGetBlueprintSettings()
	{
		BPSettings__c currentSetting = BPSettings__c.getOrgDefaults();
		currentSetting.Blueprint_Server_Path__c = 'TEST BP URL';
		upsert currentSetting;
		
		BPSettings__c result;
		result = bg_CustomSettingsUtils.GetBlueprintSettings();
		system.assertEquals(result != null, true);
		system.assertEquals(result.Blueprint_Server_Path__c != null, true);
	}
	
	

}