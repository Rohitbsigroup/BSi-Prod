/********************************************************************
 * bg_Training_Event_AI
 *
 * After Insert trigger for Training_Event__c object
 * 
 * Author: Alexis Lignereux
 * Created: 10-12-2014
 * Changes: 
 ********************************************************************/
trigger bg_Training_Event_AI on Training_Event__c (after insert) {
    bg_TrainingUtils.trainingEventInstructorAssignmentMessage(Trigger.new);
}