/*
*  change log
*  PC K2           20-07-18    re-worked test class
*/

@isTest
private class AttendanceRegisterControllerTest{

    @isTest static void testNonSplitEvent(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, Label.Enrollment_Booking_Status_Booked);
        Training_Event__c trainingEvent = [SELECT Id FROM Training_Event__c];

        Test.setCurrentPage(Page.AttendanceSheetWeeklyStretched);
        ApexPages.currentPage().getParameters().put('Id', trainingEvent.Id);

        AttendanceRegisterController controller = new AttendanceRegisterController();
        System.assertEquals(trainingEvent.Id, controller.trainingEvent.Id);
        System.assert(!controller.enrollmentList.isEmpty());
        System.assert(!controller.pageDateList.isEmpty());
    }

    @isTest static void testSplitEvent(){
        TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, Label.Enrollment_Booking_Status_Booked);

        Training_Event__c trainingEvent = [SELECT Id FROM Training_Event__c];
        trainingEvent.Split_Date_Event__c = true;
        trainingEvent.Start_Date__c = Date.today().addDays(1);
        trainingEvent.End_Date_of_Section_1__c = Date.today().addDays(3);
        trainingEvent.Start_Date_of_Section_2__c = Date.today().addDays(5);
        trainingEvent.End_Date2__c = Date.today().addDays(7);
        update trainingEvent;

        Test.setCurrentPage(Page.AttendanceSheetWeeklyStretched);
        ApexPages.currentPage().getParameters().put('Id', trainingEvent.Id);

        AttendanceRegisterController controller = new AttendanceRegisterController();
        System.assertEquals(trainingEvent.Id, controller.trainingEvent.Id);
        System.assert(!controller.enrollmentList.isEmpty());
        System.assert(!controller.pageDateList.isEmpty());
    }
    
}