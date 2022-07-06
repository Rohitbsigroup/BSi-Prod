/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         10/02/2012
* Description:  TEST CLASS: CustomerSelfQuoteController
*
* ------------------
* TESTING:		 95%
* ------------------
*       
**/
@isTest
private class CustomerSelfQuoteControllerTest {
	
	// Testing cutomer Approving - Rejecting the Quote
    static testMethod void customerValidation() {
        // Set up data
        Account acc = TestData.getTestAccount();
		insert acc;
		Contact con = TestData.getTestContact();
		con.AccountId = acc.Id;
		insert con;
		Opportunity opty = TestData.getTestOpty();
		opty.AccountId = acc.Id;
		insert opty;
		Quote__c quote = TestData.getTestQuote(opty.Id,con.Id,acc.Id);
		QuoteSetting__c setting = QuoteSetting__c.getInstance();
		quote.ValidationStatus__c = setting.StatusWaiting__c;
		insert quote;
		Note usernote = new Note();
		usernote.Title = 'Approved';
		usernote.Body = 'Test reply';
		usernote.ParentId = quote.Id;
		// Fake Attachment
        Attachment pdf = new Attachment();
        pdf.Body = Blob.toPdf('QUOTE PDF');
        pdf.ParentId = quote.Id;
        pdf.Name = 'Test';
        insert pdf;
        // Create fake Portal User
		User customer = Utility.createPortalUser(con.Id, con.Email, con.FirstName, con.LastName, acc.Name, acc.BillingCountry);
		insert customer;
		
		CustomerSelfQuoteController controller;
		System.runAs(customer) {
			Test.setCurrentPage(Page.customerSelfQuote);
	        controller = new CustomerSelfQuoteController();
		}    
        controller.userComment = usernote;
        controller.quoteToApprove.ValidationCheck__c = true;
        
        // Approve quote
        controller.approveQuote();
        // Reject quote
        controller.declineQuote();
        // Approve quote
        controller.approveQuote(); // Called again to throw the exception
	        
    }
}