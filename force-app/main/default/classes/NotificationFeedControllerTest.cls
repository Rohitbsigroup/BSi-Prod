/**
 * @Name:        NotificationFeedControllerTest
 * @Description: This class handles Notification component - FeedItem records
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 21/04/2020   Andrei Budescu     Created Class
 */

@IsTest
public class NotificationFeedControllerTest {
    
    //wrapper class for the notification item
    public class Notification{
        String title;
        String description;
        String url;
        Boolean isClicked;
        Boolean isClosed;

        public Notification(String title, String description, String url, Boolean isClicked, Boolean isClosed){
            this.title = title;
            this.description = description;
            this.url = url;
            this.isClicked = isClicked;
            this.isClosed = isClosed;
        }

    }

     /**
	 * Scenario: An user access the home page and reads the notifications available
	 * Expected Outcome: List of notifications on the feed
	 */
    public static testMethod void getNotificationsTest() {

        User uDelegate = [SELECT Id, Email, ContactId FROM User WHERE Email = 'test@test.com'];
        System.debug(uDelegate.ContactId);

        String contactId = uDelegate.ContactId;

        CLP_Notification__c notificationItem = new CLP_Notification__c();
        notificationItem.Notified_Contact__c = contactId;
        notificationItem.Notification_Is_Closed__c = false;
        notificationItem.Notification_Is_Closed__c = false;
        insert notificationItem;

        List<Notification> notifications = new List<Notification>();
        Test.startTest();
        String notificationsString = NotificationFeedController.getNotificationRecords(uDelegate.Id);
        notifications = (List<Notification>)System.JSON.deserialize(notificationsString, List<Notification>.class);
        Test.stopTest(); 

        List<CLP_Notification__c> itemsToDisplay = [SELECT Id, Notification__c, Notified_Contact__c, Notification_Clicked_on_Flag__c, Notification_Is_Closed__c FROM CLP_Notification__c WHERE Notified_Contact__c =:contactId AND Notification_Is_Closed__c = false];

        System.assertEquals(notifications.size(), itemsToDisplay.size());
    }

    /**
	 * Scenario: An user access the home page and reads the notifications available
	 * Expected Outcome: List of notifications on the feed
	 */
    public static testMethod void getNotificationsExceptionTest() {

        User uDelegate = [SELECT Id, Email, ContactId FROM User WHERE Email = 'test@test.com'];
        System.debug(uDelegate.ContactId);

        String contactId = uDelegate.ContactId;

        CLP_Notification__c notificationItem = new CLP_Notification__c();
        notificationItem.Notified_Contact__c = contactId;
        notificationItem.Notification_Is_Closed__c = false;
        notificationItem.Notification_Is_Closed__c = false;
        insert notificationItem;

        List<Notification> notifications = new List<Notification>();
        Test.startTest();
        String notificationsString = NotificationFeedController.getNotificationRecords('wrong id');
        notifications = (List<Notification>)System.JSON.deserialize(notificationsString, List<Notification>.class);
        Test.stopTest(); 

        System.assertEquals(notifications.size(), 0);
    }

     /**
	 * Scenario: An user access the home page and reads the notifications available and close a post
	 * Expected Outcome: The post is removed from the feed
	 */
    public static testMethod void closeNotificationTest() {

        User uDelegate = [SELECT Id, Email, ContactId FROM User WHERE Email = 'test@test.com'];
        System.debug(uDelegate.ContactId);
        String contactId = uDelegate.ContactId;

        CLP_Notification__c notificationItem = new CLP_Notification__c();
        notificationItem.Notified_Contact__c = contactId;
        notificationItem.Notification_Is_Closed__c = false;
        notificationItem.Notification_Is_Closed__c = false;
        insert notificationItem;

        Test.startTest();
        NotificationFeedController.closePost(notificationItem.Id);
        Test.stopTest();

        CLP_Notification__c notificationLiked = [SELECT Id, Notification__c, Notified_Contact__c,Notification_Is_Closed__c, Notification_Clicked_on_Flag__c FROM CLP_Notification__c WHERE Id = :notificationItem.Id LIMIT 1];
        System.assertEquals(true, notificationLiked.Notification_Is_Closed__c);

        List<CLP_Notification__c> itemsToDisplay = [SELECT Id, Notification__c, Notified_Contact__c, Notification_Clicked_on_Flag__c FROM CLP_Notification__c WHERE Notified_Contact__c =:contactId AND Notification_Is_Closed__c = false];
        System.assertEquals(true, itemsToDisplay.isEmpty());

    }

    /**
	 * Scenario: An user access the home page and reads the notifications available and close a post
	 * Expected Outcome: The post is not closed and it is not removed from the feed
	 */
    public static testMethod void closePostExceptionTest() {

        User uDelegate = [SELECT Id, Email, ContactId FROM User WHERE Email = 'test@test.com'];
        String contactId = uDelegate.ContactId;

        CLP_Notification__c notificationItem = new CLP_Notification__c();
        notificationItem.Notified_Contact__c = contactId;
        notificationItem.Notification_Is_Closed__c = false;
        notificationItem.Notification_Is_Closed__c = false;
        insert notificationItem;

        Test.startTest();
        NotificationFeedController.closePost('wrong Id');
        Test.stopTest();

        List<Notification> notifications = new List<Notification>();
        String notificationsString = NotificationFeedController.getNotificationRecords(uDelegate.Id);
        notifications = (List<Notification>)System.JSON.deserialize(notificationsString, List<Notification>.class);
        
        CLP_Notification__c notificationNotLiked = [SELECT Id, Notification__c, Notified_Contact__c,Notification_Is_Closed__c, Notification_Clicked_on_Flag__c FROM CLP_Notification__c WHERE Id = :notificationItem.Id LIMIT 1];
        System.assertEquals(notificationNotLiked.Notification_Is_Closed__c, false);

    }

