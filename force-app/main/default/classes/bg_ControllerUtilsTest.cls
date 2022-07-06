/********************************************************************
 * bg_ControllerUtilsTest
 *
 * Test class for bg_ControllerUtils
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 ********************************************************************/
@isTest
private class bg_ControllerUtilsTest {

	private static testMethod void testCreateSelectOptions1() {
		/*
			Test CreateSelectOptions method using a set of strings
		*/
		set<string> values = new set<string>{'a','b','c'};		
		list<SelectOption> options = bg_ControllerUtils.CreateSelectOptions(values, true, true);
		system.assertEquals(4, options.size());
	}

	private static testMethod void testCreateSelectOptions2() {
		/*
			Test CreateSelectOptions method using a list of strings
		*/
		list<string> values = new list<string>{'a','b','c'};		
		list<SelectOption> options = bg_ControllerUtils.CreateSelectOptions(values, true, true);
		system.assertEquals(4, options.size());
	}
	
	private static testMethod void testGetPicklistSelectOptions() {
		/*
			Test GetPicklistSelectOptions method using an sObject
		*/

		// Get instance of object
		Account acc = new Account();
		list<SelectOption> options;
		
		options = bg_ControllerUtils.GetPicklistSelectOptions(acc, 'CurrencyIsoCode');
		system.assertEquals(true, options.size() > 0);	

		options = bg_ControllerUtils.GetPicklistSelectOptions(acc, 'CurrencyIsoCode', true);
		system.assertEquals(true, options.size() > 0);	
	}
	
	private static testMethod void testCreateSelectOptions() {
		/*
			Test CreateSelectOptions method
		*/
		list<Account> accs = new list<Account>();
		accs.add(new Account(name='UT1'));
		accs.add(new Account(name='UT2'));
		list<SelectOption> options = bg_ControllerUtils.CreateSelectOptions(accs, 'name', 'name', true, true);
		system.assertEquals(3, options.size());	
	}
	
	private static testMethod void testCreateSelectOptions3() {
		/*
			Test CreateSelectOptions method
		*/
		Contact con = bg_UnitTestHelper.GetContact('Name');		
		set<Id> Ids = new set<Id>{con.Id};
		map<Id, Contact> objMap = new map<Id, Contact>();
		objMap.put(con.Id, con);
		test.startTest();
			system.assertEquals(2, bg_ControllerUtils.CreateSelectOptions(Ids, objMap, 'lastname', 'lastname', true, true).size());
			system.assertEquals(2, bg_ControllerUtils.CreateSelectOptions(new set<sObject>{objMap.values()}, 'lastname', 'lastname', true, true).size());
		test.stopTest();	
	}
}