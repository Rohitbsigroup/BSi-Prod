/**
* ******************* Change Log *******************
*  PC K2           31-08-18    added onBeforeInsert() and onBeforeUpdate()
*  PC K2           21-05-20    aded CLL to the Event Confirmed setting
**/

public with sharing class TrainingEventTriggerHandler {
    public static boolean firstRun = true;
    private boolean m_isExecuting = false;
    public static Boolean isBeforeUpdateFirstRun = true;
    public static Boolean isAfterUpdateFirstRun = true;
    private integer BatchSize = 0;
    
    // Constructor
    public TrainingEventTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

    public void onBeforeInsert(List<Training_Event__c> newTrainingEvents){
        System.debug('### TrainingEventTriggerHandler.onBeforeInsert');

        //confirm event if UK Public Event, update 20-04-2020
        for(Training_Event__c te : newTrainingEvents){
            if (te.Event_Country__c == 'UK' && 
                te.Course_Type_Formula__c == 'Public' && 
                (te.Course_Format_Formula__c == 'ILT - Training Course' || te.Course_Format_Formula__c == 'Virtual Learning - Training Course')){
                te.Event_Confirmed__c = true;
            }
        }
    }

    public void onBeforeUpdate(List<Training_Event__c> oldTrainingEvents, Map<Id, Training_Event__c> oldMap, List<Training_Event__c> newTrainingEvents, Map<Id, Training_Event__c> newMap){
        System.debug('### TrainingEventTriggerHandler.onBeforeUpdate');

        if (isBeforeUpdateFirstRun) isBeforeUpdateFirstRun = false;
        else return;

        //confirm event if UK Public Event, update 20-04-2020
        for(Training_Event__c te : newTrainingEvents){
            if (te.Event_Country__c == 'UK' && 
                te.Course_Type_Formula__c == 'Public' && 
                (te.Course_Format_Formula__c == 'ILT - Training Course' || te.Course_Format_Formula__c == 'Virtual Learning - Training Course')){
                te.Event_Confirmed__c = true;
            }
        }
    }

}