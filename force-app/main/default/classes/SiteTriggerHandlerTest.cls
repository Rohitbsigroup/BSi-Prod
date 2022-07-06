/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         25/11/2011
* Description:  TEST CLASS: SiteTriggerHandler
* Changes   26-07-2017 - RC had to change number of sites as it does not count the process builder default site.
*           08-12-2017 - ADS - Case 34308 - Site Creation Process
*
* ------------------
* TESTING:		 93%
* ------------------
* TRIGGER:		100%
* ------------------      
**/
@isTest
private class SiteTriggerHandlerTest {

    // Testing adding,updating and deleting site - account
    static testMethod void siteAccount() {
        // Set up data
        Account acc = TestData.getTestAccount();
        insert acc;
        Lead lead = TestData.getTestLead();
        insert lead;
        
        // Add a new Site
        Site__c sa = TestData.getTestSite();
        sa.Account__c = acc.Id;
        insert sa;
        // Update a site - Lead Conversion
        Site__c sl = TestData.getTestSite();
        sl.Lead__c = lead.Id;
        insert sl;
        sl.Lead__c = null;
        sl.Account__c = acc.Id;
        sl.Postcode__c='EC4';
        update sl;
        
        // Check expected results
        Account accadd = [SELECT Id, SiteNumber__c FROM Account WHERE Id =:acc.Id];
        System.assertEquals(accadd.SiteNumber__c,3); // HQ is auto created, count HQ also
        
        // Delete the site from opportinity
        delete sl;
        Account accdel = [SELECT Id, SiteNumber__c FROM Account WHERE Id =:acc.Id];
        System.assertEquals(accdel.SiteNumber__c,2); // HQ is auto created, count HQ also
        
        // Add new HQ Site
        SiteSetting__c setting = SiteSetting__c.getInstance();
        List<Site__c> hqs = new List<Site__c>();
        Site__c hq1 = TestData.getTestSite();
        hq1.Account__c = acc.Id;
        hq1.Type__c = setting.HQLabel__c;
        try {insert hq1;} catch (Exception ex) {}
    }
    
    // Testing check unique methods (HQ, Transient, Network Site)
    static testMethod void uniqueTypes() {
    	// Set up data
        Account accT = TestData.getTestAccount();
        insert accT;
        Account accN = TestData.getTestAccount();
        insert accN;

        Map<String,Id> rtypeMap = Utility.getRecordTypes('Site__c');
        String transientId 		= rtypeMap.get(Utility.RTNAME_TRANSIENT);
        String networkId		= rtypeMap.get(Utility.RTNAME_NETWORK);
        
        List<Site__c> sites = new List<Site__c>();
        // Insert Transient
        Site__c st = TestData.getTestSite();
        st.Account__c = accT.Id;
        st.RecordTypeId = transientId;
        sites.add(st);
        // Insert Network
        Site__c sn = TestData.getTestSite();
        sn.Account__c = accN.Id;
        sites.add(sn);
        insert sites;
        
        for (Integer i=0;i<20;i++) {
       		Site__c s = TestData.getTestSite();
       		if (i <= 5) s.Account__c = accN.Id;
       		else s.Account__c = accT.Id;
       		if (i <= 10) s.RecordTypeId = networkId;
       		else s.RecordTypeId = transientId;
       		sites.add(s);
       	}
       	
       	Test.startTest();
       	try {
       		upsert sites;
       	} catch (Exception ex) {}
       	Test.stopTest();
    }
    
    static testMethod void dupeSites() {
    	SystemSetting__c ss = SystemSetting__c.getInstance();
    	ss.SkipSiteDupeCheck__c = false;
    	upsert ss;
    	
        // Set up data
        Account acc = TestData.getTestAccount();
        insert acc;
        
        Exception myEx;
		Site__c sa_EC1;
		Site__c sa_EC2;
		Site__c sa_EC1_dupe;
		
		try {
	        // Add a new Site
	        sa_EC1 = TestData.getTestSite();
	        sa_EC1.PostCode__c='sa_EC1';
	        sa_EC1.Account__c = acc.Id;
	        insert sa_EC1;
        } catch (Exception ex) {
        	myEx = ex;
        }        
        system.assertEquals(null, myEx);//shouldnt get an exception        
        sa_EC1 = [SELECT Id, DupeCheckID__c, Type__c FROM Site__c 
        	 WHERE Id = :sa_EC1.Id LIMIT 1];
        System.AssertEquals(acc.Id + 'sa_ec1' + sa_EC1.Type__c, sa_EC1.DupeCheckID__c, 'Dupe ID build out of acc id and postcode');
        
        /**
        INSERT SECOND SITE
        **/
        try {
	        // Add a new Site
	        sa_EC2 = TestData.getTestSite();
	        sa_EC2.PostCode__c='sa_EC2';
	        sa_EC2.Account__c = acc.Id;
	        insert sa_EC2;
        } catch (Exception ex) {
        	myEx = ex;
        }  
        system.assertEquals(null, myEx);//shouldnt get an exception 
        sa_EC2 = [SELECT Id, DupeCheckID__c, Type__c FROM Site__c 
        	 WHERE Id = :sa_EC2.Id LIMIT 1];
        System.AssertEquals(acc.Id + 'sa_ec2' + sa_EC2.Type__c, sa_EC2.DupeCheckID__c, 'Dupe ID build out of acc id and postcode');
        
        
        /**
        INSERT DUPE SITE
        **/
        try {
	         // Add another new Site
	        sa_EC1_dupe = TestData.getTestSite();
	        sa_EC1_dupe.PostCode__c='sa_EC1';
	        sa_EC1_dupe.Account__c = acc.Id;
	        insert sa_EC1_dupe;
        } catch (Exception ex) {
        	myEx = ex;
        }
        system.assertNotEquals(null, myEx);//expect to get an exception
        
    }
    
