/**
 * @Name:        EnrollmentTilesControllerTest
 * @Description: Test Class for EnrollmentTilesController
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 20/04/2020   Andrei Budescu     Created Class
 */

 
@IsTest
public class EnrollmentTilesControllerTest {

    public class Tile{
        String title;
        String description;
        String url;
        Boolean isClicked;
        String sObjectField;

        public Tile(String title, String description, String url, Boolean isClicked, String sObjectField){
            this.title = title;
            this.description = description;
            this.url = url;
            this.isClicked = isClicked;
            this.sObjectField = sObjectField;
        }

    }

    /**
     * Scenario: An user access an enrollment which has available all the tiles
     * Expected Outcome: List of tiles to display 8 elements.
     */
    public static testMethod void getEnrollmentTilesTest() {
        insert new Automation_Settings__c(Process_Builders_On__c = true);

        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];

        Contact c = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        string productName = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
        prod = [SELECT Id, Course_Duration_Days__c, Course_Name_English__c, Pre_Learning_Material_Count__c FROM Product2 WHERE Id =:prod.Id];
        prod.Course_Duration_Days__c = 10;
        prod.Course_Name_English__c = 'English Name Course';
        System.debug(prod.Id);
        update prod;

        Id devRecordTypeId = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('File').getRecordTypeId();
        System.debug(devRecordTypeId);

        Material_List__c materialFile = new Material_List__c(Name = 'materialFile', Product__c = prod.Id, RecordTypeId = devRecordTypeId, Order__c = 1, Type__c = 'Pre-Course Learning');
        insert materialFile;
        System.debug(materialFile.Product__c);
        System.debug(prod.Pre_Learning_Material_Count__c);

        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Content',
            PathOnClient = 'Content.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_1;

