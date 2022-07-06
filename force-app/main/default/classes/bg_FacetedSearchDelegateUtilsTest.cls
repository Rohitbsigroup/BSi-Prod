/********************************************************************
 * bg_FacetedSearchDelegateUtilsTest
 *
 * Test class for  bg_FacetedSearchComponentDelegateUtils
 * Author: Ian Bowman
 * Created: 12/06/17
 * Changes:  
 *
 *
 ********************************************************************/
@isTest
public with sharing class bg_FacetedSearchDelegateUtilsTest {
     
	public static testMethod void TestCreateQueryStringForOneObjectNullSearchTerm()
	{
    
    	Map<String, Set<String>> fieldsToReturnByObjectName = new Map<String, Set<String>>();
    	fieldsToReturnByObjectName.put('myObject', new Set<String>{'fieldOne', 'fieldTwo'});
    	
    	Map <String, Map<String, Set<String>>> paramByObjectAndFieldMap = new Map<String, Map<String, Set<String>>>();
		Map<String, Set<String>> valuesForFieldMap = new Map<String, Set<String>>();
		valuesForFieldMap.put('fieldOne', new Set<String>{'valueOne', 'valueTwo', 'valueThree'});
		paramByObjectAndFieldMap.put('myObject', valuesForFieldMap);
        String query = bg_FacetedSearchComponentDelegateUtils.createQueryString(fieldsToReturnByObjectName, null, paramByObjectAndFieldMap);
    	
    	String expectedResult = 'select fieldOne, fieldTwo from myObject where fieldOne in (\'valueOne\', \'valueTwo\', \'valueThree\')';
    	
    	System.assertEquals(expectedResult, query);
	}
	
	public static testMethod void TestCreateQueryStringForOneObjectWithSearchTerm()
	{
    
    	Map<String, Set<String>> fieldsToReturnByObjectName = new Map<String, Set<String>>();
    	fieldsToReturnByObjectName.put('myObject', new Set<String>{'fieldOne', 'fieldTwo'});
    	
    	Map <String, Map<String, Set<String>>> paramByObjectAndFieldMap = new Map<String, Map<String, Set<String>>>();
		Map<String, Set<String>> valuesForFieldMap = new Map<String, Set<String>>();
		valuesForFieldMap.put('fieldOne', new Set<String>{'valueOne', 'valueTwo', 'valueThree'});
		paramByObjectAndFieldMap.put('myObject', valuesForFieldMap);
		String initialSearchTerm = 'searchField=\'findthis\'';
        String query = bg_FacetedSearchComponentDelegateUtils.createQueryString(fieldsToReturnByObjectName, initialSearchTerm, paramByObjectAndFieldMap);
    	
    	String expectedResult = 'select fieldOne, fieldTwo from myObject where searchField=\'findthis\' and fieldOne in (\'valueOne\', \'valueTwo\', \'valueThree\')';
    	
    	System.assertEquals(expectedResult, query);
	}
	
	public static testMethod void TestGetFacetedSearchComponents()
	{
		
		List<List<Faceted_Search_Component__mdt>> productSearchMDTList = bg_CustomMetadataUtils.getFacetedSearchComponents('Product_Search');
		
		List<Faceted_Search_Component__mdt> expectedMDTs = [select id, Row_Number__c from Faceted_Search_Component__mdt where active__c = true and Container__r.DeveloperName = 'Product_Search'];
		Map <Decimal, Integer> numberOfComponentsByRowNumber = new Map <Decimal, Integer>();
		for (Faceted_Search_Component__mdt c : expectedMDTs)
		{
			if (!numberOfComponentsByRowNumber.containsKey(c.Row_Number__c))
			{
				numberOfComponentsByRowNumber.put(c.Row_Number__c, 0);
			}
			Integer i = numberOfComponentsByRowNumber.get(c.Row_Number__c);
			numberOfComponentsByRowNumber.put(c.Row_Number__c, ++i);
		}
		System.debug('++++ numberOfComponentsByRowNumber = ' + numberOfComponentsByRowNumber);
		for(List<Faceted_Search_Component__mdt> row  : productSearchMDTList)
		{
			System.assertEquals(numberOfComponentsByRowNumber.get(row[0].Row_Number__c), row.size());
		}
		
	}
    
}