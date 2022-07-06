/********************************************************************
 * bg_PricebookUtils
 *
 * Utility methods to support pricebook functions
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 *          10-12-2014 - RJ - Extended GetPricebooks to take set of Ids
 *                            Get default pricebook year from country settings 
 *			23-05-2017 - RC - Created function to set lookup on account
 *							  when MSA pricebook is added
 *			05-09-2017 - IB - added cached todaysExchangeRateMap
 *			15-09-2017 - CPE  New method to obtain PricebookEntry for a particular currency
 *							  New method to obtain all PBE's for given pricebook, product records
 ********************************************************************/
public with sharing class bg_PricebookUtils {

	public class PricebookException extends Exception{}

	public static final string MSA_DEVELOPER_NAME = Label.BG_MSA_DEVELOPER_NAME;
	public static List<RecordType> priceBooksRT;

	private static Pricebook2 standardPricebook;
	public static Pricebook2 GetGlobalPricebook() {
		/*
			Return Standard Pricebook
		*/
		if(standardPricebook == null) {
			// Return standard pricebook
			standardPricebook = [SELECT Id 
									FROM Pricebook2 
									WHERE IsStandard = true];
			}
		return standardPricebook;
	}

	private static map<String, Decimal> todaysExchangeRateMap;
	public static map<String, Decimal> GetTodaysExchangeRateMap() {
		if(todaysExchangeRateMap == null) {
			todaysExchangeRateMap = new map<string, Decimal>();
		
			todaysExchangeRateMap.put(bg_Globals.CURRENCY_CODE_GBP, 1);
			for(DatedConversionRate dcr: [SELECT IsoCode, ConversionRate
										FROM DatedConversionRate
										WHERE StartDate <= TODAY AND NextStartDate >= TODAY]) 
			{
				todaysExchangeRateMap.put(dcr.IsoCode, dcr.ConversionRate);
			}
		}
		return todaysExchangeRateMap;
	}

	private static List<RecordType> GetPriceBookRecordType(String developerName)
	{
		if(priceBooksRT==null)
		{
			return priceBooksRT = new List<RecordType>([SELECT Name, Id, SobjectType, DeveloperName
										 FROM RecordType
										 Where SobjectType='Pricebook2'
										 AND DeveloperName=:developername]);
		}
		else
		{
			return priceBooksRT;
		}
	}

	

	/*
	*	Function to return the developerName of the pricebook
	*/
	public static RecordType GetPricebookByDeveloperName(String developerName) 
	{
		RecordType pricebookRecordTypeToReturn = null;
	
		
		// Get Pricebooks by developerName
		priceBooksRT = GetPriceBookRecordType(developerName);

	    	// Check we only got 1 pricebook back
    		if(1==priceBooksRT.size())
    		{
    			// set the return value and add pricebook to cache
    			pricebookRecordTypeToReturn = priceBooksRT[0];
    		}
    		// dont need to check the size the system enforces developername as unique so will not be more than 1
    		else
    		{
				// create a label to go in here 'No Pricebook found for the developer name {0}'
				throw new PricebookException(label.BG_MSA_DEVELOPERNAME_ERROR +  ' ' + developerName);    		
			}
		
		return pricebookRecordTypeToReturn;
	}


	/*
	*	Function to set the lookup on account when a new MSA pricebook is added to an account
	*/
	public static void UpdateAccountLookupToMSA(List<Pricebook2> priceBookList)
	{
		Map<Id, Pricebook2> pricebookMapMsa = new Map<Id, Pricebook2>();
		Set<Id> accountSet = new Set<Id>();
		for(Pricebook2 pb : priceBookList)
		{
			pricebookMapMsa.put(pb.Account__c,pb);
			accountSet.add(pb.Account__c);
		}

		List<Account> accList = [Select Id, MSA_Pricebook__c FROM Account WHERE Id IN : accountSet];

		//look through accounts and set the msa_pricebook field
		for(Account acc : accList)
		{
			acc.MSA_Pricebook__c = pricebookMapMsa.get(acc.Id).Id;
		}

		if(!accList.isEmpty())
		{	
			Database.SaveResult[] srList = Database.update(accList);

			// Iterate through each returned result
			for (Database.SaveResult sr : srList) 
			{
				if(!sr.isSuccess()) 
				{
        			// Operation failed, so get all errors                
        			for(Database.Error err : sr.getErrors()) 
        			{
            			System.debug('The following error has occurred.');                    
            			System.debug(err.getStatusCode() + ': ' + err.getMessage());
        			}
    			}
			}
		}


	}

	private static map<string, Pricebook2> pricebookNameMap;
	public static Pricebook2 GetPricebookByName(string pricebookName) {
		/*
			Return pricebook by name
		*/
		if(pricebookNameMap == null) {
			pricebookNameMap = new map<string, Pricebook2>();
		}

		if(!pricebookNameMap.containsKey(pricebookName)) {
			// Get Pricebook
	    	list<Pricebook2> pbs = [SELECT Id, Name 
	    							FROM Pricebook2 
	    							WHERE Name = :pricebookName 
	    								AND IsActive = true];
			if (!pbs.isEmpty()) {
				pricebookNameMap.put(pricebookName, pbs.get(0));
	    		return pbs.get(0);
			} else {
				return null;
			}
		} else {
			return pricebookNameMap.get(pricebookName);
		} 
	}

	public static list<Pricebook2> GetPricebooks() {
		/* Return list of pricebooks */
		return GetPricebooks(null);
	}

	public static list<Pricebook2> GetPricebooks(integer year) {
		/* Return list of pricebooks */
		return GetPricebooks(year, null);
	}

	public static list<Pricebook2> GetPricebooks(integer year, Id accountId) {
		/*
			Return list of pricebooks
		*/
		return GetPricebooks(year, accountId, null);
	}

	public static list<Pricebook2> GetPricebooks(integer year, Id accountId, set<string> countryCodes) {
		/*
			Return list of pricebooks
		*/
		return GetPricebooks(year, accountId, countryCodes, null, false);
	}

	public static list<Pricebook2> GetPriceBooksNonMSA(integer year, Id accountId, set<string> countryCodes, boolean NonMSA)
	{
		/*
			Return list of pricebooks
		*/
		return GetPricebooks(year, accountId, countryCodes, null, true);
	}
					
	public static list<Pricebook2> GetPricebooks(integer year, Id accountId, set<string> countryCodes, set<Id> pricebookIds, Boolean IgnoreMSA) {
		/*
			Return list of pricebooks
		*/

    	string query = 'SELECT Id, Name, Country_Code__c, Year__c ' +
					   'FROM Pricebook2 ' + 
					   'WHERE (IsActive = true ' +
					   '   AND AvailableForUse__c = true ' +
					   '   AND IsStandard = false ';

		if(year != null) {
			string yearString = string.valueOf(year);
			query += ' AND Year__c = :yearString ';
		}

		if(IgnoreMSA)
		{
			query+=' AND RecordType.DeveloperName!=:MSA_DEVELOPER_NAME ';
		}

		if(accountId != null) {
			query += ' AND (Account__c = null OR Account__c = :accountId) ';
		} else {
			query += ' AND Account__c = null ';
		}			   

		if(countryCodes != null) {
			query += ' AND Country_Code__c IN :countryCodes ';
		}

		query += ' ) ';

		if(pricebookIds != null) {
			query += ' OR Id IN :pricebookIds ';
		}

		query += ' ORDER BY name ';
						
		return database.query(query);
	}
	
	public static Pricebook2 GetUserDefaultPricebook() {
		/*
			Return default pricebookId based on user operation country
		*/
		ConversionScore__c cs = bg_CustomSettingsUtils.GetDefaultCountrySettings();
		Pricebook2 pb;
		pb = bg_PricebookUtils.GetPricebookByName(cs.DefaultPriceBookName__c);
		if(pb == null) {
			throw new PricebookException('Unable to find pricebook ' + cs.DefaultPriceBookName__c);
		}
		return pb;
	}	

	private static map<Id, Pricebook2> pricebookMap;
	private static map<Id, Pricebook2> GetPricebookMap() {
		if(pricebookMap == null) {
			pricebookMap = new map<Id, Pricebook2>();
		}
		return pricebookMap;
	}
	
	public static Pricebook2 GetPricebookById(Id pricebookId) {
		/*
			Return pricebook by Id
		*/
    	Pricebook2 pb;
    	if(!GetPricebookMap().containsKey(pricebookId)) {
	    	// Load price book
	    	try {
				pb = [SELECT Id, Name, Country_Code__c, Year__c, Default_Pricebook_Currency__c 
						FROM Pricebook2 
						WHERE Id = :pricebookId];
				pricebookMap.put(pb.Id, pb);						
	    	} catch (Exception e) {}
		} else {	    	
	    	// Check price book cache
    		pb = pricebookMap.get(pricebookId);
		}
		return pb;
	}

	private static map<Id, map<string, Pricebook2>> pricebookOppCountryMap;
	private static map<Id, map<string, Pricebook2>> GetPricebookOppCountryMap() {
		if(pricebookOppCountryMap == null) {
			pricebookOppCountryMap = new map<Id, map<string, Pricebook2>>();
		}
		return pricebookOppCountryMap;
	}
			
	public static map<string, Pricebook2> GetPricebookByOpportunitySites(Id oppId) {
		/*
			Return Pricebooks by Country
		*/
		map<string, Pricebook2> pricebookCountryMap;		
    	if(!GetPricebookOppCountryMap().containsKey(oppId)) {
	    	// Load price book
	    	pricebookCountryMap = new map<string, Pricebook2>();
	    	try {
	    		set<string> countryCodes = new set<string>();

	    		for(OpportunitySite__c oppSite : [SELECT SiteCountryCode__c 
	    											FROM OpportunitySite__c 
													WHERE Opportunity__c = :oppId]) {
	    			countryCodes.add(oppSite.SiteCountryCode__c);	
	    		}

				pricebookCountryMap = GetPricebookCountryMap(null, countryCodes);
		
				pricebookOppCountryMap.put(oppId, pricebookCountryMap);								
	    	} catch (Exception e) {}
    	} else {
    		pricebookCountryMap = pricebookOppCountryMap.get(oppId);
    	}
		return pricebookCountryMap;
	}
	
	public static map<string, Pricebook2> GetPricebookCountryMap(integer year, set<string> countryCodes) {
		/*
			Return Pricebook Country Map
		*/
		map<string, Pricebook2> pricebookCountryMap = new map<string, Pricebook2>();
		list<Pricebook2> pbs = GetPricebooks(year, null, countryCodes);
		for(Pricebook2 pb : pbs) {				
			pricebookCountryMap.put(pb.Country_Code__c, pb);
		}
		return pricebookCountryMap;		
	}

	public static string GetCurrencyCodeByCountry(string countryCode, string defaultCurrency) {
		/*
			Return currency code by country
		*/
		string currencyCode = defaultCurrency;
		map<string, Country_Currency__c> countryCurrencyMap = bg_CustomSettingsUtils.GetCountryCurrencySettings();
		if(countryCurrencyMap.containsKey(countryCode)) {
			currencyCode = countryCurrencyMap.get(countryCode).Currency_Code__c;
		}
		return currencyCode;
	} 

	public static Id GetPricebookIdByCountry(map<string, Pricebook2> pricebookCountryMap, string countryCode, Id defaultPriceBookId) {
		/*
			Return Pricebook Id by country
		*/
		if(pricebookCountryMap.containsKey(countryCode)) {
			return pricebookCountryMap.get(countryCode).Id;
		} else {
			return defaultPriceBookId;
		}
	} 
		
	public static boolean CheckPricebookSupportsCurrency(Id pricebookId, string currencyISOCode) {
		/*
			Check the price support currency
		*/
		return [SELECT COUNT()
				FROM PricebookEntry 
				WHERE Pricebook2Id = :pricebookId 
						AND CurrencyIsoCode = :currencyISOCode 
						AND IsActive = true] > 0;
	}
	


	public static map<string, decimal> GetExchangeRateMap(set<string> isoCodes, date pDate) {
		/*
			Return exchange rate map		
		*/
		// Build list of exchange rates from salesforce
		map<string, decimal> exchangeRateMap = new map<string, decimal>();
		exchangeRateMap.put(bg_Globals.CURRENCY_CODE_GBP, 1);
		for(DatedConversionRate dcr: [SELECT IsoCode, ConversionRate
										FROM DatedConversionRate
										WHERE StartDate <= :pDate AND NextStartDate >= :pDate
											AND IsoCode IN :isoCodes]) {
			exchangeRateMap.put(dcr.IsoCode, dcr.ConversionRate);
		}
		system.debug('exchangeRateMap: ' + exchangeRateMap);
		return exchangeRateMap;
	}

	public static map<string, PricebookEntry> GetPricebookEntryMap(set<Id> pricebookIds, set<Id> productIds) {
		/*
			Return pricebook entry map		
		*/
		map<string, PricebookEntry> pricebookEntryMap = new map<string, PricebookEntry>();
		for(PricebookEntry pbe : [SELECT Id, Pricebook2Id, Product2Id, CurrencyIsoCode, UnitPrice 
									FROM PricebookEntry 
									WHERE IsActive = true AND
											Pricebook2Id IN :pricebookIds AND
											Product2Id IN :productIds]) {
			pricebookEntryMap.put(GetPriceProductKey(pbe.Pricebook2Id, pbe.Product2Id), pbe);
			//isoCodes.add(pbe.CurrencyIsoCode);
		}
		system.debug('pricebookEntryMap: ' + pricebookEntryMap);
		return pricebookEntryMap;
	}

	////************ 2017 **************/
	public static map<string, PricebookEntry> GetPricebookEntryMap(set<Id> productIds, set<String> inptISOCodes) {
		/*
			Return pricebook entry map		
		*/
		map<string, PricebookEntry> pricebookEntryMap = new map<string, PricebookEntry>();
		for(PricebookEntry pbe : [SELECT Id, Pricebook2Id, Product2Id, CurrencyIsoCode, UnitPrice 
									FROM PricebookEntry 
									WHERE IsActive = true AND
											Product2Id IN :productIds AND
											CurrencyIsoCode IN: inptISOCodes]) {
			pricebookEntryMap.put(GetPriceProductKey(pbe.Pricebook2Id, pbe.Product2Id), pbe);
			//isoCodes.add(pbe.CurrencyIsoCode);
		}
		system.debug('pricebookEntryMap: ' + pricebookEntryMap);
		return pricebookEntryMap;
	}
	////************ 2017 **************/
	
	public static string GetPriceProductKey(string pricebookId, string productId) {
		/* Return price product key */
		return pricebookId + '_' + productId;
	}
	
	public static decimal GetConvertedValue(string fromCurrencyIsoCode, string toCurrencyIsoCode, decimal value) {
		/*
			Get Convert Value into another currency
		*/
		// convert quote value to matrix value
		set<string> isoCodes = new set<string>{fromCurrencyIsoCode, toCurrencyIsoCode};
		// Get Exchange Rate Map
		map<string, decimal> exchangeRateMap = GetExchangeRateMap(isoCodes, Date.Today());
		return GetConvertedValue(exchangeRateMap, fromCurrencyIsoCode, toCurrencyIsoCode, value);		
	}

	public static decimal GetConvertedValue(map<string, decimal> exchangeRateMap, string fromCurrencyIsoCode, string toCurrencyIsoCode, decimal value) {
		/*
			Get Convert Value into another currency
		*/
		decimal fromRate = exchangeRateMap.get(fromCurrencyIsoCode);
		decimal toRate = exchangeRateMap.get(toCurrencyIsoCode);
		// return converted value			
		return (value * (toRate / fromRate)).setScale(6);
	}
	
	/*
		Find the PriceBookEntry record from the supplied list for the desired Currency
		Returns null if desired Currency record is not found
	*/
	public static PricebookEntry FindPricebookEntryByCurrency(List<PricebookEntry> entries, String currencyCode)
	{
		PricebookEntry result = null;
		if (entries != null)
		{
			for (PricebookEntry pbe : entries)
			{
				if (pbe.CurrencyISOCode == currencyCode)
				{
					result = pbe;
					break;
				}
			}
		}
		return result;
	} 	
	
	/*
		Obtains all Active Pricebook Entries for given Pricebook and Product2 Ids
	*/
	public static Map<Id, List<PricebookEntry>> GetPriceBookEntriesByPricebookProduct(Set<Id> pricebookIds, Set<Id> productIds)
	{
		Map<Id, List<PricebookEntry>> results = new Map<Id, List<PricebookEntry>>();
		for (PricebookEntry pbe : [SELECT	Id, Pricebook2Id, Product2Id, CurrencyIsoCode, UnitPrice 
								   FROM 	PricebookEntry 
								   WHERE 	IsActive = true 
								   AND		Pricebook2Id IN :pricebookIds 
								   AND		Product2Id IN :productIds]) 
		{
			if (!results.containsKey(pbe.Pricebook2Id))
			{
				results.put(pbe.Pricebook2Id, new List<PricebookEntry>());
			}
			results.get(pbe.Pricebook2Id).add(pbe);
		}
		return results;
	}
}