        contentVersion_1 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];//query the contentdocumentID

        ContentDocumentLink newcontent = new ContentDocumentLink();
        newcontent.ContentDocumentId = contentVersion_1.ContentDocumentId;
        newcontent.LinkedEntityId = materialFile.Id;
        newcontent.ShareType =  'v';

        insert newcontent;

        FeedItem feed = new FeedItem (
            parentid = materialFile.id,
            type = 'ContentPost',
            RelatedRecordId = contentVersion_1.id,
            Body = 'Hello'
        );
        insert feed;

        Product2 prod2 = [SELECT Id, Pre_Learning_Material_Count__c FROM Product2 WHERE Id = :prod.Id];
        System.debug(prod2);

        System.debug(feed);

        Material_List__c materialFile2 = new Material_List__c(Name = 'materialFile2', Product__c = prod.Id, RecordTypeId = devRecordTypeId, Order__c = 1, Type__c = 'Extra Resources');
        insert materialFile2;

        ContentVersion contentVersion_2 = new ContentVersion(
            Title = 'Content',
            PathOnClient = 'Content.zip',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_2;

        contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_2.Id LIMIT 1];//query the contentdocumentID

        ContentDocumentLink newcontent2 = new ContentDocumentLink();
        newcontent2.ContentDocumentId = contentVersion_2.ContentDocumentId;
        newcontent2.LinkedEntityId = materialFile2.Id;
        newcontent2.ShareType =  'v';

        insert newcontent2;

        FeedItem feed2 = new FeedItem (
            parentid = materialFile2.id,
            type = 'ContentPost',
            RelatedRecordId = contentVersion_2.id,
            Body = 'Hello'
        );
        insert feed2;

        //create training event and enrollment
        Training_Event__c t = new Training_Event__c(Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, End_Date2__c = Date.today() - 15, Max_seats__c = 3, Start_date__c = Date.today() + 8);
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
        Notification_Post_Course_Survey_Avail__c = 'survey available', Notification_Include_Dietary_Requirement__c = 'include diet req', Notification_Virtual_Training_Login_Test__c = 'login test', Notification_Online_Course_Expiry__c = 'Online course expiry', Notification_Exam_Expiry__c = 'Exam expiry', Notification_Dietary_Req_Immediate__c = 'Change diet req', Notification_Change_of_Dates__c = 'Change of dates', 
        Notification_Change_of_Venue__c = 'Change of venue', Notification_Change_of_Tutor__c = 'Change of tutor', Notification_Certificate_Ready_for_Down__c = 'Cert ready for download', Notification_Course_Materials_Available__c = 'Materials Available', Notification_Complete_PreCourse_Reminder__c = 'Reminder Pre Course', Notification_Pre_Course_Learning_avail__c = 'There are Pre-Course Learning materials available for the following -', 
        Notification_New_ENR_added_to_the_portal__c = 'You have been enrolled into the following -');
        insert trainingTransl;

        Enrollment__c enr = new Enrollment__c(Pre_Course_Questionnaire_Link__c='https://www.google.co.uk', Confirmit_Survey_Link__c = 'https://confirmsurvey.co.uk', Mimeo_Access_Email_Sent__c = true, Certificate_added_to_Portal__c = Date.valueOf('2020-03-17T16:21:11.000+0000'), Training_Translations__c = trainingTransl.Id, Training_Event__c = t.Id, Delegate_name__c = c.Id, Show_Certificate_in_Portal__c = true, Booking_status__c = 'Application', Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), Invoice_status__c = 'Completed');    
        insert enr;
        enr.Learning_Type__c = 'Webinar';
        update enr;

        Enrollment__c enroll = [SELECT Id, Pre_Course_Questionnaire_Link__c, Course_Materials__c, Course_Start_Date__c, Pre_Course_Questionnaire__c, Learning_Type__c, Green_Tile_About_My_Course__c FROM Enrollment__c WHERE Id =:enr.Id LIMIT 1];

        //check the tiles
        Test.startTest();
        String listTiles = EnrollmentTilesController.getEnrollmentTiles(enr.Id);
        List<Tile> tiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        for(Tile tl : tiles){

            if(tl.title == 'About My Course'){
                EnrollmentTilesController.updateGreenTile(enr.Id, String.valueOf(Enrollment__c.Green_Tile_About_My_Course__c.getDescribe().getSObjectField()));
            }
            
            EnrollmentTilesController.updateGreenTile(enr.Id, String.valueOf(Enrollment__c.Green_Tile_Pre_Course_Learning__c.getDescribe().getSObjectField()));
            
        }

        Test.stopTest();

        enroll = [SELECT Id, Course_Start_Date__c, Pre_Course_Questionnaire__c, Learning_Type__c, Green_Tile_About_My_Course__c FROM Enrollment__c WHERE Id =:enr.Id LIMIT 1];
        System.assertEquals(enroll.Green_Tile_About_My_Course__c, true);
    }

    /**
     * Scenario: An user access an enrollment which has available all the tiles
     * Expected Outcome: List of tiles to display 8 elements.
     */
    public static testMethod void getEnrollmentTileAccessMyCourseTest() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];

        Contact c = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        string productName = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
        prod = [SELECT Id, Course_Duration_Days__c, Course_Name_English__c, Pre_Learning_Material_Count__c FROM Product2 WHERE Id =:prod.Id];
        prod.Course_Duration_Days__c = 10;
        prod.Course_Name_English__c = 'English Name Course';
        System.debug(prod.Id);
        update prod;

        //create training event and enrollment
        Training_Event__c t = new Training_Event__c(Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, End_Date2__c = Date.today() - 15, Max_seats__c = 3);
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
        Notification_Post_Course_Survey_Avail__c = 'survey available', Notification_Include_Dietary_Requirement__c = 'include diet req', Notification_Virtual_Training_Login_Test__c = 'login test', Notification_Online_Course_Expiry__c = 'Online course expiry', Notification_Exam_Expiry__c = 'Exam expiry', Notification_Dietary_Req_Immediate__c = 'Change diet req', Notification_Change_of_Dates__c = 'Change of dates', 
        Notification_Change_of_Venue__c = 'Change of venue', Notification_Change_of_Tutor__c = 'Change of tutor', Notification_Certificate_Ready_for_Down__c = 'Cert ready for download', Notification_Course_Materials_Available__c = 'Materials Available', Notification_Complete_PreCourse_Reminder__c = 'Reminder Pre Course', Notification_Pre_Course_Learning_avail__c = 'There are Pre-Course Learning materials available for the following -', 
        Notification_New_ENR_added_to_the_portal__c = 'You have been enrolled into the following -');
        insert trainingTransl;

        Enrollment__c enr = new Enrollment__c(Online_Training_Expiry_Date__c = Date.today(), Confirmit_Survey_Link__c = 'https://confirmsurvey.co.uk', Mimeo_Access_Email_Sent__c = true, Certificate_added_to_Portal__c = Date.valueOf('2020-03-17T16:21:11.000+0000'), Training_Translations__c = trainingTransl.Id, Training_Event__c = t.Id, Delegate_name__c = c.Id, Show_Certificate_in_Portal__c = true, Booking_status__c = 'Application', Litmos_Details_Emailed__c = Date.today(), Invoice_status__c = 'Completed');    
        insert enr;
        enr.Learning_Type__c = 'Online Training';
        update enr;

        //check the tiles
        Test.startTest();
        String listTiles = EnrollmentTilesController.getEnrollmentTiles(enr.Id);
        List<Tile> tiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);

        Test.stopTest();

        //assert - number of tiles available
        //System.assertEquals(7, tiles.size());
    }

    /**
     * Scenario: An user access the enrollment and is able to see 'My Exam' tile
     * Expected Outcome: List of tiles contains 'My Exam' tile
     */
    public static testMethod void getEnrollmentMyExamTileTest() {

        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test2@test.com'];

        Contact c = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        string productName = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName);
        prod = [SELECT Id, Course_Duration_Days__c, Course_Name_English__c FROM Product2 WHERE Id =:prod.Id];
        prod.Course_Name_English__c = 'English Name Course';
        prod.Course_Delivery__c = 'Public';
        prod.Course_Format__c = 'E-Learning';
        prod.Training_Product_Type__c = 'Exam';
        update prod;

        //create training event and enrollment
        Training_Event__c t = new Training_Event__c(Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, End_Date2__c = Date.today() - 8, Max_seats__c = 3,Event_Confirmed__c=true, Start_date__c = Date.today() + 8);
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
        Notification_Post_Course_Survey_Avail__c = 'survey available', Notification_Include_Dietary_Requirement__c = 'include diet req', Notification_Virtual_Training_Login_Test__c = 'login test', Notification_Online_Course_Expiry__c = 'Online course expiry', Notification_Exam_Expiry__c = 'Exam expiry', Notification_Dietary_Req_Immediate__c = 'Change diet req', Notification_Change_of_Dates__c = 'Change of dates', 
        Notification_Change_of_Venue__c = 'Change of venue', Notification_Change_of_Tutor__c = 'Change of tutor', Notification_Certificate_Ready_for_Down__c = 'Cert ready for download', Notification_Course_Materials_Available__c = 'Materials Available', Notification_Complete_PreCourse_Reminder__c = 'Reminder Pre Course', Notification_Pre_Course_Learning_avail__c = 'There are Pre-Course Learning materials available for the following -', 
        Notification_New_ENR_added_to_the_portal__c = 'You have been enrolled into the following -');
        insert trainingTransl;

        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Training_Event__c = t.Id, Delegate_name__c = c.Id, Online_Training_Attempts__c = 1, Booking_status__c = 'Application', Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), Active_Litmos_Enrollment__c = true , Invoice_status__c = 'Completed');    
        insert enr;
        enr.Learning_Type__c = 'Online Exam';
        update enr;
        Enrollment__c enroll = [SELECT Id, Course_Materials__c, Course_Start_Date__c, Pre_Course_Questionnaire__c, Learning_Type__c, Learning_Type_Formula__c, Green_Tile_About_My_Course__c FROM Enrollment__c WHERE Id =:enr.Id LIMIT 1];
        System.debug(enroll);
    
        //check the tiles
        Boolean containsMyExamTile = false;
        Test.startTest();
        String listTiles = EnrollmentTilesController.getEnrollmentTiles(enr.Id);
        List<Tile> tiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        for(Tile tl : tiles){
            if(tl.title == Label.CLP_MyExam_TileTitle){
                containsMyExamTile = true;
            }
        }

        Test.stopTest();
        System.assertEquals(containsMyExamTile, true);
    }

    public static testMethod void getUrlSubstringExceptionTest() {

        Test.startTest();
        EnrollmentTilesController.getUrlSubstring(null);
        Test.stopTest();

    }

    /**
     * Scenario: An user access the enrollment and is able to see 'My Exam' tile
     * Expected Outcome: List of tiles contains 'My Exam' tile
     */
    public static testMethod void getEnrollmentExtraResourceTileTest() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test2@test.com'];
        Contact c = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = bg_UnitTestHelper.GetProductFee('ISO 9001');
        Training_Event__c t = TestDataUtility.createTrainingEvent(uDelegate,prod);
        Training_Translations__c trainingTransl = TestDataUtility.insertTrainingTranslation();
        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Training_Event__c = t.Id, 
            Delegate_name__c = c.Id, Online_Training_Attempts__c = 1, Booking_status__c = 'Application', 
            Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), 
            Active_Litmos_Enrollment__c = true , Invoice_status__c = 'Completed',Learning_Type__c = 'Online Exam');    
        insert enr;
        Id devRecordTypeIdRichText = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('Rich Text').getRecordTypeId();
        Material_List__c materialRichtext = TestDataUtility.createMaterialList('materialRichtext',prod.Id,devRecordTypeIdRichText,3,
                'Extra Resources','');
        materialRichtext = TestDataUtility.createMaterialList('materialRichtext',prod.Id,devRecordTypeIdRichText,3,
                'Pre-Course Learning','');
        
        Test.startTest();
        String listTiles = EnrollmentTilesController.getEnrollmentTiles(enr.Id);
        List<Tile> tiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        Test.stopTest();

        Boolean containsTile = false;
        for(Tile tl : tiles){
            if(tl.title == Label.CLP_ExtraResources_TileTitle){
                containsTile = true;
            }
            System.debug('##### tile:' + tl);
        }
        System.assertEquals(containsTile, true);
    }

    /**
     * Scenario: An user access the enrollment and is able to see 'My Exam' tile
     * Expected Outcome: List of tiles contains 'My Exam' tile
     */
    public static testMethod void getEnrollmentExtraResourceTileNoResourceTest() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test2@test.com'];
        Contact c = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = bg_UnitTestHelper.GetProductFee('ISO 9001');
        Training_Event__c t = TestDataUtility.createTrainingEvent(uDelegate,prod);
        Training_Translations__c trainingTransl = TestDataUtility.insertTrainingTranslation();
        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Training_Event__c = t.Id, 
            Delegate_name__c = c.Id, Online_Training_Attempts__c = 1, Booking_status__c = 'Application', 
            Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), 
            Active_Litmos_Enrollment__c = true , Invoice_status__c = 'Completed',Learning_Type__c = 'Online Exam');    
        insert enr;
        Id devRecordTypeIdRichText = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('Rich Text').getRecordTypeId();
        //Material_List__c materialRichtext = TestDataUtility.createMaterialList('materialRichtext',prod.Id,devRecordTypeIdRichText,3,
        //        'Extra Resources','');
        Material_List__c materialRichtext = TestDataUtility.createMaterialList('materialRichtext',prod.Id,devRecordTypeIdRichText,3,
                'Pre-Course Learning','');
        
        Test.startTest();
        String listTiles = EnrollmentTilesController.getEnrollmentTiles(enr.Id);
        List<Tile> tiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        Test.stopTest();

        Boolean containsTile = false;
        for(Tile tl : tiles){
            if(tl.title == Label.CLP_ExtraResources_TileTitle){
                containsTile = true;
            }
            System.debug('##### tile:' + tl);
        }
        System.assertEquals(containsTile, false);
    }

    /**
     * Scenario: An user access the enrollment and is able to see 'My Exam' tile
     * Expected Outcome: List of tiles contains 'My Exam' tile
     */
    public static testMethod void getEnrollmentPreCourseTileTest() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test2@test.com'];
        Contact c = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = bg_UnitTestHelper.GetProductFee('ISO 9001');
        Training_Event__c t = TestDataUtility.createTrainingEvent(uDelegate,prod);
        Training_Translations__c trainingTransl = TestDataUtility.insertTrainingTranslation();
        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Training_Event__c = t.Id, 
            Delegate_name__c = c.Id, Online_Training_Attempts__c = 1, Booking_status__c = 'Application', 
            Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), 
            Active_Litmos_Enrollment__c = true , Invoice_status__c = 'Completed',Learning_Type__c = 'Online Exam');    
        insert enr;
        Id devRecordTypeIdRichText = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('Rich Text').getRecordTypeId();
        Material_List__c materialRichtext = TestDataUtility.createMaterialList('materialRichtext',prod.Id,devRecordTypeIdRichText,3,
                'Pre-Course Learning','');
        
        Test.startTest();
        String listTiles = EnrollmentTilesController.getEnrollmentTiles(enr.Id);
        List<Tile> tiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        Test.stopTest();

        Boolean containsTile = false;
        for(Tile tl : tiles){
            if(tl.title == Label.CLP_PreCourseLearningMaterials_TileTitle){
                containsTile = true;
            }
            System.debug('##### tile:' + tl);
        }
        System.assertEquals(containsTile, true);
    }

    /**
     * Scenario: An user access the enrollment and is able to see 'My Exam' tile
     * Expected Outcome: List of tiles contains 'My Exam' tile
     */
    public static testMethod void getEnrollmentPreCourseTileNoResourceTest() {
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test2@test.com'];
        Contact c = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = bg_UnitTestHelper.GetProductFee('ISO 9001');
        Training_Event__c t = TestDataUtility.createTrainingEvent(uDelegate,prod);
        Training_Translations__c trainingTransl = TestDataUtility.insertTrainingTranslation();
        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Training_Event__c = t.Id, 
            Delegate_name__c = c.Id, Online_Training_Attempts__c = 1, Booking_status__c = 'Application', 
            Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), 
            Active_Litmos_Enrollment__c = true , Invoice_status__c = 'Completed',Learning_Type__c = 'Online Exam');    
        insert enr;
        Id devRecordTypeIdRichText = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('Rich Text').getRecordTypeId();
        //Material_List__c materialRichtext = TestDataUtility.createMaterialList('materialRichtext',prod.Id,devRecordTypeIdRichText,3,
         //       'Pre-Course Learning','');
        
        Test.startTest();
        String listTiles = EnrollmentTilesController.getEnrollmentTiles(enr.Id);
        List<Tile> tiles = (List<Tile>)System.JSON.deserialize(listTiles, List<Tile>.class);
        Test.stopTest();

        Boolean containsTile = false;
        for(Tile tl : tiles){
            if(tl.title == Label.CLP_PreCourseLearningMaterials_TileTitle){
                containsTile = true;
            }
            System.debug('##### tile:' + tl);
        }
        System.assertEquals(containsTile, false);
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