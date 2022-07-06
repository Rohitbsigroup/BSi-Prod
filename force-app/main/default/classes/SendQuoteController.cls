/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         08/02/2012
* Description:  Visualforce Controller used to smooth the process of sending a
*				quote to the Customer to validate through the Customer Portal. 
*
*       
**/
public class SendQuoteController {
	
	public User 				customer		{get; set;}
	public transient Attachment	pdf				{get; set;}
	public Quote__c				quote			{get; set;}	
	public Note					bsiComment		{get; set;}
	public User					accOwner		{get; set;}
	public List<Note>			comments		{get; set;}
	
	public Boolean				noPDF			{get; set;}
	//public Boolean				isPending		{get; set;}
	
	public Boolean				historyView		{get; set;}
	
	private Opportunity opty;
	
	private QuoteSetting__c setting = QuoteSetting__c.getInstance();
	
	public SendQuoteController() {
		// Initializing...
		String idQuote = Apexpages.currentPage().getParameters().get('quoId');
		bsiComment = new Note();
		quote = [SELECT Name, Main_Quote__c, Opportunity_Name__c, Contact__c, Contact__r.FirstName, ValidationStatus__c,
				Contact__r.LastName, Contact__r.Email, Account__r.Name, Account__r.BillingCountry, Account__r.OwnerId 
				FROM Quote__c WHERE Id =:idQuote];
		opty  = [SELECT MainQuotePDFid__c FROM Opportunity WHERE Id =:quote.Opportunity_Name__c];
		accOwner = [SELECT UserRoleId FROM User WHERE Id =: quote.Account__r.OwnerId];
		
		// Search for existing user
		List<User> temp = [SELECT FirstName, LastName, Email, Username FROM User WHERE ContactId =:quote.Contact__c limit 1];
		if (!temp.isEmpty()) customer = temp.get(0);
		
		// Create the Portal User
		else {	
			customer = Utility.createPortalUser(quote.Contact__c, quote.Contact__r.Email, 
									quote.Contact__r.FirstName, quote.Contact__r.LastName, 
									quote.Account__r.Name, quote.Account__r.BillingCountry);
		}
									
		
		// Check if is History View (only comments and PDF preview) - Status = Approved
		if (quote.ValidationStatus__c == setting.StatusWaiting__c || quote.ValidationStatus__c == setting.StatusApproved__c) 	
			historyView = true;
		else 
			historyView = false;
			
		
		// Comments History
		comments = [SELECT Title, Owner.Name, CreatedDate, Body FROM Note 
					WHERE ParentId =:quote.Id
					order by CreatedDate asc];	
		
		// BSI Comment Setup
		bsiComment.ParentId = quote.Id;
		bsiComment.Title = quote.ValidationStatus__c;
		bsiComment.Body =  Label.DefaultCustomerMessage;						
		
		// Update Opportunity with ID of PDF Attachment - (Facts Summary Document)
		List<Attachment> pdfs = [SELECT Id FROM Attachment 
								WHERE ParentId =:quote.Id 
								AND Name like :quote.Name+'%' order by CreatedDate desc];
		if (!pdfs.isEmpty()) {
			noPDF = false;
			pdf = pdfs.get(0);
			opty.MainQuotePDFid__c = pdfs.get(0).Id;
		} else {
			noPDF = true;
		}		 					
	}
	
	public Pagereference startValidation() {
		
		Pagereference pageQ;

		try {
			// Insert Portal User if not enabled
			if (customer.Id == null) insert customer;
			
			// Update quote Status
			quote.ValidationStatus__c = setting.StatusWaiting__c;
			quote.SentDate__c		  = DateTime.now();
			update quote;
			
			// Update opty pdf reference
			update opty;
			
			// Manual Share to Customer Portal User to avoid visibility issues
			/*Quote__Share shareToCustomer = new Quote__Share();
			shareToCustomer.RowCause = Schema.Quote__Share.RowCause.Manual;
			shareToCustomer.UserOrGroupId = customer.Id;
			shareToCustomer.ParentId = quote.Id;
			shareToCustomer.AccessLevel = 'Read'; 
			insert shareToCustomer;*/
			
			// Insert the comment
			insert bsiComment;
			
			// Redirect to Quote page
			pageQ = new Pagereference('/' + quote.Id);
		} catch (Exception dml) {
			Apexpages.addMessages(dml);
			pageQ = null;
		}
		
		return pageQ;
	}
	
	public Pagereference back() {
		Pagereference pageQ = new Pagereference('/' + quote.Id);
		return pageQ;
	}
}