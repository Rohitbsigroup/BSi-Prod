/********************************************************************
 * AttendanceRegisterControllerRankTest
 *
 * Test class for AttendanceRegisterControllerRank
 * 
 *
 * Create a test Training Course
 * Create a test Pricebook
 * Create a standard Pricebook Entry
 * Create a test Pricebook Entry
 * Create a training venue
 * Create an instructor
 * Create a test Training Event
 *
 * For master combined would want to make master first for id
 * 
 * Account
 * Contact
 * Enrollment
 *

 * Author: Maria Dyer
 * Created: 25th April 2018
 * Copied from AttendanceRegisterControllerTest
 * Changes: 
 * 30-10-2018 PC K2 optimised class to fix governor limits
 ********************************************************************/

@isTest
private class AttendanceRegisterControllerRankTest{

// Create set of Event and Enrolments
    
    @isTest static void testSomething()
    {        
        // Here BG would start by creating a user
        // Initialise Custom Settings
        //bg_UnitTestHelper.SetupCustomSettings();
        //User user1 = bg_UnitTestHelper.GetUser('BG@brightgen.com', 'BG@brightgen.com', 'tstuserx');
        //System.runAs(user1)
        //{
        
            //Account
            Account acc = bg_TrainingUnitTestHelper.createAccount('AName','GB');

            //Training Venue
            Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
            Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');

            //Contacts
            Contact con1 = new Contact(AccountId = acc.Id, FirstName = 'Bob1', LastName = 'SName1', MailingCountry = 'UK', Country_Office__c = tv.Id);
            Contact con2 = new Contact(AccountId = acc.Id, FirstName = 'Bob2', LastName = 'SName2', MailingCountry = 'UK', Country_Office__c = tv.Id);
            Contact con3 = new Contact(AccountId = acc.Id, FirstName = 'Bob3', LastName = 'SName3', MailingCountry = 'UK', Country_Office__c = tv.Id);
            Contact con4 = new Contact(AccountId = acc.Id, FirstName = 'Bob4', LastName = 'SName4', MailingCountry = 'UK', Country_Office__c = tv.Id);
            Contact con5 = new Contact(AccountId = acc.Id, FirstName = 'Bob5', LastName = 'SName5', MailingCountry = 'UK', Country_Office__c = tv.Id);
            Contact con6 = new Contact(AccountId = acc.Id, FirstName = 'Bob6', LastName = 'SName6', MailingCountry = 'UK', Country_Office__c = tv.Id);
            Contact con7 = new Contact(AccountId = acc.Id, FirstName = 'Tod1', LastName = 'SNameInstr1', MailingCountry = 'UK', Country_Office__c = tv.Id);
            con7.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Instructor').getRecordTypeId();
            con7.Instructor_SAP_number__c = 1234;
            // con7.Trainer_Day_Rate__c = 100;
            List<Contact> contactList = new List<Contact>{con1, con2, con3, con4, con5, con6, con7};
            insert contactList;
          
            // Three products and three events all with the same venue and instructor
            Product2 product1 = new Product2(Name = 'Test Course1', I_codes_Required__c = 'Icode1,Icode2', Course_Duration_Days__c = 1, ProductArea__c = 'Training', IsActive = true, CurrencyIsoCode = bg_Globals.CURRENCY_CODE_USD);
            Product2 product2 = new Product2(Name = 'Test Course2', I_codes_Required__c = 'Icode1,Icode2', Course_Duration_Days__c = 2, ProductArea__c = 'Training', IsActive = true, CurrencyIsoCode = bg_Globals.CURRENCY_CODE_USD);
            Product2 product3 = new Product2(Name = 'Test Course3', I_codes_Required__c = 'Icode1,Icode2', Course_Duration_Days__c = 5, ProductArea__c = 'Training', IsActive = true, CurrencyIsoCode = bg_Globals.CURRENCY_CODE_USD);
            List<Product2> productList = new List<Product2>{product1, product2, product3};
            insert productList;
            
            // Training Translation
            Training_Translations__c translation = bg_TrainingUnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
            translation.Date_s__c = 'Date(s)';
            translation.The_venue__c = 'The Venue';
            translation.Language__c = 'EN';
            insert translation;


            Id combinedMasterRTId = Schema.SObjectType.Training_Event__c.getRecordTypeInfosByName().get('Global Training Event (Combined Master)').getRecordTypeId();
            Id combinedEventRTId = Schema.SObjectType.Training_Event__c.getRecordTypeInfosByName().get('Global Training Event (Combined Event)').getRecordTypeId();

            // Training Event - Global Training Event (Combined Master)
            Training_Event__c te1 = new Training_Event__c(Training_Venue__c = tv.Id, CurrencyIsoCode = 'GBP', Max_Seats__c = 10, Start_date__c = Date.today() + 5, Event_status__c = 'Active');
            te1.Course__c = product1.Id;
            te1.Trainer__c = con7.Id;
            te1.RecordTypeId = combinedMasterRTId;

            //Training Events - Global Training Event (Combined Event) Event Id for the Master Event
            Training_Event__c te2 = new Training_Event__c(Training_Venue__c = tv.Id, CurrencyIsoCode = 'GBP', Max_Seats__c = 10, Start_date__c = Date.today() + 5, Event_status__c = 'Active');
            te2.Course__c = product2.Id;
            te2.Trainer__c = con7.Id;
            te2.RecordTypeId = combinedEventRTId;
            te2.Master_Training_Event__c = te1.Id;

            Training_Event__c te3 = new Training_Event__c(Training_Venue__c = tv.Id, CurrencyIsoCode = 'GBP', Max_Seats__c = 10, Start_date__c = Date.today() + 5, Event_status__c = 'Active');
            te3.Course__c = product3.Id;
            te3.Trainer__c = con7.Id;
            te3.RecordTypeId = combinedEventRTId;
            te3.Master_Training_Event__c = te1.Id;

            Training_Event__c te4 = new Training_Event__c(Training_Venue__c = tv.Id, CurrencyIsoCode = 'GBP', Max_Seats__c = 10, Start_date__c = Date.today() + 5, Event_status__c = 'Active');
            te4.Course__c = product3.Id;
            te4.Trainer__c = con7.Id;
            te4.RecordTypeId = combinedEventRTId;
            te4.Master_Training_Event__c = te1.Id;

            List<Training_Event__c> trainingEventList = new List<Training_Event__c>{te1, te2, te3, te4};
            insert trainingEventList;

            // Enrollments going into Global Training Event (Combined Event)
            // te2
            Enrollment__c enr1 = bg_TrainingUnitTestHelper.GetEnrolment('GBP',con1,translation,te2,'Booked');
            Enrollment__c enr2 = bg_TrainingUnitTestHelper.GetEnrolment('GBP',con2,translation,te2,'Booked');
            Enrollment__c enr3 = bg_TrainingUnitTestHelper.GetEnrolment('GBP',con3,translation,te2,'Booked');

            // Enrollments going into Global Training Event (Combined Event)
            // te3
            Enrollment__c enr4 = bg_TrainingUnitTestHelper.GetEnrolment('GBP',con1,translation,te3,'Booked');
            Enrollment__c enr5 = bg_TrainingUnitTestHelper.GetEnrolment('GBP',con2,translation,te3,'Booked');
            Enrollment__c enr6 = bg_TrainingUnitTestHelper.GetEnrolment('GBP',con3,translation,te3,'Booked');

            // Enrollments going into Global Training Event (Combined Event)
            // te4
            Enrollment__c enr7 = bg_TrainingUnitTestHelper.GetEnrolment('GBP',con1,translation,te4,'Booked');
            Enrollment__c enr8 = bg_TrainingUnitTestHelper.GetEnrolment('GBP',con2,translation,te4,'Booked');
            Enrollment__c enr9 = bg_TrainingUnitTestHelper.GetEnrolment('GBP',con3,translation,te4,'Booked');  
            
            List<Enrollment__c> enrollmentList = new List<Enrollment__c>{enr1, enr2, enr3, enr4, enr5, enr6, enr7, enr8, enr9};
            insert enrollmentList;

            /*
            List<Contact> ConList = new List<Contact>();
            ConList = [Select Name from Contact where AccountID = :acc.id];
            system.debug('This is the contact list from the set ' + ConList);
            For(Contact C: ConList){
            system.debug(C.Name);
            }
            system.debug('Regualar contact recordtype ' + con6.recordtypeID);       
            system.debug('Instructor recordtype ' + con7.recordtypeID);
            */
        
            Test.startTest();
            
                // PageReference tpageRef = Page.AttendanceSheetWeeklyStretched;
                // Test.setCurrentPage(tComRef);

        
                // ApexPages.currentPage().getParameters().put('Id', te1.Id);
                // Create an instance of the custom controller  [? Below making another 2 instances but for case of master and child tpecs, they all would use the one controller ?]
                attendanceRegisterControllerRank myattendanceRegisterController = new attendanceRegisterControllerRank();
                myattendanceRegisterController.TrainingEventId = te1.Id;
                
                // System.assertEquals( te1.id,ApexPages.currentPage().getParameters().get('Id'));
        

                System.debug('blnMasterEvent: ' + myattendanceRegisterController.TrainingEventId);
                System.debug('getEnrollments: ' + myattendanceRegisterController.getEnrollments());

       Test.stopTest();

    }
    


}