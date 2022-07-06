trigger bz_UpdateEnumValueReferences on EnumValue__c (after insert, after update) {
	system.debug('BZ: Running bz_UpdateEnumValueReferences');
	
	if(bz_QuoteDataRelator.AlreadyProcessed)
	{
		return;
	} 
	else 
	{
		bz_QuoteDataRelator.RelateEnumValue(trigger.newmap.keyset());
	}
}