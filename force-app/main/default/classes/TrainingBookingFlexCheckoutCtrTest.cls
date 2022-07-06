/*
    Created by: Mahmood (Cognizant) on 12/02/2020
    Description: Test class for FlexCheckout Controller
    -----------------------------------------------------------
    Changed by          Changed date        Description
*/
@isTest
public class TrainingBookingFlexCheckoutCtrTest 
{
    @isTest
    public static void successMethod()
    {
        // build test data 
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
        System.debug('Booking Name: ' + booking.Name);

        // Setup a booker delegate
        TrainingDelegate__c delegate = TrainingBookingTestData.createTestDelegate(booking, true, true);

        // create custom setting
        Ingenico_Ogone_Settings__c iostest = new Ingenico_Ogone_Settings__c(Name ='Ogone', USERID__c = 'testuser', PSPID__c='testbsi', PSWD__c= 'pwd123',
                                                                            ALIASGATEWAY_SHA_IN__c='abc123', ALIASGATEWAY_SHA_OUT__c='123abc', DIRECTLINK_SHA_IN__c= 'xyz123');
        insert iostest;
        // create system settings
        SystemSetting__c ss = new SystemSetting__c(Ingenico_Ogone_ALIASGATEWAY_URL__c = '', SHAEncoding__c = 'SHA512', Ingenico_Ogone_DIRECTLINK_URL__c = 'www.test.com');
        insert ss;
        // Start the processing
        Test.startTest();

        // Set the current page to flexcheckout
        PageReference pageref = Page.TrainingBookingFlexCheckoutSuccessVfp;    
        pageref.getHeaders().put('USER-AGENT','iPhone');
        pageref.getHeaders().put('Accept', 'image/webp,image/apng,image/*,*/*;q=0.8');
        Test.setCurrentPageReference(pageref);

        ApexPages.currentPage().getParameters().put('ALIAS.ALIASID', 'ALIASID');
        ApexPages.currentPage().getParameters().put('ALIAS.ORDERID', booking.Name);
        ApexPages.currentPage().getParameters().put('ALIAS.STATUS', '0');
        ApexPages.currentPage().getParameters().put('ALIAS.CERROR', '0');
        ApexPages.currentPage().getParameters().put('ALIAS.NCERRORCN', '0');
        ApexPages.currentPage().getParameters().put('ALIAS.NCERRORCARDNO', '0');
        ApexPages.currentPage().getParameters().put('ALIAS.NCERRORCVC', '0');
        ApexPages.currentPage().getParameters().put('ALIAS.NCERRORED', '0');
        ApexPages.currentPage().getParameters().put('CARD.CARDHOLDERNAME', 'test');
        
        String ShaSign = calculateSha(ss.SHAEncoding__c, iosTest.ALIASGATEWAY_SHA_OUT__c);
        ApexPages.currentPage().getParameters().put('SHASIGN', ShaSign);
        ApexPages.currentPage().getParameters().put('CT', 'GB_L=EN_ID=' + booking.Id);
                
        // Create an instance of the custom controller with a language
        TrainingBookingFlexCheckoutSuccessCtr cont = new TrainingBookingFlexCheckoutSuccessCtr();
        
        // test payment process
        PageReference init = cont.successPage();
        init = cont.errorPage();
        init = cont.processPayment();
        
        TrainingBookingUtilities.sapOrder(booking.id);
        Test.stoptest();

    }
    @isTest public static void errorTestInvalidTransaction()
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
        
        // Set the current page to flexcheckout
        PageReference pageref = Page.TrainingBookingFlexCheckoutSuccessVfp;    
        Test.setCurrentPageReference(pageref);
		ApexPages.currentPage().getParameters().put('ALIAS.ORDERID', booking.Name);
        System.debug('Name::' + booking.Name);
        
        // Create an instance of the custom controller with a language
        TrainingBookingFlexCheckoutSuccessCtr cont = new TrainingBookingFlexCheckoutSuccessCtr();
        
