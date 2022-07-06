@isTest
public class BatchUpdateEnrollmentLoginTest {
    
    @IsTest public static void testBatchUpdateEnrollmentLogin() {
        String testLink = 'https://dev2020-bsiportal.cs126.force.com/training/login/?un=test%40globant5.com&pw=u4gyzLej%40';
        String resultLink = 'https://dev2020-bsiportal.cs126.force.com/training/s/portalaccess?un=test%40globant5.com&pw=u4gyzLej%40';
        Enrollment__c testEnrollment = TestDataUtility.insertEnrollmentWithDependancies(Date.today(), true, 'Booked');
        testEnrollment.Portal_Set_Password_Link__c = testLink;
        update testEnrollment;

        Test.startTest();
        Database.executeBatch(new BatchUpdateEnrollmentLogin(), 2000);
        Test.stopTest();

        List<Enrollment__c> enrollments = [SELECT Portal_Set_Password_Link__c FROM Enrollment__c];
        System.assert(!enrollments.isEmpty());
        System.assertEquals(resultLink,enrollments[0].Portal_Set_Password_Link__c);
    }
}