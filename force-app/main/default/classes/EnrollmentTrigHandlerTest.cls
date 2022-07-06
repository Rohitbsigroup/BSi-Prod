/**
* Author:       
* Date:         
* Description:  test class for EnrollmentTrigHandler
*
* ******************* Change Log *******************
*  PC K2           08-08-18    added methods
*  JS              17-02-20    updated Exam email to include all E-learning
*  PC K2           25-06-20    added manageMimeoKeyAssignmentTest, revokeMimeoKeyTest
*  JS              06/11/20    no changes made
**/

@isTest
private class EnrollmentTrigHandlerTest{

    @isTest static void mymethod() {
        String ENRId ='';
        
        List<Enrollment__c> lerol= New List<Enrollment__c>();
        Test.StartTest();
        lerol=[Select id,Delivery_Method__c, Training_Event__r.Event_Country__c,
                                   Training_Translations__r.Language__c,Booking_status__c,LitmosAccountCreated__c,Delegate_name__r.Email,
                                   Delegate_name__r.FirstName,Delegate_name__r.LastName,Training_Event__r.Taxonomy__c, Online_Training_Assigned__c 
             from Enrollment__c where  Online_Training_Assigned__c = true and Booking_status__c like '%Booked%'  and (Delivery_Method__c = 'E-Learning') limit 1 ];

        EnrollmentTrigHandler obj= new EnrollmentTrigHandler(True,lerol.size());
        
        EnrollmentTrigHandler.testrunning=true;
        
        Map<ID,Enrollment__c> EMap= New Map<ID,Enrollment__c>();
        
        for(Enrollment__c E:lerol )
        {
           if(!EMap.containsKey(E.Id)){
                EMap.put(E.ID,New Enrollment__c());
                ENRId = E.Id;
                //Commented out due to reference issues of attributes beeing removed in the EnrollmentTrigHandler.cls 
                /*EnrollmentTrigHandler.email = E.Delegate_name__r.Email;
               EnrollmentTrigHandler.FirstName = E.Delegate_name__r.FirstName;
               EnrollmentTrigHandler.LastName = E.Delegate_name__r.LastName;
               EnrollmentTrigHandler.Language = E.Training_Translations__r.Language__c;
               EnrollmentTrigHandler.deliveryMethod = E.Delivery_Method__c;
               EnrollmentTrigHandler.taxonomyCode = E.Training_Event__r.Taxonomy__c;
               EnrollmentTrigHandler.BookStatus = E.Booking_status__c;*/
                //EMap.get(E.ID).Add(E);
            }
        }

        try{
            obj.OnAfterInsert(lerol,EMap); 
            obj.OnBeforeInsert(lerol); 
        }
        catch(Exception e) {}

        try{
            obj.OnAfterUpdate(lerol, lerol, EMap, EMap);
        }
        catch(exception e) {}

        //obj.OnBeforeUpdate(lerol,lerol,EMap);
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today(), true, Label.Enrollment_Booking_Status_Booked);
        insert new LitmosSettings__c(SetupOwnerId = UserInfo.getOrganizationId(), API_Key__c = 'key', API__c = 'api', Source__c = 'source');

