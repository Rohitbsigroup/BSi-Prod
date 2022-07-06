/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         28/02/2012
* Description:  TEST CLASS: ConsultantRandomController
* Updates:		ASD @ BG 31/12/2013 : Updated code coverage to 92% from 81% - Only DML exceptions and Email Sending not covered.
*
* ------------------
* TESTING:		 92%
* ------------------
*       
**/
@isTest
private class ConsultantRandomControllerTest {

    static testMethod void randomConsultants() {
        // Set up data
        Territory__c terr = TestData.getTestTerritory('GB', '');
        insert terr;
        Account acc = TestData.getTestAccount(); // Account for Opportunity
        acc.BillingCountry = terr.Country__c;
        insert acc;
        Account consAcc = TestData.getTestAccount(); // Consultant Account
        consAcc.BillingCountry = terr.Country__c;
        insert consAcc;
        Contact con = TestData.getTestContact();
        con.AccountId = acc.Id;
        insert con;
        Opportunity opp = TestData.getTestOpty();
        opp.Standards__c = 'TEST 20000';
        opp.AccountId = acc.Id;
        opp.PrimaryContact__c = con.Id;
        insert opp;
        Site__c s = TestData.getTestSite();
        s.Account__c = acc.Id;
        s.Country__c = terr.Country__c;
        insert s;
        OpportunitySite__c os = new OpportunitySite__c();
        os.Site__c = s.Id;
        os.Opportunity__c = opp.Id;
        os.HQ__c = true;
        insert os;     
        Contact_Opportunity__c primary = new Contact_Opportunity__c();
        primary.Contact__c = con.Id;
        primary.OppPrimary__c = true;
        primary.Opportunity__c = opp.Id;
        insert primary;
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName =:Utility.RTNAME_CONSULTANT];
        
        Test.setCurrentPage(Page.consultantRandom);
        ConsultantRandomController controller = new ConsultantRandomController(new Apexpages.Standardcontroller(opp));
        controller.getCustomers();
        controller.reset();
        controller.sendEmail();
        System.assertEquals(controller.contacts.size(),0);
        
        List<Contact> consultants = new List<Contact>();
        // 20 CONSULTANT - NO MATCH
        for (Integer i = 0; i < 20; i ++) {
        	Contact temp = TestData.getTestContact();
        	temp.AccountId = acc.Id;
        	temp.RecordTypeId = rt.Id;
        	temp.Active__c = true;
        	temp.ConsultantProducts__c = 'TEST ISO 14001;TEST 20000';
        	temp.ConsultantType__c = 'NON ACP';
        	consultants.add(temp);
        }
        // 20 CONSULTANT - MATCH
        for (Integer i = 0; i < 20; i ++) {
        	Contact temp = TestData.getTestContact();
        	temp.AccountId = consAcc.Id;
        	temp.RecordTypeId = rt.Id;
        	temp.Active__c = true;
        	temp.ConsultantProducts__c = 'TEST ISO 14001;TEST 20000';
        	temp.ConsultantType__c = 'ACP';
        	temp.MailingCountry = terr.Country__c;
        	consultants.add(temp);
        }
        insert consultants;
        
        Test.setCurrentPage(Page.consultantRandom);
        controller = new ConsultantRandomController(new Apexpages.Standardcontroller(opp));
        controller.getCustomers();
        controller.reset();
        controller.sendEmail();
        //System.assertEquals(controller.contacts.size(),20);
        
        os.HQ__c = false;
        update os;
        
