/********************************************************************
 * bg_QuoteApprovalUtilsTest
 *
 * Test methods for Quote Approvals Utility class
 * 
 * 
 * Author: Richard Jimenez
 * Created: 21-10-2013
 * Changes: 02-10-2014 KM - added testResetQuoteApprovals methods
 *			04-10-2017 RC - changed tests to cause quote trigger to fire by updating the quote that gets created.
 ********************************************************************/
@isTest
public class bg_QuoteApprovalUtilsTest {

	private static testMethod void testGetQuoteProductApprovals() {
		/*
			Test GetQuoteProductApprovals and GetQuoteProductApprovalsMap methods
			Test SaveQuoteProductApprovals
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		update quote;
		test.startTest();		
			system.assertEquals(1, bg_QuoteApprovalUtils.GetQuoteProductApprovals(quote.Id).size());
			system.assertEquals(1, bg_QuoteApprovalUtils.GetQuoteProductApprovalsMap(quote.Id).size());
			bg_QuoteApprovalUtils.SaveQuoteProductApprovals(bg_QuoteApprovalUtils.GetQuoteProductApprovals(quote.Id));
		test.stopTest();			
	}

	private static testMethod void testGetDiscountLevelApproverIds() {
		/*
			Test GetDiscountLevelApproverIds method
		*/
		ConversionScore__c cs = bg_UnitTestHelper.GetDefaultCountrySetting();
		QuoteSetting__c qs = bg_UnitTestHelper.GetQuoteSettings();
		User owner = bg_UserUtils.GetUserById(UserInfo.getUserId());

		test.startTest();
			system.assertEquals(1, bg_QuoteApprovalUtils.GetDiscountLevelApproverIds(qs, 1, cs.Name, owner).size());
		test.stopTest();
	}
	
	private static testMethod void testGetCCodeApprovers() {
		/*
			Test GetCCodeApprovers method
		*/
		ConversionScore__c cs = bg_UnitTestHelper.GetDefaultCountrySetting();
		map<string, string> ccodeMap = new map<string, string>();
		ccodeMap.put('C300','Approver');
		bg_UnitTestHelper.CreateCCodeProfile(UserInfo.getUserId(), ccodeMap);
		
		test.startTest();
			system.assertEquals(1, bg_QuoteApprovalUtils.GetCCodeApprovers(ccodeMap.keySet()).size());
			system.assertEquals(1, bg_QuoteApprovalUtils.GetCCodeApprovers(ccodeMap.keySet(), UserInfo.getUserId()).size());
			system.assertEquals(1, bg_QuoteApprovalUtils.GetCCodeApprovers(ccodeMap.keySet(), UserInfo.getUserId(), cs.Name).size());
		test.stopTest();
	}

	private static testMethod void testGetCCodeProductMap() {
		/*
			Test GetCCodeProductMap method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		test.startTest();		
			system.assertEquals(1, bg_QuoteApprovalUtils.GetCCodeProductMap(quote.Id).size());
		test.stopTest();	
	}
	
	private static testMethod void testUpdateCCodeStatus() {
		/*
			Test UpdateCCodeStatus method
		*/	
		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		update quote;
		
		map<string, string> ccodeMap = new map<string, string>();
		ccodeMap.put(product.CCode__c,'');
		CCode_Profile__c userCCodeProfile = bg_UnitTestHelper.CreateCCodeProfile(UserInfo.getUserId(), ccodeMap);
		map<string, set<CCode_Profile__c>> userCCodes = bg_QuoteApprovalUtils.GetCCodeApprovers(ccodeMap.keySet(), UserInfo.getUserId());
		list<Quote_Product_Approval__c> quoteProductApprovals = bg_QuoteApprovalUtils.GetQuoteProductApprovals(quote.Id);
	
		test.startTest();		
			system.assertEquals(1, bg_QuoteApprovalUtils.UpdateCCodeStatus(quote, userCCodes, userCCodes.keySet(), quoteProductApprovals).size());
			userCCodeProfile.put(product.CCode__c + '__c', bg_QuoteApprovalUtils.CCODE_PROFILE_TYPE_QUALIFIED);
			update userCCodeProfile;
			userCCodes = bg_QuoteApprovalUtils.GetCCodeApprovers(ccodeMap.keySet(), UserInfo.getUserId());
			system.assertEquals(0, bg_QuoteApprovalUtils.UpdateCCodeStatus(quote, userCCodes, userCCodes.keySet(), quoteProductApprovals).size());
		test.stopTest();		
	}
	
