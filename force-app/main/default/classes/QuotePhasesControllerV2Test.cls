/********************************************************************
 * QuotePhasesControllerV2Test
 *
 * Test class for QuotePhaseControllerV2
 * 
 * 
 * Author: Richard Jimenez
 * Created: 18-12-2013
 * Changes: 
 *          21-11-2014 RPJ - Added new discount matrix methods
 *                         - Removed redundant / unused code
 *          KM - 15/10/2014
 *          modified quotePhaseV2Test to reset quote 
 *       KM 13/02/2015  Commented out a few assertions I believed to be wrong, signed off by NF
 *          ADS 03/11/16 - SoW027
 *          AVC 19/07/2017 - added a method testAutoSkipCustomer()
 *			IB 06/09/17 - Added testNoQuoteContact_Error()
 *      RC 11/09/17 - Added check for submitForProposal button
 ********************************************************************/
@isTest
private class QuotePhasesControllerV2Test {
    
    // TEST FULL QUOTE PHASE
    private static testMethod void quotePhaseV2Test() {
        // Set up data
        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.GetQuoteSettings();

        string productName = 'ISO 9001';
        Product__c product = bg_UnitTestHelper.GetProduct(productName);

        // Custom Setting and User
        User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        testUser.Requires_Operations_Approval__c = true;
        update testUser;

    system.runAs(testUser)
    {
      SetupDiscountMatrix(testUser);

          Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
          Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
      Contact techReviewContact = bg_UnitTestHelper.GetContact('Harry', acc);

      Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
          OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);       
  
          Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
          quote.Contact__c = techReviewContact.id; // also set a contact so proposal generation passes
          update quote;
          Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
          Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, true, quoteProduct);
  
          test.startTest();
              Test.setCurrentPage(Page.quotePhaseV2);
              QuotePhasesControllerV2 controller = new QuotePhasesControllerV2(new Apexpages.Standardcontroller(quote));
  
              system.assertEquals(false, controller.getCustomerComplete());
              system.assertEquals(true, controller.getDiscountComplete());
              system.assertEquals(true, controller.getCCodeComplete());
              //system.assertEquals(true,  controller.getCanSkipFactValidation());
  
              // Check Validation Status
              system.assertEquals(false, controller.getValidationStatusNA());
              system.assertEquals(false, controller.getValidationStatusApproved());
              system.assertEquals(false, controller.getValidationStatusRejected());
              system.assertEquals(true,  controller.getValidationStatusDraft());
              system.assertEquals(false, controller.getValidationStatusPending());
  
              // Check Discount Status
              system.assertEquals(false, controller.getNoDiscountApprover());
              system.assertEquals(true, controller.getDiscountStatusNA());
              system.assertEquals(false, controller.getDiscountStatusApproved());
              system.assertEquals(false, controller.getDiscountStatusPending());
              system.assertEquals(false, controller.getDiscountStatusRejected());
              system.assertEquals(false, controller.getDiscountStatusDraft());                        
              system.assertEquals(-2, controller.getNoDiscountableParts());
              system.assertEquals(false, controller.getRequiresDiscountPreApprover());

              // Check C-Code Status
              system.assertEquals(true, controller.getCCodeStatusNA());
              system.assertEquals(false, controller.getCCodeStatusApproved());
              system.assertEquals(false, controller.getCCodeStatusPending());
              system.assertEquals(false, controller.getCCodeStatusRejected());
              system.assertEquals(false, controller.getCCodeStatusDraft());
  
              // Check Tech Review Status
              system.assertEquals(true,  controller.getTechReviewStatusNA());
              system.assertEquals(false, controller.getTechReviewStatusApproved());
              system.assertEquals(false, controller.getTechReviewStatusRejected());
              system.assertEquals(false, controller.getTechReviewStatusDraft());
              system.assertEquals(false, controller.getTechReviewStatusPending());
              system.assertEquals(true, controller.getTechReviewComplete());          
  
