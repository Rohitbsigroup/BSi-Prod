/********************************************************************
 * bg_Utilities
 *
 * General Utility class
 * 
 * Author: Rob Earey
 * Created: 21-10-2013
 * Changes: 
 *		29-05-2015 RJ Added getInteger method
 ********************************************************************/
public with sharing class bg_Utilities 
{
	public static Decimal getDecimal(Decimal value) {
		/*
			Return Decimal value (zero if null)
		*/
    	if(value == null) return 0;
    	else return value;
  	}

	public static Integer getInteger(Decimal value) {
		return getInteger(value, 0);
	}
	
	public static Integer getInteger(Decimal value, integer defaultValue) {
		/*
			Return Decimal value (zero if null)
		*/
    	if(value == null) return defaultValue;
    	else return integer.valueOf(value);
  	}
  	
	private static map<string, map<string, Schema.SObjectField>> objectFieldMaps;	
  	public static map<string, Schema.SObjectField> GetObjectFieldMap(string objectName) {
		/* 
			Return Object Field Map		
		*/
		if(objectFieldMaps == null) {
			objectFieldMaps = new map<string, map<string, Schema.SObjectField>>();
		}
		if(!objectFieldMaps.containsKey(objectName)) {
			objectFieldMaps.put(objectName, Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap());
		}
		return objectFieldMaps.get(objectName);
  	}
}