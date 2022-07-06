/********************************************************************
 * bg_QuotePartUtils
 *
 * Utility methods to support Quote Parts
 * 
 * 
 * Author: Richard Jimenez
 * Created: 05-12-2013
 * Changes: 
 *  KM  	29/10/2014 Created ResetDiscountsOnQuote
 *	IB		05/09/2017 Use cached bg_PricebookUtils method GetTodaysExchangeRateMap()
 *  IB		14/09/2017 Removed deprecated methods PopulateQuotePartPrices(), RecalculateQuotePartPrices,
 						CheckExchangeRate()
 * CPE		18/09/2017	New method to update Quote Part pricing details from a PBE
 ********************************************************************/
public class bg_QuotePartUtils {

	public static final string PROPERTYALIAS_CERTIFICATION_BODY_UKAS = 'TypeUkas';
	public static final string PROPERTYVALUE_CERTIFICATION_BODY_UKAS = '1';

	public static final string INFOTEXT_USELOCALPRICES = 'UseLocal';
	
	public class QuotePartException extends Exception{}

	
	public static void PopulatePartExtendedValues(list<Quote_Part__c> quoteParts) {
		/*
			Method to populate Part Extended Values field
		*/

		try {
			// Scope quote parts to update		
			list<Quote_Part__c> updQuoteParts = new list<Quote_Part__c>();
			map<Id, string> qpPEVKeysMap = new map<Id, string>();
			for(Quote_Part__c qp : quoteParts) {
				if(qp.Quote_Product__c != null && !qp.IsQuestion__c
					&& qp.Price_Book__c != null && qp.Product2__c != null) {
					updQuoteParts.add(qp);
					qpPEVKeysMap.put(qp.Id, GetPEVKey(qp.Price_Book__c, qp.Product2__c));
				}
			}
			System.debug('+++ updQuoteParts = ' + updQuoteParts);
			
			if(!updQuoteParts.isEmpty()) {
				// Build Part Extended Value Map by PEV Key (PricebookId-ProductId)
				map<string, Id> pevMap = new map<string, Id>();
				for(Part_Extended_Value__c pev : [SELECT Id, Price_book__c, Product__c, PEV_Key__c  
													FROM Part_Extended_Value__c 
													WHERE PEV_Key__c IN :qpPEVKeysMap.values()]) {
						pevMap.put(pev.PEV_Key__c, pev.Id);											
				}
		
				// Populate Part Extended Value Lookup
				map<string, Part_Extended_Value__c> newPevMap = new map<string, Part_Extended_Value__c>();
				list<Quote_Part__c> unmatchedQuoteParts = new list<Quote_Part__c>();
				
				for(Quote_Part__c qp : updQuoteParts) {
					if(pevMap.containsKey(qpPEVKeysMap.get(qp.Id))) {
						qp.Part_Extended_Value__c = pevMap.get(qpPEVKeysMap.get(qp.Id));
					} else {	
						system.debug('Unable to link quote part to extended values - ' + qp);
						// add to list to create
						newPevMap.put(qpPEVKeysMap.get(qp.Id), CreateQuotePartExtension(qp.Price_Book__c, qp.Product2__c));
						unmatchedQuoteParts.add(qp);
					}
				}
				
				// Create new quote part extensions
				if(!newPevMap.isEmpty()) {
					// create new PEVs
					database.insert(newPevMap.values(), false);
					// rehook unmatched quote parts
					for(Quote_Part__c qp : unmatchedQuoteParts) {
						if(newPevMap.get(qpPEVKeysMap.get(qp.Id)).Id != null) {
							qp.Part_Extended_Value__c = newPevMap.get(qpPEVKeysMap.get(qp.Id)).Id;
						} else {	
							system.debug('Unable to link quote part to extended values - ' + qp);
						}
					}
				}
			}
		} catch (Exception ex){
			system.debug('Unable to link quote part to extended values - ' + ex);
		}
	}
	
	private static string GetPEVKey(Id pricebookId, Id productId) {
		/* Return PEV Key */
		return pricebookId + '_' +  productId;
	}
	
	public static Part_Extended_Value__c CreateQuotePartExtension(Id pricebookId, Id productId) {
		/*
			Create new quote part Extension record
		*/
		Part_Extended_Value__c newPEV = new Part_Extended_Value__c();
		newPEV.Price_Book__c = pricebookId;
		newPEV.Product__c = productId;
		newPEV.IsDiscountable__c = true;
		return newPEV;
	}

