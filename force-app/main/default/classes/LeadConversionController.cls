/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         08/12/2011
* Description:  Visualforce Controller used to convert a Lead and manage
*				all the related site. Owners are selected based on selected
*				criteria. 
*
* 	Changes:
* 	JKittridge Brightgen 	20-07-2017	Updated 'GetAccountOwner' and 'getOptyOwner' to represent new lead source values 
*	Ian Bowman Brightgen	29-08-2017  removed HQ site creation for PS implementation UAT #PS - 001
*
**/
public without sharing class LeadConversionController {
	
	public Lead			convLead		{get; set;}	
	public Account		selAccount		{get; set;}
	public Contact		selContact		{get; set;}
	public Opportunity	newOpty			{get; set;}
	public Territory__c territory;
	public List<Territory_Assignment__c> ranges;
	
	public Boolean		showContact		{get; set;}
	public Boolean		showAccount		{get; set;}
	
	public Boolean		dupeAccount		{get; set;}
	public Boolean		dupeContact		{get; set;}
	
	public String		linkAccId		{get; set;}
	public String		linkConId		{get; set;}
	
	public Boolean		showConvert		{get; set;}

	public boolean takeAccountOwnership {get; set;}

	SiteSetting__c setting = SiteSetting__c.getInstance();
	
	public boolean doNotCreateOpportunity {get; set;}
	private boolean initialising;
	
	// CONSTRUCTOR
	public LeadConversionController(ApexPages.Standardcontroller std) {
		// Initializing...
		initialising = true;
		convLead = [SELECT Name, FirstName, LastName, Company, Delivery__c, Territory__c, TotalEmployees__c,
						Street, City, Country, PostalCode, ConversionScore__c, ReadyforConversion__c, ReadyForConversionTraining__c,
						RegistrationPath__c, Standards__c, ProductArea__c, PortfolioInterestArea__c, Product_Area_Interests__c, 
						PreviousComments__c, PrevCustomer__c, Description, LeadSource, OwnerId, Product_Interests__c, Portfolio_Interests__c,
						Product_Stream__c, Product_SubStream__c, Existing_Customer_Account__c, RecordType.DeveloperName, Source_Sub_Category__c
					FROM Lead 
					WHERE Id = :std.getId()];
		// Conversion available?
		//showConvert = true;
		// Set showConvert depending on whether it is a Training lead or not
		if (convLead.RecordType.DeveloperName != 'Training_Leads')
		{
			showConvert = convLead.ReadyforConversion__c == 'Ready'? true : false;	
		}
		else
		{
			showConvert = convLead.ReadyforConversionTraining__c == 'Ready'? true : false;
		}
		// Query for Custom Assignment Rules (Header Teritory - Rows range of values)			
		if (convLead.Territory__c != null) {
			territory 	= [SELECT AssignedTo__c FROM Territory__c WHERE Id =:convLead.Territory__c];
			ranges 		= [SELECT MaxScore__c, MinScore__c, AssignedTo__c FROM Territory_Assignment__c 
						   WHERE Territory__c =:territory.Id
						   AND MaxScore__c >: convLead.TotalEmployees__c
						   AND MinScore__c <: convLead.TotalEmployees__c];
						   //AND MaxScore__c >: convLead.ConversionScore__c
						   //AND MinScore__c <: convLead.ConversionScore__c];
			//if (territory != null && territory.AssignedTo__c == null) {
			//	showConvert = false;
			//}			   
		} else if (convLead.Territory__c == null) {
			showConvert = false;
		}
		
		showAccount = false;
		showContact = false;
		dupeAccount = false;
		dupeContact = false;
		doNotCreateOpportunity = false;
		takeAccountOwnership = false;
		selAccount = new Account();
		selContact = new Contact();
		newOpty = new Opportunity();
		newOpty.Name = defaultOptyName(convLead.Company);
		newOpty.CloseDate = convLead.Delivery__c;
		newOpty.OwnerId = getOptyOwner(selAccount);
		
		// Check dupe - calling methods
		getAccounts();
		viewAccount();
		initialising = false;
	}	
	
	//DEFAUL OPTY NAME
	private String defaultOptyName(String company) {
		/*
			Set Default Oportunity Name
		*/
		String optyName = '';
		optyName = company;

		// Add Registration Path			
		if(!bg_StringUtils.IsBlank(convLead.RegistrationPath__c)) { 
			optyName += ' - ' + convLead.RegistrationPath__c;
		}

		// Add most specific information about main product
		string interest = '';
		if(!bg_StringUtils.IsBlank(convLead.Product_Area_Interests__c)) {
			interest = convLead.Product_Area_Interests__c;
		} else if(!bg_StringUtils.IsBlank(convLead.Portfolio_Interests__c)) {
			interest = convLead.Portfolio_Interests__c;		
		} else if(!bg_StringUtils.IsBlank(convLead.Product_SubStream__c)) {
			interest = convLead.Product_SubStream__c;
		} else if(!bg_StringUtils.IsBlank(convLead.Product_Stream__c)) {
			interest = convLead.Product_Stream__c;
		}		

		optyName = optyName + ' - ' + interest;
							
		return optyName;
	}
	
	// CONVERT LEAD
	public Pagereference convertLead() {
		Savepoint sp = Database.setSavepoint();
		// The trigger that create a new HQ Site must be deactivated on conversion
		Utility.lockcreateHQSite = true;
		Utility.isVisualforce	 = true;
		Utility.lockassignTerritory = true;
		// Update the lead to avoid time based workflow error
		convLead.ConvertMe__c = true;
		try {
			update convLead;
		} catch (DmlException e) {
            ApexPages.addMessages(e);
           	return null;
		}
		
		Pagereference pageA;
		Database.LeadConvert toConvert = new Database.LeadConvert();
        toConvert.setLeadId(convLead.Id);
		toConvert.setDoNotCreateOpportunity(doNotCreateOpportunity);
		
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true limit 1];
        toConvert.setConvertedStatus(convertStatus.MasterLabel);

        // Connect to existing record (Account - Contact)
        if(!bg_StringUtils.IsBlank(linkAccId)) { toConvert.setAccountId(linkAccId); }
        if(!bg_StringUtils.IsBlank(linkConId)) { toConvert.setContactId(linkConId); }    

        // Sites to be moved from Lead to selected Account
        List<Site__c> sites = [SELECT Id, Account__c, Type__c FROM Site__c WHERE Lead__c =:convLead.Id];
        
        Database.LeadConvertResult lcr = Database.convertLead(toConvert, false);
        if(lcr.isSuccess()) {
        	try {        		
        		Account convAcc = [SELECT Name, OwnerId, KeyAccount__c, Territory__c, ParentId, TCodeDescr__c,
        							BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode,
        							NumberOfEmployees
        							FROM Account WHERE Id =:lcr.getAccountId()];
	        	
	        	// Assign the correct owner for the Account - if is new
	        	if (bg_StringUtils.IsBlank(linkAccId)) {
	        		convAcc.OwnerId 			= getAccountOwner();
	        		convAcc.Territory__c 		= territory.Id;
	        		convAcc.NumberOfEmployees 	= Integer.valueOf(convLead.TotalEmployees__c);
	        		if (convLead.PrevCustomer__c == 'Yes') convAcc.Description = convLead.PreviousComments__c;
	        		update convAcc;
	        		
	        		// Assign new HQ Site if not available
		        	setting = SiteSetting__c.getInstance();
		        	/* IB removed for PS implementation UAT #PS - 001
		        	List<Site__c> hq = [SELECT Type__c FROM Site__c WHERE Lead__c =:convLead.Id AND Type__c =:setting.HQLabel__c];
		        	if (hq.isEmpty()) {
		        		Site__c hqs = Utility.setHQSite(convAcc);
		        		hqs.PrimaryContact__c = lcr.getContactId(); // Default Primary Contact on HQ Site
		        		sites.add(hqs);
		        	} 
		        	*/
	        	} else {
	        		if(takeAccountOwnership) {
	        			convAcc.OwnerId = getAccountOwner();
	        			update convAcc;
	        		}
	        	}

	        	// Assign the correct owner for the Contact
	        	Contact convCon 		= [SELECT OwnerId, Territory__c FROM Contact WHERE Id =:lcr.getContactId()];
	        	convCon.OwnerId 		= getAccountOwner();
	        	update convCon;
	        	
	        	if(!doNotCreateOpportunity) {
		        	// Assign the correct owner for the opportunity - always created
		        	Opportunity convOpty = [SELECT OwnerId, TCode__c, Territory__c, QualifiedBy__c FROM Opportunity WHERE Id =:lcr.getOpportunityId()];
		        	convOpty.Name 			= newOpty.Name;
		        	convOpty.OwnerId 		= getOptyOwner(convAcc);
		        	convOpty.Territory__c 	= territory.Id;
		        	convOpty.TCode__c 		= convAcc.TCodeDescr__c;
		        	convOpty.PrimaryContact__c = lcr.getContactId(); // Default Primary Contact on Opportunity
		        	convOpty.Description	= convLead.Description;
		        	if (convOpty.QualifiedBy__c == null) convOpty.QualifiedBy__c = UserInfo.getUserId(); // Track who has qualified the Lead
		        	// Mapping
					if(convLead.Delivery__c != null) { convOpty.CloseDate = convLead.Delivery__c; }
		        	update convOpty;
		        	
		        	// Manual Sharing Rule on Opportunity to allow the LQE to upload document or change some fields
		        	if (convOpty.OwnerId != convLead.OwnerId) {
			        	OpportunityShare oshare = new OpportunityShare();
			        	oshare.OpportunityId	= lcr.getOpportunityId();
			        	oshare.UserOrGroupId	= convLead.OwnerId;
			        	oshare.OpportunityAccessLevel = 'Edit';
			        	insert oshare;
		        	}
	        	}
	        	
	        	/*
	        	 Move all the sites to the converted Account
	        	 Andy Mahood: Any that fail (prob becuase of being dupe) will be deleted
	        	*/
	        	for (Site__c s : sites) {
	        		// Convert HQ Site to "Other" when merging with existing Account
	        		if (linkAccId != null && linkAccId != '' && s.Type__c == setting.HQLabel__c) s.Type__c = 'Other';
	        		s.Account__c = lcr.getAccountId();
	        	}
	        		        	
	        	Database.UpsertResult[] saveResults = database.upsert(sites, false); //allow some to fail if dupe
	        	system.debug('$$$ SAVE RESULTS: ' + saveResults);
	        	/*
	        	ANDREW MAHOOD 29/02/2012
	        	THIS WAS TO HANDLE MOVING SITES TO ACCOUNT WITH EXISTING SITES
	        	WE NEED TO THINK ABOUT IF WE WANT TO ALLOW DUPES HERE OR BLOCK
	        	EVEN BETTER WOULD BE TO IDENTIFY THE LEAD IS MATCHED TO AN
	        	ACCOUNT EARLIER AND DUPE BLOCK LEAD SITES AGAINST THE ACCOUNT SITES

	        	List<Site__c> sitesToDelete = new List<Site__c>();
	        	for (Database.SaveResult saveResult:saveResults) {//process resulrs
	        		if (!saveResult.isSuccess()) { //if failed add to list to delete
	        			sitesToDelete.add(new Site__c(Id=saveResult.getId()));
	        		}
	        	}
	        	system.debug('sitesToDelete...' + sitesToDelete);
	        	if (sitesToDelete!=null && !sitesToDelete.isEmpty()) {
	        		delete sitesToDelete;//remove any sites linked ot lead that couldnt be added to acc
	        	}
	        	*/
	        	
	        	Utility.lockcreateHQSite 	= false;
	        	Utility.lockassignTerritory = false;
	        	// Redirect to converted Account page        	
	        	pageA = new Pagereference('/' + lcr.getAccountId());
        	} catch (DMLException e) {
               Database.rollback(sp);
                ApexPages.addMessages(e);
                pageA = null;
            }
        } else {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, lcr.getErrors().get(0).getMessage()));
            pageA = null;
        }
        
        return pageA;
	}
	
	// QUERY FOR HOVER DETAIL - ACCOUNT
	public void viewAccount() {
		system.debug('linkAccId: [' + linkAccId + ']');
		if(!bg_StringUtils.IsBlank(linkAccId)) {
			selAccount = [SELECT Name, OwnerId, BillingStreet, BillingCity, BillingCountry, BillingPostalCode, 
							 TCodeDescr__c, Industry, KeyAccount__c, ParentId, Parent.Name 
						 FROM Account 
						 WHERE Id =:linkAccId];
			showAccount = true;
			//showMaster = false;
			//linkMasterId = '';
			linkConId = '';
			showContact = false;
			newOpty.Name = defaultOptyName(selAccount.Name);
			newOpty.OwnerId = getOptyOwner(selAccount);
			takeAccountOwnership = false;
		} else {
			showAccount = false;
			showContact = false;
			//showMaster = false;
			newOpty.Name = defaultOptyName(convLead.Company);
			newOpty.OwnerId = getOptyOwner(null);
			linkAccId = '';
			linkConId = '';
			takeAccountOwnership = true;
		}
		system.debug('showAccount: ' + showAccount);
	}
	
	// QUERY FOR HOVER DETAIL - CONTACT
	public void viewContact() {
		if(!bg_StringUtils.IsBlank(linkConId)) {
			selContact = [SELECT Name, Phone, Email, ConsultantType__c FROM Contact WHERE Id =:linkConId];
			showContact = true;
		} else {
			showContact = false;
		}
	}
	
	// BACK TO LEA DETAIL
	public Pagereference back() {
		Pagereference pageL = new Pagereference('/' + convLead.Id);
		return pageL;
	}
	
	// SEARCH FOR THE ACCOUNT OWNER
	private String getAccountOwner() {
		String ownerId = UserInfo.getUserId();
		// Skip lead scoring rule if the Lead is Self Generated
		if (convLead.LeadSource == 'Sales Channels' && (
			convLead.Source_Sub_Category__c == 'Field sales - Self-generated' || convLead.Source_Sub_Category__c == 'Telesales - Self-generated'))
		{
			ownerId = convLead.OwnerId;
		}	
		// check for assignment rules
		else if (ranges != null && !ranges.isEmpty()) {
			ownerId = ranges.get(0).AssignedTo__c;
		}
		// otherwise add the lead territory main Owner
		else if (territory != null && territory.AssignedTo__c != null) {
			ownerId = territory.AssignedTo__c;
		}
		return ownerId;
	}
	
	// SEARCH FOR THE OPPORTUNITY OWNER
	private String getOptyOwner(Account acc) {
		String ownerId = UserInfo.getUserId();
		// Skip lead scoring rule if the Lead is Self Generated
		if (convLead.LeadSource == 'Sales Channels' && (
			convLead.Source_Sub_Category__c == 'Field sales - Self-generated' || convLead.Source_Sub_Category__c == 'Telesales - Self-generated'))
		{
			ownerId = convLead.OwnerId;
		}		 
		// If is a Key Account the Owner must be the same regardless of the region
		else if (acc != null && acc.KeyAccount__c) ownerId = acc.OwnerId;
		// check for assignment rules
		else if (ranges != null && !ranges.isEmpty()) {
			ownerId = ranges.get(0).AssignedTo__c;
		}
		// otherwise add the lead territory main Owner
		else if (territory != null && territory.AssignedTo__c != null) {
			ownerId = territory.AssignedTo__c;
		}
		return ownerId;
	}
	
	// ACCOUNTS LIST
    public List<SelectOption> getAccounts() {
      	List<SelectOption> optionList = new List<SelectOption>();
      	
      	// Default option create a new Account - default changed on 25/09/2013 to show existing accounts if any first
      	
        /*  optionList.add(new SelectOption('', 'CREATE NEW ACCOUNT: ' + convLead.Company));  */
		List<Site__c> temp = [SELECT Account__r.Name, Account__c, Account__r.BillingPostalCode, Postcode__c FROM Site__c 
							  WHERE Account__c != null 
							  AND (Name like :'%'+convLead.Company+'%' 
							  OR Account__r.Name like :'%'+convLead.Company+'%' 						  
							  OR (Postcode__c = :convLead.PostalCode AND Postcode__c != null)
							  OR (Account__r.BillingPostalCode = :convLead.PostalCode AND Account__r.BillingPostalCode != null))];
		Map<Id,String> mapTemp = new Map<Id,String>(); 
		for (Site__c s : temp) {
			mapTemp.put(s.Account__c,s.Account__r.Name);
		}					  
	    //for (Account a : [SELECT Name FROM Account WHERE Name like :'%'+convLead.Company+'%' AND ParentId != null]) {
	    for (Id curr : mapTemp.keySet()) {
	    	optionList.add(new SelectOption(curr,'ADD TO EXISTING: ' + mapTemp.get(curr)));
	    	dupeAccount = true;
	    }
	    optionList.add(new SelectOption('', 'CREATE NEW ACCOUNT: ' + convLead.Company));
	    
		if(initialising) { 
			if(convLead.Existing_Customer_Account__c != null) {
				linkAccId = convLead.Existing_Customer_Account__c;
			} else {
				linkAccId = optionList[0].getValue();
			}
		}
	    			
      	return optionList;
    }
    
    /*// MASTER ACCOUNTS LIST
    public List<SelectOption> getMasterAccounts() {
      	List<SelectOption> optionList = new List<SelectOption>();
      	optionList.add(new SelectOption('', 'NEW MASTER ACCOUNT: ' + convLead.Company)); 
		
	    for (Account a : [SELECT Name FROM Account WHERE Name like :'%'+convLead.Company+'%' AND ParentId = null]) {
	    	optionList.add(new SelectOption(a.Id,'LINK TO MASTER ACCOUNT: ' + a.Name));
	    	dupeMaster = true;    	
	    }
      	return optionList;
    }*/
    
    // CONTACTS LIST
    public List<SelectOption> getContacts() {
      	List<SelectOption> optionList = new List<SelectOption>();
      	// Deafault option create a new Account
      	optionList.add(new SelectOption('', 'CREATE NEW CONTACT: ' + convLead.Name)); 
		
	    for (Contact c : [SELECT Name FROM Contact WHERE (FirstName like :'%'+convLead.FirstName+'%' OR LastName like :'%'+convLead.LastName+'%') AND AccountId =:linkAccId AND AccountId != null]) {
	    	optionList.add(new SelectOption(c.Id,'ADD TO EXISTING: ' + c.Name));
	    	dupeContact = true;
	    }
      	return optionList;
    }
    
}