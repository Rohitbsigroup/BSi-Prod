/**
*
* Author 		: Prasad J N
* Date			: 22 May 2018 
* Description	: Apex class to create c-code profile when a user is created
*
*/
public with sharing class emq_UserTriggerHandler {
    
    public void OnAfterInsert(User[] users){
    	Set<Id> userIds = new Set<Id>();
    	for(User user: users){
    		userIds.add(user.Id);	
    	}
    	
    	users = [SELECT Id, Profile.UserLicense.Name FROM User WHERE Id = :userIds];
    	for(User user: users){
    		if(user.Profile.UserLicense.Name == 'Salesforce')
    			userIds.add(user.Id);
    	}
		if(!System.isFuture()){
			emq_UserTriggerHandler.createCCodeProfile(userIds);    	
		}
    }
    
    @future
    public static void createCCodeProfile(Set<Id> userIds) {
    	List<CCode_Profile__c> ccodeProfiles = new List<CCode_Profile__c>();
    	
    	for(Id userId: userIds){
    		CCode_Profile__c profile = new CCode_Profile__c();
    		profile.User__c = userId;
    		ccodeProfiles.add(profile);
    	}
    	
    	insert ccodeProfiles;
	}
	
	/**
     * To handle the User After Update Context
     *
     * @param newList List of Users who have changed
     * @param oldMap Map of Users by Id before changes
     */
    public void onAfterUpdate(List<User> newList, Map<Id, User> oldMap) {

        // Sync Fields to Contact
		UserContactSync.updateContact(newList, oldMap);
		
	}

	/**
     * To handle the User Before Update Context
     *
     * @param newList List of Users who have changed
     * @param oldMap Map of Users by Id before changes
     */
    public void onBeforeUpdate(List<User> newList, Map<Id, User> oldMap) {
		newList = updateLanguageUser(newList);
	}

	/**
     * To handle the User Before Insert Context
     *
     * @param newList List of Users who have changed
     * @param oldMap Map of Users by Id before changes
     */
    public void onBeforeInsert(List<User> newList, Map<Id, User> oldMap) {
		newList = updateLanguageCustomUser(newList);
	}
	
	
	private static List<User> updateLanguageUser(List<User> usersToUpdate){
		// Sync Fields LanguageCustom__c and LanguageLocaleKey
		for(User u : usersToUpdate){
			if(String.isNotBlank(u.LanguageCustom__c)){
				u.LanguageLocaleKey = u.LanguageCustom__c;
			}
			
		}

		return usersToUpdate;
	}

	private static List<User> updateLanguageCustomUser(List<User> usersToUpdate){
		// Sync Fields LanguageCustom__c and LanguageLocaleKey
		Schema.DescribeFieldResult fieldResult = User.LanguageCustom__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for(User u : usersToUpdate){
			if(String.isNotBlank(u.LanguageLocaleKey)){
				System.debug('LanguageLocaleKey: ' + u.LanguageLocaleKey);
				
				for(Schema.PicklistEntry f : ple){
					if(u.LanguageLocaleKey.contains(f.getValue())){
						u.LanguageCustom__c = u.LanguageLocaleKey;
					}
				}
				   
				/*try{
					u.LanguageCustom__c = u.LanguageLocaleKey; 
					System.debug('Language custom updated.' + u.LanguageCustom__c);
				}catch(Exception e){
					return usersToUpdate;
					System.debug('Restricted picklist Language Custom.');
				}*/
				
			}
			 
		}

		return usersToUpdate;
	}

}