        Dom.Document xmlDoc = new Dom.Document();
        xmlDoc.load('<?xml version="1.0"?><ncresponse NCERROR="0" PAYID="1234567890" BRAND="VISA" STATUS="0" />');
        Dom.XmlNode xmlRoot = xmlDoc.getRootElement();
            
        cont.transactionHasErrors(xmlRoot);
    }
    @isTest public static void test3D()
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
        
        // Set the current page to flexcheckout
        PageReference pageref = Page.TrainingBookingFlexCheckoutSuccessVfp;    
        Test.setCurrentPageReference(pageref);
		//MODE=3D&orderID=0186702&STATUS=9&PAYID=3065427427&NCERROR=0
        ApexPages.currentPage().getParameters().put('MODE', '3D');
        ApexPages.currentPage().getParameters().put('orderID', booking.Name);
        ApexPages.currentPage().getParameters().put('STATUS', '9');
        ApexPages.currentPage().getParameters().put('PAYID', '3065427427');
        ApexPages.currentPage().getParameters().put('NCERROR', '0');
 		
        // Create an instance of the custom controller with a language
        TrainingBookingFlexCheckoutSuccessCtr cont = new TrainingBookingFlexCheckoutSuccessCtr();
        cont.processPayment();
        cont.getPaymentProcess();
    }
    private static String calculateSha(String encoding, String ShaDirection)
    {
        // *** calculate SHA ***
        
        // Method used to generally validate SHA (IN or OUT)
       	String alias = ApexPages.currentPage().getParameters().get('ALIAS.ALIASID');
        String ncError1 = ApexPages.currentPage().getParameters().get('ALIAS.NCERROR');
        String ncErrorCn1 = ApexPages.currentPage().getParameters().get('ALIAS.NCERRORCN');
        String ncErrorCardNo1 = ApexPages.currentPage().getParameters().get('ALIAS.NCERRORCARDNO');
        String ncErrorCvc1 = ApexPages.currentPage().getParameters().get('ALIAS.NCERRORCVC');
        String ncErrorEd1 = ApexPages.currentPage().getParameters().get('ALIAS.NCERRORED');
        String orderid1 = ApexPages.currentPage().getParameters().get('ALIAS.ORDERID');
        String status1  = ApexPages.currentPage().getParameters().get('ALIAS.STATUS');
        String cardholdername1 = ApexPages.currentPage().getParameters().get('CARD.CARDHOLDERNAME');

        String recvd = '';
        if (String.isNotBlank(alias)) recvd += 'ALIAS.ALIASID=' + alias + ShaDirection;
        if (String.isNotBlank(ncError1)) recvd += 'ALIAS.NCERROR=' + ncError1 + ShaDirection;
        if (String.isNotBlank(ncErrorCardNo1)) recvd += 'ALIAS.NCERRORCARDNO=' + ncErrorCardNo1 + ShaDirection;
        if (String.isNotBlank(ncErrorCn1)) recvd += 'ALIAS.NCERRORCN=' + ncErrorCn1 + ShaDirection;
        if (String.isNotBlank(ncErrorCvc1)) recvd += 'ALIAS.NCERRORCVC=' + ncErrorCvc1 + ShaDirection;
        if (String.isNotBlank(ncErrorEd1)) recvd += 'ALIAS.NCERRORED=' + ncErrorEd1 + ShaDirection;
        if (String.isNotBlank(orderid1)) recvd += 'ALIAS.ORDERID=' + orderid1 + ShaDirection;
        if (String.isNotBlank(status1)) recvd += 'ALIAS.STATUS=' + status1 + ShaDirection;
        if (String.isNotBlank(cardholdername1)) recvd += 'CARD.CARDHOLDERNAME=' + cardholdername1 + ShaDirection;
        
        return EncodingUtil.convertToHex(Crypto.generateDigest(encoding, Blob.valueOf(recvd))).toUpperCase();
        
        // *** end calculate SHA ***
        
    }
}