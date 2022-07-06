/********************************************************************
 * bg_CustomMetadataUtilsTest
 *
 * Test class for: bg_CustomMetadataUtils
 * Author: Chris Eales
 * Created: 04/09/17
 * Changes: ADS 01-03-2017 - Case 34308 - Added Country Codes 
 *
 * test methods for bg_CustomMetadataUtils class
 *
 ********************************************************************/
@isTest
private class bg_CustomMetadataUtilsTest 
{
	/*
		Test method for getFacetedSearchComponents
		Tests for empty results when invalid container supplied
	*/
	static testMethod void testgetFacetedSearchComponentsInvalid()
	{
		List<List<Faceted_Search_Component__mdt>> results;
		String containerName = 'TEST_CONTAINER';
		results = bg_CustomMetadataUtils.getFacetedSearchComponents(containerName);
		system.assertEquals(false, results == null);
		system.assertEquals(true, results.isEmpty());
		
	}

	/*
		Test method for getFacetedSearchComponents
		Tests valid results when valid container supplied - PRODUCT_SEARCH
	*/
	static testMethod void testgetFacetedSearchComponentsValidPRODUCT()
	{
		List<List<Faceted_Search_Component__mdt>> results;
		String containerName = bg_CustomMetadataUtils.PRODUCT_SEARCH_CONTAINER;
		results = bg_CustomMetadataUtils.getFacetedSearchComponents(containerName);
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(true, results.size()>=1);
	}


	/*
		Test method for GetSearchResultFields
		Tests for empty results when invalid container supplied
	*/
	static testMethod void testGetSearchResultFieldsInvalid()
	{
		List<Faceted_Search_Result_Fields__mdt> results;
		String containerName = 'TEST_CONTAINER';
		results = bg_CustomMetadataUtils.GetSearchResultFields(containerName);
		system.assertEquals(false, results == null);
		system.assertEquals(true, results.isEmpty());
		
	}

	/*
		Test method for GetSearchResultFields
		Tests valid results when valid container supplied - PRODUCT_SEARCH
	*/
	static testMethod void testGetSearchResultFieldsValidPRODUCT()
	{
		List<Faceted_Search_Result_Fields__mdt> results;
		String containerName = bg_CustomMetadataUtils.PRODUCT_SEARCH_CONTAINER;
		results = bg_CustomMetadataUtils.GetSearchResultFields(containerName);
		system.assertEquals(false, results == null);
		system.assertEquals(false, results.isEmpty());
		system.assertEquals(true, results.size()>=1);
	}
        
	/*
		Test method for getCountryCodeByCountryName
		Tests for empty results when invalid Country supplied
	*/
	static testMethod void testGetCountryCodeByCountryName()
	{
		final String theTestCountryName = 'TEST COUNTRY';
        String theCountryCode;
        
        Test.startTest();
        theCountryCode = bg_CustomMetadataUtils.getCountryCodeByCountryName(theTestCountryName);
        Test.stopTest();
        
		System.assert(String.isBlank(theCountryCode));
	} // testGetCountryCodeByCountryName
    
}