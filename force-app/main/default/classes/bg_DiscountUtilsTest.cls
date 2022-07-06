/********************************************************************
 * bg_DiscountUtilsTest
 *
 * Test class for bg_DiscountUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 19-11-2014
 * Changes: 
 ********************************************************************/
@isTest
public class bg_DiscountUtilsTest {
	
	private static testMethod void testGetQuoteDiscountApprovers() {
		/*
			Test GetQuoteDiscountApprovers method
		*/

		User approverUser1 = bg_UnitTestHelper.GetUser('BG_APU1@brightgen.com.test', 'BG_APU1@brightgen.com.test', 'tstuserx1');
		User approverUser2 = bg_UnitTestHelper.GetUser('BG_APU2@brightgen.com.test', 'BG_APU2@brightgen.com.test', 'tstuserx2');
		User approverUser3 = bg_UnitTestHelper.GetUser('BG_APU3@brightgen.com.test', 'BG_APU3@brightgen.com.test', 'tstuserx3');
		User approverUser4 = bg_UnitTestHelper.GetUser('BG_APU4@brightgen.com.test', 'BG_APU4@brightgen.com.test', 'tstuserx4');
		User preApproverUser1 = bg_UnitTestHelper.GetUser('BG_PAPU1@brightgen.com.test', 'BG_PAPU1@brightgen.com.test', 'tstuserx5');
		User preApproverUser2 = bg_UnitTestHelper.GetUser('BG_PAPU2@brightgen.com.test', 'BG_PAPU2@brightgen.com.test', 'tstuserx6');
				
		User regApproverUser = bg_UnitTestHelper.GetUser('BG_RAP@brightgen.com.test', 'BG_RAP@brightgen.com.test', 'tstuserx7');
		User inRegApproverUser = bg_UnitTestHelper.GetUser('BG_IRAP@brightgen.com.test', 'BG_IRAP@brightgen.com.test', 'tstuser8');

		User overrideRegApproverUser = bg_UnitTestHelper.GetUser('BG_ORAP@brightgen.com.test', 'BG_ORAP@brightgen.com.test', 'tstuserx9');
		User overrideInRegApproverUser = bg_UnitTestHelper.GetUser('BG_OIRAP@brightgen.com.test', 'BG_OIRAP@brightgen.com.test', 'tstuserx10');

		User salesUser = bg_UnitTestHelper.GetUser('BG_SU@brightgen.com.test', 'BG_SU@brightgen.com.test', 'tstuserxsu');
	
		// Add line manager to sales user
		User lineManagerUser = bg_UnitTestHelper.GetUser('BG_LMU@brightgen.com.test', 'BG_LMU@brightgen.com.test', 'tstuserlm');
		salesUser.ManagerId = lineManagerUser.Id;

		// Add discount manager 1
		User discountManagerUser1 = bg_UnitTestHelper.GetUser('BG_DMU1@brightgen.com.test', 'BG_DMU1@brightgen.com.test', 'tstuserdm1');
		salesUser.Discount_Manager_1__c = discountManagerUser1.Id;

		update salesUser;

		bg_UnitTestHelper.GetDefaultCountrySetting();

		// create discount region
		Discount_Region__c region1 = new Discount_Region__c();
		region1.Regional_Approver__c = regApproverUser.Id;
		region1.IntraRegional_Approver__c = inRegApproverUser.Id;
		region1.Region__c = 'Americas';
		region1.Country_Code__c = 'US';
		insert region1;

		Discount_Region__c region2 = new Discount_Region__c();
		region2.Regional_Approver__c = regApproverUser.Id;
		region2.IntraRegional_Approver__c = inRegApproverUser.Id;
		region2.Region__c = 'EMEA';
		region2.Country_Code__c = 'GB';
		insert region2;
		
		// create discount matrix
		Discount_Matrix__c dm = new Discount_Matrix__c();
		dm.Name = 'UT-Discount_Matrix';
		dm.Active__c = true;
		dm.Description__c = 'UT-Discount-Matrix-Description';
		dm.PreApprover__c = preApproverUser1.Id;
		dm.PreApprover_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;
		dm.CurrencyIsoCode = 'GBP';
		insert dm;

		// create discount matrix user record for sales user
		Discount_User_Matrix__c dum = new Discount_User_Matrix__c();
		dum.Discount_Matrix__c = dm.Id;
		dum.User__c = salesUser.Id;
		insert dum;

		// create discount matrix record - with no approvers required
		list<Discount_Matrix_Record__c> dmrs = new list<Discount_Matrix_Record__c>(); 
		Discount_Matrix_Record__c dmr;
		dmr = GetDiscountMatrixRecord(dm, 0.00,  40000.00, 0.00, 0.01);
		dmrs.add(dmr);

		// create discount matrix record - 2 approvers required
		dmr = GetDiscountMatrixRecord(dm, 40000.00,  150000.00, 0.00, 0.01);

		dmr.Approver_1__c = ApproverUser1.Id;
		dmr.Approver_1_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;
		dmr.Approver_2__c = ApproverUser2.Id;
		dmr.Approver_2_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;
		dmrs.add(dmr);

		// create discount matrix record - pre approver & 4 approvers required
		dmr = GetDiscountMatrixRecord(dm, 150000.00,  200000.00, 0.00, 0.01);
		//dmr.PreApprover__c = discountManagerUser1.Id;
		dmr.PreApprover_Type__c = bg_DiscountUtils.DISCOUNT_MANAGER_APPROVER_TYPE + ' 1';				
		//dmr.Approver_1__c = discountManagerUser1.Id;
		dmr.Approver_1_Type__c = bg_DiscountUtils.DISCOUNT_MANAGER_APPROVER_TYPE + ' 1';
		//dmr.Approver_2__c = ApproverUser2.Id;
		dmr.Approver_2_Type__c = bg_DiscountUtils.LINE_MANAGER_APPROVER_TYPE;
		dmr.Approver_3__c = ApproverUser3.Id;
		dmr.Approver_3_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;
		dmr.Approver_4__c = ApproverUser4.Id;
		dmr.Approver_4_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;
		dmrs.add(dmr);

		// create discount matrix record - 4 approvers required & regional approver overrides
		dmr = GetDiscountMatrixRecord(dm, 200000.00,  null, 0.00, 0.01);
		dmr.Approver_1__c = ApproverUser1.Id;
		dmr.Approver_1_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;		
		dmr.Approver_2__c = ApproverUser2.Id;
		dmr.Approver_2_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;
		dmr.Approver_3__c = ApproverUser3.Id;
		dmr.Approver_3_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;		
		dmr.Approver_4__c = ApproverUser4.Id;
		dmr.Approver_4_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;		
		dmr.PreApprover__c = PreApproverUser2.Id;
		dmr.PreApprover_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;		
		dmr.Regional_Approver_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;
		dmr.Regional_Approver__c = overrideRegApproverUser.Id;
		dmr.IntraRegional_Approver_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;
		dmr.IntraRegional_Approver__c = overrideInRegApproverUser.Id;
		dmrs.add(dmr);

		// Insert all discount matrix records
		insert dmrs;

 		map<string, map<string, User>> approversMap;

		system.runAs(salesUser) {
			test.startTest();

				// Check user has matrix - pass
				system.assertEquals(true, bg_DiscountUtils.HasDiscountUserMatrix(salesUser.Id));

				// Check user has matrix - failed
				system.assertEquals(false, bg_DiscountUtils.HasDiscountUserMatrix(dmr.Id));

				// Check Line Manager
				system.assertEquals(lineManagerUser.Id, bg_DiscountUtils.GetLineManager(salesUser.Id).Id);

				// Check no approvers required
				Opportunity opp = bg_UnitTestHelper.GetOpportunity();
				Quote__c quote = bg_UnitTestHelper.GetQuote(opp);

				approversMap = bg_DiscountUtils.GetQuoteDiscountApprovers(quote.Id);
				system.assertEquals(0, approversMap.get(bg_DiscountUtils.PREAPPROVER_FIELD_NAME).size());				
				system.assertEquals(0, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).size());
				
				// Check no approvers required
				approversMap = bg_DiscountUtils.GetQuoteDiscountApprovers(salesUser.Id, 'GB', 'GBP', 5000.00, 0.00, false, false);
				system.assertEquals(0, approversMap.get(bg_DiscountUtils.PREAPPROVER_FIELD_NAME).size());				
				system.assertEquals(0, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).size());

