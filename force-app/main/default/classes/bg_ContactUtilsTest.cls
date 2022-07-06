/********************************************************************
 * bg_ContactUtilsTest
 *
 * Test class for bg_ContactUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 19-10-2013
 * Changes: 
 *	CPE	04-09-2017	New test methods for GetOpportunityContactsFromContactRoles
 ********************************************************************/
@isTest
private class bg_ContactUtilsTest {

	private static testMethod void testGetAccountContact() {
		/*
			Test GetAccountContact & GetAccountContactMap method
		*/
		bg_UnitTestHelper.GetSiteSettings();				
		Account acc = bg_UnitTestHelper.GetAccount('UT-CONTACTUTILS-ACC');
		Contact con = bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON', acc);
		test.startTest();
			system.assertEquals(1, bg_ContactUtils.GetAccountContacts(acc.Id).size());
			system.assertEquals(1, bg_ContactUtils.GetAccountContactMap(acc.Id).size());
			system.assertEquals(true, bg_ContactUtils.GetAccountContactMap(acc.Id).containsKey(con.Id));
		test.stopTest();
	}

	private static testMethod void testGetSiteContactMap() {
		/*
			Test GetSiteContactMap method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT-CONTACTUTILS-ACC');
		Site__c site = bg_UnitTestHelper.GetSite(acc, 'UT-CONTACTUTILS-SITE', bg_SiteUtils.COUNTRY_CODE_US);
		Contact con = bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON', acc);
		ContactSite__c conSite = bg_UnitTestHelper.GetSiteContact(site, con, bg_ContactUtils.CONTACT_SITE_ROLE_PRIMARY);
		
		test.startTest();
			system.assertEquals(1, bg_ContactUtils.GetSiteContactMap(acc.Id).size());
		test.stopTest();
	}

	private static testMethod void testGetOpportunityContact() {
		/*
			Test GetOpportunityContact method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONTACTUTILS');
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		Contact con = bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON', acc);
		test.startTest();
			system.assertNotEquals(null, bg_ContactUtils.GetOpportunityContact(opp.Id, con.Id, bg_ContactUtils.CONTACT_OPP_ROLE_DECISION_MAKER));
		test.stopTest();
	}

	private static testMethod void testGetOpportunityContactRoleMap() {
		/*
			Test GetOpportunityContactRoleMap method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONTACTUTILS');
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		Contact con = bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON', acc);
		Contact_Opportunity__c oppCon = bg_UnitTestHelper.GetOpportunityContact(opp, con, bg_ContactUtils.CONTACT_OPP_ROLE_DECISION_MAKER);
		test.startTest();
			map<string, set<Id>> oppConMap = bg_ContactUtils.GetOpportunityContactRoleMap(opp.Id);
			system.assertEquals(1, oppConMap.size());
			system.assertEquals(true, oppConMap.containsKey(oppCon.OppRole__c));
		test.stopTest();
	}

	private static testMethod void testGetContacts() {
		/*
			Test GetContacts and GetContactsMap method
		*/
		set<Id> conIds = new set<Id>();
		conIds.add(bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON1').Id);
		conIds.add(bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON2').Id);

		test.startTest();
			system.assertEquals(2, bg_ContactUtils.GetContacts(conIds).size());
			system.assertEquals(2, bg_ContactUtils.GetContactsMap(conIds).size());			
		test.stopTest();
	}

	private static testMethod void testGetOpportunityContacts() {
		/*
			Test GetOpportunityContacts method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONTACTUTILS');
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		Contact con = bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON', acc);
		Contact_Opportunity__c oppCon = bg_UnitTestHelper.GetOpportunityContact(opp, con, bg_ContactUtils.CONTACT_OPP_ROLE_DECISION_MAKER);
		test.startTest();
			system.assertEquals(1, bg_ContactUtils.GetOpportunityContacts(opp.Id).size());
		test.stopTest();
	}

	private static testMethod void testGetQuoteProductContactIds() {
		/*
			Test GetQuoteProductContactIds method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONTACTUTILS');
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		Contact con = bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON', acc);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp);
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, con);			
		test.startTest();
			set<Id> conIds = bg_ContactUtils.GetQuoteProductContactIds(quote.Id);
			system.assertEquals(1, conIds.size());
			system.assertEquals(true, conIds.contains(con.Id));			
		test.stopTest();
	}

	private static testMethod void testSaveOpportunityContacts() {
		/*
			Test SaveOpportunityContacts method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONTACTUTILS');
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		Contact con = bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON', acc);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp, con);			
		test.startTest();
			bg_ContactUtils.SaveOpportunityContacts(quote);
		test.stopTest();
		system.assertEquals(4, bg_ContactUtils.GetOpportunityContactRoleMap(quote.Opportunity_Name__c).size());
	}

	private static testMethod void testDeleteOpportunityContactsOnSave()
	{
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONTACTUTILS');
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		Contact con = bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON', acc);
		Quote__c quote = bg_UnitTestHelper.GetQuote(opp, con);

		//save them and then blank them to see if the roles get deleted 
		bg_ContactUtils.SaveOpportunityContacts(quote);
		system.assertEquals(4, bg_ContactUtils.GetOpportunityContactRoleMap(quote.Opportunity_Name__c).size());

		//wipe out the quote
		quote.Contact__c = null;
		quote.Invoice_Contact__c = null;
		quote.Booking__c = null;
		quote.CreditCheck__c = null;

		//call same function see that they have been wiped out.
		bg_ContactUtils.SaveOpportunityContacts(quote);
		system.assertEquals(0, bg_ContactUtils.GetOpportunityContactRoleMap(quote.Opportunity_Name__c).size());
	}
	
	private static testMethod void testGetContactsByRecordType() {
		/*
			Test GetContactsByRecordType method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONTACTUTILS');
		Contact con = bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON', acc);
		test.startTest();
			system.assertEquals(1, bg_ContactUtils.GetContactsByRecordType(bg_ContactUtils.RECORD_TYPE_NAME_CLIENTS).size());
		test.stopTest();
	}
	
	private static testMethod void testGetContactEmailList() {
		/*
			Test GetContactEmailList method
		*/
		list<Contact> contacts = new list<Contact>();
		contacts.add(bg_UnitTestHelper.GetContact('UT-Smith'));
		test.startTest();
			system.assertEquals(1, bg_ContactUtils.GetContactEmailList(contacts).size());
		test.stopTest();
	}
	
	private static testMethod void testGetOtherAccountContacts() {
		/*
			Test GetContactEmailList method
		*/
		bg_UnitTestHelper.GetSiteSettings();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONTACTUTILS');
		list<Id> contacts = new list<Id>();
		contacts.add(bg_UnitTestHelper.GetContact('UT-Smith', acc).Id);
		bg_UnitTestHelper.GetContact('UT-Jones', acc);
		
		test.startTest();
			system.assertEquals(1, bg_ContactUtils.GetOtherAccountContacts(contacts).size());
		test.stopTest();
	}



	/*
		Test GetOpportunityContactsFromContactRoles method where no Opporutnity Contacts exist
	*/
	private static testMethod void testGetOpportunityContactsFromContactRolesNoContacts() 
	{
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONTACTUTILS');
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		//Contact con = bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON', acc);
		//Contact_Opportunity__c oppCon = bg_UnitTestHelper.GetOpportunityContact(opp, con, bg_ContactUtils.CONTACT_OPP_ROLE_DECISION_MAKER);
		
		Set<Id> results;
		
		results = bg_ContactUtils.GetOpportunityContactsFromContactRoles(opp.Id);
		system.assertEquals(results.isEmpty(), true);
	}

	/*
		Test GetOpportunityContactsFromContactRoles method where one Opporutnity Contacts exist
	*/
	private static testMethod void testGetOpportunityContactsFromContactRolesOneContacts() 
	{
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONTACTUTILS');
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		Contact con = bg_UnitTestHelper.GetContact('UT-CONTACTUTILS-CON', acc);
		Contact_Opportunity__c oppCon = bg_UnitTestHelper.GetOpportunityContact(opp, con, bg_ContactUtils.CONTACT_OPP_ROLE_DECISION_MAKER);
		
		Set<Id> results;
		
		results = bg_ContactUtils.GetOpportunityContactsFromContactRoles(opp.Id);

		system.assertEquals(results.isEmpty(), false);
		system.assertEquals(results.size(), 1);
		system.assertEquals(results.contains(con.Id), true);

	}

	/*
		Test GetOpportunityContactsFromContactRoles method where one Opporutnity Contacts exist
	*/
	private static testMethod void testGetOpportunityContactsFromContactRolesMulti() 
	{
		bg_UnitTestHelper.GetSiteSettings();
		bg_UnitTestHelper.GetDefaultCountrySetting();
		Account acc = bg_UnitTestHelper.GetAccount('UT_ACCOUNT_CONTACTUTILS');
		Opportunity opp = bg_UnitTestHelper.GetOpportunity(acc);
		Integer contactCount = 10;
		List<Contact> forInsert = new List<Contact>();
		List<Contact_Opportunity__c> forInsertCO = new List<Contact_Opportunity__c>();
		for (Integer iterator=0; iterator<contactCount; iterator++)
		{
			forInsert.add(bg_UnitTestHelper.CreateContact('UT-CONTACTUTILS-CON-' + iterator, acc));
		}
		insert forInsert;
		for (Contact testContact : forInsert)
		{
			forInsertCO.add(bg_ContactUtils.GetOpportunityContact(opp.Id, testContact.Id, bg_ContactUtils.CONTACT_OPP_ROLE_DECISION_MAKER));
		}		
		insert forInsertCO;
				
		Set<Id> results;
		
		results = bg_ContactUtils.GetOpportunityContactsFromContactRoles(opp.Id);

		system.assertEquals(results.isEmpty(), false);
		system.assertEquals(results.size(), contactCount);

		for (Contact testContact : forInsert)
		{
			system.assertEquals(results.contains(testContact.Id), true);
		}		

	}

}