	private static testMethod void testPopulateDiscountApprovers() {
		/*
			Test PopulateDiscountApprovers method
		*/		
		ConversionScore__c cs = bg_UnitTestHelper.GetDefaultCountrySetting();
		QuoteSetting__c qs = bg_CustomSettingsUtils.GetQuoteSettings();
		User owner = bg_UserUtils.GetUserById(UserInfo.getUserId());
		string productName = 'ISO 9001';
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		set<Id> approverIds = new set<Id>();
		
		test.startTest();
			bg_QuoteApprovalUtils.PopulateDiscountApprovers(quote, cs.Name, owner, approverIds);
			system.assertEquals(0, approverIds.size());
		
			bg_QuoteApprovalUtils.ApplyDiscountLevelsApprovers(quote, 1, qs, cs, cs.Name, owner, approverIds);
			system.assertEquals(0, approverIds.size());

			bg_QuoteApprovalUtils.ApplyDiscountLevelsApprovers(quote, 5.0, qs, cs, cs.Name, owner, approverIds);
			system.assertEquals(1, approverIds.size());

			bg_QuoteApprovalUtils.ApplyDiscountLevelsApprovers(quote, 50.0, qs, cs, cs.Name, owner, approverIds);
			system.assertEquals(1, approverIds.size());
		test.stopTest();		
	}

	private static testMethod void testApplyDiscountBandApprovers() {
		/*
			Test UpdateDiscounts method
		*/
		ConversionScore__c cs = bg_UnitTestHelper.GetDefaultCountrySetting();
		QuoteSetting__c qs = bg_CustomSettingsUtils.GetQuoteSettings();
		User owner = bg_UserUtils.GetUserById(UserInfo.getUserId());
		string productName = 'ISO 9001';
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		
		// Set Manager
		User manager = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
		owner.managerId = manager.Id;
		owner.OperationCountry__c = cs.Name;
		update owner;

		test.startTest();
			system.assertEquals(bg_QuoteApprovalUtils.DISCOUNT_APPROVER_NA, bg_QuoteApprovalUtils.ApplyDiscountBandApprovers(quote, 1, qs, cs, owner));
			system.assertEquals(bg_QuoteApprovalUtils.DISCOUNT_APPROVER_MANAGER, bg_QuoteApprovalUtils.ApplyDiscountBandApprovers(quote, 3.1, qs, cs, owner));
			system.assertEquals(bg_QuoteApprovalUtils.DISCOUNT_APPROVER_DIRECTOR, bg_QuoteApprovalUtils.ApplyDiscountBandApprovers(quote, 5.1, qs, cs, owner));
		test.stopTest();		
	}

	private static testMethod void testUpdateDiscounts() {
		/*
			Test UpdateDiscounts method
		*/
	}
	