        EnrollmentTrigHandler.LitmosUser(null, 'rao@gmail.com', 'rao@gmail.com', 'Rao', 'Rao', 'OLE001', 'com', 'UK', 'english', e.Id, null, null);
        EnrollmentTrigHandler.LitmosUser('123', 'rao@gmail.com', 'rao@gmail.com', 'Rao', 'Rao', 'OLE001', 'com', 'UK', 'english', e.Id, null, null);
        EnrollmentTrigHandler.updateLitmosResponse(ENRId);
        EnrollmentTrigHandler.RemoveCourse('rao@gmail.com','OLE001');
        Test.stopTest();
    }

    @isTest static void onBeforeInsertTest_cancelEnrollment(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Cancelled_Delegate);
        Enrollment__c e = [SELECT Sales_Price__c FROM Enrollment__c];

        System.assertEquals(0, e.Sales_Price__c);
    }

    @isTest static void onBeforeInsertTest_InHouseBookingContact(){
        Account a = new Account(Name = 'test', BillingCountry = 'UK');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
        insert c;

        Opportunity o = new Opportunity(Name = 'test Opp', StageName = 'Sales Engaged', CloseDate = Date.today(), AccountId = a.Id, Sync_in_Progress__c = true, BusinessDrivers__c = 'New Customer');
        insert o;

        Training_Event__c event = TestDataUtility.insertTrainingEvent(Date.today() + 5, true);
        event.Event_Revenue__c = 1000;
        update event;

        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        product.Course_Delivery__c = Label.In_House;
        update product;

        Training_Translations__c translation = TestDataUtility.insertTrainingTranslation();

        Enrollment__c testEnrollment = new Enrollment__c();
        testEnrollment.Training_Event__c = event.Id;
        testEnrollment.Training_Translations__c = translation.Id;
        testEnrollment.Booking_status__c = Label.Enrollment_Booking_Status_Booked;
        testEnrollment.Delegate_Name__c = c.Id;
        testEnrollment.Bookers_Email__c = 'test-booker@test.com';
        testEnrollment.Inhouse_Booking_Contact__c = true;
        insert testEnrollment;

        Enrollment__c e = [SELECT Sales_Price__c FROM Enrollment__c];
        System.assertEquals(event.Event_Revenue__c, e.Sales_Price__c);
    }

    @isTest static void onAfterInsertTest_confirmationOfPlace(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Email_Confirmation_Sent__c FROM Enrollment__c];

        System.assert(e.Email_Confirmation_Sent__c);
    }

    @isTest static void onAfterInsertTest_resitConfirmation(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked_Resit);
        Enrollment__c e = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c];

        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
        System.assert(e.Email_Confirmation_Sent__c);
    }

    @isTest static void onAfterInsertTest_confirmationIH(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Delegate_Name__c, Training_Translations__c, Training_Event__r.Course__c FROM Enrollment__c];

        update new Product2(Id = e.Training_Event__r.Course__c, Course_Delivery__c = Label.In_House);

        Enrollment__c newEnrollment = new Enrollment__c(Training_Event__c = e.Training_Event__c, Training_Translations__c = e.Training_Translations__c, Booking_status__c = Label.Enrollment_Booking_Status_Booked, Delegate_Name__c = e.Delegate_Name__c);
        insert newEnrollment;

        newEnrollment = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c WHERE Id = :newEnrollment.Id];
        System.assertNotEquals(null, newEnrollment.Course_Confirmed_Email_Sent__c);
        System.assert(newEnrollment.Email_Confirmation_Sent__c);
    }

    @isTest static void onAfterInsertTest_confirmationBespokeIH(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Delegate_Name__c, Training_Translations__c, Training_Event__r.Course__c FROM Enrollment__c];

        update new Product2(Id = e.Training_Event__r.Course__c, Course_Delivery__c = Label.In_House, Bespoke_Event__c = true);

        Enrollment__c newEnrollment = new Enrollment__c(Training_Event__c = e.Training_Event__c, Training_Translations__c = e.Training_Translations__c, Booking_status__c = Label.Enrollment_Booking_Status_Booked, Delegate_Name__c = e.Delegate_Name__c);
        insert newEnrollment;

        newEnrollment = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c WHERE Id = :newEnrollment.Id];
        System.assertNotEquals(null, newEnrollment.Course_Confirmed_Email_Sent__c);
        System.assert(newEnrollment.Email_Confirmation_Sent__c);
    }

    @isTest static void onAfterInsertTest_confirmationACC(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c];

        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
        System.assert(e.Email_Confirmation_Sent__c);
    }

    /*
    * !important 
    * after insert fires update triggers also, so recursion protection must be disabled in order to test update trigger
    */

    @isTest static void onBeforeUpdateTest_PDFcertificate(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() - 5, true, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Id FROM Enrollment__c];

        //trigger PDF Certificate email
        EnrollmentTrigHandler.isBeforeUpdateFirstRun = true;
        e.Invoice_status__c = Label.Completed;
        e.Email_PDF_Certificate__c = true;
        update e;

        e = [SELECT Certificate_status__c, Certificate_Issued_By__c FROM Enrollment__c];
        System.assertEquals(Label.Sent, e.Certificate_status__c);
        System.assertEquals(UserInfo.getFirstName() + '' + UserInfo.getLastName(), e.Certificate_Issued_By__c);
    }

    @isTest static void onBeforeUpdateTest_cancelEnrollment(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        e.Booking_status__c = Label.Cancelled_Delegate;
        EnrollmentTrigHandler.isBeforeUpdateFirstRun = true;
        update e;

        e = [SELECT Sales_Price__c FROM Enrollment__c];
        System.assertEquals(0, e.Sales_Price__c);
    }

    /*
    @isTest static void onAfterUpdateTest_confirmationOfPlace(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Id FROM Enrollment__c];

        //trigger Confirmation of Place
        Test.startTest();
            System.debug('############# start test');
            EnrollmentTrigHandler.bypassTrigger = false;
            EnrollmentTrigHandler.isAfterUpdateFirstRun = true;
            e.Email_Confirmation_Sent__c = false;
            update e;
        Test.stopTest();

        e = [SELECT Email_Confirmation_Sent__c FROM Enrollment__c];
        System.assert(e.Email_Confirmation_Sent__c);
    }
    */
    @isTest static void onAfterUpdateTest_confirmationOfPlace(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Id FROM Enrollment__c];

        //trigger Confirmation of Place
        Test.startTest();
            EnrollmentTrigHandler.isAfterUpdateFirstRun = true;
            e.Email_Confirmation_Sent__c = false;
            update e;
        Test.stopTest();

        e = [SELECT Email_Confirmation_Sent__c FROM Enrollment__c];
        System.assert(e.Email_Confirmation_Sent__c);
    }

    @isTest static void onBeforeUpdateTest_InHouseBookingContact(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);

        Training_Event__c event = [SELECT Id FROM Training_Event__c LIMIT 1];
        event.Event_Revenue__c = 1000;
        update event;

        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        product.Course_Delivery__c = Label.In_House;
        update product;

        EnrollmentTrigHandler.isBeforeUpdateFirstRun = true;
        e.Inhouse_Booking_Contact__c = true;
        update e;

        e = [SELECT Sales_Price__c FROM Enrollment__c];
        System.assertEquals(event.Event_Revenue__c, e.Sales_Price__c);
    }

    /*
    @isTest static void onBeforeUpdateTest_resitConfirmation(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked_Resit);
        Enrollment__c e = [SELECT Id FROM Enrollment__c];

        //trigger Resit Confirmation
        EnrollmentTrigHandler.isBeforeUpdateFirstRun = true;
        e.Email_Confirmation_Sent__c = false;
        e.Booking_status__c = Label.Enrollment_Booking_Status_Booked_Resit;
        update e;

        e = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
        System.assert(e.Email_Confirmation_Sent__c);
    }
    */
    @isTest static void onAfterUpdateTest_resitConfirmation(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked_Resit);
        Enrollment__c e = [SELECT Id FROM Enrollment__c];

        //trigger Resit Confirmation
        Test.startTest();
            EnrollmentTrigHandler.isAfterUpdateFirstRun = true;
            e.Email_Confirmation_Sent__c = false;
            e.Booking_status__c = Label.Enrollment_Booking_Status_Booked_Resit;
            update e;
        Test.stopTest();

        e = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
        System.assert(e.Email_Confirmation_Sent__c);
    }

    /*
    @isTest static void onBeforeUpdateTest_confirmationIH(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Training_Event__r.Course__c FROM Enrollment__c];

        update new Product2(Id = e.Training_Event__r.Course__c, Course_Delivery__c = Label.In_House);

        //trigger Confirmation In-House
        EnrollmentTrigHandler.isBeforeUpdateFirstRun = true;
        e.Email_Confirmation_Sent__c = false;
        update e;

        e = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
        System.assert(e.Email_Confirmation_Sent__c);
    }
    */
    @isTest static void onAfterUpdateTest_confirmationIH(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Training_Event__r.Course__c FROM Enrollment__c];

        update new Product2(Id = e.Training_Event__r.Course__c, Course_Delivery__c = Label.In_House);

        //trigger Confirmation In-House
        Test.startTest();
            EnrollmentTrigHandler.isAfterUpdateFirstRun = true;
            e.Email_Confirmation_Sent__c = false;
            update e;
        Test.stopTest();

        e = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
        System.assert(e.Email_Confirmation_Sent__c);
    }

    /*
    @isTest static void onBeforeUpdateTest_confirmationBespokeIH(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Training_Event__r.Course__c FROM Enrollment__c];

        update new Product2(Id = e.Training_Event__r.Course__c, Course_Delivery__c = Label.In_House, Bespoke_Event__c = true);

        //trigger Confirmation Bespoke In-House
        EnrollmentTrigHandler.isBeforeUpdateFirstRun = true;
        e.Email_Confirmation_Sent__c = false;
        update e;

        e = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
        System.assert(e.Email_Confirmation_Sent__c);
    }
    */
    @isTest static void onAfterUpdateTest_confirmationBespokeIH(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Training_Event__r.Course__c FROM Enrollment__c];

        update new Product2(Id = e.Training_Event__r.Course__c, Course_Delivery__c = Label.In_House, Bespoke_Event__c = true);

        //trigger Confirmation Bespoke In-House
        Test.startTest();
            EnrollmentTrigHandler.isAfterUpdateFirstRun = true;
            e.Email_Confirmation_Sent__c = false;
            update e;
        Test.stopTest();

        e = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
        System.assert(e.Email_Confirmation_Sent__c);
    }

    /*
    @isTest static void onBeforeUpdateTest_confirmationWCC(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Training_Event__c FROM Enrollment__c];

        //trigger Delivery Confirmation WCC via Confirm Event functionality on Training Event
        EnrollmentTrigHandler.isBeforeUpdateFirstRun = true;
        update new Training_Event__c(Id = e.Training_Event__c, Event_Confirmed__c = true);

        e = [SELECT Course_Confirmed_Email_Sent__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
    }
    */
    @isTest static void onAfterUpdateTest_confirmationWCC(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Training_Event__c FROM Enrollment__c];

        //trigger Delivery Confirmation WCC via Confirm Event functionality on Training Event
        Test.startTest();
            EnrollmentTrigHandler.isAfterUpdateFirstRun = true;
            update new Training_Event__c(Id = e.Training_Event__c, Event_Confirmed__c = true);
        Test.stopTest();

        e = [SELECT Course_Confirmed_Email_Sent__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
    }

    /*
    @isTest static void onBeforeUpdateTest_confirmationACC(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Training_Event__c FROM Enrollment__c];

        update new Training_Event__c(Id = e.Training_Event__c, Event_Confirmed__c = true);

        //trigger Delivery Confirmation ACC
        EnrollmentTrigHandler.isBeforeUpdateFirstRun = true;
        e.Course_Confirmed_Email_Sent__c = null;
        e.Email_Confirmation_Sent__c = false;
        e.Email_Changes__c = true;
        update e;

        e = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
        System.assert(e.Email_Confirmation_Sent__c);
    }
    */
    @isTest static void onAfterUpdateTest_confirmationACC(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Training_Event__c FROM Enrollment__c];

        update new Training_Event__c(Id = e.Training_Event__c, Event_Confirmed__c = true);

        //trigger Delivery Confirmation ACC
        Test.startTest();
            EnrollmentTrigHandler.isAfterUpdateFirstRun = true;
            e.Course_Confirmed_Email_Sent__c = null;
            e.Email_Confirmation_Sent__c = false;
            e.Email_Changes__c = true;
            update e;
        Test.stopTest();

        e = [SELECT Email_Confirmation_Sent__c, Course_Confirmed_Email_Sent__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Course_Confirmed_Email_Sent__c);
        System.assert(e.Email_Confirmation_Sent__c);
    }
    
    /*
    @isTest static void onBeforeUpdateTest_courseUpdate(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Training_Event__c FROM Enrollment__c];

        update new Training_Event__c(Id = e.Training_Event__c, Event_Confirmed__c = true, Change_of_Date__c = true);

        //trigger Course Update
        EnrollmentTrigHandler.isBeforeUpdateFirstRun = true;
        e.Course_Confirmed_Email_Sent__c = Datetime.now();
        e.Email_Confirmation_Sent__c = true;
        e.Email_Changes__c = true;
        update e;

        e = [SELECT Changes_Emailed__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Changes_Emailed__c);
    }
    */
    @isTest static void onAfterUpdateTest_courseUpdate(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, false, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Training_Event__c FROM Enrollment__c];

        update new Training_Event__c(Id = e.Training_Event__c, Event_Confirmed__c = true, Change_of_Date__c = true);

        //trigger Course Update
        Test.startTest();
            EnrollmentTrigHandler.isAfterUpdateFirstRun = true;
            e.Course_Confirmed_Email_Sent__c = Datetime.now();
            e.Email_Confirmation_Sent__c = true;
            e.Email_Changes__c = true;
            update e;
        Test.stopTest();

        e = [SELECT Changes_Emailed__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Changes_Emailed__c);
    }
    
    /*
    @isTest static void onBeforeUpdateTest_exam(){
        Account a = new Account(Name = 'test', BillingCountry = 'UK');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
        insert c;

        Opportunity o = new Opportunity(Name = 'test Opp', StageName = 'Sales Engaged', CloseDate = Date.today(), AccountId = a.Id, Sync_in_Progress__c = true, BusinessDrivers__c = 'New Customer');
        insert o;

        Training_Event__c event = TestDataUtility.insertTrainingEvent(Date.today() + 5, true);

        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        product.ProductCode = 'SGEX0022';
        update product;

        Training_Translations__c translation = TestDataUtility.insertTrainingTranslation();

        Enrollment__c e = new Enrollment__c();
        e.Training_Event__c = event.Id;
        e.Training_Translations__c = translation.Id;
        e.Booking_status__c = Label.Enrollment_Booking_Status_Booked;
        e.Delegate_Name__c = c.Id;
        e.Bookers_Email__c = 'test-booker@test.com';
        e.RecordTypeId = EnrollmentUtils.recordType_ELearning;
        insert e;

        //trigger Exam/E-Learning
        EnrollmentTrigHandler.isBeforeUpdateFirstRun = true;
        e.Online_Training_Assigned__c = true;
        e.LitmosAccountCreated__c = true; //JS added in 20200217
        e.Litmos_Login_Key__c = 'https://bsisandboxdev.litmos.com/login.aspx?loginkey=test';
        e.Litmos_Details_Emailed__c = null;
        update e;
        
        e = [SELECT Litmos_Details_Emailed__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Litmos_Details_Emailed__c);
    }
    */
    @isTest static void onAfterUpdateTest_exam(){
        Account a = new Account(Name = 'test', BillingCountry = 'UK');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
        insert c;

        Opportunity o = new Opportunity(Name = 'test Opp', StageName = 'Sales Engaged', CloseDate = Date.today(), AccountId = a.Id, Sync_in_Progress__c = true, BusinessDrivers__c = 'New Customer');
        insert o;

        Training_Event__c event = TestDataUtility.insertTrainingEvent(Date.today() + 5, true);

        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        product.ProductCode = 'SGEX0022';
        update product;

        Training_Translations__c translation = TestDataUtility.insertTrainingTranslation();

        Enrollment__c e = new Enrollment__c();
        e.Training_Event__c = event.Id;
        e.Training_Translations__c = translation.Id;
        e.Booking_status__c = Label.Enrollment_Booking_Status_Booked;
        e.Delegate_Name__c = c.Id;
        e.Bookers_Email__c = 'test-booker@test.com';
        e.RecordTypeId = EnrollmentUtils.recordType_ELearning;
        insert e;

        //trigger Exam/E-Learning
        Test.startTest();
            EnrollmentTrigHandler.isAfterUpdateFirstRun = true;
            e.Online_Training_Assigned__c = true;
            e.LitmosAccountCreated__c = true; //JS added in 20200217
            e.Litmos_Login_Key__c = 'https://bsisandboxdev.litmos.com/login.aspx?loginkey=test';
            e.Litmos_Details_Emailed__c = null;
            update e;
        Test.stopTest();
        
        e = [SELECT Litmos_Details_Emailed__c FROM Enrollment__c];
        System.assertNotEquals(null, e.Litmos_Details_Emailed__c);
    }
    

