@isTest
public class ShowingCertificationCmpControllerTest {

    @testSetup
    private static void setup() {
        Account account = new Account(Name = 'test', BillingCountry = 'GB');
        insert account;
        Contact contact = new Contact(AccountId = account.Id, FirstName = 'test', Phone = '07123436542', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
        insert contact;
        Id qualificationRecordTypeId = Schema.SObjectType.Qualification__c.getRecordTypeInfosByName().get('BSI Qualification').getRecordTypeId(); 
        Qualification__c qualification = new Qualification__c(Name = 'UK - ISO 9001 Qualification Test', Status__c = 'Active', RecordTypeId = qualificationRecordTypeId);
        insert qualification;
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
        Notification_New_ENR_added_to_the_portal__c = 'You have been enrolled into the following -', Notification_Pre_Course_Learning_avail__c = 'There are Pre-Course Learning materials available for the following -', Certificate_verification__c = true);
        insert trainingTransl;
        Personal_Qualification__c personalQualification = new Personal_Qualification__c(Qualification__c = qualification.Id, Training_Translations__c = trainingTransl.Id, Show_Certificate_Holder__c = true, Delegate__c = contact.Id, Certificate_Sent__c = true, Share_Certificate__c = true);
        insert personalQualification;
        String productName = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
        prod = [SELECT Id, Course_Duration_Days__c FROM Product2 WHERE Id =:prod.Id];
        prod.Course_Duration_Days__c = 10;
        update prod;
        Training_Event__c t = new Training_Event__c(Course__c = prod.Id, End_Date2__c = Date.today() - 8, Max_seats__c = 3, Start_date__c = Date.today() + 8);
        insert t;
        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Show_Certificate_Holder__c = true, Delegate_name__c = contact.Id, Training_Event__c = t.Id, Booking_status__c = 'Application', 
                                              Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), Invoice_status__c = 'Completed', Certificate_status__c = 'Sent', Share_Certificate__c = true);    
        insert enr;
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(
            Alias = 'standt', 
            Email = 'standarduser@testorg.com', 
            EmailEncodingKey = 'UTF-8', 
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser1111@testorg.com',
            OperationCountry__c = 'GB'
        );
        insert u;
    }
    
    @isTest
    private static void checkShowCertConditionValidityPersonalQualificationSuccessTest() {
        List<User> users = [SELECT Id FROM User WHERE UserName = 'standarduser1111@testorg.com' LIMIT 1];
        List<Personal_Qualification__c> personalQualification = [SELECT Id FROM Personal_Qualification__c LIMIT 1];
        System.runAs(users[0]) {
            Test.startTest();
            ShowingCertificationCmpController.ResultWrapper result = ShowingCertificationCmpController.checkShowCertConditionValidity(personalQualification[0].Id);
            Test.stopTest();
            System.assertEquals(true, result.isValidity);
            System.assertEquals(ShowingCertificationCmpController.PERSONAL_QUALIFICATION_OBJECT_API_NAME, result.objectApiName);
        }
    }
    
    @isTest
    private static void checkShowCertConditionValidityPersonalQualificationFailTest() {
        List<User> users = [SELECT Id FROM User WHERE UserName = 'standarduser1111@testorg.com' LIMIT 1];
        List<Personal_Qualification__c> personalQualification = [SELECT Id, Show_Certificate_Holder__c FROM Personal_Qualification__c LIMIT 1];
        personalQualification[0].Show_Certificate_Holder__c = false;
        update personalQualification;
        System.runAs(users[0]) {
            Test.startTest();
            ShowingCertificationCmpController.ResultWrapper result = ShowingCertificationCmpController.checkShowCertConditionValidity(personalQualification[0].Id);
            Test.stopTest();
            System.assertEquals(false, result.isValidity);
            System.assertEquals(ShowingCertificationCmpController.PERSONAL_QUALIFICATION_OBJECT_API_NAME, result.objectApiName);
        }
    }
    
    @isTest
    private static void checkShowCertConditionValidityEnrollmentSuccessTest() {
        List<User> users = [SELECT Id FROM User WHERE UserName = 'standarduser1111@testorg.com' LIMIT 1];
        List<Enrollment__c> enrollment = [SELECT Id, Certificate_status__c FROM Enrollment__c LIMIT 1];
        System.runAs(users[0]) {
            Test.startTest();
            ShowingCertificationCmpController.ResultWrapper result = ShowingCertificationCmpController.checkShowCertConditionValidity(enrollment[0].Id);
            Test.stopTest();
            System.assertEquals(true, result.isValidity);
            System.assertEquals(ShowingCertificationCmpController.ENROLLMENT_OBJECT_API_NAME, result.objectApiName);
        }
    }
    
    @isTest
    private static void checkShowCertConditionValidityEnrollmentFailTest() {
        List<User> users = [SELECT Id FROM User WHERE UserName = 'standarduser1111@testorg.com' LIMIT 1];
        List<Enrollment__c> enrollment = [SELECT Id, Certificate_status__c FROM Enrollment__c LIMIT 1];
        enrollment[0].Show_Certificate_Holder__c = false;
        update enrollment;
        System.runAs(users[0]) {
            Test.startTest();
            ShowingCertificationCmpController.ResultWrapper result = ShowingCertificationCmpController.checkShowCertConditionValidity(enrollment[0].Id);
            Test.stopTest();
            System.assertEquals(false, result.isValidity);
            System.assertEquals(ShowingCertificationCmpController.ENROLLMENT_OBJECT_API_NAME, result.objectApiName);
        }
    }
    
    @isTest
    private static void checkShowCertConditionValidityNullResult() {
        List<User> users = [SELECT Id FROM User WHERE UserName = 'standarduser1111@testorg.com' LIMIT 1];
        System.runAs(users[0]) {
            Test.startTest();
            ShowingCertificationCmpController.ResultWrapper result = ShowingCertificationCmpController.checkShowCertConditionValidity(users[0].Id);
            Test.stopTest();
            System.assertEquals(false, result.isValidity);
            System.assertEquals(null, result.objectApiName);
        }
    }

    @isTest
    private static void udpateShareCertificateCheckboxOnRecordEnrollmentTest() {
        List<Enrollment__c> enrollment = [SELECT Id, Certificate_status__c FROM Enrollment__c LIMIT 1];
        Test.startTest();
        ShowingCertificationCmpController.udpateShareCertificateCheckboxOnRecord(enrollment[0].Id);
        Test.stopTest();
        List<Enrollment__c> result = [SELECT Id, Share_Certificate__c FROM Enrollment__c LIMIT 1];
        System.assertEquals(false, result[0].Share_Certificate__c);
    }
    
    @isTest
    private static void udpateShareCertificateCheckboxOnRecordPersonalQualificationTest() {
        List<Personal_Qualification__c> personalQualification = [SELECT Id FROM Personal_Qualification__c LIMIT 1];
        Test.startTest();
        ShowingCertificationCmpController.udpateShareCertificateCheckboxOnRecord(personalQualification[0].Id);
        Test.stopTest();
        List<Personal_Qualification__c> result = [SELECT Id, Share_Certificate__c FROM Personal_Qualification__c LIMIT 1];
        System.assertEquals(false, result[0].Share_Certificate__c);
    }
}