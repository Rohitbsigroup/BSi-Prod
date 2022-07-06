trigger bz_UpdatePropertyValueReferences on PropertyValue__c (after insert, after update) {
	system.debug('BZ: Running bz_UpdatePropertyValueReferences');
	
	if(bz_QuoteDataRelator.AlreadyProcessed)
	{
		return;
	} 
	else 
	{
		bz_QuoteDataRelator.RelatePropertyValue(trigger.newmap.keyset());
	}
}