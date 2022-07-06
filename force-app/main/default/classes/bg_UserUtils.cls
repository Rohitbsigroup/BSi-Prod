/********************************************************************
 * bg_UserUtils
 *
 * Utility methods to support User
 * and sites
 * 
 * Author: Richard Jimenez
 * Created: 24-10-2013
 * Changes: 
 *          RJ 01-06-2014 Added PROFILE_NAME_BSI_SALESPERSON constant 
 *          RJ 29-07-2015 Added OperationsTeamApprover__c to User SOQL
 *          03-11-2016 ADS - SoW027
 *                         - Removed use of and references to Operations Team Approver
 *                         - Added Requires_Operations_Approval__c to GetUsers()/GetUserById() SOQL
 *			14-11-2016 JT Added Blueprint_Language__c to User SOQL
 *			RC 21-07-2017 Added function to update the user record.
 *			CPE 01-09/2017	Moved method GetCountryMap from OpportunityTriggerHandler
 ********************************************************************/
public with sharing class bg_UserUtils {

	public static final string OPERATION_REGION_EMEA = 'EMEA';
	public static final string OPERATION_REGION_AMERICAS = 'AMERICAS';
	public static final string OPERATION_REGION_ASIA_PAC = 'ASIA-PAC';

	public static final string OPERATION_COUNTRY_GB = 'GB';
	public static final string OPERATION_COUNTRY_US = 'US';
	
	public static final string PROFILE_NAME_BSI_SALESPERSON = 'BSI Salesperson';
	public static final string PROFILE_NAME_BSI_SYSADMIN = 'System Administrator'; 
	
	public static map<Id, User> GetUserMap() {
		/* Return user map */
		return GetUserMap(true);
	}

	public static map<Id, User> GetUserMap(boolean activeOnly) {
		/*
			Return user map
		*/
		return new map<Id, User>(GetUsers(activeOnly));
	}
	
	public static list<User> GetUsers(boolean activeOnly) {
		/*
			Return list of users
		*/
		list<User> users = new list<User>();
		users.addAll([SELECT Id, Name, Profile.Name, ManagerId, DelegatedApproverId, OperationCountry__c, Requires_Operations_Approval__c, UserRole.Name
						FROM User
						WHERE (IsActive = true OR IsActive = :activeOnly)
							AND Profile.UserType = 'Standard']);
		return users;
	}

	public static User GetUserById(Id userId) {
		/*
			Return user by Id
		*/
		User user = [SELECT Id, Name, Profile.Name, ManagerId, DelegatedApproverId, 
						OperationCountry__c, Requires_Operations_Approval__c, IsActive, Blueprint_Language__c,
						PS_Approval_User__c
						FROM User
						WHERE Id = :userId];
		return user;
	}
	
	public static boolean IsAdministrator(Id userId) {
		/*
			Return if user is an admin
		*/
		return GetUserById(userId).Profile.Name.contains('System Administrator');		
	}

	/*
    *   Function to update the user record with the ps proposal approval user.
  	*/
  	public static void UpdateUserRecordForPs(Id userId)
  	{
    	User usr = [Select Id, PS_Approval_User__c FROM User Where Id=:Userinfo.getUserId()];    
        usr.PS_Approval_User__c = userId;
        update usr;
  	}


	/*
		Returns a map of user records based on the supplied user ids.
		Uses a class member variable to maintain to maintain state between triggers that utilise
		this method
		If a different set of user is passed in a later trigger, then these are added to the existing set 
	*/
	private static Map<Id,User> countryMap;
	public static Map<Id,User> GetCountryMap(Set<Id> ownerids)
	{
		if(countryMap == null)
		{
			countryMap = new Map<Id,User>([SELECT OperationCountry__c FROM User WHERE Id IN:ownerids]);
		}
		else
		{
			Set<Id> ownerIdsNotInMap = new Set<Id>();
			for(Id ownerId : ownerIds)
			{
				if(!countryMap.containsKey(ownerid))
				{
					ownerIdsNotInMap.add(ownerId);
				}
			}
			countryMap.putAll(new Map<Id,User>([SELECT OperationCountry__c FROM User WHERE Id IN:ownerIdsNotInMap]));
		}
		return countryMap;
	}


	
	/************************************************************************/
	/* TEST METHODS - bg_UserUtilsTest                                      */	
	/************************************************************************/	
	
}