/**
*
* Author:       Carmine Barbuto
* Company:		Tquila
* Date:         06/12/2011
* Description:  Visualforce Controller used to smooth the process of adding a new
*				quote from the opportunity page. After saving quote and selected 
*				product, the user willbe automatically redirected to the main
*				configurator page. 
*
*       
**/
public without sharing class NewQuoteController {
	
    public Quote__c 		newQuote		{get; set;} 
    
    public String			sContact		{get; set;}
    public String			sInvoice		{get; set;}
    public String			sType			{get; set;}
    public String			sFamily			{get; set;}
    public String			sCostCenter		{get; set;}
    public String 			opporutnityid	{get; set;}
	public Boolean			isEditMode		{get; set;}
	public Opportunity		opty			{get; set;}
	public OpportunitySite__c	quoteHQ		{get; set;}
	public OpportunitySite__c	quoteT		{get; set;}
	public OpportunitySite__c	quoteN		{get; set;}
	
	public List<OpportunitySite__c> namedSites 	{get; set;}
	
    public List<ProductWrapper> 	PWlist 	{get; set;}
	public Map<String,Integer>      sTypes  {get; set;}	
	
	private Id 				idOpty 			= null;
    private Id 				idAccount 		= null;
    private Id				idQuote			= null;
    private Integer 		countlist 		= 0;
    private String			hqName			= '';
    
    public String 			slistQuoteProducts 	= '';
    public String 			sActiveProduct		= '';
    
    public List<String>		countries		{get; set;}
    
    public Boolean 			isMultiSite		{get; set;}
    public Boolean			isTransient		{get; set;}
    public Boolean			isNetwork		{get; set;}
    public Boolean			editPath		{get; set;}
    public Boolean			noSiteType		{get; set;}
    public Integer			totalSites		{get; set;}
    public List<SiteType>	siteTypes		{get; set;}
    
    public String			consID			{get; set;}    
    public Contact			consultant		{get; set;}
    
    public SiteSetting__c	setting			{get; set;}
    public Set<String>		keyRoles;
    public String			countryList;
    
    public String getconsRT() {
    	return Utility.RTNAME_CONSULTANT;
    }
    
    Map<String,ID> mapProd 	= new Map<String,ID>();
    QuoteSetting__c qset	= QuoteSetting__c.getInstance();
    
    // CONTROLLER
    public NewQuoteController() {
		// Initializing...
        idOpty		= ApexPages.currentPage().getParameters().get('oppid');
        idAccount	= ApexPages.currentPage().getParameters().get('accid');
        idQuote 	= ApexPages.currentPage().getParameters().get('quoid');
		newQuote 	= new Quote__c();
		opty		= new Opportunity();
		consultant	= new Contact();
		PWList		= new List<ProductWrapper>();
		sTypes		= new Map<String,Integer>();
		siteTypes	= new List<SiteType>();
		countries	= new List<String>();
		isMultiSite = false;
		isTransient = false;
		isNetwork   = false;
		editPath	= false;
		noSiteType	= false;
		totalSites	= 0;
		setting 	= SiteSetting__c.getInstance();
		
		// Select all BP Products
		List<Product__c> prods = [SELECT Name FROM Product__c];
		for (Product__c curr : prods) {
			mapProd.put(curr.Name, curr.Id);
		}
		
		// Check if we are creating a new quote or adding product to an existing one
		isEditMode = (idQuote != null)? true : false;
		
		//if (!isEditMode) {
			opty = [SELECT Name, Account.Name, Account.SiteNumber__c, SiteNumber__c, SiteDifference__c, ScopeofRegistration__c, RegistrationPath__c, PrimaryContact__c, PriceBook2Id, QuoteReady__c FROM Opportunity WHERE Id =:idOpty];
			
			// Quote HQ and sites
			Map<String,Id> rtypeMap = Utility.getRecordTypes('Site__c');
			List<OpportunitySite__c> osites = [SELECT Site__r.Type__c, Site__r.RecordTypeId, Site__r.Name, 
												Site__r.Postcode__c, Site__r.Country__c, Site__r.Street__c,
												Site__r.City__c, HQ__c, Site__r.Description__c, Site__c,
												Site__r.SecurityIssue__c, Site__r.GeographicIssue__c,
												Site__r.State__c
												FROM OpportunitySite__c WHERE Opportunity__c =:idOpty];
			totalSites = osites.size();
			Integer siteNum = 0;
			namedSites = new List<OpportunitySite__c>();
			Set<String> sc = new Set<String>();
			for (OpportunitySite__c curr : osites) {
				if (curr.Site__r.RecordTypeId == rtypeMap.get(Utility.RTNAME_NETWORK)) {
					isNetwork 	= true;
					quoteN    	= curr;
				} else if (curr.Site__r.RecordTypeId == rtypeMap.get(Utility.RTNAME_TRANSIENT)) {
					isTransient = true;
					quoteT		= curr;
				} else if (curr.Site__r.RecordTypeId == rtypeMap.get(Utility.RTNAME_NAMED) && !curr.HQ__c) {//HQ must be filtered
					namedSites.add(curr);
					siteNum ++;
				} else {
					siteNum ++;
				}
				if (curr.HQ__c) quoteHQ = curr;
				sc.add(curr.Site__r.Country__c);
			}
			
		
			// Filter List of available Products based on sites' countries
			if (!sc.isEmpty()) {
				countries.addAll(sc);
				countryList = '';//quoteHQ.Site__r.Country__c;
				for (String c : sc) {
					countryList += '\'' + c + '\''+',';
				}
				countryList = countryList.substring(0,countryList.length()-1); //Remove last comma from dynamic string for dynamic query
				//countryList = quoteHQ.Site__r.Country__c; //Fixed Country
				searchProds();
			}
			
		if (!isEditMode) {		
			// Site Type and sampling Management
			if (siteNum > 1) isMultiSite = true;
			Map<String,List<String>> namesMap = new Map<String,List<String>>();
			if (quoteHQ != null) hqName = quoteHQ.Site__r.Name;
			for (OpportunitySite__c curr : namedSites) {
					if (sTypes.containsKey(curr.Site__r.Type__c)) {
						Integer cnt = sTypes.get(curr.Site__r.Type__c) + 1;
						sTypes.put(curr.Site__r.Type__c,cnt);
						namesMap.get(curr.Site__r.Type__c).add(curr.Site__r.Name);
					} else if (curr.Site__r.Type__c == null) {
						noSiteType = true;
					} else {
						List<String> temp = new List<String>();
						temp.add(curr.Site__r.Name);
						sTypes.put(curr.Site__r.Type__c,1);
						namesMap.put(curr.Site__r.Type__c,temp);
					}
			}
			for (String curr : sTypes.keySet()) {
				SiteType temp = new SiteType(curr, String.valueOf(sTypes.get(curr)),samplingValue(sTypes.get(curr)));
				temp.siteNames.addAll(namesMap.get(curr));
				siteTypes.add(temp);
			}
			
			// Contact Roles
			List<Contact_Opportunity__c> roles = [SELECT Contact__c, Contact__r.Name, OppRole__c, OppPrimary__c 
												  FROM Contact_Opportunity__c 
												  WHERE Opportunity__c =:opty.Id];
			keyRoles = new Set<String>();
			for (Contact_Opportunity__c curr : roles) {
				keyRoles.add(curr.Contact__c+curr.OppRole__c);
			}
			
			// Default Field on Quote
			newQuote.Account__c				= idAccount;
			newQuote.Opportunity_Name__c	= idOpty;
			newQuote.Quote_Date__c			= Date.today();
			newQuote.Type__c				= 'Initial Quote';
			newQuote.Status__c				= 'Open';
			newQuote.Transient__c			= isTransient;
			newQuote.Network__c				= isNetwork;
			newQuote.ScopeOfRegistration__c	= opty.ScopeofRegistration__c;
			if (quoteHQ != null) {
				newQuote.Street__c			= quoteHQ.Site__r.Street__c;
				newQuote.City__c			= quoteHQ.Site__r.City__c;
				newQuote.Postcode__c		= quoteHQ.Site__r.Postcode__c;
				newQuote.State__c			= quoteHQ.Site__r.State__c;
				newQuote.Country__c			= quoteHQ.Site__r.Country__c;
			}
			// Pricebook on Opportunity
			if (opty.Pricebook2Id == null) opty.Pricebook2Id = updateOptyPricebook();
			
			// Contact defaulted to Primary Contact (if available on opportunity)
			if (opty.PrimaryContact__c != null) sContact = opty.PrimaryContact__c; 
			
			// Multi Site
			if (isMultiSite) newQuote.MultiSiteUplift__c = 1;// CREATE A CUSTOM SETTING? Not needed now
			else newQuote.MultiSiteUplift__c = 0;
			
		} else {
			// SiteType selection - retrieving the information from previous product groups 
			// Select the first one, they all follow the same structure 
			List<Quote_Product__c> qprods = [SELECT Name,SiteType__c,SiteTabLabel__c FROM Quote_Product__c 
											//WHERE GroupNumber__c = 1 AND SiteType__c != null AND Quote_Ref__c =:idQuote];
											WHERE GroupNumber__c = 1 AND Quote_Ref__c =:idQuote];
			Map<String,List<String>> namesMap = new Map<String,List<String>>();
			for (Quote_Product__c curr : qprods) {
				if (curr.SiteType__c != null) {
					if (sTypes.containsKey(curr.SiteType__c)) {
						Integer cnt = sTypes.get(curr.SiteType__c) + 1;
						sTypes.put(curr.SiteType__c,cnt);
						namesMap.get(curr.SiteType__c).add(curr.SiteTabLabel__c);
					} else {
						List<String> temp = new List<String>();
						temp.add(curr.SiteTabLabel__c);
						sTypes.put(curr.SiteType__c,1);
						namesMap.put(curr.SiteType__c,temp);
					}
				} else {
					hqName = curr.SiteTabLabel__c;
				}
			}
			for (String curr : sTypes.keySet()) {
				SiteType temp = new SiteType(curr, String.valueOf(sTypes.get(curr)),String.valueOf(sTypes.get(curr)));
				temp.siteNames.addAll(namesMap.get(curr));
				siteTypes.add(temp);
			}
		}
    }
    
    // QUICK UPDATE ON REGISTRATION PATH
    public void updatePath() {
    	try {
    		update opty;
    	} catch (DmlException dml) {
    		Apexpages.addMessages(dml);
    	}
    }
 	
 	// CLASS TO MANAGE QUOTE PRODUCT SELECTION
 	public class ProductWrapper {
 		
 		public Product__c  	product {get; set;}
 		public Boolean	   	checked {get; set;}
 		
 		public ProductWrapper(Product__c p) {
 			this.product = p;
 			this.checked = false;
 		}
 	}
	
    // RETURN THE LIST OF PRODUCT BASED ON FITER CRITERIA
    /*public List<ProductWrapper> getPWlist() {
        PWlist = new List<productWrapper>();
        for (Product__c p :  (List<Product__c>)getProducts())
            PWlist.add(new productWrapper(p));
        return PWlist;
    }*/
    
    // RETURN THE LIST OF PRODUCT BASED ON FITER CRITERIA - (simple onclick refresh not working for some reason)
    public void searchProds() {
    	PWlist.clear();
        for (Product__c p :  (List<Product__c>)queryProducts())
            PWlist.add(new productWrapper(p));
    }
    
    // CANCEL AND BACK TO OPTY-QUOTE DETAIL
    public Pagereference back() {
    	String retId = isEditMode? idQuote : idOpty;
    	Pagereference retPage = new Pagereference('/' + retId);
    	return retPage;
    }
    
    // REDIRECT TO MANAGE SITE PAGE
    public Pagereference manageSite() {
    	Pagereference retPage = new Pagereference('/apex/addOptySite?oppid=' + idOpty);
    	return retPage;
    }
    
    // UPDATE OPPORTUNITY WITH DEFAULT COUNTRY BASED ON USER OPERATION COUNTRY
    private String updateOptyPricebook() {
    	User currentUser = [SELECT OperationCountry__c FROM User WHERE Id =: UserInfo.getUserId()];
    	ConversionScore__c cs = ConversionScore__c.getInstance(currentUser.OperationCountry__c);
    	List<Pricebook2> pbs = [SELECT Id FROM Pricebook2 WHERE Name =:cs.DefaultPriceBookName__c AND IsActive = true];
		if (!pbs.isEmpty()) {
    		return pbs.get(0).Id;
		} else {
			return null;
		}
    }
	
	// GENERATE QUOTE AND REDIRECT TO CONFIGURATOR
    public PageReference generateQuote() {
		Pagereference pageQ = null;
		
		// Count number of sites
		// Check that the Salesperson has confirmed all the sampling selection
		Integer siteNum = 0;
		String samplingSelection = '';
		Set<String> samplingOK = new Set<String>();
		for (SiteType curr : siteTypes) {
			siteNum = siteNum + Integer.valueOf(curr.value);
			// Skip this check if is not a new Quote
			if (!isEditMode && curr.showQuestion) samplingOK.add(curr.approved); 
			// Skip this step if the real HQ is included in the quote but is not the HQ for the quote
			if (curr.name != setting.HQLabel__c) samplingSelection = samplingSelection + curr.name + ' (' + curr.value + ')' + ' - Selection confirmed: ' + curr.approved + '\n';
		}
		
		Set<Product__c> plist = new Set<Product__c>();
        for (productWrapper pw : PWlist) {
            if (pw.checked){
                //mapProdToAdd.put(pw.product.Id,pw.product);
                //countlist= mapProdToAdd.size();
                plist.add(pw.product);
                countlist = plist.size();
            }
        }

        if (countlist > 0 && sContact != null && sInvoice != null 
        	&& newQuote.Booking__c != null && newquote.CreditCheck__c != null 
        	&& !samplingOK.contains('No') || countList > 0 && idQuote != null) {    
            try {
            	
            	String quoteID = idQuote;
            	Integer groupNum = 1; // One for each product
	            Integer tabOrder = 1; // One for each tab in the configurator
	            
            	if (!isEditMode) {
            		// Update Opportunity with Default Pricebook if not selected - setted in the constructor
            		// Select Primary Contact
            		// Blank PDF Id for Conga Template (this is a new quote, a new doc must be linked)
            		opty.PrimaryContact__c = sContact;
            		opty.MainQuotePDFid__c = null;
    				update opty;
    				
    				// Contact Role management
    				newQuote.Contact__c			   = sContact;
	            	newQuote.Invoice_Contact__c    = sInvoice;
					List<Contact_Opportunity__c> cos = new List<Contact_Opportunity__c>();
					if (newQuote.Contact__c != null && !keyRoles.contains(newQuote.Contact__c+'Decision Maker'))
						cos.add(createContactRole(newQuote.Contact__c,'Decision Maker'));
					if (newQuote.Invoice_Contact__c != null && !keyRoles.contains(newQuote.Invoice_Contact__c+'Invoicing'))
						cos.add(createContactRole(newQuote.Invoice_Contact__c,'Invoicing'));
					if (newQuote.Booking__c != null && !keyRoles.contains(newQuote.Booking__c+'Booking'))
						cos.add(createContactRole(newQuote.Booking__c,'Booking'));
					if (newQuote.CreditCheck__c != null && !keyRoles.contains(newQuote.CreditCheck__c+'Credit Check'))
						cos.add(createContactRole(newQuote.CreditCheck__c,'Credit Check'));
	
		            // Create a new Consultant if not found
					if (newQuote.ConsultantInvolved__c == 'Yes' && consultant.FirstName != null && consultant.FirstName != ''
						&& consultant.LastName != null && consultant.LastName != '' && consultant.MailingCountry != null && consultant.MailingCountry != '') {	
						if (consID == null || consID == '') {
							Map<String,Id> rtmap = Utility.getRecordTypes('Contact');
							consultant.RecordTypeId = rtmap.get(getconsRT());
							consultant.ConsultantType__c = 'Unknown';
							insert consultant;
							cos.add(createContactRole(consultant.Id,'Consultant'));
							newQuote.ConsultantName__c = consultant.FirstName + ' ' + consultant.LastName;
						}
						// Check if the Contact Role exists
						else {
							if (newQuote.Contact__c != null && !keyRoles.contains(consID+'Consultant'))
								cos.add(createContactRole(consID,'Consultant'));
						}
		            }
		            insert cos;
					
	            	// Insert the quote
	            	newQuote.SiteSampling__c	   	= siteNum;
	            	newQuote.SamplingSelection__c  	= samplingSelection;
	            	newQuote.RegistrationPath__c   	= opty.RegistrationPath__c;
	            	if (newQuote.Outsourcing__c != 'Yes') 	newQuote.OutsourcingDetails__c = null;
	           		upsert newQuote;
	           		quoteID = newQuote.Id;
            	} else {
            		// Number of sample sites from edited quote
            		siteNum = Integer.valueOf([SELECT SiteSampling__c FROM Quote__c WHERE Id =:quoteID].SiteSampling__c);
            		// Get the current number of real Product (not the Site one -> )
            		tabOrder = (siteNum*groupNum) + groupNum + 1;	
            		groupNum = [SELECT Id FROM Quote_Product__c WHERE Quote_Ref__c =:quoteID AND Product_Name__r.Active__c = true].size() + 1;
            	}
	            
	            // Insert the selected products - check if configurator is available otherwise use related Generic
	            List<Quote_Product__c> productsToAdd = new List<Quote_Product__c>{};	            
	            //for(ID prodId : mapProdToAdd.keySet()) {
	            for(Product__c prod : plist) {	
	            	Quote_Product__c hq = new Quote_Product__c();
	            	hq.Quote_Ref__c 	= quoteID;
	            	hq.Product_Name__c = prod.Id;
	            	hq.GroupNumber__c 	= groupNum;
	            	hq.LayoutOrder__c	= tabOrder;
	            	//hq.SiteType__c		= setting.HQLabel__c;
	            	//hq.SiteTabLabel__c	= setting.HQLabel__c;
	            	hq.SiteTabLabel__c		= hqName;
	                productsToAdd.add(hq);
	                tabOrder ++;
	                // Add Site Template Product (one for each sample site)
	                for (SiteType st : siteTypes) {
	                	Boolean samp = st.value != st.realNum ? true : false; 
	                	for (Integer i = 0; i < Integer.valueOf(st.value); i++) {
	                		Quote_Product__c site = new Quote_Product__c();
		            		site.Quote_Ref__c 		= quoteID;
		            		site.Product_Name__c 	= mapProd.get(prod.Name + ' Site'); // NAMING CONVENTION = PRODCUT + SITE
		            		site.GroupNumber__c 	= groupNum;
		            		site.LayoutOrder__c		= tabOrder;
		            		site.SiteType__c		= st.name;
		            		if (samp) 
		            			site.SiteTabLabel__c = st.name + ' Sample ' + String.valueOf(i+1); // SITE TYPE + SAMPLE + #
		            		else
		            			site.SiteTabLabel__c = st.siteNames.get(i); // CURRENT NAME OF THE SITE (NO SAMPLING)
		                	productsToAdd.add(site);
	                		tabOrder ++;
	                	}
	                }

                	groupNum ++;
	            }
	            insert productsToAdd; 
	           	
				// Redirect to Configurator
            	pageQ = new Pagereference(buildURL(quoteID));
            	//pageQ = new Pagereference('/'+quoteID);
            	
            } catch (DmlException dml) {
            	Apexpages.addMessages(dml);
            	pageQ = null;
            }

        } else if ((sContact == null || sInvoice == null || newquote.Booking__c == null || newquote.CreditCheck__c == null) && idQuote == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must select all the contacts'));
            pageQ = null;
        } else if (countlist < 1) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must select at least one product'));
            pageQ = null;
        } else if (samplingOK.contains('No')) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must confirm all your sampling selections'));
            pageQ = null;
        } /*else if (newQuote.ConsultantInvolved__c == null) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must answer if a Consultant is involved.'));
            pageQ = null;
        }*/
        
        return pageQ;
    }
    
    // CREATE CONTACT ROLES
    private Contact_Opportunity__c createContactRole(String contactID, String role) {  	
    	Contact_Opportunity__c co 	= new Contact_Opportunity__c();
		co.Contact__c 				= contactID;
   		co.Opportunity__c 			= newQuote.Opportunity_Name__c;
   		co.OppRole__c 				= role;
   		if (role == 'Decision Maker') co.OppPrimary__c = true;
   		return co;
    }
    
    // BUILD BLUEPRINT URL - MULTI SITES SUPPORT
    private String buildURL(String quoteID) {
    	SystemSetting__c ss = SystemSetting__c.getInstance();
		String serverURL = ss.ServerURL__c + 'services/Soap/u/16.0/' + UserInfo.getOrganizationId();
		String returnURL = EncodingUtil.urlEncode(ss.ServerURL__c + quoteID, 'UTF-8');
		String sUrl = ss.BlueprintURL__c + 'SessionId=' + Userinfo.getSessionId() + '&ServerURL=' + serverURL + '&QuoteId=' + quoteID + '&ReturnUrl=' + returnURL;
		return sURL;
    }
    
    // SAMPLING RULE ON MULTI SITES
    private String samplingValue(Integer i) {
    	Integer num = i;
    	if (num >= setting.SamplingThreshold__c) num = Integer.valueOf(Math.sqrt(i));
    	String sample = String.valueOf(num);
    	return sample;
    }
    
    // SITE TYPE SELECTION
    public List<SelectOption> getSites() {
      	List<SelectOption> optionList = new List<SelectOption>();
      	// Add a null option to force the user to make a selection.
       	optionList.add(new SelectOption('', '- None -')); 
        
        for (String s : sTypes.keySet()) {
        	optionList.add(new SelectOption(samplingValue(sTypes.get(s)),s + ' (' + sTypes.get(s) + ')'));
        }

		return optionList;
    }
 	
 	// FAMILY SELECTION
    public List<SelectOption> getFamilys() {
      	List<SelectOption> optionList = new List<SelectOption>();
      	// Add a null option to force the user to make a selection.
       	optionList.add(new SelectOption('', '- None -')); 
        
        Map<String,Product__c> mFs = new Map<String,Product__c>();
        for (Product__c p : [SELECT Product_Family__c from Product__c p where Active__c = true and Product_Family__c != null]) {
        	mFs.put(p.Product_Family__c, p); 
        }
        for (Product__c mf : mFs.values()){
        	optionList.add(new SelectOption(mf.Product_Family__c,mf.Product_Family__c));
        }

		return optionList;
    } 
    
 	// COST CENTER SELECTION
    public List<SelectOption> getCostCenters() {
      	List<SelectOption> optionList = new List<SelectOption>();
      	// Add a null option to force the user to make a selection.
       	optionList.add(new SelectOption('', '- None -')); 

      	if(sFamily != NULL) {
	        map<STRING,Product__c> mCCs = new Map<STRING,Product__c>();
	        for (Product__c p : [select Cost_Center__c from Product__c p where Active__c = TRUE and p.Product_Family__c = :sFamily and Cost_Center__c != null]) {
	        	mCCs.put(p.Cost_Center__c, p); 
	        }
	        for (Product__c mcc : mCCs.values()){
	        	optionList.add(new SelectOption(mcc.Cost_Center__c,mcc.Cost_Center__c));
	        }

      	}
		return optionList;
    }
	
	// PRODUCT LIST BASED ON COST CENTER AND FAMILY SELECTION
	public List<Product__c> queryProducts() {
  		List<Product__c> lProducts= new List<Product__c>();
  		// If a category has been selected then query for the related values
  		if(sCostCenter != NULL && sCostCenter != '') {
   			/*lProducts = [SELECT Name, Type__c, CCode__c FROM Product__c 
   						WHERE Active__c = TRUE 
   						AND Cost_Center__c = :sCostCenter 
   						AND Product_Family__c =:sFamily 
   						order by Name];*/
   			String query = 'SELECT Name, Type__c, CCode__c FROM Product__c ' + 
   						'WHERE Active__c = TRUE ' +
   						'AND Cost_Center__c = :sCostCenter ' + 
   						'AND Product_Family__c =:sFamily ' +
   						'AND Country__c INCLUDES (' + countryList + ') ' +
   						'order by Name';
   			lProducts =	Database.query(query);		
  		}
  		// If no category has been selected then present all the products
  		else {
  			//lProducts = [SELECT Name, Type__c, CCode__c FROM Product__c WHERE Active__c = true AND Country__c includes (:countryList) order by Name];
  			String queryAll = 'SELECT Name, Type__c, CCode__c FROM Product__c WHERE Active__c = TRUE AND Country__c INCLUDES (' + countryList + ') order by Name';	
  			lProducts =	Database.query(queryAll);	
  		}
      	return lProducts;
    }

    // CONTACTS LIST BASED ON CURRENT ACCOUNT 
    public List<SelectOption> getContacts() {
      	idAccount = ApexPages.currentPage().getParameters().get('accid');
      	List<SelectOption> optionList = new List<SelectOption>();
      	// Add a null option to force the user to make a selection.
      	optionList.add(new SelectOption('', '- None -')); 

      	if(idAccount != NULL) {
	        for (Contact c : [SELECT Name FROM Contact c WHERE c.AccountId = :idAccount AND RecordType.Name !=:Utility.RTNAME_CONSULTANT]){
	          	optionList.add(new SelectOption(c.id,c.name));
	        }
     	}
      	return optionList;
    }
    
    // USERS LIST WTH NO PORAL USERS
    public List<SelectOption> getUsers() {
      	List<SelectOption> optionList = new List<SelectOption>();
      	// Add a null option to force the user to make a selection.
      	optionList.add(new SelectOption('', '- None -')); 

	    for (User u : [SELECT Name FROM User WHERE UserType = 'Standard' AND isActive = true]){
	    	optionList.add(new SelectOption(u.id,u.name));
	    }
	    
      	return optionList;
    }
    
    public class SiteType {
    	
    	public String	realNum;
    	public String	sampleNum;
    	public String	name					{get; set;}
    	public List<SelectOption>	sampling 	{get; set;}
    	public List<SelectOption>	approving	{get; set;}
    	public String	value					{get; set;}
    	public String	approved				{get; set;}
    	public Boolean	showQuestion			{get; set;}	
    	public List<String>			siteNames;
    	
    	public SiteType(String name, String real, String sample) {
    		this.name = name;
    		this.realNum = real;
    		this.sampleNum = sample;
    		this.sampling = new List<SelectOption>();
    		this.sampling.add(new SelectOption(this.realNum,this.realNum + ' (Actual)'));
    		if (real != sample) {
    			this.sampling.add(new SelectOption(this.sampleNum,this.sampleNum + ' (Sampled)'));
    			this.value = sample;
    			this.showQuestion = true;
    		} else {
    			this.value = real;
    			this.showQuestion = false;
    		}
    		this.approving = new List<SelectOption>();
    		this.approving.add(new SelectOption('Yes','Yes'));
    		this.approving.add(new SelectOption('No','No'));
    		this.approved = 'No';
    		this.siteNames = new List<String>();
    	}
    	
    }

}