              // Check Proposal Status
              system.assertEquals(false, controller.getProposalSignedOffline());
              system.assertEquals(false, controller.getProposalStatusNA());
              system.assertEquals(false, controller.getProposalStatusApproved());
              system.assertEquals(false, controller.getProposalStatusRejected());
              system.assertEquals(true, controller.getProposalStatusDraft());
              system.assertEquals(false, controller.getProposalStatusPending());
  
              // Check Finance Status
              system.assertEquals(true, controller.getFinanceStatusNA());
              system.assertEquals(false, controller.getFinanceStatusApproved());
              system.assertEquals(false, controller.getFinanceStatusPending());
              system.assertEquals(false, controller.getFinanceStatusRejected());
              system.assertEquals(false, controller.getFinanceStatusDraft());
              system.assertEquals(true, controller.getFinanceStatusComplete());
              system.assertEquals(1, controller.getTechReviewTeams().size());
  
        // Check Operation Status
              system.assertEquals(false, controller.getOperationsReviewStatusNA());
              system.assertEquals(false, controller.getOperationsReviewStatusApproved());
              system.assertEquals(false, controller.getOperationsReviewStatusPending());
              system.assertEquals(false, controller.getOperationsReviewStatusRejected());
              system.assertEquals(true, controller.getOperationsReviewStatusDraft());
              system.assertEquals(false, controller.getOperationsReviewStatusComplete());

              controller.GetCCodeApprovers();         
              system.assertEquals(1, controller.cCodeApproversMap.size());
              system.assertEquals(true, controller.showLocalApprovers);
  
        system.assertNotEquals(null, controller.ConfigureQuote());
        system.assertNotEquals(null, controller.ConfigureProducts());
        //KM - The below assertion relies on the global pricebook throwing a null pointer exception due to it being in test context
        //system.assertEquals(null, controller.BrowseKeysFactsTemplate());
        system.assertNotEquals(null, controller.GenerateKeyFactsDocument());
        system.assertNotEquals(null, controller.BrowseProposalTemplate());
        system.assertNotEquals(null, controller.GenerateProposalDocument());
        system.assertNotEquals(null, controller.BrowseSalesBriefTemplate());
        system.assertNotEquals(null, controller.GenerateSalesBriefDocument());

        quote.Tech_Review_Team__c = techReviewContact.Id;
        system.assertNotEquals(null, quote.Tech_Review_Team__c);
        //system.assertNotEquals(null, controller.GenerateTechReviewDocument());
        //system.assertNotEquals(null, controller.BrowseTechReviewTemplate());

              controller.SkipTechReview();

        controller.ConfigurePrices();
        system.assertNotEquals(null, controller.reloadPageURL);
        
        controller.RequestDiscountApproval();

        //controller.submitProposalForApproval();

