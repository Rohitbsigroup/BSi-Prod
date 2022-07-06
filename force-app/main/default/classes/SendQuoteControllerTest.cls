/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         08/02/2012
* Description:  TEST CLASS: SendQuoteController
*
* ------------------
* TESTING:		 92%
* ------------------
*       
**/
@isTest
private class SendQuoteControllerTest {
	
	// Testing submitting quote to Customer
    static testMethod void sendQuoteTest() {
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
		insert quote;
		Note bsinote = new Note();
		bsinote.Title = 'Pending';
		bsinote.Body = 'Test';
		bsinote.ParentId = quote.Id;
		// Fake Attachment
        Attachment pdf = new Attachment();
        pdf.Body = Blob.toPdf('QUOTE PDF');
        pdf.ParentId = quote.Id;
        pdf.Name = 'Test';
        insert pdf;
		
		Test.setCurrentPage(Page.sendQuote);
		ApexPages.currentPage().getParameters().put('quoId', quote.Id);
        SendQuoteController controller = new SendQuoteController();
        
        System.assertEquals(controller.back().getURL(), '/' + quote.Id);
        
        controller.bsiComment = bsinote;
        
        System.assertEquals(controller.startValidation().getURL(), '/' + quote.Id);
        
    }
}