	public static list<PropertyValue__c> GetQuoteProductValues(Id quoteId, string productName, string propertyAlias, string value) {
		/*
			Method to return list of Property Values
		*/
		list<PropertyValue__c> pvList = new list<PropertyValue__c>();
		for(PropertyValue__c pv : [SELECT Id, QuoteToProduct__c, TextValue__c, Value__c
				FROM PropertyValue__c 
				WHERE QuoteToProduct__r.Quote_Ref__c = :quoteId
					AND QuoteToProduct__r.Product_Name__r.Main_Product_Name__c = :productName
					AND ProductPropertyAlias__c = :propertyAlias]) {
			if(pv.TextValue__c == value) {
				pvList.add(pv);
			}
		}
		return pvList;
	}
	
	public static void UpdateExchangeRates(Quote__c quote, list<Quote_Part__c> quoteParts, boolean updateAll) {
		/*
			Set Exchange Rates
		*/
		set<string> isoCodes = new set<string>();
		for(Quote_Part__c qp : quoteParts) {
			isoCodes.add(qp.CurrencyIsoCode);					
		}

		// add quote currency code
		isoCodes.add(quote.CurrencyIsoCode);
		
		// Get Exchange Rate Map
		map<string, decimal> exchangeRateMap = bg_PricebookUtils.GetExchangeRateMap(isoCodes, Date.Today());

		decimal quoteRate = exchangeRateMap.get(quote.CurrencyIsoCode);

		for(Quote_Part__c qp : quoteParts) {
			if(updateAll || integer.valueOf(bg_Utilities.getDecimal(qp.Exchange_Rate__c)) == 0) {
				decimal localRate = exchangeRateMap.get(qp.CurrencyIsoCode);
				qp.Exchange_Rate__c = (quoteRate / localRate);
			}
			if(qp.Price_Book__c == null) {
				qp.Price_Book__c = qp.Quote_Product__r.Price_Book__c;
			}
		}
	}

	////************ 2017 **************/ Input: Price to convert, Quote Part Currency, Main Quote Currency
	public static Decimal getConvertedPriceInQuotePartCurrency(Decimal inptPrice, String inptQuotePartCurrency, String inptQuoteCurrency)
	{
		if(inptPrice == null || inptPrice == 0)
		{
			return 0;
		}else if(inptQuotePartCurrency == inptQuoteCurrency)
		{
			return inptPrice;
		}else
		{
			map<string, decimal> exchangeRateMap = bg_PricebookUtils.GetTodaysExchangeRateMap();
			//Get Quote Currency code
			decimal quoteRate = exchangeRateMap.get(inptQuoteCurrency);
			//Get Quote part currency quote
			decimal quotePartRate = exchangeRateMap.get(inptQuotePartCurrency);
			//1. convert price book to GBP
			Decimal priceBookConverted = (inptPrice * (1 / quotePartRate)).setScale(2);
			//2. Convert GPB into Quote currency
			return (priceBookConverted * quoteRate).setScale(2);
		}
	}

	////************ 2017 **************/
	
	
	public static boolean CheckQuotePartsBelowGridMax(Id quoteId, integer maxGridParts) {
		/* 
			Check if quote parts exceeds Quote Part Grid Max
		*/
		System.debug('++++ maxGridParts = ' + maxGridParts);
		return [SELECT COUNT() FROM Quote_Part__c 
				WHERE Quote_Ref__c = :quoteId 
					AND IsQuestion__c = false] <= maxGridParts;
	}
	
	public static boolean HasHalfDayPrices(Id quoteId, set<string> countryCodes) {
		/*
			Check if quote has half days
		*/
		return [SELECT COUNT()
				FROM Quote_Part__c
				WHERE Quote_Ref__c = :quoteId
					AND IsQuestion__c = false
					AND HasHalfDay__c = true
					AND Country_Code__c IN :countryCodes
				LIMIT 1] > 0;
	}


	/*
		Update QuotePart from PricebookEntry
	*/
	public static void UpdateQuotePartFromPricebookEntry(Quote_Part__c quotePart, PricebookEntry priceBookEntry, String quoteCurrency)
	{
		if ((quotePart != null) &&
			(priceBookEntry != null) &&
			(!bg_StringUtils.IsBlank(quoteCurrency)))
		{
			quotePart.CurrencyISOCode = priceBookEntry.CurrencyISOCode;
			quotePart.List_Price__c = priceBookEntry.UnitPrice;
			quotePart.Converted_list_Price__c = getConvertedPriceInQuotePartCurrency(quotePart.List_Price__c, quotePart.CurrencyIsoCode, quoteCurrency);
			quotePart.Price__c = quotePart.Converted_list_Price__c; 
		}
	} 


		
}