/*
* Created By : PC K2 (July 2020)
* Test class for EnrollmentMimeoBatchUpdateSchedule
*
* changelog
*/

@isTest
private class EnrollmentMimeoBatchUpdateScheduleTest {

    @isTest static void scheduleTest(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today(), true, Label.Enrollment_Booking_Status_Booked);
        insert new Mimeo_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), API__c = 'api');

        List<Id> enrollmentIds = new List<Id>{e.Id};
        DateTime dt = DateTime.now().addSeconds(20);
        String cron = String.valueOf(dt.second()) + ' ' + String.valueOf(dt.minute()) + ' ' + String.valueOf(dt.hour()) + ' ' + String.valueOf(dt.day()) + ' ' + String.valueOf(dt.month()) + ' ? ' + String.valueOf(dt.year());
        EnrollmentMimeoBatchUpdateSchedule mimeoJob = new EnrollmentMimeoBatchUpdateSchedule(enrollmentIds);
        
        Test.startTest();
            System.schedule('Enrollment Mimeo Batch Update', cron, mimeoJob);
        Test.stopTest();
    }
}