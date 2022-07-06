public class bg_DelegateUtils {
	
	public static Boolean DelegatesReadyToConvert(List<TrainingDelegate__c> pTrainingDelegates){
		Boolean retVal = true;
		for(TrainingDelegate__c td : pTrainingDelegates)
		{
			if(null==td.Ready_For_Conversion__c || !td.Ready_For_Conversion__c)
			{
				retVal = false;
			}
		}
		return retVal;
	}
}