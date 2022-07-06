/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         31/01/2012
* Description:  Visualforce Controller used to set a quote as Main Quote.
*				All the other quote are updated to false.
*
*       
**/
public with sharing class MainQuoteController {
	
	public List<Quote__c> quotes;
	public Quote__c main;
	
	public Boolean showBack		{get; set;}
	
	public MainQuoteController() {
		// Intitializing...
		String idMain = Apexpages.currentPage().getParameters().get('quoteId');
		quotes = new List<Quote__c>();
		showBack = false;
		
		main = [SELECT Main_Quote__c, Opportunity_Name__c FROM Quote__c WHERE Id =:idMain];
		quotes = [SELECT Main_Quote__c FROM Quote__c WHERE Opportunity_Name__c =:main.Opportunity_Name__c AND Id !=:idMain];
	}
	
	public Pagereference makeMainQuote() {
		Pagereference pageO;
		try {
			for (Quote__c q : quotes) {
				q.Main_Quote__c = false;
			}
			main.Main_Quote__c = true;
			quotes.add(main);
			update quotes;
			pageO = new Pagereference('/' + main.Opportunity_Name__c);
		} catch (DmlException dml) {
			showBack = true;
			ApexPages.addMessages(dml);
            pageO = null;
		}
		
		return pageO;
	}
	
	public Pagereference back() {
		Pagereference pageQ = new Pagereference('/' + main.Id);
		return pageQ;
	}
}