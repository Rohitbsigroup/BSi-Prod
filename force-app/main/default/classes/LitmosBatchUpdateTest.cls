@IsTest()
public class LitmosBatchUpdateTest{
     
    @IsTest private static void testEnrollmentsScheduler() 
    {
        createLitmosSetting();
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today(), true, Label.Enrollment_Booking_Status_Booked);
        e.Online_Training_Complete__c = false;
        e.LitmosAccountCreated__c = true;
        e.Online_Training_Attempts__c = 0;
        e.Reason_for_Cancelling_Enrolment__c = null;
        e.Online_Training_Expiry_Date__c = null;
        update e;
        update new Training_Event__c(Id = e.Training_Event__c, Bespoke_Taxonomy__c = 'test');
        Integer currentJobs = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.JobType = '7'];

        Test.StartTest();
        LitmosSchedule sh1 = new LitmosSchedule();
        String sch = '0 0 19 * * ?';
        System.schedule('Test Litmos', sch, sh1);
        Test.stopTest();

        Integer newJobs = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.JobType = '7'];
        System.assertEquals(currentJobs+1,newJobs);
    }

    @IsTest private static void testEnrollmentsUpdate() 
    {
        createLitmosSetting();
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today(), true, Label.Enrollment_Booking_Status_Booked);
        e.Online_Training_Complete__c = false;
        e.LitmosAccountCreated__c = true;
        e.Online_Training_Attempts__c = 0;
        e.Reason_for_Cancelling_Enrolment__c = null;
        e.Online_Training_Expiry_Date__c = null;
        update e;
        update new Training_Event__c(Id = e.Training_Event__c, Bespoke_Taxonomy__c = 'test');

        Test.StartTest();
        LitmosBatchUpdate.LitmosBatchEnrollmentUpdate(new List<Id>{e.Id},'');
        Test.stopTest();

        List<Enrollment__c> enrollments = [SELECT Online_Training_perc_Complete__c,Online_Training_Completed_Date__c,
                                            Online_Training_Complete__c,Online_Training_Attempts__c,Exam_percentage__c,
                                            Online_Training_Expiry_Date__c
                                            FROM Enrollment__c];
        System.assert(!enrollments.isEmpty());
        System.assertEquals(100, enrollments[0].Online_Training_perc_Complete__c);
        System.assertNotEquals(null, enrollments[0].Online_Training_Completed_Date__c);
        System.assert( enrollments[0].Online_Training_Complete__c);
        System.assertEquals(1, enrollments[0].Online_Training_Attempts__c);
        System.assertNotEquals(null,enrollments[0].Online_Training_Expiry_Date__c);
    }

    @IsTest private static void testEnrollmentsUpdateIncorrectQuery() 
    {
        createLitmosSetting('incorrectFilter','incorrectFilter','incorrectFilter','incorrectFilter', 50);
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today(), true, Label.Enrollment_Booking_Status_Booked);
        e.Online_Training_Complete__c = false;
        e.LitmosAccountCreated__c = true;
        e.Online_Training_Attempts__c = 0;
        e.Reason_for_Cancelling_Enrolment__c = null;
        e.Online_Training_Expiry_Date__c = null;
        update e;
        update new Training_Event__c(Id = e.Training_Event__c, Bespoke_Taxonomy__c = 'test');

        Test.StartTest();
        LitmosSchedule sh1 = new LitmosSchedule();
        String sch = '0 0 19 * * ?';
        System.schedule('Test Litmos', sch, sh1);
        Test.stopTest();
        
        List<Enrollment__c> enrollments = [SELECT Online_Training_perc_Complete__c,Online_Training_Completed_Date__c,
                                            Online_Training_Complete__c,Online_Training_Attempts__c,Exam_percentage__c,
                                            Online_Training_Expiry_Date__c
                                            FROM Enrollment__c];
        System.assert(!enrollments.isEmpty());
        System.assertEquals(null, enrollments[0].Online_Training_perc_Complete__c);
        System.assertEquals(null, enrollments[0].Online_Training_Completed_Date__c);
        System.assert( !enrollments[0].Online_Training_Complete__c);
        System.assertEquals(0, enrollments[0].Online_Training_Attempts__c);
        System.assertEquals(null,enrollments[0].Online_Training_Expiry_Date__c);
    }

    @IsTest private static void testEnrollmentsUpdateJobOverLimit() 
    {
        createLitmosSetting('','','','', 1);
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today(), true, Label.Enrollment_Booking_Status_Booked);
        e.Online_Training_Complete__c = false;
        e.LitmosAccountCreated__c = true;
        e.Online_Training_Attempts__c = 0;
        e.Reason_for_Cancelling_Enrolment__c = null;
        e.Online_Training_Expiry_Date__c = null;
        update e;
        update new Training_Event__c(Id = e.Training_Event__c, Bespoke_Taxonomy__c = 'test');

        Test.StartTest();
        String sch = '0 0 19 * * ?';
        System.schedule('Test Litmos', sch, new LitmosSchedule());
        Test.stopTest();
        
        List<Enrollment__c> enrollments = [SELECT Online_Training_perc_Complete__c,Online_Training_Completed_Date__c,
                                            Online_Training_Complete__c,Online_Training_Attempts__c,Exam_percentage__c,
                                            Online_Training_Expiry_Date__c
                                            FROM Enrollment__c];
        System.assert(!enrollments.isEmpty());
        System.assertEquals(null, enrollments[0].Online_Training_perc_Complete__c);
        System.assertEquals(null, enrollments[0].Online_Training_Completed_Date__c);
        System.assert( !enrollments[0].Online_Training_Complete__c);
        System.assertEquals(0, enrollments[0].Online_Training_Attempts__c);
        System.assertEquals(null,enrollments[0].Online_Training_Expiry_Date__c);
    }

    private static void createLitmosSetting(){
        createLitmosSetting('', '', '', '', 50);
    }

    private static void createLitmosSetting(String additionalFilter, String additionalFilter2, String additionalFilter3, 
            String additionalFilter4, Integer batchMaxScheduleJobs){
        LitmosSettings__c litmosSetting = new LitmosSettings__c(
            Additional_filter__c = additionalFilter,
            Additional_filter2__C = additionalFilter2,
            Additional_filter3__C = additionalFilter3,
            Additional_filter4__C = additionalFilter4,
            API__c = 'https://test.test.test',
            API_Key__c = '447c6d82afwfawfawfawfawf',
            Batch_Max_Schedule_Jobs__c = batchMaxScheduleJobs,
            Batch_Update_Email__c = 'test@tisoweifjoweif.coewij',
            Batch_Update_Max_List_Size__c = 10,
            Batch_Update_Second_Delay__c = 20,
            Source__c = 'testSource'
        );
        insert litmosSetting;
    }

    private static Enrollment__c createTestEnrollment(Id eventId, Id translationId, String bookingStatus, Id delegateName, Boolean isInsert){
        Enrollment__c testEnrollment = new Enrollment__c(
            Training_Event__c = eventId,
            Training_Translations__c = translationId,
            Booking_status__c = bookingStatus,
            Delegate_Name__c = delegateName,
            Bookers_Email__c = 'test-booker@test.com',
            Online_Training_Complete__c = false,
            LitmosAccountCreated__c = true,
            Online_Training_Attempts__c = 0,
            Reason_for_Cancelling_Enrolment__c = null,
            Online_Training_Expiry_Date__c = null
        );
        if(isInsert){
            insert testEnrollment;
        }
        return testEnrollment;
    }

}