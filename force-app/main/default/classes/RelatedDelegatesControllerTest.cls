@IsTest
public with sharing class RelatedDelegatesControllerTest {
    
    @IsTest public static void areChildDelegatesReturnedSuccess(){
        Product2 testCourse = bg_TrainingUnitTestHelper.CreateProductTraining('testCouse1','EUR');
        insert testCourse;
        Contact testContact = bg_UnitTestHelper.CreateContact('TestLastName1',null);
        insert testContact;
        Training_Event__c masterEvent = createTrainingEvent('GB','Active',testCourse,testContact);
        insert masterEvent;
        List<Training_Event__c> childEvents = new List<Training_Event__c>();
        childEvents.add(createTrainingEvent('GB','Active',testCourse,testContact,'',masterEvent.Id));
        childEvents.add(createTrainingEvent('CN','Active',testCourse,testContact,'SW',masterEvent.Id));
        insert childEvents;

        Test.startTest();
        String result = RelatedDelegatesController.getChildEvents(masterEvent.Id);
        Test.stopTest();

        List<RelatedDelegatesController.EventDTO> results = (List<RelatedDelegatesController.EventDTO>)JSON.deserialize(RESULT, List<RelatedDelegatesController.EventDTO>.class);
        System.assertEquals(childEvents.size(),results.size());
    }
  
    @IsTest public static void shouldNotShowCancelledEvents(){
        Product2 testCourse = bg_TrainingUnitTestHelper.CreateProductTraining('testCouse1','EUR');
        insert testCourse;
        Contact testContact = bg_UnitTestHelper.CreateContact('TestLastName1',null);
        insert testContact;
        Training_Event__c masterEvent = createTrainingEvent('GB','Active',testCourse,testContact);
        insert masterEvent;
        List<Training_Event__c> childEvents = new List<Training_Event__c>();
        childEvents.add(createTrainingEvent('GB','Active',testCourse,testContact,'',masterEvent.Id));
        childEvents.add(createTrainingEvent('CN','Active',testCourse,testContact,'SW',masterEvent.Id));
        insert childEvents;
        List<Training_Event__c> childEventsCancelled = new List<Training_Event__c>();
        childEventsCancelled.add(createTrainingEvent('GB','Cancelled',testCourse,testContact,'',masterEvent.Id));
        insert childEventsCancelled;

        Test.startTest();
        String result = RelatedDelegatesController.getChildEvents(masterEvent.Id);
        Test.stopTest();

        List<RelatedDelegatesController.EventDTO> results = (List<RelatedDelegatesController.EventDTO>)JSON.deserialize(RESULT, List<RelatedDelegatesController.EventDTO>.class);
        System.assertEquals(childEvents.size(),results.size());
    }


    //Helper methods
    private static Training_Event__c createTrainingEvent(String BespokeTaxonomy, String status, 
            Product2 testCourse, Contact testContact){
        return createTrainingEvent(BespokeTaxonomy,status,testCourse,testContact,'',null);
    }
    
    private static Training_Event__c createTrainingEvent(String BespokeTaxonomy, String status, 
            Product2 testCourse, Contact testContact, String region, String masterEventId){
        Training_Event__c trainingEvent = bg_TrainingUnitTestHelper.getTrainingEvent(
            bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'EUR'), 
            'EUR', 10, testCourse, Date.today()+5, testContact.Id);
        trainingEvent.Bespoke_Taxonomy__c = BespokeTaxonomy;
        trainingEvent.Event_status__c = status;
        if(!String.isBlank(region))  trainingEvent.China_Region__c = region;
        if(!String.isBlank(masterEventId))  trainingEvent.Master_Training_Event__c = masterEventId;
        return trainingEvent;
    }

    private static Enrollment__c createEnrollment(String delegateContactId,String trainingTranslationsId,String trainingEventId,
            String bookingStatus){
        Enrollment__c enrollment = new Enrollment__c();
        enrollment.Delegate_name__c = delegateContactId;
        enrollment.Training_Translations__c = trainingTranslationsId;
        enrollment.Email_Confirmation_Sent__c = true;
        enrollment.Booking_status__c = bookingStatus;
        enrollment.Training_Event__c = trainingEventId;
        enrollment.Email_Confirmation_Sent__c = false;
        enrollment.Email_Reminder_Sent__c = false;
        enrollment.Certificate_Printed__c = false;
        enrollment.Email_PDF_Certificate__c = false;
        enrollment.Certificate_status__c = 'Not required'; 
        return enrollment;
    }

}