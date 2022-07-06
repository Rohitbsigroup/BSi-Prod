/**
 * @Name:        CustomPreviewControllerTest
 * @Description: Test Class for CustomPreviewController
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
public class CustomPreviewControllerTest {

    public class Material{
        String materialId;
        String name;
        Decimal order;
        String type;
        String topic;
        String recordTypeName;
        String content;
        String videoUrl;
        String fileId;
        Boolean isDownloadable;
        String fileExtension;

        public Material(String materialId, String name, Decimal order, String type, String topic, String recordTypeName, String content, String videoUrl, String fileId, Boolean isDownloadable, String fileExtension){
            this.materialId = materialId;
            this.name = name;
            this.order = order;
            this.type = type;
            this.topic = topic;
            this.recordTypeName = recordTypeName;
            this.content = content;
            this.videoUrl = videoUrl;
            this.fileId = fileId;
            this.isDownloadable = isDownloadable;
            this.fileExtension = fileExtension;
        }
    }

    /**
	 * Scenario: An enrollment is accessed and the user clicks on the Pre-Course Learning Tile.
	 * Expected Outcome: A list with pre-course learning materials should be displayed.
	 */
    public static testMethod void getMaterialListPreCourseLearningTest(){

        String tileClicked = 'Pre-Course Learning';
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];

        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        string productName1 = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName1);
        prod.Course_Name_English__c = 'English Name Course';
        update prod;

        //create material list records of pre-course learning related to the product
            //file 1
        Id devRecordTypeIdFile = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('File').getRecordTypeId();
        Material_List__c materialFile = new Material_List__c(Name = 'materialFile', Product__c = prod.Id, RecordTypeId = devRecordTypeIdFile, Order__c = 1, Type__c = 'Pre-Course Learning');
        insert materialFile;

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

            //file 2
        Material_List__c materialFile2 = new Material_List__c(Name = 'materialFile2', Product__c = prod.Id, RecordTypeId = devRecordTypeIdFile, Order__c = 2, Type__c = 'Pre-Course Learning');
        insert materialFile2;

        ContentVersion contentVersion_2 = new ContentVersion(
            Title = 'Content',
            PathOnClient = 'Content.doc',
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

            //file 3
        Material_List__c materialFile3 = new Material_List__c(Name = 'materialFile3', Product__c = prod.Id, RecordTypeId = devRecordTypeIdFile, Order__c = 3, Type__c = 'Pre-Course Learning');
        insert materialFile3;

        ContentVersion contentVersion_3 = new ContentVersion(
            Title = 'Content',
            PathOnClient = 'Content.csv',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_3;

        contentVersion_3 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_3.Id LIMIT 1];//query the contentdocumentID

        ContentDocumentLink newcontent3 = new ContentDocumentLink();
        newcontent3.ContentDocumentId = contentVersion_3.ContentDocumentId;
        newcontent3.LinkedEntityId = materialFile3.Id;
        newcontent3.ShareType =  'v';

        insert newcontent3;

        FeedItem feed3 = new FeedItem (
            parentid = materialFile3.id,
            type = 'ContentPost',
            RelatedRecordId = contentVersion_3.id,
            Body = 'Hello'
        );
        insert feed3;

            //file 4
        Material_List__c materialFile4 = new Material_List__c(Name = 'materialFile4', Product__c = prod.Id, RecordTypeId = devRecordTypeIdFile, Order__c = 4, Type__c = 'Pre-Course Learning');
        insert materialFile4;

        ContentVersion contentVersion_4 = new ContentVersion(
            Title = 'Content',
            PathOnClient = 'Content.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_4;

        contentVersion_4 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_4.Id LIMIT 1];//query the contentdocumentID

        ContentDocumentLink newcontent4 = new ContentDocumentLink();
        newcontent4.ContentDocumentId = contentVersion_4.ContentDocumentId;
        newcontent4.LinkedEntityId = materialFile4.Id;
        newcontent4.ShareType =  'v';

        insert newcontent4;

        FeedItem feed4 = new FeedItem (
            parentid = materialFile4.id,
            type = 'ContentPost',
            RelatedRecordId = contentVersion_4.id,
            Body = 'Hello'
        );
        insert feed4;

            //video
        Id devRecordTypeIdVideo = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('Video').getRecordTypeId();
        Material_List__c materialVideo = new Material_List__c(Name = 'materialVideo', Product__c = prod.Id, RecordTypeId = devRecordTypeIdVideo, Order__c = 2, Video_URL__c = 'https://www.youtube.com/embed/olHw-8py9K0', Type__c = 'Pre-Course Learning');
        insert materialVideo;
            //rich text
        Id devRecordTypeIdRichText = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('Rich Text').getRecordTypeId();
        Material_List__c materialRichtext = new Material_List__c(Name = 'materialRichtext', Product__c = prod.Id, RecordTypeId = devRecordTypeIdRichText, Order__c = 3, Type__c = 'Pre-Course Learning', Content__c = 'This is a rich text content.');
        insert materialRichtext;

        //Opportunity oppty = getTestOpty();
        

        //create training event and enrollment
        Training_Event__c t = new Training_Event__c(Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, End_Date2__c = Date.today() - 8, Max_seats__c = 3, Start_date__c = Date.today() + 8);
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

        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Delegate_name__c = contactDelegate.Id, Training_Event__c = t.Id, Booking_status__c = 'Application', Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), Invoice_status__c = 'Completed');    
        insert enr;


        List<Material_List__c> materialList = new List<Material_List__c>();
        Test.startTest();

        System.runAs(uDelegate){
            String listMaterials = CustomPreviewController.getMaterialList(enr.Id, tileClicked);
            materialList = (List<Material_List__c>)System.JSON.deserialize(listMaterials, List<Material_List__c>.class);
        }
        Test.stopTest();

        System.debug(materialList);
        System.assertEquals(6, materialList.size());
        

    }

    /**
	 * Scenario: An enrollment is accessed and the user clicks on the Extra Resources Tile.
	 * Expected Outcome: A list with extra resources materials should be displayed.
	 */
    public static testMethod void getMaterialListExtraResourcesTest(){

        String tileClicked = 'Extra Resources';
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];

        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        string productName1 = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName1);
        prod.Course_Name_English__c = 'English Name Course';
        update prod;

        //create material list records of pre-course learning related to the product
            //file
        Id devRecordTypeIdFile = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('File').getRecordTypeId();
        Material_List__c materialFile = new Material_List__c(Name = 'materialFile', Product__c = prod.Id, RecordTypeId = devRecordTypeIdFile, Order__c = 1, Type__c = 'Extra Resources');
        insert materialFile;

        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'Content',
            PathOnClient = 'Content.xml',
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

            //file 2
        Material_List__c materialFile2 = new Material_List__c(Name = 'materialFile2', Product__c = prod.Id, RecordTypeId = devRecordTypeIdFile, Order__c = 1, Type__c = 'Extra Resources');
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

            //file 3
        Material_List__c materialFile3 = new Material_List__c(Name = 'materialFile3', Product__c = prod.Id, RecordTypeId = devRecordTypeIdFile, Order__c = 1, Type__c = 'Extra Resources');
        insert materialFile3;

        ContentVersion contentVersion_3 = new ContentVersion(
            Title = 'Content',
            PathOnClient = 'Content.png',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_3;

        contentVersion_3 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_3.Id LIMIT 1];//query the contentdocumentID

        ContentDocumentLink newcontent3 = new ContentDocumentLink();
        newcontent3.ContentDocumentId = contentVersion_3.ContentDocumentId;
        newcontent3.LinkedEntityId = materialFile3.Id;
        newcontent3.ShareType =  'v';

        insert newcontent3;

        FeedItem feed3 = new FeedItem (
            parentid = materialFile3.id,
            type = 'ContentPost',
            RelatedRecordId = contentVersion_3.id,
            Body = 'Hello'
        );
        insert feed3;

            //file 4
        Material_List__c materialFile4 = new Material_List__c(Name = 'materialFile4', Product__c = prod.Id, RecordTypeId = devRecordTypeIdFile, Order__c = 1, Type__c = 'Extra Resources');
        insert materialFile4;

        ContentVersion contentVersion_4 = new ContentVersion(
            Title = 'Content',
            PathOnClient = 'Content.xls',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_4;

        contentVersion_4 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_4.Id LIMIT 1];//query the contentdocumentID

        ContentDocumentLink newcontent4 = new ContentDocumentLink();
        newcontent4.ContentDocumentId = contentVersion_4.ContentDocumentId;
        newcontent4.LinkedEntityId = materialFile4.Id;
        newcontent4.ShareType =  'v';

        insert newcontent4;

        FeedItem feed4 = new FeedItem (
            parentid = materialFile4.id,
            type = 'ContentPost',
            RelatedRecordId = contentVersion_4.id,
            Body = 'Hello'
        );
        insert feed4;

            //file 5
        Material_List__c materialFile5 = new Material_List__c(Name = 'materialFile5', Product__c = prod.Id, RecordTypeId = devRecordTypeIdFile, Order__c = 1, Type__c = 'Extra Resources');
        insert materialFile5;

        ContentVersion contentVersion_5 = new ContentVersion(
            Title = 'Content',
            PathOnClient = 'Content.ppt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_5;

        contentVersion_5 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_5.Id LIMIT 1];//query the contentdocumentID

        ContentDocumentLink newcontent5 = new ContentDocumentLink();
        newcontent5.ContentDocumentId = contentVersion_4.ContentDocumentId;
        newcontent5.LinkedEntityId = materialFile5.Id;
        newcontent5.ShareType =  'v';

        insert newcontent5;

        FeedItem feed5 = new FeedItem (
            parentid = materialFile5.id,
            type = 'ContentPost',
            RelatedRecordId = contentVersion_5.id,
            Body = 'Hello'
        );
        insert feed5;


            //video
        Id devRecordTypeIdVideo = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('Video').getRecordTypeId();
        Material_List__c materialVideo = new Material_List__c(Name = 'materialVideo', Product__c = prod.Id, RecordTypeId = devRecordTypeIdVideo, Order__c = 2, Video_URL__c = 'https://www.youtube.com/embed/olHw-8py9K0', Type__c = 'Extra Resources');
        insert materialVideo;
            //rich text
        Id devRecordTypeIdRichText = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('Rich Text').getRecordTypeId();
        Material_List__c materialRichtext = new Material_List__c(Name = 'materialRichtext', Product__c = prod.Id, RecordTypeId = devRecordTypeIdRichText, Order__c = 3, Type__c = 'Extra Resources', Content__c = 'This is a rich text content.');
        insert materialRichtext;


        //create training event and enrollment
        Training_Event__c t = new Training_Event__c(Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, End_Date2__c = Date.today() - 8, Max_seats__c = 3, Start_date__c = Date.today() + 8);
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

        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Delegate_name__c = contactDelegate.Id, Training_Event__c = t.Id, Booking_status__c = 'Application', Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), Invoice_status__c = 'Completed');    
        insert enr;


        List<Material_List__c> materialList = new List<Material_List__c>();
        Test.startTest();

        System.runAs(uDelegate){
            String listMaterials = CustomPreviewController.getMaterialList(enr.Id, tileClicked);
            materialList = (List<Material_List__c>)System.JSON.deserialize(listMaterials, List<Material_List__c>.class);
        }
        Test.stopTest();

        System.debug(materialList);
        System.assertEquals(7, materialList.size());        

    }

    /**
	 * Scenario: An enrollment is accessed and the user clicks on the Extra Resources Tile.
	 * Expected Outcome: A list with extra resources materials should be displayed.
	 */
    public static testMethod void getMaterialListExtraResourcesWithoutArchivesTest(){
        String tileClicked = 'Extra Resources';
        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];
        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        Product2 prod = bg_UnitTestHelper.GetProductFee('ISO 9001');

        Id devRecordTypeIdFile = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('File').getRecordTypeId();
        Material_List__c materialFile = TestDataUtility.createMaterialList('materialFile',prod.Id,devRecordTypeIdFile,1,'Extra Resources','Active');
        ContentVersion contentVersion_1 = TestDataUtility.createContentVersion();
        contentVersion_1 = [SELECT Id, Title, ContentDocumentId 
                            FROM ContentVersion 
                            WHERE Id = :contentVersion_1.Id LIMIT 1];
        ContentDocumentLink newcontent = TestDataUtility.createContetnDocumentLink(contentVersion_1.ContentDocumentId,materialFile.Id);

        //file 2
        Material_List__c materialFile2 = TestDataUtility.createMaterialList('materialFile2',prod.Id,devRecordTypeIdFile,1,'Extra Resources','Archived');
        ContentVersion contentVersion_2 = TestDataUtility.createContentVersion();
        contentVersion_2 = [SELECT Id, Title, ContentDocumentId 
                            FROM ContentVersion 
                            WHERE Id = :contentVersion_2.Id LIMIT 1];
        ContentDocumentLink newcontent2 = TestDataUtility.createContetnDocumentLink(contentVersion_2.ContentDocumentId,materialFile2.Id);

        //file 3
        Material_List__c materialFile3 = TestDataUtility.createMaterialList('materialFile3',prod.Id,devRecordTypeIdFile,1,'Extra Resources','Active');
        ContentVersion contentVersion_3 = TestDataUtility.createContentVersion();
        contentVersion_3 = [SELECT Id, Title, ContentDocumentId 
                            FROM ContentVersion 
                            WHERE Id = :contentVersion_3.Id LIMIT 1];
        ContentDocumentLink newcontent3 = TestDataUtility.createContetnDocumentLink(contentVersion_3.ContentDocumentId,materialFile3.Id);

        //video
        Id devRecordTypeIdVideo = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('Video').getRecordTypeId();
        Material_List__c materialVideo = TestDataUtility.createMaterialList('materialVideo',prod.Id,devRecordTypeIdVideo,2,'Extra Resources','Archived');
        //rich text
        Id devRecordTypeIdRichText = Schema.SObjectType.Material_List__c.getRecordTypeInfosByName().get('Rich Text').getRecordTypeId();
        Material_List__c materialRichtext = TestDataUtility.createMaterialList('materialRichtext',prod.Id,devRecordTypeIdRichText,3,'Extra Resources','');
        //create training event and enrollment
        Training_Event__c t = TestDataUtility.createTrainingEvent(uDelegate,prod);
        Training_Translations__c trainingTransl = TestDataUtility.insertTrainingTranslation();

        Enrollment__c enr = new Enrollment__c(Training_Translations__c = trainingTransl.Id, Delegate_name__c = 
                contactDelegate.Id, Training_Event__c = t.Id, Booking_status__c = 'Application', 
                Online_Training_Expiry_Date__c = Date.today() + 3, Litmos_Details_Emailed__c = Date.today(), 
                Invoice_status__c = 'Completed');    
        insert enr;


        List<Material_List__c> materialList = new List<Material_List__c>();
        Test.startTest();

        System.runAs(uDelegate){
            String listMaterials = CustomPreviewController.getMaterialList(enr.Id, tileClicked);
            materialList = (List<Material_List__c>)System.JSON.deserialize(listMaterials, List<Material_List__c>.class);
        }
        Test.stopTest();

        System.debug(materialList);
        System.assertEquals(3, materialList.size());        

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