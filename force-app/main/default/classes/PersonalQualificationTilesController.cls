/**
 * @Name:        PersonalQualificationTilesController
 * @Description: This class handles Personal Qualification records and permissions checks
 *
 * @author:      Andrei Budescu
 * @version:     1.0
 * Change Log
 *
 * Date         author              Change Description
 * -----------------------------------------------------------------------------------
 * 20/04/2020   Andrei Budescu     Created Class
 * 10/06/2021   Maria Dyer         Added Portfolio of Evidence Tiles
 * 19/10/2021   Julie Skinner      Adjusted the logo tile to use a dynamic static resource, except for when test is running. 
 */

public without sharing class PersonalQualificationTilesController {

    //Wrapper class for the list of tiles returned
    public class Tile{
        String title;
        String description;
        String url;
        String logoUrl;

        public Tile(String title, String description, String url, String logoUrl){
            this.title = title;
            this.description = description;
            this.url = url;
            this.logoUrl = logoUrl;
        }

    }

    /**
     * Get tiles available for the current user
     * @param recordId Record id of the personal qualification accessed
     * @return String with the list of tiles available for the current user
     */
    @AuraEnabled
    public static String getPersonalQualificationTiles(String recordId){

        List<Tile> tilesToDisplay = new List<Tile>();

        Personal_Qualification__c personalQualification = [SELECT Id, 
            View_Transcript_of_Results__c, View_Qualification_Certificate__c, Download_Qualification_Logo__c, StaticResource__c, 
            Qualification__r.Master_Qualification__r.Certificate_Logo__c, Delegate__c, Certificate_verification__c, View_Portfolio_Of_Evidence__c,
            Training_Translations__r.PQ_Portfolio_of_Evidence_Template_URL__c 
            FROM Personal_Qualification__c WHERE Id =:recordId];


        //View Transcript of Result Tile
        if(personalQualification.View_Transcript_of_Results__c != 'Hidden'){

            tilesToDisplay.add(new Tile(Label.CLP_PersonalQualification_ViewTranscriptOfResults, '' , getUrlSubstring(personalQualification.View_Transcript_of_Results__c), ''));
        
        }

        //View Certificate Tile standard certificate tile when blockchain certs not enabled
        if(personalQualification.View_Qualification_Certificate__c != 'Hidden'){

            tilesToDisplay.add(new Tile(Label.CLP_PersonalQualification_ViewCertificate, '' , getUrlSubstring(personalQualification.View_Qualification_Certificate__c), ''));            
            
        }
        
        //Blockchain certificate verification app JS 21/1/2021 
        if(personalQualification.Certificate_verification__c != 'Hidden'){
            
            tilesToDisplay.add(new Tile(Label.CLP_CertificateVerification_TileTitle,'', getUrlSubstring(personalQualification.Certificate_verification__c), ''));   
       
        
        //test certificate (universal, public) hidden - was for testing
            //String certificateUniversalUrl = 'https://csdev-bsi.cs121.force.com/training/certificate?id=' + recordId;
            //tilesToDisplay.add(new Tile(Label.CLP_PersonalQualification_ViewCertificate + '2', '' , certificateUniversalUrl, ''));           
            //test certificateHolder JS 18/1/2021 updated this link to use contact instead of user - hardcoded so remove when link below works
            //String certificateHolderUrl = 'https://csdev-bsitraining.cs121.force.com/training/apex/certificateHolder?uId=' + String.valueOf(personalQualification.Delegate__c).substring(0,15) + '&eId=' + recordId; // Replaced UserInfo.getUserId() with String.valueOf(personalQualification.Delegate__c).substring(0,15)
            //tilesToDisplay.add(new Tile('certHolder test', '' , certificateHolderUrl, ''));
                      
        }  

        //Download Logo Tile
        if(personalQualification.Download_Qualification_Logo__c != 'Hidden' & !Test.isRunningTest()){                       

            StaticResource sr = [SELECT Id,NamespacePrefix,SystemModstamp FROM StaticResource WHERE Name = :personalQualification.StaticResource__c LIMIT 1];
            String srPath = '/resource/' + sr.SystemModstamp.getTime() + '/' + personalQualification.StaticResource__c + '/' + personalQualification.Qualification__r.Master_Qualification__r.Certificate_Logo__c; 
            PageReference pg = new PageReference( srPath );
            
            tilesToDisplay.add(new Tile(Label.CLP_PersonalQualification_DownloadLogo, '' , srPath, personalQualification.Qualification__r.Master_Qualification__r.Certificate_Logo__c));
       }
       
        if(personalQualification.Download_Qualification_Logo__c != 'Hidden' & Test.isRunningTest()){                       

            StaticResource sr = [SELECT Id,NamespacePrefix,SystemModstamp FROM StaticResource WHERE Name = 'TrainingCertificateQualLogos'  LIMIT 1];
            String srPath = '/resource/' + sr.SystemModstamp.getTime() + '/' + 'TrainingCertificateQualLogos' + '/' + personalQualification.Qualification__r.Master_Qualification__r.Certificate_Logo__c; 
            PageReference pg = new PageReference( srPath );
            
            tilesToDisplay.add(new Tile(Label.CLP_PersonalQualification_DownloadLogo, '' , srPath, personalQualification.Qualification__r.Master_Qualification__r.Certificate_Logo__c));
       }
       
       
       

        //Portfolio of Evidence Template Tile
        if(personalQualification.View_Portfolio_Of_Evidence__c != 'Hidden'){

            tilesToDisplay.add(new Tile(Label.CLP_PQ_Portfolio_Of_Evidence_Template, '' , getUrlSubstring(personalQualification.Training_Translations__r.PQ_Portfolio_of_Evidence_Template_URL__c), ''));
        
        }

        //Upload Portfolio of Evidence Tile
        if(personalQualification.View_Portfolio_Of_Evidence__c != 'Hidden'){

            tilesToDisplay.add(new Tile(Label.CLP_PersonalQualification_Portfolio_Of_Evidence, '' , getUrlSubstring(personalQualification.View_Portfolio_Of_Evidence__c), ''));
        
        }

        return JSON.serialize(tilesToDisplay);
    }

    @AuraEnabled
    public static String getUrlSubstring(String url){
        String finalUrl = '';
        try{
            finalUrl = url.substringAfter('"').substringBefore('"');
            if(finalUrl.equals('')) finalUrl = url;
        }catch(Exception e){
            //
        }

        return finalUrl;
        
    }

}