	private static testMethod void testIsFinanceApprovalRequired() {
		/*
			Test IsFinanceApprovalRequired method
		*/
		//ConversionScore__c cs = bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.SetupCustomSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_SITEUTILS');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_SITEUTILS', bg_SiteUtils.COUNTRY_CODE_US);		
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opp, site, true); 
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);

		test.startTest();
			system.assertEquals(false, bg_QuoteApprovalUtils.IsFinanceApprovalRequired(quote));
		test.stopTest();
	}

	private static testMethod void testIsTechReviewRequired() {
		/*
			Test IsTechReviewRequired method
		*/
		ConversionScore__c cs = bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = bg_ProductUtils.PRODUCT_NAME_CE_MARKING;
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		quote.ownerId = UserInfo.getUserId();
				
		test.startTest();
			system.assertEquals(false, bg_QuoteApprovalUtils.IsTechReviewRequired(quote));
			Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
			cs.Technical_Review_Region__c = bg_Globals.REGION_US;
			update cs;
			system.assertEquals(true, bg_QuoteApprovalUtils.IsTechReviewRequired(quote));
			cs.Technical_Review_Region__c = bg_Globals.REGION_EMEA;
			update cs;
			system.assertEquals(true, bg_QuoteApprovalUtils.IsTechReviewRequired(quote));
		test.stopTest();
	}
	
	
	private static testMethod void testGetUserManagerId() {
		/*
			Test GetUserManagerId method
		*/
		QuoteSetting__c qs = bg_UnitTestHelper.GetQuoteSettings();
		test.startTest();
			User usr1 = bg_UnitTestHelper.GetUser('BG@UT1brightgen.com', 'BG@UT1brightgen.com', 'tstuserx1');
			system.assertEquals(null, bg_QuoteApprovalUtils.GetUserManagerId(qs, usr1));

			User usr2 = bg_UnitTestHelper.GetUser('BG@UT2brightgen.com', 'BG@UT2brightgen.com', 'tstuserx2');
			usr2.ManagerId = usr1.Id;
			system.assertEquals(usr2.ManagerId, bg_QuoteApprovalUtils.GetUserManagerId(qs, usr2));

			User usr3 = bg_UnitTestHelper.GetUser('BG@UT3brightgen.com', 'BG@UT3brightgen.com', 'tstuserx3');
			usr3.DelegatedApproverId = usr2.Id;
			system.assertEquals(usr3.DelegatedApproverId, bg_QuoteApprovalUtils.GetUserManagerId(qs, usr3));

			qs.GlobalDiscountApprover__c = usr3.Id;
			User usr4 = bg_UnitTestHelper.GetUser('BG@UT4brightgen.com', 'BG@UT4brightgen.com', 'tstuserx4');
			system.assertEquals(qs.GlobalDiscountApprover__c, bg_QuoteApprovalUtils.GetUserManagerId(qs, usr4));			
		test.stopTest();
	}
	
	private static testMethod void testResetQuoteApprovalFields() {
		/*
			test method to check the quote approval fields reset
		*/
		
		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);

		update quote;
		
		map<string, string> ccodeMap = new map<string, string>();
		ccodeMap.put(product.CCode__c,'');
		CCode_Profile__c userCCodeProfile = bg_UnitTestHelper.CreateCCodeProfile(UserInfo.getUserId(), ccodeMap);
		map<string, set<CCode_Profile__c>> userCCodes = bg_QuoteApprovalUtils.GetCCodeApprovers(ccodeMap.keySet(), UserInfo.getUserId());
		Quote_Product_Approval__c quoteProductApproval = bg_QuoteApprovalUtils.GetQuoteProductApprovals(quote.Id).get(0);
		quoteProductApproval.CCodeStatus__c = bg_QuoteApprovalUtils.APPROVAL_STATUS_SUBMITTED;
		quoteProductApproval.CCodeDateTimeSubmitted__c = System.Today();
		
		test.StartTest();		
			bg_QuoteApprovalUtils.ResetQuoteApprovalFields(quoteProductApproval);
			System.assertEquals(true, checkQuoteApprovalFieldsReset(quoteProductApproval));
		test.StopTest();
	}
	
	public static Boolean checkQuoteApprovalFieldsReset(Quote_Product_Approval__c productApproval) {
		/*
			Returns true if the quote product approval fields reset correctly
		*/
		return	productApproval.CCodeStatus__c == null &&
				productApproval.CCodeApprover__c == null &&
				productApproval.CCodeDateTimeApproved__c == null &&
				productApproval.CCodeDateTimeDeclined__c == null &&
				productApproval.CCodeDateTimeSubmitted__c == null;
	}
	
	public static Boolean checkQuoteApprovalFieldsReset(Quote__c quote) {
		List<Quote_Product_Approval__c> productApprovals = new List<Quote_Product_Approval__c>(
																	[	SELECT id, CCodeStatus__c, CCodeApprover__c, CCodeDateTimeApproved__c,
																					CCodeDateTimeDeclined__c, CCodeDateTimeSubmitted__c
																		FROM Quote_Product_Approval__c
																		WHERE quote__c = :quote.id]);
		Boolean returnVal = true;
		
		for(Quote_Product_Approval__c productApprovalIterator : productApprovals) {
			if(!checkQuoteApprovalFieldsReset(productApprovalIterator)) {
				returnVal = false;
				break;
			}
		}
		return returnVal;																
	}
	
	private static testMethod void testResetQuoteApprovalsByQuoteId() {
		/*
			test method to check the quote approval resets the fields in db
		*/	
		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Product__c product = bg_UnitTestHelper.GetProduct(productName);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
		update quote;
		
		map<string, string> ccodeMap = new map<string, string>();
		ccodeMap.put(product.CCode__c,'');
		CCode_Profile__c userCCodeProfile = bg_UnitTestHelper.CreateCCodeProfile(UserInfo.getUserId(), ccodeMap);
		map<string, set<CCode_Profile__c>> userCCodes = bg_QuoteApprovalUtils.GetCCodeApprovers(ccodeMap.keySet(), UserInfo.getUserId());
		Quote_Product_Approval__c quoteProductApproval = bg_QuoteApprovalUtils.GetQuoteProductApprovals(quote.Id).get(0);
		quoteProductApproval.CCodeStatus__c = bg_QuoteApprovalUtils.APPROVAL_STATUS_SUBMITTED;
		quoteProductApproval.CCodeDateTimeSubmitted__c = System.Today();
		update quoteProductApproval;
		
		test.StartTest();		
			bg_QuoteApprovalUtils.ResetQuoteApprovalsByQuoteId(quote.id);
			System.assertEquals(true, checkQuoteApprovalFieldsReset(quote));
		test.StopTest();
	}	
	
	private static testMethod void testSubmitForApproval() {
		/*
			Test SubmitForApproval method
		*/
	}
	
	private static testMethod void testAllDiscountsSet() {
		/*
			Test AllDiscountsSet method
		*/
	}
	
	private static testMethod void testGetProductDiscountMap() { 
		/*
			Test GetProductDiscountMap method
		*/
	}
}