/********************************************************************
 * bg_StringUtils
 *
 * String Utility methods to support advanced string functions
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 29-09-2014 ASD BG - Added string to id/id to string methods
 ********************************************************************/
public class bg_StringUtils {

	public static boolean IsBlank(string value) {
		/*
			Return if string is null or blank
		*/
		return (value == null || value.trim() == '');
	}

	public static list<string> ConvertPicklistValueToList(string value) {
		/* Return picklist value as list of string */
		return ConvertPicklistValueToList(value, ';');
	}

	public static set<string> ConvertPicklistValueToSet(string value) {
		/* Return picklist value as set of string */
		return ConvertPicklistValueToSet(value, ';');
	}

	public static set<string> ConvertPicklistValueToSet(string value, string delimiter) {
		/* Return picklist value as set of string */		
		return new set<string>(ConvertPicklistValueToList(value, delimiter));
	}

	public static list<string> ConvertPicklistValueToList(string value, string delimiter) {
		/*
			Return picklist value as list of string
		*/
		if(IsBlank(value)) {
			return new list<string>();
		} else {
			return value.split(delimiter);
		}
	}

	public static string ConvertToPicklistValue(set<string> valueSet) {
		/*
			Return picklist value as list of string using a set
		*/			
		return ConvertToPicklistValue(valueSet, ';');
	}

	public static string ConvertToPicklistValue(set<string> valueSet, string delimiter) {
		/*
			Return picklist value as list of string using a set
		*/			
		return ConvertToPicklistValue(new list<string>(valueSet), delimiter);
	}

	public static string ConvertToPicklistValue(list<string> valueList) {
		return ConvertToPicklistValue(valueList, ';');
	}
	
	public static string ConvertToPicklistValue(list<string> valueList, string delimiter) {
		/*
			Return picklist value as list of string
		*/		
		string result = '';
		for(string value : valueList) {
			result += value + delimiter;
		}
		// remove last semi-colon
		if(result.length() != 0) {
			result = result.substring(0, result.length()-1);
		}
		return result; // return semi-colon string
	}

	public static set<string> GetObjectStringSet(list<sObject> values, string fieldName) {
		/*
			Return list of string from list of sObjects values
		*/
		set<string> valueSet = new set<string>();
		for(sObject obj : values) {
			valueSet.add(string.valueOf(obj.get(fieldName)));
		}
		return valueSet;
	}

	public static list<sObject> GetBlankValuesList(list<sObject> values, string searchFieldName) {
		/*
			Find blank value
		*/
		list<sObject> results = new list<sObject>();
		for(sObject obj : values) {
			if(obj.get(searchFieldName) == null || string.valueOf(obj.get(searchFieldName)) == '') {
				results.add(obj);
			}			
		}
		return results;
	}
	
	public static string RemoveSpaces(string text) {
		/* Remove Spaces from string */
		return text.replace(' ', '');	
	}

	public static string AddValueToPicklistString(string pickListValue, string newValue) {
		/*
			Method to add value to picklist string
		*/
		set<string> valueSet = ConvertPicklistValueToSet(pickListValue);
		valueSet.add(newValue);
		return ConvertToPicklistValue(valueSet);
	}
	
	public static String convertListOfIdsToString(List<Id> Ids)
	{
		String toReturn = '';
		if(Ids.size() != 0)
		{
			for(Id i : Ids)
			{
				toReturn += i + ',';
			}
			toReturn = toReturn.Substring(0,toReturn.length()-1);
		}
		
		return toReturn;
	}
	
	public static List<Id> convertStringToListOfIds(String str)
	{
		List<Id> toReturn = new List<Id>();
		if(!IsBlank(str))
		{
			for(String s : str.split(',',0))
			{
				toReturn.add(Id.valueOf(s));
			}
		}
		
		return toReturn;
	}
	
	public static String truncateString(String str, Integer len)
	{
		String toReturn = str.substring(0, len);
		
		return toReturn;
	} 
	
	/************************************************************************/
	/* TEST METHODS - bg_StringUtilsTest                                    */	
	/************************************************************************/
}