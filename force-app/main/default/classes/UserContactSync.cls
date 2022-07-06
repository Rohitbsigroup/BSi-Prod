/**
 * @author: Ana Duarte
 *
 * @Description: This is class that holds all the logic required for update Contact and User when some update happen
 *
 * @Name: UserContactSync
 *
 * @version: 1.0
 * Change Log
 * Date author Change Description
 * -----------------------------------------------------------------------------------
 * 06/12/2018 Ana Duarte Created Class
 */
public class UserContactSync {

	private static List<ContactUserSync__mdt> updateFieldsUserToContact = new List<ContactUserSync__mdt> ();
	private static List<ContactUserSync__mdt> updateFieldsContactToUser = new List<ContactUserSync__mdt> ();

	/**
	 * Get contacts from a changed User and apply those to the contact (if necessary)
	 *
	 * @param syncUser Users that suffer changes
	 * @param oldMapUser Map with the Id and Users before suffering changes
	 */
	public static void updateContact(List<User> newList, Map<Id, User> oldMapUser) {
		Set<Id> contactIds = getUserContactIds( newList);
		System.debug(newList);
		System.debug(contactIds);
		Map<Id, Contact> syncContInUser = new Map<Id, Contact>();
		
        //populate global lists with metadata fields
		getMetaFields();

		//Get the contacts that need to be updated with the fields in metadata
		Map<Id, SObject> contactsMap = new Map<Id, SObject>(Database.query(getFieldsContact(contactIds)));

		SObject contact;
		User oldUser;
		//For each user changed in the update
		for (User user : newList) {

			contact = contactsMap.get(user.ContactId);
            System.debug(contact);
            if(contact!=null) {
				//Get each field that can be changed in the contact
				for (ContactUserSync__mdt contactUserField : updateFieldsUserToContact) {

					try {
						oldUser = oldMapUser.get(user.Id);
						//If the User field is not null
						if (user.get(contactUserField.User_Field_Api_Name__c) != null) {
							//If was not erased
							if (oldUser.get(contactUserField.User_Field_Api_Name__c) != null) {
								//If the field was not modified
								if (!user.get(contactUserField.User_Field_Api_Name__c).equals(oldUser.get(contactUserField.User_Field_Api_Name__c))) {

									//If the contact has a different value (changed fields PF)
									if (!user.get(contactUserField.User_Field_Api_Name__c).equals(contact.get(contactUserField.Contact_Field_Api_Name__c))) {

										//Put value from the user field into the contact field
										contact.put(contactUserField.Contact_Field_Api_Name__c, user.get(contactUserField.User_Field_Api_Name__c));
										syncContInUser.put(contact.Id, (Contact) contact);
									}
								}
								//add field to contact
							} else {
								contact.put(contactUserField.Contact_Field_Api_Name__c, user.get(contactUserField.User_Field_Api_Name__c));
								syncContInUser.put(contact.Id, (Contact) contact);
							}
							//delete field
						} else {
							if (oldUser.get(contactUserField.User_Field_Api_Name__c) != null) {
								contact.put(contactUserField.Contact_Field_Api_Name__c, null);
								syncContInUser.put(contact.Id, (Contact) contact);
							}
						}
					} catch (Exception e) {
						System.debug('Exception during updateContact() mapping: ' + e.getMessage());
					}
				}

			}
		}

        if(!syncContInUser.isEmpty()){
			System.enqueueJob(new SyncContactAndUser(syncContInUser.values()));
        }

	}

	/**
	 * Get users associated to changed contacts and apply the same changes in the user (if necessary)
	 *
	 * @param syncUser Users that suffer changes
	 * @param oldMapUser Map with the Id and Users before suffering changes
	 */
	public static void updateUser(List<Contact> newList, Map<Id, Contact> oldMap) {

		Map<Id, User> syncUserInContact = new Map<Id, User>();
		Set<Id> contactIds =  getContactIds(newList);
       
        //populate global lists with metadata fields
		getMetaFields();

		//Get the contacts that need to be updated with the fields in metadata
		Map<Id, SObject> usersMap = new Map<Id, SObject>();
		//Get the users associated to the updated contacts
		for (User user : Database.query(getFieldsUser(contactIds))) {
			usersMap.put(user.ContactId, user);
		}

		SObject user;
		Contact oldContact;
		//For each contact updated

		for (Contact contact : newList) {
			user = usersMap.get(contact.Id);

			// user has to exist for this Contact (as some Contacts don't have a Community user yet)
			if(user != null) {

				//Get each field that can be changed in the user
				for (ContactUserSync__mdt contactUserField : updateFieldsContactToUser) {

					try {
						oldContact = oldMap.get(contact.Id);
						//If the Contact field is not null
						if (contact.get(contactUserField.Contact_Field_Api_Name__c) != null) {

							if (oldContact.get(contactUserField.Contact_Field_Api_Name__c) != null) {

								//If the field was not modified
								if (!contact.get(contactUserField.Contact_Field_Api_Name__c).equals(oldContact.get(contactUserField.Contact_Field_Api_Name__c))) {

									//If the user has a different value
									if (!contact.get(contactUserField.Contact_Field_Api_Name__c).equals(user.get(contactUserField.User_Field_Api_Name__c))) {
										//Put value from the contact field into the user field
										user.put(contactUserField.User_Field_Api_Name__c, contact.get(contactUserField.Contact_Field_Api_Name__c));
										syncUserInContact.put(user.Id, (User) user);
									}
								}
							} else {
								user.put(contactUserField.User_Field_Api_Name__c, contact.get(contactUserField.Contact_Field_Api_Name__c));
								syncUserInContact.put(user.Id, (User) user);
							}
						} else {
							if (oldContact.get(contactUserField.Contact_Field_Api_Name__c) != null) {
								user.put(contactUserField.User_Field_Api_Name__c, null);
								syncUserInContact.put(user.Id, (User) user);
							}
						}
					} catch (Exception e) {
						System.debug('Exception during updateContact() mapping: ' + e.getMessage());
					}
				}
			}

		}
		if(!syncUserInContact.isEmpty()){
			System.enqueueJob(new SyncContactAndUser(syncUserInContact.values()));
        }

	}
    
