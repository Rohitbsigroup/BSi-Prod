/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         19/01/2012
* Description:  Visualforce Controller used for self quoting validation
*				via Customer Portal. 
*
*       
**/
public without sharing class CustomerSelfQuoteController {
	
	public Quote__c		quoteToApprove	{get; set;}

	public String		quoteBP			{get; set;}
	public String		errorMessage	{get; set;}
	public Boolean		noQuote			{get; set;}
	public Boolean		isGuest			{get; set;}
	
	
	
	public Attachment	pdf				{get; set;}
	
	public Note			userComment		{get; set;}
	public List<Note>	comments		{get; set;}
	
	private Opportunity opty;
	private String		salesPersonName;
	
	QuoteSetting__c		setting = QuoteSetting__c.getInstance();
	SystemSetting__c	syst    = SystemSetting__c.getInstance();
	
	public CustomerSelfQuoteController() {
		// Initializing...	
		try {
			User customer 			= [SELECT Name, AccountId, ContactId FROM User WHERE Id =:UserInfo.getUserId()];
			List<Quote__c> quotes 	= [SELECT Name, ValidationCheck__c, Opportunity_Name__c, OwnerId 
										FROM Quote__c WHERE Account__c =:customer.AccountId 
							  		   	AND Contact__c =:customer.ContactId 
							  		   	AND ValidationStatus__c =:setting.StatusWaiting__c 
							  		   	order by CreatedDate desc limit 1];
			userComment = new Note();
			
			// Check if User is not logged in, and show 
			if (customer.Name == syst.GuestUserName__c) {
				noQuote = true;
				isGuest = true;
			} else if (!quotes.isEmpty()) {
				quoteToApprove = quotes.get(0);
				salesPersonName = [SELECT Name FROM User WHERE Id =:quoteToApprove.OwnerId].Name;
				
				// URL to BluePrint page
	        	// quoteBP = buildURL(quoteToApprove.Id);
	        	// Query for the Opportunity to update
	        	opty = [SELECT Id, ApprovedtoGenerateQuote__c FROM Opportunity WHERE Id=:quoteToApprove.Opportunity_Name__c];
	        	
	        	// Show the Quote PDF
				List<Attachment> pdfs = [SELECT Id FROM Attachment WHERE ParentId =:quoteToApprove.Id order by CreatedDate desc];
				if (!pdfs.isEmpty()) {
					pdf = pdfs.get(0);
				}	
	        	noQuote = false;
	        	
	        	// Comments History
				comments = [SELECT Title, Owner.Name, CreatedDate, Body FROM Note 
							WHERE ParentId =:quoteToApprove.Id
							order by CreatedDate asc];	
			
				// User Comment Setup
				userComment.ParentId = quoteToApprove.Id;
			
			} else {
				noQuote = true;
			}
			
		} catch (Exception ex) {
			system.debug('ex...' + ex);
		}
	}
	
	// APPROVE THE QUOTE
	public Pagereference approveQuote() {
		Savepoint sp = Database.setSavepoint();
		Pagereference retPage = null;
			
		try {
			quoteToApprove.ValidationStatus__c 	= setting.StatusApproved__c;
			quoteToApprove.ValidationDate__c	= DateTime.now();
			quoteToApprove.ValidatedBy__c 		= UserInfo.getName();
			// Update Opty with signed document ID
			// opty.ApprovedtoGenerateQuote__c		= true;
			// opty.MainQuotePDFid__c = pdf.Id;
			
			if (quoteToApprove.ValidationCheck__c) {
				try {
					Utility.lockQuoteTrigger = true;
					update quoteToApprove;
					update opty;
					retPage = page.customerSelfQuote;
					retPage.setRedirect(true);
					
					// Insert the comment
					userComment.Title = quoteToApprove.ValidationStatus__c;
					insert userComment;
				} catch (DmlException dml) {
					Database.rollback(sp);
					errorMessage = 'An error has occured. Please contact ' + salesPersonName; //dml.getDmlMessage(0);
				}
			} else {
				errorMessage = 'You need to accept Terms and Conditions';
			}
		} catch (Exception ex) {
			Database.rollback(sp);
		}

		return retPage;
	}
	
	// REJECT THE QUOTE
	public Pagereference declineQuote() {
		Savepoint sp = Database.setSavepoint();
		Pagereference retPage = null;

		quoteToApprove.ValidationStatus__c 	= setting.StatusRejected__c;
		quoteToApprove.ValidationDate__c 	= DateTime.now();
		quoteToApprove.ValidatedBy__c 		= UserInfo.getName();
		
		if (quoteToApprove.ValidationCheck__c) {
			try {
				Utility.lockQuoteTrigger = true;
				update quoteToApprove;
				retPage = page.customerSelfQuote;
				retPage.setRedirect(true);
				
				// Insert the comment
				userComment.Title = quoteToApprove.ValidationStatus__c;
				insert userComment;
			} catch (DmlException dml) {
				Database.rollback(sp);
				errorMessage = 'An error has occured. Please contact ' + salesPersonName; //dml.getDmlMessage(0);
			}
		} else {
			Database.rollback(sp);
			errorMessage = 'You need to accept Terms and Conditions';
		}
		
		return retPage;
	}

}