/**
     * Method tested: onAfterInsert() and getEnrollmentContactsInsert()
     * Test Scenario: Insert an enrollment with the booking status as booked.
     * Expected Result: successful insertion of user and linked to the enrollment.
     */
    @isTest static void onAfterInsertCreateUser(){
        // test data
        generateOrgData();

        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTranslation = [SELECT Id FROM Training_Translations__c LIMIT 1];
        
        t.End_Date2__c = Date.today().addDays(10);
        update t;
        
        Test.startTest();
        Enrollment__c e = new Enrollment__c(Available_In_Portal_Override__c = 'Show', Portal_Access__c = null, Training_Event__c = t.Id, Delegate_name__c = c.Id, Booking_status__c = 'Booked', Training_Translations__c = trainingTranslation.Id);    
        insert e;
        Test.stopTest();

        e = [SELECT Id, Booking_status__c, Portal_Access__c, Portal_Set_Password_Link__c, Could_not_create_User__c FROM Enrollment__c WHERE Id =:e.Id];
        System.assertNotEquals(null, [SELECT Id, Email FROM User WHERE Email = 'test@test.com']);
        System.assertNotEquals(null, e.Portal_Access__c);
        System.assertNotEquals(null, e.Portal_Set_Password_Link__c);
        //4. enrollment's Could_not_create_User__c = false
        System.assertEquals(false, e.Could_not_create_User__c);
        //5. enrollment's Portal_Access__c = 'New User'
        System.assertEquals('New User', e.Portal_Access__c);
        //6. enrollment's booking status = booked
        System.assertEquals('Booked', e.Booking_status__c);
    }

    /**
     * Method tested: onAfterUpdate() and getEnrollmentContactsUpdate()
     * Test Scenario: update the booking status as booked of an existing enrollment.
     * Expected Result: successful insertion of user and linked to the enrollment.
     */
    @isTest static void onAfterUpdateBookingStatusCreateUser(){

        //generate org data
        generateOrgData();

        Contact c = [SELECT Id,Email FROM Contact LIMIT 1];

        //Assert user created succesfully
        List<User> u = [Select Id FROM User WHERE Username = :c.Email];
        Integer userCountBefore = u.size();


        //create enrollment
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTranslation = [SELECT Id FROM Training_Translations__c LIMIT 1];

        t.End_Date2__c = Date.today().addDays(10);
        update t;

        Enrollment__c e = new Enrollment__c(Available_In_Portal_Override__c = 'Show', Portal_Access__c = null, Training_Event__c = t.Id, Delegate_name__C = c.Id, Booking_status__c = 'Application', Training_Translations__c = trainingTranslation.Id);    
        insert e;

        e = [SELECT Id, Delegate_name__r.Email, Portal_Login_Link__c, Portal_Set_Password_Link__c, Could_not_create_User__c, Booking_status__c, Portal_Access__c, Training_Event__c FROM Enrollment__c WHERE Delegate_name__r.Email = 'test@test.com' LIMIT 1];
        
        Test.startTest();
        e.Booking_status__c = 'Booked';
        Database.update(e);
        Test.stopTest();
        
        //Asserts
        //1. user created succesfully 
        u = [Select Id FROM User WHERE Username = :c.Email];
        Integer userCountAfter = u.size();
        System.assertEquals(userCountBefore+1, userCountAfter);

        User us = [Select Id, Username, ContactId, TimeZoneSidKey FROM User WHERE Username = 'test@test.com' LIMIT 1];
        System.assertNotEquals(null, us);
        System.assertEquals('test@test.com', us.Username);
        //2. new user linked to the contact
        System.assertEquals(us.ContactId, c.Id);

        Enrollment__c en = [SELECT Id, Delegate_name__r.Email, Portal_Login_Link__c, Portal_Set_Password_Link__c, Could_not_create_User__c, Booking_status__c, Portal_Access__c, Training_Event__c FROM Enrollment__c WHERE Delegate_name__r.Email = 'test@test.com' LIMIT 1];
        //3. enrollment's Portal_Login_Link__c and Portal_Set_Password_Link__c populated. 
        System.assertNotEquals(en.Portal_Login_Link__c, null);
        System.debug(en.Portal_Login_Link__c);
        System.assertNotEquals(en.Portal_Set_Password_Link__c, null);
        //4. enrollment's Could_not_create_User__c = false
        System.assertEquals(en.Could_not_create_User__c, false);
        //5. enrollment's Portal_Access__c = 'New User'
        System.assertEquals(en.Portal_Access__c, 'New User');
        //6. enrollment's booking status = booked
        System.assertEquals(en.Booking_status__c, 'Booked');
        //7. user's timezone populated successfuly
        System.assertEquals(us.TimeZoneSidKey, 'Europe/London');
    }

    /**
     * Method tested: onAfterUpdate() and getEnrollmentContactsUpdate()
     * Test Scenario: update the could not create user checkbox of an existing booked enrollment.
     * Expected Result: successful insertion of user and linked to the enrollment.
     */
    @isTest static void onAfterUpdateCouldNotCreateUserCreateUser(){
        //test data
        generateOrgData();

        //create enrollment
        Contact c = [SELECT Id, Email FROM Contact LIMIT 1];
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTranslation = [SELECT Id FROM Training_Translations__c LIMIT 1];

        t.End_Date2__c = Date.today().addDays(10);
        update t;

        Enrollment__c e = new Enrollment__c(Available_In_Portal_Override__c = 'Show', Portal_Access__c = null, Could_not_create_user__c = true, Training_Event__c = t.Id, Delegate_name__C = c.Id, Booking_status__c = 'Booked', Training_Translations__c = trainingTranslation.Id);    
        insert e;

        //Assert user created succesfully
        List<User> u = [Select Id, Email FROM User WHERE Email =:c.Email];
        Integer userCountBefore = u.size();
        System.debug(userCountBefore);

        Test.startTest();
        e.Could_not_create_user__c = false;
        Database.update(e);
        Test.stopTest();

        //Asserts
        //1. user created succesfully 
        u = [Select Id, Email FROM User WHERE Email =:c.Email];
        Integer userCountAfter = u.size();
        System.assertEquals(userCountBefore+1, userCountAfter);

        Enrollment__c en = [SELECT Id, Delegate_name__r.Email, Portal_Login_Link__c, Portal_Set_Password_Link__c, Could_not_create_User__c, Booking_status__c, Portal_Access__c, Training_Event__c FROM Enrollment__c WHERE Delegate_name__r.Email = 'test@test.com' LIMIT 1];
        //3. enrollment's Portal_Login_Link__c and Portal_Set_Password_Link__c populated. 
        System.assertNotEquals(en.Portal_Login_Link__c, null);
        System.debug(en.Portal_Login_Link__c);
        System.assertNotEquals(en.Portal_Set_Password_Link__c, null);
        //4. enrollment's Could_not_create_User__c = false
        System.assertEquals(en.Could_not_create_User__c, false);
        //5. enrollment's Portal_Access__c = 'New User'
        System.assertEquals(en.Portal_Access__c, 'New User');
        //6. enrollment's booking status = booked
        System.assertEquals(en.Booking_status__c, 'Booked');


    }

    /**
     * Method tested: onAfterUpdate() and getEnrollmentContactsUpdate()
     * Test Scenario: update booking status to booked of an existing enrollment - wrong name for the training translation record
     * Expected Result: insertion of new portal user fails
     */
    @isTest static void onAfterUpdateBookingStatusFailCreateUser(){

        //generate org data
        generateOrgData();

        Contact c = [SELECT Id, Email FROM Contact LIMIT 1];
        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTranslation = [SELECT Id FROM Training_Translations__c LIMIT 1];

        Enrollment__c e = new Enrollment__c(Available_In_Portal_Override__c = 'Show', Portal_Access__c = null, Could_not_create_user__c = true, Training_Event__c = t.Id, Delegate_name__C = c.Id, Booking_status__c = 'Application', Training_Translations__c = trainingTranslation.Id);    
        insert e;
        
        //Assert user created succesfully
        List<User> u = [Select Id FROM User WHERE Username = :c.Email];
        Integer userCountBefore = u.size();

        e = [SELECT Id, Training_Translations__c, Delegate_name__r.Email, Portal_Login_Link__c, Portal_Set_Password_Link__c, Could_not_create_User__c, Booking_status__c, Portal_Access__c, Training_Event__c FROM Enrollment__c WHERE Delegate_name__r.Email = 'test@test.com' LIMIT 1];
        Training_Translations__c trans = [SELECT Id, Name, Language__c FROM Training_Translations__c WHERE Id = :e.Training_Translations__c];
        trans.Name = 'Wrong Name';
        update trans;

        Test.startTest();
        e.Booking_status__c = 'Booked';
        Database.update(e);
        Test.stopTest();


        //Asserts
        //1. user not created succesfully 
        u = [Select Id FROM User WHERE Username = :c.Email];
        Integer userCountAfter = u.size();
        System.assertEquals(userCountBefore, userCountAfter);
        Enrollment__c en = [SELECT Id, Delegate_name__c, Delegate_name__r.Email, Portal_Login_Link__c, Portal_Set_Password_Link__c, Could_not_create_User__c, Booking_status__c, Portal_Access__c, Training_Event__c FROM Enrollment__c WHERE Delegate_name__r.Email = 'test@test.com' LIMIT 1];
        //2. enrollment's Could_not_create_User__c = true
        System.assertEquals(en.Could_not_create_User__c, true);
        //3. enrollment's booking status = booked
        System.assertEquals(en.Booking_status__c, 'Booked');
        //4. enrollment's Portal_Login_Link__c and Portal_Set_Password_Link__c null. 
        System.assertEquals(en.Portal_Login_Link__c, null);
        System.debug(en.Portal_Login_Link__c);
        System.assertEquals(en.Portal_Set_Password_Link__c, null);
    }


    /**
     * Method tested: onAfterUpdate()
     * Test Scenario: update the booking status as booked of an existing enrollment which already has a linked user.
     * Expected Result: fails insertion of user and updates the enrollment fields for the portal access.
     */
    @isTest static void onAfterUpdateExistingUser(){

        //generate org data
        generateOrgData();

        //create enrollment
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        List<Contact> contacts1 = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Id = :c.Id LIMIT 1];
        List<User> users = TestData.createPortalUsers(contacts1, true);
        User u = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];

        Training_Event__c t = [SELECT Id FROM Training_Event__c LIMIT 1];
        Training_Translations__c trainingTranslation = [SELECT Id FROM Training_Translations__c LIMIT 1];

        t.End_Date2__c = Date.today().addDays(10);
        update t;

        Enrollment__c e = new Enrollment__c(Portal_Access__c = null, Training_Event__c = t.Id, Delegate_name__C = c.Id, Booking_status__c = 'Application', Training_Translations__c = trainingTranslation.Id);    
        insert e;

        e = [SELECT Id, Delegate_name__r.Email, Portal_Login_Link__c, Portal_Set_Password_Link__c, Could_not_create_User__c, Booking_status__c, Portal_Access__c, Training_Event__c FROM Enrollment__c WHERE Delegate_name__r.Email = 'test@test.com' LIMIT 1];

        //update enrollment
        Test.startTest();
        e.Booking_status__c = 'Booked';
        Database.update(e);
        Test.stopTest();

        //Asserts
        //1. enrollment's Portal_Access__c = 'Existing User'
        Enrollment__c en = [SELECT Id, Portal_Access__c, Portal_Login_Link__c, Booking_status__c FROM Enrollment__C LIMIT 1];
        System.assertEquals(en.Portal_Access__c, 'Existing User');
        //2. enrollment's Portal_Login_Link__c populated with the login link
        Network myNetwork = [Select Id FROM Network WHERE Name = :Label.CLP_Community_Name];
        String loginUrl = Network.getLoginUrl(myNetwork.Id).removeEnd('s/login').removeEnd('login')+ 'login/';
        System.assertEquals(en.Portal_Login_Link__c, loginUrl.removeEnd('login/') + 's/');
        //System.assertEquals(expected, actual);
        System.assertEquals(e.Portal_Set_Password_Link__c, null);
        //3. enrollment's booking status = booked
        System.assertEquals(en.Booking_status__c, 'Booked');

    }

    /**
     * Method tested: 
     * Test Scenario: 
     * Expected Result: Creates data for the test methods.
     */
    private static void generateOrgData(){

        Account a = new Account(Name = 'test', BillingCountry = 'GB');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
        insert c;

        string productName = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
        prod = [SELECT Id, Course_Duration_Days__c, Show_in_Portal__c, Course_Name_English__c FROM Product2 WHERE Id =:prod.Id];
        prod.Show_in_Portal__c = true;
        update prod;

        Training_Event__c t = new Training_Event__c(Max_seats__c = 3, Course__c = prod.Id);
        insert t;

        Training_Translations__c trainingTranslation = bg_TrainingUnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        trainingTranslation.Language__c = 'EN';
        trainingTranslation.Client_Learning_Portal_on__c = true;
        System.debug(trainingTranslation.Country_code__c);
        insert trainingTranslation;
        
        //Enrollment__c e = new Enrollment__c(Portal_Access__c = null, Training_Event__c = t.Id, Delegate_name__C = c.Id, Booking_status__c = 'Application', Training_Translations__c = trainingTranslation.Id);    
        //insert e;
    }
    
    @isTest static void manageMimeoKeyAssignmentTest(){
        insert new Mimeo_Settings__c(API__c = 'test');

        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, 'Booked');

        Training_Event__c event = [SELECT Course__c FROM Training_Event__c WHERE Id = :e.Training_Event__c];
        event.Mimeo_Distribution_Id__c = 'test';
        update event;

        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;

        Test.startTest();
            EnrollmentTrigHandler.isManageMimeoKeyAssignmentFirstRun = true;
            e.Mimeo_Key_Assignment__c = true;
            update e;
        Test.stopTest();

        e = [SELECT Mimeo_Key_Assignment__c, Mimeo_Key__c, Mimeo_Key_Created_Date__c, Mimeo_Error__c FROM Enrollment__c WHERE Id = :e.Id];
        System.assert(e.Mimeo_Key__c != null);
        System.debug(e);
    }

    @isTest static void revokeMimeoKeyTest(){
        insert new Mimeo_Settings__c(API__c = 'test');

        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, 'Booked');

        Training_Event__c event = [SELECT Course__c FROM Training_Event__c WHERE Id = :e.Training_Event__c];
        event.Mimeo_Distribution_Id__c = 'test';
        update event;

        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;

        Test.startTest();
            EnrollmentTrigHandler.isManageMimeoRevokeKeyFirstRun = true;
            e.Mimeo_Key__c  = 'test';
            e.Revoke_Mimeo_Key__c = true;
            update e;
        Test.stopTest();

        e = [SELECT Revoke_Mimeo_Key__c, Mimeo_Key_Revoked_Date__c, Mimeo_Error__c FROM Enrollment__c WHERE Id = :e.Id];
        System.assert(e.Mimeo_Key_Revoked_Date__c != null);
        System.debug(e);
    }
    
    @isTest static void uploadEnrollmentCertificatesTest(){
        insert new TraceLabs_Settings__c(App_Id__c = 'test', API__c = 'test');
        
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() - 10, true, 'Booked');

        Training_Event__c event = [SELECT Course__c FROM Training_Event__c WHERE Id = :e.Training_Event__c];
        event.Mimeo_Distribution_Id__c = 'test';
        event.End_Date2__c = Date.today().addDays(-10);
        update event;

        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        course.Show_in_Portal__c = true;
        update course;
        
        update new Training_Translations__c(Id = e.Training_Translations__c, Client_Learning_Portal_on__c = true, Certificate_verification__c = true);
                
        Test.startTest();
            EnrollmentTrigHandler.isUploadEnrollmentCertificatesFirstRun = true;
            e.Certificate_status__c = 'Sent';
            e.Show_Certificate_in_Portal__c = true;
            e.Show_Certificate_Holder__c = false;
            update e;
        Test.stopTest();
        
        e = [SELECT Show_Certificate_Holder__c FROM Enrollment__c WHERE Id = :e.Id];
        System.assert(e.Show_Certificate_Holder__c);
    }
}