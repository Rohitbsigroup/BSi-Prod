/*
* Created By : PC K2 (July 2020)
* Test class for TrainingEventMimeoBatchUpdateSchedule
*
* changelog
*/

@isTest
private class TrainingEventMimeoBatchUpdateScheduleT {

    @isTest static void scheduleTest(){
        Training_Event__c event = TestDataUtility.insertTrainingEvent(Date.today() + 5, true);
        insert new Mimeo_Settings__c(SetupOwnerId = UserInfo.getOrganizationId(), API__c = 'api');

        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;

        insert new Mimeo_Document__c(Course__c = course.Id, Name = 'test1', Active__c = true);

        List<Id> eventIds = new List<Id>{event.Id};
        DateTime dt = DateTime.now().addSeconds(20);
        String cron = String.valueOf(dt.second()) + ' ' + String.valueOf(dt.minute()) + ' ' + String.valueOf(dt.hour()) + ' ' + String.valueOf(dt.day()) + ' ' + String.valueOf(dt.month()) + ' ? ' + String.valueOf(dt.year());
        TrainingEventMimeoBatchUpdateSchedule mimeoJob = new TrainingEventMimeoBatchUpdateSchedule(eventIds);
        
        Test.startTest();
            System.schedule('Training Event Mimeo Batch Update', cron, mimeoJob);
        Test.stopTest();
    }
}