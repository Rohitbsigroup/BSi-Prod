/********************************************************************
 * bg_FacetedSearchComponentDelegateUtils
 *
 * Test class: bg_FacetedSearchDelegateUtilsTest
 * Author: Ian Bowman
 * Created: 12/06/17
 * Changes:  
 *
 * Utility methods for handling one or more faceted search components presented
 * by a bg_FacetedSearchComponentDelegate
 *
 ********************************************************************/
 
public with sharing class bg_FacetedSearchComponentDelegateUtils {
  
    /*
        Builds a SOQL select based on the fields and values passed in paramByObjectAndFieldMap is the format returned from
        the facetedSearchComponent
    */
    public static String createQueryString(Map<String, Set<String>> fieldsToReturnByObjectName, String initialSearchTerm, Map<String, Map<String, Set<String>>> paramByObjectAndFieldMap)
    {
    	System.debug('+++ paramByObjectAndFieldMap = ' + paramByObjectAndFieldMap);
    	System.debug('+++ initialSearchTerm = ' + initialSearchTerm);
    	
    	
        
        /** @TODO extend to query multiple objects */
        String objectToSearch = (new list<string>(fieldsToReturnByObjectName.keySet()) )[0];
        String fieldsToReturn = '';
        for(String s:fieldsToReturnByObjectName.get(objectToSearch)) {
            fieldsToReturn += (fieldsToReturn==''?'':', ')+s;
        }
        
        String queryString = 'select ' + fieldsToReturn + ' from ' + objectToSearch;
        String paramString = '';
        Boolean objectCommaRequired = false;
        Boolean paramWhereRequired = true;
        Boolean paramAndRequired = false;
        
        if (initialSearchTerm != null)
        {
			paramString = paramString + ' where ' + initialSearchTerm;
            paramWhereRequired = false;
        	paramAndRequired = true;
        }
        
        if (paramByObjectAndFieldMap != null)
        {
            for ( String o : paramByObjectAndFieldMap.keySet())
            {
                //if (objectCommaRequired)
                //{
                //    queryString = queryString + ',';
                //}
                //queryString = queryString + o;
                objectCommaRequired = true;
                            
                for (String f : paramByObjectAndFieldMap.get(o).keySet())
                {
                
                    if (paramByObjectAndFieldMap.get(o).keySet().size() != 0)
                    {
                        if (paramWhereRequired)
                        {
                            paramString = paramString + ' where ';
                            paramWhereRequired = false;
                        }
                        if (paramAndRequired)
                        {
                            paramString = paramString + ' and ';
                        }
                        //paramString = paramString + f + ' in ' + ':valueSet';
                        paramAndRequired = true;
                        paramString = paramString + f + ' in ' ;
                        Set<String> paramSet = paramByObjectAndFieldMap.get(o).get(f);
                        String searchFields = GetParamString(paramSet);
                        paramString = paramString + searchFields ;
                    }
                }
            	paramAndRequired = false;
            }
        }
        System.debug('+++ paramString = ' + paramString);
        
        System.debug('+++ queryString + paramString = ' + queryString + paramString);
        return queryString + paramString;
    }
    
    private static String GetParamString(Set<String> params)
	{
		String paramString = '(';
		Boolean commaRequired = false;
		for( String s : params)
		{
			if (commaRequired == true)
			{
				paramString = paramString + ', ';
			}
			paramString = paramString + '\'' + s + '\'';
			commaRequired = true;
		}
		paramString = paramString + ')';
		return paramString;
	}
	
  /*
  	Get the components to be presented from the metadata type
  */
  /*
  public static List<List<Faceted_Search_Component__mdt>> getFacetedSearchComponents(String containerName)
  {
        // @TODO returns all metadata components currently, restrict by name of parenet metadata type 
        List<Faceted_Search_Component__mdt> componentMDTs = [ select Row_Number__c, Object_Name__c, Field_Name__c,
                                                                Rendered__c, Controlling_Object_Name__c, Controlling_Field_Name__c, Controlling_Field_Value__c
                                                                 from Faceted_Search_Component__mdt 
                                                                 where Container__r.DeveloperName = :containerName and active__c = true and Container__r.active__c = true
                                                                 order by Row_Number__c];
                                                                 
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
  */
  
}