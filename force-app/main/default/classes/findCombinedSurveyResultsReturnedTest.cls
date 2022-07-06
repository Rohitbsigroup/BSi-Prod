/********************************************************************
 * findCombinedSurveyResultsReturned_Test
 *
  *Test class to test menthods defined in class findCombinedSurveyResultsReturned 
 * Author:Vimlesh Azad
 * Created: 14 July 2016
 * Updated : Vimlesh on 02 Aug 2016 add more code coverage for survey comments, translation name
 * Updated : Vimlesh on 08 Aug 2016 add more code coverage for events without survey data - Now coverage is 100%
 * Updated : JS 2022/04/13 Most of the code was commented out so no code coverage! re-written and now 100%
 * 
 ********************************************************************/

@isTest(SeeAllData=True)
public class findCombinedSurveyResultsReturnedTest  
{
        public static testMethod void myTestMethod()
        {
             
        //JS new Set up test data  Master Venue, Training Venue, account, product, instructor, event, translation
        Account acc = bg_TrainingUnitTestHelper.createAccount('AName','GB');
        Training_Venue__c masterVenue = bg_TrainingUnitTestHelper.createTrainingVenue('Master Venue', 'GBP');
        Training_Venue__c tv = bg_TrainingUnitTestHelper.createTrainingVenue(masterVenue,'Training Venue', 'GBP');
        Product2 product = bg_TrainingUnitTestHelper.GetProductTraining('Test Course','Icode1,Icode2');
        Contact trainer = bg_TrainingUnitTestHelper.GetContactTraining('Trainer','Icode1,Icode2', masterVenue.id);
        Training_Event__c te = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id); 
        Training_Event__c te2 = bg_TrainingUnitTestHelper.createTrainingEvent(tv,'GBP', 5, product, Date.today()+5,trainer.Id);
        Training_Translations__c Trans1 = bg_TrainingUnitTestHelper.GetTrainingTranslation('UK (English)', 'GBP');
        Enrollment__c enr = bg_TrainingUnitTestHelper.GetEnrolment('GB', trainer, Trans1, te, 'Booked');
        Enrollment__c enr2 = bg_TrainingUnitTestHelper.GetEnrolment('GB', trainer, Trans1, te, 'Booked');

        
        //Create test surveys
                   
            Survey__c surv1 = new Survey__c ();
            surv1.Enrollment__c = enr.Id;
            surv1.Training_Event__c = te.Id;
            surv1.RecordTypeId = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Training Survey').getRecordTypeId();
            surv1.Survey_Type__c = 'Training Survey';
            surv1.Tutor_1_Delivery__c = 8;                        
            surv1.Tutor_1_s_competence__c  =  8;                      
            surv1.Net_Promoter_Score__c  =  8; 
            surv1.Training_Venue__c  =  8;      
            surv1.Training_Course_Expectations__c = 8;
            surv1.Anything_Else_Comments__c = 'blah blah blah';
            insert surv1;
            
            Survey__c surv2 = new Survey__c ();
            surv2.Enrollment__c = enr2.Id;
            surv2.Training_Event__c = te.Id;
            surv2.RecordTypeId = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Training Survey').getRecordTypeId();
            surv2.Survey_Type__c = 'Training Survey';
            surv2.Tutor_1_Delivery__c = 4;                       
            surv2.Tutor_1_s_competence__c  =  4;                      
            surv2.Net_Promoter_Score__c  =  4; 
            surv2.Training_Venue__c  =  4; 
            surv2.Training_Course_Expectations__c  =  4;          
            insert surv2;
            
            System.debug('## Event Id' + te.Id);  
            
            //Test
            Test.startTest();
            findCombinedSurveyResultsReturned surveyData = new findCombinedSurveyResultsReturned();   
            surveyData.TrainingEventId_S = te.Id;
            
            system.debug('##TrainingEventId_S get: ' + surveyData.getTrainingEventId_S());
            system.debug('##TrainingEventId_S: ' + surveyData.TrainingEventId_S);
           
            surveyData.setTrainingEventId_S(te.Id);
            surveyData.getTrainingTranslationName();
            surveyData.getTrainingTranslations();
            
            System.debug('### TrainingTranslationName '+ surveyData.TrainingTranslationName);
            System.debug('### BlnSurveysReturned '+ surveyData.BlnSurveysReturned); 
            
            surveyData.Summaries = surveyData.getCombinedSurveyResults();
            
            

            System.debug('### Summaries[0].DeliveryScore' + surveyData.Summaries[0].DeliveryScore);
            System.debug('### Summaries[0].CompetenceScore' + surveyData.Summaries[0].CompetenceScore);
            System.debug('### Summaries[0].NetPromoterScore' + surveyData.Summaries[0].NetPromoterScore);
            System.debug('### Summaries[0].OverallScore' + surveyData.Summaries[0].OverallScore);                     
            System.debug('### Summaries[0].TrainingVenueScore' + surveyData.Summaries[0].TrainingVenueScore);

           
            surveyData.getSurveyComments();
            System.debug('### blnDelegateComments' + surveyData.blnDelegateComments);
            
            findCombinedSurveyResultsReturned withoutSurveyData = new findCombinedSurveyResultsReturned();   
            withoutSurveyData.TrainingEventId_S = te2.Id; // (Without Survey)
            withoutSurveyData.setTrainingEventId_S(te2.Id);
            withoutSurveyData.getTrainingTranslationName();
            withoutSurveyData.getTrainingTranslations();
            withoutSurveyData.Summaries = withoutSurveyData.getCombinedSurveyResults();
            System.debug(withoutSurveyData.BlnSurveysReturned); 
            
                     
            Test.stopTest();
            

        }
}