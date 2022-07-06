/**
 * @Name:        NotificationFeedController
 * @Description: This class handles Notification component - FeedItem records
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 21/04/2020   Andrei Budescu     Created Class
 * 29/06/2021   Julie Skinner       Added debugs
 */

public without sharing class NotificationFeedController {
    private static Map<String,Set<String>> DATE_FORMATS_BY_COUNTRY = new Map<String,Set<String>> 
            {   'dd/MM/YYYY' => new Set<String>{
                    'ME', 'AU', 'NZ', 'IN', 'SA', 'FR', 'MY', 'PH', 'UK', 'SG', 'NL', 'HK', 'ID', 'DE', 'ES', 'PL', 'TR', 'IT', 
                    'IE', 'VN', 'TH', 'RU'
                },
                'YYYY/MM/dd' => new Set<String>{ 'JP', 'CN', 'KR', 'TW' }
            };
    private static String DEFAULT_FORMAT = 'dd/MM/YYYY';

    //wrapper class for the notification item
    public class Notification{
        String title;
        String description;
        String url;
        Boolean isClicked;
        Boolean isClosed;
        String createdDate;

        public Notification(String title, String description, String url, Boolean isClicked, Boolean isClosed, String createDate){
            this.title = title;
            this.description = description;
            this.url = url;
            this.isClicked = isClicked;
            this.isClosed = isClosed;
            this.createdDate = createDate;
        }

    }

    /**
     * Get notifications available for the user
     *
     * @param recordId Current user id 
     *  
     * @return List<FeedItem> with items to be displayed on the notification feed
     */
    @AuraEnabled
    public static String getNotificationRecords(String userId){
        List<Notification> notifications = new List<Notification>();
        List<CLP_Notification__c> itemsToDisplay = new List<CLP_Notification__c>();

        try{
            String contactId = [SELECT Id, ContactId FROM User WHERE Id =:userId].ContactId;
            itemsToDisplay = [SELECT Id, Notification__c, Notified_Contact__c, Notification_Clicked_on_Flag__c, Notification_Is_Closed__c, CreatedDate FROM CLP_Notification__c WHERE Notified_Contact__c =:contactId AND Notification_Is_Closed__c = false AND Notification_Is_Archived__c = false ORDER BY CreatedDate DESC];
            
            for(CLP_Notification__c notifItem : itemsToDisplay){
                String descriptionNotif = notifItem.Notification__c.substringAfter('>').substringBefore('</a>');
                notifications.add(new Notification(notifItem.Id, descriptionNotif, getUrlSubstring(notifItem.Notification__c), notifItem.Notification_Clicked_on_Flag__c, notifItem.Notification_Is_Closed__c, getCreatedDateFormatted(notifItem.CreatedDate)));
            }

        }catch(Exception e){ 
            //
        }

        return JSON.serialize(notifications);

    }
    
    private static String getCreatedDateFormatted(Datetime createdDate){
        String formattedDate = '';
        String userCountry = getUserCountry();
        for(String key : DATE_FORMATS_BY_COUNTRY.keySet()){
            if(DATE_FORMATS_BY_COUNTRY.get(key).contains(userCountry)){
                formattedDate = createdDate.format(key);
            }
        }
        return String.isBlank(formattedDate) ? createdDate.format(DEFAULT_FORMAT) : formattedDate;
    }

    private static String getUserCountry(){
        String userCountryCode = '';
        List<User> currentUserList = [SELECT Portal_User_Country__c FROM User WHERE Id = :UserInfo.getUserId()];
        if(!currentUserList.isEmpty()){
            String countryCode = currentUserList[0].Portal_User_Country__c;
            if(!String.isBlank(countryCode)){
                userCountryCode = countryCode.toUppercase();
            } 
        }
        return userCountryCode;
    }

    /**
     * Get url for the tiles with external url
     *
     * @param url Formula field from the enrollment contains the url
     *  
     * @return String with the proper url to be accessed
     */
    @AuraEnabled
    public static String getUrlSubstring(String url){
        String finalUrl = '';

        finalUrl = url.substringAfter('"').substringBefore('"');
        finalUrl = finalUrl.replace('&amp;', '&');

        System.debug('### finalUrl: ' + finalUrl);

        return finalUrl;

        
        
    }

    
    

    /**
     * Update notification record in order to remove it from the feed
     *
     * @param notificationRecordId Record id of notification to close
     *  
     */
    @AuraEnabled
    public static void closePost(String notificationRecordId){
        CLP_Notification__c notificationRecord = new CLP_Notification__c();

        try{
            notificationRecord = [SELECT Id, Notification_Is_Closed__c FROM CLP_Notification__c WHERE Id =:notificationRecordId];
            notificationRecord.Notification_Is_Closed__c = true;
            update notificationRecord; 
        }catch(Exception e){

        }
    
        
    }

    /**
     * Update the notification record in order to change the colour to grey of the border
     *
     * @param notificationRecordId Record id of notification to read
     *  
     */
    @AuraEnabled
    public static void readPost(String notificationRecordId){
        CLP_Notification__c notificationRecord = new CLP_Notification__c();

        try{
            notificationRecord = [SELECT Id, Notification_Clicked_on_Flag__c FROM CLP_Notification__c WHERE Id =:notificationRecordId];
            notificationRecord.Notification_Clicked_on_Flag__c = true;
            update notificationRecord; 
        }catch(Exception e){

        }
    
        
    }


}