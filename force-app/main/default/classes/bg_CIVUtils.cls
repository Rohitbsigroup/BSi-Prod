/********************************************************************
 * bg_CIVUtils
 *
 * Base class for all CIVs controller
 * 
 * 
 * Author: Alexis Lignereux
 * Created: 11-09-2014
 * Changes: 
 *          30-07-15 RJ Uncommented line set company name property for account
 *          25-08-15 RJ CIV Score matches is not case insensitive
 ********************************************************************/
public with sharing class bg_CIVUtils {

    /** Standard Icon location **/
    public final static String LEAD_ICON                       = '/img/icon/leads16.png';
    public final static String ACCOUNT_ICON                    = '/img/icon/accounts16.png';
    public final static String CONTACT_ICON                    = '/img/icon/contacts16.png';
    public final static String OPPORTUNITY_ICON                = '/img/icon/opportunities16.png';
    public final static String CAMPAIGN_ICON                   = '/img/icon/campaigns16.png';
    public final static String TASK_ICON                       = '/img/icon/tasks16.png';
    public final static String EVENT_ICON                      = '/img/icon/home16.png';

    public final static String LEAD_OBJECT_TYPE_NAME            = 'Lead';
    public final static String ACCOUNT_OBJECT_TYPE_NAME         = 'Account';
    public final static String CONTACT_OBJECT_TYPE_NAME         = 'Contact';
    public final static String OPPORTUNITY_OBJECT_TYPE_NAME     = 'Opportunity';
    public final static String TASK_OBJECT_TYPE_NAME            = 'Task';
    public final static String EVENT_OBJECT_TYPE_NAME           = 'Event';
    public final static String CAMPAIGN_OBJECT_TYPE_NAME        = 'Campaign';
	public final static String CAMPAIGN_MEMBER_OBJECT_TYPE_NAME = 'CampaignMember';

    //public final static string RELATIONSHIP_TYPE_DIRECT			= 'Direct'; 
    //public final static string RELATIONSHIP_TYPE_INDIRECT		= 'Indirect';

    // should these be in custom label????
    public final static String MERGE_ACTION                    = 'Merge';
    public final static String LINK_ACTION                     = 'Link';
    public final static String LINKED_ACTION                   = 'Linked';
    public final static String UNLINK_ACTION                   = 'Unlink';

	public final static String SYNC_ACTION                     = 'Sync';
	public final static String UNSYNC_ACTION                   = 'Unsync';
	
    public static Integer MAX_ROWS                             = 5;
    public static String LEAD_MERGE_WIZARD_URL                 = '/lead/leadmergewizard.jsp?';
    public static String MERGE_WIZARD_NEXT_PARAM			   = '&goNext=';
	public static final String MERGE_WIZARD_URL_ID_PARAM 	   = '&cid=';
	public static final String MERGE_WIZARD_RETURL_PARAM 	   = '&retURL=';

    public static List<String> characters = new List<String>{'\\','?','&','|','!','{','}','[',']','^','~','*',':','\"','\'','+','-'};

	public static string SORTCOL_OBJECTTYPE 		= 'objecttype';
	public static string SORTCOL_LASTMODIFIEDDATE 	= 'lastmodifieddate';
	public static string SORTCOL_CREATEDDATE 		= 'createddate';
	public static string SORTCOL_STATUS 			= 'status';
	public static string SORTCOL_OWNER 				= 'owner';
	public static string SORTCOL_CLOSEDATE 			= 'closedate';
	public static string SORTCOL_NAME 				= 'name';
	public static string SORTCOL_COMPANY 			= 'company';	
	public static string SORTCOL_EMAIL	 			= 'email';
	public static string SORTCOL_PHONE 				= 'phone';
	public static string SORTCOL_POSTCODE 			= 'postcode';
	public static string SORTCOL_SCORE	 			= 'score';
	public static string SORTCOL_SUBJECT	 		= 'subject';
	public static string SORTCOL_TYPE	 			= 'type';
	public static string SORTCOL_ASSIGNEDTO	 		= 'assignedto';	
	public static string SORTCOL_DUEDATE	 		= 'duedate';
	public static string SORTCOL_ENDDATE            = 'enddate';
	public static string SORTCOL_WHO				= 'who';
	public static string SORTCOL_WHAT	 			= 'what';
	public static string SORTCOL_CAMPAINGNSTARTDATE = 'campaignstartdate';
	public static string SORTCOL_CAMPAINGNENDDATE   = 'campaignenddate';
	public static string SORTCOL_HASRESPONDED	    = 'hasresponded';
	
    public virtual class civWrapper implements comparable {
        /*
            Shared CIV Base Wrapper
        */
        public SObject obj {get; set;}
        public string sourceObjectType {get; set;}
        public String recordId {get; set;}
        public String objectType {get; set;}
        public String image {get; set;}
        public string name {get; set;}
        public string company {get; set;}
        public string AccountId {get; set;} // Link to Account/Lead Id        
        public string phone {get; set;}
        public string email {get; set;}
        public string ContactId {get; set;}  // Link to Contact/Lead Id                
        public string postcode {get; set;}
        public string ownerName {get; set;}
        public string ownerId {get; set;}
        public string status {get; set;}
        public Date closeDate {get; set;}

        public String createdById {get; set;}
        public String createdByName {get; set;}
        public String createdDate {get; set;}

        public String lastModifiedById {get; set;}
        public String lastModifiedByName {get; set;}
        public String lastModifiedDate {get; set;}

		public string orderBy {get; set;}
		public boolean orderAsc {get; set;}

		public civWrapper() {
			orderBy = SORTCOL_LASTMODIFIEDDATE;
			orderAsc = false;
		}

		// Used for sorting
        public virtual integer compareTo(Object compareTo) {
            civWrapper compareToWrapper = (civWrapper)compareTo;
			// Last Modified Date
			if(orderBy == SORTCOL_LASTMODIFIEDDATE) {           
            	return bg_SortUtils.getSortResult(lastModifiedDate, compareToWrapper.lastModifiedDate, orderAsc);
			// Created Date
			} else if(orderBy == SORTCOL_CREATEDDATE) {           
            	return bg_SortUtils.getSortResult(createdDate, compareToWrapper.createdDate, orderAsc);
			// Object Type
			} else if(orderBy == SORTCOL_OBJECTTYPE) {
				return bg_SortUtils.getSortResult(objectType, compareToWrapper.objectType, orderAsc);
			// Owner
			} else if(orderBy == SORTCOL_OWNER) {
				return bg_SortUtils.getSortResult(ownerName, compareToWrapper.ownerName, orderAsc);
			// Object Type
			} else if(orderBy == SORTCOL_STATUS) {
				return bg_SortUtils.getSortResult(status, compareToWrapper.status, orderAsc);
			} else if(orderBy == SORTCOL_CLOSEDATE) {
				return bg_SortUtils.getSortResult(closedate, compareToWrapper.closedate, orderAsc);
				
			} else if(orderBy == SORTCOL_NAME) {
				return bg_SortUtils.getSortResult(name, compareToWrapper.name, orderAsc);

			} else if(orderBy == SORTCOL_COMPANY) {
				return bg_SortUtils.getSortResult(company, compareToWrapper.company, orderAsc);

			} else if(orderBy == SORTCOL_EMAIL) {
				return bg_SortUtils.getSortResult(email, compareToWrapper.email, orderAsc);

			} else if(orderBy == SORTCOL_PHONE) {
				return bg_SortUtils.getSortResult(phone, compareToWrapper.phone, orderAsc);

			} else if(orderBy == SORTCOL_POSTCODE) {
				return bg_SortUtils.getSortResult(postcode, compareToWrapper.postcode, orderAsc);
			}
			return 0;
        }
    }

    public class SearchResultWrapper extends civWrapper {
        /*
            Search Results Wrapper - used on CIV Matches tab
        */
        public string action {get; set;}
        public string linkAction {get; set;}
		public integer score {get; set;}
		
        public override integer compareTo(Object compareTo) {
            SearchResultWrapper compareToWrapper = (SearchResultWrapper)compareTo;
			// Score
			if(orderBy == SORTCOL_SCORE) {
				return bg_SortUtils.getSortResult(score, compareToWrapper.score, orderAsc);
			} else {
				return super.compareTo(compareTo);
			}
        }		
    }

    public class LinkedWrapper extends civWrapper {
        /*
            Linked Wrapper - used on CIV Linked tab
        */
        //public string action {get; set;}
        //public string relationshipType {get; set;}
        public set<Id> Ids {get; set;}
        
		public string accountId {get; set;}
		public string contactId {get; set;}

		public LinkedWrapper () {
			Ids = new set<Id>();
		}

        public string Action {
            get {
                // from a lead, allow unlink of account & contact
                if(Ids.contains(recordId)) {
                	return UNSYNC_ACTION;
                } else {
                	return UNLINK_ACTION;
                }
            }
        }        
    }

    public class CampaignMemberWrapper extends civWrapper {
        /*
            Campaign Member Wrapper - used on CIV Linked tab
        */
		public date campaignStartDate {get; set;}
        public date campaignEndDate {get; set;}
        public boolean hasResponded {get; set;}
        public string type {get; set;}

        public string whoId {get; set;}
        public string whoName {get; set;}

        public override integer compareTo(Object compareTo) {
            CampaignMemberWrapper compareToWrapper = (CampaignMemberWrapper)compareTo;
			// Campaign Start Date
			if(orderBy == SORTCOL_CAMPAINGNSTARTDATE) {
				return bg_SortUtils.getSortResult(campaignStartDate, compareToWrapper.campaignStartDate, orderAsc);	   
			// Campaign End Date
			} else if(orderBy == SORTCOL_CAMPAINGNSTARTDATE) {
				return bg_SortUtils.getSortResult(campaignEndDate, compareToWrapper.campaignEndDate, orderAsc);	  	
			// hasResponded
			} else if(orderBy == SORTCOL_HASRESPONDED) {
				return bg_SortUtils.getSortResult(hasResponded, compareToWrapper.hasResponded, orderAsc);	 							         
			// type
			} else if(orderBy == SORTCOL_TYPE) {
				return bg_SortUtils.getSortResult(type, compareToWrapper.type, orderAsc);	
			// Who
			} else if(orderBy == SORTCOL_WHO) {
				return bg_SortUtils.getSortResult(whoName, compareToWrapper.whoName, orderAsc);	
								
			} else {
				return super.compareTo(compareTo);
			}
        }        
    }

	public class ActivityWrapper extends civWrapper {
        /*
            Activity Wrapper - used on CIV Linked tab
        */				
		public string subject {get; set;}
		public string type {get; set;}
		public string assignedTo {get; set;}
		public string assignedToId {get; set;}		
		public dateTime dueDateTime {get; set;}
		public dateTime endDateTime {get; set;}

		public string whoId {get; set;}
		public string whoName {get; set;}
		public string whatId {get; set;}
		public string whatName {get; set;}

        public override integer compareTo(Object compareTo) {
            ActivityWrapper compareToWrapper = (ActivityWrapper)compareTo;
			// Subject
			if(orderBy == SORTCOL_SUBJECT) {
				return bg_SortUtils.getSortResult(subject, compareToWrapper.subject, orderAsc);
			} else if(orderBy == SORTCOL_TYPE) {
				return bg_SortUtils.getSortResult(type, compareToWrapper.type, orderAsc);
			} else if(orderBy == SORTCOL_ASSIGNEDTO) {
				return bg_SortUtils.getSortResult(assignedTo, compareToWrapper.assignedTo, orderAsc);
			} else if(orderBy == SORTCOL_DUEDATE) {
				return bg_SortUtils.getSortResult(dueDateTime, compareToWrapper.dueDateTime, orderAsc);
			} else if(orderBy == SORTCOL_ENDDATE) {
				return bg_SortUtils.getSortResult(endDateTime, compareToWrapper.endDateTime, orderAsc);
			} else if(orderBy == SORTCOL_WHO) {
				return bg_SortUtils.getSortResult(whoName, compareToWrapper.whoName, orderAsc);	
			} else if(orderBy == SORTCOL_WHAT) {
				return bg_SortUtils.getSortResult(whatName, compareToWrapper.whatName, orderAsc);									
			} else {
				return super.compareTo(compareTo);
			}
        }
	}
	
    private static string getObjectValue(SObject obj, String field) {
        /*
            Return field value from sObject
        */
        if (obj.get(field) != null) {
            return string.valueOf(obj.get(field));
        }
        return null;
    }

    public static void PopulateCIVWrapper(civWrapper civW, SObject obj, string sourceObjectType, string orderBy, boolean orderAsc) {
        /*
            Populate CIV base class wrappers
        */
        civW.obj = obj;
        civW.objectType = obj.getSObjectType().getDescribe().getName();
        civW.recordId = getObjectValue(obj, 'Id');
        civW.createdById = getObjectValue(obj, 'CreatedById');
        civW.createdDate = getObjectValue(obj, 'CreatedDate');
        civW.lastModifiedById = getObjectValue(obj, 'LastModifiedById');
        civW.lastModifiedDate = getObjectValue(obj, 'LastModifiedDate');
        civW.sourceObjectType = sourceObjectType;
		civW.orderBy = orderBy;
		civW.orderAsc = orderAsc;

        // LEAD
        if (civW.objectType == LEAD_OBJECT_TYPE_NAME) {
            civW.image = LEAD_ICON;
            Lead lead = (Lead)obj;
        	civW.name = lead.Name;
        	civW.company = lead.company;            
            civW.createdByName = lead.CreatedBy.Name;
            civW.lastModifiedByName = lead.LastModifiedBy.Name;
            civW.phone = lead.Phone;
            civW.email = lead.Email;
            civW.postcode = lead.PostalCode;
            civW.ownerName = lead.Owner.FirstName + ' ' + lead.Owner.LastName;
            civW.status = lead.Status;
            civW.ownerId = lead.OwnerId;
            
            // Lead Account Id
            if(lead.Existing_Customer_Account__c != null) {
				civW.AccountId = lead.Existing_Customer_Account__c;
            } 

			// Lead Contact Id
            if(lead.Contact__c != null) {
				civW.ContactId = lead.Contact__c;
            } 

        // ACCOUNT
        } else if (civW.objectType == ACCOUNT_OBJECT_TYPE_NAME) {
            civW.image = ACCOUNT_ICON;
            Account acc = (Account)obj;
            civW.name = acc.Name;
            civW.company = acc.Name;     
            civW.createdByName = acc.CreatedBy.Name;
            civW.lastModifiedByName = acc.LastModifiedBy.Name;  
            civW.phone = acc.Phone;
            civW.postcode = acc.BillingPostalCode;
            civW.ownerName = acc.Owner.FirstName + ' ' + acc.Owner.LastName;
            civW.ownerId = acc.OwnerId;

        // CONTACT
        } else if (civW.objectType == CONTACT_OBJECT_TYPE_NAME) {
            civW.image = CONTACT_ICON;
            Contact con = (Contact)obj;
            civW.name = con.Name;  
            civW.createdByName = con.CreatedBy.Name;
            civW.lastModifiedByName = con.LastModifiedBy.Name;
            civW.phone = con.Phone;
            civW.email = con.Email;
            civW.postcode = con.MailingPostalCode;
			civW.company = con.Account.Name;
			civW.AccountId = con.AccountId;
            civW.ownerName = con.Owner.FirstName + ' ' + con.Owner.LastName;
            civW.ownerId = con.OwnerId;

        // OPPORTUNITY
        } else if (civW.objectType == OPPORTUNITY_OBJECT_TYPE_NAME) {
            civW.image = OPPORTUNITY_ICON;
            Opportunity opp = (Opportunity)obj;
            civW.name = opp.Name;  
			civW.company = opp.Account.Name;
			civW.AccountId = opp.AccountId;
            civW.createdByName = opp.CreatedBy.Name;
            civW.lastModifiedByName = opp.LastModifiedBy.Name;
            civW.ownerName = opp.Owner.FirstName + ' ' + opp.Owner.LastName;
            civW.status = opp.StageName;
            civW.closeDate = opp.CloseDate;
            civW.ownerId = opp.OwnerId;
            civW.phone = opp.PrimaryContact__r.Phone;
            civW.email = opp.PrimaryContact__r.Email;
            civW.ContactId = opp.PrimaryContact__c;
            civW.postcode = opp.Account.BillingPostalCode;
            			
        // CAMPAIGN MEMBER
        } else if (civW.objectType == CAMPAIGN_MEMBER_OBJECT_TYPE_NAME) {
            civW.image = CAMPAIGN_ICON;
            CampaignMember cam = (CampaignMember)obj;
            civW.createdByName = cam.CreatedBy.Name;
            civW.lastModifiedByName = cam.LastModifiedBy.Name;
	        civW.Name = cam.Campaign.Name;
        	civW.status = cam.status;
        
        // TASK
        } else if (civW.objectType == TASK_OBJECT_TYPE_NAME) {
            civW.image = TASK_ICON;
            Task t = (Task)obj;
            civW.createdByName = t.CreatedBy.Name;
            civW.lastModifiedByName = t.LastModifiedBy.Name;
			civW.status = t.status;
        
        // Event
        } else if (civW.objectType == EVENT_OBJECT_TYPE_NAME) {
            civW.image = EVENT_ICON;
            Event e = (Event)obj;
            civW.createdByName = e.CreatedBy.Name;
            civW.lastModifiedByName = e.LastModifiedBy.Name;
        }        
    }

    public static LinkedWrapper CreateLinkedWrapper(SObject obj, string sourceObjectType, set<Id> Ids, string orderby, boolean orderAsc) {
        /*
            Create Linked Wrapper
        */
        LinkedWrapper civLW = new LinkedWrapper();
        
        // Populate base class wrapper properties
        PopulateCIVWrapper(civLW, obj, sourceObjectType, orderby, orderAsc);
        
        civLW.Ids.addAll(Ids);
        
        return civLW;
    }

    public static CampaignMemberWrapper CreateCampaignMemberWrapper(CampaignMember obj, string sourceObjectType) {
        /*
            Create Campaign Member Wrapper
        */
        CampaignMemberWrapper civCMW = new CampaignMemberWrapper();

        // Populate base class wrapper properties
        PopulateCIVWrapper(civCMW, obj, sourceObjectType, SORTCOL_LASTMODIFIEDDATE, true);

        civCMW.campaignStartDate = obj.Campaign.StartDate;
        civCMW.campaignEndDate = obj.Campaign.EndDate;
        civCMW.hasResponded = obj.hasResponded;
        civCMW.Type = obj.Campaign.Type;

        if(!bg_StringUtils.IsBlank(obj.LeadId)) {
            civCMW.whoId = obj.LeadId;
            civCMW.whoName = obj.Lead.Name; 
        }

        if(!bg_StringUtils.IsBlank(obj.ContactId)) {
            civCMW.whoId = obj.ContactId;
            civCMW.whoName = obj.Contact.Name; 
        }

        return civCMW;
    }

	public static final string SEARCH_TERM_NAME = 'name';
	public static final string SEARCH_TERM_COMPANY = 'company';
	public static final string SEARCH_TERM_EMAIL = 'email';
	public static final string SEARCH_TERM_PHONE = 'phone';
	public static final string SEARCH_TERM_POSTCODE = 'postcode';
	
	public static void PopulateSearchResultScore(SearchResultWrapper srw, map<string, string> valueMap) {
		/*
			Calculate Search result score
		*/
		integer score = 0;
		for(string key : valueMap.keySet()) {
			if(!bg_StringUtils.IsBlank(valueMap.get(key))) {
				if(key == SEARCH_TERM_NAME) {
					if(!bg_StringUtils.IsBlank(srw.name)) {
						score += (srw.name.containsIgnoreCase(valueMap.get(key))?1:0);
					}
				} else if(key == SEARCH_TERM_COMPANY) {
					if(!bg_StringUtils.IsBlank(srw.company)) {
						score += (srw.company.containsIgnoreCase(valueMap.get(key))?1:0);
					}
				} else if(key == SEARCH_TERM_EMAIL) {
					if(!bg_StringUtils.IsBlank(srw.email)) {
						score += (srw.email.containsIgnoreCase(valueMap.get(key))?1:0);
					}
				} else if(key == SEARCH_TERM_PHONE) {
					if(!bg_StringUtils.IsBlank(srw.phone)) {
						score += (srw.phone.containsIgnoreCase(valueMap.get(key))?1:0);
					}
				} else if(key == SEARCH_TERM_POSTCODE) {
					if(!bg_StringUtils.IsBlank(srw.postcode)) {
						score += (srw.postcode.containsIgnoreCase(valueMap.get(key))?1:0);
					}
				}
			}
		}
		srw.score = score;
	}
	
	public static list<SearchResultWrapper> CreateSearchResultWrappers(list<list<sObject>> objs, map<string, string> valueMap, string sourceObjectType, string recordAccountId, string recordContactId,  map<Id, CIV_Link__c> linkMap, string orderBy, boolean orderAsc) {
		/*
			Create search results wrappers
		*/
        list<SearchResultWrapper> civDWs = new list<SearchResultWrapper>();
        for(list<sObject> objType : objs) {
            for(sObject obj : objType) {
            	SearchResultWrapper srw = CreateSearchResultWrapper(obj, sourceObjectType, recordAccountId, recordContactId, orderBy, orderAsc);

				if(srw.action != LINKED_ACTION) {
					if(!linkMap.containsKey(srw.recordId)) {
	            		srw.linkAction = LINK_ACTION;
					} else {
						srw.linkAction = UNLINK_ACTION;
					}            		 

					// Populate search results score
					PopulateSearchResultScore(srw, valueMap);

					// Show only items with a scoe
					if(srw.score > 0) {
                		civDWs.add(srw);
					}
				}
            }
        }
        return civDWs;
    }
	
	
    public static SearchResultWrapper CreateSearchResultWrapper(sObject obj, string sourceObjectType, string recordAccountId, string recordContactId, string orderBy, boolean orderAsc) {
        /*
            Create Search Result Wrapper (Matches tab)
        */
        SearchResultWrapper civSR = new SearchResultWrapper();
        
        // Populate base class wrapper properties
        PopulateCIVWrapper(civSR, obj, sourceObjectType, orderBy, orderAsc);

        if (sourceObjectType == civSR.objectType) {
            civSR.action = MERGE_ACTION;
        } else {
            if (civSR.objectType == ACCOUNT_OBJECT_TYPE_NAME) {
                if (recordAccountId == civSR.recordId) {
                    civSR.action = LINKED_ACTION;
                } else {
                    civSR.action = SYNC_ACTION;
                }
            } else if (civSR.objectType == CONTACT_OBJECT_TYPE_NAME) {
                if (recordContactId == civSR.recordId) {
                    civSR.action = LINKED_ACTION;
                } else {
                    civSR.action = SYNC_ACTION;
                }
            } else if (civSR.objectType == LEAD_OBJECT_TYPE_NAME) {
                civSR.action = LINK_ACTION;
            } else {
                civSR.action = null;
            }
        }

        return civSR;
    }

    public static boolean UnlinkRecord(Id recordId, string objectType, string selectedrecordId, string selectedObjectType) {
        /*
            Remove link between Lead and Accounts or Contacts
        */
        boolean result = false;
        string leadId;
        if(objectType == LEAD_OBJECT_TYPE_NAME) {
            leadId = recordId;
        } else {
            leadId = selectedrecordId;
        }

        if(objectType == LEAD_OBJECT_TYPE_NAME) {
            // Remove link on lead to account
            Lead updlead = new Lead(Id = leadId);
            if(selectedObjectType == ACCOUNT_OBJECT_TYPE_NAME) {
                // Clear Account Link
                updlead.Existing_Customer_Account__c = null;
            } else if(selectedObjectType == CONTACT_OBJECT_TYPE_NAME) {
                // Clear Contact Link
                updlead.Contact__c = null;
            }
            update updlead;
            result = true;
        }
        return result;
    }

    public static list<Account> GetLinkedAccounts(string recordId, integer recordLimit, set<Id> accountIds) {
        /*
            Get Linked Accounts
        */
        list<Account> accounts = [SELECT Id, Name, Phone, BillingPostalCode, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedById, LastModifiedBy.Name, LastModifiedDate, Owner.FirstName, Owner.LastName, OwnerId
                                    FROM Account
                                    WHERE Id IN :accountIds
                                        AND Id != :recordId
                                    ORDER BY LastModifiedDate DESC
                                    LIMIT :recordLimit];
        return accounts;
    }

    public static list<Contact> GetLinkedContacts(string recordId, integer recordLimit, set<Id> contactIds) {
        /*
            Get Linked Contacts
        */
        list<Contact> contacts = [SELECT Id, Name, Account.Name, Email, Phone, MailingPostalCode, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedById, LastModifiedBy.Name, LastModifiedDate, Owner.FirstName, Owner.LastName, OwnerId,
        							AccountId
                                    FROM Contact
                                    WHERE Id IN :contactIds
                                        AND Id != :recordId
                                    ORDER BY LastModifiedDate DESC
                                    LIMIT :recordLimit];
        return contacts;
    }

    public static list<Lead> GetLinkedLeads(string recordId, integer recordLimit, Id accountId, Id contactId, set<Id> leadIds) {
        /*
            Get Linked Leads
        */
        list<Lead> leads = [SELECT Id, Name, Company, Email, Phone, PostalCode, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedById, LastModifiedBy.Name, LastModifiedDate, Owner.FirstName, Owner.LastName, Status, OwnerId,
        						Contact__c, Existing_Customer_Account__c
                            FROM Lead
                            WHERE Id IN : leadIds
                                AND Id != :recordId
                            ORDER BY LastModifiedDate DESC
                            LIMIT :recordLimit];
        return leads;
    }

    public static list<Opportunity> GetLinkedOpportunities(string recordId, integer recordLimit, Id accountId, Id contactId, set<Id> oppIds) {
        /*
            Get Linked Opportunities
        */
        list<Opportunity> opportunities = [SELECT Id, Name, Account.Name, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedById, LastModifiedBy.Name, LastModifiedDate, Owner.FirstName, Owner.LastName, StageName, CloseDate, OwnerId,
        									PrimaryContact__r.phone, PrimaryContact__r.email, Account.BillingPostalCode 
                                FROM Opportunity
                                WHERE Id IN: oppIds 
                                	AND Id != :recordId
                                ORDER BY LastModifiedDate DESC
                                LIMIT :recordLimit];
        return opportunities;
    }

    public static list<CampaignMember> GetCampaignMembers(integer recordLimit, integer recordOffset, set<Id> parentIds) {
        /*
            Get Campaign Members
        */
        list<CampaignMember> campaignMembers = [SELECT Id, Campaign.Name, status, Campaign.type,
                                    Campaign.StartDate, Campaign.EndDate, hasResponded,
                                    ContactId, Contact.Name, LeadId, Lead.Name, 
                                    createdById, createdBy.Name, createdDate,
                                    lastmodifiedbyId, lastmodifiedby.name, lastmodifieddate
                                FROM CampaignMember
                                WHERE LeadId IN :parentIds OR ContactId IN :parentIds
                                ORDER BY lastmodifieddate DESC
                                LIMIT :recordLimit
                                OFFSET :recordOffset];
        return campaignMembers;
    }

    public static list<Task> GetTasks(integer recordLimit, set<Id> parentIds, date startDate, date endDate) {
        /*
            Get Tasks
        */    	
		list<Task> tasks = [SELECT Id, subject, type, status, owner.name, ownerId, activitydate,
								createdById, createdBy.Name, createdDate,
								lastmodifiedbyId, lastmodifiedby.name, lastmodifieddate,
								whatId, what.name, whoId, who.name
							FROM Task 
							WHERE (WhoId IN :parentIds OR WhatId IN :parentIds)
								AND activityDate >= :startDate AND activityDate <= :endDate
							ORDER BY activityDate desc
							limit :recordLimit];
		return tasks;
	}

    public static list<Event> GetEvents(integer recordLimit, set<Id> parentIds, date startDate, date endDate) {
        /*
            Get Events
        */      	
		list<Event> events = [SELECT  Id, subject, type, owner.name, ownerId, activitydate,
									createdById, createdBy.Name, createdDate, startDateTime, endDateTime,
									lastmodifiedbyId, lastmodifiedby.name, lastmodifieddate,
									whatId, what.name, whoId, who.name 
								FROM Event
								WHERE (WhoId IN :parentIds OR WhatId IN :parentIds)
									AND activityDate >= :startDate AND activityDate <= :endDate
								ORDER BY activityDate desc 
								limit :recordLimit];
		return events;
	}
	public static ActivityWrapper CreateActivityWrapper(Task obj, string orderBy, boolean orderAsc) {
        /*
            Create Activity Wrapper from task
        */
		ActivityWrapper civAW = new ActivityWrapper();

        // Populate base class wrapper properties
        PopulateCIVWrapper(civAW, obj, TASK_OBJECT_TYPE_NAME, orderby, orderAsc);

		civAW.subject = obj.subject;
		civAW.type = obj.type;
		civAW.assignedTo = obj.owner.Name;
		civAW.assignedToId = obj.ownerId;		
		civAW.dueDateTime = obj.activityDate;

		civAW.whatId = obj.whatId;
		civAW.whatName = obj.what.name;
		civAW.whoId = obj.whoId;
		civAW.whoName = obj.who.name;

		return civAW;
	}

	public static ActivityWrapper CreateActivityWrapper(Event obj, string orderBy, boolean orderAsc) {
        /*
            Create Activity Wrapper from event
        */		
		ActivityWrapper civAW = new ActivityWrapper();

        // Populate base class wrapper properties
        PopulateCIVWrapper(civAW, obj, EVENT_OBJECT_TYPE_NAME, orderby, orderAsc);

		civAW.subject = obj.subject;
		civAW.type = obj.type;
		civAW.assignedTo = obj.owner.Name;
		civAW.assignedToId = obj.ownerId;
		civAW.dueDateTime = obj.StartDateTime;
		civAW.endDateTime = obj.EndDateTime;	
		
		civAW.whatId = obj.whatId;
		civAW.whatName = obj.what.name;
		civAW.whoId = obj.whoId;
		civAW.whoName = obj.who.name;

		return civAW;
	}

    public static String buildFindString(boolean isNameValue, String recordNameValue, boolean isCompanyValue, 
            String recordCompanyValue, boolean isPostcodeValue, String recordPostcodeValue, boolean isPhoneValue, 
            String recordPhoneValue, boolean isEmailValue, String recordEmailValue) {

        /*
            Build SOL search string dynmically
        */
        Integer groupings = 0;
        String tmpString = '';

        if (isNameValue) {
            if (recordNameValue != null) {
                recordNameValue = escapeCharacters(recordNameValue);
                tmpString += '\"' + recordNameValue + '\"';
                groupings++;
            } 
        }

        if (isCompanyValue) {
            if (recordCompanyValue != null) {
                if (groupings > 0) {
                    tmpString += ' OR ';
                }
                recordCompanyValue = escapeCharacters(recordCompanyValue);
                tmpString += '\"' +  recordCompanyValue + '\"';
                groupings++;
            }
        }
        
        if (isPostcodeValue) {
            if (recordPostcodeValue !=null) {
                if (groupings > 0) {
                    tmpString += ' OR ';
                }
                recordPostcodeValue = escapeCharacters(recordPostcodeValue);
                tmpString += '\"' + recordPostcodeValue + '\"';
                groupings++;
            }
        }
        
        if (isPhoneValue) {
            if (recordPhoneValue != null) {
                if (groupings > 0) {
                    tmpString += ' OR ';
                }
                recordPhoneValue = escapeCharacters(recordPhoneValue);
                tmpString += '\"' +  recordPhoneValue + '\"';
                groupings++;
            }
        }
        
        if (isEmailValue) {
            if (recordEmailValue != null) {
                if (groupings > 0) {
                    tmpString += ' OR ';
                }
                recordEmailValue = escapeCharacters(recordEmailValue);
                tmpString +=  '\"' + recordEmailValue + '\"';
                groupings++;
            }
        }
        
        return tmpString;
    }

    public static String escapeCharacters(String value) {
        String newValue;

        for (String s : characters) {
            if (value.contains(s)) {
                newValue = value.replaceAll('\\'+s, '\\\\'+s);
                value = newValue;
            } else {
                newValue = value;
            }
        }

        return newValue;
    }

    public static String createSoslString(boolean isNameValue, String recordNameValue, boolean isCompanyValue, 
            String recordCompanyValue, boolean isPostcodeValue, String recordPostcodeValue, boolean isPhoneValue, 
            String recordPhoneValue, boolean isEmailValue, String recordEmailValue, boolean isLead, 
            boolean isAccount, boolean isContact, boolean isOpportunity, Integer pageNumber, String recordId) {

        /*
            Build SOSL query string depending on the FIND string and on the filters flags
        */

        // build search string
        String findString = buildFindString(isNameValue, recordNameValue, isCompanyValue, 
            recordCompanyValue, isPostcodeValue, recordPostcodeValue, isPhoneValue, 
            recordPhoneValue, isEmailValue, recordEmailValue);

        if (findString != null && findString != '') {
        
            // work out limit based on pageNumber
            Integer newLimit = pageNumber * (MAX_ROWS * 4);
            
            String tmpString = 'FIND {' + findString + '} IN ALL Fields RETURNING ';
            String tmpLimitOffsetString = 'LIMIT ' + newLimit;
            Integer groupings = 0;
            
            if (isLead) {
                tmpString = tmpString + 'lead(id, CreatedDate, LastModifiedDate, Name, Company, LastModifiedById, LastModifiedBy.Name, CreatedById, CreatedBy.Name, Phone, Email, PostalCode, Existing_Customer_Account__c, Contact__c, Owner.LastName, Owner.FirstName, Status, OwnerId WHERE id != \'' 
                    + recordId + '\')';
                groupings++;
            }
    
            if (isAccount) {
                if (groupings > 0) {
                    tmpString = tmpString + ', ';
                }
                tmpString = tmpString + 'account(id, CreatedDate, LastModifiedDate, Name, LastModifiedById, LastModifiedBy.Name, CreatedById, CreatedBy.Name, Phone, BillingPostalCode, Owner.LastName, Owner.FirstName, OwnerId WHERE id != \'' 
                    + recordId + '\' )';
                groupings++;
            }
    
            if (isContact) {
                if (groupings > 0) {
                    tmpString = tmpString + ', ';
                }
                tmpString = tmpString + 'contact(id, CreatedDate, LastModifiedDate, Name, Account.Name, LastModifiedById, LastModifiedBy.Name, CreatedById, CreatedBy.Name, Phone, Email, MailingPostalCode, Owner.LastName, Owner.FirstName, OwnerId WHERE id != \'' 
                    + recordId + '\')';
                groupings++;
            }
    
            if (isOpportunity) {
                if (groupings > 0) {
                    tmpString = tmpString + ', ';
                }
                tmpString = tmpString + 'opportunity(name, CreatedDate, LastModifiedDate, Account.Name, LastModifiedById, LastModifiedBy.Name, CreatedById, CreatedBy.Name, Owner.LastName, Owner.FirstName, StageName, CloseDate, OwnerId, PrimaryContact__r.Email, PrimaryContact__r.Phone, Account.BillingPostalCode WHERE id != \'' 
                    + recordId + '\')';
                groupings++;
            }

            if (groupings == 0) {
                return null;
            } else {
                return tmpString + ' ' + tmpLimitOffsetString;
            }
        }
        return null;
    }

	/*
		Method to build lead merge url
	*/    
	public static string getLeadMergeURL(string masterId, list<string> mergeIds)
	{
		// build base url
		string urlString = URL.getSalesforceBaseUrl().toExternalForm() + bg_CIVUtils.LEAD_MERGE_WIZARD_URL;
		urlString += 'id=' + masterId;

		if(mergeIds.size() > 0)
		{
			urlString += MERGE_WIZARD_NEXT_PARAM;
			urlString += MERGE_WIZARD_URL_ID_PARAM + masterId;
			// Add additional record Ids
			for(string recordId : mergeIds)
			{
				urlString += MERGE_WIZARD_URL_ID_PARAM + recordId;
			}			
		}
/*
		else
		{
			// no other records selected to merge with
			urlString += 'id=' + masterId;
		}
*/
		// add return URL param
		urlString += MERGE_WIZARD_RETURL_PARAM + masterId;

		return urlString;
	}    
}