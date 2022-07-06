/*
    Created by: Mahmood (Cognizant)
    Created date: 11-02-2020
    Description: Test class for OgoneIframe Controller
    Change log
    Changed by              Changed date        Description
*/
@isTest 
private class TrainingBookingOgoneIFrameCtrTest
{
    static final String ALIASGATEWAY_SHA_OUT = 'U[}CTN8Lkn4J3%GvKyL';
    
    @isTest
    static void invalidParametersTest()
    {
        // Start the processing
        Test.startTest();
        // Set the current page to TrainingBookingOgone
        Test.setCurrentPageReference(Page.TrainingBookingOgoneIFrame);
        // invalid country
	    ApexPages.currentPage().getParameters().put('CT', null);
        // Create an instance of the custom controller without parameters
        TrainingBookingOgoneIFrameCtr cont = new TrainingBookingOgoneIFrameCtr();
        
        //null language
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('L', null);
		// Create an instance of the custom controller without parameters
        cont = new TrainingBookingOgoneIFrameCtr();
        
        //null Id
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('paramId', null);
        // Create an instance of the custom controller without parameters
        cont = new TrainingBookingOgoneIFrameCtr();
        
        //invalid Id
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('paramId', 'a2F8E000004rk4YUAQ');
		// Create an instance of the custom controller without parameters
        cont = new TrainingBookingOgoneIFrameCtr();
        
        Test.stopTest();
    }
    @isTest
    static void withExistingPaymentTest()
    {
        //setup account
        Account acc = bg_UnitTestHelper.CreateAccount();
        insert acc;
		// Set up a venue
        Training_Venue__c ven = TrainingBookingTestData.createTestVenue();
        
        Contact con = bg_UnitTestHelper.CreateContact('ILOVEUNITTESTS', acc);
        con.Country_Office__c = ven.Id;
        insert con;

        // Set up product #1 (non-residential)
        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        // Set up product #2 (residential)
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        
        // Setup an event
        Training_Event__c evt = TrainingBookingTestData.createTestEvent(prd1, ven, 10 , con.Id);
        // Set up price book entries
        Id std1 = Test.getStandardPricebookId();
        PricebookEntry pbe1 = TrainingBookingTestData.createTestPbe(prd1, 100, 'GBP');
        PricebookEntry pbe2 = TrainingBookingTestData.createTestPbe(prd2, 200, 'GBP');
        // Setup the booking for a residential event (1 delegate with accommodation, 1 without)
        TrainingBooking__c booking = TrainingBookingTestData.createTestBooking(evt, pbe1, pbe2);
        booking.Payment_Order_No__c = '0112233';
        update booking;
        
        Test.startTest();
        // Set the current page to TrainingBookingOgone
        Test.setCurrentPageReference(Page.TrainingBookingOgoneIFrame);

        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        // Create an instance of the custom controller with uncertain error
        TrainingBookingOgoneIFrameCtr cont = new TrainingBookingOgoneIFrameCtr();
        
        Test.stopTest();
    }
    @isTest
    static void uncertainPaymentTest()
    {
        //setup account
        Account acc = bg_UnitTestHelper.CreateAccount();
        insert acc;
		// Set up a venue
        Training_Venue__c ven = TrainingBookingTestData.createTestVenue();
        
        Contact con = bg_UnitTestHelper.CreateContact('ILOVEUNITTESTS', acc);
        con.Country_Office__c = ven.Id;
        insert con;

        // Set up product #1 (non-residential)
        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        // Set up product #2 (residential)
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        
        // Setup an event
        Training_Event__c evt = TrainingBookingTestData.createTestEvent(prd1, ven, 10 , con.Id);
        // Set up price book entries
        Id std1 = Test.getStandardPricebookId();
        PricebookEntry pbe1 = TrainingBookingTestData.createTestPbe(prd1, 100, 'GBP');
        PricebookEntry pbe2 = TrainingBookingTestData.createTestPbe(prd2, 200, 'GBP');
        // Setup the booking for a residential event (1 delegate with accommodation, 1 without)
        TrainingBooking__c booking = TrainingBookingTestData.createTestBooking(evt, pbe1, pbe2);
        booking.Payment_Error_Message__c = 'payment uncertain';
        update booking;
        
        Test.startTest();
        // Set the current page to TrainingBookingOgone
        Test.setCurrentPageReference(Page.TrainingBookingOgoneIFrame);

        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        // Create an instance of the custom controller with uncertain error
        TrainingBookingOgoneIFrameCtr cont = new TrainingBookingOgoneIFrameCtr();
        
        Test.stopTest();
    }
    
