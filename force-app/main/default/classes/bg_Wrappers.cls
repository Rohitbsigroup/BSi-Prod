/********************************************************************
 * bg_Wrappers
 *
 * 
 * 
 * 
 * Author: Richard Jimenez
 * Created: 02-09-2013
 * Changes: 
 * 			27-09-2017 - RC - Added extra changes to select Options RegistrationPathItems
 *			02-10-2017 - RC - Added Grid view to ProductSiteWrapper and ProductAreaWrapper
 ********************************************************************/
public class bg_Wrappers {

	public static final string SAMPLING_RULE_SQRT = 'Square Root';
	public static final string SAMPLING_RULE_1INN = '1 in N'; 
	public static final integer DEFAULT_SAMPLING_THRESHOLD = 2;
	public static final integer DEFAULT_SAMPLING_1IN5 = 5;

	public virtual class ProductWrapper {
		/*
			Product Wrapper
		*/		
		public string Id {get; set;}
		public string name {get; set;}
		public product__c Product {get; set;}
        public string ClassificationName {get; set;}
        public boolean AllowMultipleInstances {get; set;}
        public boolean ShowClassificationName {get; set;}
        public Product_Classification__c productClassification {get; set;}
		public string StandardId {get; set;}
		
		public boolean Selected {get; set;}
		public ProductAreaWrapper ProductArea {get; set;}
		public boolean GridView{get;set;}
		public string Area {get; set;}
		public string CCode {get; set;}
		public boolean SupportsIMS {get; set;}
		public string RegistrationPaths {get; set;}
		public string RiskType {get; set;}
		public boolean FileUpload {get; set;}
		
		public string SamplingRule {get; set;}
		public integer SamplingThreshold {get; set;}
		public integer Sampling1inN {get; set;}

		public ProductWrapper() {
			Selected = false;
			SupportsIMS = false;
			ShowClassificationName = false;
			SamplingRule = SAMPLING_RULE_SQRT;
			SamplingThreshold = DEFAULT_SAMPLING_THRESHOLD;
			Sampling1inN = DEFAULT_SAMPLING_1IN5;
		}
		
		public boolean IsRisk {
			get {
				return RiskType == bg_ProductUtils.PRODUCT_TYPE_RISK;
			}
		}
		
		// IB POC of dynamic wrapper
		public Map<String, Object> displayFields{get; set;}
		
	}

	public class RegPathSampleWrapper {
		/*
			Registration Path Sampling Wrapper
		*/
		public boolean SelectionValid {get; set;}
		public integer MinSampleSize {get; set;}
		public map<integer, bg_Wrappers.ProductSiteWrapper> pswMap {get; set;}
		
		public RegPathSampleWrapper() {
			pswMap = new map<integer, bg_Wrappers.ProductSiteWrapper>();
		}		
	}

	public class RelatedProductWrapper extends ProductWrapper {
		/*
			Related Product Wrapper
		*/
		public string RelationshipType {get; set;}
		
		public RelatedProductWrapper() {
		}		
	}

	public class RelatedProjectWrapper extends ProjectWrapper {
		/*
			Related Project Wrapper
		*/
		public string RelationshipType {get; set;}
		
		public RelatedProjectWrapper() {
		}		
	}

	public class ProductAreaWrapper {
		/*
			Product Area Wrapper
		*/
		public boolean IsCollapsed {get; set;}
		public string Title {get; set;}
		public list<QuoteProductWrapper> Products {get;set;}
		public integer SelectedProductCount {get;set;}
		public boolean GridView{get;set;}
		//JORGE
		public Project__c Project {get; set; }
		//JORGE
		
		public ProductAreaWrapper() {
			IsCollapsed = true;
			SelectedProductCount = 0;
			Products = new list<QuoteProductWrapper>();
		}
	}
	
	public class ProductSiteWrapper {
		/*
			Product Site Wrapper
		*/
		public Id qpId {get; set;}
		public string RegistrationPath {get; set;}
		public string OldRegistrationPath {get; set;}

		public boolean Selectable {get; set;}
		public string Product {get;set;}
		public integer SiteIndex {get;set;}
		public string PricebookName {get;set;}
		public Id PricebookId {get;set;}
		public string CurrencyCode {get;set;}
		public boolean Completed {get;set;}
		public Id SecondaryPricebookId {get; set;}
		public string RiskLevel {get; set;}
		public string OldRiskLevel {get; set;}
		public string CalculatedRiskLevel {get; set;}
		public boolean Selected {get; set;}
		public boolean FileUploaded {get; set;}
		public boolean IsControllingLocation{get;set;}
		
