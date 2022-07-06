trigger bz_UpdateProductToPropertyReferences on ProductToProperty__c (after insert, after update) {
	system.debug('BZ: Running bz_UpdateProductToPropertyReferences');
	
	if(bz_QuoteDataRelator.AlreadyProcessed)
	{
		return;
	} 
	else 
	{
		bz_QuoteDataRelator.RelateProductToProperty(trigger.newmap.keyset());
	}
}