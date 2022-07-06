/**
 * @author Andrei Budescu <andrei.budescu@cloudshiftgroup.com>
 * @date 2020-03-22
 * @group CloudShiftGroup
 * @description Handler to create new users for the updated enrollments.
 *
 * Date          author             Change Description
 * -----------------------------------------------------------------------------------
 * 22/03/2020    Andrei Budescu     Created Class
 * 28/07/2020    Julie Skinner      Updated to populate further fields
 * 
 */
public class UserCreationService {
    
    /**
     * To create Users when the booking status of the enrollment changes to 'Booked'.
     *
     * @param contactIds Set of contact Ids linked to the enrollments.
     *
     */
    @future
    public static void createUsersFromEnrollments(Set<ID> contactIds) {
        //profile id for the bsi delegates
        String profileId = [SELECT Id FROM Profile WHERE Name =:Label.BSIUserSettings_ProfileNameDelegate LIMIT 1].Id;
        //Login url community page 
        String loginUrl = createCommunityLoginUrl();

        //List of users to be inserted
        List<User> newUsers = new List<User>();

        //List of Enrollments to update after user created
        List<Enrollment__c> enrollmentsToUpdate = new List<Enrollment__c>();
        
        //list of Contacts to create users
            //construct query to get contacts
            //Get Fields to update in user
        List<ContactUserSync__mdt> updateFieldsContactToUser = [SELECT Contact_Field_Api_Name__c, User_Field_Api_Name__c FROM ContactUserSync__mdt WHERE Sync_Contact_to_User__c = true];
        
        String queryStr = 'SELECT Id, FirstName, LastName, AccountId, (Select Id FROM Users), (Select Id, Portal_Access__c, Delegate_Name__c, End_Expiry_Date__c, Training_Translations__c FROM Enrollments__r) ';
        for (ContactUserSync__mdt contactUserField : updateFieldsContactToUser) {
            queryStr += Constants.COMMA_STRING + contactUserField.Contact_Field_Api_Name__c;
            System.debug(contactUserField.Contact_Field_Api_Name__c);
        }
        queryStr += ' FROM Contact';
        queryStr += ' WHERE Id in :contactIds';

        List<Contact> contacts = Database.query(queryStr);
        //List<Contact> contacts = [SELECT Id, FirstName, LastName, Email, AccountId, (Select Id FROM Users), (Select Id, Portal_Access__c, Delegate_Name__c, Training_Translations__c FROM Enrollments__r) FROM Contact WHERE Id IN :contactIds];
        
        //Get Enrollments of the contacts
        Map<ID, List<Enrollment__c>> enrollmentsByContactId = getEnrollments(contactIds);

        //get existing Users of Contacts
        Map<Id, User> contactUserMap = new Map<Id, User>();
        for(User u : [SELECT ContactId, LastLoginDate, Username FROM User WHERE ContactId IN :contactIds]){
            contactUserMap.put(u.ContactId, u);
        }
        System.debug('### contactUserMap: ' + contactUserMap);
        
        Date today = Date.today();
        
        for(Contact contact : contacts){

            //Contact has no related Users
            if(contact.Users.isEmpty()){
                for(Enrollment__c enrollment : enrollmentsByContactId.get(contact.Id)){
                    if(enrollment.End_Expiry_Date__c > today){
                        //New user to be created
                        //construct user and link the contact
                        System.debug('### UserCreationService, create new User, Contact ' + contact.Id + ', Enrollment ' + enrollment.Id);
                        User u = createNewUser(contact, enrollment, profileId);
                        u = UserContactSync.setUserFields(u, contact, updateFieldsContactToUser);
                        newUsers.add(u);
                    }
                }
            }
            
            //Contact has related Users
            if(!contact.Users.isEmpty()){
                System.debug('### UserCreationService, update existing user for Contact: ' + contact.Id);
                //Enrollments with existing users linked. Update the fields
                
                //existing User, but never logged in
                //reset password for existing User
                Boolean isPasswordReset = false;
                String password = '';
                String setPasswordUrl = '';
                User u = contactUserMap.get(contact.Id);
                if(u != null && u.LastLoginDate == null){
                    ResetPasswordResult rpr = System.resetPassword(u.Id, false);
                    password = rpr.getPassword();
                    setPasswordUrl = loginUrl + 'portalaccess?un=' + EncodingUtil.urlEncode(u.Username, 'UTF-8') + '&pw=' + EncodingUtil.urlEncode(password, 'UTF-8');
                    isPasswordReset = true;
                }
                
                System.debug('### isPasswordReset: ' + isPasswordReset);
                for(Enrollment__c enrollment : contact.Enrollments__r){
                    if(enrollment.End_Expiry_Date__c > today){
                        enrollment.Portal_Access__c = 'Existing User';
                        enrollment.Portal_Login_Link__c = loginUrl;
                        enrollment.Could_not_create_User__c = false;
                        enrollment.Could_Not_Create_User_Error_Message__c = '';
                        if(isPasswordReset) enrollment.Portal_Set_Password_Link__c = setPasswordUrl;
                        enrollmentsToUpdate.add(enrollment);
                    }
                }
            }
        }

        //reset password for new Users
        if(!newUsers.isEmpty()){
            //call method to insert the users and return the enrollments to update
            //DML Options - not send an email to the new user
            Database.DMLOptions dlo = new Database.DMLOptions();
            dlo.EmailHeader.triggerUserEmail = false;
            dlo.optAllOrNone = false;
            List<Database.SaveResult> results = Database.insert(newUsers, dlo);
            Savepoint sp = Database.setSavepoint();
            ResetPasswordQueueable queueable = new ResetPasswordQueueable(newUsers, JSON.serialize(results), enrollmentsByContactId);
            system.debug('dudaresults1111 ' + JSON.serialize(results));
            Database.rollback(sp);
            System.enqueueJob(queueable);
        }

        //Update Enrollments of existing Users
        if(!enrollmentsToUpdate.isEmpty()){
            Database.update(enrollmentsToUpdate, false);
        }
    }


