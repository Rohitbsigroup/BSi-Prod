@isTest
public class EnrollmentEmailServiceSyncTest {

    @isTest
    static void sendEmailTest(){
        Enrollment__c e = TestDataUtility.insertEnrollmentWithDependancies(Date.today() + 5, true, 'Booked');

        Training_Event__c event = [SELECT Course__c FROM Training_Event__c WHERE Id = :e.Training_Event__c];
        event.Mimeo_Distribution_Id__c = 'test';
        update event;

        Product2 course = new Product2(Id = event.Course__c);
        course.Training_Taxonomy_Code__c = 'testUK';
        update course;
    
        Map<String, Set<Id>> emailTypeEnrollmentIdsMap = new Map<String, Set<Id>>();
        emailTypeEnrollmentIdsMap.put(Label.Confirmation_of_Place, new Set<Id>{e.Id});
        
        EnrollmentEmailServiceSync.sendEmail(emailTypeEnrollmentIdsMap);
    }
}