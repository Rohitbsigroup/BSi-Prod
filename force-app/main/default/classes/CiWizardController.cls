public with sharing class CiWizardController
{
	// STEP 1 ===========================================================================================================================

	// Properties
	public CI_Account__c sourceAccount { get; set; }				// Source CI Account
	public List<SelectOption> existingAccounts { get; set; }		// List of accounts with source GoldenCompanyId
	public String targetType { get; set; }							// Selected target type (id, new or old)
	public Site__c tempSite { get; set; }							// Temporary site to provide Account lookup
	private Id targetAccountId { get; set; }						// Selected target id (null for new)

	// Forward method
	public CiWizardController(ApexPages.StandardController controller)
	{
		// Retrieve the source CI Account
		this.sourceAccount = [
			SELECT	sa.Id, sa.Name, sa.Account_Id__c, sa.Current_Holdings__c, sa.Key_Account__c 
			FROM	CI_Account__c sa 
			WHERE	sa.Id = :controller.getRecord().Id 
			LIMIT	1
			];
		
		// Create the drop-down list for existing Accounts
		this.targetType = 'new';
		this.tempSite = new Site__c();
		this.existingAccounts = new List<SelectOption>();
		for (Account ea : [
			SELECT	ea.Id, ea.Name, ea.BillingCity, ea.BillingState, ea.BillingCountry 
			FROM	Account ea 
			WHERE	ea.GoldenCompanyID__c = :Integer.valueOf(this.sourceAccount.Account_Id__c) 
			LIMIT	1000
			])
		{
			// Set the first option to be the default selection
			if (this.existingAccounts.size() == 0) this.targetType = ea.Id;
			String lbl = 'Use existing Account: ' + ea.Name;
			if (ea.BillingCity != null && ea.BillingCity != '') lbl += ', ' + ea.BillingCity;
			if (ea.BillingState != null && ea.BillingState != '') lbl += ', ' + ea.BillingState;
			if (ea.BillingCountry != null && ea.BillingCountry != '') lbl += ', ' + ea.BillingCountry;
			this.existingAccounts.add(new SelectOption(ea.Id, lbl));
		}
	}

	// Back method
	public PageReference backToStep1()
	{
		return Page.CiWizard1;
	}
	
	// Refresh the page after updates
	public PageReference ok()
	{		
		return null;
	}


	// STEP 2 ===========================================================================================================================

	// Wrapper classes
	public class SiteWrapper
	{
		public CI_Site__c ciSite { get; set; }						// Source CI Site
		public Site__c matchingSite { get; set; }					// A matching existing site (if found)
		public Boolean isPicked { get; set; }						// Selected for copy
		private Id newId { get; set; }								// Newly created Id
	}

	// Properties
	public List<SiteWrapper> sourceSites { get; set; }				// Source CI Sites
	public List<SelectOption> unlinkedSites { get; set; }			// Target Account Sites with no GoldenSiteId

	// Forward method
	public PageReference forwardToStep2()
	{
		// Validate account selection
		if (this.targetType == 'old' && this.tempSite.Account__c == null)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select an Account!'));
			return null;
		}

		// Initialize Step 2 collections
		Map<String, Site__c> linkedSites = new Map<String, Site__c>();
		this.unlinkedSites = new List<SelectOption>();
		
		// Deal with selection	
		if (this.targetType == 'new')
		{
			// There is no existing account
			this.targetAccountId = null;
		}
		else
		{
			// There is an existing account
			this.targetAccountId = this.targetType == 'old' ? this.tempSite.Account__c : this.targetType;

			// Map linked sites & build list of unlinked sites
			for (Site__c es : [
				SELECT	es.Id, es.Name, es.City__c, es.State__c, es.Postcode__c, es.Country__c, es.Account__c, es.GoldenSiteID__c
				FROM	Site__c es
				WHERE	es.Account__c = :this.targetAccountId
				LIMIT	1000
				])
			{
				if (es.GoldenSiteID__c != null)
				{
					linkedSites.put(String.valueOf(es.GoldenSiteID__c), es);
				}
				else
				{
					this.unlinkedSites.add(new SelectOption(es.Id, es.Name));
				}
			}
		}

		// Retrieve the source CI Sites & populate site list
		this.sourceSites = new List<SiteWrapper>();
		for (CI_Site__c ss : [
			SELECT	ss.Id, ss.Name, ss.Phone__c, ss.Fax__c, ss.CI_Site_Type__c, ss.Street__c, ss.City__c, ss.Region__c, ss.Postcode__c, ss.Country__c, ss.Country_Code__c, ss.Site_Id__c 
			FROM	CI_Site__c ss 
			WHERE	ss.CI_Account__c = :this.sourceAccount.Id 
			LIMIT	1000 
			])
		{
			SiteWrapper wrap = new SiteWrapper();
			wrap.isPicked = false;
			wrap.ciSite = ss;
			if (linkedSites.containsKey(ss.Site_Id__c))	wrap.matchingSite = linkedSites.get(ss.Site_Id__c);
			this.SourceSites.add(wrap);
		}

		// Move the wizard to Step 2
		return Page.CiWizard2;
	}

	// Back method
	public PageReference backToStep2()
	{
		// Welcome back to Step 2
		return Page.CiWizard2;
	}


	// STEP 3 ===========================================================================================================================

	// Wrapper classes
	public class ContactWrapper
	{
		public CI_Contact__c ciContact { get; set; }				// Source CI Contact
		public Contact matchingContact { get; set; }				// A matching existing contact (if found)
		public Boolean isPicked { get; set; }						// Selected for copy
		private Id newId { get; set; }								// Newly created Id
	}
	
	// Properties
	public Boolean hasWarnings { get; set; }						// Save has fully/partially failed
	public List<ContactWrapper> sourceContacts { get; set; }		// Source CI Contacts
	public List<SelectOption> unlinkedContacts { get; set; }		// Target Account Contacts with no GoldenContactId	

	// Forward method
	public PageReference forwardToStep3()
	{
		// Initialize Step 3 flags and collections
		this.hasWarnings = false;
		Map<String, Contact> linkedContacts = new Map<String, Contact>();
		this.unlinkedContacts = new List<SelectOption>();
		
		// If existing account was selected in Step 1	
		if (this.targetAccountId != null)
		{
			// Map linked contacts & build list of unlinked contacts
			for (Contact ec : [
				SELECT	ec.Id, ec.Name, ec.AccountId, ec.GoldenContactID__c
				FROM	Contact ec
				WHERE	ec.AccountId = :this.targetAccountId
				LIMIT	1000
				])
			{
				if (ec.GoldenContactID__c != null)
				{
					linkedContacts.put(String.valueOf(ec.GoldenContactID__c), ec);
				}
				else
				{
					this.unlinkedContacts.add(new SelectOption(ec.Id, ec.Name));
				}
			}
		}

		// Retrieve the source CI Contacts & populate contact list
		this.sourceContacts = new List<ContactWrapper>();
		for (CI_Contact__c sc : [
			SELECT	sc.Id, sc.Name, sc.Title__c, sc.First_Name__c, sc.Last_Name__c, sc.Job_Title__c, sc.Phone__c, sc.Fax__c, sc.Email__c, sc.Do_Not_Email__c, sc.Street__c, sc.City__c, sc.Region__c, sc.Postcode__c, sc.Country__c, sc.Country_Code__c, sc.Contact_Id__c 
			FROM	CI_Contact__c sc 
			WHERE	sc.CI_Account__c = :this.sourceAccount.Id 
			LIMIT	1000 
			])
		{
			ContactWrapper wrap = new ContactWrapper();
			wrap.isPicked = false;
			wrap.ciContact = sc;
			if (linkedContacts.containsKey(sc.Contact_Id__c)) wrap.matchingContact = linkedContacts.get(sc.Contact_Id__c);
			this.SourceContacts.add(wrap);
		}

		// Move the wizard to Step 3
		return Page.CiWizard3;
	}

	// Carry out updates
	public PageReference doIt2()
	{
		// Retrieve the record type Ids
		Id customerAccount;
		for (RecordType r : [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Customer' AND IsActive = true LIMIT 1]) customerAccount = r.Id;
		Id namedSite;
		for (RecordType r : [SELECT Id FROM RecordType WHERE SObjectType = 'Site__c' AND DeveloperName = 'Named' AND IsActive = true LIMIT 1]) namedSite = r.Id;
		Id accountContacts;
		for (RecordType r : [SELECT Id FROM RecordType WHERE SObjectType = 'Contact' AND DeveloperName = 'Clients' AND IsActive = true LIMIT 1]) accountContacts = r.Id;
		if (customerAccount == null || namedSite == null || accountContacts == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Required record types are missing'));
			this.hasWarnings = true;
			return null;
		}
		
		// Deal with the Account
		if (this.targetAccountId == null)
		{
			// Create a new Account without address so that trigger doesn't create HQ site
			Account newAccount = new Account();
			newAccount.RecordTypeId = customerAccount;
			newAccount.Name = this.sourceAccount.Name;
			//newAccount.ParentId;
			newAccount.Type = String.IsNotBlank(this.sourceAccount.Current_Holdings__c) ? 'Customer' : 'Ex-Customer';
			//newAccount.CoRegNo__c;
			//newAccount.CharityRegNo__c;
			//newAccount.Reference_Number__c;
			//newAccount.NumberOfEmployees;
			newAccount.GoldenCompanyID__c = Decimal.valueOf(this.sourceAccount.Account_Id__c);
			//newAccount.VAT_Number__c;
			//newAccount.CompanyLogo__c;
			//newAccount.Trading_name__c;
			//newAccount.CurrencyIsoCode;
			//newAccount.Phone;
			//newAccount.Fax;
			//newAccount.Website;
			//newAccount.Territory__c;
			newAccount.KeyAccount__c = this.sourceAccount.Key_Account__c;
			//newAccount.ContactLevel__c;
			//newAccount.CI_Account__c = this.sourceAccount.Id;
			//newAccount.OrgType1__c;
			//newAccount.OrgType2__c;
			//newAccount.OrgType3__c;
			//newAccount.Whattypeofsite__c;
			//newAccount.Howmanysitesaretherealtogether__c;
			//newAccount.ExistingRegistrations__c;
			//newAccount.DetailsExistingReg__c;
			//newAccount.CertifyingOrganisations__c;
			//newAccount.OtherCertifyingOrganisations__c;
			//newAccount.Industry;
			//newAccount.TCodeDescr__c;
			newAccount.BillingStreet = '389 Chiswick high Rd';
			newAccount.BillingCity = 'London';
			newAccount.BillingState = '';
			newAccount.BillingPostalCode = 'W4 4AL';
			newAccount.BillingCountry = 'GB';
			//newAccount.ShippingStreet;
			//newAccount.ShippingCity;
			//newAccount.ShippingState;
			//newAccount.ShippingPostalCode;
			//newAccount.ShippingCountry;
			//newAccount.Description;

			// Get best-fit head office to add the address
			List<CI_Site__c> bestFitHqs  = [
				SELECT	ss.Id, ss.Name, ss.Street__c, ss.City__c, ss.Region__c, ss.Postcode__c, ss.Country__c, ss.Country_Code__c, ss.Site_Id__c, ss.Phone__c, ss.Fax__c, ss.Web_Address__c 
				FROM	CI_Site__c ss 
				WHERE	ss.CI_Account__c = :this.sourceAccount.Id
				ORDER	BY ss.CI_Site_Type__c, ss.Site_ID__c 
				LIMIT	1 
				];
			if (!bestFitHqs.isEmpty())
			{
				CI_Site__c bestFitHq = bestFitHqs[0];
				newAccount.Phone = bestFitHq.Phone__c;
				newAccount.Fax = bestFitHq.Fax__c;
				newAccount.Website = bestFitHq.Web_Address__c;
				newAccount.BillingStreet = bestFitHq.Street__c;
				newAccount.BillingCity = bestFitHq.City__c;
				newAccount.BillingState = bestFitHq.Region__c;
				newAccount.BillingPostalCode = bestFitHq.Postcode__c;
				newAccount.BillingCountry = bestFitHq.Country_Code__c;
			}
			// Try to insert new account
			Database.Saveresult accountResult = Database.insert(newAccount, false);
			if (!accountResult.isSuccess()) {
				
				// Report the problem and quit back
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to create Account'));
				for (Database.Error error : accountResult.getErrors()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error.getMessage()));
				this.hasWarnings = true;
				return null;
			}			
			
			// Remember new Account Id
			this.targetAccountId = newAccount.Id;
			
			// Delete any automatically created site
			List<Site__c> createdHqs  = [
				SELECT	st.Id 
				FROM	Site__c st 
				WHERE	st.Account__c = :newAccount.Id
				LIMIT	1 
				];
			if (!createdHqs.isEmpty()) delete createdHqs;
		}

		// Deal with the Sites
		List <Site__c> newSites = new List<Site__c>();
		for (SiteWrapper site : this.sourceSites)
		{
			if (site.isPicked && site.matchingSite == null)
			{
				CI_Site__c sourceSite = site.ciSite;
				Site__c newSite = new Site__c();
				newSite.RecordTypeId = namedSite;
				newSite.Name = sourceSite.Name;
				//newSite.DupeCheckID__c;
				//newSite.Risk_Level__c;
				//newSite.S_Code__c;
				//newSite.PrimaryContact__c;
				newSite.Account__c = this.targetAccountId;
				//newSite.Lead__c;
				newSite.SitePhone__c = sourceSite.Phone__c;
				newSite.SiteFax__c = sourceSite.Fax__c;
				//newSite.Territory__c;
				newSite.Type__c = (this.targetType == 'new' && sourceSite.CI_Site_Type__c == 'Head Office') ? 'HQ' : 'Ship To Address';
				//newSite.OrgType1__c;
				//newSite.OrgType2__c;
				//newSite.OrgType3__c;
				//newSite.NumberEmployees__c;
				newSite.Industry__c = '';
				//newSite.TCodeDescr__c;
				//newSite.Description__c;
				//newSite.CI_Site__c = sourceSite.Id;
				newSite.Street__c = sourceSite.Street__c;
				newSite.City__c = sourceSite.City__c;
				newSite.State__c = sourceSite.Region__c;
				newSite.Postcode__c = sourceSite.Postcode__c;
				newSite.Country__c = sourceSite.Country__c;
				newSite.Country_Code__c = sourceSite.Country_Code__c;				
				newSite.GoldenSiteID__c = Decimal.valueOf(sourceSite.Site_Id__c);
				newSite.SkipDupeChecker__c = true;
				newSites.add(newSite);
			}
		}

		// Insert sites
		if (!newSites.isEmpty()) {
		
			// Try to insert the new sites	
			Database.Saveresult[] siteResults = Database.insert(newSites, false);
			
			// Report back any errors
			for (Integer i = 0; i < siteResults.size(); i++) {
				if (!siteResults[i].isSuccess()) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to create site ' + newSites[i].Name));
					for (Database.Error error : siteResults[i].getErrors()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error.getMessage()));
					this.hasWarnings = true;
				}
			}
		}
		
		// Deal with the Contacts
		List <Contact> newContacts = new List<Contact>();
		for (ContactWrapper contact : this.sourceContacts)
		{
			if (contact.isPicked && contact.matchingContact == null)
			{
				CI_Contact__c sourceContact = contact.ciContact;
				Contact newContact = new Contact();
				newContact.RecordTypeId = accountContacts;
				newContact.Salutation = sourceContact.Title__c;
				newContact.FirstName = sourceContact.First_Name__c;
				newContact.LastName = sourceContact.Last_Name__c;
				newContact.AccountId = this.targetAccountId;
				newContact.Title = sourceContact.Job_Title__c;
				//newContact.ReportsTo;
				//newContact.Department;
				newContact.Position__c = sourceContact.Job_Title__c;
				//newContact.LeadSource;			
				//newContact.Source_Sub_Category__c;
				newContact.Phone = sourceContact.Phone__c;
				//newContact.HomePhone;
				//newContact.MobilePhone;
				//newContact.OtherPhone;
				newContact.Fax = sourceContact.Fax__c;
				newContact.Email = sourceContact.Email__c;
				newContact.HasOptedOutOfEmail = sourceContact.Do_Not_Email__c;
				//newContact.AlternativeEmailAddress__c;
				//newContact.AlternativePhoneNo__c;
				//newContact.AssistantName;
				//newContact.AssistantPhone;
				newContact.MailingStreet = sourceContact.Street__c;
				newContact.MailingCity = sourceContact.City__c;
				newContact.MailingState = sourceContact.Region__c;
				newContact.MailingPostalCode = sourceContact.Postcode__c;
				newContact.MailingCountry = sourceContact.Country_Code__c;
				newContact.GoldenContactID__c = Decimal.valueOf(sourceContact.Contact_Id__c);
				//newContact.Description;
				newContacts.add(newContact);
			}
		}

		// Insert contacts
		if (!newContacts.isEmpty()) {
		
			// Try to insert the new sites	
			Database.Saveresult[] contactResults = Database.insert(newContacts, false);
			
			// Report back any errors
			for (Integer i = 0; i < contactResults.size(); i++) {
				if (!contactResults[i].isSuccess()) {
					this.hasWarnings = true;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to create contact ' + newContacts[i].Name));
					for (Database.Error error : contactResults[i].getErrors()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error.getMessage()));
				}
			}
		}
		
		if (this.hasWarnings) {
			return null;
		}

		// Redirect to the target Account
		PageReference acctPage = new ApexPages.StandardController(new Account(id = this.targetAccountId)).view();
        acctPage.setRedirect(true);
        return acctPage;
	}
}