        /*Test.setCurrentPage(Page.consultantRandom);
        controller = new ConsultantRandomController(new Apexpages.Standardcontroller(opp));
        controller.getCustomers();
        controller.reset();
        controller.sendEmail();
        System.assertEquals(controller.warning,true);
        
        os.Site__c = null;
        os.HQ__c = true;
        update os;
        
        test.startTest();
	        Test.setCurrentPage(Page.consultantRandom);
	        controller = new ConsultantRandomController(new Apexpages.Standardcontroller(opp));
	        controller.getCustomers();
	        controller.reset();
	        controller.sendEmail();
	        System.assertEquals(controller.warning,true);
        test.stopTest();*/
    }
    
    static testMethod void testSlotMachine()
    {
    	// Set up data
        Territory__c terr = TestData.getTestTerritory('GB', '');
        insert terr;
        Account acc = TestData.getTestAccount(); // Account for Opportunity
        acc.BillingCountry = terr.Country__c;
        acc.Territory__c = terr.Id;
        insert acc;
        Account consAcc = TestData.getTestAccount(); // Consultant Account
        consAcc.BillingCountry = terr.Country__c;
        insert consAcc;
        Contact con = TestData.getTestContact();
        con.AccountId = acc.Id;
        insert con;
        Opportunity opp = TestData.getTestOpty();
        opp.Standards__c = 'TEST 20000';
        opp.AccountId = acc.Id;
        opp.PrimaryContact__c = con.Id;
        insert opp;
        Site__c s = TestData.getTestSite();
        s.Account__c = acc.Id;
        s.Country__c = terr.Country__c;
        s.Territory__c = terr.Id;
        insert s;
        OpportunitySite__c os = new OpportunitySite__c();
        os.Site__c = s.Id;
        os.Opportunity__c = opp.Id;
        os.HQ__c = true;
        insert os;     
        Contact_Opportunity__c primary = new Contact_Opportunity__c();
        primary.Contact__c = con.Id;
        primary.OppPrimary__c = true;
        primary.Opportunity__c = opp.Id;
        insert primary;
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName =:Utility.RTNAME_CONSULTANT];

		test.startTest();        
	        Test.setCurrentPage(Page.consultantRandom);
	        ConsultantRandomController controller = new ConsultantRandomController(new Apexpages.Standardcontroller(opp));
	        controller.getCustomers();
	        controller.reset();
	        controller.sendEmail();
	        System.assertEquals(controller.contacts.size(),0);
	        
	        List<Contact> consultants = new List<Contact>();
	        Contact temp = TestData.getTestContact();
	        temp.AccountId = acc.Id;
	        temp.RecordTypeId = rt.Id;
	        temp.Active__c = true;
	        temp.ConsultantProducts__c = 'TEST ISO 14001;TEST 20000';
	        temp.ConsultantType__c = 'NON ACP';
	        consultants.add(temp);
	                
	        Contact temp2 = TestData.getTestContact();
	        temp2.AccountId = consAcc.Id;
	        temp2.RecordTypeId = rt.Id;
	        temp2.Active__c = true;
	        temp2.ConsultantProducts__c = 'TEST ISO 14001;TEST 20000';
	        temp2.ConsultantType__c = 'ACP';
	        temp2.MailingCountry = terr.Country__c;
            temp2.Territory__c = terr.Id;
	        consultants.add(temp2);
	        
	        insert consultants;
	        
	        Test.setCurrentPage(Page.consultantRandom);
	        controller = new ConsultantRandomController(new Apexpages.Standardcontroller(opp));
            controller.contacts.addAll(consultants);
	        controller.getCustomers();
            controller.slotMachine();
	        controller.reset();
	        controller.sendEmail();
	        
	        Contact temp3 = TestData.getTestContact();
	        temp3.AccountId = consAcc.Id;
	        temp3.RecordTypeId = rt.Id;
	        temp3.Active__c = true;
	        temp3.ConsultantProducts__c = 'TEST ISO 14001;TEST 20000';
	        temp3.ConsultantType__c = 'ACP';
	        temp3.MailingCountry = terr.Country__c;
	        
	        insert temp3;
	        
	        Test.setCurrentPage(Page.consultantRandom);
	        controller = new ConsultantRandomController(new Apexpages.Standardcontroller(opp));
	        controller.getCustomers();
	        controller.reset();
	        controller.sendEmail();
	        
	        Contact temp4 = TestData.getTestContact();
	        temp4.AccountId = consAcc.Id;
	        temp4.RecordTypeId = rt.Id;
	        temp4.Active__c = true;
	        temp4.ConsultantProducts__c = 'TEST ISO 14001;TEST 20000';
	        temp4.ConsultantType__c = 'ACP';
	        temp4.MailingCountry = terr.Country__c;
	        
	        insert temp4;
	        
	        Test.setCurrentPage(Page.consultantRandom);
	        controller = new ConsultantRandomController(new Apexpages.Standardcontroller(opp));
	        controller.getCustomers();
	        controller.reset();
	        controller.sendEmail();
		test.stopTest();
    }
}