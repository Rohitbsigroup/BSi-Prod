/**
 * @Name:        RecommendationUserController
 * @Description: Apex Controller class for the recommendationUser.cmp
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 20/04/2020   Andrei Budescu     Created Class
 * 23/04/2021   Eugene Nadudik     Added sorting by Order_c field
 */
global without sharing class RecommendationUserController {

    //Wrapper class for the tiles displayed on the enrollment record
    global class Tile implements Comparable{
        String title;
        String description;
        String stage;
        String type;
        String colour;
        String url;
        Decimal order;

        public Tile(String title, String url, String description, String stage, String type, String colour, Decimal order){
            this.title = title;
            this.url = url;
            this.description = description;
            this.stage = stage;
            this.type = type;
            this.colour = colour;
            this.order = order;
        }

        // Compare recommendations by order -> type -> stage -> title
        global Integer compareTo(Object compareTo) {
            // Cast argument to OpportunityWrapper
            Tile compareToTile = (Tile)compareTo;
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;

            System.debug(compareToTile);
            if (order != null && order > compareToTile.order) {
                returnValue = 1;
            } else if(order != null && order < compareToTile.order) {
                returnValue = -1;
            } else {
                if (type > compareToTile.type) {
                // Set return value to a positive value.
                returnValue = 1;
                } else if (type < compareToTile.type) {
                    // Set return value to a negative value.
                    returnValue = -1;
                } else { 
                    //sort by stage
                    if(stage=='Understand' && compareToTile.stage =='Implement'){
                        returnValue = - 1;
                    } else if(stage == 'Understand' && compareToTile.stage == 'Prove it’s working'){
                        returnValue = -1;
                    } else if(stage == 'Understand' && compareToTile.stage == 'Build resilience'){
                        returnValue = -1;
                    } else if(stage == 'Implement' && compareToTile.stage == 'Understand'){
                        returnValue = 1;
                    } else if(stage == 'Implement' && compareToTile.stage =='Prove it’s working'){
                        returnValue = - 1; 
                    } else if(stage == 'Implement' && compareToTile.stage =='Build resilience'){
                        returnValue = - 1; 
                    } else if(stage == 'Prove it’s working' && compareToTile.stage == 'Understand'){
                        returnValue = 1;
                    } else if(stage == 'Prove it’s working' && compareToTile.stage == 'Implement'){
                        returnValue = 1;
                    } else if(stage =='Prove it’s working' && compareToTile.stage == 'Build resilience'){
                        returnValue = -1;
                    } else if(stage == 'Build resilience' && compareToTile.stage == 'Understand'){
                        returnValue = 1;
                    } else if(stage == 'Build resilience' && compareToTile.stage == 'Implement'){
                        returnValue = 1;
                    }   else if(stage == 'Build resilience' && compareToTile.stage =='Prove it’s working'){
                        returnValue = 1;
                    } else{
                        if(title > compareToTile.title){
                            returnValue = 1;
                        } else if (title < compareToTile.title){
                            returnValue = -1;
                        } else {
                            returnValue = 0;
                        }
                    } 
                }
            }
            return returnValue;      
        }

    }

    /**
     * Get List with the recommendation tiles
     *
     * @param recordId Record id of the enrollment accessed
     *
     * @return String with list of recommendation tiles
     */
    @AuraEnabled
    public static String getRecommendationTiles(String recordId){

        System.debug('Record id of enrollment: ' + recordId);


        //1) Query parent-Course (Product2.Id) based on Enrolment__c.Id
            //enrollment and product linked
        Enrollment__c enr = [SELECT Id, Training_Event__r.Course__c FROM Enrollment__c WHERE Id =:recordId LIMIT 1];
        
            //product details and recommendation records
        List<Product2> products = [SELECT Id, Name, Online_Booking__c, Course_Details_Text__c, Product_Name_Local__c,
        (SELECT Id, Qualification__c, Qualification__r.Name, Qualification__r.Website_Link__c, 
        Qualification__r.Title__c, Qualification__r.Status__c, Qualification__r.Type__c, Qualification__r.Level__c, Qualification__r.Description__c FROM Qualification_Courses__r WHERE Qualification__r.Status__c = 'Active'), 
        
        (SELECT Id, Name, Product_To_Recommend__c, Product_To_Recommend__r.Product_Name_Local__c, Product_To_Recommend__r.Online_Booking_Link__c, 
        Product_To_Recommend__r.Course_Details_Text__c, Product_To_Recommend__r.Training_Stage__c, Colour_Scheme__c, Type__c, Order__c FROM Learning_Recommendations__r WHERE Product_To_Recommend__r.isActive=true ) 
        FROM Product2 WHERE ID = :enr.Training_Event__r.Course__c];
        
        
        Map<String, Tile> tilesMap = new Map<String, Tile>();

            //add tiles recomm courses - product.Id key
        for(Product2 product : products){
            //2) Query all Learning_Recommendations__r linked to the provided Product2.Id -> create Set<Id> of recommended Courses
            for(Recommendation__c recommendation : product.Learning_Recommendations__r){
                tilesMap.put(recommendation.Product_To_Recommend__c, new Tile(recommendation.Product_To_Recommend__r.Product_Name_Local__c, recommendation.Product_To_Recommend__r.Online_Booking_Link__c, recommendation.Product_To_Recommend__r.Course_Details_Text__c, recommendation.Product_To_Recommend__r.Training_Stage__c, recommendation.Type__c, recommendation.Colour_Scheme__c, recommendation.Order__c));
            }
            //3) Query all Qualification_Courses__r contained in Set<It>recommended Courses -> create Set<Id> of qualification Ids
            for(Qualification_Course__c qualificationCourse : product.Qualification_Courses__r){
                tilesMap.put(qualificationCourse.Qualification__c, new Tile(qualificationCourse.Qualification__r.Name, qualificationCourse.Qualification__r.Website_Link__c, qualificationCourse.Qualification__r.Description__c, '', 'Qualification', Label.CLP_Qualification_Recommendation_Colour, null));
            }
        }

        //4a) Exclude all completed Qualifications for this Delegate [via Enrolments__r.Personal_Qualifications__r.Qualification__c from step 3 qualifications]
        User user = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        
        List<Tile> recommendedTiles = new List<Tile>();

        try{
            Contact contact = [SELECT Id, (Select Id, Qualification__c FROM Personal_Qualifications__r), (Select Id, Training_Event__r.Course__c FROM Enrollments__r) FROM Contact WHERE Id =:user.ContactId];
            //loop and remove from the tiles map the personal qualifications - qualification__c key
            for(Personal_Qualification__c qualificationId : contact.Personal_Qualifications__r){
                if(tilesMap.containsKey(qualificationId.Qualification__c)){
                    tilesMap.remove(qualificationId.Qualification__c);
                }
            }

            //4b) Exclude all completed Courses for this Delegate [via Enrolments__r.Product2.Id from step 2 recommended Courses]
            //System.debug(contact.Enrollments__r[0].Training_Event__r.Course__c);
            //loop and remove from the tiles map the completed courses - Product2.Id key
            for(Enrollment__c enrollmentProduct : contact.Enrollments__r){
                if(tilesMap.containsKey(enrollmentProduct.Training_Event__r.Course__c)){
                    tilesMap.remove(enrollmentProduct.Training_Event__r.Course__c);
                }
            }

            //create list of recommendation tiles
            recommendedTiles = new List<Tile>();
            for(Tile tile : tilesMap.values()){
                recommendedTiles.add(tile);
            }
            
            //order list
            recommendedTiles.sort();
        }catch(Exception e){
            // no enrollments or qualifications related to the user
        }

       
        
        return JSON.serialize(recommendedTiles);
        
       
    }

    @AuraEnabled(cacheable=true)
    public static Training_Translations__c getTrainingTranslation(){
        User u = [SELECT Portal_User_Country__c, Portal_User_Translation_Country__c FROM User WHERE Id = :UserInfo.getUserId()];
        String countryCode = u.Portal_User_Country__c;
    
        if(!String.isBlank(countryCode)){
            Training_Translations__c tt = [SELECT Recommended_Courses__c FROM Training_Translations__c WHERE Country_code__c = :countryCode LIMIT 1];
            return tt;
        }
        return null;
    }
}