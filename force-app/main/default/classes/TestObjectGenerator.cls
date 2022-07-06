/********************************************************************
* TestObjectGenerator
*
* Unit test method class to generate objects needed in the tests
*
* Author: Nebula - Robert Bedding
* Created: 08-08-2016 
********************************************************************/
public class TestObjectGenerator {
    
    private static Account testAccount;
    
    public static Account getAccount() {
        if(testAccount == null) {
            testAccount = getAccountNoInsert();
            insert testAccount;
        }
        
        return testAccount;
    }
    
    public static Account getAccountNoInsert() {
        return new Account(Name = 'Test Account', BillingCountry = 'GB');
    }
    
    private static Contact testContact;
    
    public static Contact getContact() {
        if(testContact == null) {
            testContact = new Contact(LastName = 'lastname', Email = 'test@test.com', AccountId = getAccount().Id, MailingCountry = 'GB', Create_Lead__c = true);
            
            insert testContact;
        }       
        return testContact;
    }
    
    private static List<Contact_to_Lead_Field_Map__c> contactToLeadFields;
    
    public static List<Contact_to_Lead_Field_Map__c> getContactToLeadFields() {
        if(contactToLeadFields == null) {
            contactToLeadFields = new List<Contact_to_Lead_Field_Map__c> {
                new Contact_to_Lead_Field_Map__c(Name = 'Email', Lead_Field__c = 'Email',Contact_Field__c = 'Email'),
                    new Contact_to_Lead_Field_Map__c(Name = 'Account', Lead_Field__c = 'Company',Contact_Field__c = 'AccountId'),
                    new Contact_to_Lead_Field_Map__c(Name = 'LastName', Lead_Field__c = 'LastName',Contact_Field__c = 'LastName')
                    };
                        
                        System.runAs(new User(Id = UserInfo.getUserId())) {
                            insert contactToLeadFields;
                        }
        }
        return contactToLeadFields;
        
    }
}