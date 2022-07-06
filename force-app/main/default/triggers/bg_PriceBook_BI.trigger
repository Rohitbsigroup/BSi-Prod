/********************************************************************
 * bg_PriceBook_BI
 *
 * Before insert trigger for Pricebook2 object
 * 
 * Author: Chris Bacon
 * Created: 25-05-2017
 * Changes: 
 ********************************************************************/
trigger bg_PriceBook_BI on Pricebook2 (before insert) 
{
	RecordType MSAPricebook = bg_PricebookUtils.GetPricebookByDeveloperName(bg_PricebookUtils.MSA_DEVELOPER_NAME);
	
	List<Pricebook2> pricebook2List = new List<Pricebook2>();
	for(Pricebook2 pb : Trigger.new)
	{
		if(pb.RecordTypeId.Equals(MSAPricebook.Id))
		{
			pricebook2List.add(pb);
		}
	}
 	
 	if(!pricebook2List.isEmpty())
 	{
 		if(bg_CustomPermissionUtils.HasPermission(UserInfo.getUserId() ,bg_CustomPermissionUtils.CAN_CREATE_MSA))
 		{
 			bg_PricebookUtils.UpdateAccountLookupToMSA(pricebook2List);
 		}
 		else
 		{
 			for(Pricebook2 pb : pricebook2List)
 			{
 				pb.addError(Label.BG_MSA_Permission_Error);
 			}
 		}
 	}
}