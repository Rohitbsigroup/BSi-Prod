trigger UpdateSelfRollup on Campaign (before update)  
{
	//This trigger is only for case where you update the parent itself, as this 
	//cannot be handled in after-update (causes recursive updates) , this is being done in before-update
	bg_CampaignUtils.UpdateCampaignRollup(trigger.new, trigger.newMap);
}