		// Referenced Objects
		public QuoteProductWrapper QuoteProduct {get; set;}
		public SiteWrapper Site {get; set;}

		// new contact map
		public map<string, Id> ContactRoleMap {get; set;}
		public map<Id, Contact> ContactMap {get; set;}
			
		public ProductSiteWrapper() {
			ContactRoleMap = new map<string, Id>();
			//internalSelected = false;
			Selected = false;
		}

		public string MainContact {
			get { return ContactRoleMap.get(bg_ContactUtils.CONTACT_SITE_ROLE_PRIMARY); }
			set {}
		}

		public string BookingContact {
			get { return ContactRoleMap.get(bg_ContactUtils.CONTACT_SITE_ROLE_BOOKING); }
			set {}
		}
		
		public string InvoiceContact {
			get { return ContactRoleMap.get(bg_ContactUtils.CONTACT_SITE_ROLE_INVOICE); }
			set {}
		}	
		
		public string CreditContact {
			get { return ContactRoleMap.get(bg_ContactUtils.CONTACT_SITE_ROLE_CREDIT_CHECK); }
			set {}
		}
		
		public boolean HasSelectedContacts {
			get {
				for(string role : ContactRoleMap.keySet()) {
					if(!bg_StringUtils.IsBlank(ContactRoleMap.get(role))) {
						return true;
					}
				}
				return false;
			}
		}

				
		public boolean HasUnselectedContacts {
			get {
				for(string role : ContactRoleMap.keySet()) {
					if(bg_StringUtils.IsBlank(ContactRoleMap.get(role))) {
						return true;
					} 
				}
				return false;
			}
		} 

		public string SelectedContacts {
			get {
				return bg_WrapperHelper.GetContactsRoleString(ContactRoleMap, ContactMap);
			}
		} 

		public string UnselectedContacts {
			get {
				return bg_WrapperHelper.GetContactsRoleString(ContactRoleMap, ContactMap);
			}
		}

		public list<SelectOption> RegistrationPathItems {
			get {
				//work out if there is an transition set and its controlling.
				boolean transitionExists = false;
				string controllingLocationRegPath = '';
				
				for(ProductSiteWrapper psw : QuoteProduct.SitesMap.Values())
				{
					if(bg_Globals.HQ_ONLY_REG_PATHS.contains(psw.RegistrationPath))
					{
						transitionExists = true;
					}
					
					if(psw.IsControllingLocation)
						controllingLocationRegPath = psw.RegistrationPath;
						
				}
				return bg_WrapperHelper.GetRegistrationPathItems(QuoteProduct.IsDefaultSelected, QuoteProduct.RegistrationPaths, 
					this.IsControllingLocation, controllingLocationRegPath, transitionExists);
			}
			set;
		}		
	}

	public class QuoteProductWrapper extends ProductWrapper {
		/*
			Quote Product Wrapper
		*/
		public string qpId {get; set;}
		public boolean SamplingAvailable {get; set;}
		public boolean UseSampling {get; set;}
		public boolean IMS {get; set;}
		public string controllingLocationId {get; set;}	
		public boolean VerifiedForSampling {get; set;}
		public boolean HQOnly {get; set;}
		public set<string> IMSProducts {get; set;}
		public map<integer, ProductSiteWrapper> SitesMap {get; set;}

		public string ConfigureUrl {get; set;}		
		public string SampleQuestionURL {get;set;}  
		public string IMSQuestionURL {get;set;}  
		public boolean SingleSellProduct {get;set;}
		public string CountriesRequiringBSIMembership {get;set;}
		public Quote_Product__c QuoteProduct {get; set;}
		public Project__c project {get; set;}

		public integer Instance {get; set;}		

		public boolean RequiresContractReview {get; set;}


		public ID projectID { get; set; }

		public string InstanceName {
			get {
				if(AllowMultipleInstances) {
					return Name + ' (' + string.valueOf(Instance) + ')';
				} else {
					return Name;
				}
			}
		}

		public boolean ConfigurationComplete
		{
			get
			{
				//loop round all the site maps to see that the configuation is complete
				for(ProductSiteWrapper psw : sitesMap.values())
				{
					if(psw.Completed!=null)
					{
						if(!psw.Completed && psw.Selected)
						{
							return false;
						}

					}
					else
					{
						return false;
					}
				}

				//tick box can only exist if the quote product is in the system.
				if(qpId==null)
				{
					return false;	

				}
				
				return true;
			}

		}