    /**
     * To create a map with the contact id as a key and the list of linked enrollments as a value.
     *
     * @param contactIds Set of contact Ids linked to the enrollments.
     *
     * @return Map<Id, List<Enrollment__c>> Response containing contact Id as keys and lists of linked enrollments as values.
     */
    private static Map<ID, List<Enrollment__c>> getEnrollments(Set<ID> contactIds){
        System.debug('### getEnrollments');
        List<Enrollment__c> enrollments = [SELECT Available_In_Portal__c, Delegate_Name__c, Delegate_Name__r.Account.BillingCity, Delegate_Email__c, End_Expiry_Date__c, 
            Could_not_create_User__c, Could_Not_Create_User_Error_Message__c, Portal_Access__c, Portal_Set_Password_Link__c, Portal_Login_Link__c, 
            Training_Translations__r.TimeZoneSidKeyUser__c, Training_Translations__r.LocaleSidKeyUser__c, Training_Translations__r.LanguageLocaleKeyUser__c, Training_Translations__r.Country_code__c, Training_Translations__r.Language__c 
            FROM Enrollment__c WHERE Delegate_Name__c IN :contactIds];
        // AND Available_In_Portal__c = true
        
        System.debug('### found: ' + enrollments); 
        Map<ID, List<Enrollment__c>> enrollmentsByContactId = new Map<ID, List<Enrollment__c>>();
        for(Enrollment__c enrollment : enrollments){
            if(!enrollmentsByContactId.containsKey(enrollment.Delegate_Name__c)){
                enrollmentsByContactId.put(enrollment.Delegate_Name__c, new List<Enrollment__c>());
            }
            enrollmentsByContactId.get(enrollment.Delegate_Name__c).add(enrollment);
        }
        
        return enrollmentsByContactId;
    }


