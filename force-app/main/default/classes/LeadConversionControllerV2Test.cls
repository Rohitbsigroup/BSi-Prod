/*
	Changes ASD BG - 14-01-16 - Fixed unit tests due to VR rule.
    IB - 23-06-17 - Tests were not running as they did not have @testmethod annotation and @isTest(SeeAllData-true) had been removed
                            SeeAllData reintroduced due to this issue https://success.salesforce.com/issues_view?id=a1p30000000sXzfAAE ( I couldn't get the
                                runAs workaround to work )
    JK BG - 20-07-2017 - Changed leadSource to represent new PL Value
    ADS BG - 07-11-2017 - Updates for failure in converLeadTerritory() after Sandbox refresh with no other Territories than those created in the Unit Test
*/

@isTest
private class LeadConversionControllerV2Test {

    // Testing conversion with Territory
     @IsTest(SeeAllData=true)
    private static void converLeadTerritory() {

        // Assignment
        User u = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        // Initialise Custom Settings
		bg_UnitTestHelper.GetSystemSettings();

		system.runAs(u)
		{
	        Territory__c terr = bg_UnitTestHelper.GetTerritory();
	        terr.PostZipCode__c = 'XX20,TT20';
	        terr.Country__c = 'ZZ';
	        terr.AssignedTo__c = u.Id;
	        update terr;
	
	        // Set up data
	        Account acc = bg_UnitTestHelper.GetAccount('Test Account');
	        Contact con = bg_UnitTestHelper.GetContact('Test Contact');
	
	        Lead lead = bg_UnitTestHelper.CreateLead('Test Lead');
	        lead.PostalCode = 'XX20';
            // 07/11/2017 ADS - After Sandbox refresh, the Country must match that of one of the Territories created in the Unit Test
	        // lead.Country = 'GB';
	        lead.Country = 'ZZ';
	        lead.Territory__c = terr.Id;
	        lead.TotalEmployees__c = 200;
	        lead.Product_Area_Interests__c = 'Advisory';
	        //lead.Existing_Customer_Account__c = acc.Id;
	        insert lead;

	        Task task = new Task();
	        task.ActivityDate = Date.today();
	        task.Subject = 'Test';
	        task.Status = 'Not Started';
	        task.WhoId = lead.Id;
	        task.Status = 'Completed';
	        insert task;

	        lead.Status = 'Open-Contacted';	        
	        update lead;
            
	        Site__c site = TestData.getTestSite('XX20 TST');
	        site.Lead__c = lead.Id;
	        site.SkipDupeChecker__c = true;
	        insert site;
		
			test.startTest();
		        //Controller
		        Test.setCurrentPage(Page.leadConversionV2);
		        LeadConversionControllerV2 controller = new LeadConversionControllerV2(new Apexpages.Standardcontroller(lead));
		        controller.getContacts();
		        controller.getAccounts();
				controller.linkAccId = null;
				controller.selectedCurrency = 'GBP';
		        controller.convertLead();
				
		        // Check expected results
		        Lead convlead = [SELECT isConverted FROM Lead WHERE Id = :lead.Id];
		        System.assertEquals(true, convlead.isConverted);
	        		  
		        // No Account selected
		        controller.viewAccount();
	
		        // Account selected
		        controller.linkAccId = acc.Id;
		        controller.viewAccount();

				// Get Accounts
				controller.getAccounts();
						        
		        // No Contact selected
		        controller.linkConId = '';
		        controller.viewContact();
		        
		        // Contact selected
		        controller.linkConId = con.id;
		        controller.viewContact();

				System.assertNotEquals(null, controller.backConvert());
        		System.assertEquals(controller.back().getURL(), '/' + lead.Id);
			test.stopTest();
		}
    }

/*
   	// Testing Conversion with Territory and Territory assignments
	private static testmethod void convertLeadScore() {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();
        
        // Assignment
        User u = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        Territory__c terr = bg_UnitTestHelper.GetTerritory();
        terr.PostZipCode__c = 'XX20,TT20';
        terr.Country__c = 'AE';
        terr.AssignedTo__c = u.Id;
        update terr;
        
        Territory_Assignment__c range = new Territory_Assignment__c();
        range.Territory__c = terr.Id;
        range.MinScore__c = 0;
        range.MaxScore__c = 100000;
        range.AssignedTo__c = u.Id;
        insert range;

        // Set up data
        Account acc = bg_UnitTestHelper.GetAccount('Test Account');
        Contact con = bg_UnitTestHelper.GetContact('Test Contact');
        
        Lead lead = bg_UnitTestHelper.GetLead('Test Lead');
        lead.PostalCode = 'XX20';
        lead.Territory__c = terr.Id;
        lead.TotalEmployees__c = 200;
        lead.Status = 'Open-Contacted';
        lead.Product_Area_Interests__c = 'Advisory';

        Task task = new Task();
        task.ActivityDate = Date.today();
        task.Subject = 'Test';
        task.Status = 'Not Started';
        task.WhoId = lead.Id;
        task.Status = 'Completed';
        insert task;
        
        update lead;
        
        Site__c site = TestData.getTestSite('XX20 TST');
        site.Lead__c = lead.Id;
        insert site;

        //Controller
        Test.setCurrentPage(Page.leadConversionV2);
        LeadConversionControllerV2 controller = new LeadConversionControllerV2(new Apexpages.Standardcontroller(lead));
        controller.convertLead();

        // Check expected results
        Lead convlead = [SELECT isConverted FROM Lead WHERE Id =:lead.Id];
        System.assertEquals(true,convlead.isConverted);
    }
*/

