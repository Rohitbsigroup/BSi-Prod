/*
 * bg_Opportunity_AU
 *
 * Changes:
 * 	Nick Fisher: Added callout to bg_TrainingUtils.setSMOScheduledDate()
 *  Chris Bacon: 24/06/2015
 *
 *               Commented existing trigger calls
 *							 - bg_OpportunityUtils.createEnrollementOpportunityStageCloseProcessing()
 *							 - bg_TrainingUtils.setSMOScheduledDate
 *
 *				 Added calls - ConvertTrainingBookingIfStageClosedProcessing
 *								- This handles TB conversion, smo dates are calculated during conversion
 *							 - SupersedeQuotes_TrainingBookings_TrainingEvents
 *								- Updates related quotes, TBs and In-House Training Events upon opp closed won/lost
 */
trigger bg_Opportunity_AU on Opportunity (after update) 
{
		if (!Utility.lockOptyTrigger) {
			//bg_OpportunityUtils.createEnrollementOpportunityStageCloseProcessing(Trigger.oldMap, Trigger.newMap);
			//bg_TrainingUtils.setSMOScheduledDate(trigger.new);
		    bg_OpportunityUtils.ConvertTrainingBookingIfStageClosedProcessing(Trigger.oldMap, Trigger.newMap);
	    	bg_OpportunityUtils.SupersedeQuotes_TrainingBookings_TrainingEvents(Trigger.oldMap, Trigger.newMap);
	    	bg_opportunityUtils.CalculateEventRevenue(Trigger.oldMap, Trigger.newMap);
		}
}