@isTest
public class AddTrainingDelegateDetailsControllerTest {

    @isTest
    static void controllerTest(){
        Training_Event__c event = TestDataUtility.insertTrainingEvent(Date.today(), true);
        TrainingBooking__c booking = new TrainingBooking__c(First_Name__c='name', Training_Event__c=event.Id);
        insert booking;

        List<TrainingDelegate__c> delegateList = new List<TrainingDelegate__c>();
        delegateList.add(new TrainingDelegate__c(Email_Address__c='test@test.com', First_Name__c='first', Last_Name__c='last', Training_Booking__c=booking.Id));
        insert delegateList;
        
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(delegateList);
        ssc.setSelected(delegateList);
        AddTrainingDelegateDetailsController controller = new AddTrainingDelegateDetailsController(ssc);
        controller.updateDelegates();

        //negative
        delete delegateList;
        controller.updateDelegates();
    }
}