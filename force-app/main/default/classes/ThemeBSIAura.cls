/**
 * @Name:        ThemeBSIAura
 * @Description: This class handles Theme operations and permissions checks
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 04/04/2020   Andrei Budescu     Created Class
 */

 
public without sharing class ThemeBSIAura {

    //vars for the string
    private static final String IS_INTERNAL_USER = 'isInternalUser';
    private static final String RECORD_ID_ACCESS = 'recordIdAccess';

    //wrapper class for the footer link
    public class FooterLink{
        String txt;
        String lnk;

        public FooterLink(String txt, String lnk){
            this.txt = txt;
            this.lnk = lnk;
        }

    }
    /**
     * Check access for records of User 
     * 
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRecordRelatedList(){
        
        Boolean isInternalUser = true;
        //set of ids related to the current user
        Set<Id> recordIdsAccess = new Set<Id>();

        //map of String and setIds
        Map<String, Object> recordAccessMap = new Map<String, Object>();

        User u = [SELECT Id, Username, ContactId, Profile.Name, Profile.Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        if(String.isNotBlank(u.ContactId)){
            isInternalUser = false;

            List<Enrollment__c> enrollmentIds = [SELECT Id, Delegate_Name__c, Training_Event__r.Tutor_User_Id__c, Training_Event__r.Tutor_2nd_User_Id__c,
            Training_Event__r.Tutor_3rd_User_Id__c, Training_Event__r.Tutor_4th_User_Id__c, Training_Event__r.Tutor_5th_User_Id__c, Training_Event__c 
            FROM Enrollment__c WHERE Community_User_My_List_View_Toggle__c = true AND Available_In_Portal__c = true];

           
            for(Enrollment__c e : enrollmentIds){
                //give access to profile of my instructing tutor
                recordIdsAccess.add(e.Training_Event__r.Tutor_User_Id__c);
                recordIdsAccess.add(e.Training_Event__r.Tutor_2nd_User_Id__c);
                recordIdsAccess.add(e.Training_Event__r.Tutor_3rd_User_Id__c);
                recordIdsAccess.add(e.Training_Event__r.Tutor_4th_User_Id__c);
                recordIdsAccess.add(e.Training_Event__r.Tutor_5th_User_Id__c);

                //give access to my enrollment I'm attending / I'm instructing
                recordIdsAccess.add(e.Id);

                if(u.Profile.Name == Label.BSIUserSettings_ProfileNameTutor){

                    //give access to Training Event where tutor is instructing
                    recordIdsAccess.add(e.Training_Event__c);
                
                    //give access to User Profile page of the own Tutor
                    recordIdsAccess.add(u.Id);


                }

            }

            //give access to surveys to the tutor
            if(u.Profile.Name == Label.BSIUserSettings_ProfileNameTutor){
                List<Survey__c> surveys = [SELECT Id, Community_Tutor_List_View_Toggle__c, Community_2nd_Tutor_List_View_Toggle__c FROM Survey__c 
                                            WHERE Community_Tutor_List_View_Toggle__c = true OR Community_2nd_Tutor_List_View_Toggle__c = true];
                for(Survey__c survey : surveys){
                    recordIdsAccess.add(survey.Id);
                } 
            }

            //add training events for tutor without enrollments linked to that training event record
            if(u.Profile.Name == Label.BSIUserSettings_ProfileNameTutor){
                recordIdsAccess.addall(new Map<Id, Training_Event__c>([SELECT Id FROM Training_Event__c WHERE Community_User_My_List_View_Toggle__c = true]).keySet());
            }
        }

        recordAccessMap.put(IS_INTERNAL_USER, isInternalUser);
        recordAccessMap.put(RECORD_ID_ACCESS, recordIdsAccess);

        return recordAccessMap;

    }

    /**
     * Get footer links depending on the user's country
     * 
     */
    @AuraEnabled(cacheable=true)
    public static String getFooterLinks(){
        List<FooterLink> footerlinksList = new List<FooterLink>();

        User u = [SELECT Id, LocaleSidKey, Portal_User_Translation_Country__c FROM User WHERE Id = :UserInfo.getUserId()];
        String countryCode = u.Portal_User_Translation_Country__c;

        System.debug(countryCode.substringAfter('_'));
        System.debug(countryCode.substringBefore('_'));
        

        TrainingBookingUtilities.Configuration config = new TrainingBookingUtilities.Configuration();
        //System.debug(config);
        //TrainingBookingUtilities.Country selectedCountry = new TrainingBookingUtilities.Country(config.supportedCountries.get(localeKey.substringBefore('_').toUpperCase()), localeKey.substringBefore('_').toUpperCase());
        //if(localeKey.substringAfter('_') != null){
        TrainingBookingUtilities.Country selectedCountry = new TrainingBookingUtilities.Country(config.supportedCountries.get(countryCode.substringAfter('_')), countryCode.substringBefore('_'), '');
        //}
        System.debug(selectedCountry);
        System.debug(selectedCountry.accessibilityUrl);

        footerlinksList.add(new FooterLink(Label.TrainingBookingPrivacyLink, selectedCountry.privacyUrl));
        footerlinksList.add(new FooterLink(Label.TrainingBookingCookieLink, selectedCountry.cookieUrl));
        footerlinksList.add(new FooterLink(Label.CLP_TermsOfUse, selectedCountry.termsUrl));
        footerlinksList.add(new FooterLink(Label.TrainingBookingAccessibilityLink, selectedCountry.accessibilityUrl));

        return JSON.serialize(footerlinksList);
    }
}