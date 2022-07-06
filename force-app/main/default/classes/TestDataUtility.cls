/**
* Author:       Pawel Chrzanowski (K2)
* Date:         08/08/2018
* Description:  test class with utilities
*
* ******************* Change Log *******************
**/

@isTest
public class TestDataUtility {

    public static Product2 insertCourse(){
        Product2 course = new Product2();
        course.Name = 'Test Course';
        course.CurrencyIsoCode = 'GBP';
        course.Enable_automated_email_confirmation__c = true;
        course.Enable_pdf_certificate_emails__c = true;
        course.I_codes_Required__c = 'Icode1,Icode2';
        course.ProductArea__c = 'Training';
        course.ProductCode = 'code';
        course.IsActive = true;
        insert course;
        return course;
    }

    public static Training_Event__c insertTrainingEvent(Date courseStartDate, Boolean eventConfirmed){
        Training_Venue__c masterv = new Training_Venue__c(Name = 'Master Venue', CurrencyIsoCode = 'GBP', Public_Venue__c = true);
        insert masterv;

        Training_Venue__c trainingv = new Training_Venue__c(Name = 'Training Venue', CurrencyIsoCode = 'GBP', Public_Venue__c = true, Training_Office__c = masterv.Id, Venue_Day_Rate__c = 100, Venue_Day_Delegate_Rate__c = 100, Venue_Residential_Delegate_Rate__c = 100);
        insert trainingv;

        Contact instructor = new Contact(FirstName = 'test', LastName = 'test', MailingCountry = 'GB', Email = 'email@email.com', RecordTypeId = bg_RecordTypeUtils.GetRecordTypes(bg_RecordTypeUtils.OBJECT_NAME_CONTACT).get(bg_ContactUtils.RECORD_TYPE_NAME_CLIENTS).Id, I_Codes_text__c = 'ICODES', Country_Office__c = masterv.Id);
        insert instructor;

        Product2 course = insertCourse();

        Training_Event__c event = new Training_Event__c();
        event.Training_Venue__c = trainingv.Id;
        event.CurrencyIsoCode = 'GBP';
        event.Max_Seats__c = 10;
        event.Course__c = course.Id;
        event.Start_date__c = courseStartDate;
        event.Event_status__c = Label.Active;
        event.Trainer__c = instructor.Id;
        event.Duration_days__c = 1;
        event.Event_Confirmed__c = eventConfirmed;
        insert event;
        return event;
    }

    public static Training_Translations__c insertTrainingTranslation(){
        Training_Translations__c translation = new Training_Translations__c();
        translation.Name = 'test translation';
        translation.CurrencyIsoCode = 'GBP';
        translation.Certificate_Number__c = 'Certificate Number';
        translation.Certified_By_IRCA__c = 'Certified by IRCA';
        translation.Certified_By__c = 'For and on behalf BSI:';
        translation.Course_Number__c = 'Course Number';
        translation.IRCA_Logo__c = 'https://eu1.salesforce.com/servlet/servlet.ImageServer?id=015D0000001Fs3o&oid=00D200000000Evl';
        translation.Email_Header__c = 'https://eu1.salesforce.com/servlet/servlet.ImageServer?id=015D0000001HJot&oid=00D200000000Evl';
        translation.Dear__c = 'Dear';
        translation.OnlineBooking_Notfn_Subject__c = 'Confirmation of BSI Online Booking';
        translation.Signature__c = 'https://eu1.salesforce.com/servlet/servlet.ImageServer?id=015D0000001Fs3y&oid=00D200000000Evl';
        translation.Signature_Image__c = 'signature_UK.jpg';
        translation.Training_Manager__c = 'Test Manager, Head of Test';
        translation.Contact_Email__c = 'testmanager@company.com';
        translation.Booking_Confirmation__c = 'Booking Confirmation';
        translation.Booking_Reference__c = 'Booking Reference';
        translation.Contact_Us__c = 'Contact us';
        translation.Course_Details__c = 'Course Details';
        translation.Date__c = 'Date';
        translation.Start_date__c = 'Course Start Date';
        translation.Location__c = 'Venue';
        translation.Notfn_Subject__c = 'Important! Your BSI course joining instructions';
        translation.ExR_Text2__c = 'Please be at the venue for 9am. The exam will finish around 12pm.';
        translation.Office_Address__c = 'A member of the BSI Group of Companies.';
        translation.Exam_Resit__c = 'Exam Resit';
        translation.Outcomes__c = 'When the course is finished, you should be able to';
        translation.General_Info__c = 'General Information';
        translation.Prerequisites__c = 'Prerequisites';
        translation.Aims__c = 'Aims';
        translation.Reminder__c = 'Reminder';
        translation.Text_Box_1__c = 'This is to certify that';
        translation.Text_Box_2__c = 'has attended';
        translation.Text_Box_3__c = 'has attended and passed';
        translation.Residential_Text1__c = 'You have chosen the following option:';
        translation.Residential_Text2__c = 'BSI offer a residential option with this course which includes 4 nights accommodation and evening meals starting from';
        translation.Schedule__c = 'The course schedule';
        translation.Notfn_Subject_TA__c = 'Important! Your BSI course joining instructions';
        translation.InH_Text1__c = 'Thank you for arranging an In-company training course with BSI. Please find your course details below.';
        translation.Additional_Emails__c = 'test-email1@test.com, test-email2@test.com, test-email3@test.com';
        translation.Enable_Booking_Confirmation_IH_Emails__c = true;
        translation.Enable_Booking_Confirmation_BIH_Emails__c = true;
        translation.Enable_Confirmation_of_Place_Emails__c = true;
        translation.Enable_Course_Update_Emails__c = true;
        translation.Enable_Delivery_Confirmation_ACC_Emails__c = true;
        translation.Enable_Delivery_Confirmation_WCC_Emails__c = true;
        translation.Enable_Exam_Emails__c = true;
        translation.Enable_PDF_Certificate_Emails__c = true;
        translation.Enable_Resit_Confirmation_Emails__c = true;
        translation.From_Email_Address__c = 'general-test-email@test.com';
        translation.CC_Training_Event_Owner__c = true;
        translation.CC_Enrollment_Creator__c = true;
        translation.Certificate_verification__c = false;
        insert translation;
        return translation;
    }

