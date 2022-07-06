/********************************************************************
 * PropertyValueTriggerHandlerTest
 *
 * Test methods for PropertyValueTriggerHandler
 * 
 * 
 * Author: Richard Jimenez
 * Created: 07-01-2014
 * Changes: 
 ********************************************************************/
@isTest
private class PropertyValueTriggerHandlerTest {

	private static testMethod void testPropertyValueTriggerHandler() {
		/*
			Test PropertyValueTriggerHandler
			
			NOTE: Tests covered in bg_PropertyValueUtilsTest
		*/
		test.startTest();
			// INSERT TEST
			PropertyValue__c pv = bg_UnitTestHelper.GetPropertyValue('', null, '');
			// UPDATE TEST
			update pv;
		test.stopTest();		
	}
}