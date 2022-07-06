/**
*	Author		: Prasad JN
*	Description	: Test Class for emq_SiteImportController
*/
@isTest
public with sharing class emq_SiteImportControllerTest {
    
    static testMethod void testReadFile() {
    	Account account = getAccount();
    	insert account;
    	
    	emq_SiteImportController controller = new emq_SiteImportController();
    	controller.CSVFile.body = controller.CSVFile.body = getCSV();
    	controller.AccountId = account.Id;
    	
		Test.startTest();		
		controller.readFile();			
    	System.assertEquals(2, controller.SitesToImport.size());
    	Test.stopTest();
    }
    
    static testMethod void testImportSites() {
    	Account account = getAccount();
    	insert account;
		
    	emq_SiteImportController controller = new emq_SiteImportController();
    	controller.CSVFile.body = getCSV();
    	controller.AccountId = account.Id;
    				
    	controller.readFile();
		Test.startTest();		
    	controller.importSites();
    	List<Site__c> sites = [SELECT Id FROM Site__c WHERE Account__c = :account.Id];
    	//System will create a default site so expected is CSV rows + 1
    	System.assertEquals(3, sites.size());
    	Test.stopTest();
    }
    
    static Blob getCSV(){
    	String sampleCSV = 'Name,Street,City,State,Country,Post Code,Site Phone,No of Employees\r' +
							'Test Site 1,3 Edgar Buildings,Bath,Cardiff,United Kingdom,560079,99877161,12\r' +
							'Test Site 2,44-46 Morningside Road,Edinburgh,Scotland,United Kingdom,560989,76551776,234\r';
		return Blob.valueOf(sampleCSV);
    }
    
    static Account getAccount(){
    	Account account = new Account();
    	account.Name = 'BSI Test Account';
    	account.BillingCity = 'LONDON';
		account.BillingCountry = 'GB';
		    	
    	return account;
    }
}