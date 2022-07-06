public with sharing class PersonalQualificationHandler {

    public static Boolean isUploadPQCertificatesFirstRun = true;

    public PersonalQualificationHandler(){}
    
    public void onAfterUpdate(Map<Id, Personal_Qualification__c> oldMap, Map<Id, Personal_Qualification__c> newMap){
    
        List<Personal_Qualification__c> pqList = [
            SELECT
                Date_Qualification_Completed__c, Expiry_Date__c, Name, Progress__c, Qualification_Name__c, Show_Certificate_in_Portal__c, Show_Certificate_Holder__c, 
                Training_Translations__r.Client_Learning_Portal_on__c, Training_Translations__r.Certificate_verification__c
            FROM Personal_Qualification__c WHERE Id IN :newMap.keySet()
        ];
        
        //TRACELABS integration
        List<Id> qualificationIdsToUpload = new List<Id>();
        for(Personal_Qualification__c pq : pqList){
            if(
                pq.Progress__c == 'Complete' && 
                pq.Training_Translations__r.Client_Learning_Portal_on__c && 
                pq.Date_Qualification_Completed__c <= Date.today() &&  //JS changed to <= instead of just < on 6/1/22
                pq.Show_Certificate_in_Portal__c &&
                pq.Training_Translations__r.Certificate_verification__c &&
                !pq.Show_Certificate_Holder__c
            ){
                qualificationIdsToUpload.add(pq.Id);
            }
        }
        if(!qualificationIdsToUpload.isEmpty()){
            if(isUploadPQCertificatesFirstRun){
                isUploadPQCertificatesFirstRun = false;
                uploadQualificationCertificates(qualificationIdsToUpload);
            }
        }
    }
    
    
    /*** TRACELABS ***/
    
    
    //TraceLabs uploadQualificationCertificates callout
    @future (callout=true)
    public static void uploadQualificationCertificates(List<Id> qualificationIds){
        System.debug('### PersonalQualificationHandler.uploadQualificationCertificates: ' + qualificationIds);
    
        //call tracelabs upload certificates
        try{
            TraceLabsAPI tAPI = new TraceLabsAPI();
            TraceLabsAPI.UploadResponse ur = tAPI.uploadQualificationCertificates(qualificationIds);
            
            //get successful Qualifications
            Set<String> successfulQualifications = new Set<String>();
            if(ur != null && ur.statusCode == 200 && ur.body != null && !ur.body.successfull.isEmpty()){
                for(TraceLabsAPI.UploadResponseBodyItem item : ur.body.successfull){
                    successfulQualifications.add(item.enrollment_code);
                }
            }
            System.debug('### successfulQualifications: ' + successfulQualifications);
            
            //update successful Qualifications
            List<Personal_Qualification__c> qualificationsToUpdate = new List<Personal_Qualification__c>();
            for(Id id : qualificationIds){
                String id15 = String.valueOf(id).substring(0,15);
                if(successfulQualifications.contains(id15)) {
                    qualificationsToUpdate.add(new Personal_Qualification__c(Id = id, Show_Certificate_Holder__c = true));
                }
            }
            System.debug('### qualificationsToUpdate: ' + qualificationsToUpdate);

            if(!qualificationsToUpdate.isEmpty()){
                Database.update(qualificationsToUpdate, false);
            }
        }catch(Exception e){
            System.debug('### uploadQualificationCertificates error: ' + e.getMessage());
        }
    }
}