		public string DisplayName {
			get {
				string displayName;
				
				if(ShowClassificationName) {
					displayName = ClassificationName;
				} else {
					displayName = Name;
				}
				
				if(AllowMultipleInstances) {
					displayName += ' (' + string.valueOf(Instance) + ')';
				}

				//fix displayname for projects
				if(projectId!=null && Project.RecordType.Name == 'Customized Audits')
				{
					displayName = Project.Name + ' - ' + Project.Project_Name__c;
				} else if(projectId!=null ){
					displayName = Project.Name + ' - ' + Project.Project_Name__c + ' - ' + Project.Area_of_Practice__c;
				}

				return displayName;
			}
		}

		public QuoteProductWrapper() {
			Instance = 1;
			Selected = false;
			SamplingAvailable = false;
			UseSampling = true;
			IMS = false;
			VerifiedForSampling = false;
			HQOnly = false;
			AllowMultipleInstances = false;
			SitesMap = new map<integer, ProductSiteWrapper>(); 
			IMSProducts = new set<string>();
			SingleSellProduct = false;
			ClassificationName = '';
			Name = '';
			RequiresContractReview = false;
		}

		public boolean ValidForSampling {
			get { 
					return VerifiedForSampling && UseSampling && SamplingAvailable; 
				} 
			set;
		}

		public boolean UnvalidForSampling {
			get { 
					return !VerifiedForSampling && UseSampling && SamplingAvailable; 
				} 
			set;
		}

		public string DefaultRegistrationPath {
			get { 
				return (IsDefaultSelected?RegistrationPaths:'');
			} 
		}
		
		public list<SelectOption> RegistrationPathItems {
			get {
				return bg_WrapperHelper.GetRegistrationPathItems(IsDefaultSelected, RegistrationPaths);
			}
			set;
		}

		public list<SelectOption> ControllingLocations {
			get {
					return bg_WrapperHelper.GetControllingLocations(SitesMap.Values());
				}
			set;
		}
		
		public boolean IsDefaultSelected {
			get {
				list<string> values = bg_StringUtils.ConvertPicklistValueToList(RegistrationPaths);
				return ((HQOnly || SingleSellProduct ) && values.size() == 1);
			}
		}
	}

	public class SiteWrapper {
		/*
			Site Wrapper
		*/		
		public integer Index {get;set;}
		public Id Id {get;set;}
		public Id OppSiteId {get;set;}
		public string Name {get;set;}	
		public string Type {get;set;}
		public boolean IsHQ {get;set;}
		public string TCode {get;set;}
		public string SCode {get;set;}
		public string Country {get;set;}
		public string RiskLevel {get;set;}
		public integer NoEmployees{get;set;}
		
		public string TCodePrefix {
			get {
				if(!bg_StringUtils.IsBlank(TCode)) { 
					return TCode.left(TCode.indexOf(' '));
				} else {
					return '';
				}
			}
		}
	}	

	public class IMSWrapper {
		/*
			IMS Wrapper
		*/		
		public string Product {get;set;}
		public set<string> IMSProducts {get;set;}
		public set<string> SelectedProducts {get;set;}
		public set<string> AllSelectedIMS {get;set;}
		public set<string> SelectedIMSProducts {get;set;}
		public boolean AllProducts {get;set;}

		public IMSWrapper() {
			IMSProducts = new set<string>();
			AllSelectedIMS = new set<string>();
			AllProducts = false;
		}

		public boolean IMSAvailable {	
			get { 
					system.debug('IMSWrapper.Product: ' + Product);
					system.debug('IMSWrapper.SelectedIMSProducts: ' + SelectedIMSProducts);
					system.debug('IMSWrapper.AllProducts: ' + AllProducts);
					system.debug('IMSWrapper.IMSProducts: ' + IMSProducts);
					system.debug('IMSWrapper.SelectedProducts: ' + SelectedProducts);
					system.debug('IMSWrapper.AllSelectedIMS: ' + AllSelectedIMS);
					
					return (AllProducts && AllSelectedIMS.size() > 1) ||					
							IMSProducts.size() > 0 && SelectedIMSProducts(); 
				}
			set;
		}

		private boolean SelectedIMSProducts() {
			return bg_WrapperHelper.IsSelectedIMSProducts(Product, SelectedProducts, SelectedIMSProducts, IMSProducts);
		}
	}

	public virtual class ProjectWrapper {
		/*
			Project Wrapper
		*/	
		public string Id {get; set;}
		public string name {get; set;}
		public Project__c Project {get; set;}
	    public Boolean Active{get;set;}
	    public boolean Selected {get; set;}
	    public String ProjectStatus {get;set;}
	    public String ProjectType {get;set;}

	    //Constructor Method
		public ProjectWrapper(){
			Selected = false;
		}
		// IB POC of dynamic wrapper
		public Map<String, Object> displayFields{get; set;}
		public Product_Classification__c productClassification {get; set;}

	}


}