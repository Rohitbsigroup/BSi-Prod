/**
* Author:       Pawel Chrzanowski (K2)
* Date:         08/08/2018
* Description:  test class for EnrollmentEmailService
*
* ******************* Change Log *******************
**/

@isTest
public class EnrollmentEmailServiceTest {

    @isTest
    static void emailServiceTest(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, Label.Enrollment_Booking_Status_Booked);
        Enrollment__c e = [SELECT Training_Translations__c FROM Enrollment__c LIMIT 1];

        //populate Static Resource if available
        List<StaticResource> srList = [SELECT Name FROM StaticResource LIMIT 1];
        if(!srList.isEmpty()){
            update new Training_Translations__c(Id = e.Training_Translations__c, Booking_Confirmation_IH_additional_SR__c = srList[0].Name);
        }

        EnrollmentEmailService ees1 = new EnrollmentEmailService(new Set<Id>{e.Id}, Label.PDF_Certificate);
        EnrollmentEmailService ees2 = new EnrollmentEmailService(new Set<Id>{e.Id}, Label.Confirmation_of_Place);
        EnrollmentEmailService ees3 = new EnrollmentEmailService(new Set<Id>{e.Id}, Label.Resit_Confirmation);
        EnrollmentEmailService ees4 = new EnrollmentEmailService(new Set<Id>{e.Id}, Label.Booking_Confirmation_In_House);
        EnrollmentEmailService ees5 = new EnrollmentEmailService(new Set<Id>{e.Id}, Label.Booking_Confirmation_Bespoke_In_House);
        EnrollmentEmailService ees6 = new EnrollmentEmailService(new Set<Id>{e.Id}, Label.Delivery_Confirmation_ACC);
        EnrollmentEmailService ees7 = new EnrollmentEmailService(new Set<Id>{e.Id}, Label.Delivery_Confirmation_WCC);
        EnrollmentEmailService ees8 = new EnrollmentEmailService(new Set<Id>{e.Id}, Label.Course_Update);

        Test.startTest();
            System.enqueueJob(ees1);
            System.enqueueJob(ees2);
            System.enqueueJob(ees3);
            System.enqueueJob(ees4);
            System.enqueueJob(ees5);
            System.enqueueJob(ees6);
            System.enqueueJob(ees7);
            System.enqueueJob(ees8);
        Test.stopTest();
    }

}