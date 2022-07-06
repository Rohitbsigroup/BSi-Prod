/**
 * @Name:        EnrollmentTilesController
 * @Description: This class handles Enrollment records and permissions checks
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 20/04/2020   Andrei Budescu      Created Class
 * 28/07/2020   Julie Skinner       Added Virtual Classroom tile
 * 18/05/2021   Eugene Nadudik      Removed clicked tile custom label check
 */

public without sharing class EnrollmentTilesController {

    public class Tile{
        String title;
        String description;
        String url;
        Boolean isClicked;
        String sObjectField;

        public Tile(String title, String description, String url, Boolean isClicked, String sObjectField){
            this.title = title;
            this.description = description;
            this.url = url;
            this.isClicked = isClicked;
            this.sObjectField = sObjectField;
        }

    }

    //check what tiles are available for the user
    /**
   * Get tiles available for the user
   *
   * @param recordId Record id of the enrollment accessed
     *  
     * @return String with list of tiles available
   */
    @AuraEnabled
    public static String getEnrollmentTiles(String recordId){

        List<Tile> tilesToDisplay = new List<Tile>();

        Enrollment__c enrollment = [SELECT Id, 
            About_My_Course__c, Green_Tile_About_My_Course__c, 
            Pre_Course_Questionnaire__c, Green_Tile_Pre_Course_Questionnaire__c, 
            Pre_Course_Learning__c, Green_Tile_Pre_Course_Learning__c, 
            Course_Materials__c, Green_Tile_Course_Materials__c, 
            Extra_Resources__c, Green_Tile_Extra_Resources__c, 
            Access_My_Course__c, Green_Tile_Access_My_Course__c, 
            My_Exam__c, Green_Tile_My_Exam__c, 
            Post_Course_Questionnaire__c, Green_Tile_Post_Course_Questionnaire__c, 
            My_Certificate__c, Green_Tile_My_Certificate__c,
            Virtual_Classroom__c, Green_Tile_Virtual_Classroom__c, //JS added
            Certificate_verification__c, Green_Tile_Certificate_Verification__c, //JS added
            Online_Training_Expiry_Date__c, Online_Training_Attempts__c, Litmos_Details_Emailed__c ,
            Training_Event__r.Course__c
            FROM Enrollment__c WHERE Id =:recordId];
        System.debug(enrollment.Pre_Course_Questionnaire__c);
        System.debug(enrollment.Id);
        
        //about my course tile
        if(enrollment.About_My_Course__c != 'Hidden'){

            tilesToDisplay.add(new Tile(Label.CLP_AboutMyCourse_TileTitle, Label.CLP_AboutMyCourse_TileDescription , getUrlSubstring(enrollment.About_My_Course__c), enrollment.Green_Tile_About_My_Course__c, String.valueOf(Enrollment__c.Green_Tile_About_My_Course__c.getDescribe().getSObjectField())));
        
        }
        //pre course questionnaire tile
        if(enrollment.Pre_Course_Questionnaire__c != 'Hidden'){
            
            tilesToDisplay.add(new Tile(Label.CLP_MyPreCourseQuestionnaire_TileTitle, Label.CLP_MyPreCourseQuestionnaire_TileDescription, getUrlSubstring(enrollment.Pre_Course_Questionnaire__c), enrollment.Green_Tile_Pre_Course_Questionnaire__c, String.valueOf(Enrollment__c.Green_Tile_Pre_Course_Questionnaire__c.getDescribe().getSObjectField())));

        }
        //pre course learning tile
        if(enrollment.Pre_Course_Learning__c != 'Hidden'){
            Integer materialsListCount = [SELECT COUNT()
                        FROM Material_List__c 
                        WHERE Product__c = :enrollment.Training_Event__r.Course__c 
                        AND Type__c = 'Pre-Course Learning' 
                        AND Status__c != 'Archived'];
            if(materialsListCount > 0){
                tilesToDisplay.add(
                    new Tile(
                        Label.CLP_PreCourseLearningMaterials_TileTitle, 
                        Label.CLP_PreCourseLearningMaterials_TileDescription, 
                        getUrlSubstring(enrollment.Pre_Course_Learning__c), 
                        enrollment.Green_Tile_Pre_Course_Learning__c, 
                        String.valueOf(Enrollment__c.Green_Tile_Pre_Course_Learning__c.getDescribe().getSObjectField())));
            }
        }                
        //virtual classroom tile JS added
        if(enrollment.Virtual_Classroom__c != 'Hidden'){

            tilesToDisplay.add(new Tile(Label.CLP_VirtualClassroom_TileTitle, Label.CLP_VirtualClassroom_TileDescription, getUrlSubstring(enrollment.Virtual_Classroom__c), enrollment.Green_Tile_Virtual_Classroom__c, String.valueOf(Enrollment__c.Green_Tile_Virtual_Classroom__c.getDescribe().getSObjectField())));

        }
        //course materials tile
        if(enrollment.Course_Materials__c != 'Hidden'){
                tilesToDisplay.add(
                    new Tile(Label.CLP_CourseMaterials_TileTitle, 
                                Label.CLP_CourseMaterials_TileDescription, 
                                getUrlSubstring(enrollment.Course_Materials__c), 
                                enrollment.Green_Tile_Course_Materials__c, 
                                String.valueOf(Enrollment__c.Green_Tile_Course_Materials__c.getDescribe().getSObjectField())));
        }
        //extra resources tile
        if(enrollment.Extra_Resources__c != 'Hidden'){
            Integer materialsListCount = [SELECT COUNT()
                        FROM Material_List__c 
                        WHERE Product__c = :enrollment.Training_Event__r.Course__c 
                        AND Type__c = 'Extra Resources' 
                        AND Status__c != 'Archived'];
            if(materialsListCount > 0){
                tilesToDisplay.add(
                    new Tile(Label.CLP_ExtraResources_TileTitle, 
                                Label.CLP_ExtraResources_TileDescription, 
                                getUrlSubstring(enrollment.Extra_Resources__c), 
                                enrollment.Green_Tile_Extra_Resources__c, 
                                String.valueOf(Enrollment__c.Green_Tile_Extra_Resources__c.getDescribe().getSObjectField())));
            }
        }
        //access my course tile
        if(enrollment.Access_My_Course__c != 'Hidden'){

            tilesToDisplay.add(new Tile(Label.CLP_AccessMyCourse_TileTitle, Label.CLP_AccessMyCourse_TileDescription, getUrlSubstring(enrollment.Access_My_Course__c), enrollment.Green_Tile_Access_My_Course__c, String.valueOf(Enrollment__c.Green_Tile_Access_My_Course__c.getDescribe().getSObjectField())));

        }
        //my exam tile
        if(enrollment.My_Exam__c != 'Hidden'){

            tilesToDisplay.add(new Tile(Label.CLP_MyExam_TileTitle, Label.CLP_MyExam_TileDescription, getUrlSubstring(enrollment.My_Exam__c), enrollment.Green_Tile_My_Exam__c, String.valueOf(Enrollment__c.Green_Tile_My_Exam__c.getDescribe().getSObjectField())));

        }
        //post course questionnaire tile
        if(enrollment.Post_Course_Questionnaire__c != 'Hidden'){

            tilesToDisplay.add(new Tile(Label.CLP_MyPostCourseQuestionnaire_TileTitle, Label.CLP_MyPostCourseQuestionnaire_TileDescription, getUrlSubstring(enrollment.Post_Course_Questionnaire__c), enrollment.Green_Tile_Post_Course_Questionnaire__c, String.valueOf(Enrollment__c.Green_Tile_Post_Course_Questionnaire__c.getDescribe().getSObjectField())));

        }
        //my certificate tile
        if(enrollment.My_Certificate__c != 'Hidden'){

            tilesToDisplay.add(new Tile(Label.CLP_MyCertificate_TileTitle, Label.CLP_MyCertificate_TileDescription, getUrlSubstring(enrollment.My_Certificate__c), enrollment.Green_Tile_My_Certificate__c, String.valueOf(Enrollment__c.Green_Tile_My_Certificate__c.getDescribe().getSObjectField())));

        }
        //certificate verification holder app tile
        if(enrollment.Certificate_verification__c != 'Hidden'){

            tilesToDisplay.add(new Tile(Label.CLP_CertificateVerification_TileTitle, Label.CLP_CertificateVerification_TileDescription, getUrlSubstring(enrollment.Certificate_verification__c), enrollment.Green_Tile_Certificate_Verification__c, String.valueOf(Enrollment__c.Green_Tile_Certificate_Verification__c.getDescribe().getSObjectField())));

        }
        
        return JSON.serialize(tilesToDisplay);
        
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
        try{
            finalUrl = url.substringAfter('"').substringBefore('"');
            finalUrl = finalUrl.replace('&amp;', '&');
            if(finalUrl.equals('')) finalUrl = url;
        }catch(Exception e){
            //
        }

        return finalUrl;
        
    }

    /**
   * Updates the tile clicked on the enrollment record - change colour to green
   *
   * @param recordId Record id of the current enrollment
     * @param tileCheckbox API Name of the checkbox field of the tile clicked
     *  
     * @return String with the name of the tile clicked
   */
    @AuraEnabled
    public static String updateGreenTile(String recordId, String tileCheckbox){

        String tileClickedFieldName = '';

        Enrollment__c enr = [SELECT Id, 
            About_My_Course__c, Green_Tile_About_My_Course__c, 
            Pre_Course_Questionnaire__c, Green_Tile_Pre_Course_Questionnaire__c, 
            Pre_Course_Learning__c, Green_Tile_Pre_Course_Learning__c, 
            Course_Materials__c, Green_Tile_Course_Materials__c, 
            Extra_Resources__c, Green_Tile_Extra_Resources__c, 
            Access_My_Course__c, Green_Tile_Access_My_Course__c, 
            My_Exam__c, Green_Tile_My_Exam__c, 
            Post_Course_Questionnaire__c, Green_Tile_Post_Course_Questionnaire__c, 
            My_Certificate__c, Green_Tile_My_Certificate__c,
            Virtual_Classroom__c, Green_Tile_Virtual_Classroom__c, //JS added 
            Certificate_verification__c, Green_Tile_Certificate_Verification__c //JS added 
            FROM Enrollment__c WHERE Id =:recordId];


        //check if field is updateable
        Map<String, Schema.SObjectField> mapObject = Schema.SObjectType.Enrollment__c.fields.getMap();
        if(mapObject.get(tileCheckbox).getDescribe().isUpdateable()) {
            enr.put(tileCheckbox, true);
            update enr;
        }

        System.debug('Label of tile clicked: ' + mapObject.get(tileCheckbox).getDescribe().getLabel());
        String tileClicked = mapObject.get(tileCheckbox).getDescribe().getLabel().substringAfter('- ');
        System.debug(tileClicked);
        // EN - 19/05/2021 - Removed clicked tile custom label check
        // if(Label.CLP_PreCourseLearningMaterials_TileTitle.containsIgnoreCase(tileClicked) || Label.CLP_ExtraResources_TileTitle.containsIgnoreCase(tileClicked)){
        //     tileClickedFieldName = tileClicked;
        // }
        return tileClicked;

    }



}