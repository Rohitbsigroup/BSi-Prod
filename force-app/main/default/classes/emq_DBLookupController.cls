/**
*	Author		: Prasad JN
*	Description	: Looks up for accounts against DUNS API
*/
public with sharing class emq_DBLookupController {

    public Account PassedAccount { get; set; }
    public String SelectedDuns { get; set; }
    public String CompanyName { get; set;}
    public String DUNSNumber { get; set;}
    public String City { get; set;}
    public String State { get; set;}
    public String CountryCode { get; set;}
    public Boolean Filter { get; set;}
    public Boolean ShowCreate { get; set;}
    public List<LOOKUPRSCOMPANY> LookupResults{ get; set;}
    public SystemSetting__c sys = SystemSetting__c.getInstance();
    
    public emq_DBLookupController(){
    	String operationCountry = [Select OperationCountry__c From User Where Id = :UserInfo.getUserId()][0].OperationCountry__c;
    	this.CountryCode = operationCountry;
    	
    	this.CompanyName = ApexPages.currentPage().getParameters().get('companyName');
		this.DUNSNumber = ApexPages.currentPage().getParameters().get('dunsNumber');
		this.City = ApexPages.currentPage().getParameters().get('city');
		this.State = ApexPages.currentPage().getParameters().get('state');
		this.CountryCode = String.isNotBlank(ApexPages.currentPage().getParameters().get('countryCode')) ?
							ApexPages.currentPage().getParameters().get('countryCode') : operationCountry;
		this.ShowCreate = true;
		
		if(String.isNotBlank(this.CompanyName) || String.isNotBlank(this.DUNSNumber))
			Lookup();
    }
    
    public emq_DBLookupController(ApexPages.StandardController stdController) {
    	String operationCountry = [Select OperationCountry__c From User Where Id = :UserInfo.getUserId()][0].OperationCountry__c;
    	this.CountryCode = operationCountry;
    	
    	if(String.isNotBlank(stdController.getId())){
	        // Select the Account
	        this.PassedAccount = [
	            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Phone, DUNS_Number__c
	            FROM   Account
	            WHERE  Id = :stdController.getId()
	        ];    
        	
    		this.ShowCreate = false;
        
      		Lookup();
    	} else{
    		this.CompanyName = ApexPages.currentPage().getParameters().get('companyName');
    		this.DUNSNumber = ApexPages.currentPage().getParameters().get('dunsNumber');
    		this.City = ApexPages.currentPage().getParameters().get('city');
    		this.State = ApexPages.currentPage().getParameters().get('state');
    		this.CountryCode = String.isNotBlank(ApexPages.currentPage().getParameters().get('countryCode')) ?
    							ApexPages.currentPage().getParameters().get('countryCode') : operationCountry;
    		this.ShowCreate = true;
    		
    		if(String.isNotBlank(this.CompanyName) || String.isNotBlank(this.DUNSNumber))
    			Lookup();
    	}
    }
    
    public void Lookup() {
    	this.lookupResults = new List<LOOKUPRSCOMPANY>();
        
        emq_DBLookupProvider.lookUpInput inp = new emq_DBLookupProvider.lookUpInput();
		inp.Business_Number = '';
		inp.Reason_Code = '';
		inp.Match_Type = 'C';
		inp.Max_Responses = '50';
		inp.File_Id = '';
		inp.Search_Rule_Code = '';
		inp.Town = '';
		inp.PostTown = '';
		
		if((filter == null || !filter) && !ShowCreate){
        	this.CompanyName = this.PassedAccount.Name;
        	this.DUNSNumber = this.PassedAccount.DUNS_Number__c;
        
			inp.Name = String.isNotBlank(this.PassedAccount.Name) ? this.PassedAccount.Name : '';
	        inp.Town = String.isNotBlank(this.PassedAccount.BillingCity) ? this.PassedAccount.BillingCity : '';
	        inp.State_or_Region = String.isNotBlank(this.PassedAccount.BillingState) ? this.PassedAccount.BillingState : '';
	        inp.Post_Code = String.isNotBlank(this.PassedAccount.BillingPostalCode) ? this.PassedAccount.BillingPostalCode : '';
	        inp.DnB_DUNS_Number = String.isNotBlank(this.PassedAccount.DUNS_Number__c) ? this.PassedAccount.DUNS_Number__c : '';
	        inp.PostTown = String.isNotBlank(this.PassedAccount.BillingCity) ? this.PassedAccount.BillingCity : '';
	        inp.Country_Code = String.isNotBlank(this.PassedAccount.BillingCountry) ? this.PassedAccount.BillingCountry : this.CountryCode;
		} else {
			inp.Name = String.isNotBlank(this.CompanyName) ? this.CompanyName : '';
			inp.DnB_DUNS_Number = String.isNotBlank(this.DUNSNumber) ? this.DUNSNumber : '';
	        inp.Country_Code = String.isNotBlank(this.CountryCode) ? this.CountryCode : '';
	        inp.State_or_Region = String.isNotBlank(this.State) ? this.State : '';
	        inp.Town = String.isNotBlank(this.City) ? this.City : '';
	        inp.PostTown = String.isNotBlank(this.City) ? this.City : '';
		}
		
		if((this.CountryCode == 'US' || this.CountryCode == 'CA') && this.State == ''){
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'State selection is mandatory for US & Cananda'));
			return;
		}
    
    	emq_DBLookupProvider.lookUpRequest request = new emq_DBLookupProvider.lookUpRequest();
		request.lookUpInput = inp;
		request.UserId = sys.DBUserName__c;//'BSITKT3ST';
        request.Password = sys.DBPassword__c;//'CH1SWICk';

        emq_DBLookupProvider.DNB_WebServices_Providers_LookUp_wsp_LookUp_Port service = new emq_DBLookupProvider.DNB_WebServices_Providers_LookUp_wsp_LookUp_Port();
        emq_DBLookupProvider.lookUpResponse response = service.ws_LookUp(request);
        
        if (response.DGX.CREDITMSGSRSV2 != null && response.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.STATUS.CODE == '0') {
			List<emq_DBLookupProvider.LOOKUPRSCOMPANY> companies = response.DGX.CREDITMSGSRSV2.LOOKUPTRNRS.LOOKUPRS.LOOKUPRSCOMPANY.ArrayOfLOOKUPRSCOMPANYItem;
            for (emq_DBLookupProvider.LOOKUPRSCOMPANY company : companies) {
            	if(this.PassedAccount.DUNS_Number__c == company.DUNS_NBR)
					this.SelectedDuns = company.DUNS_NBR;
					
                this.LookupResults.add(new LOOKUPRSCOMPANY(company));
			}
        } else if (response.DGX.SIGNONMSGSRSV1 != null && response.DGX.SIGNONMSGSRSV1.SONRS.STATUS.CODE == '36803') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Your D&B user credentials have expired. Please contact BSI Salesforce Support Team or your D&B representative'));
            return;
        }
        
        if(String.isEmpty(this.SelectedDuns) && this.LookupResults != null && this.LookupResults.size() > 0)
        	this.SelectedDuns = this.LookupResults.get(0).DUNS_NBR;
    }
    
    public PageReference UpdateDuns() {
    	// Update the Account
        Account account = new Account(Id = this.PassedAccount.Id, DUNS_Number__c = this.SelectedDuns);
        update account;
        
    	PageReference pageRef = new PageReference('/' + this.PassedAccount.Id);
        return pageRef;
    }
    
    public PageReference UpdateAddress() {
    	LOOKUPRSCOMPANY source;
    	for (LOOKUPRSCOMPANY company : this.LookupResults) {
            if (company.DUNS_NBR == this.SelectedDuns) {
                source = company;
                break;
            }
        }
        
        Account account = new Account(Id = this.PassedAccount.Id, DUNS_Number__c = this.SelectedDuns, Name = source.NME, 
        	BillingStreet = source.ADR_LINE, BillingCity = source.NON_POST_TOWN, BillingPostalCode = source.POST_CODE, Phone = source.TLCM_NBR,
        	BillingCountry = this.CountryCode);
        update account;
        
    	PageReference pageRef = new PageReference('/' + this.PassedAccount.Id);
        return pageRef;
    }
    
    public PageReference SearchDB(){
    	PageReference pageRef = new PageReference('/emq_DBLookup/' + this.PassedAccount.Id);
        return pageRef;
    }
    
    public void Filter() {
    	this.Filter = true;
    	Lookup();
    }
    
    public PageReference CreateAccount() {
    	LOOKUPRSCOMPANY source;
    	for (LOOKUPRSCOMPANY company : this.LookupResults) {
            if (company.DUNS_NBR == this.SelectedDuns) {
                source = company;
                break;
            }
        }
        
        List<Account> acc = [SELECT ID, Name FROM Account WHERE DUNS_Number__c = :this.SelectedDuns];
        
        if(acc != null && acc.size() > 0){
        	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Account with the same DUNS Number already exists. Click <a href="/' 
        				+ acc[0].Id + '">' + acc[0].Name + '</a> to view account.'));
        	return null;
        }
        
    	Account account = new Account(DUNS_Number__c = this.SelectedDuns, Name = source.NME, 
        	BillingStreet = source.ADR_LINE, BillingCity = source.NON_POST_TOWN, BillingPostalCode = source.POST_CODE,
        	BillingCountry = this.CountryCode, Phone = source.TLCM_NBR);
        
        insert account;	
    	PageReference pageRef = new PageReference('/' + account.Id);
        return pageRef;
    }
    
     // Copy of dbLookUp.LOOKUPRSCOMPANY is required for presentation via VisualForce
    public class LOOKUPRSCOMPANY {
        public String ADR_LINE { get; set; }                    // Street
        public String BR_IND { get; set; }                    	// Branch Indicator
        public String DUNS_NBR { get; set; }                    // DUNS number
        public String NME { get; set; }                         // Company name
        public String NON_POST_TOWN { get; set; }               // Town/city (e.g. Bangalore)
        public String POST_CODE { get; set; }                   // Postcode
        public String TLCM_NBR { get; set; }   	                // Telephone Number
        public String CTRY_CD  { get; set; }   	                // Telephone Number
        public String CONF_CD  { get; set; } 

        public LOOKUPRSCOMPANY(emq_DBLookupProvider.LOOKUPRSCOMPANY c) {
            this.ADR_LINE = c.ADR_LINE;
            this.BR_IND = c.BR_IND;
            this.DUNS_NBR = c.DUNS_NBR;
            this.NME = c.NME;
            this.NON_POST_TOWN = c.NON_POST_TOWN;
            this.POST_CODE = c.POST_CODE;
            this.TLCM_NBR = c.TLCM_NBR;
            this.CTRY_CD = c.CTRY_CD;
            this.CONF_CD = c.CONF_CD;
        }
    }
    
    public List<SelectOption> CountryList{
    	get{
    		List<SelectOption> options = new List<SelectOption>();
    		
			List<Country_Code__mdt> countries = [SELECT Country_Name__c, ISO_Alpha_2_Country_Code__c FROM Country_Code__mdt ORDER BY Country_Name__c ASC];
			for(Country_Code__mdt country: countries){
				options.add(new SelectOption(country.ISO_Alpha_2_Country_Code__c, country.Country_Name__c));
			}
			
			return options;
    	}
    }
    
    public List<SelectOption> StateList{
    	get{
    		List<SelectOption> options = new List<SelectOption>();
    		
			List<US_Canada_State_Codes__mdt> states = [SELECT Label, Code__c FROM US_Canada_State_Codes__mdt WHERE Country__c = :this.CountryCode ORDER BY Label ASC];
			for(US_Canada_State_Codes__mdt state: states){
				options.add(new SelectOption(state.Code__c, state.Label));
			}
			
			return options;
    	}
    }
    
    public Boolean StateSelectOrInput{
    	get{
    		if(this.CountryCode == 'US' || this.CountryCode == 'CA')
    			return true;
    		else
    			return false;
    	}
    }
}