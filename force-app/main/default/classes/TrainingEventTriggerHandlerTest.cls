/**
* Author:       Pawel Chrzanowski (K2)
* Date:         31/08/2018
* Description:  test class for TrainingEventTriggerHandler
*
* 20200523 PC Adjusted for changes to set Event confirmed for UK CLL events as well as ILT
* ******************* Change Log *******************
**/

@isTest
public class TrainingEventTriggerHandlerTest {

    @isTest static void onBeforeInsertTest(){
        RecordType rt = [SELECT Id FROM RecordType WHERE Name = :Label.UK_Public_Event];
    
        Training_Venue__c masterv = new Training_Venue__c(Name = 'UK Master', CurrencyIsoCode = 'GBP', Public_Venue__c = true);
        insert masterv;

        Training_Venue__c trainingv = new Training_Venue__c(Name = 'Training Venue', CurrencyIsoCode = 'GBP', Public_Venue__c = true, Training_Office__c = masterv.Id, Venue_Day_Rate__c = 100, Venue_Day_Delegate_Rate__c = 100, Venue_Residential_Delegate_Rate__c = 100, Venue_SAP_Ship_To__c = '12345');
        insert trainingv;

        Contact instructor = new Contact(FirstName = 'test', LastName = 'test', Internal_Instructor__c = true, MailingCountry = 'GB', Email = 'email@email.com', RecordTypeId = bg_RecordTypeUtils.GetRecordTypes(bg_RecordTypeUtils.OBJECT_NAME_CONTACT).get(bg_ContactUtils.RECORD_TYPE_NAME_CLIENTS).Id, I_Codes_text__c = 'ICODES', Country_Office__c = masterv.Id);
        insert instructor;

        Product2 course = TestDataUtility.insertCourse();
        course.Course_Delivery__c = 'Public';
        course.Course_Format__c = 'Virtual Learning';
        course.Training_Product_Type__c = 'Training Course';
        course.Training_Taxonomy_Code__c = 'TAX00001ENUK';
        update course;

        Training_Event__c event = new Training_Event__c();
        event.Training_Venue__c = trainingv.Id;
        event.CurrencyIsoCode = 'GBP';
        event.Max_Seats__c = 10;
        event.Course__c = course.Id;
        event.Start_date__c = Date.today() + 5;
        event.Event_status__c = Label.Active;
        event.Trainer__c = instructor.Id;
        event.Duration_days__c = 1;
        event.Event_Confirmed__c = false;
        event.Accommodation_available_for_this_event__c = false;
        event.RecordTypeId = rt.Id;
        event.VL_Login__c = 'www.test.com';
        insert event;
    
        event = [SELECT Event_Confirmed__c FROM Training_Event__c WHERE Id = :event.Id];
        System.assert(event.Event_Confirmed__c);
    }

    @isTest static void onBeforeUpdateTest(){
        RecordType rt = [SELECT Id FROM RecordType WHERE Name = :Label.UK_Public_Event];
    
        Training_Venue__c masterv = new Training_Venue__c(Name = 'UK Master', CurrencyIsoCode = 'GBP', Public_Venue__c = true);
        insert masterv;

        Training_Venue__c trainingv = new Training_Venue__c(Name = 'Training Venue', CurrencyIsoCode = 'GBP', Public_Venue__c = true, Training_Office__c = masterv.Id, Venue_Day_Rate__c = 100, Venue_Day_Delegate_Rate__c = 100, Venue_Residential_Delegate_Rate__c = 100,Venue_SAP_Ship_To__c = '12345');
        insert trainingv;

        Contact instructor = new Contact(FirstName = 'test', LastName = 'test', Internal_Instructor__c = true, MailingCountry = 'GB', Email = 'email@email.com', RecordTypeId = bg_RecordTypeUtils.GetRecordTypes(bg_RecordTypeUtils.OBJECT_NAME_CONTACT).get(bg_ContactUtils.RECORD_TYPE_NAME_CLIENTS).Id, I_Codes_text__c = 'ICODES', Country_Office__c = masterv.Id);
        insert instructor;

        Product2 course = TestDataUtility.insertCourse();

        Training_Event__c event = new Training_Event__c();
        event.Training_Venue__c = trainingv.Id;
        event.CurrencyIsoCode = 'GBP';
        event.Max_Seats__c = 10;
        event.Course__c = course.Id;
        event.Start_date__c = Date.today() + 5;
        event.Event_status__c = Label.Active;
        event.Trainer__c = instructor.Id;
        event.Duration_days__c = 1;
        event.Event_Confirmed__c = false;
        event.Accommodation_available_for_this_event__c = false;
        event.VL_Login__c = 'www.test.com';
        insert event;
    
        event = [SELECT Event_Confirmed__c FROM Training_Event__c WHERE Id = :event.Id];
        System.assert(!event.Event_Confirmed__c);
        
        course.Course_Delivery__c = 'Public';
        course.Course_Format__c = 'Virtual Learning';
        course.Training_Product_Type__c = 'Training Course';
        course.Training_Taxonomy_Code__c = 'TAX00001ENUK';
        update course;

        TrainingEventTriggerHandler.isBeforeUpdateFirstRun = true;
        event.RecordTypeId = rt.Id;
        update event;

        event = [SELECT Event_Confirmed__c FROM Training_Event__c WHERE Id = :event.Id];
        System.assert(event.Event_Confirmed__c);
    }

}