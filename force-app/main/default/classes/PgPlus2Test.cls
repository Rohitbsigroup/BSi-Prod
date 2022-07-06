@isTest
private class PgPlus2Test
{
    static testMethod void myUnitTest()
    {
		// Run the test
		Test.startTest();
		
		// Reference the parent class for coverage
		PgPlus2 parent = new PgPlus2();

		// Create an instance of the SOAP service
		PgPlus2.TrainingTaxCalculatorServiceSoap calculator = new PgPlus2.TrainingTaxCalculatorServiceSoap();

		// Add the authentication header
		PgPlus2.TrainingTaxCalculatorHeader header = new PgPlus2.TrainingTaxCalculatorHeader();
		header.UserName = 'xx';
		header.Password = 'xx';
		calculator.TrainingTaxCalculatorHeader = header;
		
		// Add the items
		List<PgPlus2.TrainingTaxCalculatorItem> parItems = new List<PgPlus2.TrainingTaxCalculatorItem>();
		PgPlus2.TrainingTaxCalculatorItem item = new PgPlus2.TrainingTaxCalculatorItem();
		item.Material = '000000000030208057';
		item.Quantity = 1;
		item.Price = 100.00;
		item.Currency_x = 'GBP';
		parItems.add(item);

		// Format the inputs
		String parSalesOrg = '1000';
		String parCurrency = 'GBP';
		String parCity = 'Bedford';
		String parRegion = '';
		String parCountry = 'GB';
		String parVatNumber = '';
		PgPlus2.ArrayOfTrainingTaxCalculatorItem parArrayOfItems = new PgPlus2.ArrayOfTrainingTaxCalculatorItem();
		parArrayOfItems.TrainingTaxCalculatorItem = parItems;

		// Call the calculator
		PgPlus2.TrainingTaxCalculatorResult result = calculator.TrainingTaxCalculate(parSalesOrg, parCurrency, parCity, parRegion, parCountry, parVatNumber, parArrayOfItems);
		
		Test.stopTest();
    }
}