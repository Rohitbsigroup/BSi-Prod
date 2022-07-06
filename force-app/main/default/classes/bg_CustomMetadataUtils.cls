/********************************************************************
 * bg_CustomMetadataUtils
 *
 * Test class: bg_CustomMetadataUtilsTest
 * Author: Ian Bowman
 * Created: 27/06/17
 * Changes:  
 *
 * Utility methods to handle custom metadata
 *
 *	CPE 04-09-2017	Added constants for Search meta containers
 *  ADS 01-03-2017  Case 34308 - Added Country Codes
 ********************************************************************/
public with sharing class bg_CustomMetadataUtils 
{
	public static String PRODUCT_SEARCH_CONTAINER = 'Product_Search';
	public static String PROJECT_SEARCH_CONTAINER = 'Project_Search';
	
	
	/*
		Retrieve the Custom metadata that defines the fields to be queried and whether they should be displayed
	*/
	public static List<Faceted_Search_Result_Fields__mdt> GetSearchResultFields(String containerName)
	{
		List <Faceted_Search_Result_Fields__mdt> metadataFields = [select id, Display_Name__c, Display_Order__c, Field_API_Name__c from Faceted_Search_Result_Fields__mdt 
																	where Container__r.DeveloperName = :containerName order by Display_Order__c ];
																	
		return metadataFields;
																	
	}
	
  /*
  	Get the components to be presented from the metadata type
  */
  public static List<List<Faceted_Search_Component__mdt>> getFacetedSearchComponents(String containerName)
  {
        List<Faceted_Search_Component__mdt> componentMDTs = [ select Row_Number__c, Object_Name__c, Field_Name__c,
                                                                Rendered__c, Controlling_Object_Name__c, Controlling_Field_Name__c, Controlling_Field_Value__c,
                                                                Display_Order_Within_Row__c
                                                                 from Faceted_Search_Component__mdt 
                                                                 where Container__r.DeveloperName = :containerName and active__c = true and Container__r.active__c = true
                                                                 order by Row_Number__c, Display_Order_Within_Row__c];
                                                                 
        // loop over meta data and organise it into rows
        Map<Integer, List<Faceted_Search_Component__mdt>> metadataMap = new Map<Integer, List<Faceted_Search_Component__mdt>>();
        for (Faceted_Search_Component__mdt c : componentMDTs)
        {
            
            String componentKey = c.Object_Name__c.trim() + c.Field_Name__c.trim();
            
            if (!metadataMap.containsKey((Integer)c.Row_Number__c))
            {
                metadataMap.put((Integer)c.Row_Number__c, new List<Faceted_Search_Component__mdt>());
            }

            // add the component to the correct row
            metadataMap.get((Integer)c.Row_Number__c).add(c);
        }
        
        List<Integer> keyList = new List<Integer>(metadataMap.keySet());
        keyList.sort();
        List<List<Faceted_Search_Component__mdt>> metadataList = new List<List<Faceted_Search_Component__mdt>>();
        for (Integer i : metadataMap.keySet())
        {
            metadataList.add(metadataMap.get(i));
        }
        
        return metadataList;        
  }

    /*
        Retrieve the Country Code Custom Metadata
    */    
    private static List<Country_Code__mdt> getCountryCodes()
    {
        return [SELECT Country_Name__c,
                ISO_Alpha_2_Country_Code__c
                FROM Country_Code__mdt];
    } // getCountryCodes
    
    private static Map<String, String> countryToCountryCodeMap;
    
	/*
		Retrieve the Custom Metadata that defines the Country Code for a Country Names
	*/    
    private static Map<String, String> getCountryToCountryCodeMap()
    {
        
        if (null == countryToCountryCodeMap)
        {
            countryToCountryCodeMap = new Map<String, String>();

            for (Country_Code__mdt theCountryCode : getCountryCodes())
            {
                countryToCountryCodeMap.put(theCountryCode.Country_Name__c, theCountryCode.ISO_Alpha_2_Country_Code__c);
            }
            
        }        
        
        return countryToCountryCodeMap;
    } // getCountryToCountryCodeMap
    
	/*
		Retrieve the Custom Metadata that defines the Country Code for a given Country Name
	*/    
    public static String getCountryCodeByCountryName(final String theCountryName)
    {
        final Map<String, String> theCountryToCountryCodeMap = getCountryToCountryCodeMap();
        return theCountryToCountryCodeMap.containsKey(theCountryName) ? theCountryToCountryCodeMap.get(theCountryName) : null;
    } // getCountryCodeByCountryName
    
}