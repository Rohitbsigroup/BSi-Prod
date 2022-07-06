/********************************************************************
 * bg_PriceBook_AI
 *
 * After insert trigger for Pricebook2 object
 * 
 * Author: Richard Cave
 * Created: 09-05-2017
 * Changes: 
 ********************************************************************/
trigger bg_PriceBook_AI on Pricebook2 (after insert) 
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
 		bg_PricebookUtils.UpdateAccountLookupToMSA(pricebook2List);
 	}
}