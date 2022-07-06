/********************************************************************
 * bg_TrainingBooking_AI
 *
 * After Update trigger for TrainingBooking__c object
 * 
 * Author: Nick Fisher
 * Created: 30-10-2014
 * Changes: 
 * 06/01/2015 - AL - Added call to getTrainingBookingEmailInformation
 ********************************************************************/
trigger bg_TrainingBooking_AU on TrainingBooking__c (after update) 
{
    // CB - REMOVED - After clarification from Julies email 29/06/2015
    bg_TrainingUtils.syncDelegatesWithTrainingBooking(trigger.newMap);

	// RJ - REMOVED - USING WORKFLOW RULES FROM GLOBAL
    //bg_EmailUtils.sendOnlineBookingReceived(trigger.oldMap, trigger.newMap);
}