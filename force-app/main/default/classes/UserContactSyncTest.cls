/**
 * @author: Ana Duarte
 *
 * @Description: Test class for UserContactSync functionality
 *
 * @Name: UserContactSyncTest
 *
 * @version: 1.0
 * Change Log
 * Date author Change Description
 * -----------------------------------------------------------------------------------
 * 06/12/2018 Ana Duarte Created Class
 */
@IsTest
public without sharing class UserContactSyncTest{

	@TestSetup
	public static void testSetup() {
		// create Test Data

		Account a = new Account(Name = 'test', BillingCountry = 'GB');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', Phone = '07123436542', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
		insert c;

		List<Contact> contacts1 = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
		
		System.debug([SELECT Id FROM Contact]);
	}

	/**
	 * Scenario: A field was updated in the user record
	 * Expected Outcome: Field value is synchronized to the related contact record
	 */
	private static testMethod void updateUserSuccess() {
		
		// GIVEN (prerequisites)
		List<ContactUserSync__mdt> updateFieldsUserToContact = getFieldsUserToContact();
		System.debug(updateFieldsUserToContact);
		String queryStr = getQueryContact(updateFieldsUserToContact);
		System.debug(queryStr);
		System.debug([SELECT Id FROM Contact]);
		List<Contact> contacts = Database.query(queryStr);
		System.debug(contacts);
		List<User> usersList = TestData.createPortalUsers(contacts, true);
		System.debug(usersList);
        
		//Trigger.old and trigger.new Simulation
		Map<Id, User>oldMap = createOldMapUser(usersList);
		List<User> newUsers = createNewListUsers(OldMap);
		
		// WHEN (do the actual test)
		Test.startTest();
		UserContactSync.updateContact(newUsers, oldMap);
		Test.stopTest();

		// THEN (do the Assertions)
		Map<Id, SObject> contactsToUpdate = new Map<Id, SObject>(Database.query(queryStr));

		SObject auxContact;
		User oldUser;
		for (User user : newUsers) {

			auxContact = contactsToUpdate.get(user.ContactId);
			oldUser = oldMap.get(user.Id);
          
			for (ContactUserSync__mdt contactUserField : updateFieldsUserToContact) {
                
                if (user.get(contactUserField.User_Field_Api_Name__c)!=null && !user.get(contactUserField.User_Field_Api_Name__c).equals(oldUser.get(contactUserField.User_Field_Api_Name__c))){
                    
					System.assertEquals(user.get(contactUserField.User_Field_Api_Name__c), auxContact.get(contactUserField.Contact_Field_Api_Name__c),'Expecting to be equal... ' + contactUserField.Contact_Field_Api_Name__c);
                }

			}
		}

	}



	/**
	 * Scenario: A field was updated in the Contact record
	 * Expected Outcome: Field value is synchronised to the related user record
	 */
	private static testMethod void updateContactSuccess() {

		// GIVEN (prerequisites)
		List<ContactUserSync__mdt> updateFieldsContactToUser = getFieldsContactToUser();
		String queryStr = getQueryContact(updateFieldsContactToUser);
		List<Contact> contacts = Database.query(queryStr);
		//create users with these contacts
		TestData.createPortalUsers(contacts, true);

		//Trigger.old and trigger.new Simulation
		Map<Id, Contact> oldMap = createOldMapContact(contacts);
		List<Contact> newContacts = createNewListContacts(oldMap);

		// WHEN (do the actual test)
		Test.startTest();
		UserContactSync.updateUser(newContacts, oldMap);
		Test.stopTest();

		// THEN (do the Assertions)

		//Get the contacts that need to be updated with the fields in metadata

		Map<Id, SObject> userMap =getContactId(newContacts, updateFieldsContactToUser);

		SObject user;
        Contact old;
		for (Contact contact : newContacts) {
			user = userMap.get(contact.Id);
            old = oldMap.get(contact.Id);
			for (ContactUserSync__mdt contactUserField : updateFieldsContactToUser) {
                if(contact.get(contactUserField.Contact_Field_Api_Name__c)!=null && !contact.get(contactUserField.Contact_Field_Api_Name__c).equals(old.get(contactUserField.Contact_Field_Api_Name__c))){
					System.assertEquals(contact.get(contactUserField.Contact_Field_Api_Name__c),	user.get(contactUserField.User_Field_Api_Name__c),'Expecting to be equal... ' + contactUserField.Contact_Field_Api_Name__c);
                }
				
			}
		}
	}
	


	/**
	 * Scenario: A field was updated in the Contact record and old contact had a sync field set as null 
	 * Expected Outcome: Field value is synchronised to the related user record
	 */
	private static testMethod void updateContactSuccessElse() {

		// GIVEN (prerequisites)
		List<ContactUserSync__mdt> updateFieldsContactToUser = getFieldsContactToUser();
		String queryStr = getQueryContact(updateFieldsContactToUser);
		List<Contact> contacts = Database.query(queryStr);
		//create users with these contacts
		TestData.createPortalUsers(contacts, true);

		//Trigger.old and trigger.new Simulation
		Map<Id, Contact> oldMap = createOldMapContact(contacts);
		List<Contact> newContacts = createNewListContacts(oldMap);

		// WHEN (do the actual test)
		Test.startTest();

		for (string theKey : oldMap.keySet()) {
		   System.debug('1 theKey=|'+theKey+'|\toldMap.get(theKey)=|'+oldMap.get(theKey)+'|');
		   oldMap.get(theKey).Email = null;
		}

		UserContactSync.updateUser(newContacts, oldMap);
		Test.stopTest();

		// THEN (do the Assertions)

		//Get the contacts that need to be updated with the fields in metadata

		Map<Id, SObject> userMap =getContactId(newContacts, updateFieldsContactToUser);

		SObject user;
        Contact old;
		for (Contact contact : newContacts) {
			user = userMap.get(contact.Id);
            old = oldMap.get(contact.Id);
			for (ContactUserSync__mdt contactUserField : updateFieldsContactToUser) {
                if(contact.get(contactUserField.Contact_Field_Api_Name__c)!=null && !contact.get(contactUserField.Contact_Field_Api_Name__c).equals(old.get(contactUserField.Contact_Field_Api_Name__c))){
					System.assertEquals(contact.get(contactUserField.Contact_Field_Api_Name__c),	user.get(contactUserField.User_Field_Api_Name__c),'Expecting to be equal... ' + contactUserField.Contact_Field_Api_Name__c);
                }
				
			}
		}
	}

    private static testMethod void unitTest(){
		// GIVEN (prerequisites)
		List<ContactUserSync__mdt> updateFieldsUserToContact = getFieldsUserToContact();
		String queryStr = getQueryContact(updateFieldsUserToContact);
		List<Contact> contacts = Database.query(queryStr);
		List<User> usersList = TestData.createPortalUsers(contacts, true);
		Map<Id, User>oldMap = createOldMapUser(usersList);

		//Create Users To check one by one
		List<User> newUsers = new List<User>();
		for (User user : oldMap.values()) {
			User clonedUser = user.clone(true, true);
			clonedUser.FirstName = 'HELLO' ;
			clonedUser.LastName = 'World' ;
			clonedUser.Phone = '+55555';
			clonedUser.Title = 'Professor';
			newUsers.add(clonedUser);
		}
        
        
		// WHEN (do the actual test)
		Test.startTest();
		UserContactSync.updateContact(newUsers, oldMap);
		Test.stopTest();

		//THEN
        for(User user : newUsers){
			Contact c = [Select Id,  FirstName, LastName, Phone, Title From Contact Where Id = :user.ContactId limit 1];
			System.assertEquals(c.Phone,user.Phone,'Expecting to be equal... ');
			System.assertEquals(c.Title,user.Title,'Expecting to be equal... ');
        }
        
    }

	/**
	 * Scenario: A field phone was removed in the user record
	 * Expected Outcome: Field value is removed from the related contact record
	 */
	private static testMethod void updateUserNullPhone() {

		// GIVEN (prerequisites)
		List<ContactUserSync__mdt> updateFieldsContact = getFieldsUserToContact();

		String queryStr = getQueryContact(updateFieldsContact);

		List<Contact> contacts = Database.query(queryStr);
		List<User> usersList = TestData.createPortalUsers(contacts, true);
		Map<Id, User>oldMap = createOldMapUser(usersList);
		List<User> newUsers = new List<User>();

		for (User user : oldMap.values()) {
			User clonedUser = user.clone(true, true);
			clonedUser.Phone = null ;
			newUsers.add(clonedUser);
		}

		// WHEN (do the actual test)
		Test.startTest();
		UserContactSync.updateContact(newUsers, oldMap);
		Test.stopTest();

		// THEN (do the Assertions)
		Set<Id> contactIds = getContactId(newUsers);
		queryStr += ' WHERE Id IN :contactIds';

		Map<Id, SObject> updatedContacts = new Map<Id, SObject>(Database.query(queryStr));
		SObject auxContact;

		for (User user : newUsers) {
			auxContact = updatedContacts.get(user.ContactId);
			System.assertEquals(auxContact.get('Phone'),null,'Expecting to be Null');
				
		
		}
	}
    
	/**
	 * Scenario: A field phone was removed in the client record
	 * Expected Outcome: Field value is removed from the related contact record
	 */
	private static testMethod void updateClientNullPhone() {

		// GIVEN (prerequisites)
		List<ContactUserSync__mdt> updateFieldsContactToUser = getFieldsContactToUser();
		String queryStr = getQueryContact(updateFieldsContactToUser);
		List<Contact> contacts = Database.query(queryStr);
		//create users with these contacts
		TestData.createPortalUsers(contacts, true);

		//Trigger.old and trigger.new Simulation
		Map<Id, Contact> oldMap = createOldMapContact(contacts);
		List<Contact> newContacts =new List<Contact>();
		
        for (Contact contact : oldMap.values()) {
			Contact clonedContact = contact.clone(true, true);
			clonedContact.Phone = null ;
			newContacts.add(clonedContact);
		}
        
        // WHEN (do the actual test)
		Test.startTest();
		UserContactSync.updateUser(newContacts, oldMap);
		Test.stopTest();
        
        // THEN (do the Assertions)
		//Get the contacts that need to be updated with the fields in metadata

		Map<Id, SObject> userMap =getContactId(newContacts, updateFieldsContactToUser);

		SObject user;

		for (Contact contact : newContacts) {
			user = userMap.get(contact.Id);
			System.assertEquals(user.get('Phone'),null,'Expecting to be Null');
				
		
		}
        
	}
    
	/**
	 * Scenario: A field phone was removed in the client record
	 * Expected Outcome: Field value is removed from the related contact record
	 */
	private static testMethod void updateClientNewField() {

		// GIVEN (prerequisites)
		List<ContactUserSync__mdt> updateFieldsContactToUser = getFieldsContactToUser();
		String queryStr = getQueryContact(updateFieldsContactToUser);
		List<Contact> contacts = Database.query(queryStr);
		//create users with these contacts
		TestData.createPortalUsers(contacts, true);

		//Trigger.old and trigger.new Simulation
		Map<Id, Contact> oldMap = createOldMapContact(contacts);
		List<Contact> newContacts =new List<Contact>();
		
        for (Contact contact : oldMap.values()) {
			Contact clonedContact = contact.clone(true, true);
			clonedContact.Title = 'Hello World';
			newContacts.add(clonedContact);
		}
        
        // WHEN (do the actual test)
		Test.startTest();
		UserContactSync.updateUser(newContacts, oldMap);
		Test.stopTest();
        
        // THEN (do the Assertions)
		//Get the contacts that need to be updated with the fields in metadata

		Map<Id, SObject> userMap =getContactId(newContacts, updateFieldsContactToUser);

		SObject user;
		for (Contact contact : newContacts) {
			user = userMap.get(contact.Id);
			System.assertEquals(user.get('Title'),'Hello World','Expecting to be Hello World');
		}
        
	}
	
    
    /**
	 * Scenario: A field phone was added in the user record
	 * Expected Outcome: Field value is removed from the related contact record
	 */
	private static testMethod void updateUserNewField() {

		// GIVEN (prerequisites)
		List<ContactUserSync__mdt> updateFieldsContact = getFieldsUserToContact();

		String queryStr = getQueryContact(updateFieldsContact);

		List<Contact> contacts = Database.query(queryStr);
		List<User> usersList = TestData.createPortalUsers(contacts, true);
		Map<Id, User>oldMap = createOldMapUser(usersList);
		List<User> newUsers = new List<User>();

		for (User user : oldMap.values()) {
			User clonedUser = user.clone(true, true);
			clonedUser.Title = 'Hello World' ;
			newUsers.add(clonedUser);
		}

		// WHEN (do the actual test)
		Test.startTest();
		UserContactSync.updateContact(newUsers, oldMap);
		Test.stopTest();

		// THEN (do the Assertions)
		Set<Id> contactIds = getContactId(newUsers);
		queryStr += ' WHERE Id IN :contactIds';

		Map<Id, SObject> updatedContacts = new Map<Id, SObject>(Database.query(queryStr));
		SObject auxContact;

		for (User user : newUsers) {
			auxContact = updatedContacts.get(user.ContactId);
			System.assertEquals(auxContact.get('Title'),'Hello World','Expecting to be filled');
				
		
		}
	}

	/**
	 * Scenario: A new List of users is updated to the database directly in the Queueable class
	 * Expected Outcome: All the contacts should be updated in the database
	 */
	private static testMethod void testQueueable() {

		// GIVEN (prerequisites)
		List<ContactUserSync__mdt> updateFieldsContact = getFieldsContactToUser();
		String queryStr = getQueryContact(updateFieldsContact);
		List<Contact> contacts = Database.query(queryStr);
		List<User> usersList = TestData.createPortalUsers(contacts, true);
		Map<Id, User>oldMap = createOldMapUser(usersList);
		List<User> newUsers = createNewListUsers(OldMap);

		UserContactSync.SyncContactAndUser syncUser = new UserContactSync.SyncContactAndUser(newUsers);

		// WHEN (do the actual test)
		Test.startTest();
		System.enqueueJob(syncUser);
		Test.stopTest();

		//THEN
		System.assertEquals(1, [SELECT count() FROM User WHERE LastName LIKE '%-changed']);
	}
    
	/**
	 * Scenario: A field is being updated on the user record
	 * Expected Outcome: Field value is synchronised to the related contact record
	 */
	private static testMethod void nullClient() {

		// GIVEN (prerequisites)
		List<User> usersList =  createUsers( 2,true) ;
        Map<Id, User>oldMap = createOldMapUser(usersList);
		List<User> newUsers = createNewListUsers(OldMap);

        // WHEN (do the actual test)
		Test.startTest();
		UserContactSync.updateContact(newUsers, oldMap);
		Test.stopTest();

		System.assertEquals(0, [SELECT count() FROM Contact WHERE LastName LIKE '%-changed']);
	}

	/**
	 * Scenario: Sync on the user creation
	 * Expected Outcome: Fields from the metadata type should be sync between the contact and the user
	 */
	private static testMethod void setUserFieldsTest() {

		// GIVEN (prerequisites)
		Account a = new Account(Name = 'test', BillingCountry = 'GB');
        insert a;
		Contact c = new Contact(AccountId = a.Id, FirstName = 'test', Phone = '07123436542', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB', Title='Director');
		insert c;
		List<Contact> contacts = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
		List<User> users = TestData.createPortalUsers(contacts, true);
		
		User user = users[0];
		List<ContactUserSync__mdt> updateFieldsContactToUser = [SELECT Contact_Field_Api_Name__c, User_Field_Api_Name__c FROM ContactUserSync__mdt WHERE Sync_Contact_to_User__c = true];

		
        // WHEN (do the actual test)
		Test.startTest();
		User userReturned = UserContactSync.setUserFields(user, c, updateFieldsContactToUser);
		Test.stopTest();
		
		System.assertEquals(userReturned.Title, 'Director');
	}
    
    
	/**
     * To construct a number of User records
     *
     * @param count amount of records to construct
     * 
     * @param isInsert true to insert records, else false
     *
     * @return list of User records
     */
    private static List<User> createUsers( integer count, Boolean isInsert) {

        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
        
        List<User> users = new List<User>();

        for(Integer i = 0; i < count ;i++) {
            users.add(
                    new User(
                            ProfileId = profileId,
                            LastName = 'TestLast'+i,
                            FirstName = 'TestFirst'+i,
                            Email = 'test'+i+'@test.com',
                            EmailEncodingKey='UTF-8',
                            Alias = 'abc',
                            Username =  'test'+i+'@test.com'+'.username',
                            TimeZoneSidKey='GMT',
                            LocaleSidKey='en_GB',
							LanguageLocaleKey='en_GB',
							Portal_User_Country__c = 'UK'
                    )
            );
        }
        if (isInsert) {
            insert users;
        }
        return users;
	}
	

	/**
	 * Constructs a Map with users and the id as key
	 *
	 * @param usersList
	 *
	 * @return Map with users and its id as key
	 */
	private static Map<Id, User> createOldMapUser(List<User> usersList) {

		Map<Id, User> users = new Map<Id, User>();

		for (User user : usersList) {
			User clonedUser = user.clone(true, true);
			users.put(user.Id, clonedUser);
		}

		return users;
	}

	/**
	 * Change User objects Last Name
	 *
	 * @param oldMap
	 *
	 * @return List of users changed
	 */
	private static List< User> createNewListUsers(Map<Id, User> oldMap) {

		List< User> users = new List<User>();

		for (User user : oldMap.values()) {
			User clonedUser = user.clone(true, true);
			clonedUser.LastName = clonedUser.LastName + '-changed' ;
			users.add(clonedUser);
		}

		return users;
	}

	/**
	 * Get all ContactId present in the input users
	 *
	 * @param users
	 *
	 * @return Set of contact ids
	 */
	static Set<Id> getContactId(List<User> users) {
		Set<Id> contactIds = new Set<Id>();
		for (User user : users) {
			contactIds.add(user.ContactId);
		}
		return contactIds;
	}

	/**
	 * Get all ContactId present in the input users
	 *
	 * @param users
	 *
	 * @return Set of contact ids
	 */
	private static Map<Id, Contact> createOldMapContact(List<Contact> initList) {

		Map<Id, Contact> contacts = new Map<Id, Contact>();

		for (Contact contact : initList) {

			Contact clonedContact = contact.clone(true, true);

			contacts.put(contact.Id, clonedContact);
		}

		return contacts;
	}

	/**
	 * Change Contacts last name
	 *
	 * @param oldMap
	 *
	 * @return List Of Contacts
	 */
	private static List< Contact> createNewListContacts(Map<Id, Contact> oldMap) {

		List< Contact> contacts = new List<Contact>();

		for (Contact contact : oldMap.values()) {
			Contact clonedContact = contact.clone(true, true);
			clonedContact.LastName = clonedContact.LastName + '-changed' ;
			contacts.add(clonedContact);
		}

		return contacts;
	}

	/**
	 * Creates a query with all the fields from the contact that should have the same values
	 *
	 * @param updateFieldsContact list with metadata fields
	 *
	 * @return String with the query
	 */
	private static String getQueryContact(List<ContactUserSync__mdt> updateFieldsContact) {
		String queryStr = 'SELECT Id, FirstName, LastName ';

		//Get the fields
		for (ContactUserSync__mdt contactUserField : updateFieldsContact) {
			queryStr += ', ' + contactUserField.Contact_Field_Api_Name__c ;
		}

		queryStr = queryStr.subString(0, queryStr.length());
		queryStr += ' FROM Contact';

		return queryStr;
	}

	/**
	 * Creates a query with all the fields from the User that should have the same values
	 *
	 * @param updateFieldsContact list with metadata fields
	 *
	 * @return String with the query
	 */
	private static String getQueryUser(List<ContactUserSync__mdt> updateFieldsContactToUser) {
		String queryStr = 'SELECT ContactId ';

		//Get the fields
		for (ContactUserSync__mdt contactUserField : updateFieldsContactToUser) {
			queryStr += ', ' + contactUserField.User_Field_Api_Name__c ;
		}
		queryStr += ' FROM User';

		return queryStr;
	}

	/**
	 * Get all the fields that should be the same from the contact to user
	 *
	 * @return List with all the fields
	 */
	private static List<ContactUserSync__mdt> getFieldsContactToUser(){
		return [SELECT Contact_Field_Api_Name__c, User_Field_Api_Name__c FROM ContactUserSync__mdt WHERE Sync_Contact_to_User__c = true];
	}

	/**
	 * Get all the fields that should be the same from the User to Contact
	 * @return List with all the fields
	 */
	private static List<ContactUserSync__mdt> getFieldsUserToContact(){
		return [SELECT Contact_Field_Api_Name__c, User_Field_Api_Name__c FROM ContactUserSync__mdt WHERE Sync_User_to_Contact__c = true];
	}

	/**
	 * Creates a Map with contactID as key and user as Value
	 * @param List<Contact> with contacts
	 * @param List<ContactUserSync__mdt> fields needed to exist in the user
	 * @return Map<Id, sObject> contact Id and User object
	 */
	private static Map<Id, SObject> getContactId(List<Contact> newContacts,List<ContactUserSync__mdt> updateFieldsContactToUser ){
		Set<Id> contactIds = new Set<Id>();

		for (Contact contact : newContacts) {
			contactIds.add(contact.Id);
		}

		String queryStrUser = getQueryUser(updateFieldsContactToUser);
		queryStrUser += ' WHERE ContactId in :contactIds';

		Map<Id, SObject> userMap = new Map<Id, SObject>();

		//Get the users associated to the updated contacts
		for (User user : Database.query(queryStrUser)) {
			userMap.put(user.ContactId, user);
		}
		return userMap;
	}

}