    public static Enrollment__c insertEnrollmentWithDependancies(Date courseStartDate, Boolean eventConfirmed, String bookingStatus){
        Account a = new Account(Name = 'test', BillingCountry = 'UK');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
        insert c;

        Opportunity o = new Opportunity(Name = 'test Opp', StageName = 'Sales Engaged', CloseDate = Date.today(), AccountId = a.Id, Sync_in_Progress__c = true, BusinessDrivers__c = 'New Customer');
        insert o;

        Training_Event__c event = insertTrainingEvent(courseStartDate, eventConfirmed);

        Training_Translations__c translation = insertTrainingTranslation();

        Enrollment__c testEnrollment = new Enrollment__c();
        testEnrollment.Training_Event__c = event.Id;
        testEnrollment.Training_Translations__c = translation.Id;
        testEnrollment.Booking_status__c = bookingStatus;
        testEnrollment.Delegate_Name__c = c.Id;
        testEnrollment.Bookers_Email__c = 'test-booker@test.com';
        insert testEnrollment;
        return testEnrollment;
    }

    public static Personal_Qualification__c insertPersonalQualificationWithDependancies(){
        Account a = new Account(Name = 'test', BillingCountry = 'UK');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
        insert c;

        Training_Translations__c translation = insertTrainingTranslation();

        Master_Qualification__c mq = new Master_Qualification__c(
            Name = 'ISO 9001 Internal Auditor Practitioner',
            Taxonomy__c = 'QMS58009ENGX', 
            Product__c = 'ISO 9001'
        );
        insert mq;

        Qualification__c q = new Qualification__c(
            Name = 'UK - ISO 9001 Internal Auditor Practitioner', 
            Master_Qualification__c = mq.Id, 
            RecordTypeId = '0124G000000KNfBQAW',
            Status__c = 'Active'
        );
        insert q;

        Personal_Qualification__c pq = new Personal_Qualification__c(
            Certificate_Language__c = 'English',
            Delegate__c = c.Id,
            Qualification__c = q.Id,
            Show_Transcript_in_Portal__c = false, 
            Show_Certificate_in_Portal__c = false, 
            Show_Logo_in_Portal__c = false, 
            Training_Translations__c = translation.Id
        );
        insert pq;
        return pq;
    }

    
    public static Training_Event__c createTrainingEvent(User uDelegate,Product2 prod){
        Training_Event__c t = new Training_Event__c(Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, 
                End_Date2__c = Date.today() - 8, Max_seats__c = 3, Start_date__c = Date.today() + 8);
        insert t;
        return t;
    }

    public static ContentVersion createContentVersion(){
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Content',
            PathOnClient = 'Content.png',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        return contentVersion;
    }

    public static ContentDocumentLink createContetnDocumentLink(Id contentDocumentId, Id materialId){
        ContentDocumentLink newcontent = new ContentDocumentLink();
        newcontent.ContentDocumentId = contentDocumentId;
        newcontent.LinkedEntityId = materialId;
        newcontent.ShareType =  'v';
        insert newcontent;
        return newContent;
    }

    public static Material_List__c createMaterialList(String materialName, Id productId, Id recordTypeId, Integer order, 
            String materialType, String status){
        Material_List__c materialFile = new Material_List__c(
                    Name = materialName, 
                    Product__c = productId, 
                    RecordTypeId = recordTypeId, 
                    Order__c = order, 
                    Type__c = materialType,
                    Status__c = status);
        insert materialFile;
        return materialFile;
    }

    public static User createCommunityUser(Boolean isInsert, String username, String email, Id profileId, Id contactId){
        User newUser = new User(
            UserName = username,
            FirstName = 'FirstName',
            LastName = 'LastName',
            Alias = 'FL',
            email = email,
            ProfileID = profileId,
            ContactId = contactId,
            LanguageLocaleKey = 'en_GB',
            LocaleSidKey = 'en_GB',
            TimeZoneSidKey = 'Europe/London',
            EmailEncodingKey = Label.BSIUserSettings_EmailEncodingKey,
            BluePrint_Language__c = Label.BSIUserSettings_BluePrintLanguage,
            SalesType__c = Label.BSIUserSettings_SalesType,
            Portal_User_Country__c = 'UK',
            CostCentre__c = 'CLP-DEL',
            BusinessHours__c = 'Default'
        );
        if(isInsert) insert newUser;
        return newUser;
    }
}