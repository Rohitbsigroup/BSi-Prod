public class CiFeedbackController
{
	// Passed values	
	public Id passedId { get; set; }
	public String retURL { get; set; }
	
	// Internal properties
	public String objectType { get; set; }
	public String objectName { get; set; }
	public Boolean isLocked { get; set; }
	public String emailBody { get; set; }

	// Constructor
	public CiFeedbackController()
	{
		// Set defaults
		this.isLocked = false;
		this.emailBody = '';
		
		// Get URL to return to after cancel
		this.retURL = Apexpages.currentPage().getParameters().get('retUrl');

		// Get passed id
		this.passedId = Apexpages.currentPage().getParameters().get('Id');
		if (String.isBlank(this.passedId))
		{
			this.isLocked = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No record was found! Please click Cancel to go back.'));
			return;
		}
		
        // Get the sObject type for the Id
        Schema.SObjectType token = this.passedId.getSObjectType();
        Schema.DescribeSObjectResult dr = token.getDescribe();
        this.objectType = dr.getName();
        
        // Construct a query dynamically to get the name
        String queryString = 'SELECT Id, Name FROM ' + this.objectType + ' WHERE Id=\'' + this.passedId + '\'';
        this.objectName = String.valueOf(Database.query(queryString)[0].get('Name'));
	}
	
	// Send email when Send is clicked
	public PageReference send()
	{
		// Validate input
    	if (String.isBlank(this.emailBody))
    	{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The comments field is empty! Please provide some feedback.'));
    		return null;
    	}
		
		// Build email
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

		// String to hold the To email addresses
		String[] toAddresses = new String[] {'customer.insight@bsigroup.com'}; 
		mail.setToAddresses(toAddresses);

		// Set to true if you want to BCC sender
		mail.setBccSender(false);

		// Optionally append the salesforce.com email signature to the email
		mail.setUseSignature(false);
		
		// Specify the subject line
		mail.setSubject('SFDC Caerus: Feedback for ' + this.objectType + ' ' + this.objectName + ' (' + this.passedId + ')');

		// Specify the contents
		mail.setPlainTextBody(this.emailBody);
		mail.setHtmlBody(this.emailBody);
     
     	// Send it
     	if (!Test.isRunningTest())
     	{
	     	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	    }

		// Display success message
		this.IsLocked = true;
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Thank you! Your feedback has been sent. Please click Cancel to continue.'));
		return null;
	}
	
	// Return to calling page when Cancel is clicked
	public PageReference cancel()
	{
		PageReference result = new PageReference(this.retURL);
		result.setRedirect(true);
		return result;
	}
}