    private static void getMetaFields() {
        //Get Fields that are to update in contact
		updateFieldsContactToUser = [SELECT Contact_Field_Api_Name__c, User_Field_Api_Name__c FROM ContactUserSync__mdt WHERE Sync_Contact_to_User__c = true];

        //Get Fields to update in contact
		updateFieldsUserToContact = [SELECT Contact_Field_Api_Name__c, User_Field_Api_Name__c FROM ContactUserSync__mdt WHERE Sync_User_to_Contact__c = true];
    }

    /**
     * Get all the ids from the contacts in the user list
     * @param List users
     * @return Set of ids
     */
    private static Set<Id> getUserContactIds(List<User> newList){
        Set<Id> contactIds = new Set<Id>();
        //Get contacts in Users updated
		for (User user : newList) {
			contactIds.add(user.ContactId);
		}
		return contactIds;
    }

    /**
     * Get all the ids from the contacts in the  list
     * @param List users
     * @return Set of ids
     */
    private static Set<Id> getContactIds(List<Contact> newList){
        Set<Id> contactIds = new Set<Id>();
        //Get contacts in Users updated
		for (Contact contact : newList) {
			contactIds.add(contact.Id);
		}
		return contactIds;
    }

	/**
	 * Get all metadata fields from contacts
	 *
	 * @param contactIds
	 *
	 * @return String with query
	 */
	private static String getFieldsContact(Set<Id> contactIds) {
		String queryStr = 'SELECT Id ';
		for (ContactUserSync__mdt contactUserField : updateFieldsUserToContact) {
			queryStr += Constants.COMMA_STRING + contactUserField.Contact_Field_Api_Name__c;
		}
		queryStr += ' FROM Contact';
		queryStr += ' WHERE Id in :contactIds';

		return queryStr;
	}

	/**
	 * Get all metadata fields from users
	 * @param contactIds
	 * @return String with query
	 */
	private static String getFieldsUser(Set<Id> contactIds){
		String queryStr = 'SELECT ContactId ';
		//Get the fields
		for (ContactUserSync__mdt contactUserField : updateFieldsContactToUser) {
			queryStr += ', ' + contactUserField.User_Field_Api_Name__c ;
		}
		queryStr += ' FROM User';
		queryStr += ' WHERE ContactId in :contactIds';

		return queryStr;
	}

	/**
	 * Get all metadata fields from users
	 * @param user User record to be synchronised with the contact record
	 * @param contact Contact record used to sync with the user's fields
	 * @param updateFieldsContactToUser List of metadata fields used for the sync process between the contact and the user records
	 * @return String with query
	 */
	public static User setUserFields(User user, Contact contact, List<ContactUserSync__mdt> updateFieldsContactToUser){

		//use metadata to sync with the contact- dynamicaly query
        SObject newUser = (SObject) user;

        //Get each field that can be changed in the user
        for (ContactUserSync__mdt contactUserField : updateFieldsContactToUser) {
            try {
                //If the Contact field is not null
                if (contact.get(contactUserField.Contact_Field_Api_Name__c) != null) {
                    //If the user has a different value
                    if (!contact.get(contactUserField.Contact_Field_Api_Name__c).equals(newUser.get(contactUserField.User_Field_Api_Name__c))) {
						System.debug(contactUserField.User_Field_Api_Name__c);
						System.debug(contact.get(contactUserField.Contact_Field_Api_Name__c));
                        newUser.put(contactUserField.User_Field_Api_Name__c, contact.get(contactUserField.Contact_Field_Api_Name__c));
                    }

                }
            } catch (Exception e) {
                System.debug('Exception during updateUser() mapping: ' + e.getMessage());
            }
        }
            
		//newUser = (User) user; 
		return (User) newUser;    

	}

	/**
	 * @author: Ana Duarte
	 *
	 * @Description: This class will synchronize the sObjects whose need to be updated
	 *
	 * @Name: SyncContactAndUser
	 */
	public class SyncContactAndUser implements Queueable {

		List <SObject> toSync = new List<SObject>();

		public SyncContactAndUser(List<SObject> toSync) {
			this.toSync = toSync;
		}

		public void execute(QueueableContext context) {
            
			try {				
			
                update toSync;
			
            } catch (Exception error) {
                
			}

		}

	}

}