        test.stopTest();
    }
    }

    /*
    * Function to test submitting propsal for approval but with no user selected
    */
    private static testMethod void testSubmitProposalForApprovalNoUserSelected() 
    {
      // Set up data
      bg_UnitTestHelper.GetDefaultCountrySetting();
      bg_UnitTestHelper.GetQuoteSettings();

      string productName = 'ISO 9001';
      Product__c product = bg_UnitTestHelper.GetProduct(productName);
      
      // Custom Setting and User
      User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

      User approvalUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BGAP@brightgen.com', 'tstuserx');

      SetupDiscountMatrix(testUser);

      System.runAs(testUser) 
      {
        Test.startTest();
        Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
        Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);    

        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
        Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, true, quoteProduct);
        Test.stopTest();

        Test.setCurrentPage(Page.quotePhasesV2);
        QuotePhasesControllerV2 controller = new QuotePhasesControllerV2(new Apexpages.Standardcontroller(quote));

        //submit for proposal approval 
        controller.submitProposalForApproval();
      }

      //check to see that a apex message was displayed this is a standard salesforce message so can't compare
      System.assertEquals(true, ApexPages.hasMessages());
    }

    /*
    * Function to test submitting proposal for approval
    */
    private static testMethod void testSubmitProposalForApproval() 
    {
      // Set up data
      bg_UnitTestHelper.GetDefaultCountrySetting();
      bg_UnitTestHelper.GetQuoteSettings();

      string productName = 'ISO 9001';
      Product__c product = bg_UnitTestHelper.GetProduct(productName);
      
      // Custom Setting and User
      User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

      User approvalUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BGAP@brightgen.com', 'tstuserx');

      //update test user with approval user shouldn't need to test it as it should load automatically.
      testUser.PS_Approval_User__c = approvalUser.Id;
      update testUser;

      SetupDiscountMatrix(testUser);

      System.runAs(testUser) 
      {
        Test.startTest();
        Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
        Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
        Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
        OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);    

        Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
        Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
        Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, true, quoteProduct);
        Test.stopTest();

        Test.setCurrentPage(Page.quotePhasesV2);
        QuotePhasesControllerV2 controller = new QuotePhasesControllerV2(new Apexpages.Standardcontroller(quote));

        //check that the record is not in approval process
        List<ProcessInstance> piBefore = [SELECT TargetObjectId FROM ProcessInstance WHERE TargetObjectId = :quote.Id];
        System.assertEquals(0, piBefore.size());

        //submit for proposal approval 
        controller.submitProposalForApproval();

        //check that the record has gone into the approval process
        List<ProcessInstance> piAfter = [SELECT TargetObjectId FROM ProcessInstance WHERE TargetObjectId = :quote.Id];
        System.assertEquals(1, piAfter.size());

     
      }
    }


    
      // TEST FULL QUOTE PHASE
    private static testMethod void quotePhaseV2TestReset() {
        // Set up data
    bg_UnitTestHelper.GetDefaultCountrySetting();
    bg_UnitTestHelper.GetQuoteSettings();

    string productName = 'ISO 9001';
    Product__c product = bg_UnitTestHelper.GetProduct(productName);
      
      // Custom Setting and User
    User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

    SetupDiscountMatrix(testUser);

      System.runAs(testUser) 
      {
      Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
      Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
      Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
      OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);    

      Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
      Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
      Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, true, quoteProduct);

        // Run as Salesperson
        test.startTest();
  
          Test.setCurrentPage(Page.quotePhasesV2);
          QuotePhasesControllerV2 controller = new QuotePhasesControllerV2(new Apexpages.Standardcontroller(quote));
    
        controller.GetCCodeApprovers();      
        controller.SkipCustomer();
        controller.SkipTechReview();
        system.assertEquals(true, controller.getCustomerComplete());
        system.assertEquals(true, controller.getDiscountComplete());  
        controller.ResetQuoteStages();
        system.assertEquals(false, controller.getCustomerComplete());
        system.assertEquals(false, controller.getDiscountComplete());
        test.stopTest();
      }
    }

    private static void SetupDiscountMatrix(User saleUser) {
    bg_UnitTestHelper.GetDefaultCountrySetting();

    // create discount region
    Discount_Region__c region1 = new Discount_Region__c();
    region1.Regional_Approver__c = saleUser.Id;
    region1.IntraRegional_Approver__c = saleUser.Id;
    region1.Region__c = 'EMEA';
    region1.Country_Code__c = saleUser.OperationCountry__c;
    insert region1;

    // create discount matrix
    Discount_Matrix__c dm = new Discount_Matrix__c();
    dm.Name = 'UT-Discount_Matrix';
    dm.Active__c = true;
    dm.Description__c = 'UT-Discount-Matrix-Description';
    dm.CurrencyIsoCode = 'GBP';
    insert dm;

    // create discount matrix user record for sales user
    Discount_User_Matrix__c dum = new Discount_User_Matrix__c();
    dum.Discount_Matrix__c = dm.Id;
    dum.User__c = saleUser.Id;
    insert dum;

    // create discount matrix record - with no approvers required
    list<Discount_Matrix_Record__c> dmrs = new list<Discount_Matrix_Record__c>(); 
    Discount_Matrix_Record__c dmr;
    dmr = bg_DiscountUtilsTest.GetDiscountMatrixRecord(dm, 0.00,  40000.00, 0.00, 0.01);
    dmrs.add(dmr);

    // create discount matrix record - 2 approvers required
    dmr = bg_DiscountUtilsTest.GetDiscountMatrixRecord(dm, 40000.00,  150000.00, 0.00, 0.01);
    dmr.Approver_1_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;
    dmr.Approver_1__c = saleUser.Id;
    dmrs.add(dmr);

    // create discount matrix record - 4 approvers required
    dmr = bg_DiscountUtilsTest.GetDiscountMatrixRecord(dm, 150000.00,  200000.00, 0.00, 0.01);
    dmr.Approver_1_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;
    dmr.Approver_1__c = saleUser.Id;
    dmrs.add(dmr);

    // create discount matrix record - 4 approvers required & regional approver overrides
    dmr = bg_DiscountUtilsTest.GetDiscountMatrixRecord(dm, 200000.00,  null, 0.00, 0.01);
    dmr.Approver_1_Type__c = bg_DiscountUtils.USER_APPROVER_TYPE;
    dmr.Approver_1__c = saleUser.Id;    
    dmrs.add(dmr);

    // Insert all discount matrix records
    insert dmrs;      
    }
    
    public static testMethod void testRetrieveQuoteStatus_Action_InProgress()
    {
      // Set up data
    bg_UnitTestHelper.GetDefaultCountrySetting();
    bg_UnitTestHelper.GetQuoteSettings();

    string productName = 'ISO 9001';
    Product__c product = bg_UnitTestHelper.GetProduct(productName);

        // Custom Setting and User
        User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

    system.runAs(testUser)
    {
      SetupDiscountMatrix(testUser);

          Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
      Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);  
          Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
      quote.Sync_In_Progress__c = bg_QuoteUtils.SYNC_STATUS_COMPLETE;
      update quote;    
      QuotePhasesControllerV2 quoteController = new QuotePhasesControllerV2(new Apexpages.Standardcontroller(quote));
      quote.Sync_In_Progress__c = bg_QuoteUtils.SYNC_STATUS_RUNNING;
      update quote;    

          test.startTest();
            quoteController.retrieveQuoteStatus_Action();
        System.assertEquals(bg_QuoteUtils.SYNC_STATUS_RUNNING, quoteController.syncStatus);
      test.stopTest();
    }
  }

  public static testMethod void testRetrieveQuoteStatus_Action_Complete()
    {
      // Set up data
    bg_UnitTestHelper.GetDefaultCountrySetting();
    bg_UnitTestHelper.GetQuoteSettings();

    string productName = 'ISO 9001';
    Product__c product = bg_UnitTestHelper.GetProduct(productName);

        // Custom Setting and User
        User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

    system.runAs(testUser)
    {
      SetupDiscountMatrix(testUser);

          Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
      Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);  
          Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
      quote.Sync_In_Progress__c = bg_QuoteUtils.SYNC_STATUS_RUNNING;
      update quote;
      QuotePhasesControllerV2 quoteController = new QuotePhasesControllerV2(new Apexpages.Standardcontroller(quote));
      quote.Sync_In_Progress__c = bg_QuoteUtils.SYNC_STATUS_COMPLETE;
      update quote;

          test.startTest();
            quoteController.retrieveQuoteStatus_Action();
        System.assertEquals(bg_QuoteUtils.SYNC_STATUS_COMPLETE, quoteController.syncStatus);
      test.stopTest();
    }

    }

    /*
    Tests that when the retrieve quote status action is called when the status is in error
    the sync status is set to error.
    */
    public static testMethod void testRetrieveQuoteStatus_Action_Error()
    {
      // Set up data
    bg_UnitTestHelper.GetDefaultCountrySetting();
    bg_UnitTestHelper.GetQuoteSettings();

    string productName = 'ISO 9001';
    Product__c product = bg_UnitTestHelper.GetProduct(productName);

        // Custom Setting and User
        User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

    system.runAs(testUser)
    {
      SetupDiscountMatrix(testUser);

          Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
      Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
          Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
      quote.Sync_In_Progress__c = bg_QuoteUtils.SYNC_STATUS_RUNNING;
      update quote;
      QuotePhasesControllerV2 quoteController = new QuotePhasesControllerV2(new Apexpages.Standardcontroller(quote));
      quote.Sync_In_Progress__c = bg_QuoteUtils.SYNC_STATUS_ERROR;
      update quote;
      
          test.startTest();
            quoteController.retrieveQuoteStatus_Action();
        System.assertEquals(bg_QuoteUtils.SYNC_STATUS_ERROR, quoteController.syncStatus);
      test.stopTest();
    }

    }

  /*
    Tests that the check error message adds an error to the page and returns true
    if the sync stats is error.
  */
  public static testMethod void testCheckSyncError_Error()
    {
      // Set up data
    bg_UnitTestHelper.GetDefaultCountrySetting();
    bg_UnitTestHelper.GetQuoteSettings();

    string productName = 'ISO 9001';
    Product__c product = bg_UnitTestHelper.GetProduct(productName);

        // Custom Setting and User
        User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

    system.runAs(testUser)
    {
      SetupDiscountMatrix(testUser);

          Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
      Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);  
          Quote__c quote = bg_UnitTestHelper.GetQuote(opp);

      QuotePhasesControllerV2 quoteController = new QuotePhasesControllerV2(new Apexpages.Standardcontroller(quote));
      quote.Sync_In_Progress__c = bg_QuoteUtils.SYNC_STATUS_ERROR;
      update quote;

      List<ApexPages.Message> originalMessages = ApexPages.getMessages();
      
          test.startTest();
            Boolean returnVal = quoteController.checkSyncError();
      test.stopTest();

      System.assertEquals(true, returnVal);
      List<ApexPages.Message> messages = ApexPages.getMessages();
      messages = ApexPages.getMessages();
      system.assertNotEquals(originalMessages.size(), messages.size());
    }
  }
  
  /*
    Tests that an error is written if there is no Quote Contact when the Proposal Document button is clicked
  */
  
  public static testMethod void testNoQuoteContact_Error()
    {
      // Set up data
    bg_UnitTestHelper.GetDefaultCountrySetting();
    bg_UnitTestHelper.GetQuoteSettings();

    string productName = 'ISO 9001';
    Product__c product = bg_UnitTestHelper.GetProduct(productName);

    // Custom Setting and User
    User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

    system.runAs(testUser)
    {
      SetupDiscountMatrix(testUser);

      Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
      // create a Contact but don't assign to the quote it immediately
  	  Contact quoteContact = bg_UnitTestHelper.GetContact('Harry', acc);
      Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);  
      Quote__c quote = bg_UnitTestHelper.GetQuote(opp);

      QuotePhasesControllerV2 quoteController = new QuotePhasesControllerV2(new Apexpages.Standardcontroller(quote));

      List<ApexPages.Message> originalMessages = ApexPages.getMessages();
      Quote__c preRunQuote = [select id, Contact__c from Quote__c where id = :quote.id];
      System.assertEquals(null, preRunQuote.Contact__c);

      quoteController.BrowseProposalTemplate();

      List<ApexPages.Message> messages = ApexPages.getMessages();
      messages = ApexPages.getMessages();
      system.assertNotEquals(originalMessages.size(), messages.size());
      Boolean expectedExceptionAdded;
      for ( ApexPages.Message m : messages)
      {
      	if (m.getDetail() == Label.NoQuoteContact)
        {
        	expectedExceptionAdded = true;
        }
      }
      system.assertEquals(true, expectedExceptionAdded);
    }
  }
  
  /*
    Tests that no error is written if there is a Quote Contact when the Proposal Document button is clicked
  */
  
  public static testMethod void testNoQuoteContact_Error_Pass()
    {
      // Set up data
    bg_UnitTestHelper.GetDefaultCountrySetting();
    bg_UnitTestHelper.GetQuoteSettings();

    string productName = 'ISO 9001';
    Product__c product = bg_UnitTestHelper.GetProduct(productName);

    // Custom Setting and User
    User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

    system.runAs(testUser)
    {
      SetupDiscountMatrix(testUser);

      Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
      // create a Contact but don't assign to the quote it immediately
  	  Contact quoteContact = bg_UnitTestHelper.GetContact('Harry', acc);
      Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);  
      Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
      quote.Contact__c = quoteContact.id;
	  update quote;   

      QuotePhasesControllerV2 quoteController = new QuotePhasesControllerV2(new Apexpages.Standardcontroller(quote));
      List<ApexPages.Message> originalMessages = ApexPages.getMessages();

      quoteController.BrowseProposalTemplate();
      List<ApexPages.Message> messages = ApexPages.getMessages();
      System.debug('messages = ' + messages);
      system.assertEquals(originalMessages.size(), messages.size());
      
    }
  }
    @isTest static void testAutoSkipCustomer()
    {
        // Set up data
        bg_UnitTestHelper.GetDefaultCountrySetting();
        bg_UnitTestHelper.GetQuoteSettings();

        string productName = 'ISO 9001';
        Product__c product = bg_UnitTestHelper.GetProduct(productName);

        // Custom Setting and User
        User testUser = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        SetupDiscountMatrix(testUser);

        System.runAs(testUser)
        {
            Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_PRICEBOOKUTILS');
            Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
            Site__c siteHQ = bg_UnitTestHelper.GetSite(acc, 'UT_SITE_PRICEBOOKUTILS_HQ', bg_SiteUtils.COUNTRY_CODE_US, bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'CM2 9AB');
            OpportunitySite__c oppSite = bg_UnitTestHelper.GetOpportunitySite(opp, siteHQ, true);

            Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
            
            Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);
            Quote_Part__c quotePart = bg_UnitTestHelper.GetQuotePart(quote.Id, product, 0, true, quoteProduct);

            // Run as Salesperson
            test.startTest();
            Test.setCurrentPage(Page.quotePhaseV2);
            QuotePhasesControllerV2 controller = new QuotePhasesControllerV2(new Apexpages.Standardcontroller(quote));

            //BSIPermissions__c BSIPermission = [Select id, Can_Skip_Fact_Validation__c, SetupOwnerId from BSIPermissions__c where SetupOwnerId=: '0057E000003CFHx'] ;
            BSIPermissions__c BSIPermission =  bg_CustomSettingsUtils.GetPermissionSettings();//bg_UnitTestHelper.CreateBSIPermissionsSetting(true,true,true,true,true,true,true);
            BSIPermission.Can_Skip_Fact_Validation__c = true;
            upsert BSIPermission;

            system.assertEquals(false,controller.quote.SkipCustomer__c);

            System.debug('testAutoSkipCustomer: quote before' + quote);
            controller.quote.Configuration_Completed__c = true;
            
            update controller.quote;
            System.debug('testAutoSkipCustomer: quote after' + quote);
            controller.GetCCodeApprovers();
            controller.autoSkipCustomer();

            system.assertEquals(true,controller.quote.SkipCustomer__c);

            BSIPermission.Can_Skip_Fact_Validation__c = false;
            upsert BSIPermission;

            controller.quote.SkipCustomer__c = false;
            update controller.quote;

            controller.autoSkipCustomer();

            system.assertEquals(false,controller.quote.SkipCustomer__c);
            controller.SkipTechReview();

            test.stopTest();
        }
    }
}