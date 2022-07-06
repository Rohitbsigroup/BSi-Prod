/********************************************************************
 * bg_ControllerUtils
 *
 * Controller Extension
 * 
 * Author: Richard Jimenez
 * Created: 
 * Changes:  
 *
 ********************************************************************/
public class bg_ControllerUtils {

	public static list<SelectOption> GetPicklistSelectOptions(sObject obj, string fieldName) {
		/* Method to Return list of picklist values from an sObject */
		Schema.sObjectType objType = obj.getSObjectType();
		return GetPicklistSelectOptions(objType, fieldName); 
	}

	public static list<SelectOption> GetPicklistSelectOptions(Schema.SObjectType objType, string fieldName) {
		/* Method to Return list of picklist values from an sObject */
		return GetPicklistSelectOptions(objType, fieldName, false);
	}

	public static list<SelectOption> GetPicklistSelectOptions(sObject obj, string fieldName, boolean useValueAsLabel) {
		/*
			Method to Return list of picklist values from an sObject
		*/
		if(obj != null) {
			Schema.sObjectType objType = obj.getSObjectType(); 
			return GetPicklistSelectOptions(objType, fieldName, useValueAsLabel);
		} else {
			return new list<SelectOption>();
		}
	}

	public static list<SelectOption> GetPicklistSelectOptions(Schema.SObjectType objType, string fieldName, boolean useValueAsLabel) {
		/*
			Method to Return list of picklist values from an sObject
		*/
		list<SelectOption> lstPickvals = new list<SelectOption>();
		Schema.DescribeSObjectResult objDescribe = objType.getDescribe();       
		map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap(); 
		list<Schema.PicklistEntry> values = fieldMap.get(fieldName).getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : values) {
			if(useValueAsLabel) {
				lstPickvals.add(new SelectOption(a.getValue(), a.getValue()));
			} else {
				lstPickvals.add(new SelectOption(a.getValue(), a.getLabel()));
			}
		}
		return lstPickvals;
	}
	
	public static list<SelectOption> CreateSelectOptions(set<Id> Ids, map<Id, sObject> objMap, string valueFieldName, string labelFieldName, boolean sortList, boolean addDefaultOption) {
		/*
			Method to create list of select options from a set of Ids and Map
		*/
		list<sObject> values = new list<sObject>();
		for(Id objId : Ids) {
			if(objMap.containsKey(objId)) {
				values.add(objMap.get(objId));
			}
		}
		return CreateSelectOptions(values, valueFieldName, labelFieldName, sortList, addDefaultOption);		
	}

	public static list<SelectOption> CreateSelectOptions(set<sObject> values, string valueFieldName, string labelFieldName, boolean sortList, boolean addDefaultOption) {
		/* 
			Method to create list of select options from a set of sObjects
		*/
		list<sObject> valueList = new list<sObject>(values);
		return CreateSelectOptions(valueList, valueFieldName, labelFieldName, sortList, addDefaultOption);		
	}


	public static list<SelectOption> CreateSelectOptions(list<sObject> values, string valueFieldName, string labelFieldName, boolean sortList, boolean addDefaultOption) {
		/*
			Method to create list of select options from a list of sObjects
		*/
		// initialise option items
    	list<SelectOption> optionItems = new list<SelectOption>();
		// add 'default' item
		if(addDefaultOption) {
			optionItems.add(new SelectOption('', '-- SELECT --'));
		}
		// add products
		set<string> valueSet = new set<string>();
    	for(sObject obj : values) {
    		if(obj.get(valueFieldName) != null) {
    			string value = string.valueOf(obj.get(valueFieldName));
    			string label = string.valueOf(obj.get(labelFieldName));
    			if(!valueSet.contains(value)) {
    				optionItems.add(new SelectOption(value, label));
    				valueSet.add(value);
    			}
    		}
    	}
		return optionItems; // return list of select options
	}

	public static list<SelectOption> CreateSelectOptions(set<string> valueSet, boolean sortList, boolean addDefaultOption) {
    	/*
    		Return list of Select Options (using a set)
    	*/  
		list<string> valuesList = new list<string>(valueSet);
		return CreateSelectOptions(valuesList, sortList, addDefaultOption);
	}

	public static list<SelectOption> CreateSelectOptions(list<string> values, boolean sortList, boolean addDefaultOption) {
    	/*
    		Return list of Select Options (using a list)
    	*/  
		// Copy values to a new list (so original list remains unsorted)
		list<string> valuesList = new list<string>(values);
    	if(sortList) { valuesList.sort(); }// sort alphabetical list
		// initialise option items
    	list<SelectOption> optionItems = new list<SelectOption>();
		// add 'default' item
		if(addDefaultOption) {
			optionItems.add(new SelectOption('', '-- SELECT --'));
		}
		// add option values items
    	for(string value : valuesList) {
    		if(value != null) {
    			optionItems.add(new SelectOption(value, value));
    		}
    	}
		return optionItems; // return list of select options    	
	}

	/************************************************************************/
	/* TEST METHODS - bg_ControllerUtilsTest                            */	
	/************************************************************************/	
}