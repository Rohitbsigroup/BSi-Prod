@isTest
private class SiteUploaderControllerV2Test {

    // Testing uploading a csv
    @isTest
    static void uploadCSVTest() {

                // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        System.runAs(user1)
        {
            // Set up data
            Account acc = bg_UnitTestHelper.GetAccount('Test Account');
            Contact con = bg_UnitTestHelper.GetContact('Test Contact', acc);
            Site__c site = bg_UnitTestHelper.GetSite(acc, 'Test Site 1', 'UK', bg_SiteUtils.RECORD_TYPE_NAME_NAMED, '1234');

            Test.setCurrentPage(Page.siteUploaderV2);
            ApexPages.currentPage().getParameters().put('accountId', acc.Id);
            SiteUploaderControllerV2 controller = new SiteUploaderControllerV2();
            
            // Upload a test csv
            String testCSV =     'Name,City__c,Country__c\r'
                                +'Name,City,Country\r'
                                +'Test,Test,GB\r'
                                +'Test,"Test,Comma",GB\r'
                                +'Test,"Test""Doublequote",GB\r'
                                +'Test,"Test\nNewline",GB';

            Test.startTest();
            controller.docfile.body = Blob.valueOf(testCSV);
            controller.readFile();
            
            System.assertEquals(controller.back().getUrl(),'/' + acc.Id);

            system.assertEquals(controller.getSuccess().size(),4);
            
            controller.getSuccess();
            controller.getCustomers();
            controller.customer = con.Id;
            controller.sendCSV();
            
            // Check format Errors
            testCSV = 'Wrongformat;""';
            controller.docfile.body = Blob.valueOf(testCSV);
            controller.readFile();

            system.assertEquals(controller.getSuccess(),null);
            Test.stopTest();
        }
    }

    @isTest
    static void uploadCSVTest2() {
        // Initialise Custom Settings
        bg_UnitTestHelper.SetupCustomSettings();

        // Set up data
        Account acc = bg_UnitTestHelper.GetAccount('Test Account');
        Contact con = bg_UnitTestHelper.GetContact('Test Contact', acc);
        Site__c site = bg_UnitTestHelper.GetSite(acc, 'Test Site 1', 'UK', bg_SiteUtils.RECORD_TYPE_NAME_NAMED, '1234');

        Test.setCurrentPage(Page.siteUploaderV2);
        ApexPages.currentPage().getParameters().put('accountId', acc.Id);
        SiteUploaderControllerV2 controller = new SiteUploaderControllerV2();
            
        // Upload a test csv
        String testCSV =    'Name,City__c,Country__c,Postcode__c\r'
                            +'Name,City,Country,Postcode\r'
                            +'Test,Test,GB,12345\r'
                            +'Test Site 1,Test,GB,1234\r'
                            +'Test Site 2,Test,GB,1234\r'
                            +'Test Site 3,Test,GB,CM8';

        controller.docfile.body = Blob.valueOf(testCSV);
        controller.readFile();
            
        System.assertEquals(controller.back().getUrl(),'/' + acc.Id);

        List<SiteUploaderControllerV2.ValidatedSite> results = controller.getSuccess();

        for (SiteUploaderControllerV2.ValidatedSite vs : results) {
            // Test  newSite = true; dupeSite = false; updateSite = false;
            Site__c resultSite = vs.site;
            if (resultSite.Name == 'Test') {
                // Test  newSite = true; dupeSite = false; updateSite = false;
                System.assertEquals(true, vs.newSite);
                System.assertEquals(false, vs.dupeSite);
                System.assertEquals(false, vs.updateSite);
            } else if (resultSite.name == 'Test Site 1') {
                // Test Site 1  newSite = false; dupeSite = false; updateSite = true;
                System.assertEquals(false, vs.newSite);
                System.assertEquals(false, vs.dupeSite);
                System.assertEquals(true, vs.updateSite);
            } else if (resultSite.name == 'Test Site 2') {
                // Test  newSite = false; dupeSite = true; updateSite = false;
                System.assertEquals(false, vs.newSite);
                System.assertEquals(true, vs.dupeSite);
                System.assertEquals(false, vs.updateSite);
            } else if (resultSite.name == 'Test Site 3') {
                // Test  newSite = true; dupeSite = false; updateSite = false;
                System.assertEquals(true, vs.newSite);
                System.assertEquals(false, vs.dupeSite);
                System.assertEquals(false, vs.updateSite);
            }
        }

        /* 
            Test updateSites function

            Account should now have 4 sites attached to it.  3 new one and 1 updated (contry code should be GB instead of UK)
        */
        controller.updateSites();

        List<Site__c> updateSites = [SELECT Name, Postcode__c, Country__c, SkipDupeChecker__c from Site__c where Account__c = :acc.id];

        // this checks that new site were entered
        System.assertEquals(5,updateSites.size());
        
        for (Site__c s : updateSites) {
            if (s.Name == 'Test Site 1') {
                System.assertEquals('GB',s.Country__c);
            }
            if (s.Name == 'Test Site 2') {
                System.assertEquals(true, s.SkipDupeChecker__c);
            }
        }
    }
}