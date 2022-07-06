trigger UpdateRollupFieldsOnParentCampaign on Campaign (after delete, after insert, after update)
{
	//Perform roll-up for child campaigns to parents
	bg_CampaignUtils.UpdateParentRollupFields(trigger.new, trigger.old, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete);
}