    /**
	 * Scenario: An user access the home page and access a notification
	 * Expected Outcome: The notification's border changes the colour to grey
	 */
    public static testMethod void readNotificationTest() {

        User uDelegate = [SELECT Id, Email, ContactId FROM User WHERE Email = 'test@test.com'];
        System.debug(uDelegate.ContactId);
        String contactId = uDelegate.ContactId;

        CLP_Notification__c notificationItem = new CLP_Notification__c();
        notificationItem.Notified_Contact__c = contactId;
        notificationItem.Notification_Is_Closed__c = false;
        notificationItem.Notification_Is_Closed__c = false;
        insert notificationItem;

        Test.startTest();
        NotificationFeedController.readPost(notificationItem.Id);
        Test.stopTest();

        CLP_Notification__c notificationLiked = [SELECT Id, Notification__c, Notified_Contact__c, Notification_Clicked_on_Flag__c FROM CLP_Notification__c WHERE Id = :notificationItem.Id LIMIT 1];
        System.assertEquals(true, notificationLiked.Notification_Clicked_on_Flag__c);

        List<CLP_Notification__c> itemsToDisplay = [SELECT Id, Notification__c, Notified_Contact__c, Notification_Clicked_on_Flag__c FROM CLP_Notification__c WHERE Notified_Contact__c =:contactId AND Notification_Is_Closed__c = false];
        System.assertEquals(true, !itemsToDisplay.isEmpty());

    }

    /**
	 * Scenario: An user access the home page and access a notification
	 * Expected Outcome: The notification's border keeps tale colour as by default
	 */
    public static testMethod void readNotificationExceptionTest() {

        User uDelegate = [SELECT Id, Email, ContactId FROM User WHERE Email = 'test@test.com'];
        System.debug(uDelegate.ContactId);
        String contactId = uDelegate.ContactId;

        CLP_Notification__c notificationItem = new CLP_Notification__c();
        notificationItem.Notified_Contact__c = contactId;
        notificationItem.Notification_Is_Closed__c = false;
        notificationItem.Notification_Is_Closed__c = false;
        insert notificationItem;

        Test.startTest();
        NotificationFeedController.readPost('wrond Id');
        Test.stopTest();

        CLP_Notification__c notificationLiked = [SELECT Id, Notification__c, Notified_Contact__c, Notification_Clicked_on_Flag__c FROM CLP_Notification__c WHERE Id = :notificationItem.Id LIMIT 1];
        System.assertEquals(false, notificationLiked.Notification_Clicked_on_Flag__c);

    }

     /**
	 * Scenario: An user access the home page and reads the notifications available
	 * Expected Outcome: List of notifications on the feed
	 */
    @IsTest public static void getNotificationsWithArchivedTest() {

        User uDelegate = [SELECT Id, Email, ContactId FROM User WHERE Email = 'test@test.com'];
        System.debug(uDelegate.ContactId);
        String contactId = uDelegate.ContactId;
        CLP_Notification__c notificationItem1 = new CLP_Notification__c();
        notificationItem1.Notified_Contact__c = contactId;
        notificationItem1.Notification_Is_Closed__c = false;
        notificationItem1.Notification_Is_Archived__c = true;
        insert notificationItem1;
        CLP_Notification__c notificationItem2 = new CLP_Notification__c();
        notificationItem2.Notified_Contact__c = contactId;
        notificationItem2.Notification_Is_Closed__c = false;
        notificationItem2.Notification_Is_Archived__c = false;
        insert notificationItem2;

        List<Notification> notifications = new List<Notification>();
        Test.startTest();
        String notificationsString = NotificationFeedController.getNotificationRecords(uDelegate.Id);
        notifications = (List<Notification>)System.JSON.deserialize(notificationsString, List<Notification>.class);
        Test.stopTest(); 

        List<CLP_Notification__c> itemsToDisplay = [SELECT Id, Notification__c, Notified_Contact__c, Notification_Clicked_on_Flag__c, Notification_Is_Closed__c FROM CLP_Notification__c WHERE Notified_Contact__c =:contactId AND Notification_Is_Closed__c = false AND Notification_Is_Archived__c = false];
        System.assertEquals(notifications.size(), 1);

    }

    

    @TestSetup 
    private static void generateOrgData(){

        Account a = new Account(Name = 'test', BillingCountry = 'GB');
        insert a;

        Contact c = new Contact(AccountId = a.Id, FirstName = 'test', Phone = '07123436542', LastName = 'test', Email = 'test@test.com', MailingCountry = 'GB');
		insert c;

		Contact c2 = new Contact(AccountId = a.Id, FirstName = 'test2', Phone = '07123436542', LastName = 'test2', Email = 'test2@test.com', MailingCountry = 'GB');
		insert c2;

		List<Contact> contacts1 = [SELECT Id, Email, FirstName, Phone, LastName FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
		
        List<User> users = TestData.createPortalUsers(contacts1, true);


        
	}

}