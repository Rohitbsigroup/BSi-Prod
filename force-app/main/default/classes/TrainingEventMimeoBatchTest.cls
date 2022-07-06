/*
* Training Event Mimeo Batch Test
* Created: PC K2 (May 2020)
*
* changelog 
*/

@isTest
public class TrainingEventMimeoBatchTest {

    @isTest static void scheduleTest(){
        DateTime dt = DateTime.now().addSeconds(20);
        String cron = String.valueOf(dt.second()) + ' ' + String.valueOf(dt.minute()) + ' ' + String.valueOf(dt.hour()) + ' ' + String.valueOf(dt.day()) + ' ' + String.valueOf(dt.month()) + ' ? ' + String.valueOf(dt.year());

        Test.startTest();
            TrainingEventMimeoBatch batch = new TrainingEventMimeoBatch();
            System.schedule('batch', cron, batch);
        Test.stopTest();
    }

    @isTest static void batchTest(){
        insert new Mimeo_Settings__c(API__c = 'test');

        Mimeo_Country_Settings__mdt mcs = [SELECT Distribution_Creation_Days__c FROM Mimeo_Country_Settings__mdt WHERE Label = 'UK'];

        Training_Event__c event = TestDataUtility.insertTrainingEvent(Date.today() + (Integer)mcs.Distribution_Creation_Days__c, true);
        
        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;

        insert new Mimeo_Document__c(Course__c = course.Id, Name = 'active document', Active__c = true);

        Test.startTest();
            TrainingEventMimeoBatch batch = new TrainingEventMimeoBatch();
            Database.executeBatch(batch, 1);
            //Test.stopTest() runs asynchronous processes which are already enqueued/scheduled
            //it will not run subsequent asynchronous processes, so will not run @future createMimeoDistributionBulk()
        Test.stopTest();
    }

    @isTest static void createMimeoDistributionBulkTest(){
        insert new Mimeo_Settings__c(API__c = 'test');

        Mimeo_Country_Settings__mdt mcs = [SELECT Distribution_Creation_Days__c FROM Mimeo_Country_Settings__mdt WHERE Label = 'UK'];

        Training_Event__c event = TestDataUtility.insertTrainingEvent(Date.today() + (Integer)mcs.Distribution_Creation_Days__c, true);

        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;

        insert new Mimeo_Document__c(Course__c = course.Id, Name = 'active document', Active__c = true);

        Test.startTest();
            TrainingEventMimeoBatch.createMimeoDistributionBulk(new List<Id>{event.Id}, null);
        Test.stopTest();

        event = [SELECT Mimeo_Distribution_Assignment__c FROM Training_Event__c WHERE Id = :event.Id];
        System.assert(event.Mimeo_Distribution_Assignment__c);
    }
}