    /**
     * To create a new User linked to the contact and enrollment.
     *
     * @param contact Contact to be linked to the new user.
     * @param enrollment Enrollment linked to the contact.
     *
     * @return User Returns a new user to be inserted.
     */
    private static User createNewUser(Contact contact, Enrollment__c enrollment, String profileId){

        User newUser = New User(
                        UserName = contact.Email,
                        FirstName = contact.FirstNameCustom__c,
                        LastName = contact.LastNameCustom__c,
                        Alias = String.valueOf(contact.FirstName.substring(0,1) + contact.LastName.substring(0,1)),
                        email = contact.Email,
                        ProfileID = profileId,
                        ContactId = contact.Id,
                        //Mandatory fields - values to be set
                        LanguageLocaleKey = enrollment.Training_Translations__r.LanguageLocaleKeyUser__c,
                        LocaleSidKey = enrollment.Training_Translations__r.LocaleSidKeyUser__c,
                        TimeZoneSidKey = enrollment.Training_Translations__r.TimeZoneSidKeyUser__c,
                        EmailEncodingKey = Label.BSIUserSettings_EmailEncodingKey,
                        BluePrint_Language__c = Label.BSIUserSettings_BluePrintLanguage,
                        SalesType__c = Label.BSIUserSettings_SalesType,
                        Portal_User_Country__c = enrollment.Training_Translations__r.Country_code__c,
                        CostCentre__c = 'CLP-DEL', //JS added as mandatory
                        BusinessHours__c = 'Default' //JS added as mandatory
                    ); 
            
        return newUser;
    }

    
    /**
     * To create the login url for the community portal.
     *
     * @return String - login url for the community portal.
     */
    private static String createCommunityLoginUrl(){
        //Login url community page 
        Network myNetwork = [Select Id FROM Network WHERE Name = :Label.CLP_Community_Name];
        
        String loginUrl = Network.getLoginUrl(myNetwork.Id).removeEnd('login');
       
        return loginUrl;
    }

    /**
     * To reset password for the new users of the community portal.
     *
     * @return null
     */
    public class ResetPasswordQueueable implements Queueable {
        List <SObject> toSync = new List<SObject>();
        List<User> users = new List<User>();
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        Map<ID, List<Enrollment__c>> enrollmentsByContactId = new Map<ID, List<Enrollment__c>>();

        public ResetPasswordQueueable(List<User> users, String results, Map<ID, List<Enrollment__c>> enrollmentsByContactId) {
            this.users = users;
            this.results =  (List<Database.SaveResult>)JSON.deserialize(results, List<Database.SaveResult>.Class);
            this.enrollmentsByContactId = enrollmentsByContactId;
        }

        public void execute(QueueableContext context) {
            List<Enrollment__c> enrollmentsToUpdate = new List<Enrollment__c>();
            String baseUrl = createCommunityLoginUrl();
            try {       

                for(Integer index = 0, size = results.size(); index<size; index++){
                    if(results[index].isSuccess()){
                        //update linked enrollments - user was created
                        String password = '';
                        if(Test.isRunningTest()){
                            password = 'testPassword';
                        } else{
                            ResetPasswordResult rpr = System.resetPassword(users[index].Id, false);
                            password = rpr.getPassword();
                        }
                        String loginUrl = baseUrl + 'portalaccess?un=' + EncodingUtil.urlEncode(users[index].Username, 'UTF-8')
                                    + '&pw=' + EncodingUtil.urlEncode(password, 'UTF-8');
        
                        for(Enrollment__c e : enrollmentsByContactId.get(users[index].ContactId)){
                            e.Portal_Access__c = 'New User';
                            //e.Portal_Login_Link__c = baseUrl.removeEnd('login/') + 's/';
                            e.Portal_Login_Link__c = baseUrl;
                            e.Portal_Set_Password_Link__c = loginUrl;
                            e.Could_Not_Create_User_Error_Message__c = '';
                            e.Could_not_create_User__c = false;
                            enrollmentsToUpdate.add(e);
                        }
                    } else {
                        List<Database.Error> errors = results[index].getErrors();
                        for(Integer i = 0; i < errors.size(); i++){

                            for(enrollment__c e : enrollmentsByContactId.get(users[index].ContactId)){
                                e.Could_not_create_User__c = true;
                                e.Could_Not_Create_User_Error_Message__c = String.join(errors, ',');
                                enrollmentsToUpdate.add(e);
                            }
                        }
                        System.debug(errors);
                    }
                }
                Database.update(enrollmentsToUpdate, false);
            
            } catch (Exception error) {
                //
            }

        }

    }
}