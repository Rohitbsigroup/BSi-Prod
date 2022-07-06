/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         22/11/2011
* Description:  TEST CLASS: SiteUploader
*
* ------------------
* TESTING:		 80%
* ------------------
*       
**/
@isTest
private class SiteUploaderTest {
	// Testing uploading a csv
    static testMethod void uploadCSVTest() {
    	// Set up data
    	Account acc = TestData.getTestAccount();
    	insert acc;
    	Contact con = TestData.getTestContact();
    	con.AccountId = acc.Id;
    	insert con;
    	
    	Test.setCurrentPage(Page.siteUploader);
    	ApexPages.currentPage().getParameters().put('accountId', acc.Id);
    	SiteUploader controller = new SiteUploader();
    	
    	// Upload a test csv
    	String testCSV = 	 'Name,City__c,Country__c\r'
    					   	+'Name,City,Country\r'
    					   	+'Test,Test,GB\r'
    					   	+'Test,"Test,Comma",GB\r'
    					   	+'Test,"Test""Doublequote",GB\r'
    					   	+'Test,"Test\nNewline",GB';
    	controller.docfile.body = Blob.valueOf(testCSV);
    	controller.readFile();
    	
    	// Check expected result - 1 record
    	System.assertEquals(controller.getuploadedSites().size(),4);
    	
    	System.assertEquals(controller.back().getUrl(),'/' + acc.Id);
    	
    	controller.getSuccess();
    	controller.getErrors();
    	controller.getCustomers();
    	controller.customer = con.Id;
    	controller.sendCSV();
    	
    	// Check format Errors
    	testCSV = 'Wrongformat;""';
    	controller.docfile.body = Blob.valueOf(testCSV);
    	controller.readFile();
    	// Check that no other sites has been added
    	System.assertEquals(controller.getuploadedSites(),null);
    }
}