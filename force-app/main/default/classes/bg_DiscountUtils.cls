/********************************************************************
 * bg_DiscountUtils
 *
 * Utility methods to support Discounting
 * 
 * Author: Richard Jimenez
 * Created: 18-11-2013
 * Changes: 26-03-2015 - RPJ - Added Skip Region by Product
 ********************************************************************/
public with sharing class bg_DiscountUtils {

	public class DiscountException extends Exception{}

	public static final string APPROVER_FIELD_NAME 	    = 'Approver';
	public static final string PREAPPROVER_FIELD_NAME 	= 'PreApprover';
	public static final string APPROVAL_TYPE            = 'ApprovalType';

	public static final string APPROVAL_TYPE_UNANIMOUS  	= 'Unanimous';
	public static final string APPROVAL_TYPE_FIRSTRESPONSE  = 'First Response';
	
	public static final string DEFAULT_APPROVER_TYPE 		= 'Default';
	public static final string LINE_MANAGER_APPROVER_TYPE 	= 'Line Manager';
	public static final string USER_APPROVER_TYPE 			= 'User';
	public static final string COUNTRY_APPROVER_TYPE 		= 'Country Approver';

	public static final string DISCOUNT_MANAGER_APPROVER_TYPE = 'Discount Manager';
	public static final integer MAX_DISCOUNT_MANAGERS = 2;

	public static final integer MAX_APPROVERS = 5;

	public static map<string, map<string, User>> GetQuoteDiscountApprovers(Id quoteId) {
		/*
			Get Quote Approvers
		*/
		Quote__c quote = GetDiscountQuote(quoteId);
		decimal quoteDiscount = quote.Total_Price_Discount__c;
		decimal quoteValue = quote.Total_Price__c;
		string quoteCurrencyIsoCode = quote.CurrencyIsoCode;
		Id quoteOwnerId = quote.OwnerId;
		Id opportuntyId = quote.Opportunity_Name__c;
		string quoteOwnerCountryCode = bg_UserUtils.GetUserById(quoteOwnerId).OperationCountry__c;
		boolean isQuoteRegional = false;
		boolean isQuoteIntraRegional = false;

		if(!SkipRegionalApproval(quoteId)) {
			// Check quote is regional
			isQuoteRegional = IsQuoteRegional(opportuntyId);
			// Check quote is intra regional
			isQuoteIntraRegional = IsQuoteIntraRegional(opportuntyId);
		}

		return GetQuoteDiscountApprovers(quoteOwnerId, quoteOwnerCountryCode, quoteCurrencyIsoCode, quoteValue, quoteDiscount, isQuoteRegional, isQuoteIntraRegional); 
	}

	public static Quote__c GetDiscountQuote(Id quoteId) {
		/*
			Return Quote with discount information
		*/
		Quote__c quote = [SELECT Opportunity_Name__c, Total_Price_Discount__c, Total_Price__c, CurrencyISOCode, OwnerId, Owner.Name
							FROM Quote__c
							WHERE Id = :quoteId];
		return quote;
	}	

	public static boolean HasDiscountUserMatrix(Id userId) {
		/* Does User have Discount Matrix? */
		Discount_User_Matrix__c dum;
		try {
			dum = GetDiscountUserMatrix(userId);
		} catch (Exception e) {}
		return (dum != null);
	}
	
	public static Discount_User_Matrix__c GetDiscountUserMatrix(Id userId) {
		/* 
			Get Discount User Matrix
		*/
		Discount_User_Matrix__c dum;
		list<Discount_User_Matrix__c> dums;
		try {
				dums = [SELECT Discount_Matrix__r.Id, Discount_Matrix__r.CurrencyIsoCode 
						FROM Discount_User_Matrix__c
						WHERE Discount_Matrix__r.Active__c = true 
							AND User__c = :userId];			
		} catch (Exception e) {}

		if(dums != null && dums.size() > 0) {
			if(dums.size() > 1) {
				// throw error is user has more than 1 matrix assigned.
				throw new DiscountException(Label.UserHasMultipleDiscount);
			} else {
				dum = dums[0];
			}
		}
		return dum;
	}

	public static map<string, map<string, User>> GetQuoteDiscountApprovers(Id quoteOwnerId, string quoteOwnerCountryCode, string quoteCurrencyIsoCode, decimal quoteValue, decimal quoteDiscount, boolean isQuoteRegional, boolean isQuoteIntraRegional) {
		/*
			Get map of approvers
		*/
		
		// Approvers Map
		map<string, map<string, User>> approversMap;
		
		// Get Discount User Matrix
		Discount_User_Matrix__c dum = GetDiscountUserMatrix(quoteOwnerId);
		if(dum == null) {
			throw new DiscountException(Label.FailedToLoadUsersDiscountMatrix);
		}

		// Get Get Discount Region
		Discount_Region__c dr = GetDiscountRegion(quoteOwnerCountryCode);
		if(dr == null) {
			throw new DiscountException(string.format(Label.FailedToLoadUsersDiscountRegion, new list<string>{quoteOwnerCountryCode}));
		}		

		if(dum != null) {
			// convert quote value to matrix value
			decimal convertedValue = bg_PricebookUtils.GetConvertedValue(quoteCurrencyIsoCode, dum.Discount_Matrix__r.CurrencyIsoCode, quoteValue);

			// Get Discount Matrix Record
			Discount_Matrix_Record__c dmr = GetDiscountMatrixRecord(dum.Discount_Matrix__r.Id, quoteDiscount, convertedValue);

			if(dmr != null) {

				// Get Users Line Manager
				User lineManager;
				if(IsLineManagerRequired(dmr)) {
					lineManager = GetLineManager(quoteOwnerId);
					if(lineManager == null) {
						throw new DiscountException(Label.UserDoesNotHaveLineManager);
					}
				}

				// Get Users Discount Managers
				map<string, User> discountManagersMap;
				if(IsDiscountManagerRequired(dmr, DISCOUNT_MANAGER_APPROVER_TYPE)) {
					discountManagersMap = GetDiscountManagersMap(quoteOwnerId);
					for(integer i = 1 ; i <= MAX_DISCOUNT_MANAGERS ; i++) {
						string discountManagerApproverType = DISCOUNT_MANAGER_APPROVER_TYPE + ' ' + i;
						if(IsDiscountManagerRequired(dmr, discountManagerApproverType) && !discountManagersMap.containsKey(discountManagerApproverType)) {
							throw new DiscountException(string.format(Label.UserDoesNotHaveDiscountManager, new list<string>{string.valueOf(i)}));
						}
					}
				}

				approversMap = new map<string, map<string, User>>();
				approversMap.put(PREAPPROVER_FIELD_NAME, new map<string, User>());
				approversMap.put(APPROVER_FIELD_NAME, new map<string, User>());
				approversMap.put(APPROVAL_TYPE, new map<string, User>());
				
				// Force Unanimous approval if regional or intra-regional approvers are included
				if(isQuoteRegional || isQuoteIntraRegional) {
					approversMap.get(APPROVAL_TYPE).put(APPROVAL_TYPE_UNANIMOUS, null);
				} else {
					approversMap.get(APPROVAL_TYPE).put(dmr.Approval_Type__c, null);
				}

				// Check pre-approver
				if(dmr.PreApprover_Type__c == DEFAULT_APPROVER_TYPE) {
					if(!string.IsBlank(dmr.Discount_Matrix__r.PreApprover_Type__c)) {
						if(dmr.Discount_Matrix__r.PreApprover_Type__c == LINE_MANAGER_APPROVER_TYPE) {
							// Default line manager
							AddApproverToMap(approversMap, PREAPPROVER_FIELD_NAME, lineManager);
						} else if(dmr.Discount_Matrix__r.PreApprover_Type__c.startsWith(DISCOUNT_MANAGER_APPROVER_TYPE)) {
							// Discount Manager						
							AddApproverToMap(approversMap, PREAPPROVER_FIELD_NAME, discountManagersMap.get(dmr.Discount_Matrix__r.PreApprover_Type__c));
						} else {
							AddApproverToMap(approversMap, PREAPPROVER_FIELD_NAME, dmr.Discount_Matrix__r.PreApprover__r);
						}
					}
				} else if(dmr.PreApprover_Type__c == USER_APPROVER_TYPE) {
					AddApproverToMap(approversMap, PREAPPROVER_FIELD_NAME, dmr.PreApprover__r);
				} else if(dmr.PreApprover_Type__c == LINE_MANAGER_APPROVER_TYPE) {
					AddApproverToMap(approversMap, PREAPPROVER_FIELD_NAME, lineManager);					
				} else if(dmr.PreApprover_Type__c.startsWith(DISCOUNT_MANAGER_APPROVER_TYPE)) {
					AddApproverToMap(approversMap, PREAPPROVER_FIELD_NAME, discountManagersMap.get(dmr.PreApprover_Type__c));
				}

				// Add Approvers
				for(integer i = 1; i < MAX_APPROVERS; i++) {
					User approver = GetApprover(dmr, dr, lineManager, discountManagersMap, i);
					if(approver != null) {
						AddApproverToMap(approversMap, APPROVER_FIELD_NAME, approver);
					}	
				}

				if(isQuoteRegional) {
					if(dmr.Regional_Approver_Type__c == DEFAULT_APPROVER_TYPE) {
						AddApproverToMap(approversMap, APPROVER_FIELD_NAME, dr.Regional_Approver__r);
					} else if(dmr.Regional_Approver_Type__c == USER_APPROVER_TYPE) {
						AddApproverToMap(approversMap, APPROVER_FIELD_NAME, dmr.Regional_Approver__r);
					}
				} else if(isQuoteIntraRegional) {
					if(dmr.IntraRegional_Approver_Type__c == DEFAULT_APPROVER_TYPE) {
						AddApproverToMap(approversMap, APPROVER_FIELD_NAME, dr.IntraRegional_Approver__r);
					} else if(dmr.IntraRegional_Approver_Type__c == USER_APPROVER_TYPE) {
						AddApproverToMap(approversMap, APPROVER_FIELD_NAME, dmr.IntraRegional_Approver__r);
					}
				}

				if(approversMap.get(APPROVER_FIELD_NAME).isEmpty() && !approversMap.get(PREAPPROVER_FIELD_NAME).isEmpty()) { 
					approversMap.get(PREAPPROVER_FIELD_NAME).Clear();
				}				
			}
		}
		return approversMap;
	}

	private static Discount_Matrix_Record__c GetDiscountMatrixRecord(Id discountMatrixId, decimal quoteDiscount, decimal convertedValue) {
		/* 
			Get Discount Matrix Record
		*/
		Discount_Matrix_Record__c dmr;
		try {		
			dmr = 
				[SELECT Name, CurrencyIsoCode,
					Minimum_Discount__c, Maximum_Discount__c,
					Minimum_Value__c, Maximum_Value__c,
					Discount_Matrix__r.PreApprover_Type__c, Discount_Matrix__r.PreApprover__c, Discount_Matrix__r.PreApprover__r.Id, Discount_Matrix__r.PreApprover__r.Name,
					PreApprover__c, PreApprover__r.Id, PreApprover__r.Name,
					PreApprover_Type__c,
					Approver_1__c, Approver_1__r.Id, Approver_1__r.Name, Approver_1_Type__c,
					Approver_2__c, Approver_2__r.Id, Approver_2__r.Name, Approver_2_Type__c,
					Approver_3__c, Approver_3__r.Id, Approver_3__r.Name, Approver_3_Type__c,
					Approver_4__c, Approver_4__r.Id, Approver_4__r.Name, Approver_4_Type__c,
					Regional_Approver__c, Regional_Approver__r.Id,  Regional_Approver__r.Name,
					Regional_Approver_Type__c,
					IntraRegional_Approver__c, IntraRegional_Approver__r.Id, IntraRegional_Approver__r.Name,
					IntraRegional_Approver_Type__c,
					Approval_Type__c
				FROM Discount_Matrix_Record__c
				WHERE Discount_Matrix__c = :discountMatrixId AND
					Minimum_Discount__c <= :quoteDiscount  AND (Maximum_Discount__c > :quoteDiscount OR Maximum_Discount__c=null) AND
					Minimum_Value__c    <= :convertedValue AND (Maximum_Value__c    > :convertedValue OR Maximum_Value__c=null)];

		} catch (Exception e) {
			string errorMsg;

			// Error if no rows returned
			if(e.getMessage().contains('List has no rows')) {
				errorMsg = string.format(Label.FailedToFindDiscountMatrixRecord, new list<string>{string.valueOf(discountMatrixId), string.valueOf(quoteDiscount), string.valueOf(convertedValue)});

			// Error if multiple rows are returned
			} else if (e.getMessage().contains('List has more than 1 row')) {
				errorMsg = string.format(Label.MultipleDiscountMatrixRecordsFound, new list<string>{string.valueOf(discountMatrixId), string.valueOf(quoteDiscount), string.valueOf(convertedValue)});				

			// re-throw other errors
			} else {
				throw e;
			}

			throw new DiscountException(errorMsg);
		}
		return dmr;
	}	

	private static void AddApproverToMap(map<string, map<string, User>> approversMap, string approverType, User approver) {
		/* Add Approver to Map */
		if(approver != null) {
			approversMap.get(approverType).put(approverType + '_' + string.valueOf(approversMap.get(approverType).size()+1), approver);
		}		
	}

	private static User GetApprover(Discount_Matrix_Record__c dmr, Discount_Region__c dr, User lineManager, map<string, User> discountManagersMap, integer approverNo) {
		/*
			Get Approver
		*/
		// Get approver type
		string approverType = (string)dmr.get('Approver_' + string.valueOf(approverNo) + '_Type__c');

		User approver;
		if(!string.isBlank(approverType)) {
			// LINE MANAGER
			if(approverType == LINE_MANAGER_APPROVER_TYPE) {
				approver = lineManager;

			// DISCOUNT MANAGER
			} else if(approverType.startsWith(DISCOUNT_MANAGER_APPROVER_TYPE)) {
				approver = discountManagersMap.get(approverType);
	
			// USER APPROVER
			} else if(approverType == USER_APPROVER_TYPE) {
				approver = (User)dmr.getSObject('Approver_' + string.valueOf(approverNo) + '__r');
	
			// COUNTRY APPROVER
			} else if(approverType.startsWith(COUNTRY_APPROVER_TYPE)) {
				approver = (User)dr.getSObject('Country_Approver_' + string.valueOf(approverNo) + '__r');
			}
		}
		return approver;
	}
	
	public static boolean IsQuoteIntraRegional(Id opportunityId) {
		/* Is Quote Intra Regional */

		list<OpportunitySite__c> siteList = bg_SiteUtils.GetOpportunitySites(opportunityId, bg_SiteUtils.RECORD_TYPE_NAME_NAMED);
		set<string> countries = bg_SiteUtils.GetOpportunitySiteCountries(siteList);

		return (countries.size() > 1);
	}
	
	public static boolean IsQuoteRegional(Id opportunityId) {
		/* Does quote contain sites from multiple regions? */

		list<OpportunitySite__c> siteList = bg_SiteUtils.GetOpportunitySites(opportunityId, bg_SiteUtils.RECORD_TYPE_NAME_NAMED);
		set<string> countries = bg_SiteUtils.GetOpportunitySiteCountries(siteList);

		// Get regions for countries
  		if(countries != null && !countries.isEmpty()) {
			string query = 'SELECT Region__c FROM Discount_Region__c WHERE ';
   			query += 'Country_Code__c IN :countries ';
			query += 'Group by Region__c';
  			return ((database.query(query)).size() > 1);
  		} else {  		
			return false;
  		}
	}

	public static void PopulateQuoteDiscountApprovers(Quote__c quote, map<string, map<string, User>> approversMap) {
		/* Populate discount approvers on the quote */
		PopulateQuoteDiscountApprovers(quote, approversMap, false);
	}
	
	public static void PopulateQuoteDiscountApprovers(Quote__c quote, map<string, map<string, User>> approversMap, boolean skipPreApprover) {
		/*
			Populate discount approvers on the quote
		*/

		// Set the discount Pre-approver
		if(approversMap.get(PREAPPROVER_FIELD_NAME).size() > 0 && !skipPreApprover) {
			// Currently only 1 pre-approver
			quote.Discount_PreApprover_1__c = approversMap.get(PREAPPROVER_FIELD_NAME).get(PREAPPROVER_FIELD_NAME + '_1').Id;
		} else {
			quote.Discount_PreApprover_1__c = null;
		}

		// Set the approval type
		quote.Discount_Approval_Type__c = new list<string>(approversMap.get(bg_DiscountUtils.APPROVAL_TYPE).keySet())[0];

		// Set the discount approvers
		for(integer i = 1; i <= MAX_APPROVERS; i++) {
			User u = approversMap.get(APPROVER_FIELD_NAME).get(APPROVER_FIELD_NAME + '_' + string.valueOf(i));
			if(u == null) {
				// Get last approver
				u = approversMap.get(APPROVER_FIELD_NAME).get(APPROVER_FIELD_NAME + '_' + string.valueOf(approversMap.get(APPROVER_FIELD_NAME).size()));
			}	
			quote.put('Discount_' + APPROVER_FIELD_NAME + '_' + string.valueOf(i) + '__c', u.Id);
		}
	}

	public static string SetDiscountStatus(string currentStatus, map<string, map<string, User>> approversMap) {
		/*
			Set Discount Status
		*/
		QuoteSetting__c qs = bg_CustomSettingsUtils.GetQuoteSettings();
		string newStatus = currentStatus;
		
		if(approversMap.get(APPROVER_FIELD_NAME).size() == 0) {
			if(bg_QuoteUtils.OverrideQuoteStatus(currentStatus)) { newStatus = qs.StatusNA__c; }
		} else {
			if(bg_QuoteUtils.OverrideQuoteStatus(currentStatus)) { newStatus = qs.StatusDraft__c; }
		}

		return newStatus;
	}

	public static User GetLineManager(Id userId) {
		/*
			Return users line manager
		*/
		// Get users manager / delegated approver
		User u = [SELECT ManagerId, Manager.Name, Manager.Id FROM User WHERE Id = :userId];
		User lineManager;
		if(!string.isBlank(u.ManagerId)) {
			lineManager =  u.Manager;
		}
		return lineManager;
	}

	public static map<string, User> GetDiscountManagersMap(Id userId) {
		/*
			Return users line manager
		*/
		// Get users manager / delegated approver
		User u = [SELECT Discount_Manager_1__c, Discount_Manager_1__r.Name, Discount_Manager_1__r.Id,
		 				 Discount_Manager_2__c, Discount_Manager_2__r.Name, Discount_Manager_2__r.Id 
				FROM User WHERE Id = :userId];
		
		map<string, User> discountManagersMap = new map<string, User>();

		for(integer i = 1 ; i <= MAX_DISCOUNT_MANAGERS ; i++) {
			string discountManagerApproverType = DISCOUNT_MANAGER_APPROVER_TYPE + ' ' + i;
			string discountManagerApproverTypeAPI = discountManagerApproverType.replace(' ', '_') + '__r';

			if(u.getSobject(discountManagerApproverTypeAPI) != null) {
				discountManagersMap.put(discountManagerApproverType, (User)u.getSobject(discountManagerApproverTypeAPI));
			}
		}

		return discountManagersMap;
	}
		
	private static boolean IsLineManagerRequired(Discount_Matrix_Record__c dmr) {
		/* Check if line manager is required */
		return (dmr.PreApprover_Type__c == DEFAULT_APPROVER_TYPE && dmr.Discount_Matrix__r.PreApprover_Type__c == LINE_MANAGER_APPROVER_TYPE) ||
				(dmr.PreApprover_Type__c == LINE_MANAGER_APPROVER_TYPE) ||
				(dmr.Approver_1_Type__c == LINE_MANAGER_APPROVER_TYPE || dmr.Approver_2_Type__c == LINE_MANAGER_APPROVER_TYPE ||
				 dmr.Approver_3_Type__c == LINE_MANAGER_APPROVER_TYPE || dmr.Approver_4_Type__c == LINE_MANAGER_APPROVER_TYPE);
	}

	private static boolean IsDiscountManagerRequired(Discount_Matrix_Record__c dmr, string discountManagerApproverType) {
		/* Check if discount manager is required */
		return (dmr.PreApprover_Type__c == DEFAULT_APPROVER_TYPE &&
				dmr.Discount_Matrix__r.PreApprover_Type__c != null && dmr.Discount_Matrix__r.PreApprover_Type__c.startsWith(discountManagerApproverType)) ||				
				(dmr.PreApprover_Type__c != null && dmr.PreApprover_Type__c.startsWith(discountManagerApproverType)) ||
				((dmr.Approver_1_Type__c != null && dmr.Approver_1_Type__c.startsWith(discountManagerApproverType)) || 
				 (dmr.Approver_2_Type__c != null && dmr.Approver_2_Type__c.startsWith(discountManagerApproverType)) ||
				(dmr.Approver_3_Type__c != null && dmr.Approver_3_Type__c.startsWith(discountManagerApproverType)) || 
				(dmr.Approver_4_Type__c != null && dmr.Approver_4_Type__c.startsWith(discountManagerApproverType)));
	}

	private static Discount_Region__c GetDiscountRegion(string countryCode) {
		/*
			Get Discount Region
		*/

		Discount_Region__c dr;
		try {
			dr = [SELECT Region__c, Country_Code__c,
					Regional_Approver__c, Regional_Approver__r.Id,  Regional_Approver__r.Name,
					IntraRegional_Approver__c, IntraRegional_Approver__r.Id, IntraRegional_Approver__r.Name,
					Country_Approver_1__c, Country_Approver_1__r.Id, Country_Approver_1__r.Name,
					Country_Approver_2__c, Country_Approver_2__r.Id, Country_Approver_2__r.Name,
					Country_Approver_3__c, Country_Approver_3__r.Id, Country_Approver_3__r.Name,
					Country_Approver_4__c, Country_Approver_4__r.Id, Country_Approver_4__r.Name
				FROM Discount_Region__c 
				WHERE Country_Code__c = :countryCode];
		} catch (Exception ex) {}
		return dr;
	}

	public static boolean RequiresPreApproval(map<string, map<string, User>> approversMap) {
		/* Check if pre approval is required */
		return (approversMap.get(PREAPPROVER_FIELD_NAME).size() > 0);
	}

	public static void SkipPreApprover(map<string, map<string, User>> approversMap) {
		/* Remove PreApprovers */
		approversMap.get(PREAPPROVER_FIELD_NAME).clear();
	}

	public static boolean SkipRegionalApproval(Id quoteId) {
		/* 
			Some products do not require regional approval
		*/
		integer prodCount = 0;
		integer skipCount = 0;
		for(Quote_Product__c qp : [SELECT Id, Product_Name__r.Skip_Regional_Approval__c FROM Quote_Product__c 
									WHERE Quote_Ref__c =:quoteId 
										AND Selected__c = True
										AND Product_Name__r.Product_Type__c = 'Main']) {
			prodCount++;
			if(qp.Product_Name__r.Skip_Regional_Approval__c) { skipCount++; }
		}
		
		return (prodCount == skipCount);
	}	
}