    static testMethod void dupeMultiBatchSites() {
    	
    	SystemSetting__c ss = SystemSetting__c.getInstance();
    	ss.SkipSiteDupeCheck__c = false;
    	upsert ss;
    	
        // Set up data
        Account acc = TestData.getTestAccount();
        insert acc;
        
        Exception myEx;
		Site__c sa_EC1;
		Site__c sa_EC1_dupe;
		
		// Add a new Site
	    sa_EC1 = TestData.getTestSite();
	    sa_EC1.PostCode__c='sa_EC1';
	    sa_EC1.Account__c = acc.Id;
	    
	    // Add a dupe Site
	    sa_EC1_dupe = TestData.getTestSite();
	    sa_EC1_dupe.PostCode__c='sa_EC1';
	    sa_EC1_dupe.Account__c = acc.Id;
		
		try {
	        insert new List<Site__c>{sa_EC1, sa_EC1_dupe};
        } catch (Exception ex) {
        	myEx = ex;
        }
        system.assertNotEquals(null, myEx); //should get an exception        
    }
    
    @testSetup()
    static void SetUp()
    {
        final Account theTestAccount = TestData.getTestAccount();
        insert theTestAccount;
        
        final Site__c theTestSite = TestData.getTestSite('AA1 1AA');
        theTestSite.Account__c = theTestAccount.Id;
        theTestSite.Type__c = 'Office';
        insert theTestSite;
    } // SetUp
    
    static testMethod void TestCheckDuplicateSites()
    {
        final Account theTestAccount = GetAccount();   
        
        final Site__c theTestSite = TestData.getTestSite('AA1 1AA');
        theTestSite.Account__c = theTestAccount.Id;
        theTestSite.Type__c = 'Manufacturing';
        
        final List<Site__c> theSiteList = new List<Site__c>();
        theSiteList.add(theTestSite);
        
        Test.startTest();
        new SiteTriggerHandler(true, 1).checkDuplicateSites(theSiteList);
        Test.stopTest();
        
        System.assert(ApexPages.getMessages().isEmpty());
    } // TestCheckDuplicateSites
    
    static testMethod void TestCheckUniqueHQBulk()
    {
        final SiteSetting__c theSiteSetting = new SiteSetting__c();
        theSiteSetting.HQLabel__c = 'HQ';
        insert theSiteSetting;
        
        final Account theTestAccount = GetAccount();   
        
        final Site__c theTestSite = TestData.getTestSite('AA1 1AA');
        theTestSite.Account__c = theTestAccount.Id;
        theTestSite.Type__c = 'HQ';
        
        final List<Site__c> theSiteList = new List<Site__c>();
        theSiteList.add(theTestSite);
        
        Test.startTest();
        new SiteTriggerHandler(true, 1).checkUniqueHQ_Bulk(theSiteList);
        Test.stopTest(); 
        
        System.assert(!ApexPages.getMessages().isEmpty());                
    } // TestCheckUniqueHQBulk
    
    static testMethod void TestCheckUnique()
    {
        final Account theTestAccount = GetAccount();  
        final Site__c theTestSite = GetSite();
        
        final Site__c theNewSite = TestData.getTestSite('AA1 1AA');
        theNewSite.Account__c = theTestAccount.Id;
        theNewSite.Type__c = 'Manufacturing';
        theNewSite.RecordTypeId = theTestSite.RecordTypeId;
        
        final List<Site__c> theSiteList = new List<Site__c>();
        theSiteList.add(theNewSite);
        
        Test.startTest();
        new SiteTriggerHandler(true, 1).checkUnique(theSiteList, theTestSite.RecordTypeId, theTestSite.RecordType.Name);
        Test.stopTest();        
        
        System.assert(!ApexPages.getMessages().isEmpty());        
    } // TestCheckUnique
    
    static Account GetAccount()
    {
        final List<Account> theAccountList = [SELECT Id
                                              FROM Account];
        System.assert(!theAccountList.isEmpty());
        System.assertEquals(1, theAccountList.size());
        return theAccountList[0];
    } // GetAccount
    
    static Site__c GetSite()
    {
        final List<Site__c> theSiteList = [SELECT Id,
                                           RecordTypeId,
                                           RecordType.Name
                                           FROM Site__c
                                           WHERE RecordType.DeveloperName != 'Default'];
        System.assert(!theSiteList.isEmpty());
        System.assertEquals(1, theSiteList.size());
        return theSiteList[0];        
    } // GetSite
    
}