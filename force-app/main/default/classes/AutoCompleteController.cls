/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         08/03/2012
* Description:  Generic Controller for auto complete Component. 
*
*       
**/
global class AutoCompleteController {
	@RemoteAction
	global static SObject[] findSObjects(String obj, String qry, String addFields, String queryFields, String fixedSearch) {
		// Manage the list of fields (Comma separated list)
		List<String> fieldList; // fields in search
		List<String> queryList; // fields in query
		if (addFields != null) fieldList = addFields.split(',');
		if (queryFields != null) queryList = queryFields.split(',');
		
		// Check to see if the object passed is valid
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		Schema.SObjectType sot = gd.get(obj);
		if (sot == null) {
			// Object name not valid
			return null;
		}
		
		// Create the filter text
		String filter = ' like \'%' + String.escapeSingleQuotes(qry) + '%\'';
		// Building the dynamic soql query
		String soql = 'SELECT Id, Name';
		// Adding additional fields to the query
		if (queryList != null) {
			for (String s : queryList) {
				soql += ', ' + s;
			}
		}
		// add the object and filter by name to the soql
		soql += ' FROM ' + obj + ' WHERE ' + fixedSearch + ' (name' + filter;
		// add the filter by additional fields to the soql
		if (fieldList != null) {
			for (String s : fieldList) {
				soql += ' or ' + s + filter;
			}
		}
		soql += ') order by Name limit 20';
		
		List<sObject> L = new List<sObject>();
		try {
			L = Database.query(soql);
		}
		catch (QueryException e) {
			return null;
		}
		return L;
	}
	
	// TESTING: 92%
	@isTest
	static void testAutoComplete() {
		Account acc = TestData.getTestAccount();
		acc.Name = 'Test';
		acc.BillingStreet = 'Test';
		insert acc;
		AutoCompleteController.findSObjects('Account','Test','Name','Name','BillingStreet = \'Test\' and'); 
	}
}