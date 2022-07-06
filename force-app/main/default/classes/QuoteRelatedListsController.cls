/********************************************************************
 * NewQuoteControllerV2
 *
 * Visualforce Controller used to display a custom related list of
 *				quote parts and attachments in order to prevent the user from
 *				deleting or changing records.
 * 
 * Author: Richard Jimenez
 * Created: 24-10-2013
 * Changes: 
 ********************************************************************/
public without sharing class QuoteRelatedListsController {
	
	private Quote__c quote;
	public list<Quote_Product__c> quoteProducts {get; set;}
	public list<Quote_Part__c> quoteParts {get; set;}
	public list<Attachment> docs {get; set;}
	public map<string, decimal> productDiscountMap {get; private set;}
	public boolean editMode {get; private set;}

	// TOP PAGE CONTROL
	public boolean reloadNeeded {get; private set;}
	public string reloadPageURL {get; private set;}

	public string selectedQuoteProductId {get; set;}

	public map<Id, Quote_Product__c> quoteProductsMap {get; set;}
	
	public QuoteRelatedListsController(ApexPages.StandardController std) {
		// Populate lists
		Id quoteId = std.getId();
		quote = bg_QuoteUtils.GetQuoteById(quoteId, true);
		quoteProducts = bg_QuoteUtils.GetQuoteProducts(quoteId, false);
		quoteProductsMap = new map<Id, Quote_Product__c>(quoteProducts);

		if(!quoteProducts.isEmpty()) {
			selectedQuoteProductId = quoteProducts[0].Id;
			GetQuoteParts();
		} else {
			quoteParts = new list<Quote_Part__c>();
		}

		docs = bg_AttachmentUtils.GetAttachments(quoteId);
		productDiscountMap = bg_QuoteApprovalUtils.GetProductDiscountMap(quoteId);
		
		// Get Quote Settings (used by VF page)
		QuoteSetting__c quoteSettings = bg_CustomSettingsUtils.GetQuoteSettings();
			
		// check quote status
		//editMode = (quote.DiscountStatus__c != quoteSettings.StatusApproved__c &&
		//			quote.DiscountStatus__c != quoteSettings.StatusWaiting__c);
		editMode = true;
	}
	
	// ----------------- NAVIGATION BUTTONS ----------------- //
	public string getPageURL() {
		/*
			Reload the full page
		*/
		ApexPages.StandardController sc = new ApexPages.StandardController(quote);	
		PageReference pageRef = sc.view();
		return pageRef.getUrl();	
	}
	
	public void ConfigurePrices() {
		/*
			Redirect to Configure Prices - Quote Part Grid
		*/
		ReloadPage('/' + bg_QuoteUtils.BuildQuotePartGridURL(quote.Id, bg_CustomSettingsUtils.GetPermissionSettings().CanEditPrices__c));
	}

	private void ReloadPage(string pageUrl) {
		/*
			Reload Page
		*/
		reloadNeeded = true;
		reloadPageURL = pageUrl;
	}
	
	public void GetQuoteParts() {
		/*
			Get the quote parts
		*/
		if(!bg_StringUtils.IsBlank(selectedQuoteProductId)) {
			quoteParts = bg_QuoteUtils.GetQuoteParts(quote.Id, selectedQuoteProductId);
		}
	}
}