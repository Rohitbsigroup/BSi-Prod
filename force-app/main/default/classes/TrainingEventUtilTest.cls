/**
* Author:       Pawel Chrzanowski (K2)
* Date:         08/08/2018
* Description:  test class for TrainingEventUtil
*
* ******************* Change Log *******************
**/

@isTest
public class TrainingEventUtilTest {

    @isTest
    static void confirmEventTest_Positive(){
        Training_Event__c te = new Training_Event__c(Max_seats__c = 10);
        insert te;
        
        TrainingEventUtil.confirmEvent(te.Id);
        te = [SELECT Event_Confirmed__c FROM Training_Event__c];
        System.assert(te.Event_Confirmed__c);
    }

    @isTest
    static void confirmEventTest_Negative(){
        Training_Event__c te = new Training_Event__c(Max_seats__c = 10);
        insert te;
        delete te;

        TrainingEventUtil.confirmEvent(te.Id);
        List<Training_Event__c> resultList = [SELECT Id FROM Training_Event__c WHERE Event_Confirmed__c = true];
        System.assert(resultList.isEmpty());
    }
}