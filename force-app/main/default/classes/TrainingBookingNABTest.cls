@isTest(seeAllData=true) // Needed for access to standard pricebook
private class TrainingBookingNABTest
{
    static testMethod void myUnitTest()
    {
        //setup account
        Account acc = bg_UnitTestHelper.CreateAccount();
        insert acc;

		// Set up a venue
		Training_Venue__c ven = TrainingBookingTestData.createTestVenue();

        Contact con = bg_UnitTestHelper.CreateContact('ILOVEUNITTESTS', acc);
        con.Country_Office__c = ven.Id;
        //con.Status__c = 'Active';
        insert con;

        // Set up product #1 (non-residential)
        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        
        // Set up product #2 (residential)
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        
        // 12/02/2018 ADS - Updates for new Process Builder "Create Price Book Entry for ALL Currencies in Standard Price Book"
        delete [SELECT Id FROM PricebookEntry WHERE Product2Id IN (:prd1.Id, :prd2.Id)];                                 

		// Setup an event
		Training_Event__c evt = TrainingBookingTestData.createTestEvent(prd1, ven, 10, con.Id);
		
        // Set up price book entries
        Pricebook2 std = [SELECT Id FROM Pricebook2 WHERE isStandard = true];
        PricebookEntry pbe1 = TrainingBookingTestData.createTestPbe(prd1, 100, 'GBP');
        PricebookEntry pbe2 = TrainingBookingTestData.createTestPbe(prd2, 200, 'GBP');
		
		// Setup the booking for a residential event (1 delegate with accommodation, 1 without)
		TrainingBooking__c booking = TrainingBookingTestData.createTestBooking(evt, pbe1, pbe2);

		// Setup a booker delegate
		TrainingDelegate__c delegate = TrainingBookingTestData.createTestDelegate(booking, true, true);

        // Start the processing
        Test.startTest();

        // Set the current page to TrainingBookingNAB
        Test.setCurrentPageReference(Page.TrainingBookingNAB);

        // Create an instance of the custom controller without parameters
        TrainingBookingNAB cont = new TrainingBookingNAB();
        PageReference init = cont.initCheck();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking7'));

        // Create an instance of the custom controller with a language
        ApexPages.currentPage().getParameters().put('L', 'EN');
        cont = new TrainingBookingNAB();
        init = cont.initCheck();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking7'));

        // Create an instance of the custom controller with a country
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        cont = new TrainingBookingNAB();
        init = cont.initCheck();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking7'));
		
        // Create an instance of the custom controller with all parameters
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        cont = new TrainingBookingNAB();
        init = cont.initCheck();
        System.assert(init == null);

		// Spoof a callback with a bad fingerprint, etc.
        ApexPages.currentPage().getParameters().put('timestamp', '20140101010101');
        ApexPages.currentPage().getParameters().put('summarycode', '2');
        ApexPages.currentPage().getParameters().put('fingerprint', 'badfingerprint');
        cont = new TrainingBookingNAB();
        init = cont.initCheck();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking7'));
		
		// Spoof a callback with a good fingerprint and a failure code
        ApexPages.currentPage().getParameters().put('timestamp', '20140101010101');
        ApexPages.currentPage().getParameters().put('summarycode', '2');
        //String toCode = cont.EPS_MERCHANT + '|sEj8yltT|' + cont.EPS_REFERENCEID + '|' + cont.EPS_AMOUNT + '|20140101010101|2'; // Test
        String toCode = cont.EPS_MERCHANT + '|wVi5IAbm|' + cont.EPS_REFERENCEID + '|' + cont.EPS_AMOUNT + '|20140101010101|2';  // Live
        ApexPages.currentPage().getParameters().put('fingerprint', EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(toCode))));
        ApexPages.currentPage().getParameters().put('restext', 'Failed');
        cont = new TrainingBookingNAB();
        init = cont.initCheck();
        System.assert(init == null);
		
		// Spoof a callback with a good fingerprint and a success code
        ApexPages.currentPage().getParameters().put('timestamp', '20140101010101');
        ApexPages.currentPage().getParameters().put('summarycode', '1');
        //toCode = cont.EPS_MERCHANT + '|sEj8yltT|' + cont.EPS_REFERENCEID + '|' + cont.EPS_AMOUNT + '|20140101010101|1'; // Test
        toCode = cont.EPS_MERCHANT + '|wVi5IAbm|' + cont.EPS_REFERENCEID + '|' + cont.EPS_AMOUNT + '|20140101010101|1'; // Live
        ApexPages.currentPage().getParameters().put('fingerprint', EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(toCode))));
        ApexPages.currentPage().getParameters().put('txnid', '1234567890');
        cont = new TrainingBookingNAB();
        init = cont.initCheck();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking6'));

		// Trying again should throw an error
        cont = new TrainingBookingNAB();
        init = cont.initCheck();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking7'));

        // Test other functions
        System.assert(cont.getYears().size() == 11);
        System.assert(cont.getMonths().size() == 13);
        
        String EPS_RESULTURL = cont.EPS_RESULTURL;
        String PAYMENT_URL = cont.PAYMENT_URL;
        String EPS_MERCHANT = cont.EPS_MERCHANT;
        String EPS_MERCHANTNUM = cont.EPS_MERCHANTNUM;

        cont.invoiceInstead();

        // Stop the processing
        Test.stopTest();
    }
}