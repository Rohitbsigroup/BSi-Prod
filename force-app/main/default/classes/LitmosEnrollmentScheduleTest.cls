/*
Created By : PC K2 (February 2020)
Test class for LitmosEnrollmentSchedule
*/

@isTest
private class LitmosEnrollmentScheduleTest {

    @isTest static void scheduleTest(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today(), true, Label.Enrollment_Booking_Status_Booked);
        insert new LitmosSettings__c(SetupOwnerId = UserInfo.getOrganizationId(), API_Key__c = 'key', API__c = 'api', Source__c = 'source');

        DateTime dt = DateTime.now().addSeconds(20);
        String cron = String.valueOf(dt.second()) + ' ' + String.valueOf(dt.minute()) + ' ' + String.valueOf(dt.hour()) + ' ' + String.valueOf(dt.day()) + ' ' + String.valueOf(dt.month()) + ' ? ' + String.valueOf(dt.year());
        LitmosEnrollmentSchedule litmosJob = new LitmosEnrollmentSchedule('123', 'email', 'username', 'firstName', 'lastName', 'company', 'taxonomyCode', 'countryCode', 'language', e.Id, null);
        
        Test.startTest();
        System.schedule('Litmos Enrollment', cron, litmosJob);
        Test.stopTest();
    }
}