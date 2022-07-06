/********************************************************************
 * findCombindedSurveyResultsReturned
 *
  *controller an updated version of findCombindedSurveyResults to use with component to embed in vf email template
 *here to have a method that returns the data so test can call it
 *it may stll require passing the Training Event ID to the method
 *due to issue found trying to test class for component in email template, may want instead to test via a page
 *
 * Author: Chris Moriarty
 * 
 * Updated : Vimlesh on 14th July to fix translations from Master venue
 * Updated : Vimlesh on 02 Aug 2016 add more code  for survey comments 
 * Updated : Vimlesh on 08 Aug 2016 add more code coverage in test class for events without survey data - Now coverage is 100%
 * 2022/04/14 JS    Refreshed code from UAT and adjusted to pick up only new surveys in order to feed to Portal screen
 * 2022/06/08 JS    Added in section on Platform for VILT
 ********************************************************************/

public with sharing class findCombinedSurveyResultsReturned 
{

    public Summary[] Summaries { get; set; }
    public Boolean BlnSurveysReturned  {get; set;}
    public Boolean BlnDelegateComments  {get; set;} // added 02 Aug to capture if comments exists on survey
    public String TrainingTranslationName  {get; set;}
    public Id TrainingEventId_S; 
    Public ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'');
    public id getTrainingEventId_S()
    {
         return TrainingEventId_S; 
    } 
    
    //Following is the solution for record_Id null in the constructor
    public void setTrainingEventId_S(id s)
    {
        if (s!=null)
        {
            TrainingEventId_S = s;
            getCombinedSurveyResults();
            getTrainingTranslationName();
            getSurveyComments ();   // Added on 02 Aug 2016 by Vimlesh -  Method  return boolean value if no comments are provided by delegates 
            //Checks if anything in the list Summaries
            if(Summaries.isEmpty()) 
            {
                BlnSurveysReturned  = False;
            }
            if (!Summaries.isEmpty()) 
            {
                BlnSurveysReturned  = true;
            }   
        }
    }   
    
    // need to get the training translation name for getting translation
    Public String  getTrainingTranslationName()
    { 
        list<Training_Event__c> TrainingEvent =
        [
        Select
        Training_Venue__r.Training_Office__r.Training_Translations__r.Name
        From
        Training_Event__C
        Where
        Id = :TrainingEventId_S Limit 1
        ];
        TrainingTranslationName  = String.valueOf(TrainingEvent[0].Training_Venue__r.Training_Office__r.Training_Translations__r.Name);
       
        Return TrainingTranslationName;
    }
    
    Public List<Training_Translations__c> getTrainingTranslations()
    {
        List<Training_Translations__c> TrainingTranslations;
        TrainingTranslations = 
        [
        Select
        No_Surveys__c,
        Number_of_Surveys__c,
        Tutor_Scores__c,
        Tutor_competence__c,
        Tutor_Delivery__c,
        Event_Scores__c,
        How_likely_are_you_to_recommend_BSI__c,
        Course_Overall__c,
        Training_Venue__c,
        Platform__c, 
        Comments__c 
        From Training_Translations__c WHERE Name = :TrainingTranslationName  
        ];
            return TrainingTranslations;    
    }
    
   
    public List<Summary> getCombinedSurveyResults()
    {
       
        AggregateResult[] results = 
        [          
        SELECT Training_Event__c,
        Count(Name) SurveysReturned, 
        Avg(Tutor_1_Delivery__c) DeliveryScore ,
        Avg(Tutor_1_s_competence__c) CompetenceScore,
        Avg(Net_Promoter_Score__c)  NetPromoterScore,
        Avg(Training_Venue__c)  TrainingVenueScore,
        Avg(The_Virtual_Training_Platform__c)  PlatformScore,
        Avg(Training_Course_Expectations__c)  OverallScore
        FROM Survey__c WHERE Training_Event__r.Id = :TrainingEventId_S AND Survey_Type__c = 'Training Survey' GROUP BY Training_Event__c,Training_Event__r.Training_Venue__r.Name Limit 1

        
        ];
        Summaries = new List<Summary>();
        for (AggregateResult ar : results) 
        {
            Summaries.add(new Summary(ar));
        }
        List<Summary> CombinedSurveyResults;
        CombinedSurveyResults = Summaries;
        Return CombinedSurveyResults;

   } 
    
   // Added on 02 Aug 2016 by Vimlesh -  Method  return boolean value if no comments are provided by delegates  , this will help to exclude comments section from tutor survey results email
   public void getSurveyComments()
   {
       blnDelegateComments = false;
       Survey__c[] surveys = 
           [          
               SELECT Anything_Else_Comments__c  
               FROM Survey__c WHERE Training_Event__r.Id = :TrainingEventId_S AND Survey_Type__c = 'Training Survey'        
           ];
       for (Survey__c comment : surveys) 
       {
           if(String.valueOf(comment.Anything_Else_Comments__c) !=  null)
           {
               blnDelegateComments = true;
           }
        }               
   } 
   
   // wrapper class to hold aggregate data
   public class Summary 
   {
       public Integer SurveysReturned{ get; private set; }
       public Decimal DeliveryScore { get; private set; }
       public Decimal CompetenceScore { get; private set; }        
       public Decimal NetPromoterScore { get; private set; }
       public Decimal TrainingVenueScore { get; private set; }
       public Decimal PlatformScore { get; private set; }
       public Decimal OverallScore { get; private set; }
       
       public Summary(AggregateResult ar) 
       {
           SurveysReturned = (Integer) ar.get('SurveysReturned');
           DeliveryScore = (Decimal) ar.get('DeliveryScore');
           DeliveryScore = DeliveryScore.SetSCale(2); 
           OverallScore  = (Decimal) ar.get('OverallScore');
           OverallScore  = OverallScore.SetSCale(2);
           NetPromoterScore  = (Decimal) ar.get('NetPromoterScore');
           NetPromoterScore  = NetPromoterScore.SetSCale(2);       
           TrainingVenueScore = (Decimal) ar.get('TrainingVenueScore');
           TrainingVenueScore  = TrainingVenueScore.SetSCale(2); 
           PlatformScore = (Decimal) ar.get('PlatformScore');
           PlatformScore  = PlatformScore.SetSCale(2);       
           CompetenceScore  = (Decimal) ar.get('CompetenceScore');
           CompetenceScore  = CompetenceScore.SetSCale(2);
       }
   }
}