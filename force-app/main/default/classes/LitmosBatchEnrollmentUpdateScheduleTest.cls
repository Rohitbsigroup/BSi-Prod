/*
Created By : PC K2 (March 2020)
Test class for LitmosBatchEnrollmentUpdateSchedule
*/

@isTest
private class LitmosBatchEnrollmentUpdateScheduleTest {

    @isTest static void scheduleTest(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today(), true, Label.Enrollment_Booking_Status_Booked);
        insert new LitmosSettings__c(SetupOwnerId = UserInfo.getOrganizationId(), API_Key__c = 'key', API__c = 'api', Source__c = 'source');

        List<Id> enrollmentIds = new List<Id>{e.Id};
        DateTime dt = DateTime.now().addSeconds(20);
        String cron = String.valueOf(dt.second()) + ' ' + String.valueOf(dt.minute()) + ' ' + String.valueOf(dt.hour()) + ' ' + String.valueOf(dt.day()) + ' ' + String.valueOf(dt.month()) + ' ? ' + String.valueOf(dt.year());
        LitmosBatchEnrollmentUpdateSchedule litmosJob = new LitmosBatchEnrollmentUpdateSchedule(enrollmentIds);
        
        Test.startTest();
        System.schedule('Litmos Batch Enrollment Update', cron, litmosJob);
        Test.stopTest();
    }
}