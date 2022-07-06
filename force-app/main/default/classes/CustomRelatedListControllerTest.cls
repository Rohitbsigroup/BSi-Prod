/**
 * @Name:        CustomRelatedListControllerTest
 * @Description: This class handles the test for the CustomRelatedListController class
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
public class CustomRelatedListControllerTest {


    //Wrapper class for the request
    public class RelatedListRequest {

        public String recordId;
        public String type;
        public String fieldsString;
        public String objectString;
        public String parentObject;
        public String whereString;
        public String orderByString;
        public String editableFields;
        public String urlExtension;

        public RelatedListRequest trim() {

            recordId = trimValue(recordId);
            type = trimValue(type);
            fieldsString = trimValue(fieldsString);
            objectString = trimValue(objectString);
            parentObject = trimValue(parentObject);
            whereString = trimValue(whereString);
            orderByString = trimValue(orderByString);
            editableFields = trimValue(editableFields);
            urlExtension = trimValue(urlExtension);

            return this;
        }

        private String trimValue(String value) {
            if(String.isBlank(value)) {
                value = Constants.BLANK_STRING;
            }

            return value.trim();
        }

    }

    /**
     * RelatedListResponse Wrapper class to return data from Apex to c:customRelatedList Aura component
     */
    public class RelatedListResponse {

        @AuraEnabled public List<Object> columns { get; private set; }
        @AuraEnabled public List<Object> data { get; private set; }

        public RelatedListResponse(List<Object> columns, List<Object> data) {
            this.columns = columns;
            this.data = data;
        }

    }

    /**
	 * Scenario: 
	 * Expected Outcome: 
	 */
    public static testMethod void initialiseComponentRelatedListViewTest() {
        String fields = 'Certificate_added_to_Portal__c, Delegate_name__r.About_Tutor_Profile_Populated__c, Delegate_name__r.Confirmation_Days_Needed__c, Delegate_name__r.Salutation,Delegate_name__r.FirstName,Delegate_name__r.LastName, Delegate_name__r.Email,Delegate_name__r.Dietary_Requirements__c, Booking_status__c, Delegate_Company_Name__c, Attendance_Marked__c, Continuous_Assessment__c, Exam_Mark__c, Inhouse_Booking_Contact__c, Delegate_name__r.User_Last_Login_Date__c'; //fields to display - columns
        List<String> fieldsList = fields.replaceAll('\\s+', '').split(',');

        
        Enrollment__c enrollment = [SELECT Id, Certificate_added_to_Portal__c, Delegate_name__r.FirstName, Delegate_name__r.Confirmation_Days_Needed__c, Delegate_name__r.About_Tutor_Profile_Populated__c, Booking_status__c, Inhouse_Booking_Contact__c FROM Enrollment__C LIMIT 1];
        System.debug(enrollment);

        Training_Event__c trainingEvent = [SELECT Id FROM Training_Event__c LIMIT 1];
        System.debug(trainingEvent);

        //create request
        RelatedListRequest request = new RelatedListRequest();
        request.recordId = trainingEvent.Id; //training event record id
        request.fieldsString = fields;
        request.type = 'Related List';
        request.objectString = 'Enrollment__c'; //enrollment linked object
        request.parentObject = 'Training_Event__c';
        request.whereString = 'Booking_status__c=' + '\'' + 'Booked'+ '\''; //filter
        request.orderByString = 'CreatedDate DESC';
        request.editableFields = 'Continuous_Assessment__c, Attendance_Marked__c, Exam_Mark__c,Inhouse_Booking_Contact__c, Delegate_name__r.Confirmation_Days_Needed__c'; //field to be edited
        System.debug(request);
        System.debug(JSON.serialize(request));

        List<Object> columnsDataTable = new List<Object>();
        List<Object> rowsDataTable = new List<Object>();

        Test.startTest();
        String response = CustomRelatedListController.initialiseComponent(JSON.serialize(request));
        System.debug(response);
        System.debug(JSON.deserializeUntyped(response));

        Map<String, Object> mapDataTable = (Map<String, Object>)JSON.deserializeUntyped(response);
        System.debug(mapDataTable);
        for(String key : mapDataTable.keySet()){
            if(key == 'columns'){
                columnsDataTable = (List<Object>) mapDataTable.get(key);
            }else if(key == 'data'){
                rowsDataTable = (List<Object>) mapDataTable.get(key);
            }
        }
        System.debug(columnsDataTable.size());
        System.debug(rowsDataTable.size());
        
        Test.stopTest();

        //system asserts 
        //1. number of columns 
        System.debug(columnsDataTable.size());
        System.debug(fieldsList.size());
        System.assertEquals(fieldsList.size(), columnsDataTable.size());

        //2. number of rows
        System.assertEquals(rowsDatatable.size(), 1);//number of enrollments

    }

    public static testMethod void updateRecordsTest() {
        String fields = 'Certificate_added_to_Portal__c, Delegate_name__r.About_Tutor_Profile_Populated__c, Delegate_name__r.Confirmation_Days_Needed__c, Delegate_name__r.Salutation,Delegate_name__r.FirstName,Delegate_name__r.LastName, Delegate_name__r.Email,Delegate_name__r.Dietary_Requirements__c, Booking_status__c, Delegate_name__r.Company__c, Attendance_Marked__c, Continuous_Assessment__c, Exam_Mark__c, Inhouse_Booking_Contact__c, Delegate_name__r.User_Last_Login_Date__c'; //fields to display - columns
        List<String> fieldsList = fields.replaceAll('\\s+', '').split(',');

        Enrollment__c enrollment = [SELECT Id, Certificate_added_to_Portal__c, Delegate_name__r.FirstName, Delegate_name__r.Confirmation_Days_Needed__c, Delegate_name__r.About_Tutor_Profile_Populated__c, Booking_status__c, Inhouse_Booking_Contact__c FROM Enrollment__C LIMIT 1];
        System.debug(enrollment);
        System.debug('Value before update: ' + enrollment.Inhouse_Booking_Contact__c);
        System.debug('Value before update first name: ' + enrollment.Delegate_name__r.FirstName);
        System.debug(enrollment.Id);

        Training_Event__c trainingEvent = [SELECT Id FROM Training_Event__c LIMIT 1];
        System.debug(trainingEvent);

        //create request
        RelatedListRequest request = new RelatedListRequest();
        request.recordId = trainingEvent.Id; //training event record id
        request.fieldsString = fields;
        request.objectString = 'Enrollment__c'; //enrollment linked object
        request.parentObject = 'Training_Event__c';
        request.whereString = 'Booking_status__c=' + '\'' + 'Booked'+ '\''; //filter
        request.orderByString = 'CreatedDate DESC';
        request.editableFields = 'Continuous_Assessment__c, Attendance_Marked__c, Exam_Mark__c,Inhouse_Booking_Contact__c, Delegate_name__r.Confirmation_Days_Needed__c'; //field to be edited

        String draftValues = '[{"Exam_Mark__c":"10.2","Inhouse_Booking_Contact__c":false,"Delegate_name__rFirstName":"AndreiTT","id":"row-0","recordId":"' + enrollment.Id + '"}]';
        System.debug(draftValues);

        Test.startTest();
        //update enrollment field
        CustomRelatedListController.updateRecords(draftValues, request.fieldsString, request.objectString);
        
        Test.stopTest();

        Enrollment__c enrollmentAfter = [SELECT Id, Delegate_name__r.FirstName, Delegate_name__r.Confirmation_Days_Needed__c, Delegate_name__r.About_Tutor_Profile_Populated__c, Booking_status__c, Inhouse_Booking_Contact__c FROM Enrollment__C LIMIT 1];
        System.debug('Value after update: ' + enrollmentAfter.Inhouse_Booking_Contact__c);
        System.debug('Value after update first name: ' + enrollmentAfter.Delegate_name__r.FirstName);

        //System assert
        //3. value of field after update
        System.assertEquals(enrollmentAfter.Inhouse_Booking_Contact__c, enrollment.Inhouse_Booking_Contact__c);
    }

    /**
	 * Scenario: 
	 * Expected Outcome: 
	 */
    public static testMethod void initialiseComponentListViewTest() {
        String fields = 'Certificate_added_to_Portal__c, Delegate_name__r.About_Tutor_Profile_Populated__c, Delegate_name__r.Confirmation_Days_Needed__c, Delegate_name__r.Salutation,Delegate_name__r.FirstName,Delegate_name__r.LastName, Delegate_name__r.Email,Delegate_name__r.Dietary_Requirements__c, Booking_status__c, Delegate_name__r.Company__c, Attendance_Marked__c, Continuous_Assessment__c, Exam_Mark__c, Inhouse_Booking_Contact__c, Delegate_name__r.User_Last_Login_Date__c'; //fields to display - columns
        List<String> fieldsList = fields.replaceAll('\\s+', '').split(',');

        Enrollment__c enrollment = [SELECT Id, Certificate_added_to_Portal__c, Delegate_name__r.FirstName, Delegate_name__r.Confirmation_Days_Needed__c, Delegate_name__r.About_Tutor_Profile_Populated__c, Booking_status__c, Inhouse_Booking_Contact__c FROM Enrollment__C LIMIT 1];
        System.debug(enrollment);
        System.debug('Value before update: ' + enrollment.Inhouse_Booking_Contact__c);
        System.debug('Value before update first name: ' + enrollment.Delegate_name__r.FirstName);
        System.debug(enrollment.Id);

        Training_Event__c trainingEvent = [SELECT Id FROM Training_Event__c LIMIT 1];
        System.debug(trainingEvent);

        //create request
        RelatedListRequest request = new RelatedListRequest();
        request.fieldsString = fields;
        request.type = 'List View';
        request.objectString = 'Enrollment__c'; //enrollment linked object
        request.whereString = 'Booking_status__c=' + '\'' + 'Booked'+ '\'';//filter
        request.orderByString = 'CreatedDate DESC';
        request.urlExtension = 'enrollment';
        
        System.debug(request);
        System.debug(JSON.serialize(request));

        List<Object> columnsDataTable = new List<Object>();
        List<Object> rowsDataTable = new List<Object>();

        Test.startTest();
        String response = CustomRelatedListController.initialiseComponent(JSON.serialize(request));
        System.debug(response);
        System.debug(JSON.deserializeUntyped(response));

        Map<String, Object> mapDataTable = (Map<String, Object>)JSON.deserializeUntyped(response);
        System.debug(mapDataTable);
        for(String key : mapDataTable.keySet()){
            if(key == 'columns'){
                columnsDataTable = (List<Object>) mapDataTable.get(key);
            }else if(key == 'data'){
                rowsDataTable = (List<Object>) mapDataTable.get(key);
            }
        }
        System.debug(columnsDataTable.size());
        System.debug(rowsDataTable.size());
        
        Test.stopTest();

        //system asserts 
        //1. number of columns 
        System.debug(columnsDataTable.size());
        System.debug(fieldsList.size());
        System.assertEquals(fieldsList.size(), columnsDataTable.size());

        //2. number of rows
        System.assertEquals(rowsDatatable.size(), 1);//number of enrollments

    }



    @TestSetup 
    private static void generateOrgData(){

        Account a = new Account(Name = 'test', BillingCountry = 'GB');
        insert a;

        Contact c = new Contact(AccountId = a.Id, Salutation = 'Prof.', FirstName = 'FirstNameTest', LastName = 'LastNameTest',
                    Email = 'test@test.com', Dietary_Requirements__c = 'Allergy (general)',  Company__c = 'CompanyTest', Confirmation_Days_Needed__c = 10,
                    User_Last_Login_Date__c = Date.valueOf('2020-03-17T16:21:11.000+0000'), About_Tutor_Profile_Populated__c = true, MailingCountry = 'GB');
		insert c;

		List<Contact> contacts1 = [SELECT Id,Phone, Salutation, FirstName, LastName, Email, Dietary_Requirements__c, Company__c, User_Last_Login_Date__c FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
		
        List<User> users = TestData.createPortalUsers(contacts1, true);

        User uDelegate = [SELECT Id, Email FROM User WHERE Email = 'test@test.com'];

        Contact contactDelegate = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];

        string productName1 = 'ISO 9001';
        Product2 prod = bg_UnitTestHelper.GetProductFee(productName1);
        prod.Course_Name_English__c = 'English Name Course';
        update prod;

        //create training event and enrollment
        Training_Event__c t = new Training_Event__c(Course_returns__c = 'Not required', Opportunity_Owner__c = uDelegate.Id, Course__c = prod.Id, End_Date2__c = Date.today() - 8, Max_seats__c = 3, Start_date__c = Date.today() + 8);
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
        
        
        Enrollment__c e = new Enrollment__c(Training_Event__c = t.Id, Delegate_name__c = c.Id, Booking_status__c = 'Booked',
                Continuous_Assessment__c = false, Exam_Mark__c = 10, Inhouse_Booking_Contact__c = false, Attendance_Marked__c = false, 
                Training_Translations__c = trainingTransl.Id, Certificate_added_to_Portal__c = Date.valueOf('2020-03-17T16:21:11.000+0000'));    
        insert e;

        

        
	
	}

}