    @isTest
    static void validTest()
    {
		//setup account
        Account acc = bg_UnitTestHelper.CreateAccount();
        insert acc;
		// Set up a venue
        Training_Venue__c ven = TrainingBookingTestData.createTestVenue();
        
        Contact con = bg_UnitTestHelper.CreateContact('ILOVEUNITTESTS', acc);
        con.Country_Office__c = ven.Id;
        insert con;

        // Set up product #1 (non-residential)
        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        
        // Set up product #2 (residential)
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        
        // Setup an event
        Training_Event__c evt = TrainingBookingTestData.createTestEvent(prd1, ven, 10 , con.Id);
        
        // Set up price book entries
        Id std1 = Test.getStandardPricebookId();
        PricebookEntry pbe1 = TrainingBookingTestData.createTestPbe(prd1, 100, 'GBP');
        PricebookEntry pbe2 = TrainingBookingTestData.createTestPbe(prd2, 200, 'GBP');
        
        // Setup the booking for a residential event (1 delegate with accommodation, 1 without)
        TrainingBooking__c booking = TrainingBookingTestData.createTestBooking(evt, pbe1, pbe2);
        
        // Setup a booker delegate
        TrainingDelegate__c delegate = TrainingBookingTestData.createTestDelegate(booking, true, true);

        // create custom setting
        Ingenico_Ogone_Settings__c iostest = new Ingenico_Ogone_Settings__c(Name ='Ogone', USERID__c = 'testuser', PSPID__c='testbsi', PSWD__c= 'pwd123'
                                                                            , ALIASGATEWAY_SHA_IN__c='abc123',  ALIASGATEWAY_SHA_OUT__c='123abc', DIRECTLINK_SHA_IN__c= 'xyz123');
        insert iostest;
        // create system settings
        SystemSetting__c ss = new SystemSetting__c(Ingenico_Ogone_ALIASGATEWAY_URL__c = '', SHAEncoding__c = 'SHA512', Ingenico_Ogone_DIRECTLINK_URL__c = '');
        insert ss;

        // Start the processing
        Test.startTest();

        // Set the current page to TrainingBookingOgone
        Test.setCurrentPageReference(Page.TrainingBookingOgoneIFrame);

        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        
        // Create an instance of the custom controller without parameters
        TrainingBookingOgoneIFrameCtr cont = new TrainingBookingOgoneIFrameCtr();
        // Create an instance of the custom controller with a language
        PageReference init = cont.invoiceInstead();
        //System.assert(init.getUrl().startsWith('/apex/trainingbooking7'));

        // Create an instance of the custom controller with a country
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        cont = new TrainingBookingOgoneIFrameCtr();
        init = cont.invoiceInstead();
        //System.assert(init.getUrl().startsWith('/apex/trainingbooking7'));
        
        // Create an instance of the custom controller with all parameters
        ApexPages.currentPage().getParameters().put('ID', booking.Id);
        cont = new TrainingBookingOgoneIFrameCtr();
        init = cont.errorPage();
        System.assert(init.getUrl().startsWith('/apex/trainingbooking7'));

        // Test the SHA signature calculation
        //System.assert(String.isNotBlank(cont.getAliasGatewayShaIn()));
        
        // Spoof an ALIAS return with a bad signature
        ApexPages.currentPage().getParameters().put('MODE', 'ALIAS');
        cont = new TrainingBookingOgoneIFrameCtr();
                
        cont.validatePage();
        // Spoof an ALIAS return with a good signature but error code
        ApexPages.currentPage().getHeaders().put('User-Agent', '');
        ApexPages.currentPage().getHeaders().put('Accept', '');
        ApexPages.currentPage().getParameters().put('MODE', 'ALIAS');
        ApexPages.currentPage().getParameters().put('ORDERID', booking.Name);
        ApexPages.currentPage().getParameters().put('STATUS', '5');
        ApexPages.currentPage().getParameters().put('ALIAS', 'B5F39257FFF169067FEA3D756E5879FD8A47167F');
        ApexPages.currentPage().getParameters().put('CN', 'MR JOHN SMITH');
        ApexPages.currentPage().getParameters().put('BRAND', 'VISA');
        ApexPages.currentPage().getParameters().put('CARDNO', '4111111111111111');
        ApexPages.currentPage().getParameters().put('CVC', '123');
        ApexPages.currentPage().getParameters().put('ED', '1299');
        ApexPages.currentPage().getParameters().put('NCERROR', '');
        ApexPages.currentPage().getParameters().put('NCERRORCN', '');
        ApexPages.currentPage().getParameters().put('NCERRORCARDNO', '');
        ApexPages.currentPage().getParameters().put('NCERRORCVC', '');
        ApexPages.currentPage().getParameters().put('NCERRORED', '50001181');        
        String recvd = '';
        recvd += 'ALIAS=B5F39257FFF169067FEA3D756E5879FD8A47167F' + ALIASGATEWAY_SHA_OUT;
        recvd += 'BRAND=VISA' + ALIASGATEWAY_SHA_OUT;
        recvd += 'CARDNO=4111111111111111' + ALIASGATEWAY_SHA_OUT;
        recvd += 'CN=MR JOHN SMITH' + ALIASGATEWAY_SHA_OUT;
        recvd += 'CVC=123' + ALIASGATEWAY_SHA_OUT;
        recvd += 'ED=1299' + ALIASGATEWAY_SHA_OUT;
        recvd += 'NCERRORED=50001181' + ALIASGATEWAY_SHA_OUT;
        recvd += 'ORDERID=' + booking.Name + ALIASGATEWAY_SHA_OUT;
        recvd += 'STATUS=5' + ALIASGATEWAY_SHA_OUT;
        ApexPages.currentPage().getParameters().put('SHASIGN', EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(recvd))).toUpperCase());
        cont = new TrainingBookingOgoneIFrameCtr();
        init = cont.invoiceInstead();
        //System.assert(init == null);
                
        // Spoof an ALIAS return with a good signature and no errors
        ApexPages.currentPage().getHeaders().put('User-Agent', '');
        ApexPages.currentPage().getHeaders().put('Accept', '');
        ApexPages.currentPage().getParameters().put('MODE', 'ALIAS');
        ApexPages.currentPage().getParameters().put('ORDERID', booking.Name);
        ApexPages.currentPage().getParameters().put('STATUS', '0');
        ApexPages.currentPage().getParameters().put('ALIAS', 'B5F39257FFF169067FEA3D756E5879FD8A47167F');
        ApexPages.currentPage().getParameters().put('CN', 'MR JOHN SMITH');
        ApexPages.currentPage().getParameters().put('BRAND', 'VISA');
        ApexPages.currentPage().getParameters().put('CARDNO', '4111111111111111');
        ApexPages.currentPage().getParameters().put('CVC', '123');
        ApexPages.currentPage().getParameters().put('ED', '1299');
        // 18 Nov 2016 Vim test
        ApexPages.currentPage().getParameters().put('ECOM_BILLTO_POSTAL_NAME_FIRST', 'Vim Billing name');
        
        ApexPages.currentPage().getParameters().put('NCERROR', '');
        ApexPages.currentPage().getParameters().put('NCERRORCN', '');
        ApexPages.currentPage().getParameters().put('NCERRORCARDNO', '');
        ApexPages.currentPage().getParameters().put('NCERRORCVC', '');
        ApexPages.currentPage().getParameters().put('NCERRORED', '');        
        recvd = '';
        recvd += 'ALIAS=B5F39257FFF169067FEA3D756E5879FD8A47167F' + ALIASGATEWAY_SHA_OUT;
        recvd += 'BRAND=VISA' + ALIASGATEWAY_SHA_OUT;
        recvd += 'CARDNO=4111111111111111' + ALIASGATEWAY_SHA_OUT;
        recvd += 'CN=MR JOHN SMITH' + ALIASGATEWAY_SHA_OUT;
        recvd += 'CVC=123' + ALIASGATEWAY_SHA_OUT;
        recvd += 'ED=1299' + ALIASGATEWAY_SHA_OUT;
        recvd += 'ORDERID=' + booking.Name + ALIASGATEWAY_SHA_OUT;
        recvd += 'STATUS=0' + ALIASGATEWAY_SHA_OUT;
        system.debug('test recv: ' + recvd);
        ApexPages.currentPage().getParameters().put('SHASIGN', EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(recvd))).toUpperCase());
        cont = new TrainingBookingOgoneIFrameCtr();
        //init = cont.processor();
        System.debug(logginglevel.ERROR, '**LINE 142 CONT** ' + cont);
        System.debug(logginglevel.ERROR, '**LINE 142 INIT** ' + init);
       // System.assert(init.getUrl().startsWith('/apex/trainingbooking6'));

        // Try to process again
        cont = new TrainingBookingOgoneIFrameCtr();
        //init = cont.processor();
        //System.assert(init.getUrl().startsWith('/apex/trainingbooking7'));            
        //System.debug(cont.getAliasGatewayShaIn());
        //System.debug(cont.getDirectLinkShaIn());
        
        // Spoof a 3D secure return with a bad signature
        booking.Payment_Order_No__c = '';
        update booking;
        ApexPages.currentPage().getParameters().put('MODE', '3D');
        ApexPages.currentPage().getParameters().put('ORDERID', booking.Name);
        ApexPages.currentPage().getParameters().put('ECOM_BILLTO_POSTAL_NAME_FIRST', booking.Billing_Name__c);
        ApexPages.currentPage().getParameters().put('ECOM_SHIPTO_POSTAL_NAME_FIRST', booking.First_Name__c + ' ' + booking.Last_Name__c);
        ApexPages.currentPage().getParameters().put('STATUS', '5');
        ApexPages.currentPage().getParameters().put('PAYID', '1234567890');
        ApexPages.currentPage().getParameters().put('NCERROR', '1');
        ApexPages.currentPage().getParameters().put('SHASIGN', 'BADSIGNATURE');
        cont = new TrainingBookingOgoneIFrameCtr();
        //init = cont.processor();
        //System.assert(init == null);
                
        // Spoof a 3D secure return with a good signature but error code
        ApexPages.currentPage().getParameters().put('MODE', '3D');
        ApexPages.currentPage().getParameters().put('ORDERID', booking.Name);
        ApexPages.currentPage().getParameters().put('STATUS', '5');
        ApexPages.currentPage().getParameters().put('PAYID', '1234567890');
        ApexPages.currentPage().getParameters().put('NCERROR', '1');
        recvd = '';
        recvd += 'NCERROR=1' + ALIASGATEWAY_SHA_OUT;
        recvd += 'ORDERID=' + booking.Name + ALIASGATEWAY_SHA_OUT;
        recvd += 'PAYID=1234567890' + ALIASGATEWAY_SHA_OUT;
        recvd += 'STATUS=5' + ALIASGATEWAY_SHA_OUT;
        ApexPages.currentPage().getParameters().put('SHASIGN', EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(recvd))).toUpperCase());
        cont = new TrainingBookingOgoneIFrameCtr();
        //init = cont.processor();
        //System.assert(init == null);
                
        // Spoof a 3D secure return with a good signature and no errors
        ApexPages.currentPage().getParameters().put('MODE', '3D');
        ApexPages.currentPage().getParameters().put('ORDERID', booking.Name);
        ApexPages.currentPage().getParameters().put('STATUS', '0');
        ApexPages.currentPage().getParameters().put('PAYID', '1234567890');
        ApexPages.currentPage().getParameters().put('NCERROR', '0');
        recvd = '';
        recvd += 'NCERROR=0' + ALIASGATEWAY_SHA_OUT;
        recvd += 'ORDERID=' + booking.Name + ALIASGATEWAY_SHA_OUT;
        recvd += 'PAYID=1234567890' + ALIASGATEWAY_SHA_OUT;
        recvd += 'STATUS=0' + ALIASGATEWAY_SHA_OUT;
        ApexPages.currentPage().getParameters().put('SHASIGN', EncodingUtil.convertToHex(Crypto.generateDigest('SHA1', Blob.valueOf(recvd))).toUpperCase());
        cont = new TrainingBookingOgoneIFrameCtr();
        //init = cont.processor();
        //System.debug(cont.response);

        cont.invoiceInstead();
        cont.successPage();
        // Stop the processing
        Test.stopTest();
    }
}