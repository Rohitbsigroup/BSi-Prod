/********************************************************************
 * bg_Training_Event_AU
 *
 * After Update trigger for Training_Event__c object
 * 
 * Author: Alexis Lignereux
 * Created: 10-12-2014
 * Changes:
 *          05-08-2015 RJ Added ManageTrainingSMOUpdateRecords
 *  PC K2           08-08-18    added manageEventConfirmation()
 *  PC K2           26-10-18    added manageEventRevenue()
 *  MD      19-12-2018    Reinstated manageEventRevenue() which had been commented out by Julie on 11th Dec
 *  PC K2   14-05-2020    added manageMimeoDistributionAssignment(), 
 *  PC K2   18-05-2020    moved trainingEventInstructorAssignmentMessage() to last position to fix Trigger.oldMap issue
 ********************************************************************/
trigger bg_Training_Event_AU on Training_Event__c (after update) {

    // Create/Update SMO Update records
    bg_TrainingUtils.ManageTrainingSMOUpdateRecords(Trigger.old, Trigger.new, Trigger.newMap);

    // manage Event confirmation
    bg_TrainingUtils.manageEventConfirmation(Trigger.old, Trigger.oldMap, Trigger.new, Trigger.newMap);

    //handle Event Revenue change
    bg_TrainingUtils.manageEventRevenue(Trigger.oldMap, Trigger.newMap);

    //handle Mimeo Distribution Assignment change
    bg_TrainingUtils.manageMimeoDistributionAssignment(Trigger.oldMap, Trigger.newMap);
    
    // Update Instructor Message
    // !IMPORTANT this method updates Training Events and will overwrite Trigger.oldMap, Trigger.newMap
    bg_TrainingUtils.trainingEventInstructorAssignmentMessage(Trigger.new);
}