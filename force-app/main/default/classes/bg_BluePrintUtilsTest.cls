/********************************************************************
 * bg_BluePrintUtilsTest
 *
 * Test class for bg_BluePrintUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 17-10-2013
 * Changes: 
 *         10-09-2015	RJ	Added test for profile form template button
 *         07-02-2018 - ADS - Case 35482 - Asian Characters
 ********************************************************************/
@isTest
private class bg_BluePrintUtilsTest {
	
	private static testMethod void testBuildConfigureQuoteProductURL() {
		/*
			Test BuildConfigureQuoteProductURL method
		*/
		string quoteId = 'UT_QUOTE_ID';
		string url1 = bg_BluePrintUtils.BuildConfigureQuoteProductURL(quoteId);
		system.assert(true, url1.contains(quoteId));
		
		string productId = 'UT_PRODUCT_ID';		
		string url2 = bg_BluePrintUtils.BuildConfigureQuoteProductURL(quoteId, productId);
		system.assert(true, url2.contains(quoteId));
		system.assert(true, url2.contains(productId));		

		string cloneQuoteId = 'UT_CLONE_QUOTE_ID';		
		string url3 = bg_BluePrintUtils.BuildConfigureQuoteProductURL(quoteId, productId, cloneQuoteId);
		system.assert(true, url3.contains(quoteId));
		system.assert(true, url3.contains(productId));		
		system.assert(true, url3.contains(cloneQuoteId));	

		string retUrl = 'UT_RET_URL';		
		string url4 = bg_BluePrintUtils.BuildConfigureQuoteProductURL(quoteId, productId, cloneQuoteId, retUrl);
		system.assert(true, url4.contains(quoteId));
		system.assert(true, url4.contains(productId));		
		system.assert(true, url4.contains(cloneQuoteId));	
		system.assert(true, url4.contains(retUrl));	
		
		string quoteProductId = 'UT_QUOTE_PRODCT_ID';
		string url5 = bg_BluePrintUtils.BuildUploadFileQuoteProductURL(quoteId, productId, quoteProductId, retUrl);
		system.assert(true, url5.contains(quoteId));
		system.assert(true, url5.contains(productId));		
		system.assert(true, url5.contains(quoteProductId));	
		system.assert(true, url5.contains(retUrl));

		string url6 = bg_BluePrintUtils.BuildConfigureQuoteProductURL(true, quoteId);
		system.assert(true, url6.contains(quoteId));

		string templateName = 'templateName';
		string docPath = 'ut_test_quote.pdf';
		string hqQuoteProductId = quoteProductId + 'A';
		string imsQuoteProductId = quoteProductId + 'B';
		string samplingQuoteProductId = quoteProductId +'C';
        string quoteLanguage = 'en_GB';

		string url7 = bg_BluePrintUtils.BuildTemplateURL(templateName, docPath, quoteId, hqQuoteProductId, imsQuoteProductId, samplingQuoteProductId, quoteLanguage, retUrl);
		system.assert(true, url7.contains(quoteId));
		system.assert(true, url7.contains(templateName));		
		system.assert(true, url7.contains(docPath));
		system.assert(true, url7.contains(hqQuoteProductId));
		system.assert(true, url7.contains(imsQuoteProductId));
		system.assert(true, url7.contains(samplingQuoteProductId));		
        system.assert(true, url7.contains(quoteLanguage));
		system.assert(true, url7.contains(retUrl));

		string url8 = bg_BluePrintUtils.BuildTemplateURL(templateName, '', quoteId, hqQuoteProductId, imsQuoteProductId, samplingQuoteProductId, quoteLanguage, retUrl);
		system.assertEquals(false, url8.contains(docPath));
	}
}