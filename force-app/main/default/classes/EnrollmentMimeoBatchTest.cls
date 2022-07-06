/*
* Enrollment Mimeo Batch Test
* Created: PC K2 (May 2020)
*
* changelog 
*/

@isTest
public class EnrollmentMimeoBatchTest {

    @isTest static void scheduleTest(){
        DateTime dt = DateTime.now().addSeconds(20);
        String cron = String.valueOf(dt.second()) + ' ' + String.valueOf(dt.minute()) + ' ' + String.valueOf(dt.hour()) + ' ' + String.valueOf(dt.day()) + ' ' + String.valueOf(dt.month()) + ' ? ' + String.valueOf(dt.year());

        Test.startTest();
            EnrollmentMimeoBatch batch = new EnrollmentMimeoBatch();
            System.schedule('batch', cron, batch);
        Test.stopTest();
    }

    @isTest static void batchTest(){
        insert new Mimeo_Settings__c(API__c = 'test');

        Mimeo_Country_Settings__mdt mcs = [SELECT Key_Assignment_Days__c FROM Mimeo_Country_Settings__mdt WHERE Label = 'UK'];

        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + (Integer)mcs.Key_Assignment_Days__c, true, 'Booked');

        Training_Event__c event = [SELECT Course__c FROM Training_Event__c WHERE Id = :e.Training_Event__c];
        event.Mimeo_Distribution_Created_Date__c = DateTime.now();
        update event;

        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;

        insert new Mimeo_Document__c(Course__c = course.Id, Name = 'active document', Active__c = true);

        Test.startTest();
            EnrollmentMimeoBatch batch = new EnrollmentMimeoBatch();
            Database.executeBatch(batch, 1);
            //Test.stopTest() runs asynchronous processes which are already enqueued/scheduled
            //it will not run subsequent asynchronous processes, so will not run @future assignMimeoKeysToUsersBulk()
        Test.stopTest();
    }

    @isTest static void assignMimeoKeysToUsersBulkTest(){
        insert new Mimeo_Settings__c(API__c = 'test');

        Mimeo_Country_Settings__mdt mcs = [SELECT Key_Assignment_Days__c FROM Mimeo_Country_Settings__mdt WHERE Label = 'UK'];

        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + (Integer)mcs.Key_Assignment_Days__c, true, 'Booked');

        Training_Event__c event = [SELECT Course__c FROM Training_Event__c WHERE Id = :e.Training_Event__c];
        event.Mimeo_Distribution_Created_Date__c = DateTime.now();
        event.Mimeo_Distribution_Id__c = '001';
        update event;

        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;

        insert new Mimeo_Document__c(Course__c = course.Id, Name = 'active document', Active__c = true);

        Test.startTest();
            EnrollmentMimeoBatch.assignMimeoKeysToUsersBulk(new List<Id>{e.Id}, null);
        Test.stopTest();
        
        e = [SELECT Mimeo_Key_Assignment__c FROM Enrollment__c WHERE Id = :e.Id];
        System.assert(e.Mimeo_Key_Assignment__c);
    }
}