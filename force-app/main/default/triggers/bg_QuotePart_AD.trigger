/********************************************************************
 * bg_QuotePart_AD
 *
 * After Delete trigger for Quote_Part__c object
 * 
 * Author: Nick Fisher
 * Created: 04-02-2015
 * Changes: 
 ********************************************************************/
trigger bg_QuotePart_AD on Quote_Part__c (after delete) 
{
	bg_TrainingUtils.deleteOrphanedTrainingBookings(trigger.oldMap);
}