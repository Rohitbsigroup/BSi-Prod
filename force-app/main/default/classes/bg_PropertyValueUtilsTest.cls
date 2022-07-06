/********************************************************************
 * bg_ProductUtilsTest
 *
 * Test methods for Product Utility class
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 ********************************************************************/
@isTest
private class bg_PropertyValueUtilsTest {

	private static testMethod void testPopulateObjectsWithPropertyValues() {
		/*
			Test PopulateObjectsWithPropertyValues Method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';

		Product__c product = bg_UnitTestHelper.GetProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);

		string textValue = 'UT SCOPE TEST';
		string alias = bg_PropertyValueUtils.PROPERTYALIAS_SCOPE;

		test.startTest();
			// INSERT TEST
			PropertyValue__c pv = bg_UnitTestHelper.GetPropertyValue(alias, quoteProduct.Id, textValue);
			// Check Scope is copied onto Quote Product
			quoteProduct = [SELECT Scope__c FROM Quote_Product__c WHERE Id = :quoteProduct.Id];
			system.assertEquals(textValue, quoteProduct.Scope__c);
			
			// UPDATE TEST
			textValue = 'UT SCOPE TEST 2';
			pv.TextValue__c = textValue;
			update pv;
			quoteProduct = [SELECT Scope__c FROM Quote_Product__c WHERE Id = :quoteProduct.Id];
			system.assertEquals(textValue, quoteProduct.Scope__c);
		test.stopTest();
	}
	
	private static testMethod void testUpdatePropertyValuesSequence() {
		/*
			Test PopulateObjectsWithPropertyValues Method
		*/
		bg_UnitTestHelper.GetDefaultCountrySetting();
		string productName = 'ISO 9001';

		Product__c product = bg_UnitTestHelper.GetProduct(productName);
        Quote__c quote = bg_UnitTestHelper.GetQuote();
		Quote_Product__c quoteProduct = bg_UnitTestHelper.GetQuoteProduct(quote, null, product);

        //string productGuid = 'A76A92FC-182F-4189-AE9A-545D08D43CC4';
        //string propertyGuid = '96BEEBB6-9EB7-4561-9A48-92B11782978A';         
     	//string productToPropertyGuid = '96BEEBB6-9EB7-4561-9A48-92B117829781';
     	
		//Product__c prod = bg_UnitTestHelper.GetProductWithGuid(productGuid);
		//Property__c prop = bg_UnitTestHelper.GetProperty('TestProperty1', propertyGuid);
		//ProductToProperty__c p2p = bg_UnitTestHelper.GetProductToProperty(prop, prod, productToPropertyGuid);

		string textValue = 'UT SCOPE TEST';
		string alias = bg_PropertyValueUtils.PROPERTYALIAS_SCOPE;
		string templateType = 'Fact Validation';
		string overridePrompt = 'Override Prompt';
		
		// INSERT TEST
		PropertyValue__c pv = bg_UnitTestHelper.GetPropertyValue(alias, quoteProduct.Id, textValue, overridePrompt, templateType);

		test.startTest();
			// Update Property Values Sequence
			bg_PropertyValueUtils.UpdatePropertyValuesSequence(quote.Id);
			// Check Property value has been sequenced
			pv = [SELECT Id, FactOrderNo__c FROM PropertyValue__c WHERE Id = :pv.Id];
			system.assertEquals(1, pv.FactOrderNo__c);
		test.stopTest();		
	}
}