    // Testing Conversion failures-special cases
    @IsTest(SeeAllData=true)
    private static void convertLeadFailure() {

        // Initialise Custom Settings
		bg_UnitTestHelper.GetSystemSettings();

        // Assignment
        User u = bg_UnitTestHelper.GetUser('BG1@brightgen.com', 'BG1@brightgen.com', 'tstuserx1');
        User u2 = bg_UnitTestHelper.GetUser('BG2@brightgen.com', 'BG2@brightgen.com', 'tstuserx2');

        BSIPermissions__c perms = new BSIPermissions__c(SetupOwnerId=u2.Id, CanChangeLeadSources__c=true, CloseWinOpportunities__c=true);
        insert perms;

        System.runAs(u2)
        {
            // Set up data
            Account acc = bg_UnitTestHelper.GetAccount('Test Account');
            Contact con = bg_UnitTestHelper.GetContact('Test Contact');

            // Set up data with wrong Country
            Territory__c terr = new Territory__c();
            terr.Country__c = 'US';
            insert terr;
            Lead lead = TestData.getTestLead();
            lead.PostalCode = 'XX20';
            lead.Country = 'AE';
            lead.OwnerId = u2.Id;
            lead.Street = 'Billing Street';
            lead.City = 'Billing City';
            insert lead;

            Task task = new Task();
            task.ActivityDate = Date.today();
            task.Subject = 'Test';
            task.Status = 'Not Started';
            task.WhoId = lead.Id;
            task.Status = 'Completed';
            insert task;

            Site__c site = TestData.getTestSite('XX20 TST');
            site.Lead__c = lead.Id;
            insert site;

            Test.startTest();
            //Controller
            Test.setCurrentPage(Page.leadConversionV2);
            LeadConversionControllerV2 controller = new LeadConversionControllerV2(new Apexpages.Standardcontroller(lead));
            
            // Failure: TERRITORY = null
            system.assertEquals(controller.showConvert, false);
            
            // Failure: TERRITORY = Country
            lead.Country = 'AD';
            update lead;
            LeadConversionControllerV2 controller2 = new LeadConversionControllerV2(new Apexpages.Standardcontroller(lead));
            system.assertEquals(controller2.showConvert, false);
            
            Territory__c terr1 = bg_UnitTestHelper.GetTerritory();
            terr1.PostZipCode__c = 'XX20';
            terr1.Country__c = 'US';
            terr1.AssignedTo__c = u.Id;
            update terr;

            // Test Self Generated Leads
            lead.Territory__c = terr1.Id;
            lead.LeadSource = 'Sales Channels';
            lead.Status = 'Open-Contacted';
            lead.Product_Area_Interests__c = 'Advisory';
            lead.Position__c = 'Influencer';
            lead.SitesNumber__c = 1;
            lead.TotalEmployees__c = 1;
            lead.PrevCustomer__c = 'No';
            lead.Delivery__c = Date.today();
            lead.RegistrationPath__c = 'Transfer';
            lead.Country = 'US';
            lead.Holding_Reason__c = 'Unit Test';

            update lead;
            LeadConversionControllerV2 controller3 = new LeadConversionControllerV2(new Apexpages.Standardcontroller(lead));
            controller3.selectedCurrency = 'GBP';
            controller3.convertLead();
            
            // Check expected results
            Lead convlead = [SELECT isConverted,ConvertedOpportunityId FROM Lead WHERE Id =:lead.Id];
            system.assertEquals(true,convlead.isConverted);
            Opportunity opty = [SELECT OwnerId FROM Opportunity WHERE Id =:convlead.ConvertedOpportunityId];
            system.assertEquals(opty.OwnerId, u2.Id);

            Test.stopTest();
        }
    }

