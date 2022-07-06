/********************************************************************
 * bg_Contact_AU
 *
 * After Update trigger for Contact object
 * 
 * Author: Alexis Lignereux
 * Created: 10-12-2014
 * Changes: 
 ********************************************************************/
trigger bg_Contact_AU on Contact (after update) {
    bg_TrainingUtils.contactUpdateTrainingEventInstructorMessage(Trigger.oldMap, Trigger.newMap);
}