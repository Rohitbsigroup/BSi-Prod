/*
    22/02/16    CP      TestForwardToStep4AndEnsureErrorIfFreeAccommodationIs0() added, 
                        TestForwardToStep4AndEnsureStepForwardIfFreeAccommodationIs10() added,
                        TestApplyPromoWithValueDiscountAndEnsureCorrectPricesAreAdded() added,
                        TestApplyPromoWithPercentDiscountAndEnsureCorrectPricesAreAdded() added,
                        ForwardToStep4WithAccommodation() added
   05/04/18    MD       Copied from DEV3    28/07/2017   ADS    SoW034 - Online Exam Enhancements
   13/04/18    KD (Brightgen) Modified Creation of Pricebook due to Errors arising from Duplicate Values
   17/04/2018  MD       Reverted previous change - test failed with this in place. TrainingBookingTestData class differs between DEV and QAS, and therefore needs deployed
   17/05/2018  MD       Project 071 GDPR - New Validation requires Agree Personal Data Statement to be ticked
   21/12/2021  CS       Fixed test class for AWIN tracking and South Africa VAT skip JS also renumbered System.asserts
 */
@isTest
private class TrainingBookingControllerTest
{
    @isTest(seeAllData=true) // Needed for access to standard pricebook
    static private void myUnitTest()
    {
        
        //setup account
        Account acc = bg_UnitTestHelper.CreateAccount();
        insert acc;

        // Set up a venue
        Training_Venue__c ven = TrainingBookingTestData.createTestVenue();

        Contact con = bg_UnitTestHelper.CreateContact('ILOVEUNITTESTS', acc);
        con.Country_Office__c = ven.Id;
        con.OtherCountry = 'UK';
        insert con;

        Country_Currency__c countryCurrency = new Country_Currency__c();
        countryCurrency.Name = 'UK';
        countryCurrency.Currency_Code__c = 'GBP';
        countryCurrency.Country_Name__c = 'United Kingdom';
        countryCurrency.CurrencyIsoCode = 'GBP';
        insert countryCurrency;

        // Set up product #1 (non-residential)
        //Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        Decimal courseCost = 0; // MD Must be zero as using Standard Pricebook
        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 10, 'UTCOURSENAME', 'GBP', null, 'EMS12345ENUK', null, null, null);
        PricebookEntry pbe1 = TrainingBookingTestData.createTestPbe(prd1, courseCost, 'GBP');
        
        // Set up product #4 (exam)
        Decimal onlineExamCost = 0; // MD Must be zero as using Standard Pricebook
        Product2 prd4 = TrainingBookingTestData.createTestCourse('Normal', 10, 'UTCOURSENAME', 'GBP', null, 'EMS67890ENUK', null, null, null);
        PricebookEntry pbe4 = TrainingBookingTestData.createTestPbe(prd4, onlineExamCost, 'GBP');
        
        // Set up product #5 (standard)
        Decimal onlineStandardCost = 0; // MD Must be zero as using Standard Pricebook
        Product2 prd5 = TrainingBookingTestData.createTestCourse('Normal', 10, 'UTCOURSENAME', 'GBP', null, 'EMS67890ENUK', null, null, null);
        PricebookEntry pbe5 = TrainingBookingTestData.createTestPbe(prd5, onlineStandardCost, 'GBP');
        
        // Set up product #6 (extra night)
        Decimal extraNightCost = 0; // MD Must be zero as using Standard Pricebook
        Product2 prd6 = TrainingBookingTestData.createTestCourse('Normal', 10, 'UTCOURSENAME', 'GBP', null, 'EMS67890ENUK', null, null, null);
        PricebookEntry pbe6 = TrainingBookingTestData.createTestPbe(prd6, extraNightCost, 'GBP');
        
        prd1.Online_Exam__c = prd4.Id;
        prd1.Online_Standard__c = prd5.Id;
        prd1.Extra_Night__c = prd6.Id;
        update prd1;
        
        Training_Event__c evt1 = TrainingBookingTestData.createTestEvent(prd1, ven, 10, Con.Id);
        
