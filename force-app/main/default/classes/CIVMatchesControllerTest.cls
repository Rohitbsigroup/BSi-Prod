/********************************************************************
 * CIVMatchesControllerTest
 *
 * Test class for CIVMatchesController
 * 
 * 
 * Author: Alexis Lignereux
 * Created: 15-09-2014
 * Changes: 
 ********************************************************************/
@isTest
private class CIVMatchesControllerTest {
    
    @isTest
    static void testErrorMessage() {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)     
        {

            // create parent record
            Lead parentLead = bg_UnitTestHelper.GetLead('Parent Lead');
            parentLead.Phone = '0123456789';
            parentLead.Email = 'test@test.com';
            parentLead.PostalCode = 'SW1W 0DT';
            parentLead.Company = 'Company Test';
            update parentLead;

            Test.startTest();
            CIVMatchesController matchesController =  new CIVMatchesController();
            matchesController.record = parentLead;

            // all filters flags should be set to true;
            system.assertEquals(true, matchesController.isLead);
            system.assertEquals(true, matchesController.isContact);
            system.assertEquals(true, matchesController.isAccount);
            system.assertEquals(false, matchesController.isOpportunity);

            // set all filters to false;
            matchesController.isLead = false;
            matchesController.isAccount = false;
            matchesController.isContact = false;

            // call filters should add error message to ApexPages
            matchesController.filter();

            List<Apexpages.Message> msgs = ApexPages.getMessages();
            boolean b = false;
            for(Apexpages.Message msg:msgs){
                if (msg.getDetail().contains(Label.CIV_Filter_Error)) { 
                    b = true;
                }
            }
            system.assert(b);

            // set all filters to false;
            matchesController.isLead = true;
            matchesController.isAccount = true;
            matchesController.isContact = true;

            // remove all search term
            matchesController.isCompanyValue = false;
            matchesController.isEmailValue = false;
            matchesController.isNameValue = false;
            matchesController.isPhoneValue = false;
            matchesController.isPostcodeValue = false;

            // call search
            matchesController.search();

            msgs = ApexPages.getMessages();
            b = false;
            for(Apexpages.Message msg:msgs){
                if (msg.getDetail().contains(Label.CIV_Search_Error)) { 
                    b = true;
                }
            }
            system.assert(b);
            Test.stopTest();
        }
    }

    @isTest 
    static void testNoResults() {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)     
        {

            // create parent record
            Lead parentLead = bg_UnitTestHelper.GetLead('Parent Lead');
            parentLead.Phone = '0123456789';
            parentLead.Email = 'test@test.com';
            parentLead.PostalCode = 'SW1W 0DT';
            parentLead.Company = 'Company Test';
            update parentLead;

            // to test SOSL need to use Test.setFixedResults methods
            // for this test we won't and results list will be 0

            /** Set up data finished **/

            Test.startTest();
            // Create an instance of the standard controller and the controller extension
            CIVMatchesController matchesController =  new CIVMatchesController();
            matchesController.record = parentLead;

            List<bg_CIVUtils.SearchResultWrapper> searchResults = matchesController.getSearchResults();
            // don't set any values to search on

            // no results should be returned
            system.assertEquals(0,searchResults.size());
            Test.stopTest();
        }
    }

    @isTest
    static void testLinkMergeForAllObjects() {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {

            // create parent record
            Lead parentLead = bg_UnitTestHelper.GetLead('Parent Lead');
            parentLead.Phone = '0123456789';
            parentLead.Email = 'test@test.com';
            parentLead.PostalCode = 'SW1W 0DT';
            parentLead.Company = 'Company Test';
            update parentLead;

            Lead lead1 = bg_UnitTestHelper.GetLead('Lead 1');
            lead1.Phone = '0123456789';
            lead1.Company = 'Company Test';
            update lead1;

            Account account1 = bg_UnitTestHelper.GetAccount('Account1');
            account1.Phone = '0123456789';
            update account1;

            Contact contact1 = bg_UnitTestHelper.GetContact('Contact 1', account1);
            contact1.Phone = '0123456789';
            update contact1;

            Opportunity opportunity1 = bg_UnitTestHelper.GetOpportunity();
            opportunity1.Name = 'Company Test';
            update opportunity1;

            // need to setup SOSL so Salesforce will allow searches
            Id [] fixedSearchResults= new Id[4];
            fixedSearchResults[0] = lead1.Id;
            fixedSearchResults[1] = account1.Id;
            fixedSearchResults[2] = contact1.Id;
            fixedSearchResults[3] = opportunity1.Id;

            Test.startTest();
            //Required so SOSL will fire in Unit Tests Properly
            Test.setFixedSearchResults(fixedSearchResults);

            /** Set up data finished **/

            // Create an instance of the standard controller and the controller extension
            CIVMatchesController matchesController =  new CIVMatchesController();
            matchesController.record = parentLead;
            matchesController.recordNameValue = parentLead.Name;
            matchesController.recordCompanyValue = parentLead.Company;
            matchesController.recordPostcodeValue = parentLead.PostalCode;
            matchesController.recordEmailValue = parentLead.Email;
            matchesController.recordPhoneValue = parentLead.Phone;
            matchesController.recordAccountId = parentLead.Existing_Customer_Account__c;
            matchesController.recordContactId = parentLead.Contact__c;
            matchesController.isOpportunity = true;

            List<bg_CIVUtils.SearchResultWrapper> searchResults = matchesController.getSearchResults();

            for (bg_CIVUtils.SearchResultWrapper sr : searchResults) {
                if (sr.objectType == 'Lead') {
                    system.assertEquals('Merge', sr.action);
                } else if (sr.objectType == 'Account' || sr.objectType == 'Contact') {
                    system.assertEquals('Sync', sr.action);

                    // link account
                    if (sr.objectType == 'Account') {
                        matchesController.actionString = sr.action;
                        matchesController.linkId = sr.recordId;
                        matchesController.actionObjectType = 'Account';
                    }
                } else if (sr.objectType == 'Opportunity') {
                    system.assertEquals(null, sr.action);
                }
            }

            // Link Account information setup in above for loop
            matchesController.linkOrMerge();
            parentLead.Existing_Customer_Account__c = account1.id;
            matchesController.recordAccountId = parentLead.Existing_Customer_Account__c;
            matchesController.record = parentLead;
            searchResults = matchesController.getSearchResults();

            //now account action should be linked
            for (bg_CIVUtils.SearchResultWrapper sr : searchResults) {
                if (sr.objectType == 'Lead') {
                    system.assertEquals('Merge', sr.action);
                } else if (sr.objectType == 'Contact') {
                    system.assertEquals('Sync', sr.action);

                    // next link contact
                    matchesController.actionString = sr.action;
                    matchesController.linkId = sr.recordId;
                    matchesController.actionObjectType = 'Contact';
                } else if (sr.objectType == 'Account') {
                    //system.assertEquals(true, matchesController.isLinked);
                    system.assertEquals('Linked', sr.action);
                } else if (sr.objectType == 'Opportunity') {
                    system.assertEquals(null, sr.action);
                }
            }

            // Link Account information setup in above for loop
            matchesController.linkOrMerge();
            parentLead.Contact__c = contact1.id;
            matchesController.recordContactId = parentLead.Contact__c;
            matchesController.record = parentLead;
            searchResults = matchesController.getSearchResults();

            //now account and contact action should be linked
            for (bg_CIVUtils.SearchResultWrapper sr : searchResults) {
                if (sr.objectType == 'Lead') {
                    system.assertEquals('Merge', sr.action);
                    // next test merge
                    matchesController.actionString = sr.action;
                    matchesController.linkId = sr.recordId;
                    matchesController.actionObjectType = 'Contact';
                } else if (sr.objectType == 'Contact' || sr.objectType == 'Account') {
                    //system.assertEquals(true, matchesController.isLinked);
                    system.assertEquals('Linked', sr.action);
                } else if (sr.objectType == 'Opportunity') {
                    system.assertEquals(null, sr.action);
                }
            }

            // once merged the lead should not longer be in the view
            matchesController.linkOrMerge();
            system.assertEquals(true, matchesController.isMerged);

            // remove lead
            fixedSearchResults= new Id[3];
            fixedSearchResults[0] = account1.Id;
            fixedSearchResults[1] = contact1.Id;
            fixedSearchResults[2] = opportunity1.Id;

            matchesController.record = parentLead;

            //Required so SOSL will fire in Unit Tests Properly
            Test.setFixedSearchResults(fixedSearchResults);

            searchResults = matchesController.getSearchResults();
            system.assertEquals(0, searchResults.size());

            Integer leadCount = 0;
            for (bg_CIVUtils.SearchResultWrapper sr : searchResults) {
                if (sr.objectType == 'Lead') {
                    leadCount++;
                }
            }

            // lead count should still be 0
            system.assertEquals(0, leadCount);
            Test.stopTest();
        }
    }

    @isTest
    static void testCheckPagination() {

        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

		list<Lead> insLeads = new list<Lead>();
		list<Account> updAccounts = new list<Account>();
		list<Contact> updContacts = new list<Contact>();
		
        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)     
        {
            // create parent record
            Lead parentLead = bg_UnitTestHelper.CreateLead('Parent Lead');
            parentLead.Phone = '0123456789';
            parentLead.Email = 'test@test.com';
            parentLead.PostalCode = 'SW1W 0DT';
            parentLead.Company = 'Company Test';
            insLeads.add(parentLead);

            // create another lead record that does not match any information from parentLead
            Lead lead1 = bg_UnitTestHelper.CreateLead('Lead 1');
            insLeads.add(lead1);

            // create another lead record that matches on Phone only
            Lead lead2 = bg_UnitTestHelper.CreateLead('Lead 2');
            lead2.Phone = '0123456789';
            insLeads.add(lead2);

            // create another lead record that matches on Phone and Email
            Lead lead3 = bg_UnitTestHelper.CreateLead('Lead 3');
            lead3.Phone = '0123456789';
            lead3.Email = 'test@test.com';
            insLeads.add(lead3);

            // create another lead record that matches on Phone, Email and PostalCode;
            Lead lead4 = bg_UnitTestHelper.CreateLead('Lead 4');
            lead4.Phone = '0123456789';
            lead4.Email = 'test@test.com';
            lead4.PostalCode = 'SW1W 0DT';
            insLeads.add(lead4);

            // create another record that matches on Phone, Email, PostalCode and Company;
            Lead lead5 = bg_UnitTestHelper.CreateLead('Lead 5');
            lead5.Phone = '0123456789';
            lead5.Email = 'test@test.com';
            lead5.PostalCode = 'SW1W 0DT';
            lead5.Company = 'Company Test';
            insLeads.add(lead5);
            
            // Update Leads
            insert insLeads;

            // create Account record that matches on nothing
            Account account1 = bg_UnitTestHelper.GetAccount('Account1');
            updAccounts.add(account1);

            // create Account record that matche on phone
            Account account2 = bg_UnitTestHelper.GetAccount('Account2');
            account2.Phone = '0123456789';
            updAccounts.add(account2);

            // create Account record that matche on phone and postcode
            Account account3 = bg_UnitTestHelper.GetAccount('Account3');
            account3.Phone = '0123456789';
            account3.BillingPostalCode = 'SW1W 0DT';
            updAccounts.add(account3);

			// Update Accounts
			update updAccounts;

            // create Contact record associated with Account1 - does not matches anything
            Contact contact1 = bg_UnitTestHelper.GetContact('Contact 1', account1);
            updContacts.add(contact1);

            // create Contact record associated with Account2 - matches on phone
            Contact contact2 = bg_UnitTestHelper.GetContact('Contact 2', account2);
            contact2.Phone = '0123456789';
            updContacts.add(contact2);

            // create Contact record associated with Account3 - matches on phone and email
            Contact contact3 = bg_UnitTestHelper.GetContact('Contact 3', account3);
            contact3.Phone = '0123456789';
            contact3.Email = 'test@test.com';
            updContacts.add(contact3);

            // create Contact record associated with no account - matches on phone, email and postcode
            Contact contact4 = bg_UnitTestHelper.GetContact('Contact 4');
            contact4.Phone = '0123456789';
            contact4.Email = 'test@test.com';
            contact4.MailingPostalCode = 'SW1W 0DT';
            updContacts.add(contact4);

			// Update contacts
			update updContacts;
			
            // need to setup SOSL so Salesforce will allow searches
            Id [] fixedSearchResults= new Id[9];
            fixedSearchResults[0] = lead2.Id;
            fixedSearchResults[1] = lead3.Id;
            fixedSearchResults[2] = lead4.Id;
            fixedSearchResults[3] = lead5.Id;
            fixedSearchResults[4] = account2.Id;
            fixedSearchResults[5] = account3.Id;
            fixedSearchResults[6] = contact2.Id;
            fixedSearchResults[7] = contact3.Id;
            fixedSearchResults[8] = contact4.Id;
     
            test.startTest();
	            //Required so SOSL will fire in Unit Tests Properly
	            Test.setFixedSearchResults(fixedSearchResults);
	
	            /** Set up data finished **/
	
	            // Create an instance of the standard controller and the controller extension
	            CIVMatchesController matchesController =  new CIVMatchesController();
	            matchesController.record = parentLead;
	            matchesController.recordNameValue = parentLead.Name;
	            matchesController.recordCompanyValue = parentLead.Company;
	            matchesController.recordPostcodeValue = parentLead.PostalCode;
	            matchesController.recordEmailValue = parentLead.Email;
	            matchesController.recordPhoneValue = parentLead.Phone;
	            matchesController.recordAccountId = parentLead.Existing_Customer_Account__c;
	            matchesController.recordContactId = parentLead.Contact__c;
	
	            List<bg_CIVUtils.SearchResultWrapper> searchResults = matchesController.getSearchResults();
			
	            // 9 records are being searched but only 5 should be returned
	            system.assertEquals(5, searchResults.size());
	
	            // as they are 9 records hasNext should be true;
	            system.assertEquals(true, matchesController.hasNext);
	
	            // next has not been close so pageNumber should 1 and hasPrevious should be false;
	            system.assertEquals(1, matchesController.pageNumber);
	            system.assertEquals(false, matchesController.hasPrevious);
	
	            // filters should be false for opportunity and true for all others
	            system.assertEquals(false, matchesController.isOpportunity);
	            system.assertEquals(true, matchesController.isLead);
	            system.assertEquals(true, matchesController.isAccount);
	            system.assertEquals(true, matchesController.isContact);
	
	            // search term should all be true
	            system.assertEquals(true, matchesController.isNameValue);
	            system.assertEquals(true, matchesController.isCompanyValue);
	            system.assertEquals(true, matchesController.isEmailValue);
	            system.assertEquals(true, matchesController.isPhoneValue);
	            system.assertEquals(true, matchesController.isPostcodeValue);
	
	            // click next
	            matchesController.next();
	            searchResults = matchesController.getSearchResults();
	
	            // pageNumber is 2 and hasPrevious true and hasNext false and size 4
	            system.assertEquals(2, matchesController.pageNumber);
	            system.assertEquals(true, matchesController.hasPrevious);
	            system.assertEquals(false, matchesController.hasNext);
	            system.assertEquals(4, searchResults.size());
	
	            // click previous again
	            matchesController.previous();
	            searchResults = matchesController.getSearchResults();
	            
	            // pageNumber 0 and hasPrevious false and hasNext true and size 5
	            system.assertEquals(1, matchesController.pageNumber);
	            system.assertEquals(false, matchesController.hasPrevious);
	            system.assertEquals(true, matchesController.hasNext);
	            system.assertEquals(5, searchResults.size());
	
				system.assertEquals(null, matchesController.sortResults());
				matchesController.sortColumnName = bg_CIVUtils.SORTCOL_OBJECTTYPE;
				matchesController.orderAsc = true;
				system.assertEquals(null, matchesController.sortResults());  	
					
	            // test filtering
	            fixedSearchResults= new Id[6];
	            fixedSearchResults[0] = lead2.Id;
	            fixedSearchResults[1] = lead3.Id;
	            fixedSearchResults[2] = lead4.Id;
	            fixedSearchResults[3] = lead5.Id;
	            fixedSearchResults[4] = account2.Id;
	            fixedSearchResults[5] = account3.Id;
	
	            //Required so SOSL will fire in Unit Tests Properly
	            Test.setFixedSearchResults(fixedSearchResults);
	
	            matchesController.isContact = false;
	            matchesController.filter();
	            searchResults = matchesController.getSearchResults();
	
	            system.assertEquals(5, searchResults.size());
	
	            Integer contactsFound = 0;
	            for (bg_CIVUtils.SearchResultWrapper sr : searchResults) {
	                if (sr.objectType == 'Contact') {
	                    contactsFound++;
	                }
	            }
	
	            // no contacts objects should have been found
	            system.assertEquals(0, contactsFound);
	
	            // test search
	            fixedSearchResults= new Id[6];
	            fixedSearchResults[0] = lead2.Id;
	            fixedSearchResults[1] = lead3.Id;
	            fixedSearchResults[2] = lead4.Id;
	            fixedSearchResults[3] = account2.Id;
	            fixedSearchResults[4] = account3.Id;
	
	            //Required so SOSL will fire in Unit Tests Properly
	            Test.setFixedSearchResults(fixedSearchResults);
	
	            matchesController.recordNameValue = parentLead.Name;
	            matchesController.recordCompanyValue = null;
	            matchesController.recordPostcodeValue = parentLead.PostalCode;
	            matchesController.recordEmailValue = parentLead.Email;
	            matchesController.recordPhoneValue = parentLead.Phone;
	            matchesController.recordAccountId = parentLead.Existing_Customer_Account__c;
	            matchesController.recordContactId = parentLead.Contact__c;
	
	            matchesController.search();
	            searchResults = matchesController.getSearchResults();
	
	            Integer foundCompanyText = 0;
	            for (bg_CIVUtils.SearchResultWrapper sr : searchResults) {
	                if (sr.phone != null) {
	                    if (sr.phone.contains(parentLead.Company)) {
	                        foundCompanyText++;
	                    }
	                }
	                if (sr.postcode != null) {
	                    if (sr.postcode.contains(parentLead.Company)) {
	                        foundCompanyText++;
	                    }
	                }
	                if (sr.email != null) {
	                    if (sr.email.contains(parentLead.Company)) {
	                        foundCompanyText++;
	                    }
	                }
	            }
	
	            system.assertEquals(0,foundCompanyText);
			test.stopTest();
        }
    }
}