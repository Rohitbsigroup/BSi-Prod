/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         31/01/2012
* Description:  TEST CLASS: NewQuoteController
*
* ------------------
* TESTING:		 84%
* ------------------
*       
**/
@isTest
private class MainQuoteControllerTest {

    static testMethod void setAsMain() {
        // Set up data
        Account acc = TestData.getTestAccount();
		insert acc;
		Contact con = TestData.getTestContact();
		con.AccountId = acc.Id;
		insert con;
		Opportunity opty = TestData.getTestOpty();
		opty.AccountId = acc.Id;
		insert opty;
		Quote__c main = new Quote__c();
        main.Account__c = acc.Id;
        main.Opportunity_Name__c = opty.Id;
        main.Contact__c = con.Id;
        insert main;
        Quote__c quote = new Quote__c();
        quote.Account__c = acc.Id;
        quote.Opportunity_Name__c = opty.Id;
        quote.Contact__c = con.Id;
        insert quote;
        
        Test.setCurrentPage(Page.mainQuote);
		ApexPages.currentPage().getParameters().put('quoteId', main.Id);
        MainQuoteController controller = new MainQuoteController();
        
        System.assertEquals(controller.makeMainQuote().getURL(), '/' + opty.Id);
        System.assertEquals(controller.back().getURL(), '/' + main.Id);
    }
}