        // Set up product #2 (residential)
        Product2 accommProduct = TrainingBookingTestData.createTestCourse('Normal', 0, 'UTACCOMMPROD', 'GBP', null, 'EMS12345ENUK', null, null, null);
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 10, 'UTCOURSENAME', 'GBP', null, 'EMS12345ENUK', accommProduct, null, null);
        // prd2.Course_Format__c = 'Distance Learning';
        // update prd2;
        Training_Event__c evt2 = TrainingBookingTestData.createTestEvent(prd2, ven, 5, Con.Id);
        PricebookEntry pbeAccomm = TrainingBookingTestData.createTestPbe(accommProduct, 50, 'GBP');
        PricebookEntry pbe2 = TrainingBookingTestData.createTestPbe(prd2, 100, 'GBP');
        
        // Set up product #3 (distance)
        Product2 prd3 = TrainingBookingTestData.createTestCourse('Distance', 10, 'UTCOURSENAME', 'GBP', null, 'EMS67890ENUK', null, null, null);
        prd3.Course_Format__c = 'Distance Learning';
        update prd3;
        Training_Event__c evt3 = TrainingBookingTestData.createTestEvent(prd3, ven, 10, Con.Id);
        PricebookEntry pbe3 = TrainingBookingTestData.createTestPbe(prd3, 100, 'GBP');
        
        // Set up promotional code
        Training_Promo_Code__c prm1 = TrainingBookingTestData.createTestPromo();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        // Start the processing
        Test.startTest();

        // Create an instance of the custom controller to test Distance Learning Course_Format__c
        TrainingBookingController cont = new TrainingBookingController();

        // Set the current page to training booking step 1
        PageReference addPage = Page.TrainingBooking1;
        Test.setCurrentPageReference(addPage);

        //// Create an instance of the custom controller without parameters
        cont = new TrainingBookingController();
        PageReference init = cont.initCheck();
        //System.assert(init.getUrl().startsWith('/apex/trainingbooking7'));

        // 23 Nov 2016 Vim addedd test class code   
        boolean isValidEUCountry = TrainingBookingUtilities.validateEUCountryCodes('CY');
        System.debug(isValidEUCountry);
        // Vim code ends here
        
        // Create an instance of the custom controller with a specified language
        ApexPages.currentPage().getParameters().put('L', 'EN');
        cont = new TrainingBookingController();
        PageReference init4 = cont.initCheck();
        //System.assert(init4.getUrl().startsWith('/apex/trainingbooking7'));

        // Create an instance of the custom controller with a specified country
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        cont = new TrainingBookingController();
        PageReference init3 = cont.initCheck();
        //System.assert(init3.getUrl().startsWith('/apex/trainingbooking7'));

        // Create an instance of the custom controller with a bad taxonomy
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('C', '');//
        cont = new TrainingBookingController();
        PageReference init2 = cont.initCheck();
        system.debug('$$$$$ Page Params: ' + ApexPages.currentPage().getParameters());
        system.debug('$$$$$ Init: ' + init2);
        //System.assert(init2.getUrl() == cont.selectedCountry.enquiryUrl);

        // Create an instance of the custom controller with a good taxonomy
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('C', 'EMS12345ENUK');
        ApexPages.currentPage().getParameters().put('PB', pbe1.Pricebook2Id);
        ApexPages.currentPage().getParameters().put('ISOCode', 'GBP');
        cont = new TrainingBookingController();
        PageReference init1 = cont.initCheck();
        system.debug('##$$ Page Params: ' + ApexPages.currentPage().getParameters());
        system.debug('##$$ Init: ' + init2);
        System.assert(init1 == null);

        // Get the location options
        cont.getLocationOptions();
        // Try to change the location filter 
        cont.changeFilter();
        // Try the show more events option
        cont.moreEvents();

        // Progress without accommodation and with card ====================================================================================
        
        // progress to portal login page
        cont.selectedEventId = evt1.Id;
        PageReference loginStep = cont.forwardToLogin();
        System.assert(loginStep.getUrl() == '/apex/trainingbookingcommunityuserlogin');

        // Try selecting the first entry and moving to step 2
        cont.selectedEventId = evt1.Id;
        PageReference step2 = cont.forwardToStep2();
        System.assert(step2.getUrl() == '/apex/trainingbooking2');
        
        System.assertEquals(onlineExamCost, cont.objBooking.Price_Per_Delegate_Online_Exam__c);
        System.assertEquals(onlineStandardCost, cont.objBooking.Price_Per_Delegate_Online_Standard__c);
        
        // Try stepping back to step 1
        PageReference step1 = cont.backToStep1();
        System.assert(step1.getUrl() == '/apex/trainingbooking1');

        // Try the drop-down list of delegate options
        cont.getDelegateOptions();
        // Try setting values and moving to step 3
        cont.selectedDelegates = 3;
        cont.objBooking.Salutation__c = '';
        cont.objBooking.First_Name__c = 'Test';
        cont.objBooking.Last_Name__c = 'Contact';
        cont.objBooking.Email_Address__c = 'test@bsigroup.com';
        cont.objBooking.Job_Title__c = 'Manager';
        cont.objBooking.Attending_Course__c = true;
        cont.objBooking.Company_Name__c = 'Test Company';
        cont.objBooking.Company_Street__c = '389 High Rd';
        cont.objBooking.Company_City__c = 'London';
        cont.objBooking.Company_Region__c = 'Buckinghamshire';
        cont.objBooking.Company_Region_Code__c = 'BU';
        cont.objBooking.Company_Postcode__c = 'W4 4AL';
        cont.objBooking.Company_Country__c = 'United Kingdom';
        cont.objBooking.Company_Country_Code__c = 'GB';
        cont.objBooking.Contact_Phone__c = '02089969000';
        cont.objBooking.Contact_Mobile__c = '07234123234';
        cont.objBooking.Contact_Fax__c = '02089969001';
        cont.objBooking.Billing_Address__c = true;
        cont.objBooking.Billing_Name__c = 'Test Company';
        cont.objBooking.Billing_Street__c = '389 High Rd';
        cont.objBooking.Billing_City__c = 'London';
        cont.objBooking.Billing_Region__c = 'Buckinghamshire';
        cont.objBooking.Billing_Region_Code__c = 'BU';
        cont.objBooking.Billing_Postcode__c = 'W4 4AL';
        cont.objBooking.Billing_Country__c = 'United Kingdom';
        cont.objBooking.Billing_Country_Code__c = 'GB';
        // With mismatched emails
        cont.objBooking.Email_Confirmation__c = 'wrong@bsigroup.com';
        PageReference step3 = cont.forwardToStep3();
        List<ApexPages.Message> messageList = ApexPages.getMessages();
        System.assert(1 == messageList.size());
        System.assertEquals(ApexPages.getMessages().get(0).getSummary(), 'The email address and confirmation must match.', 'The method should return email validation exception');
        // With bad VAT number
        cont.objBooking.Email_Confirmation__c = 'test@bsigroup.com';
        cont.objBooking.VAT_Number__c = 'GB000000000';
        step3 = cont.forwardToStep3();
        messageList = ApexPages.getMessages();
        System.debug('====step 3 '+ ApexPages.getMessages());
        System.assert(1 == messageList.size());
        // With VAT number service outage
        cont.objBooking.VAT_Number__c = 'AA000000000';
        step3 = cont.forwardToStep3();
        messageList = ApexPages.getMessages();
        System.assert(1 == messageList.size());
        // With matched emails and good VAT number
        cont.objBooking.VAT_Number__c = 'GB123456789';
        step3 = cont.forwardToStep3();
        System.assert(step3.getUrl() == '/apex/trainingbooking3');

        // Try stepping back to step 2
        step2 = cont.backToStep2();
        System.assert(step2.getUrl() == '/apex/trainingbooking2');
        
        // Try setting values and moving to step 4
        cont.objDelegates[0].Accommodation_Required__c = false;
        cont.objDelegates[1].Salutation__c = '';
        cont.objDelegates[1].First_Name__c = 'Test';
        cont.objDelegates[1].Last_Name__c = 'Delegate1';
        cont.objDelegates[1].First_Name_English__c = '';
        cont.objDelegates[1].Last_Name_English__c = '';
        cont.objDelegates[1].Email_Address__c = 'test@bsigroup.com';
        cont.objDelegates[1].Job_Title__c = 'Test Title';
        cont.objDelegates[1].Accommodation_Required__c = false;
        // With mismatched emails
        cont.objDelegates[1].Email_Confirmation__c = 'wrong@bsigroup.com';
        PageReference step4 = cont.forwardToStep4();
        System.assert(step4 == null);
        // With matched emails
        cont.objDelegates[1].Email_Confirmation__c = 'test@bsigroup.com';
        step4 = cont.forwardToStep4();
        System.assert(step4.getUrl() == '/apex/trainingbooking4');
        
        System.assertEquals(cont.selectedDelegates * courseCost, cont.objBooking.Net_Price__c);

        // Try stepping back to step 3
        step3 = cont.backToStep3();
        System.assert(step3.getUrl() == '/apex/trainingbooking3');

        // Apply a duff promo
        cont.objBooking.Promotional_Code__c = 'DUFFER';
        cont.applyPromo();

        // Apply a good promo
        cont.objBooking.Promotional_Code__c = 'PROMO';
        cont.applyPromo();
        
        // Remove a promo
        cont.removePromo();

        // Reset a promo
        cont.resetPromo();

        // Try moving on to step 5 (card payment)
        cont.objBooking.Payment_Method__c = 'Card';
        // Without terms agreed
        cont.objBooking.Agree_Personal_Data_Statement__c = false;
        cont.objBooking.Agree_Terms_Conditions__c = false;
        PageReference step5 = cont.forwardToStep5or6();
        System.assert(step5 == null);
        // With terms agreed
        cont.objBooking.Agree_Personal_Data_Statement__c = true;
        cont.objBooking.Agree_Terms_Conditions__c = true;
        step5 = cont.forwardToStep5or6();
        System.assert(step5 != null);

        // Try to re-submit
        step5 = cont.forwardToStep5or6();
        System.assert(step5 == null);

        // Progress with accommodation and invoice ==========================================================================================

        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('C', 'EMS12345ENUK');
        ApexPages.currentPage().getParameters().put('ID', '');
        ApexPages.currentPage().getParameters().put('PB', pbe2.Pricebook2Id);
        ApexPages.currentPage().getParameters().put('ISOCode', 'GBP');

        // Reset the controller
        cont = new TrainingBookingController();
        
        // Try selecting the eleventh entry and moving to step 2
        cont.selectedEventId = evt2.Id;
        step2 = cont.forwardToStep2();
        System.assert(step2.getUrl() == '/apex/trainingbooking2');
        
        // Try setting values and moving to step 3
        cont.selectedDelegates = 3;
        cont.objBooking.Salutation__c = '';
        cont.objBooking.First_Name__c = 'Test';
        cont.objBooking.Last_Name__c = 'Contact';
        cont.objBooking.Email_Address__c = 'test@bsigroup.com';
        cont.objBooking.Email_Confirmation__c = 'test@bsigroup.com';
        cont.objBooking.Job_Title__c = 'Manager';
        cont.objBooking.Attending_Course__c = true;
        cont.objBooking.Company_Name__c = 'Test Company';
        cont.objBooking.Company_Street__c = '389 High Rd';
        cont.objBooking.Company_City__c = 'Rome';
        cont.objBooking.Company_Region__c = 'Rome';
        cont.objBooking.Company_Region_Code__c = 'BU';
        cont.objBooking.Company_Postcode__c = 'W4 4AL';
        cont.objBooking.Company_Country__c = 'Italy';
        cont.objBooking.Company_Country_Code__c = 'IT';
        cont.objBooking.Contact_Phone__c = '02089969000';
        cont.objBooking.Company_Professional__c = 'Company';
        cont.objBooking.Contact_Mobile__c = '07234123234';
        cont.objBooking.Billing_Country_Code__c = 'IT';
        cont.objBooking.Contact_Fax__c = '02089969001';
        cont.objBooking.VAT_Number__c = 'IT00743110157';
        cont.objBooking.Invoice_Recipient_Code__c = '00000000';
        cont.objBooking.Registered_Email_for_Invoice__c = 'registeredEmail@test.com';
        cont.objBooking.Billing_Address__c = false;
        cont.selectedCountry.flags = 'italyFormat';
        cont.forwardToStep3();
        System.debug('====step 3 Italy invalid VAT ' + ApexPages.getMessages().size());
        System.assert(5 == ApexPages.getMessages().size());

        cont.objBooking.VAT_Number__c = '';
        cont.forwardToStep3();
        System.debug('====step 3 Italy blank VAT ' + ApexPages.getMessages().size());
        System.assert(6 == ApexPages.getMessages().size());

        cont.objBooking.Company_Professional__c = null;
        cont.forwardToStep3();
        System.debug('====step 3 Company professional null ' + ApexPages.getMessages().size());
        System.assert(7 == ApexPages.getMessages().size());

        cont.objBooking.Company_Professional__c = 'Company';
        cont.objBooking.Billing_Country_Code__c = 'GB';
        cont.objBooking.VAT_Number__c = 'GB00743110157';
        cont.forwardToStep3();
        System.debug('====step 3 Incorrect VAT and Billing country code ' + ApexPages.getMessages().size());
        System.assert(8 == ApexPages.getMessages().size());
        
        cont.objBooking.Company_Professional__c = 'Professional';
        cont.forwardToStep3();
        System.debug('====step 3 Company Professional is Professional ' + ApexPages.getMessages().size());
        System.assert(9 == ApexPages.getMessages().size());

        cont.selectedCountry.blockCrossBorderBookings = true;
        cont.selectedCountry.allowedCrossBorderCountries = 'Italy';
        cont.selectedCountry.countryCode = '375';
        cont.objBooking.Phone_Country_Code__c = '333';
        cont.forwardToStep3();
        System.debug('====step 3 Different Country Codes ' + ApexPages.getMessages().size());
        System.assert(11 == ApexPages.getMessages().size());

        cont.selectedCountry.blockCrossBorderBookings = false;
        cont.selectedEvent.event.Course__r.Block_Cross_Border_Bookings__c = true;
        cont.selectedEvent.event.Course__r.Allowed_cross_border_Countries__c = 'Italy';
        cont.forwardToStep3();
        System.debug('====step 3 Block_Cross_Border_Bookings__c true' + ApexPages.getMessages().size());
        System.assert(11 == ApexPages.getMessages().size());
        
        // Check validation VAT number for non-Italy (Spain)
        cont.objBooking.Company_Country__c = 'Spain';
        cont.objBooking.Company_Country_Code__c = 'GB';
        cont.objBooking.Contact_Mobile__c = '07234123234';
        cont.objBooking.Billing_Country_Code__c = 'ES';
        cont.objBooking.VAT_Number__c = 'GB000000000';
        cont.selectedCountry.flags = 'VATRequired';
        step3 = cont.forwardToStep3();
        System.assert(11 == ApexPages.getMessages().size());

        cont.objBooking.Company_Country_Code__c = 'ES';
        cont.objBooking.Billing_Country_Code__c = 'ES';
        cont.objBooking.VAT_Number__c = 'ES000000000';
        step3 = cont.forwardToStep3();
        System.debug('====step 3 Incorrect VAT Validation '+ ApexPages.getMessages().size());
        System.assert(11 == ApexPages.getMessages().size());

        // VAT Number mandatory for South Africa
        cont.objBooking.Company_Country__c = 'South Africa';
        cont.objBooking.VAT_Number2__C = '';
        cont.selectedCountry.Flags = 'Vat2Display';
        step3 = cont.forwardToStep3();
        //System.debug('====step 3 VAT Number mandatory for South Africa '+ ApexPages.getMessages().size());
        //System.assert(12 == ApexPages.getMessages().size());

        // NIP Field Number mandatory for Poland
        cont.objBooking.Company_Country__c = 'Poland';
        cont.objBooking.VAT_Number__c = '';
        cont.selectedCountry.Flags = 'VATRequired';
        step3 = cont.forwardToStep3();
        System.debug('====step 3 NIP Field Number mandatory for Poland '+ ApexPages.getMessages().size());
        System.assert(12 == ApexPages.getMessages().size());
        //System.assert(13 == ApexPages.getMessages().size());

        // Validate the company street
        cont.objBooking.Company_Street__c = 
            'Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 ' + 
            'Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 ' + 
            'Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 ' +
            'Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 ' + 
            'Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 ' + 
            'Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 Test line1 ';
        step3 = cont.forwardToStep3();
        System.debug('====step 3 Too much lines in Company street name '+ ApexPages.getMessages().size());
        System.assert(13 == ApexPages.getMessages().size());
        //System.assert(14 == ApexPages.getMessages().size());


        // Reset the controller For Asperato Payment page
        cont = new TrainingBookingController();

        // Try selecting the eleventh entry and moving to step 2
        cont.selectedEventId = evt2.Id;
        step2 = cont.forwardToStep2();
        System.assert(step2.getUrl() == '/apex/trainingbooking2');

        // Try setting values and moving to step 3
        cont = setValuesForTrainingBooking(cont);
        step3 = cont.forwardToStep3();
        System.assert(step3.getUrl() == '/apex/trainingbooking3');
        cont.checkValue();
        // Try setting values and moving to step 4
        cont = setValuesForTrainingDelegate(cont);
        cont.selectedCountry.calculateTaxMethod = 'SAP';
        step4 = cont.forwardToStep4();
        System.assert(step4.getUrl() == '/apex/trainingbooking4');

        cont.objBooking.Payment_Method__c = 'Card';
        cont.objBooking.Agree_Terms_Conditions__c = true;
        cont.objBooking.Agree_Personal_Data_Statement__c = true;
        cont.objBooking.Promotional_Code__c = '';
        cont.selectedCountry.gateway = 'Asperato';
        PageReference step6 = cont.forwardToStep5or6();


        // // Reset the controller For NAB Payment page
        // cont = new TrainingBookingController();

        // // Try selecting the eleventh entry and moving to step 2
        // cont.selectedEventId = evt2.Id;
        // step2 = cont.forwardToStep2();
        // System.assert(step2.getUrl() == '/apex/trainingbooking2');

        // // Try setting values and moving to step 3
        // cont = setValuesForTrainingBooking(cont);
        // step3 = cont.forwardToStep3();
        // System.assert(step3.getUrl() == '/apex/trainingbooking3');
        // cont.checkValue();
        // // Try setting values and moving to step 4
        // cont = setValuesForTrainingDelegate(cont);
        // cont.selectedCountry.calculateTaxMethod = 'SAP';
        // step4 = cont.forwardToStep4();
        // System.assert(step4.getUrl() == '/apex/trainingbooking4');

        // cont.objBooking.Payment_Method__c = 'Card';
        // cont.objBooking.Agree_Terms_Conditions__c = true;
        // cont.objBooking.Agree_Personal_Data_Statement__c = true;
        // cont.objBooking.Promotional_Code__c = '';
        // cont.selectedCountry.gateway = 'NAB';
        // step6 = cont.forwardToStep5or6();


        // Reset the controller For Invoice Payment page
        cont = new TrainingBookingController();

        // Try selecting the eleventh entry and moving to step 2
        cont.selectedEventId = evt2.Id;
        step2 = cont.forwardToStep2();
        System.assert(step2.getUrl() == '/apex/trainingbooking2');

        // Try setting values and moving to step 3
        cont = setValuesForTrainingBooking(cont);
        step3 = cont.forwardToStep3();
        System.assert(step3.getUrl() == '/apex/trainingbooking3');
        cont.checkValue();
        // Try setting values and moving to step 4
        cont = setValuesForTrainingDelegate(cont);

        cont.selectedCountry.calculateTaxMethod = 'SFDC';
        cont.objBooking.Net_Price__c = 200.00;
        cont.objBooking.Discount__c = 10;
        cont.selectedCountry.taxRate = 10;
        step4 = cont.forwardToStep4();
        System.assert(step4.getUrl() == '/apex/trainingbooking4');

        cont.selectedCountry.calculateTaxMethod = 'SAP';
        step4 = cont.forwardToStep4();
        System.assert(step4.getUrl() == '/apex/trainingbooking4');

        cont.selectedCountry.calculateTaxMethod = 'SFDC';
        cont.selectedCountry.Flags = 'bankTransfer';
        step6 = cont.forwardToStep5or6();
        System.debug('====step 5 or 6 Check immediate payment ' + ApexPages.getMessages().size());
        System.assert(14 == ApexPages.getMessages().size());
        //System.assert(15 == ApexPages.getMessages().size());

        cont.selectedCountry.Flags = '';
        cont.objBooking.Promotional_Code__c = '00000';
        cont.objBooking.Discount__c = 0;
        step6 = cont.forwardToStep5or6();
        System.debug('====step 5 or 6 Check no un-applied promo code ' + ApexPages.getMessages().size());
        System.assert(15 == ApexPages.getMessages().size());
        //System.assert(16 == ApexPages.getMessages().size());

        // Try moving on to step 5 (invoice payment)
        cont.objBooking.Promotional_Code__c = '';
        cont.objBooking.Payment_Method__c = 'Invoice';
        cont.objBooking.Agree_Terms_Conditions__c = true;
        cont.objBooking.Agree_Personal_Data_Statement__c = true;
        step6 = cont.forwardToStep5or6();
        system.debug('page 6 Invoice ' + step6.getUrl());
        System.assert(step6.getUrl() == '/apex/trainingbooking6');

        // Try printing confirmation (invoice payment)
        PageReference step8 = cont.printConfirmation();
        System.assert(step8.getUrl().containsIgnoreCase('TrainingBooking8'));
        
        // Try the second entry mechanism with an ID specified
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('C', '');
        ApexPages.currentPage().getParameters().put('ID', cont.objBooking.Id);
        ApexPages.currentPage().getParameters().put('PB', '');


        cont = new TrainingBookingController();
        // MB -20/03- invalid ID test
        Id testBookingid = 'a2F8E000004000dUAI';
        TrainingBookingUtilities.bookingDetails(testBookingId) ;
        
        // 23 Nov 2016 Vim added test code 
        TrainingBookingUtilities.bookingDetails(cont.objBooking.Id) ;
        // vim code ends here 
    
        // // Distance learning ==========================================================================================

        // Create a second instance of the custom controller for distance learning
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('C', 'EMS67890ENUK');
        ApexPages.currentPage().getParameters().put('ID', '');
        ApexPages.currentPage().getParameters().put('PB', pbe3.Pricebook2Id);
        cont = new TrainingBookingController();
        System.debug(LoggingLevel.ERROR, cont.pageShowSelection);
        // System.assert(cont.pageShowSelection = false);

        // Stop the processing
        Test.stopTest();
    }

    private static TrainingBookingController setValuesForTrainingBooking(TrainingBookingController cont) {
        cont.selectedDelegates = 2;
        cont.objBooking.Salutation__c = '';
        cont.objBooking.First_Name__c = 'Test';
        cont.objBooking.Last_Name__c = 'Contact';
        cont.objBooking.Email_Address__c = 'test@bsigroup.com';
        cont.objBooking.Email_Confirmation__c = 'test@bsigroup.com';
        cont.objBooking.Job_Title__c = 'Manager';
        cont.objBooking.Attending_Course__c = true;
        cont.objBooking.Company_Name__c = 'Test Company';
        cont.objBooking.Company_Street__c = '389 High Rd';
        cont.objBooking.Company_City__c = 'London';
        cont.objBooking.Company_Region__c = 'Buckinghamshire';
        cont.objBooking.Company_Region_Code__c = 'BU';
        cont.objBooking.Company_Postcode__c = 'W4 4AL';
        cont.objBooking.Company_Country__c = 'United Kingdom';
        cont.objBooking.Company_Country_Code__c = 'GB';
        cont.objBooking.Contact_Phone__c = '02089969000';
        cont.objBooking.Contact_Mobile__c = '07234123234';
        cont.objBooking.Contact_Fax__c = '02089969001';
        cont.objBooking.VAT_Number__c = '';
        cont.objBooking.Billing_Address__c = false;

        return cont;
    }

    private static TrainingBookingController setValuesForTrainingDelegate(TrainingBookingController cont) {
        cont.objDelegates[0].Accommodation_Required__c = true;
        cont.objDelegates[0].Standard__c = true;
        cont.objDelegates[1].Salutation__c = '';
        cont.objDelegates[1].First_Name__c = 'Test';
        cont.objDelegates[1].Last_Name__c = 'Delegate1';
        cont.objDelegates[1].First_Name_English__c = '';
        cont.objDelegates[1].Last_Name_English__c = '';
        cont.objDelegates[1].Email_Address__c = 'test@bsigroup.com';
        cont.objDelegates[1].Email_Confirmation__c = 'test@bsigroup.com';
        cont.objDelegates[1].Job_Title__c = 'Test Title';
        cont.objDelegates[1].Accommodation_Required__c = false;
        cont.objDelegates[1].Online_Exam__c = true;

        return cont;
    }

    // MB - 20/03 
    @isTest static void testInvalidBookingId()
    {
        // MB -20/03- invalid ID test
        Id testBookingid = 'a2F8E000004000dUAI';
        // Try the second entry mechanism with an ID specified
        ApexPages.currentPage().getParameters().put('L', 'EN');
        ApexPages.currentPage().getParameters().put('CT', 'GB');
        ApexPages.currentPage().getParameters().put('C', '');
        ApexPages.currentPage().getParameters().put('ID', testBookingid);
        ApexPages.currentPage().getParameters().put('PB', '');
        TrainingBookingController cont = new TrainingBookingController();
        
    }
    /*
     * Do forwardToStep4() with free accommodation 0 and check that null is returned and correct error is being
     * thrown as there is not enough accommodation for the delegates.
     */
    @isTest
    static private void TestForwardToStep4AndEnsureErrorIfFreeAccommodationIs0()
    {
        
        PageReference stepForward = ForwardToStep4WithAccommodation(0);
        System.assertEquals(null,stepForward);
        List<ApexPages.Message> errors = ApexPages.getMessages();
        System.assertNotEquals(0, errors.size());
        System.assert(bg_UnitTestHelper.CheckErrorIsInListOfErrors(errors,String.format(Label.TrainingEventAccommInsufficient, 
            new string[] {String.valueOf(0)})));
    }

    /*
     * Do forwardToStep4() with free accommodation 10 and check that page 4 is returned  without any errors being
     * thrown as there is enough accommodation for the delegates.
     */
    @isTest
    static private void TestForwardToStep4AndEnsureStepForwardIfFreeAccommodationIs10()
    {
        
        PageReference stepForward = ForwardToStep4WithAccommodation(10);
        System.assertEquals(Page.TrainingBooking4.getUrl(),stepForward.getUrl());
        List<ApexPages.Message> errors = ApexPages.getMessages();
        System.assertEquals(0, errors.size());
        
    }

    /*
     * Apply Promo code for Value discount of 50 and ensure correct prices are calculated
     */
    @isTest
    static private void TestApplyPromoWithValueDiscountAndEnsureCorrectPricesAreAdded()
    {
        
        TrainingBookingController cont = bg_UnitTestHelper.SetupTrainingBookingController(10);
        cont.objBooking.Promotional_Code__c = 'Value';
        Test.startTest();
        cont.applyPromo();
        Test.stopTest();
        System.assertEquals('UK', cont.selectedEvent.event.Event_Country__c);
        System.assertEquals('Value', cont.objBooking.Promotional_Code__c);
        System.assertEquals(50, cont.objBooking.Discount_Value__c);
        System.assertEquals(0, cont.objBooking.Discount_Percentage__c);
        System.assertEquals(250, cont.objBooking.Net_Price__c);
        System.assertEquals(200, cont.objBooking.Price_Exc_Accommodation__c);
        System.assertEquals(250, cont.objBooking.Price_Inc_Accommodation__c);
        System.assertEquals(50, cont.objBooking.Discount__c);
    }

    /*
     * Apply Promo code for Percent discount of 50% and ensure correct prices are calculated
     */
    @isTest
    static private void TestApplyPromoWithPercentDiscountAndEnsureCorrectPricesAreAdded()
    {
        TrainingBookingController cont = bg_UnitTestHelper.SetupTrainingBookingController(10);
        cont.objBooking.Promotional_Code__c = 'Percent';
        Test.startTest();
        cont.applyPromo();
        Test.stopTest();
        System.assertEquals('UK', cont.selectedEvent.event.Event_Country__c);
        System.assertEquals('Percent', cont.objBooking.Promotional_Code__c);
        System.assertEquals(0, cont.objBooking.Discount_Value__c);
        System.assertEquals(0.5, cont.objBooking.Discount_Percentage__c);
        System.assertEquals(250, cont.objBooking.Net_Price__c); 
        System.assertEquals(200, cont.objBooking.Price_Exc_Accommodation__c);
        System.assertEquals(250, cont.objBooking.Price_Inc_Accommodation__c);
        System.assertEquals(100, cont.objBooking.Discount__c);
    }

    /*
     * Do the set up to do forwardToStep4() setting the max accommodation to the inputted integer and return
     * the page reference from forwardToStep4().
     */
    static private PageReference ForwardToStep4WithAccommodation(Integer maxAccommodation)
    {
        
        TrainingBookingController cont = bg_UnitTestHelper.SetupTrainingBookingController(maxAccommodation);
        Test.startTest();
        PageReference stepForward = cont.forwardToStep4();
        Test.stopTest();
        return stepForward;
    }

    @isTest(seeAllData=false)
    private static void TestOnlineExam()
    {
        final Decimal onlineExamCost = 0;
        final Decimal onlineStandardCost = 0;
        
        final Account theAccount = bg_UnitTestHelper.GetAccount();
        final Contact theContact = bg_UnitTestHelper.GetContact('Test Contact', theAccount);
        final Training_Venue__c theTrainingVenue = TrainingBookingTestData.createTestVenue();
        final Product2 theTrainingCourse = TrainingBookingTestData.createTestCourse('Normal', 'Test Course');

        final PricebookEntry theTrainingCoursePricebookEntry = TrainingBookingTestData.createTestPbe(theTrainingCourse, 1000.0, 'GBP');
        // final PricebookEntry theTrainingCoursePricebookEntry = [SELECT ID, Product2Id, CurrencyIsoCode FROM PricebookEntry WHERE Product2Id =: theTrainingCourse.Id AND CurrencyIsoCode = 'GBP' LIMIT  1];

        final Training_Event__c theTrainingEvent = TrainingBookingTestData.createTestEvent(theTrainingCourse, theTrainingVenue, 10, theContact.Id);
        final Product2 theOnlineExam = TrainingBookingTestData.createTestCourse('Normal', 'Test Exam');
        final PricebookEntry theOnlineExamPricebookEntry = TrainingBookingTestData.createTestPbe(theOnlineExam, onlineExamCost, 'GBP');
        final Product2 theOnlineStandard = TrainingBookingTestData.createTestCourse('Normal', 'Test Standard');
        final PricebookEntry theOnlineStandardPricebookEntry = TrainingBookingTestData.createTestPbe(theOnlineStandard, onlineStandardCost, 'GBP');
        theTrainingCourse.Online_Exam__c = theOnlineExam.Id;
        theTrainingCourse.Online_Standard__c = theOnlineStandard.Id;
        update theTrainingCourse;
        
        final TrainingBooking__c theTrainingBooking = new TrainingBooking__c();
        theTrainingBooking.Pricebook_Entry__c = theTrainingCoursePricebookEntry.Id;
        theTrainingBooking.Pricebook_Entry_Online_Exam__c = theOnlineExamPricebookEntry.Id;
        theTrainingBooking.Pricebook_Entry_Online_Standard__c = theOnlineStandardPricebookEntry.Id;
        theTrainingBooking.Training_Event__c = theTrainingEvent.Id;
        
        Test.startTest();
        final TrainingBookingUtilities.EventWrapper theSelectedEvent = new TrainingBookingUtilities.EventWrapper(theTrainingBooking);
        Test.stopTest();
        
        System.assertEquals(theOnlineExam.Id, theSelectedEvent.Event.Course__r.Online_Exam__c);
        System.assertEquals(theOnlineExamPricebookEntry.Id, theSelectedEvent.onlineExamPrice.Id);
        System.assert(theSelectedEvent.onlineExamAvailable);
        System.assertEquals(onlineExamCost, theSelectedEvent.onlineExamCost);
        System.assert(theSelectedEvent.onlineStandardAvailable);
        System.assertEquals(onlineStandardCost, theSelectedEvent.onlineStandardCost);
        System.assertEquals(0.0, theSelectedEvent.extraNightCost);
        System.assertEquals(0.0, theSelectedEvent.totalPriceWithAccom);
        System.assertEquals(0.0, theSelectedEvent.totalPriceWithExtraNight);
        System.assertEquals(0.0, theSelectedEvent.totalPriceWithAccomAndExtraNight);
        System.assert(!theSelectedEvent.accommodationAvailable);
        System.assert(!theSelectedEvent.extraNightAvailable);
        
        // test other event wrapper constructors
        Training_Event__c[] event = [SELECT id, Accommodation_available_for_this_event__c, Course_Duration_Days__c, Max_seats__c, Enrollment_Count__c,
                                            On_Hold_for_Payment__c, Enrollment_Pending__c, Start_date__c, End_date__c
                                     FROM Training_Event__c WHERE Id =: theTrainingEvent.Id];
        TrainingBookingUtilities.EventWrapper evWrapper = 
            new TrainingBookingUtilities.EventWrapper(event[0], theTrainingCoursePricebookEntry, theOnlineExamPricebookEntry);
        
    }
    
    @isTest(seeAllData=false)
    private static void TestCreateAsperatoPayment() {
        asp04__AsperatoOneSettings__c asperatoSettings = new asp04__AsperatoOneSettings__c(
            asp04__Customer_ID__c = '2820',
            asp04__Is_Live__c = false,
            asp04__Server_URL__c = 'test.protectedpayments.net',
            asp04__BACS_Delay__c = 4,
            asp04__CreatePaymentSchedule__c = true
        );
        insert asperatoSettings;
        TrainingBookingController cont = bg_UnitTestHelper.SetupTrainingBookingController(10);
        cont.objBooking.Total_Price__c = 1000;
        cont.objBooking.CurrencyIsoCode = 'GBP';
        Test.startTest();
        cont.createAsperatoPayment();
        Test.stopTest();
        List<asp04__Payment__c> payments = [SELECT Id FROM asp04__Payment__c];
        System.assertEquals(1, payments.size(), 'failed to create payment');
    }
    
    @isTest(seeAllData=false)
    private static void TestCheckIP() {
        TrainingBookingController cont = bg_UnitTestHelper.SetupTrainingBookingController(10);
        cont.selectedCountry.blockCrossBorderBookings = true;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Test.startTest();
        Boolean ipCheckStatus = cont.checkIP();
        Test.stopTest();
        System.assertEquals(true, ipCheckStatus, 'Failed to validate ip country code');
    }
    
    @isTest(seeAllData=false)
    private static void TestSetExistingContactDetails() {
        Account account = bg_UnitTestHelper.GetAccount();
        Contact contact = bg_UnitTestHelper.GetContact('Test Contact', account);
        contact.MailingStreet = 'main street';
        contact.OtherStreet = 'different street';
        contact.MailingCountry = 'GB';
        contact.OtherCountry = 'GB';
        update contact;
        TrainingBookingController cont = bg_UnitTestHelper.SetupTrainingBookingController(10);
        Test.startTest();
        cont.setExistingContactDetails(contact.Id);
        Test.stopTest();
        System.assertEquals(contact.MailingStreet, cont.objBooking.Company_Street__c, 'Failed to populate mailing street');
        System.assertEquals(contact.OtherStreet, cont.objBooking.Billing_Street__c, 'Failed to populate billing street');

    }
    
    @isTest(seeAllData=false)
    private static void testGetIpAddress(){
        PageReference myVfPage = Page.TrainingBooking;
        Test.setCurrentPage(myVfPage);
        Test.startTest();
        ApexPages.currentPage().getHeaders().put('True-Client-IP','123');
        TrainingBookingController cont = bg_UnitTestHelper.SetupTrainingBookingController(10);
        String addressString = cont.getIPAddress();
        Test.stopTest();
        System.assertEquals('123', addressString, 'Should be returned True IP address');
    }
    
    @isTest(seeAllData=false)
    private static void testGetIpAddress1(){
        PageReference myVfPage = Page.TrainingBooking;
        Test.setCurrentPage(myVfPage);
        Test.startTest();
        ApexPages.currentPage().getHeaders().put('X-Salesforce-SIP','123');
        TrainingBookingController cont = bg_UnitTestHelper.SetupTrainingBookingController(10);
        String addressString = cont.getIPAddress();
        Test.stopTest();
        System.assertEquals('123', addressString, 'Should be returned SIP IP address');
    }
    
    @isTest(seeAllData=false)
    private static void testGetIpAddress2(){
        PageReference myVfPage = Page.TrainingBooking;
        Test.setCurrentPage(myVfPage);
        Test.startTest();
        ApexPages.currentPage().getHeaders().put('X-Forwarded-For','123');
        TrainingBookingController cont = bg_UnitTestHelper.SetupTrainingBookingController(10);
        String addressString = cont.getIPAddress();
        Test.stopTest();
        System.assertEquals('123', addressString, 'Should be returned For IP address');
    }
    
    @isTest(seeAllData=false)
    private static void testGetIpAddress3(){
        PageReference myVfPage = Page.TrainingBooking;
        Test.setCurrentPage(myVfPage);
        Test.startTest();
        ApexPages.currentPage().getHeaders().put('X-X-X','123');
        TrainingBookingController cont = bg_UnitTestHelper.SetupTrainingBookingController(10);
        String addressString = cont.getIPAddress();
        Test.stopTest();
        System.assertEquals(null, addressString, 'Should be returned null value ');
    }
    
    public class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'Application/json');
            res.setBody('{"country":{"iso_code":"GB","geoname_id":2635167,"names":{"es":"Reino Unido","fr":"Royaume-Uni","ja":"イギリス","pt-BR":"Reino Unido","ru":"Великобритания","zh-CN":"英国","de":"Vereinigtes Königreich","en":"United Kingdom"}}}');
            res.setStatusCode(200);
            return res;
        }
    }
    
}