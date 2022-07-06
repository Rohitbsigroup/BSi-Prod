/********************************************************************
 * bg_ProductInterestUtils
 *
 * Utility methods to support Accounts
 * Test Class : bg_ProductInterestUtilsTest
 *
 * 
 * Author: Richard Jimenez
 * Created: 11-11-2014 
 ********************************************************************/
public class bg_ProductInterestUtils {

	private static string GetIncludesString(set<string> stringSet) {
		/* Return Includes String */
  		string stringList = '';
  		if(stringSet != null && !stringSet.isEmpty()) {
			// Filter List of available Products based on sites' countries
			for (string c : stringSet) {
				stringList += '\'' + c + '\''+',';
			}
			stringList = stringList.substring(0, stringList.length()-1);
  		}
  		return stringList;
	}
	
	public static list<Product_Classification_Relationship__c> GetSuggestedProductClassificationRelationships(list<string> pcNames) {
		/* Return list of suggested product classifications */		
		return GetSuggestedProductClassificationRelationships(pcNames, new set<string>(), 0, new set<string>(), new set<string>(), new set<string>());
	}
	
	public static list<Product_Classification_Relationship__c> GetSuggestedProductClassificationRelationships(list<string> pcNames, string country, integer companySize, string sector, string certStages, string customerBuyStage) {
		/* Return list of suggested product classifications */		
		return GetSuggestedProductClassificationRelationships(pcNames, new set<string>{country}, companySize, new set<string>{sector}, new set<string>{certStages}, new set<string>{customerBuyStage});
	}

	public static list<Product_Classification_Relationship__c> GetSuggestedProductClassificationRelationships(list<string> pcNames, set<string> countries, integer companySize, set<string> sectors, set<string> certStages, set<string> customerBuyingStages) {
		/*
			Return list of suggested product classifications relationships
		*/
		string query = 'SELECT SuggestedProductClassificationName__c, SuggestedProductAndReason__c ';
		query += 'FROM Product_Classification_Relationship__c ';
		query += 'WHERE ProductClassification__r.Product__c IN :pcNames ';		
		query += 'AND SuggestedProductClassificationName__c NOT IN :pcNames ';

		// Filter on Region
		list<string> regionList = new list<string>();
		string globalRegion = 'GLOBAL';
		regionList.add(globalRegion);

		if(!countries.isEmpty()) {
			for(AggregateResult ar : [SELECT Region__c FROM Country_Currency__c 
										WHERE Name IN :countries
											AND Region__c != null
										GROUP BY Region__c]) {
				regionList.add(string.valueOf(ar.get('Region__c')));											
			}
		}
		
		string otherRegion = 'OTHER';
		regionList.add(otherRegion);

		query += 'AND Region__c IN :regionList ';

		// Filter on Country
		string countryList = GetIncludesString(countries);
  		if(!string.IsBlank(countryList)) {
			query += 'AND (Country__c = NULL ';
   			query += ' OR Country__c INCLUDES (' + countryList + ') ';
			query += ') ';
  		}

		// Filter on Sector
		string sectorList = GetIncludesString(sectors);
  		if(!string.IsBlank(sectorList)) {
			query += 'AND (Sector__c = NULL ';
   			query += 'OR Sector__c INCLUDES (' + sectorList + ') ';
			query += ') ';
		}

		string certStageList = GetIncludesString(certStages);
  		if(!string.IsBlank(certStageList)) {
			query += 'AND (BSIReadiness__c = NULL ';
   			query += 'OR BSIReadiness__c INCLUDES (' + certStageList + ') ';
   			query += ') ';
		}

		string custBuyingStageList = GetIncludesString(customerBuyingStages);
  		if(!string.IsBlank(certStageList)) {
			query += 'AND (CustomerBuyingStage__c = NULL ';
   			query += 'OR CustomerBuyingStage__c INCLUDES (' + custBuyingStageList + ') ';
   			query += ') ';
		}
		
		if(companySize != null && companySize > 0) {
			query += 'AND ( ' +
				'(CompanySizeMin__c = NULL AND CompanySizeMax__c = NULL) OR ' +
				'(CompanySizeMin__c = NULL AND CompanySizeMax__c <= :companySize) OR ' +
				'(CompanySizeMin__c >= :companySize AND CompanySizeMax__c = NULL) OR ' +
				'(CompanySizeMin__c >= :companySize AND CompanySizeMax__c <= :companySize)) ';
		}

  		query += 'ORDER BY Ranking__c, SuggestedProductClassificationName__c ASC';

  		system.debug('GetSuggestedProductClassifications: ' + query);
		return database.query(query);	
	}
}