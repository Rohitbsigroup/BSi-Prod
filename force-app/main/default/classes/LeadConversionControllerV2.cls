/********************************************************************
 * LeadConversionControllerV2
 *
 * Controller extension for Lead Conversion
 * 
 * Orignial version written by Tquilla
 * 
 * Author: Alexis Lignereux
 * Created: 16-09-2014
 * Changes: 
 *          RJ - 12-12-2014 - Added conversion of existing certs onto Account
 *          RJ - 25-08-2015 - Only use stream on default opportunity name
 *          RJ - 02-10-2015 - Limited Account & Contact returned to 1000 records
 *          JK - 02-07-2017 - Updated getAccountOwner and getOpptyOwner to match new picklist values 
 *	        IB - 29-08-2017 - removed HQ site creation for PS implementation UAT #PS - 001
 *			JNP - 25-05-2018 - Added currency select list as external leads were created with GBP as currency and caused issues in opp line items
 ********************************************************************/
public with sharing class LeadConversionControllerV2 {

    public Lead convLead {get; set;} 
    public Account selAccount {get; set;}
    public Contact selContact {get; set;}
    public Opportunity newOpty {get; set;}
    public Territory__c territory;
    public List<Territory_Assignment__c> ranges;

    public Boolean showContact {get; set;}
    public Boolean showAccount {get; set;}
    public Boolean createNewAccount {get; set;}

    public Boolean dupeAccount {get; set;}
    public Boolean dupeContact {get; set;}
    public Boolean dupeSite {get; set;}
    public Boolean updateDone {get; set;}

    public String  linkAccId {get; set;}
    public String  linkConId {get; set;}

    public Boolean showConvert {get; set;}

    public boolean takeAccountOwnership {get; set;}

    SiteSetting__c setting = SiteSetting__c.getInstance();

    public boolean doNotCreateOpportunity {get; set;}
    private boolean initialising;

    public Map<Site__c,Site__c> siteErrors {get; set;}

	public String  selectedCurrency {get; set;}
	
    public LeadConversionControllerV2(ApexPages.Standardcontroller std) {
        convLead = [SELECT Name, FirstName, LastName, Company, Delivery__c, Territory__c, TotalEmployees__c,
                        Street, City, Country, PostalCode, ConversionScore__c, ReadyforConversion__c, ReadyForConversionTraining__c,
                        RegistrationPath__c, Standards__c, ProductArea__c, PortfolioInterestArea__c, Product_Area_Interests__c, 
                        PreviousComments__c, PrevCustomer__c, Description, LeadSource, OwnerId, Product_Interests__c, Portfolio_Interests__c,
                        Product_Stream__c, Product_SubStream__c, Existing_Customer_Account__c, RecordType.DeveloperName, Contact__c, Owner_Role_Team__c, Source_Sub_Category__c,CurrencyIsoCode,
                    	DNBoptimizer__DNB_D_U_N_S_Number__c 
                    FROM Lead 
                    WHERE Id = :std.getId()];

        //System.debug(LoggingLevel.ERROR,'***SM*** OwnerId = ' +convLead.OwnerId);
        //System.debug(LoggingLevel.ERROR,'***SM*** The User Role for the Owner = ' + convLead.Owner_Role_Team__c);


        // Conversion available?
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
            territory = [SELECT AssignedTo__c FROM Territory__c WHERE Id =:convLead.Territory__c];

            ranges = [SELECT MaxScore__c, 
                        MinScore__c,
                        AssignedTo__c
                    FROM Territory_Assignment__c 
                    WHERE Territory__c =:territory.Id
                    AND MaxScore__c >: convLead.TotalEmployees__c
                    AND MinScore__c <: convLead.TotalEmployees__c
            ];

        // why is this required as territory cannot be null for conversion
        // this case should never happen???
        } else if (convLead.Territory__c == null) {
            showConvert = false;
        }
        
        createNewAccount = false;
        showAccount = false;
        showContact = false;
        dupeAccount = false;
        dupeContact = false;
        dupeSite = false;
        updateDone = false;
        doNotCreateOpportunity = false;
        takeAccountOwnership = false;
        selAccount = new Account();
        selContact = new Contact();
        newOpty = new Opportunity();
        newOpty.Name = defaultOptyName(convLead.Company);
        newOpty.CloseDate = convLead.Delivery__c;
        newOpty.OwnerId = getOptyOwner(selAccount);
        initialising = true;
        siteErrors = new Map<Site__c,Site__c>();
        
        selectedCurrency = userinfo.getDefaultCurrency();
    }

    // ACCOUNTS LIST
    public List<bg_LeadUtils.RecordWrapper> getAccounts() {

        List<bg_LeadUtils.RecordWrapper> accountWrappers = new List<bg_LeadUtils.RecordWrapper>();

		List<Site__c> sites = null;
		
		if(convLead.DNBoptimizer__DNB_D_U_N_S_Number__c == null) {
			sites = [SELECT id, name, Account__r.Name, Account__c, Account__r.BillingPostalCode, Account__r.BillingStreet, Account__r.BillingCity,
	            Postcode__c, Account__r.Phone, Account__r.BillingState, Account__r.BillingCountry, Account__r.Type
	                            FROM Site__c
	                            WHERE Account__c != null 
	                            AND ( Name like :'%'+convLead.Company+'%' 
	                                  OR Account__r.Name like :'%'+convLead.Company+'%'
	                                    OR ( Postcode__c = :convLead.PostalCode 
	                                         AND Postcode__c != null
	                                    )
	                                    OR ( Account__r.BillingPostalCode = :convLead.PostalCode 
	                                         AND Account__r.BillingPostalCode != null
	                                    )
	                            )
								LIMIT 1000
	        ];
		} else {
			sites = [SELECT id, name, Account__r.Name, Account__c, Account__r.BillingPostalCode, Account__r.BillingStreet, Account__r.BillingCity,
	            Postcode__c, Account__r.Phone, Account__r.BillingState, Account__r.BillingCountry, Account__r.Type
	                            FROM Site__c
	                            WHERE Account__c != null AND Account__r.DNBoptimizer__DNB_D_U_N_S_Number__c = :convLead.DNBoptimizer__DNB_D_U_N_S_Number__c
								LIMIT 1000
	        ];
		}
		
        // use map to use contains methods instead of using for-loop
        Map<Id,bg_LeadUtils.RecordWrapper> mapTemp = new Map<Id,bg_LeadUtils.RecordWrapper>(); 
        for (Site__c s : sites) {

            bg_LeadUtils.RecordWrapper aw = new bg_LeadUtils.RecordWrapper();

            if (mapTemp.containsKey(s.Account__c)) {
                aw = mapTemp.get(s.Account__c);
            } else {
                Boolean checked = false;
                if (!bg_StringUtils.IsBlank(linkAccId) ) {
                    if (linkAccId == s.Account__c) {
                        checked = true;
                        linkAccId = s.Account__c;
                    }
                }
                aw = bg_LeadUtils.createRecord(s.Account__c, s.Account__r.Name, checked);
            }

            // add phone
            aw.phone = s.Account__r.Phone;
            aw.address = bg_LeadUtils.buildAddress(s.Account__r.BillingStreet, s.Account__r.BillingCity, s.Account__r.BillingState, s.Account__r.BillingPostalCode, s.Account__r.BillingCountry);
            aw.type = s.Account__r.Type;
            aw.reasons.add(bg_LeadUtils.getReason(s.Name, s.Postcode__c, s.Account__r.Name, s.Account__r.BillingPostalCode, convLead));
            mapTemp.put(aw.id,aw);
        }

        if(convLead.Existing_Customer_Account__c != null) {
            bg_LeadUtils.RecordWrapper aw = new bg_LeadUtils.RecordWrapper();
            if (mapTemp.containsKey(convLead.Existing_Customer_Account__c)) {
                aw = mapTemp.get(convLead.Existing_Customer_Account__c);
                aw.checked = true;
            } else {
                // get checked account and add to list
                Account checkedAccount = [Select Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Phone, Type
                    from Account where id = :convLead.Existing_Customer_Account__c];
                aw = bg_LeadUtils.createRecord(checkedAccount.id, checkedAccount.Name, true);

                // add phone
                aw.phone = checkedAccount.Phone;
                aw.address = bg_LeadUtils.buildAddress(checkedAccount.BillingStreet, checkedAccount.BillingCity, checkedAccount.BillingState, checkedAccount.BillingPostalCode, checkedAccount.BillingCountry);
                aw.type = checkedAccount.type;

            }
            aw.order = 0;
            aw.linked = true;

            if (initialising) {
                linkAccId = aw.id;
            } else {
                if (linkAccId != aw.id) {
                    aw.checked = false;
                }
            }
            mapTemp.put(aw.id,aw);
            showAccount = true;
        }

        // create list from map
        for (Id curr : mapTemp.keySet()) {
            accountWrappers.add(mapTemp.get(curr));
        }

        // if lead does not have any link account then assign first one
        if (initialising) {
            if (accountWrappers.size() > 0) {
                if (bg_StringUtils.IsBlank(linkAccId)) {
                    linkAccId = accountWrappers[0].id;
                    accountWrappers[0].checked = true;
                }
            }
        }

        // need to allow user to create new account
        bg_LeadUtils.RecordWrapper aw = bg_LeadUtils.createRecord(null, convLead.Company, false);
        aw.createNew = true;
        aw.order = 2;
        if (bg_StringUtils.IsBlank(linkAccId)) {
            aw.checked = true;
        }
        accountWrappers.add(aw);

        // set dupeAccount to true as 'Create New' record will always be in
        // the list
        if (accountWrappers.size() > 1) {
            dupeAccount = true;
        }

        accountWrappers.sort();
        return accountWrappers;
    }
    
    // CONTACTS LIST
    public List<bg_LeadUtils.RecordWrapper> getContacts() {
        List<bg_LeadUtils.RecordWrapper> contactWrappers = new List<bg_LeadUtils.RecordWrapper>();

        for (Contact c : [SELECT Id, Name, Email, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, AccountId, Contact.Account.Name
                FROM Contact WHERE (FirstName like :'%'+convLead.FirstName+'%' OR LastName like :'%'+convLead.LastName+'%') 
                AND AccountId = :linkAccId AND AccountId != null AND Id != :convLead.Contact__c
                LIMIT 1000]) {

            Boolean checked = false;
            if (!bg_StringUtils.IsBlank(linkConId)) {
                if (linkConId == c.id) {
                    checked = true;
                    linkConId = c.id;
                }
            }
            bg_LeadUtils.RecordWrapper cw = bg_LeadUtils.createRecord(c.id, c.name, checked);
            cw.order = 1;
            cw.contact = c;
            cw.phone = c.Phone;
            cw.email = c.Email;
            cw.address = bg_LeadUtils.buildAddress(c.MailingStreet, c.MailingCity, c.MailingState, c.MailingPostalCode, c.MailingCountry);
            cw.linked = true;
            contactWrappers.add(cw);
            dupeContact = true;
        }

        if (convLead.Contact__c != null) {
            Contact c;
            try {
                c = [SELECT Id, Name, Email, Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, AccountId, Contact.Account.Name
                from Contact WHERE id = :convLead.Contact__c];
            } catch(System.QueryException e) {
                c = null;
            }

            if (c != null) {
                bg_LeadUtils.RecordWrapper cw = bg_LeadUtils.createRecord(c.Id, c.Name, true);
                cw.order = 0;
                cw.contact = c;
                cw.linked = true;
                cw.phone = c.Phone;
                cw.email = c.Email;
                cw.address = bg_LeadUtils.buildAddress(c.MailingStreet, c.MailingCity, c.MailingState, c.MailingPostalCode, c.MailingCountry);
                contactWrappers.add(cw);

                if (initialising) {
                    linkConId = cw.id;
                } else {
                    if (linkConId != cw.id) {
                        cw.checked = false;
                    }
                }
                showContact = true;
            }
        }

        if (contactWrappers.size() > 0) {
            if (initialising) {
                if (bg_StringUtils.IsBlank(linkConId)) {
                    contactWrappers[0].checked = true;
                    linkConId = contactWrappers[0].id;
                }
            } else {
                if (bg_StringUtils.IsBlank(linkConId) && !createNewAccount) {
                    contactWrappers[0].checked = true;
                    linkConId = contactWrappers[0].id;
                }
            }
        }

        // need to allow user to create new content
        bg_LeadUtils.RecordWrapper cw = bg_LeadUtils.createRecord(null, convLead.Name, false);
        cw.createNew = true;
        cw.order = 2;

        if (bg_StringUtils.IsBlank(linkConId) || contactWrappers.size() == 0) {
            cw.checked = true;
            linkConId = '';
        }
        contactWrappers.add(cw);

        contactWrappers.sort();
        return contactWrappers;
    }

    public Map<Site__c,Site__c> getSites() {
        return siteErrors;
    }

    // QUERY FOR HOVER DETAIL - ACCOUNT
    public void viewAccount() {
        initialising = false;
        system.debug('linkAccId: [' + linkAccId + ']');
        if(!bg_StringUtils.IsBlank(linkAccId) && linkAccId != 'null') {
            selAccount = [SELECT Name, OwnerId, BillingStreet, BillingCity, BillingCountry, BillingPostalCode, 
                             TCodeDescr__c, Industry, KeyAccount__c, ParentId, Parent.Name, (SELECT id FROM Contacts)
                         FROM Account 
                         WHERE Id =:linkAccId];
            newOpty.Name = defaultOptyName(selAccount.Name);
            newOpty.OwnerId = getOptyOwner(selAccount);
            if (selAccount.Contacts.size() > 0) {
                linkConId = selAccount.Contacts[0].id;
            } else {
                linkConId = '';
            }
            initialising = true;
            takeAccountOwnership = false;
        } else {
            newOpty.Name = defaultOptyName(convLead.Company);
            newOpty.OwnerId = getOptyOwner(null);
            takeAccountOwnership = true;
            linkAccId = '';
            linkConId = '';
        }
        createNewAccount = false;
        system.debug('showAccount: ' + showAccount);
    }
    
    // QUERY FOR HOVER DETAIL - CONTACT
    public void viewContact() {
        initialising = false;
        if(!bg_StringUtils.IsBlank(linkConId) && linkConId != 'null') {
            selContact = [SELECT Name, Phone, Email, ConsultantType__c FROM Contact WHERE Id =:linkConId];
            showContact = true;
        } else {
            createNewAccount = true;
            showContact = false;
            linkConId = '';
        }
    }

    public Pagereference updateSite() {
    	if(String.isBlank(selectedCurrency) || selectedCurrency == 'None'){
    		ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please choose the Currency');
    		ApexPages.addMessage(msg);
    		return null;
    	}
    	
        // go through list and update sites

        for (Site__c newSite : siteErrors.keySet()) {
            if (newSite.SkipDupeChecker__c) {
                update newSite;
            }
        }

        siteErrors = new Map<Site__c,Site__c>();
        dupeSite = false;
        updateDone = true;
        return convertLead();
    }
    
    // CONVERT LEAD
    public Pagereference convertLead() {
    	if(String.isBlank(selectedCurrency) || selectedCurrency == 'None'){
    		ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please choose the Currency');
    		ApexPages.addMessage(msg);
    		return null;
    	}
    	
        Savepoint sp = Database.setSavepoint();

        // The trigger that create a new HQ Site must be deactivated on conversion
        Utility.lockcreateHQSite = true;
        Utility.isVisualforce    = true;
        Utility.lockassignTerritory = true;

        // Update the lead to avoid time based workflow error
        convLead.ConvertMe__c = true;
    	convLead.CurrencyIsoCode = selectedCurrency;
        system.debug('###BG - Try Lead Convert');
        try {
            update convLead;
        } catch (DmlException e) {
            system.debug('###BG - Try Lead Convert - CAUGHT EXCEPTION');
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
        List<Site__c> sites = [SELECT Id, Account__c, Type__c, Name, DupeCheckID__c, SkipDupeChecker__c,
            PostCode__c, Street__c, Lead__c
            FROM Site__c WHERE Lead__c =:convLead.Id];

        // 01/08/15 RJ: Removed GetExistingCustomerServices requested by BSI
        // Sales Consultants to move from Lead to Opps
//        List<Sales_Consultant__c> salesConsultantList = [SELECT Id FROM Sales_Consultant__c WHERE Lead__c = :convLead.Id];

        // 01/08/15 RJ: Removed GetExistingCustomerServices requested by BSI
        // Existing certifications to be moved from Account
//        list<ExistingCustomerServices__c> ecsList = bg_LeadUtils.GetExistingCustomerServices(convLead.Id); 

        Database.LeadConvertResult lcr = Database.convertLead(toConvert, false);
		system.debug('###BG - Finish Lead Convert');
        Integer failedUpsertSites = 0;

        if(lcr.isSuccess()) {
            try {
                Account convAcc = [SELECT Name, OwnerId, KeyAccount__c, Territory__c, ParentId, TCodeDescr__c,
                                    BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode,
                                    NumberOfEmployees
                                    FROM Account WHERE Id =:lcr.getAccountId()];
                
                // Assign the correct owner for the Account - if is new
                if (bg_StringUtils.IsBlank(linkAccId)) {
                    convAcc.OwnerId             = getAccountOwner();
                    convAcc.Territory__c        = territory.Id;
                    convAcc.NumberOfEmployees   = Integer.valueOf(convLead.TotalEmployees__c);
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
                Contact convCon         = [SELECT OwnerId, Territory__c FROM Contact WHERE Id =:lcr.getContactId()];
                convCon.OwnerId         = getAccountOwner();
                update convCon;
                
                if(!doNotCreateOpportunity) {
                    // Assign the correct owner for the opportunity - always created
                    Opportunity convOpty = [SELECT OwnerId, TCode__c, Territory__c, QualifiedBy__c FROM Opportunity WHERE Id =:lcr.getOpportunityId()];
                    convOpty.Name           = newOpty.Name;
                    convOpty.OwnerId        = getOptyOwner(convAcc);
                    convOpty.Territory__c   = territory.Id;
                    convOpty.TCode__c       = convAcc.TCodeDescr__c;
                    convOpty.PrimaryContact__c = lcr.getContactId(); // Default Primary Contact on Opportunity
                    convOpty.Description    = convLead.Description;
                    if (convOpty.QualifiedBy__c == null) convOpty.QualifiedBy__c = UserInfo.getUserId(); // Track who has qualified the Lead
                    // Mapping
                    if(convLead.Delivery__c != null) {  convOpty.CloseDate = convLead.Delivery__c; }
                    
                    update convOpty;
                    
                    // Manual Sharing Rule on Opportunity to allow the LQE to upload document or change some fields
                    if (convOpty.OwnerId != convLead.OwnerId) {
                        OpportunityShare oshare = new OpportunityShare();
                        oshare.OpportunityId    = lcr.getOpportunityId();
                        oshare.UserOrGroupId    = convLead.OwnerId;
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

		        // 01/08/15 RJ: Removed GetExistingCustomerServices requested by BSI
				// Move all the Existing customer services to the converted Account
				//bg_LeadUtils.TransferExistingCustomerServiceToAccount(ecsList, lcr.getAccountId());

				// 01/08/15 RJ: Removed TransferExistingSalesConsultantsToOpportunity requested by BSI
        		// Sales Consultants to move from Lead to Opps
        		//if(!doNotCreateOpportunity) {
        		//	bg_LeadUtils.TransferExistingSalesConsultantsToOpportunity(salesConsultantList, lcr.getOpportunityId());
        		//}
        		
                if (!updateDone) {
                    siteErrors = bg_LeadUtils.checkDuplicateSitesV2(sites);
                }

                if (siteErrors.size() > 0) {
                    dupeSite = true;
                    Database.rollback(sp);
                    pageA = null;
                } else {
                    //allow some to fail if dupe
                    Database.UpsertResult[] saveResults = database.upsert(sites, false);
                    system.debug('$$$ SAVE RESULTS: ' + saveResults);

					// 01/08/15 RJ: Removed GetExistingCustomerServices requested by BSI
					// update Existing Customer Services records
                    //Database.SaveResult[] saveResults2 = database.update(ecsList, false);
                    //system.debug('$$$ SAVE RESULTS: ' + saveResults2);

					// 01/08/15 RJ: Removed salesConsultantList requested by BSI
					/*
					if(!doNotCreateOpportunity) {
						// update Existing Customer Services records
	                    Database.SaveResult[] saveResults3 = database.update(salesConsultantList, false);
	                    system.debug('$$$ SAVE RESULTS: ' + saveResults3);
					}
					*/
                    Utility.lockcreateHQSite    = false;
                    Utility.lockassignTerritory = false;

                    // Redirect to converted Account page           
                    pageA = new Pagereference('/' + lcr.getAccountId());
                }
            } catch (DMLException e) {
                system.debug('DMLExcpetion ==' + e);
                Database.rollback(sp);
                ApexPages.addMessages(e);
                pageA = null;
            }
        } else {
        	system.debug('Lead conversion error ==' + lcr.getErrors().get(0).getMessage());
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, lcr.getErrors().get(0).getMessage()));
            pageA = null;
        }
        return pageA;
    }

    //DEFAUL OPTY NAME
    private String defaultOptyName(String company) {
        /*
            Set Default Oportunity Name
        */
        String optyName = '';
        optyName = company;

        // Add Registration Path            
        if(!String.IsBlank(convLead.RegistrationPath__c)) { 
            optyName += ' - ' + convLead.RegistrationPath__c;
        }

        // Add most specific information about main product
        string interest = '';
        //if(!bg_StringUtils.IsBlank(convLead.Product_Area_Interests__c)) {
        //    interest = convLead.Product_Area_Interests__c;
        //} else if(!bg_StringUtils.IsBlank(convLead.Portfolio_Interests__c)) {
        //    interest = convLead.Portfolio_Interests__c;     
        //} else if(!bg_StringUtils.IsBlank(convLead.Product_SubStream__c)) {
        //    interest = convLead.Product_SubStream__c;

        // RJ 25-08-15
        // Add Stream
        if(!String.isBlank(convLead.Product_Stream__c)) {
            interest = convLead.Product_Stream__c;
        }

		// Add Product Interest
        if(!String.isBlank(convLead.Product_Interests__c)) {
            interest += ' ' + convLead.Product_Interests__c;
        }

        optyName = (optyName + ' - ' + interest).left(120); // ensure name is limited to 120 characters

        return optyName;
    }

    
    // BACK TO LEA DETAIL
    public Pagereference back() {
        Pagereference pageL = new Pagereference('/' + convLead.Id);
        return pageL;
    }

    // back to convert page
    public Pagereference backConvert() {
        siteErrors = new Map<Site__c,Site__c>();
        dupeSite = false;
        Pagereference pageL = new Pagereference('/apex/leadConversionV2?scontrolCaching=1&id=' + convLead.Id);
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
        else if (acc != null && acc.KeyAccount__c) { 
            ownerId = acc.OwnerId;

        // check for assignment rules
        } else if (ranges != null && !ranges.isEmpty()) {
            ownerId = ranges.get(0).AssignedTo__c;
        }
        // otherwise add the lead territory main Owner
        else if (territory != null && territory.AssignedTo__c != null) {
            ownerId = territory.AssignedTo__c;
        }
        return ownerId;
    }

	public List<SelectOption> getCurrencyISOCodes(){
		List<CurrencyType> pListSupportedISOCodes = [SELECT ISOCode FROM CurrencyType WHERE IsActive=TRUE];                    
		//List<sObject> pListSupportedISOCodes = Database.query(supportedISOCodesQ);
		
		List<SelectOption> currencyOptions = new List<SelectOption>();
		currencyOptions.add(new SelectOption('','-None-'));
		
		for(CurrencyType c:pListSupportedISOCodes){
			currencyOptions.add(new SelectOption(c.IsoCode, c.IsoCode));
		}
		
		return currencyOptions;
	}
}