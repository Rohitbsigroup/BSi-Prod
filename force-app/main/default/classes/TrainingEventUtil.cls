/**
* Author:       Pawel Chrzanowski (K2)
* Date:         08/08/2018
* Description:  class to handle JS button on Training Event
*
* ******************* Change Log *******************
**/

global class TrainingEventUtil {

    webservice static String confirmEvent(String id){
        System.debug('### TrainingEventUtil.confirmEvent');
        Training_Event__c te = new Training_Event__c(Id = id, Event_Confirmed__c = true);
        Database.saveResult result = Database.update(te, false);
        
        if(result.isSuccess()) return Label.Confirm_Event_Button_Success;
        else {
            System.debug('### TrainingEventUtil.confirmEvent: ' + Label.Confirm_Event_Button_Error + ', ' + result.getErrors());
            return Label.Confirm_Event_Button_Error;
        }
    }
}