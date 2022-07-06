/********************************************************************
 * QuotePartTriggerHandler
 *
 * Handler Class for Quote Part
 * 
 * 
 * Author: Richard Jimenez
 * Created: 04-12-2013
 * Changes: NF 03-11-2014 : Added training calls
 * Changes: CB 26/06/2015 : Added trigger lock
 ********************************************************************/
public with sharing class QuotePartTriggerHandler {
	
	private boolean isExecuting = false;
	private integer BatchSize = 0;
    public SystemSetting__c sys = SystemSetting__c.getInstance();
	
	// CONSTRUCTOR
	public QuotePartTriggerHandler(boolean isExecuting, integer size) {
		isExecuting = isExecuting;
		BatchSize = size;
	}
	
	// BEFORE INSERT
	public void OnBeforeInsert(Quote_Part__c[] newQuoteParts){
		if (!Utility.lockQuotePartTrigger) {
			String productCodes = sys.Products_to_Check_Pricing_Configured__c;
			List<String> listProductCodes = productCodes != null ? productCodes.split(',') : null;
			
			Set<String> productIds = new Set<String>();
			for(Quote_Part__c quotePart: newQuoteParts){
				if(quotePart.Product2__c != null)
					productIds.add(quotePart.Product2__c);
			}
			
			if(productIds.size() > 0) {
				Map<Id, Product2> products = new Map<Id, Product2>([SELECT Id, ProductCode FROM Product2 WHERE Id = :productIds]);
				List<PricebookEntry> priceBookEntries = [SELECT Product2.Id, PriceBook2.Id, UnitPrice, CurrencyIsoCode FROM PricebookEntry WHERE Product2.Id = :productIds];
				
				// Loop for each quote part to find out if any part pricing is calculated in Blueprint and set the flag accordingly
				for(Quote_Part__c quotePart: newQuoteParts){
					if(listProductCodes != null && products != null && quotePart.Product2__c != null && listProductCodes.contains(products.get(quotePart.Product2__c).productCode)){
						for(PriceBookEntry pbe:priceBookEntries){
							if(pbe.Product2.Id == quotePart.Product2__c && pbe.PriceBook2.Id == quotePart.Price_Book__c 
								&& pbe.CurrencyIsoCode == quotePart.CurrencyIsoCode
								&& pbe.UnitPrice != quotePart.List_Price__c){
								quotePart.Pricing_Configured__c = True;
							}
						}
					}
				}
			}
			
			// Populate Quote Part Extended Values
			bg_QuotePartUtils.PopulatePartExtendedValues(newQuoteParts);
			// Populate Quote Part prices
			//bg_QuotePartUtils.PopulateQuotePartPrices(newQuoteParts, null);
		}
	}

	// AFTER INSERT
	public void OnAfterInsert(Quote_Part__c[] newQuoteParts, map<Id, Quote_Part__c> newMapQuoteParts) 
	{
	}
	
	// BEFORE UPDATE
	public void OnBeforeUpdate(Quote_Part__c[] updatedQuoteParts, map<Id, Quote_Part__c> oldMapQuoteParts){
		if (!Utility.lockQuotePartTrigger) {
			// Populate Quote Part Extended Values
			bg_QuotePartUtils.PopulatePartExtendedValues(updatedQuoteParts);
			// Populate Quote Part prices
			//bg_QuotePartUtils.PopulateQuotePartPrices(updatedQuoteParts, oldMapQuoteParts);
		}
	}	
	
	// AFTER UPDATE
	public void OnAfterUpdate(Quote_Part__c[] updatedQuoteParts, Map<Id, Quote_Part__c> oldMapQuoteParts)
	{
		// Keep Training Bookings in sync with training Quote Parts
		if (!Utility.lockQuotePartTrigger) {
			Map<Id, Quote_Part__c> newQuotePartMap = new Map<Id, Quote_Part__c>(updatedQuoteParts);
			bg_TrainingUtils.syncTrainingBookingsv2(newQuotePartMap);
		}
	}
	
	// BEFORE DELETE
	public void OnBeforeDelete(Quote_Part__c[] oldQuoteParts){
		Set<String> qpIds = new Set<String>();
		for(Quote_Part__c quotePart: oldQuoteParts){
			qpIds.add(quotePart.Id);
		}
		
		List<Quote_Part__c> quoteParts = [SELECT Id, Quote_Ref__r.Sync_in_Progress__c FROM Quote_Part__c WHERE Id = :qpIds];
		
		for(Quote_Part__c qp: quoteParts){
			if(qp.Quote_Ref__r.Sync_in_Progress__c == 0){
				//oldQuoteParts[0].addError('You do not have permission to delete this record');
			}
		}
	}
}