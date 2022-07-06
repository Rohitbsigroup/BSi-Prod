/********************************************************************
 * bg_BluePrintUtils2Test
 *
 * Test class for bg_BluePrintUtils2
 * 
 * 
 * Author: Richard Jimenez
 * Created: 17-10-2013
 * Changes: 
 *   20170703 - BG-MJ Added test for new Configurator URL (and Custom Setting insert)
 *   07-09-2017 - RC Added extra test to mode param
 *   07-02-2018 - ADS - Case 35482 - Asian Characters
 ********************************************************************/
@isTest
private class bg_BluePrintUtils2Test {
	
	private static testMethod void testBuildConfigureURL() {
		/*
			Set Custom Settigns for test
		*/
		insert new BPSettings__c(BluePrint_Server_URL__c = 'NewBPServerURL.com',Blueprint_Server_Path__c = 'BP/Server/Path',SalesforceURL__c = 'SalesforceURL');

		/*
			Test BuildConfigureURL method
		*/
		boolean editMode 			= true;
		string quoteId 				= 'UT_QUOTE_ID';
		string productId 			= 'UT_PRODUCT_ID';
        string quoteLanguage        = 'UT_LANGUAGE';
		string retUrl				= 'UT_RETURL';
		BPSettings__c BP_SETTINGS	= BPSettings__c.getOrgDefaults();
		boolean newURL	 			= true;

		Test.startTest();
		string url1 = bg_BluePrintUtils2.BuildConfigureURL(editMode, quoteId, productId, quoteLanguage, retUrl);
		// Should not contain mode param
		system.assertEquals(false, url1.contains(bg_BluePrintUtils2.PARAM_NAME_MODE));
		// Should contain quote Id param
		system.assertEquals(true, url1.contains(bg_BluePrintUtils2.PARAM_NAME_QUOTEID));
		// Should contain quote Id value
		system.assertEquals(true, url1.contains(quoteId));
        // Should contain quote language param
		system.assertEquals(true, url1.contains(bg_BluePrintUtils2.PARAM_NAME_LANGUAGE));
        // Should contain quote language value
        system.assertEquals(true, url1.contains(quoteLanguage));
		// Should contain active product param
		system.assertEquals(true, url1.contains(bg_BluePrintUtils2.PARAM_NAME_PRODUCTCODE));
		// Should contain active product Id value
		system.assertEquals(true, url1.contains(productId));
		// Should contain returl param
		system.assertEquals(true, url1.contains(bg_BluePrintUtils2.PARAM_NAME_RETURNURL));
		// Should contain returl param value
		system.assertEquals(true, url1.contains(returl));
        
		// Should not contain returl
		string url2 = bg_BluePrintUtils2.BuildConfigureURL(editMode, quoteId, productId, quoteLanguage);
		system.assertEquals(false, url2.contains(bg_BluePrintUtils2.PARAM_NAME_RETURNURL));
		// Should contain returl close window param
		system.assertEquals(true, url2.contains(bg_BluePrintUtils2.PARAM_NAME_CLOSE));
		
		// Should not contain mode
		string url3 = bg_BluePrintUtils2.BuildConfigureURL(quoteId, productId);
		system.assertEquals(false, url3.contains(bg_BluePrintUtils2.PARAM_NAME_MODE));

		// Should use new Configurator Address
		string url4 = bg_BluePrintUtils2.BuildConfigureURL(editMode, quoteId, productId, quoteLanguage, retUrl, newURL);
		system.assertEquals(true, url4.contains(BP_SETTINGS.BluePrint_Server_URL__c));

		//should contain mode param
		string url5 = bg_BluePrintUtils2.BuildConfigureURL(false, quoteId, productId, quoteLanguage);
		system.assertEquals(true, url5.contains(bg_BluePrintUtils2.PARAM_NAME_MODE));

		Test.stopTest();
	
	}
}