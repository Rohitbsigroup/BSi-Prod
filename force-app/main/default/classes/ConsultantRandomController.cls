/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         03/01/2012
* Description:  This class select 3 random Consultants based on pre-selected 
*				filtering criteria. This is only a test, real feature TBD.
*       
**/
public with sharing class ConsultantRandomController {
	
	public Integer random1 			{get; set;}
	public Integer random2 			{get; set;}
	public Integer random3 			{get; set;}
	public Integer maxCount			{get; set;}
	
	//public String customerEmail		{get; set;}
	public String customerId		{get; set;}
	public String errorMessage		{get; set;}	
	
	public List<Contact> contacts 	{get; set;}
	
	public Contact con1 			{get; set;}
	public Contact con2 			{get; set;}
	public Contact con3 			{get; set;}
	
	public Opportunity opty;
	
	public Boolean noConsultant		{get; set;}
	public Boolean showError		{get; set;}
	public Boolean emailSent		{get; set;}
	public Boolean warning			{get; set;}			
	
	public List<SelectOption>	customer {get; set;}
	
	public ConversionScore__c setting;	
	
	public ConsultantRandomController(Apexpages.StandardController std) {
		// Initializing...
		con1 = new Contact(FirstName = 'No', LastName = 'Consultant');
		con2 = new Contact(FirstName = 'No', LastName = 'Consultant');
		con3 = new Contact(FirstName = 'No', LastName = 'Consultant');
		showError = false;
		emailSent = false;
		warning	  = false;
		
		// Query all consultants that match selected criteria (TBD)
		opty     = [SELECT AccountId, Account.Territory__c, Account.BillingCountry, Standards__c, Standards2__c, 
					Consultant1__c, Consultant2__c, Consultant3__c, OwnerId, PrimaryContact__c 
					FROM Opportunity WHERE Id =:std.getId()];
		setting = ConversionScore__c.getInstance(opty.Account.BillingCountry);			
		
		// Search the Teritory of the main HQ site for this quote
		String territoryID = null;
		List<OpportunitySite__c> site = [SELECT Site__r.Territory__r.Name,SiteZipPostalCode__c,SiteCountry__c FROM OpportunitySite__c WHERE Opportunity__c =: opty.Id AND HQ__c = true];
		if (!site.isEmpty()) {
			territoryID = site.get(0).Site__r.Territory__r.Name;
		}
		
		// Seach Consultants
		contacts = [SELECT Name, FirstName, LastName, Email, Phone, ConsultantType__c, MailingPostalCode FROM Contact 
					WHERE RecordType.DeveloperName =: Utility.RTNAME_CONSULTANT
					AND Territory__r.Name =: territoryID
					AND Territory__c != null
					AND ConsultantType__c = 'ACP' 
					AND ConsultantProducts__c includes (:opty.Standards__c,:opty.Standards2__c) 
					AND ConsultantProducts__c != null
					AND Active__c = true];		
		maxCount = contacts.size(); 
		
		if (contacts.isEmpty()) {
			noConsultant = true;
		} else {
			slotMachine();
			noConsultant = false;
		}
		
		if (site.isEmpty()) {
			warning = true;
			errorMessage = 'You need to define an HQ Site for this Opportunity before selecting a Consultant';
		} else if (territoryID == null) {
			warning = true;
			errorMessage = 'No Territory found for Postcode ' + site.get(0).SiteZipPostalCode__c + ' and Country ' + site.get(0).SiteCountry__c + ' on HQ Site';
		}
	}
	
	// SELECT 3 RANDOM CONSULTANTS
	public void slotMachine() {
		List<Contact> tempList = contacts.deepClone(true);
		if (maxCount < 3) {
			if (maxCount == 1) {
				con1 = tempList.get(0);
			} else {
				con1 = tempList.get(0);
				con2 = tempList.get(1);
			}
		} else if (maxCount > 3) {
			random1 = Integer.valueOf(Math.random()*maxCount);
			con1 = tempList.get(random1);
			tempList.remove(random1);
			random2 = Integer.valueOf(Math.random()*(maxCount-1));
			con2 = tempList.get(random2);
			tempList.remove(random2);
			random3 = Integer.valueOf(Math.random()*(maxCount-2));
			con3 = tempList.get(random3);
			tempList.remove(random3);
		} else {
			con1 = tempList.get(0);
			con2 = tempList.get(1);
			con3 = tempList.get(2);
		}
	}
	
	// RESET ERROR
	public void reset() {
		showError = false;
		errorMessage = '';
	}
	
	// GET CONTACTS FROM CONTACT ROLES
	// 1. Default to Primary Contact Role
	// 2. Only Contact with emails are displayed
    public List<SelectOption> getCustomers() {
      	List<SelectOption> optionList = new List<SelectOption>();
      	Set<Id> uniqueCons = new Set<Id>();  
	    /*for (Contact_Opportunity__c c : [SELECT Name, OppPrimary__c, Contact__c, Contact__r.Name, Contact__r.Email FROM Contact_Opportunity__c WHERE Opportunity__c = :opty.Id order by OppPrimary__c]){	    	
	    	if (!uniqueCons.contains(c.Contact__c) && c.Contact__r.Email != null) optionList.add(new SelectOption(c.Contact__c,c.Contact__r.Name + ' (' + c.Contact__r.Email + ')'));
	    	if (c.OppPrimary__c && customerId == null) customerId = c.Contact__c;
	    	uniqueCons.add(c.Contact__c);
	    }*/
	    for (Contact c : [SELECT Name, Email FROM Contact WHERE AccountId = :opty.AccountId order by Name]){	    	
	    	if (!uniqueCons.contains(c.Id) && c.Email != null) optionList.add(new SelectOption(c.Id,c.Name + ' (' + c.Email + ')'));
	    	if (opty.PrimaryContact__c == c.Id && customerId == null) customerId = c.Id;
	    	uniqueCons.add(c.Id);
	    }
		 
      	return optionList;
    }
	
	// SEND EMAIL TO CUSTOMER
	public void sendEmail() {
		// Store the recommended Consultant on the Opportunity
		opty.Consultant1__c = con1.Id;
		opty.Consultant2__c = con2.Id;
		opty.Consultant3__c = con3.Id;
		try {
			update opty;
		} catch (DmlException dml) {
			errorMessage = dml.getDmlMessage(0);
			showError = true;
		}
		
		// Send the email if there are no errors
		if (!showError) {
			// Get the Template
			List<EmailTemplate> template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Opportunity_SuggestedConsultants'];
			
			// Build the Email
			if (customerId != null && customerId != '') {
				List<String> ccs = new List<String>();
				if (setting != null) ccs.add(setting.ConsultantEmailCC__c);
				Messaging.SingleEmailmessage mail = new Messaging.SingleEmailMessage();
				mail.setTemplateId(template.get(0).Id);
				mail.setCcAddresses(ccs);
				mail.setTargetObjectId(customerId); // Must be the Customer Email address
				mail.setWhatId(opty.Id);
				mail.setSaveAsActivity(false);
				
				try {
					// Send the Email to the Customer
					List<Messaging.Sendemailresult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
					for (Messaging.Sendemailresult curr : results) {
						if (!curr.isSuccess()) {
							showError = true;
							errorMEssage = Utility.friendlyMessage(curr.getErrors().get(0).getMessage());
						} else {
							emailSent = true;
						}
					}
				} catch (Exception ex) {
					showError = true;
					errorMEssage = Utility.friendlyMessage(ex.getMessage());
				}
			}
		}
	}
	
	
}