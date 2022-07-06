/*
 *
 * bg_TemplateSelectionController_Test
 *
 * Test class for bg_TemplateSelectionController populates select lists and left/right
 *
 * Author 	: ASD BrightGen
 * Date 	: 29/09/2014
 * Changes: 
 *         10-09-2015	RJ	Added test for template bundles
 *		   22-07-2016   CH 	commented out unused variable quotePart in TestTemplateSelectionControllerWithData
 *         05-02-2018   ADS Case 35399 - Default Filters on Conga Template Page
 */
@isTest
private class bg_TemplateSelectionController_Test 
{
/*	static testMethod void TestTemplateSelectionController() 
	{
		bg_TemplateSelectionController c = new bg_TemplateSelectionController();
		list<SelectOption> TempOptionList;	 
		
		system.Test.startTest(); 
			 
			// initial lists should be empty as no records have been created
			TempOptionList = c.getLeftOptionList();
			system.assertEquals(0, TempOptionList.size());
			TempOptionList = c.getRightOptionList();
			system.assertEquals(0, TempOptionList.size());  // returned option list
			system.assertEquals(0, c.CurrentRightList.size());  // current right list
			system.assertEquals(false, c.reloadNeeded);
			system.assertEquals(null, c.reloadPageURL);

			c.templateNameString = 'dne';
			c.typeFilterString = 'dne';
			c.languageFilterString = 'XX';
			
			//Execute Find() which will return null as no objects exist to find
			PageReference pr = c.Find();
			List<SelectOption> lso = c.getLeftOptionList();
			system.assertEquals(0, lso.size());
			
			//Call list builders
			List<SelectOption> so = c.getLanguageFilter();
			system.assertNotEquals(0, so.size());
				 
			so = c.getTypeFilter();
			system.assertNotEquals(0, so.size());
			
			so = c.getProductTypeFilter();
			system.assertNotEquals(0, so.size());
			
			so = c.getCountryFilter();
			system.assertNotEquals(0, so.size());
			
		system.Test.stopTest();
	}
*/	
	static testMethod void TestTemplateSelectionControllerWithData() 
	{
		//Create a TQ, CQ and Template in oder to test for values
		APXTConga4__Conga_Template__c ct = bg_UnitTestHelper.GetCongaTemplate('a Test CT', 'Test Group', True);
		Attachment att1 = bg_UnitTestHelper.GetAttachment(ct.Id, 'template', 'some text');
		APXT_CMQR__Conga_Merge_Query__c cq = bg_UnitTestHelper.GetCongaQuery('SNCQ');
		Template_Queries__c tq = bg_UnitTestHelper.GetTemplateQuery(cq.Id, ct.Id);
		
		APXTConga4__Conga_Template__c ct2 = bg_UnitTestHelper.GetCongaTemplate('b Test CT', 'Test Group', True);
		Attachment att2 = bg_UnitTestHelper.GetAttachment(ct2.Id, 'template2', 'some text2');
		APXT_CMQR__Conga_Merge_Query__c cq2 = bg_UnitTestHelper.GetCongaQuery('SNCX');
		Template_Queries__c tq2 = bg_UnitTestHelper.GetTemplateQuery(cq2.Id, ct2.Id);
		
		APXT_CMQR__Conga_Merge_Query__c cq3 = bg_UnitTestHelper.GetCongaQuery('SNCZ');
		Template_Queries__c tq3 = bg_UnitTestHelper.GetTemplateQuery(cq3.Id, ct2.Id);
		
		// Create Bundle
		APXTConga4__Conga_Template__c bundle = bg_UnitTestHelper.GetCongaTemplate('ZZ Bundle Test', 'Test Group', True);
		bundle.APXTConga4__Template_Type__c = bg_DocumentUtils.TEMPLATE_TYPE_BUNDLE;
		update bundle; 

		// Insert Bundle templates
		list<Bundle_Template__c> bundleTemplates = new list<Bundle_Template__c>();
		Bundle_Template__c bt1 = new Bundle_Template__c();
		bt1.Bundle_Template__c = bundle.Id;
		bt1.Conga_Template__c = ct.Id;
		bt1.Order__c = 1;
		insert bt1;
		
		//CREATE Quote
		// Set up data
		// 05-02-2018   ADS Case 35399 - Default Filters on Conga Template Page
		// bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetDefaultCountrySetting(bg_SiteUtils.COUNTRY_CODE_UK);
		bg_UnitTestHelper.GetQuoteSettings();

		string productName = 'ISO 9001';
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
		Contact con = bg_UnitTestHelper.GetContact('Test Con', acc);
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		quote.Account__c = acc.Id;
		update quote;
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		//Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, true, quoteProduct);
    	
    	// Custom Setting and User
		User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

		list<SelectOption> TempOptionList;	 
		
			Test.startTest();
			system.debug(logginglevel.ERROR,'### ### BEGIN TESTS ### ###');
			PageReference pageRef = Page.bg_TemplateSelection;
			Test.setCurrentPage(pageRef);
	    	ApexPages.currentPage().getParameters().put('docType', 'Test Group');
			ApexPages.currentPage().getParameters().put('quoteId', quote.Id);
			ApexPages.currentPage().getParameters().put('recCont', con.Id);
		
			bg_TemplateSelectionController c = new bg_TemplateSelectionController();
			
			 
			// left should contain 3, right should be empty
			TempOptionList = c.getLeftOptionList();
			system.assertEquals(3, TempOptionList.size());
			TempOptionList = c.getRightOptionList();
			system.assertEquals(0, TempOptionList.size());  // returned option list
			system.assertEquals(0, c.CurrentRightList.size());  // current right list
			 
			// Select entry to move to right box
			TempOptionList = c.getLeftOptionList();
			c.LeftSelectedList.add(TempOptionList[0].getValue());
			c.ClickRight();
			TempOptionList = c.getRightOptionList();  // update CurrentRightList with 1 selected ids
			system.assertEquals(1, c.CurrentRightList.size()); 
			system.debug(logginglevel.error, '### currentNoQueriesUsed : ' + c.currentNoQueriesUsed);
			 
			// Select entry to move to left box 
			c.RightSelectedList.add(TempOptionList[0].getValue());
			c.ClickLeft();
			TempOptionList = c.getRightOptionList();  // update CurrentRightList with 1 selected ids
			system.assertEquals(0, c.CurrentRightList.size());
			system.debug(logginglevel.error, '### currentNoQueriesUsed : ' + c.currentNoQueriesUsed);
			
			//generating URL should give error as no query selected
			pageReference url = c.GenerateURL();
			system.assertEquals(1, ApexPages.getMessages().size());
			
			// Select entry to move to right box
			TempOptionList = c.getLeftOptionList();
			system.debug(logginglevel.error, '### TempOptionList : ' + TempOptionList);
			c.LeftSelectedList.add(TempOptionList[0].getValue());
			system.debug(logginglevel.error, '### c.LeftSelectedList : ' + c.LeftSelectedList);
			c.ClickRight();
			TempOptionList = c.getRightOptionList();  // update CurrentRightList with 1 selected ids
			system.debug(logginglevel.error, '### TempOptionList : ' + TempOptionList);
			system.assertEquals(1, c.CurrentRightList.size()); 
			system.debug(logginglevel.error, '### Test currentNoQueriesUsed : ' + c.currentNoQueriesUsed);

			// Select entry to move to right box
			TempOptionList = c.getLeftOptionList();
			c.LeftSelectedList.add(TempOptionList[1].getValue());
			c.ClickRight();
			TempOptionList = c.getRightOptionList();  // update CurrentRightList with 1 selected ids
			system.assertEquals(2, c.CurrentRightList.size()); 
			system.debug(logginglevel.error, '### currentNoQueriesUsed : ' + c.currentNoQueriesUsed);
			
			url = c.GenerateURL();
			system.debug(logginglevel.error, '### url : ' + url);
			system.debug(logginglevel.error, '### Test msgs : ' + ApexPages.getMessages());
			system.assertNotEquals(null, url);
			
			system.debug(logginglevel.ERROR,'### ### FAILING TEST START ### ###');
			c.templateNameString = 'Test';
			c.typeFilterString = 'Test';
			c.languageFilterString = 'EN';
			c.productTypeFilterString = 'Assessment';
			c.countryFilterString = 'GB';
			
			//Execute Find() which will return 1 as 1 objects exist to find
			system.debug(Logginglevel.error,[SELECT APXTConga4__Name__c, Id, Number_Of_Queries_Used_Max_Allowed_50__c, Type__c, APXTConga4__Template_Group__c, Language__c, Country__c, Product_Type__c, (Select Id From Attachments) FROM APXTConga4__Conga_Template__c]);
			PageReference pr = c.Find();
			List<SelectOption> lso = c.getLeftOptionList();
			system.assertEquals(1, lso.size());
			
			c.Cancel();
			system.assertEquals(true, c.reloadNeeded);
			system.assertNotEquals('', c.reloadPageURL);
			
			system.debug(logginglevel.ERROR,'### ### END TESTS ### ###');
		Test.stopTest();
	}
}