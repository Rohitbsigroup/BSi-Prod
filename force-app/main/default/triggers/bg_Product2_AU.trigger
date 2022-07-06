/********************************************************************
 * bg_Product2_AU
 *
 * After Update trigger for Product2 object
 * 
 * Author: Alexis Lignereux
 * Created: 10-12-2014
 * Changes: 
 ********************************************************************/
trigger bg_Product2_AU on Product2 (after update) {
    bg_TrainingUtils.productUpdateTrainingEventInstructorMessage(Trigger.newMap, Trigger.oldMap);
}