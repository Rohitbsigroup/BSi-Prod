/********************************************************************
 * bg_TrainingBooking_AI
 *
 * After Insert trigger for TrainingBooking__c object
 * 
 * Author: Nick Fisher
 * Created: 30-10-2014
 * Changes: 
 * 06/01/2015 - AL - Added call to getTrainingBookingEmailInformation
 ********************************************************************/
trigger bg_TrainingBooking_AI on TrainingBooking__c (after insert) 
{
    bg_TrainingUtils.createDelegatesForTrainingBooking(trigger.newMap);

    //bg_EmailUtils.sendOnlineBookingReceived(trigger.oldMap, trigger.newMap);
}