				// Check pre approvers and 2 approvers required
				approversMap = bg_DiscountUtils.GetQuoteDiscountApprovers(salesUser.Id, 'GB', 'GBP', 40000.00, 0.00, false, false);
				system.assertEquals(1, approversMap.get(bg_DiscountUtils.PREAPPROVER_FIELD_NAME).size());				
				system.assertEquals(2, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).size());

				// Test populate of quote discount approver fields
				bg_DiscountUtils.PopulateQuoteDiscountApprovers(quote, approversMap);

				system.assertEquals(preApproverUser1.Id, quote.Discount_PreApprover_1__c); 
				system.assertEquals(quote.Discount_Approver_1__c, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).get(bg_DiscountUtils.APPROVER_FIELD_NAME + '_1').Id);
				system.assertEquals(quote.Discount_Approver_2__c, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).get(bg_DiscountUtils.APPROVER_FIELD_NAME + '_2').Id);
				system.assertEquals(quote.Discount_Approver_3__c, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).get(bg_DiscountUtils.APPROVER_FIELD_NAME + '_2').Id);
				system.assertEquals(quote.Discount_Approver_4__c, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).get(bg_DiscountUtils.APPROVER_FIELD_NAME + '_2').Id);
				system.assertEquals(quote.Discount_Approver_5__c, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).get(bg_DiscountUtils.APPROVER_FIELD_NAME + '_2').Id);
				system.assertEquals(quote.Discount_Approval_Type__c, new list<string>(approversMap.get(bg_DiscountUtils.APPROVAL_TYPE).keySet())[0]);

				// Check pre approvers and 4 approvers required
				approversMap = bg_DiscountUtils.GetQuoteDiscountApprovers(salesUser.Id, 'GB', 'GBP', 150000.00, 0.00, false, false);
				system.assertEquals(1, approversMap.get(bg_DiscountUtils.PREAPPROVER_FIELD_NAME).size());				
				system.assertEquals(4, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).size());

				// Check pre approvers and 5 approvers required
				approversMap = bg_DiscountUtils.GetQuoteDiscountApprovers(salesUser.Id, 'GB', 'GBP', 150000.00, 0.00, true, false);
				system.assertEquals(1, approversMap.get(bg_DiscountUtils.PREAPPROVER_FIELD_NAME).size());				
				system.assertEquals(5, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).size());

				// Check pre approvers and 5 approvers required
				approversMap = bg_DiscountUtils.GetQuoteDiscountApprovers(salesUser.Id, 'GB', 'GBP', 150000.00, 0.00, false, true);
				system.assertEquals(1, approversMap.get(bg_DiscountUtils.PREAPPROVER_FIELD_NAME).size());				
				system.assertEquals(5, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).size());

				// Check pre approvers and 5 approvers required
				approversMap = bg_DiscountUtils.GetQuoteDiscountApprovers(salesUser.Id, 'GB', 'GBP', 150000.00, 0.00, true, true);
				system.assertEquals(1, approversMap.get(bg_DiscountUtils.PREAPPROVER_FIELD_NAME).size());				
				system.assertEquals(5, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).size());

				// Check regional / intra approver overrides
				map<Id, User> approverMap;
				approversMap = bg_DiscountUtils.GetQuoteDiscountApprovers(salesUser.Id, 'GB', 'GBP', 200000.00, 0.00, true, false);
				system.assertEquals(1, approversMap.get(bg_DiscountUtils.PREAPPROVER_FIELD_NAME).size());				
				system.assertEquals(5, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).size());

				approverMap = new map<Id, User>();
				approverMap.putAll(approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).values());
				system.assertEquals(true, approverMap.containsKey(overrideRegApproverUser.Id));

				// Check regional / intra approver overrides
				approversMap = bg_DiscountUtils.GetQuoteDiscountApprovers(salesUser.Id, 'GB', 'GBP', 200000.00, 0.00, false, true);
				system.assertEquals(1, approversMap.get(bg_DiscountUtils.PREAPPROVER_FIELD_NAME).size());				
				system.assertEquals(5, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).size());

				approverMap = new map<Id, User>();
				approverMap.putAll(approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).values());
				system.assertEquals(true, approverMap.containsKey(overrideInRegApproverUser.Id));

				// Check regional / intra approver overrides
				approversMap = bg_DiscountUtils.GetQuoteDiscountApprovers(salesUser.Id, 'GB', 'GBP', 200000.00, 0.00, true, true);
				system.assertEquals(1, approversMap.get(bg_DiscountUtils.PREAPPROVER_FIELD_NAME).size());				
				system.assertEquals(5, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).size());

				approverMap = new map<Id, User>();
				approverMap.putAll(approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).values());
				system.assertEquals(true, approverMap.containsKey(overrideRegApproverUser.Id));


				// Test populate of quote discount approver fields
				bg_DiscountUtils.PopulateQuoteDiscountApprovers(quote, approversMap);

				system.assertEquals(preApproverUser2.Id, quote.Discount_PreApprover_1__c); 
				system.assertEquals(quote.Discount_Approver_1__c, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).get(bg_DiscountUtils.APPROVER_FIELD_NAME + '_1').Id);
				system.assertEquals(quote.Discount_Approver_2__c, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).get(bg_DiscountUtils.APPROVER_FIELD_NAME + '_2').Id);
				system.assertEquals(quote.Discount_Approver_3__c, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).get(bg_DiscountUtils.APPROVER_FIELD_NAME + '_3').Id);
				system.assertEquals(quote.Discount_Approver_4__c, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).get(bg_DiscountUtils.APPROVER_FIELD_NAME + '_4').Id);
				system.assertEquals(quote.Discount_Approver_5__c, approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).get(bg_DiscountUtils.APPROVER_FIELD_NAME + '_5').Id);

			test.stopTest();
		}
	}

	public static Discount_Matrix_Record__c GetDiscountMatrixRecord(Discount_Matrix__c dm, decimal minValue, decimal maxValue, decimal minDiscount, decimal maxDiscount) {
		/*
			Get New discount matrix record
		*/
		Discount_Matrix_Record__c dmr = new Discount_Matrix_Record__c();
		dmr.Discount_Matrix__c = dm.Id;
		dmr.CurrencyIsoCode = dm.CurrencyIsoCode;
		dmr.Minimum_Value__c = minValue;
		dmr.Maximum_Value__c = maxValue;
		dmr.Minimum_Discount__c = minDiscount;
		dmr.Maximum_Discount__c = maxDiscount;
		dmr.Approval_Type__c = 'Unanimous';
		return dmr;		
	}

	private static testMethod void testGetDiscountQuote() {
		/*
			Test GetDiscountQuote method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);

		test.startTest();
			quote = bg_DiscountUtils.GetDiscountQuote(quote.Id);
			system.assertNotEquals(null, quote.Id);
		test.stopTest();		
	}

	private static testMethod void testIsQuoteIntraRegional() {
		/*
			Test IsQuoteIntraRegional method
		*/
		// create discount regions
		Discount_Region__c region1 = new Discount_Region__c();
		region1.Region__c = 'EMEA';
		region1.Country_Code__c = 'GB';
		insert region1;

		Discount_Region__c region2 = new Discount_Region__c();
		region1.Region__c = 'Americas';
		region2.Country_Code__c = 'US';
		insert region2;

		// Create opportunity & oppportunity sites
    	bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();    	

		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_DISCOUNTUTILS');
		Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_DISCOUNTUTILS_SITE1', bg_SiteUtils.COUNTRY_CODE_UK, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'GB2 9AB');
		Site__c site2 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_DISCOUNTUTILS_SITE2', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'US3 9AB');
		Site__c site3 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_DISCOUNTUTILS_SITE3', bg_SiteUtils.COUNTRY_CODE_IRELAND, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'IR4 9AB');		
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);
		bg_UnitTestHelper.GetOpportunitySite(opportunity1, site2);
		bg_UnitTestHelper.GetOpportunitySite(opportunity1, site3); 	

		test.startTest();
			system.assertEquals(true, bg_DiscountUtils.IsQuoteIntraRegional(opportunity1.Id));

			site1.Country_Code__c = bg_SiteUtils.COUNTRY_CODE_UK;
			site2.Country_Code__c = bg_SiteUtils.COUNTRY_CODE_UK;
			site3.Country_Code__c = bg_SiteUtils.COUNTRY_CODE_UK;
			update(new list<Site__c>{site1, site2, site3});

			system.assertEquals(false, bg_DiscountUtils.IsQuoteIntraRegional(opportunity1.Id));
		test.stopTest();		
	}
	
	private static testMethod void testIsQuoteRegional() {
		/*
			Test IsQuoteRegional method
		*/

		// create discount regions
		Discount_Region__c region1 = new Discount_Region__c();
		region1.Region__c = 'EMEA';
		region1.Country_Code__c = 'GB';
		insert region1;

		Discount_Region__c region2 = new Discount_Region__c();
		region2.Region__c = 'Americas';
		region2.Country_Code__c = 'US';
		insert region2;

		// Create opportunity & oppportunity sites
    	bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();    	

		Account account1 = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_DISCOUNTUTILS');
		Site__c site1 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_DISCOUNTUTILS_SITE1', bg_SiteUtils.COUNTRY_CODE_UK, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'GB2 9AB');
		Site__c site2 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_DISCOUNTUTILS_SITE2', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'US3 9AB');
		Site__c site3 = bg_UnitTestHelper.GetSite(account1, 'UT_SITE_DISCOUNTUTILS_SITE3', bg_SiteUtils.COUNTRY_CODE_IRELAND, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'IR4 9AB');		
		Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity(account1);
		bg_UnitTestHelper.GetOpportunitySite(opportunity1, site1, true);
		bg_UnitTestHelper.GetOpportunitySite(opportunity1, site2);
		bg_UnitTestHelper.GetOpportunitySite(opportunity1, site3); 		

		test.startTest();
			system.assertEquals(true, bg_DiscountUtils.IsQuoteRegional(opportunity1.Id));

			site1.Country_Code__c = bg_SiteUtils.COUNTRY_CODE_UK;
			site2.Country_Code__c = bg_SiteUtils.COUNTRY_CODE_IRELAND;
			site3.Country_Code__c = bg_SiteUtils.COUNTRY_CODE_IRELAND;
			update(new list<Site__c>{site1, site2, site3});

			system.assertEquals(false, bg_DiscountUtils.IsQuoteRegional(opportunity1.Id));
		test.stopTest();		
	}
	
	private static testMethod void testGetDiscountUserMatrix() {
		/*
			Test GetDiscountUserMatrix method
		*/

		User salesUser1 = bg_UnitTestHelper.GetUser('BG_SU1@brightgen.com.test', 'BG_SU1@brightgen.com.test', 'tstuserxsu1');
		User salesUser2 = bg_UnitTestHelper.GetUser('BG_SU2@brightgen.com.test', 'BG_SU2@brightgen.com.test', 'tstuserxsu2');
		
		// create discount region
		Discount_Region__c region1 = new Discount_Region__c();
		region1.Region__c = 'EMEA';
		region1.Country_Code__c = 'GB';
		insert region1;

		// create discount matrix
		Discount_Matrix__c dm = new Discount_Matrix__c();
		dm.Name = 'UT-Discount_Matrix';
		dm.Active__c = true;
		insert dm;
		
		// create discount matrix user record for sales user
		Discount_User_Matrix__c dum = new Discount_User_Matrix__c();
		dum.Discount_Matrix__c = dm.Id;
		dum.User__c = salesUser1.Id;
		insert dum;

		test.startTest();
			system.assertNotEquals(null, bg_DiscountUtils.GetDiscountUserMatrix(salesUser1.Id));
			system.assertEquals(null, bg_DiscountUtils.GetDiscountUserMatrix(salesUser2.Id));
		test.stopTest();
	}
	
	private static testMethod void testSetDiscountStatus() {
		/*
			Test GetDiscountUserMatrix method
		*/
		QuoteSetting__c qs = bg_CustomSettingsUtils.GetQuoteSettings();

		map<string, map<string, User>> approversMap = new map<string, map<string, User>>();
		approversMap.put(bg_DiscountUtils.APPROVER_FIELD_NAME, new map<string, User>());

		test.startTest();
			// Test NA status
			system.assertEquals(qs.StatusNA__c, bg_DiscountUtils.SetDiscountStatus('', approversMap));

			// Test Draft status
			approversMap.get(bg_DiscountUtils.APPROVER_FIELD_NAME).put('Approver1', null);
			system.assertEquals(qs.StatusDraft__c, bg_DiscountUtils.SetDiscountStatus('', approversMap));
		test.stopTest();
	}

	
	private static testMethod void testSkipRegionalApproval() {
		/*
			Test GetDiscountUserMatrix method
		*/
		bg_CustomSettingsUtils.GetQuoteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();

		Opportunity opp = bg_UnitTestHelper.GetOpportunity();
		
		Product__c productA = bg_UnitTestHelper.GetProduct('Product A');
		Product__c productB = bg_UnitTestHelper.GetProduct('Product B');
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProductA = bg_UnitTestHelper.GetQuoteProduct(quote, null, productA);
		Quote_Product__c quoteProductB = bg_UnitTestHelper.GetQuoteProduct(quote, null, productB);

		test.startTest();
			system.assertEquals(false, bg_DiscountUtils.SkipRegionalApproval(quote.Id));

			productA.Skip_Regional_Approval__c = true;
			update productA;
			system.assertEquals(false, bg_DiscountUtils.SkipRegionalApproval(quote.Id));

			productB.Skip_Regional_Approval__c = true;
			update productB;
			system.assertEquals(true, bg_DiscountUtils.SkipRegionalApproval(quote.Id));
		test.stopTest();				
	}
}