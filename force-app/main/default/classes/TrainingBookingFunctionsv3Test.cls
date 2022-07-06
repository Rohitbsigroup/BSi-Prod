@isTest
private class TrainingBookingFunctionsv3Test {    
    
    static void setUp()
    {
        final BSIPermissions__c bsiPermissions = new BSIPermissions__c();
        bsiPermissions.CloseWinOpportunities__c = true; // custom setting required for all deployments where SeeAllData=true no longer required
        insert bsiPermissions;
    }
    
    // Manual Conversion 
    @isTest(SeeAllData=false) 
    static void manualConvertSuccess()
    {
        setUp();
        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.GetContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

        // CB to fix
        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        Product2 prd3 = TrainingBookingTestData.createTestCourse('Exam','EMS12345ENUK', null);

        // Set up price book entries
        // Pricebook2 std = bg_UnitTestHelper.GetStandardPricebook();
        Pricebook2 std = new Pricebook2(Id = Test.getStandardPricebookId()); // SeeAllData=true no longer required
        PriceBookEntry pbe3 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd3.id);
        PricebookEntry pbe1 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd1.id);
        PricebookEntry pbe2 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd2.id);

        // todo create a traning translation test method
        Training_Translations__c translation = bg_TrainingUnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        insert translation;

        TrainingBooking__c booking = bg_TrainingUnitTestHelper.GetTrainingBooking(te, pbe1, pbe2, translation);
        booking.Pricebook_Entry__c = pbe1.Id;
        booking.Booking_Route__c = 'Online';
        booking.Price_Per_Delegate__c = 500.00;
        booking.Price_Per_Delegate_Extra_Night__c = 0.00;
        booking.Price_Per_Delegate_Accommodation__c = 100.00;
        booking.CurrencyIsoCode = 'USD';
        booking.Company_Country_Code__c = 'GB';
        booking.Number_of_Delegates__c = 2;
        booking.Delegates_Inc_Accommodation__c = 1;
        booking.Delegates_inc_extra_night__c = 0;
        booking.Delegates_inc_exam__c = 0;
        booking.Manage_Government_Incentive__c = 'Yes';
        // Case 26482
        booking.VAT_Number__c = 'VAT EU';
        booking.VAT_Number2__c = 'VAT NonEU';
        booking.Codice_Fiscale__c = 'Codice Fiscale';
        booking.PO_Number__c = 'Training Test';
        insert booking;

        // Setup a booker delegate
        List<TrainingDelegate__c> delegateList = new List<TrainingDelegate__c>();
        TrainingDelegate__c delegate1 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate1', null, null, 
            'a@a.com', null, true, null);
        delegate1.Is_Booker__c = true;
        update delegate1;
        delegateList.add(delegate1);
        
        // create second delegate
        TrainingDelegate__c delegate2 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate2', null, null, 
            'a2@a.com', null, false, null);
        delegateList.add(delegate2);

        PageReference convertPage = Page.bg_ConvertTrainingBooking;
        Test.setCurrentPageReference(convertPage);
        ApexPages.CurrentPage().getparameters().put('id', booking.id);

        // create standard controller
        ApexPages.StandardController sc = new ApexPages.standardController(booking);

        // Instantiate Convert Controller
        TrainingBookingFunctionsV3 convertController = new TrainingBookingFunctionsV3(sc);
        
        // test page does not have any page messages
        System.assertEquals(0, ApexPages.getMessages().size());
        
        // run convert
        //PC K2 29-10-2018 create new set of government limits
        Test.startTest();
            convertController.convert();
        Test.stopTest();
        
        // check we have 1 message
        System.assertEquals(1, ApexPages.getMessages().size());
        
        // check the page message is success
        System.debug(logginglevel.error, '**1** ' + ApexPages.getMessages());
        system.assertEquals(true,ApexPages.hasMessages(ApexPages.Severity.Confirm));

        // create expected page message
        ApexPages.Message expectedMessage = new ApexPages.Message(ApexPages.Severity.Confirm, System.Label.TrainingBooking_Success);
        // get actual page message
        ApexPages.Message actualMessage = ApexPages.getMessages()[0];

        Boolean messageIsExpected = false;
        // test page messages are the same
        if(expectedMessage.getSummary() == actualMessage.getSummary()
             && expectedMessage.getDetail() == actualMessage.getDetail()
             && expectedMessage.getSeverity() == actualMessage.getSeverity())
        {
             messageIsExpected = true;        
        }
        // assert messages are the same
        system.assertEquals(true,messageIsExpected);

        // Case 26482 - assert all new fields are being set correctly and enrollments created with lookup to original delegate
        Map<Id, Enrollment__c> enrollmentMap = new Map<Id, Enrollment__c>();
        List<Enrollment__c> enrollments = new List<Enrollment__c>([SELECT Manage_Government_Incentive__c, RelatedTrainingDelegate__c FROM Enrollment__c WHERE Training_Event__c = :te.Id]);
        for(Enrollment__c en :enrollments)
        {
            enrollmentMap.put(en.RelatedTrainingDelegate__c, en);
        }
        booking = [SELECT Contact_Phone__c, Contact_Mobile__c, Conversion_Account__c, Conversion_Contact__c, Conversion_Opportunity__c, PO_Number__c, Manage_Government_Incentive__c FROM TrainingBooking__c WHERE Id =:booking.Id LIMIT 1];
        List<Account> accounts = new List<Account>([SELECT VAT_Number__c, VAT_Number_NonEU__c, Codice_Fiscale__c FROM Account WHERE Id =:booking.Conversion_Account__c]);
        List<Contact> contacts = new List<Contact>([SELECT Phone, MobilePhone FROM Contact WHERE Id =: booking.Conversion_Contact__c]);
        List<Opportunity> opportunities = new List<Opportunity>([SELECT PrevCustomer__c, Product_Stream__c, PO_Number__c, DeliveryDateExpectations__c, BusinessDrivers__c, CreateFollowupOpp__c, Sync_in_Progress__c From Opportunity WHERE Id =:booking.Conversion_Opportunity__c]);

        System.debug(enrollments);
        System.debug(accounts);
        System.debug(opportunities);

        for (TrainingDelegate__c td : delegateList) 
        {
            System.assertEquals(td.Id, enrollmentMap.get(td.Id).RelatedTrainingDelegate__c);
            System.assertEquals(booking.Manage_Government_Incentive__c, enrollmentMap.get(td.Id).Manage_Government_Incentive__c);
        }
        for (Account acc : accounts) 
        {
            System.assertEquals('VAT EU', acc.VAT_Number__c);
            System.assertEquals('VAT NonEU', acc.VAT_Number_NonEU__c);
            System.assertEquals('Codice Fiscale', acc.Codice_Fiscale__c);
        }
        for(Contact c : contacts){
            System.assertEquals(c.Phone, booking.Contact_Phone__c);
            System.assertEquals(c.MobilePhone, booking.Contact_Mobile__c);
        }
        for (Opportunity opp : opportunities) 
        {
            System.assertEquals('No', opp.PrevCustomer__c);
            System.assertEquals('Training', opp.BusinessDrivers__c);
            System.assertEquals('No', opp.CreateFollowupOpp__c);
            System.assertEquals(bg_TrainingUtils.TRAINING_PUBLIC, opp.Product_Stream__c);
            System.assertEquals(booking.PO_Number__c, opp.PO_Number__c);
            System.assertEquals(te.Start_date__c, opp.DeliveryDateExpectations__c);
            System.assertEquals(false, opp.Sync_in_Progress__c);
        }

    }
    
    @isTest(SeeAllData=true)
    static void manualConvert_Error_NoBookingRoute()
    {
        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.GetContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 2, product, Date.today()+5,trainer.Id);

        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        Product2 prd3 = TrainingBookingTestData.createTestCourse('Exam','EMS12345ENUK', null);

        // Set up price book entries
        Pricebook2 std = bg_UnitTestHelper.GetStandardPricebook();
        PriceBookEntry pbe3 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd3.id);
        PricebookEntry pbe1 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd1.id);
        PricebookEntry pbe2 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd2.id);

        // todo create a traning translation test method
        Training_Translations__c translation = bg_TrainingUnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        insert translation;

        TrainingBooking__c booking = bg_TrainingUnitTestHelper.GetTrainingBooking(te, pbe1, pbe2, translation);
        booking.Pricebook_Entry__c = pbe3.Id;
        booking.Price_Per_Delegate__c = 50.00;
        booking.CurrencyIsoCode = 'USD';
        booking.Company_Country_Code__c = 'GB';
        booking.Number_of_Delegates__c = 2;
        booking.Delegates_Inc_Accommodation__c = 1;
        booking.Delegates_inc_extra_night__c = 0;
        booking.Delegates_inc_exam__c = 0;
        insert booking;

        // Setup a booker delegate
        TrainingDelegate__c delegate1 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate1', null, null, 
            'a@a.com', null, true, null);
        delegate1.Is_Booker__c = true;
        update delegate1;

        // create second delegate
        TrainingDelegate__c delegate2 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate2', null, null, 
            'a@a.com', null, false, null);

        PageReference convertPage = Page.bg_ConvertTrainingBooking;
        Test.setCurrentPageReference(convertPage);
        ApexPages.CurrentPage().getparameters().put('id', booking.id);

        // create standard controller
        ApexPages.StandardController sc = new ApexPages.standardController(booking);

        // Instantiate Convert Controller
        TrainingBookingFunctionsV3 convertController = new TrainingBookingFunctionsV3(sc);
        
        // test page does not have any page messages
        System.assertEquals(0, ApexPages.getMessages().size());
        
        // run convert
        //PC K2 29-10-2018 create new set of government limits
        Test.startTest();
            convertController.convert();
        Test.stopTest();
        
        // check we have 1 message
        System.assertEquals(1, ApexPages.getMessages().size());
        
        // check the page message is not a success message 
        System.assertEquals(false,ApexPages.hasMessages(ApexPages.Severity.Confirm));
        /*
        // create expected page message
        ApexPages.Message expectedMessage = new ApexPages.Message(ApexPages.Severity.Warning, System.Label.TrainingBooking_BookingRoute_Error);
        // get actual page message
        ApexPages.Message actualMessage = ApexPages.getMessages()[0];

        Boolean messageIsExpected = false;
        // test page messages are the same
        if(expectedMessage.getSummary() == actualMessage.getSummary()
             && expectedMessage.getDetail() == actualMessage.getDetail()
             && expectedMessage.getSeverity() == actualMessage.getSeverity())
        {
             messageIsExpected = true;        
        }
        // assert messages are the same
        system.assertEquals(true,messageIsExpected);
        */
    }
    
    @isTest(SeeAllData=true)
    static void manualConvert_Error_DelegatesNotReadyForConversion()
    {
        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.GetContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 2, product, Date.today()+5,trainer.Id);

        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        Product2 prd3 = TrainingBookingTestData.createTestCourse('Exam','EMS12345ENUK', null);

        // Set up price book entries
        Pricebook2 std = bg_UnitTestHelper.GetStandardPricebook();
        PriceBookEntry pbe3 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd3.id);
        PricebookEntry pbe1 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd1.id);
        PricebookEntry pbe2 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd2.id);

        // todo create a traning translation test method
        Training_Translations__c translation = bg_TrainingUnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        insert translation;

        TrainingBooking__c booking = bg_TrainingUnitTestHelper.GetTrainingBooking(te, pbe1, pbe2, translation);
        booking.Booking_Route__c = 'Online';
        booking.Pricebook_Entry__c = pbe3.Id;
        booking.Price_Per_Delegate__c = 50.00;
        booking.CurrencyIsoCode = 'USD';
        booking.Company_Country_Code__c = 'GB';
        booking.Number_of_Delegates__c = 2;
        booking.Delegates_Inc_Accommodation__c = 1;
        booking.Delegates_inc_extra_night__c = 0;
        booking.Delegates_inc_exam__c = 0;
        insert booking;

        // Setup a booker delegate
        TrainingDelegate__c delegate1 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate1', null, null, 
            null, null, true, null);
        delegate1.Is_Booker__c = true;
        update delegate1;

        // create second delegate
        TrainingDelegate__c delegate2 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate2', null, null, 
            null, null, false, null);

        PageReference convertPage = Page.bg_ConvertTrainingBooking;
        Test.setCurrentPageReference(convertPage);
        ApexPages.CurrentPage().getparameters().put('id', booking.id);

        // create standard controller
        ApexPages.StandardController sc = new ApexPages.standardController(booking);

        // Instantiate Convert Controller
        TrainingBookingFunctionsV3 convertController = new TrainingBookingFunctionsV3(sc);
        
        // test page does not have any page messages
        System.assertEquals(0, ApexPages.getMessages().size());
        
        // run convert
        //PC K2 29-10-2018 create new set of government limits
        Test.startTest();
            convertController.convert();
        Test.stopTest();
        
        // check we have 1 message
        System.assertEquals(1, ApexPages.getMessages().size());
        
        // check the page message is not a success message
        System.assertEquals(false,ApexPages.hasMessages(ApexPages.Severity.Confirm));
        /*
        // create expected page message
        ApexPages.Message expectedMessage = new ApexPages.Message(ApexPages.Severity.Warning, System.Label.Delegates_Not_Ready_To_Convert);
        // get actual page message
        ApexPages.Message actualMessage = ApexPages.getMessages()[0];
        
        Boolean messageIsExpected = false;
        // test page messages are the same
        if(expectedMessage.getSummary() == actualMessage.getSummary()
             && expectedMessage.getDetail() == actualMessage.getDetail()
             && expectedMessage.getSeverity() == actualMessage.getSeverity())
        {
             messageIsExpected = true;        
        }
        // assert messages are the same
        system.assertEquals(true,messageIsExpected);
        */
    }
    @isTest(SeeAllData=true)
    static void manualConvert_Error_NotEnoughSeats()
    {
        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.GetContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 2, product, Date.today()+5,trainer.Id);

        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        Product2 prd3 = TrainingBookingTestData.createTestCourse('Exam','EMS12345ENUK', null);

        // Set up price book entries 
        Pricebook2 std = bg_UnitTestHelper.GetStandardPricebook();
        PriceBookEntry pbe3 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd3.id);
        PricebookEntry pbe1 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd1.id);
        PricebookEntry pbe2 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd2.id);

        // todo create a traning translation test method
        Training_Translations__c translation = bg_TrainingUnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        insert translation;

        //Account conversionAccTest = bg_TrainingUnitTestHelper.createAccount('Conversion Account Test','GB');
        //insert conversionAccTest;

        TrainingBooking__c booking = bg_TrainingUnitTestHelper.GetTrainingBooking(te, pbe1, pbe2, translation);
        booking.Conversion_Account__c = bg_TrainingUnitTestHelper.createAccount('Conversion Account Test','GB').Id;
        booking.Pricebook_Entry__c = pbe3.Id;
        booking.Booking_Route__c = 'Internal sales';
        booking.Price_Per_Delegate__c = 50.00;
        booking.CurrencyIsoCode = 'USD';
        booking.Company_Country_Code__c = 'GB';
        booking.Number_of_Delegates__c = 3;
        booking.Delegates_Inc_Accommodation__c = 1;
        booking.Delegates_inc_extra_night__c = 0;
        booking.Delegates_inc_exam__c = 0;

        insert booking;

        // Setup a booker delegate
        TrainingDelegate__c delegate1 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate1', null, null, 
            'a@a.com', null, true, null);
        delegate1.Is_Booker__c = true;
        update delegate1;

        // create second delegate
        TrainingDelegate__c delegate2 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate2', null, null, 
            'a2@a.com', null, false, null);

        // create third delegate
        TrainingDelegate__c delegate3 = bg_TrainingUnitTestHelper.createTrainingDelegate(booking, 'Training', 'Delegate3', null, null, 
            'a3@a.com', null, false, null);

        PageReference convertPage = Page.bg_ConvertTrainingBooking;
        Test.setCurrentPageReference(convertPage);
        ApexPages.CurrentPage().getparameters().put('id', booking.id);

        // create standard controller
        ApexPages.StandardController sc = new ApexPages.standardController(booking);

        // Instantiate Convert Controller
        TrainingBookingFunctionsV3 convertController = new TrainingBookingFunctionsV3(sc);
        
        // test page does not have any page messages
        System.assertEquals(0, ApexPages.getMessages().size());
        
        // run convert
        //PC K2 29-10-2018 create new set of government limits
        Test.startTest();
            convertController.convert();
        Test.stopTest();
        
        // check we have 1 message
        System.debug(logginglevel.error, '**bg** error--- ' + ApexPages.getMessages());
        System.assertEquals(1, ApexPages.getMessages().size());
        
        // check the page message is not a success message 
        //system.assertEquals(false,ApexPages.hasMessages(ApexPages.Severity.Confirm));
        /*
        // create expected page message
        ApexPages.Message expectedMessage = new ApexPages.Message(ApexPages.Severity.Warning, System.Label.TrainingBooking_Conversion_Error + System.Label.TrainingEvent_Not_Enough_Seats);
        System.debug(logginglevel.error, '**bg** expected ' + expectedMessage);
        // get actual page message
        ApexPages.Message actualMessage = ApexPages.getMessages()[0];

        Boolean messageIsExpected = false;
        // test page messages are the same
        if(expectedMessage.getSummary() == actualMessage.getSummary()
             && expectedMessage.getDetail() == actualMessage.getDetail()
             && expectedMessage.getSeverity() == actualMessage.getSeverity())
        {
             messageIsExpected = true;        
        }
        // assert messages are the same
        system.assertEquals(true,messageIsExpected);
       */
    }

    // Manual Conversion 
    @isTest(SeeAllData=false) 
    static void manualConvertSuccess_WithoutCreatingConversionAccount()
    {
        setUp();
        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.GetContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);

        // CB to fix
        Product2 prd1 = TrainingBookingTestData.createTestCourse('Normal', 'EMS12345ENUK', null);
        Product2 prd2 = TrainingBookingTestData.createTestCourse('Residential', 'EMS12345ENUK', prd1);
        Product2 prd3 = TrainingBookingTestData.createTestCourse('Exam','EMS12345ENUK', null);

        // Set up price book entries
        // Pricebook2 std = bg_UnitTestHelper.GetStandardPricebook();
        Pricebook2 std = new Pricebook2(Id = Test.getStandardPricebookId()); // SeeAllData=true no longer required
        PriceBookEntry pbe3 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd3.id);
        PricebookEntry pbe1 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd1.id);
        PricebookEntry pbe2 = bg_UnitTestHelper.GetPricebookEntry(std.id, prd2.id);

        // todo create a traning translation test method
        Training_Translations__c translation = bg_TrainingUnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        insert translation;

        // create Account, Contact, Opportunity and Quote
        Account testAccount = bg_UnitTestHelper.CreateAccount();
        insert testAccount;
        Contact testContact = bg_UnitTestHelper.CreateContact('Test Contact', testAccount);
        insert testContact;
        Opportunity testOpp = bg_UnitTestHelper.CreateOpportunity(testAccount);
        insert testOpp;
        // Quote__c testQuote = bg_UnitTestHelper.CreateQuote(testOpp, testContact);
        Quote__c testQuote = CreateQuote(testOpp, testContact); // SeeAllData=true no longer required
        insert testQuote;

        TrainingBooking__c booking = bg_TrainingUnitTestHelper.GetTrainingBooking(te, pbe1, pbe2, translation);
        booking.Pricebook_Entry__c = pbe1.Id;
        booking.Booking_Route__c = 'Online';
        booking.Price_Per_Delegate__c = 500.00;
        booking.Price_Per_Delegate_Extra_Night__c = 0.00;
        booking.Price_Per_Delegate_Accommodation__c = 100.00;
        booking.CurrencyIsoCode = 'USD';
        booking.Company_Country_Code__c = 'GB';
        booking.Number_of_Delegates__c = 2;
        booking.Delegates_Inc_Accommodation__c = 2;
        booking.Delegates_inc_extra_night__c = 0;
        booking.Delegates_inc_exam__c = 0;
        // Case 26482
        booking.VAT_Number__c = 'VAT EU';
        booking.VAT_Number2__c = 'VAT NonEU';
        booking.Codice_Fiscale__c = 'Codice Fiscale';
        booking.PO_Number__c = 'Training Test';
        booking.Quote__c = testQuote.Id;
        booking.Conversion_Account__c = testAccount.Id;
        booking.Conversion_Contact__c = testContact.Id;
        //booking.Conversion_Opportunity__c = testOpp.Id;
        insert booking;

        // Setup a booker delegate
        List<TrainingDelegate__c> delegateList = new List<TrainingDelegate__c>([SELECT Id FROM TrainingDelegate__c WHERE Training_Booking__c = :booking.Id]);
        for (Integer i=0; i < delegateList.size(); i++)
        {
            delegateList[i].First_Name__c = 'Test'+i;
            delegateList[i].Last_Name__c = 'Test'+i;
            delegateList[i].Email_Address__c = 'Test'+i+'@test.com';
            delegateList[i].Accommodation_Required__c = true;
        }
        update delegateList;
        
        PageReference convertPage = Page.bg_ConvertTrainingBooking;
        Test.setCurrentPageReference(convertPage);
        ApexPages.CurrentPage().getparameters().put('id', booking.id);

        // create standard controller
        ApexPages.StandardController sc = new ApexPages.standardController(booking);

        // Instantiate Convert Controller
        TrainingBookingFunctionsV3 convertController = new TrainingBookingFunctionsV3(sc);
        
        // test page does not have any page messages
        System.assertEquals(0, ApexPages.getMessages().size());
        
        // run convert
        //PC K2 29-10-2018 create new set of government limits
        Test.startTest();
            convertController.convert();
        Test.stopTest();
        
        // check we have 1 message
        System.debug(logginglevel.error, '**1** ' + ApexPages.getMessages());
        System.assertEquals(1, ApexPages.getMessages().size());
        
        // check the page message is success
        System.debug(logginglevel.error, '**1** ' + ApexPages.getMessages());
        system.assertEquals(true,ApexPages.hasMessages(ApexPages.Severity.Confirm));

        // create expected page message
        ApexPages.Message expectedMessage = new ApexPages.Message(ApexPages.Severity.Confirm, System.Label.TrainingBooking_Success);
        // get actual page message
        ApexPages.Message actualMessage = ApexPages.getMessages()[0];

        Boolean messageIsExpected = false;
        // test page messages are the same
        if(expectedMessage.getSummary() == actualMessage.getSummary()
             && expectedMessage.getDetail() == actualMessage.getDetail()
             && expectedMessage.getSeverity() == actualMessage.getSeverity())
        {
             messageIsExpected = true;        
        }
        // assert messages are the same
        system.assertEquals(true,messageIsExpected);

        // Case 26482 - assert all new fields are being set correctly and enrollments created with lookup to original delegate
        Map<Id, Enrollment__c> enrollmentMap = new Map<Id, Enrollment__c>();
        List<Enrollment__c> enrollments = new List<Enrollment__c>([SELECT RelatedTrainingDelegate__c FROM Enrollment__c WHERE Training_Event__c = :te.Id]);
        for(Enrollment__c en :enrollments)
        {
            enrollmentMap.put(en.RelatedTrainingDelegate__c, en);
        }
        booking = [SELECT Conversion_Account__r.Id, Conversion_Opportunity__r.Id, PO_Number__c, Quote__c FROM TrainingBooking__c WHERE id =:booking.Id LIMIT: 1];
        List<Account> accounts = new List<Account>([SELECT VAT_Number__c, VAT_Number_NonEU__c, Codice_Fiscale__c FROM Account WHERE id =:booking.Conversion_Account__r.Id]);
        List<Opportunity> opportunities = new List<Opportunity>([SELECT PrevCustomer__c, Product_Stream__c, PO_Number__c, DeliveryDateExpectations__c, BusinessDrivers__c, CreateFollowupOpp__c From Opportunity WHERE id =:booking.Conversion_Opportunity__r.Id]);

        System.debug(enrollments);
        System.debug(accounts);
        System.debug(opportunities);

        System.assertEquals(testQuote.id, booking.Quote__c);
        for (TrainingDelegate__c td : delegateList) 
        {
            System.assertEquals(td.id, enrollmentMap.get(td.id).RelatedTrainingDelegate__c);
        }
        for (Account acc : accounts) 
        {
            System.assertEquals('VAT EU', acc.VAT_Number__c);
            System.assertEquals('VAT NonEU', acc.VAT_Number_NonEU__c);
            System.assertEquals('Codice Fiscale', acc.Codice_Fiscale__c);
        }
        for (Opportunity opp : opportunities) 
        {
            System.assertEquals('Yes', opp.PrevCustomer__c);
            System.assertEquals('Training', opp.BusinessDrivers__c);
            System.assertEquals('No', opp.CreateFollowupOpp__c);
            System.assertEquals('Yes', opp.PrevCustomer__c);
            System.assertEquals(bg_TrainingUtils.TRAINING_PUBLIC, opp.Product_Stream__c);
            System.assertEquals(booking.PO_Number__c, opp.PO_Number__c);
            System.assertEquals(te.Start_date__c, opp.DeliveryDateExpectations__c);
        }

    }
    
    private static Quote__c CreateQuote(Opportunity opp, Contact con) {
        /*
            Return Quote
        */
        Quote__c quote = new Quote__c();
        if(opp != null) 
        { 
            quote.Opportunity_Name__c = opp.Id; 
            if(opp.CurrencyIsoCode != null)
            {   
                quote.CurrencyIsoCode = opp.CurrencyIsoCode;
            }else { 
                opp.CurrencyIsoCode = 'GBP';
                quote.CurrencyIsoCode = 'GBP';
            }
        }
        if(con != null) { 
            quote.Contact__c = con.Id;
            quote.Booking__c = con.Id;
            quote.CreditCheck__c = con.Id;
            quote.Invoice_Contact__c = con.Id; 
        }
        quote.PriceBook2Id__c = Test.getStandardPricebookId();
        return quote;
    }    
}