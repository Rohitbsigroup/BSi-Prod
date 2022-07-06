/**
 * @Name:        ThemeBSIAuraTest
 * @Description: Test Class for ThemeBSIAura
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 03/04/2020   Andrei Budescu     Created Class
 */
@IsTest
public class ThemeBSIAuraTest {

    //wrapper class for the footer link
    public class FooterLink{
        String txt;
        String lnk;

        public FooterLink(String txt, String lnk){
            this.txt = txt;
            this.lnk = lnk;
        }

    }

    /**
	 * Check access for records of Delegate
	 * 
	 */
    public static testMethod void testRunAsDelegate() {

        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact cDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        User uTutor = [SELECT Id, Email FROM User WHERE Email = 'test2@test.com'];
        Contact cTutor = [SELECT Id, Email FROM Contact WHERE Email = 'test2@test.com' LIMIT 1];


        //create training event and enrollment
        string productName = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
        prod = [SELECT Id, Course_Duration_Days__c, Course_Name_English__c FROM Product2 WHERE Id =:prod.Id];
        prod.Course_Duration_Days__c = 10;
        prod.Course_Name_English__c = 'English Name Course';
        update prod;

        //create training event and enrollment
        Training_Event__c t = new Training_Event__c(Trainer__c  = cTutor.Id, Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, End_Date2__c = Date.today() - 30, Max_seats__c = 3, Start_date__c = Date.today() + 8);
        insert t;

        Training_Translations__c trainingTransl = new Training_Translations__c(Name = 'UK (English)', Text_Box_1__c = 'This is to certify that', Text_Box_2__c = 'has attended', Text_box_3__c = 'has attended and passed', 
        Course_Number__c = 'Course number', Certified_By_IRCA__c = 'certified by IRCA', Certified_By__c = 'For and on behalf of BSI:', Signature__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003ufJw&oid=00DD0000000mhEp',
        Training_Manager__c = 'Commercial Training Director: BSI Training Academy', Certificate_Number__c = 'Certificate Number:', Office_Address__c = 'A member of the BSI Group of Companies.', Booking_Confirmation__c = 'Booking Confirmation', 
        Reminder__c = 'Reminder', Rem_Text1__c = 'We would like to take this opportunity to remind you that you are confirmed to attend:', InH_Text1__c = 'Thank you for arranging an In-company training course with BSI. Please find your course details below.', 
        General_Info__c = 'General Information', Aims__c = 'Aims', Start_Date__c = 'Course Start Date', Contact_Us__c = 'Contact Us', Contact_Email__c = 'training.admin@bsigroup.com', Email_Ending__c = 'We hope you enjoy and benefit from the course you have selected. We look forward to seeing you there!', 
        Email_Header__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003uZoe&oid=00DD0000000mhEp', IRCA_Logo__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003uZoN&oid=00DD0000000mhEp', 
        Prerequisites__c = 'Prerequisites', Residential_Text1__c = 'You have chosen the following option:', Residential_Text2__c = 'BSI offer a residential option with this course which includes 4 nights accommodation and evening meals starting from', 
        Location__c = 'Venue', Course_Details__c = 'Course Details', Schedule__c = 'The course schedule', Outcomes__c = 'When the course is finished, you should be able to', Contact_Details_for_Email__c = 'If you have any questions about this course, give us a call on +44 0345 086 9000. If you’d like to see our other courses, please visit http://www.bsigroup.com/en-GB/our-services/training-courses/.', 
        Dear__c = 'Dear', Thank_You__c = 'Thank you for booking with BSI. We can confirm your place on the', Exam_Resit__c = 'Exam Resit', ExR_Text2__c = 'Please be at the venue for 9am. The exam will finish around 12pm.', 
        Booking_Reference__c = 'Booking Reference', OnlineBooking_Notfn_Subject__c = 'Confirmation of BSI Online Booking', Contact_Phone__c = '+44 345 086 9000', Date__c = 'Date', Notfn_Subject__c = 'Important! Your BSI course joining instructions', 
        Notification_New_ENR_added_to_the_portal__c = 'You have been enrolled into the following -', Notification_Pre_Course_Learning_avail__c = 'There are Pre-Course Learning materials available for the following -');
        insert trainingTransl;

        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Delegate_name__c = cDelegate.Id, Training_Event__c = t.Id, Booking_status__c = 'Application', Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), Invoice_status__c = 'Completed');    
        insert enr;
        
        //run as a bsi delegate user
        Map<String, Object> mapReturned = new Map<String, Object> ();
        Set<Id> userRecords = new Set<Id>();

        System.runAs(uDelegate) {
            test.startTest();
            mapReturned = ThemeBSIAura.getRecordRelatedList();
            test.stopTest();
            
            List<Enrollment__c> enrollmentIds = [SELECT Id, Delegate_Name__c, Training_Event__r.Tutor_User_Id__c, Training_Event__r.Tutor_2nd_User_Id__c,
            Training_Event__r.Tutor_3rd_User_Id__c, Training_Event__r.Tutor_4th_User_Id__c, Training_Event__r.Tutor_5th_User_Id__c, Training_Event__c 
            FROM Enrollment__c WHERE Community_User_My_List_View_Toggle__c = true AND Available_In_Portal__c = true];

            for(Enrollment__c e : enrollmentIds){
                //give access to profile of my instructing tutor
                userRecords.add(e.Training_Event__r.Tutor_User_Id__c);
                userRecords.add(e.Training_Event__r.Tutor_2nd_User_Id__c);
                userRecords.add(e.Training_Event__r.Tutor_3rd_User_Id__c);
                userRecords.add(e.Training_Event__r.Tutor_4th_User_Id__c);
                userRecords.add(e.Training_Event__r.Tutor_5th_User_Id__c);

                //give access to my enrollment I'm attending / I'm instructing
                userRecords.add(e.Id);
            }
            
            
        }

        //ids returned by the map
        Set<Id> enrollmentIdsReturned = (Set<Id>) mapReturned.get('recordIdAccess');
        System.assertEquals(userRecords.size(), enrollmentIdsReturned.size());
        
}
    

    /**
	 * Check access for records of Tutor 
	 * 
	 */
    public static testMethod void testRunAsTutor() {

        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact cDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        User uTutor = [SELECT Id, Email FROM User WHERE Email = 'test2@test.com'];
        Contact cTutor = [SELECT Id, Email, AccountId FROM Contact WHERE Email = 'test2@test.com' LIMIT 1];
        Account aTutor = [SELECT Id FROM Account WHERE Id = :cTutor.AccountId];
        Profile profileTutor = [SELECT Id, Name FROM Profile WHERE Name = :Label.BSIUserSettings_ProfileNameTutor LIMIT 1];

        //create training event and enrollment
        string productName = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
        prod = [SELECT Id, Course_Duration_Days__c, Course_Name_English__c FROM Product2 WHERE Id =:prod.Id];
        prod.Course_Duration_Days__c = 10;
        prod.Course_Name_English__c = 'English Name Course';
        update prod;

        //create training event and enrollment
        Training_Event__c t = new Training_Event__c(Trainer__c  = cTutor.Id, Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, End_Date2__c = Date.today() - 30, Max_seats__c = 3, Start_date__c = Date.today() + 8);
        insert t;

        Training_Translations__c trainingTransl = new Training_Translations__c(Name = 'UK (English)', Text_Box_1__c = 'This is to certify that', Text_Box_2__c = 'has attended', Text_box_3__c = 'has attended and passed', 
        Course_Number__c = 'Course number', Certified_By_IRCA__c = 'certified by IRCA', Certified_By__c = 'For and on behalf of BSI:', Signature__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003ufJw&oid=00DD0000000mhEp',
        Training_Manager__c = 'Commercial Training Director: BSI Training Academy', Certificate_Number__c = 'Certificate Number:', Office_Address__c = 'A member of the BSI Group of Companies.', Booking_Confirmation__c = 'Booking Confirmation', 
        Reminder__c = 'Reminder', Rem_Text1__c = 'We would like to take this opportunity to remind you that you are confirmed to attend:', InH_Text1__c = 'Thank you for arranging an In-company training course with BSI. Please find your course details below.', 
        General_Info__c = 'General Information', Aims__c = 'Aims', Start_Date__c = 'Course Start Date', Contact_Us__c = 'Contact Us', Contact_Email__c = 'training.admin@bsigroup.com', Email_Ending__c = 'We hope you enjoy and benefit from the course you have selected. We look forward to seeing you there!', 
        Email_Header__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003uZoe&oid=00DD0000000mhEp', IRCA_Logo__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003uZoN&oid=00DD0000000mhEp', 
        Prerequisites__c = 'Prerequisites', Residential_Text1__c = 'You have chosen the following option:', Residential_Text2__c = 'BSI offer a residential option with this course which includes 4 nights accommodation and evening meals starting from', 
        Location__c = 'Venue', Course_Details__c = 'Course Details', Schedule__c = 'The course schedule', Outcomes__c = 'When the course is finished, you should be able to', Contact_Details_for_Email__c = 'If you have any questions about this course, give us a call on +44 0345 086 9000. If you’d like to see our other courses, please visit http://www.bsigroup.com/en-GB/our-services/training-courses/.', 
        Dear__c = 'Dear', Thank_You__c = 'Thank you for booking with BSI. We can confirm your place on the', Exam_Resit__c = 'Exam Resit', ExR_Text2__c = 'Please be at the venue for 9am. The exam will finish around 12pm.', 
        Booking_Reference__c = 'Booking Reference', OnlineBooking_Notfn_Subject__c = 'Confirmation of BSI Online Booking', Contact_Phone__c = '+44 345 086 9000', Date__c = 'Date', Notfn_Subject__c = 'Important! Your BSI course joining instructions', 
        Notification_New_ENR_added_to_the_portal__c = 'You have been enrolled into the following -', Notification_Pre_Course_Learning_avail__c = 'There are Pre-Course Learning materials available for the following -');
        insert trainingTransl;

        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Delegate_name__c = cDelegate.Id, Training_Event__c = t.Id, Booking_status__c = 'Application', Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), Invoice_status__c = 'Completed');    
        insert enr;

        //create opportunity
        Opportunity op = new Opportunity(Name='JP Test 2705 - Business Continuity Management Systems Understanding Course', AccountId = aTutor.Id, PrevCustomer__c = 'No',
                    CountrySalesAdminEmail__c = 'quotation.station@bsigroup.com.test', CurrencyIsoCode = 'JPY', CloseDate = Date.newInstance(2021, 12, 9), 
                    StageName = 'Closed Won', LeadSource = 'Marketing Channels', SourceSubCategory__c = 'Website', DeliveryDateExpectations__c = Date.newInstance(2021, 12, 10),
                    Product_Stream__c = 'Training Public');
        insert op;

        //create case for survey
        Case c = new Case(Opportunity__c = op.Id, ContactId = cTutor.Id, Status='New', Origin = 'Customer Survey');
        insert c;

        //create survey record
        Survey__c survey = new Survey__c(Training_Event__c = t.Id, Enrollment__c = enr.Id, Survey_Type__c = 'Activity');
        insert survey;

        //run as a bsi delegate user
        Map<String, Object> mapReturned = new Map<String, Object> ();
        Set<Id> userRecords = new Set<Id>();

        System.runAs(uTutor) {
            test.startTest();
            mapReturned = ThemeBSIAura.getRecordRelatedList();
            test.stopTest();
            
            List<Enrollment__c> enrollmentIds = [SELECT Id, Delegate_Name__c, Training_Event__r.Tutor_User_Id__c, Training_Event__r.Tutor_2nd_User_Id__c,
            Training_Event__r.Tutor_3rd_User_Id__c, Training_Event__r.Tutor_4th_User_Id__c, Training_Event__r.Tutor_5th_User_Id__c, Training_Event__c 
            FROM Enrollment__c WHERE Community_User_My_List_View_Toggle__c = true AND Available_In_Portal__c = true];

            List<Survey__c> surveys = [SELECT Id, Community_Tutor_List_View_Toggle__c, Community_2nd_Tutor_List_View_Toggle__c FROM Survey__c 
                                        WHERE Community_Tutor_List_View_Toggle__c = true OR Community_2nd_Tutor_List_View_Toggle__c = true];
           

            for(Enrollment__c e : enrollmentIds){
                //give access to profile of my instructing tutor
                userRecords.add(e.Training_Event__r.Tutor_User_Id__c);
                userRecords.add(e.Training_Event__r.Tutor_2nd_User_Id__c);
                userRecords.add(e.Training_Event__r.Tutor_3rd_User_Id__c);
                userRecords.add(e.Training_Event__r.Tutor_4th_User_Id__c);
                userRecords.add(e.Training_Event__r.Tutor_5th_User_Id__c);

                //give access to my enrollment I'm attending / I'm instructing
                userRecords.add(e.Id);

                if(profileTutor.Name == Label.BSIUserSettings_ProfileNameTutor){
                    //give access to Training Event where tutor is instructing
                    userRecords.add(e.Training_Event__c);
                
                    //give access to User Profile page of the own Tutor
                    userRecords.add(uTutor.Id);

                }
            }
            
            //add training events for tutor without enrollments linked to that training event record
            if(profileTutor.Name == Label.BSIUserSettings_ProfileNameTutor){
                userRecords.addall(new Map<Id, Training_Event__c>([SELECT Id FROM Training_Event__c WHERE Community_User_My_List_View_Toggle__c = true]).keySet());
            }

            for(Survey__c s : surveys){
                userRecords.add(s.Id);
            }
            
        }

        //ids returned by the map
        Set<Id> enrollmentIdsReturned = (Set<Id>) mapReturned.get('recordIdAccess');
        System.assertEquals(userRecords.size(), enrollmentIdsReturned.size());
    }

    /**
	 * Check footer links for a user depending on the country
	 * 
	 */
    public static testMethod void testFooterLinks() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact cDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        User uTutor = [SELECT Id, Email FROM User WHERE Email = 'test2@test.com'];
        Contact cTutor = [SELECT Id, Email FROM Contact WHERE Email = 'test2@test.com' LIMIT 1];


        //create training event and enrollment
        string productName = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
        prod = [SELECT Id, Course_Duration_Days__c, Course_Name_English__c FROM Product2 WHERE Id =:prod.Id];
        prod.Course_Duration_Days__c = 10;
        prod.Course_Name_English__c = 'English Name Course';
        update prod;

        //create training event and enrollment
        Training_Event__c t = new Training_Event__c(Trainer__c  = cTutor.Id, Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, End_Date2__c = Date.today() - 30, Max_seats__c = 3, Start_date__c = Date.today() + 8);
        insert t;

        Training_Translations__c trainingTransl = new Training_Translations__c(Name = 'UK (English)', Text_Box_1__c = 'This is to certify that', Text_Box_2__c = 'has attended', Text_box_3__c = 'has attended and passed', 
        Course_Number__c = 'Course number', Certified_By_IRCA__c = 'certified by IRCA', Certified_By__c = 'For and on behalf of BSI:', Signature__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003ufJw&oid=00DD0000000mhEp',
        Training_Manager__c = 'Commercial Training Director: BSI Training Academy', Certificate_Number__c = 'Certificate Number:', Office_Address__c = 'A member of the BSI Group of Companies.', Booking_Confirmation__c = 'Booking Confirmation', 
        Reminder__c = 'Reminder', Rem_Text1__c = 'We would like to take this opportunity to remind you that you are confirmed to attend:', InH_Text1__c = 'Thank you for arranging an In-company training course with BSI. Please find your course details below.', 
        General_Info__c = 'General Information', Aims__c = 'Aims', Start_Date__c = 'Course Start Date', Contact_Us__c = 'Contact Us', Contact_Email__c = 'training.admin@bsigroup.com', Email_Ending__c = 'We hope you enjoy and benefit from the course you have selected. We look forward to seeing you there!', 
        Email_Header__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003uZoe&oid=00DD0000000mhEp', IRCA_Logo__c = 'https://bsi--c.documentforce.com/servlet/servlet.ImageServer?id=015D0000003uZoN&oid=00DD0000000mhEp', 
        Prerequisites__c = 'Prerequisites', Residential_Text1__c = 'You have chosen the following option:', Residential_Text2__c = 'BSI offer a residential option with this course which includes 4 nights accommodation and evening meals starting from', 
        Location__c = 'Venue', Course_Details__c = 'Course Details', Schedule__c = 'The course schedule', Outcomes__c = 'When the course is finished, you should be able to', Contact_Details_for_Email__c = 'If you have any questions about this course, give us a call on +44 0345 086 9000. If you’d like to see our other courses, please visit http://www.bsigroup.com/en-GB/our-services/training-courses/.', 
        Dear__c = 'Dear', Thank_You__c = 'Thank you for booking with BSI. We can confirm your place on the', Exam_Resit__c = 'Exam Resit', ExR_Text2__c = 'Please be at the venue for 9am. The exam will finish around 12pm.', 
        Booking_Reference__c = 'Booking Reference', OnlineBooking_Notfn_Subject__c = 'Confirmation of BSI Online Booking', Contact_Phone__c = '+44 345 086 9000', Date__c = 'Date', Notfn_Subject__c = 'Important! Your BSI course joining instructions', 
        Notification_New_ENR_added_to_the_portal__c = 'You have been enrolled into the following -', Notification_Pre_Course_Learning_avail__c = 'There are Pre-Course Learning materials available for the following -');
        insert trainingTransl;

        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Delegate_name__c = cDelegate.Id, Training_Event__c = t.Id, Booking_status__c = 'Application', Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), Invoice_status__c = 'Completed');    
        insert enr;

        List<FooterLink> footerLinkList = new List<FooterLink>();
        
        
        //run as a bsi delegate user
        System.runAs(uTutor) {
            test.startTest();
            String listLinks = ThemeBSIAura.getFooterLinks();
            footerLinkList = (List<FooterLink>)System.JSON.deserialize(listLinks, List<FooterLink>.class);
            test.stopTest();

            System.assertEquals(4, footerLinkList.size());
            for(FooterLink link : footerLinkList){

            }



        }

    }

    @TestSetup
    private static void generateOrgData(){

        Account a = new Account(Name = 'test', BillingCountry = 'GB');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', Phone = '07123436542', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
		insert c;

		Contact c2 = new Contact(AccountId = a.Id, FirstName = 'test2', Phone = '07123436542', LastName = 'test2', Email = 'test2@test.com', MailingCountry = 'GB');
		insert c2;

		List<Contact> contacts1 = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
		
        List<User> users = TestData.createPortalUsers(contacts1, true);
        
        List<Contact> contacts2 = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test2@test.com' LIMIT 1];

        List<User> users2 = TestData.createPortalUsersTutors(contacts2, true);
	
	}

}