    // Testing Conversion failures-special cases
	 @IsTest(SeeAllData=true)    
    private static void convertLeadFailure2() {
        // Initialise Custom Settings
		bg_UnitTestHelper.GetSystemSettings();

        // Assignment
        User u = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        System.runAs(u)
        {

            Territory__c terr = bg_UnitTestHelper.GetTerritory();
            terr.PostZipCode__c = 'XX20,TT20';
            terr.Country__c = 'GB';
            terr.AssignedTo__c = u.Id;
            update terr;

            // Set up data
            Account acc = bg_UnitTestHelper.GetAccount('Test Account');
            Contact con = bg_UnitTestHelper.GetContact('Test Contact');

            Lead lead = bg_UnitTestHelper.GetLead('Test Lead');
            lead.PostalCode = 'XX20';
            lead.Territory__c = terr.Id;
            lead.TotalEmployees__c = 200;
            update lead;

            Site__c site = TestData.getTestSite('XX20 TST');
            site.Lead__c = lead.Id;
            insert site;

            //Controller
            Test.setCurrentPage(Page.leadConversionV2);
            LeadConversionControllerV2 controller = new LeadConversionControllerV2(new Apexpages.Standardcontroller(lead));

            // Check expected results
            Lead convlead = [SELECT isConverted FROM Lead WHERE Id =:lead.Id];
            System.assertEquals(false,convlead.isConverted);
        }
    }

/*    
    @IsTest(SeeAllData=true)
    private static void convertLeadSiteDuplication() {
        // Initialise Custom Settings
		SystemSetting__c cs = bg_UnitTestHelper.GetSystemSettings();
	    cs.SkipSiteDupeCheck__c = false;
        upsert cs;
        
        // Assignment
        User u = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');

        System.runAs(u)
        {
            Territory__c terr = bg_UnitTestHelper.GetTerritory();
            terr.PostZipCode__c = 'XX20';
            terr.Country__c = 'US';
            terr.AssignedTo__c = u.Id;
            update terr;

            // Set up data
            Account acc = bg_UnitTestHelper.GetAccount('Test Account');
            Contact con = bg_UnitTestHelper.GetContact('Test Contact', acc);
            Site__c siteAccount = bg_UnitTestHelper.GetSite(acc, 'Site Account', 'UK', bg_SiteUtils.RECORD_TYPE_NAME_NAMED, 'XX20 TST');

            Lead lead = bg_UnitTestHelper.GetLead('Test Lead');          
            lead.PostalCode = 'XX20';
            lead.Territory__c = terr.Id;
            lead.Existing_Customer_Account__c = acc.id;
            lead.Product_Area_Interests__c = 'Advisory';
            lead.Position__c = 'Influencer';
            lead.SitesNumber__c = 10;
            lead.TotalEmployees__c = 200;
            lead.PrevCustomer__c = 'No';
            lead.Delivery__c = Date.today();
            lead.RegistrationPath__c = 'Transfer';
            lead.Country = 'US';
            lead.Holding_Reason__c = 'Unit Test';

            Task task = new Task();
            task.ActivityDate = Date.today();
            task.Subject = 'Test';
            task.Status = 'Not Started';
            task.WhoId = lead.Id;
            task.Status = 'Completed';
            insert task;

            lead.Status = 'Open-Contacted';
            update lead;

            Site__c site = new Site__c();
            site.Name = 'Lead Site';
            site.Country__c = 'GB';
            site.Postcode__c = 'XX20 TST';
            site.Lead__c = lead.id;
            site.RecordTypeId = bg_RecordTypeUtils.GetRecordTypes(bg_RecordTypeUtils.OBJECT_NAME_SITE).get(bg_SiteUtils.RECORD_TYPE_NAME_NAMED).Id;
            site.Type__c = 'MANUFACTURING';
            site.TCodeDescr__c = 'MANUFACTURING';
            insert site;

            Test.startTest();
            //Controller
            Test.setCurrentPage(Page.leadConversionV2);
            LeadConversionControllerV2 controller = new LeadConversionControllerV2(new Apexpages.Standardcontroller(lead));
            controller.getAccounts();
            controller.getContacts();
            controller.linkAccId = acc.id;
            controller.convertLead();

            // Check expected results
            Lead convlead = [SELECT isConverted FROM Lead WHERE Id =:lead.Id];
            System.assertEquals(false,convlead.isConverted);
            
            System.assertEquals(true, controller.dupeSite);

            System.assertNotEquals(0, controller.getSites().size());

            Map<Site__c,Site__c> updateSiteErrors = controller.getSites();

            for (Site__c newSite : updateSiteErrors.keySet()) {
                newSite.SkipDupeChecker__c = true;
            }
            controller.siteErrors = updateSiteErrors;

            controller.updateSite();

            convlead = [SELECT isConverted FROM Lead WHERE Id =:lead.Id];
            System.assertEquals(true,convlead.isConverted);

            Test.stopTest();
        }
    }
*/
}