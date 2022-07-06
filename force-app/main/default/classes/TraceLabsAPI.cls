/*
* Created By:  PC K2 - December 2020
* Purpose: Class to integrate with TraceLabs API Webservice methods 
*
* changelog
* ------------------------------------------------
*/

public with sharing class TraceLabsAPI {

    public String appId;
    public String apiURL;

    private String holderBearer;
    private String verifierBearer;
    
    private final String BEARER = 'Bearer';
    private final String HOLDER = 'Holder';
    private final String VERIFIER = 'Verifier';
    
    public class HolderResponse {
        public String type;
        public String src;
    }
    
    public class VerifierResponse {
        public String type;
        public String src;
    }
    
    public class UploadResponse {
        public Integer statusCode;
        public UploadResponseBody body;
    }
    
    public class UploadResponseBody {
        public List<UploadResponseBodyItem> successfull;
        public List<UploadResponseBodyItem> errors;
    }
    
    public class UploadResponseBodyItem {
        public String enrollment_code;
        public String message;
    }
    
    //constructor
    public TraceLabsAPI(){
        System.debug('### TraceLabsAPI');
        try{
            TraceLabs_Settings__c ts = TraceLabs_Settings__c.getOrgDefaults();
            appId = ts.App_Id__c;
            apiURL = ts.API__c;
                      
            List<TraceLabs_Authorization_Tokens__mdt> tokens = [SELECT DeveloperName, Token__c, Type__c FROM TraceLabs_Authorization_Tokens__mdt];
            for(TraceLabs_Authorization_Tokens__mdt t : tokens){
                if(t.DeveloperName == HOLDER && t.Type__c == BEARER) holderBearer = t.Token__c;
                if(t.DeveloperName == VERIFIER && t.Type__c == BEARER) verifierBearer = t.Token__c;
            }
        }catch(Exception e){
            System.debug('### TraceLabsAPI error: ' + e.getMessage());
        }
    }
      
    public HolderResponse getHolderScript(String userId, String portalUserId, String enrollmentId){   
        if(String.isBlank(userId) || String.isBlank(portalUserId) || String.isBlank(enrollmentId)) return null; 

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(apiURL + 'app?app_id=' + appId + '&certificate_holder_id=' + userId + '&enrollment_code=' + enrollmentId + '&user_id=' + portalUserId);  //JS changed back to enrollmentId
        req.setHeader('Authorization', 'Bearer ' + holderBearer);
        
        HttpResponse res;
        if(!Test.isRunningTest()){
            System.debug('### TraceLabsAPI getHolderScript request: ' + req);
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"type": "application/javascript", "src": "https://test.com/test.js"}');
        }
        System.debug('### TraceLabsAPI getHolderScript response: ' + res);
        System.debug('### TraceLabsAPI getHolderScript response body: ' + res.getBody());
        
        HolderResponse hr;
        try{
            hr = (HolderResponse)JSON.deserialize(res.getBody(), HolderResponse.class);
        }catch(Exception e){
            System.debug('### TraceLabsAPI getHolderScript error: ' + e.getMessage());
            hr = new HolderResponse();
        }

        System.debug('### TraceLabsAPI getHolderScript: ' + hr);
        return hr;
    }
    
    public VerifierResponse getVerifierScript(String shareId){
        if(String.isBlank(shareId)) return null;

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(apiURL + 'app?app_id=' + appId + '&shareId=' + shareId);
        req.setHeader('Authorization', 'Bearer ' + verifierBearer);
        
        HttpResponse res;
        if(!Test.isRunningTest()){
            System.debug('### TraceLabsAPI getVerifierScript request: ' + req);
            res = h.send(req);
        }else{
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"type": "application/javascript", "src": "https://test.com/test.js"}');
        }
        System.debug('### TraceLabsAPI getVerifierScript response: ' + res);
        System.debug('### TraceLabsAPI getVerifierScript response body: ' + res.getBody());
        
        VerifierResponse vr;
        try{
            vr = (VerifierResponse)JSON.deserialize(res.getBody(), VerifierResponse.class);
        }catch(Exception e){
            System.debug('### TraceLabsAPI getVerifierScript error: ' + e.getMessage());
            vr = new VerifierResponse();
        }

        System.debug('### TraceLabsAPI getVerifierScript: ' + vr);
        return vr;
    }
    
    public UploadResponse uploadEnrollmentCertificates(List<Id> enrollmentIds){
        if(enrollmentIds.isEmpty()) return null;
    
        List<Enrollment__c> enrollmentList = [
            SELECT
                Booking_status__c,
                Certificate_Language__c,
                Course_Duration__c,
                Course_Start_Date__c,
                Delegate_Name__c,
                Delegate_name__r.FirstName,
                Delegate_name__r.FirstNameLocal,
                Delegate_name__r.LastName,
                Delegate_name__r.LastNameLocal,
                Delegate_Name__r.Name,
                Delegate_name__r.Salutation,
                Exam_results__c,
                Name,
                Original_IRCA_Course_Enrollment__r.Training_Event__r.Course_Name_for_Certificate__c,
                Training_Event__r.Bespoke_Course_Name_for_Certificate__c,
                Training_Event__r.Course_Duration_Days__c,
                Training_Event__r.Course_Name_for_Certificate__c,
                Training_Event__r.English_Course_Name_for_CertificateF__c,
                Training_Event__r.English_Course_Name_for_Certificatetxt__c,
                Training_Event__r.Event_Country__c,
                Training_Event__r.RecordType.Name,
                Training_Event__r.Special_Course_Name_for_Certificate__c,
                Training_Event__r.Start_date__c,
                Training_Event__r.Course__r.Bespoke_Event__c,
                Training_Event__r.Course__r.Certified_Course__c,
                Training_Event__r.Course__r.Course_Name_English__c,
                Training_Event__r.Course__r.Japanese_Course_Name_for_Certificates__c,
                Training_Event__r.Course__r.Product_Name_Local__c,
                Training_Event__r.Course__r.Training_Taxonomy_Code__c,
                Training_Translations__r.Country_Code__c,
                Training_Translations__r.Language__c,
                Training_Translations__r.Name,
                Training_Translations__r.Text_Box_2__c,
                Training_Translations__r.Text_Box_3__c,
                Translation_Formula__c
            FROM Enrollment__c WHERE Id IN :enrollmentIds
        ];
        if(enrollmentList.isEmpty()) return null;
    
        String jsonBody = '[';
        for(Integer i=0; i<enrollmentList.size(); i++){
            Enrollment__c e = enrollmentList[i];
            
            //course name
            String courseName = '';
            if(e.Training_Event__r.Course__r.Certified_Course__c == 'IRCA'){
                if(e.Booking_status__c == 'Booked - Resit' && e.Exam_results__c == 'IRCA - Pass exam & pass CA'){
                    courseName = e.Original_IRCA_Course_Enrollment__r.Training_Event__r.Course_Name_for_Certificate__c;
                }
                if(e.Booking_status__c != 'Booked - Resit'){
                    courseName = e.Training_Event__r.Course_Name_for_Certificate__c;
                }
            }
            if(e.Training_Event__r.Course__r.Certified_Course__c != 'IRCA'){
                if(e.Translation_Formula__c == 'Japan (Japanese)' && e.Certificate_Language__c == 'Local'){
                    if(!e.Training_Event__r.Course__r.Bespoke_Event__c) courseName = e.Training_Event__r.Course__r.Japanese_Course_Name_for_Certificates__c;
                    if(e.Training_Event__r.Course__r.Bespoke_Event__c) courseName = e.Training_Event__r.Course_Name_for_Certificate__c;
                    if(e.Training_Event__r.Course__r.Certified_Course__c == 'JRCA' && (e.Training_Event__r.Course__r.Training_Taxonomy_Code__c == 'ISM10901JAJP' || e.Training_Event__r.Course__r.Training_Taxonomy_Code__c == 'ISM11101JAJP')) courseName += ' JRCA登録 継続的専門能力開発(CPD)コース<br/>(ISO/IEC 27001の新旧規格の差分の内容を含んだ研修）';
                }
                if(e.Translation_Formula__c == 'Japan (Japanese)' && e.Certificate_Language__c == 'English'){
                    if(!String.isBlank(e.Training_Event__r.English_Course_Name_for_Certificatetxt__c)) courseName = e.Training_Event__r.English_Course_Name_for_Certificatetxt__c;
                    else courseName = e.Training_Event__r.Course__r.Course_Name_English__c;
                }
                if(e.Translation_Formula__c == 'Turkey (Türkçe)'){
                    courseName = 'BSI - British Standards Institution tarafından düzenlenmiş olan ' + e.Training_Event__r.Course_Name_for_Certificate__c + '\'ne ';
                    if(e.Exam_results__c == null) courseName += e.Training_Translations__r.Text_Box_2__c;
                    if(e.Exam_results__c == 'NON - Fail exam') courseName += e.Training_Translations__r.Text_Box_2__c;
                    if(e.Exam_results__c == 'NON - Pass exam') courseName += e.Training_Translations__r.Text_box_3__c;
                    if(e.Exam_results__c == 'NON - Fail exam & pass CA') courseName += e.Training_Translations__r.Text_Box_2__c;
                    if(e.Exam_results__c == 'NON - Pass exam & fail CA') courseName += e.Training_Translations__r.Text_Box_2__c;
                    if(e.Exam_results__c == 'NON - Pass exam & pass CA') courseName += e.Training_Translations__r.Text_box_3__c;
                    if(e.Exam_results__c == 'NON - Fail exam & fail CA') courseName += e.Training_Translations__r.Text_box_2__c;
                    if(e.Exam_results__c == 'Fail exam & pass CA') courseName += e.Training_Translations__r.Text_box_2__c;
                    if(e.Exam_results__c == 'Pass exam & fail CA') courseName += e.Training_Translations__r.Text_box_2__c;
                    if(e.Exam_results__c == 'Pass exam & pass CA') courseName += e.Training_Translations__r.Text_box_3__c;
                    if(e.Exam_results__c == 'Fail exam & fail CA') courseName += e.Training_Translations__r.Text_box_2__c;
                }
                if(e.Translation_Formula__c == 'Korea (Korean)' || e.Translation_Formula__c == 'Vietnam (Vietnamese)'){
                    if(e.Certificate_Language__c == 'English'){
                        if(!String.isBlank(e.Training_Event__r.English_Course_Name_for_Certificatetxt__c)) courseName = e.Training_Event__r.English_Course_Name_for_Certificatetxt__c;
                        else courseName = e.Training_Event__r.Course__r.Course_Name_English__c;
                    }
                    if(e.Certificate_Language__c == 'Local' || e.Certificate_Language__c == null){
                        if(!String.isBlank(e.Training_Event__r.Bespoke_Course_Name_for_Certificate__c)) courseName = e.Training_Event__r.Bespoke_Course_Name_for_Certificate__c;
                        else courseName = e.Training_Event__r.Course__r.Product_Name_Local__c;
                    }
                    if(e.Certificate_Language__c == 'Both'){
                        //no english for 'both'
                        //if(!String.isBlank(e.Training_Event__r.English_Course_Name_for_Certificatetxt__c)) courseName = e.Training_Event__r.English_Course_Name_for_Certificatetxt__c;
                        //else courseName = e.Training_Event__r.Course__r.Course_Name_English__c;
                        if(!String.isBlank(e.Training_Event__r.Bespoke_Course_Name_for_Certificate__c)) courseName += ' ' + e.Training_Event__r.Bespoke_Course_Name_for_Certificate__c;
                        else courseName += ' ' + e.Training_Event__r.Course__r.Product_Name_Local__c;
                    }
                }
                if(e.Translation_Formula__c == 'China (Chinese)'){
                    if(e.Certificate_Language__c == 'English'){
                        if(!String.isBlank(e.Training_Event__r.English_Course_Name_for_Certificatetxt__c)) courseName = e.Training_Event__r.English_Course_Name_for_Certificatetxt__c;
                        else courseName = e.Training_Event__r.Course__r.Course_Name_English__c;
                    }
                    if(e.Certificate_Language__c == 'Local' || e.Certificate_Language__c == null){
                        if(!String.isBlank(e.Training_Event__r.Bespoke_Course_Name_for_Certificate__c)) courseName = e.Training_Event__r.Bespoke_Course_Name_for_Certificate__c;
                        else courseName = e.Training_Event__r.Course_Name_for_Certificate__c;
                    }
                    if(e.Certificate_Language__c == 'Both'){
                        //no english for 'both'
                        //if(!String.isBlank(e.Training_Event__r.English_Course_Name_for_Certificatetxt__c)) courseName = e.Training_Event__r.English_Course_Name_for_Certificatetxt__c;
                        //else courseName = e.Training_Event__r.Course__r.Course_Name_English__c;
                        if(!String.isBlank(e.Training_Event__r.Bespoke_Course_Name_for_Certificate__c)) courseName += ' ' + e.Training_Event__r.Bespoke_Course_Name_for_Certificate__c;
                        else courseName += ' ' + e.Training_Event__r.Course__r.Product_Name_Local__c;
                    }
                }
                if(e.Translation_Formula__c == 'Taiwan (Chinese)'){
                    if(e.Certificate_Language__c == 'English'){
                        if(!String.isBlank(e.Training_Event__r.English_Course_Name_for_Certificatetxt__c)) courseName = e.Training_Event__r.English_Course_Name_for_Certificatetxt__c;
                        else courseName = e.Training_Event__r.Course__r.Course_Name_English__c;
                    }
                    if(e.Certificate_Language__c == 'Local' || e.Certificate_Language__c == null){
                        if(!String.isBlank(e.Training_Event__r.Bespoke_Course_Name_for_Certificate__c)) courseName = e.Training_Event__r.Bespoke_Course_Name_for_Certificate__c;
                        else courseName = e.Training_Event__r.Course_Name_for_Certificate__c;
                    }
                    if(e.Certificate_Language__c == 'Both'){
                        if(!String.isBlank(e.Training_Event__r.English_Course_Name_for_Certificatetxt__c)) courseName = e.Training_Event__r.English_Course_Name_for_Certificatetxt__c;
                        else courseName = e.Training_Event__r.Course__r.Course_Name_English__c;
                    }
                }
                if(
                    e.Translation_Formula__c != 'Taiwan (Chinese)' &&
                    e.Translation_Formula__c != 'Japan (Japanese)' &&
                    e.Translation_Formula__c != 'Korea (Korean)' &&
                    e.Translation_Formula__c != 'Vietnam (Vietnamese)' &&
                    e.Translation_Formula__c != 'Turkey (Türkçe)' &&
                    e.Translation_Formula__c != 'China (Chinese)'
                ){
                    if(e.Certificate_Language__c == 'English'){
                        courseName = e.Training_Event__r.English_Course_Name_for_CertificateF__c;
                    }
                    if(e.Certificate_Language__c == 'Local' || e.Certificate_Language__c == null){
                        courseName = e.Training_Event__r.Course_Name_for_Certificate__c;
                    }
                    if(e.Certificate_Language__c == 'Both'){
                        if(e.Training_Event__r.RecordType.Name == 'Global Training Event (Bespoke)') courseName = e.Training_Event__r.Bespoke_Course_Name_for_Certificate__c;
                        else courseName = e.Training_Event__r.Course_Name_for_Certificate__c;
                        
                        //no english for 'both'
                        //courseName += ' ' + e.Training_Event__r.English_Course_Name_for_CertificateF__c;
                    }
                    if(e.Certificate_Language__c == 'Special'){
                        courseName = e.Training_Event__r.Special_Course_Name_for_Certificate__c;
                    }
                }
            }
            
            //delegate name
            String delegateName = '';
            String translation = e.Training_Translations__r.Name;
            if(
                translation != 'Korea (Korean)' && 
                translation != 'Vietnam (Vietnamese)' && 
                translation != 'China (Chinese)' && 
                translation != 'Taiwan (Chinese)' && 
                translation != 'Japan (Japanese)' && 
                translation != 'Germany (Deutsch)' && 
                translation != 'Singapore (English)' && 
                translation != 'Malaysia (English)' && 
                translation != 'Hong Kong (English)'
            ){
                delegateName = e.Delegate_name__r.Name;
            }
            if(translation == 'Germany (Deutsch)'){
                if(e.Delegate_name__r.Salutation == 'Herr Dr.' || e.Delegate_name__r.Salutation == 'Frau Dr.'){
                    delegateName = 'Dr. ' + e.Delegate_name__r.Name;
                }else{
                    delegateName = e.Delegate_name__r.Salutation + ' ' + e.Delegate_name__r.Name;
                }
            }
            if(translation == 'Japan (Japanese)'){
                if(e.Certificate_Language__c == 'Local' && e.Training_Event__r.Course__r.Certified_Course__c != 'IRCA'){
                    delegateName = e.Delegate_name__r.LastNameLocal + ' ' + e.Delegate_name__r.FirstNameLocal + ' 殿 ';
                }
                delegateName += e.Delegate_name__r.FirstName + ' ' + e.Delegate_name__r.LastName;
            }
            if(translation == 'Taiwan (Chinese)' || translation == 'Korea (Korean)' || translation == 'Vietnam (Vietnamese)'){
                //removed 'both'
                if(e.Certificate_Language__c == 'English' || e.Training_Event__r.Course__r.Certified_Course__c == 'IRCA'){
                    delegateName =  e.Delegate_name__r.FirstName + ' ' + e.Delegate_name__r.LastName;
                }
                if(e.Training_Event__r.Course__r.Certified_Course__c != 'IRCA' && (e.Certificate_Language__c == 'Local' || e.Certificate_Language__c == 'Both')){
                    delegateName =  e.Delegate_name__r.LastNameLocal + '' + e.Delegate_name__r.FirstNameLocal;
                }
            }
            if(translation == 'China (Chinese)'){
                //removed 'both'
                if(e.Certificate_Language__c == 'English' || e.Training_Event__r.Course__r.Certified_Course__c == 'IRCA'){
                    delegateName =  e.Delegate_name__r.LastName + ' ' + e.Delegate_name__r.FirstName;
                }
                if(e.Training_Event__r.Course__r.Certified_Course__c != 'IRCA' && (e.Certificate_Language__c == 'Local' || e.Certificate_Language__c == 'Both')){
                    delegateName =  e.Delegate_name__r.LastNameLocal + '' + e.Delegate_name__r.FirstNameLocal;
                }
            }
            if(translation == 'Singapore (English)' || translation == 'Malaysia (English)'){
                if(!String.isBlank(e.Delegate_name__r.FirstNameLocal) && !String.isBlank(e.Delegate_name__r.LastNameLocal)){
                    delegateName = e.Delegate_name__r.LastNameLocal + ' ' + e.Delegate_name__r.FirstNameLocal;
                }
                if(String.isBlank(e.Delegate_name__r.FirstNameLocal) && String.isBlank(e.Delegate_name__r.LastNameLocal)){
                    delegateName = e.Delegate_name__r.Name;
                }
            }
            if(translation == 'Hong Kong (English)'){
                delegateName = e.Delegate_name__r.LastName + ' ' + e.Delegate_name__r.FirstName;
            }
            
            jsonBody += '{';
            jsonBody += '"country_id": "' + e.Training_Translations__r.Country_Code__c + '", ';
            jsonBody += '"certificate_language": "' + e.Training_Translations__r.Language__c + '", ';
            jsonBody += '"certificate_issuer": "BSI", ';
            jsonBody += '"certificate_holder_id": "' + String.valueOf(e.Delegate_Name__c).substring(0,15) + '", '; //use 15-digit Id
            jsonBody += '"certificate_holder": "' + delegateName + '", ';
            jsonBody += '"enrollment_id": "' + e.Name + '", ';  // JS swapped this to be Name
            jsonBody += '"enrollment_code": "' + String.valueOf(e.Id).substring(0,15) + '", '; //use 15-digit Id
            jsonBody += '"course_name": "' + courseName + '", ';
            jsonBody += '"course_duration": "' + e.Course_Duration__c + '", ';
            jsonBody += '"course_date": "' + e.Course_Start_Date__c + '"';
            jsonBody += '}';
            if(i+1 < enrollmentList.size()) jsonBody += ', ';
        }
        jsonBody += ']';
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(apiURL + 'services/datasets');
        req.setHeader('Authorization', 'Bearer ' + verifierBearer);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        System.debug(jsonBody);
        
        HttpResponse res;
        if(!Test.isRunningTest()){
            System.debug('### TraceLabsAPI uploadEnrollmentCertificates request: ' + req);
            res = h.send(req);
        }else{
            String id15 = String.valueOf(enrollmentIds[0]).substring(0,15);
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"successfull":[{"enrollment_code":"' + id15 + '","message":"Certificate with enrollment code ' + id15 + ' is successfully created."}],"errors":[]}');
        }
        System.debug('### TraceLabsAPI uploadEnrollmentCertificates response: ' + res);
        System.debug('### TraceLabsAPI uploadEnrollmentCertificates response body: ' + res.getBody());
        
        UploadResponse ur = new UploadResponse();
        try{
            ur.statusCode = res.getStatusCode();
            ur.body = (UploadResponseBody)JSON.deserialize(res.getBody(), UploadResponseBody.class);
        }catch(Exception e){
            System.debug('### TraceLabsAPI uploadEnrollmentCertificates error: ' + e.getMessage());
        }

        System.debug('### TraceLabsAPI uploadEnrollmentCertificates: ' + ur);
        return ur;
    }
    
    public UploadResponse uploadQualificationCertificates(List<Id> qualificationIds){
        if(qualificationIds.isEmpty()) return null;
    
        List<Personal_Qualification__c> qualificationList = [
            SELECT
                Certificate_Language__c,
                Date_Qualification_Completed__c,
                Delegate__c,
                Delegate__r.FirstName,
                Delegate__r.FirstNameLocal,
                Delegate__r.LastName,
                Delegate__r.LastNameLocal,
                Delegate__r.Name,
                Delegate__r.Salutation,
                Expiry_Date__c,
                Name,
                Qualification_Name__c,
                Training_Translations__r.Country_Code__c,
                Training_Translations__r.Language__c,
                Training_Translations__r.Name,
                Training_Translations__r.Text_Box_2__c,
                Training_Translations__r.Text_Box_3__c
            FROM Personal_Qualification__c WHERE Id IN :qualificationIds
        ];
        if(qualificationList.isEmpty()) return null;
        
        String jsonBody = '[';
        for(Integer i=0; i<qualificationList.size(); i++){
            Personal_Qualification__c pq = qualificationList[i];
            
            //delegate name
            String delegateName = '';
            String translation = pq.Training_Translations__r.Name;
            if(
                translation != 'Korea (Korean)' && 
                translation != 'Vietnam (Vietnamese)' && 
                translation != 'China (Chinese)' && 
                translation != 'Taiwan (Chinese)' && 
                translation != 'Japan (Japanese)' && 
                translation != 'Germany (Deutsch)' && 
                translation != 'Singapore (English)' && 
                translation != 'Malaysia (English)' && 
                translation != 'Hong Kong (English)'
            ){
                delegateName = pq.Delegate__r.Name;
            }
            if(translation == 'Germany (Deutsch)'){
                if(pq.Delegate__r.Salutation == 'Herr Dr.' || pq.Delegate__r.Salutation == 'Frau Dr.'){
                    delegateName = 'Dr. ' + pq.Delegate__r.Name;
                }else{
                    delegateName = pq.Delegate__r.Salutation + ' ' + pq.Delegate__r.Name;
                }
            }
            if(translation == 'Japan (Japanese)'){
                if(pq.Certificate_Language__c == 'Local'){
                    delegateName = pq.Delegate__r.LastNameLocal + ' ' + pq.Delegate__r.FirstNameLocal + ' 殿 ';
                }
                delegateName += pq.Delegate__r.FirstName + ' ' + pq.Delegate__r.LastName;
            }
            if(translation == 'Taiwan (Chinese)' || translation == 'Korea (Korean)' || translation == 'Vietnam (Vietnamese)'){
                //removed 'both'
                if(pq.Certificate_Language__c == 'English'){
                    delegateName =  pq.Delegate__r.FirstName + ' ' + pq.Delegate__r.LastName;
                }
                if(pq.Certificate_Language__c == 'Local' || pq.Certificate_Language__c == 'Both'){
                    delegateName =  pq.Delegate__r.LastNameLocal + '' + pq.Delegate__r.FirstNameLocal;
                }
            }
            if(translation == 'China (Chinese)'){
                //removed 'both'
                if(pq.Certificate_Language__c == 'English'){
                    delegateName =  pq.Delegate__r.LastName + ' ' + pq.Delegate__r.FirstName;
                }
                if(pq.Certificate_Language__c == 'Local' || pq.Certificate_Language__c == 'Both'){
                    delegateName =  pq.Delegate__r.LastNameLocal + '' + pq.Delegate__r.FirstNameLocal;
                }
            }
            if(translation == 'Singapore (English)' || translation == 'Malaysia (English)'){
                if(!String.isBlank(pq.Delegate__r.FirstNameLocal) && !String.isBlank(pq.Delegate__r.LastNameLocal)){
                    delegateName = pq.Delegate__r.LastNameLocal + ' ' + pq.Delegate__r.FirstNameLocal;
                }
                if(String.isBlank(pq.Delegate__r.FirstNameLocal) && String.isBlank(pq.Delegate__r.LastNameLocal)){
                    delegateName = pq.Delegate__r.Name;
                }
            }
            if(translation == 'Hong Kong (English)'){
                delegateName = pq.Delegate__r.LastName + ' ' + pq.Delegate__r.FirstName;
            }
            
            jsonBody += '{';
            jsonBody += '"country_id": "' + pq.Training_Translations__r.Country_Code__c + '", ';
            jsonBody += '"certificate_language": "' + pq.Training_Translations__r.Language__c + '", ';
            jsonBody += '"certificate_issuer": "BSI", ';
            jsonBody += '"certificate_holder_id": "' + String.valueOf(pq.Delegate__c).substring(0,15) + '", '; //use 15-digit Id
            jsonBody += '"certificate_holder": "' + delegateName + '", ';
            jsonBody += '"personal_qualification_id": "' + pq.Name + '", '; // JS swapped this to be Name
            jsonBody += '"enrollment_code": "' + String.valueOf(pq.Id).substring(0,15) + '", '; //use 15-digit Id
            jsonBody += '"qualification_name": "' + pq.Qualification_Name__c+ '", ';
            jsonBody += '"qualification_completion_date": "' + pq.Date_Qualification_Completed__c + '", ';
            jsonBody += '"qualification_expiry_date": "' + pq.Expiry_Date__c + '"';
            jsonBody += '}';
            if(i+1 < qualificationList.size()) jsonBody += ', ';
        }
        jsonBody += ']';
   
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(apiURL + 'services/datasets');
        req.setHeader('Authorization', 'Bearer ' + verifierBearer);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        System.debug(jsonBody);
        
        HttpResponse res;
        if(!Test.isRunningTest()){
            System.debug('### TraceLabsAPI uploadQualificationCertificates request: ' + req);
            res = h.send(req);
        }else{
            String id15 = String.valueOf(qualificationIds[0]).substring(0,15);
            res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"successfull":[{"enrollment_code":"' + id15 + '","message":"Certificate with enrollment code ' + id15 + ' is successfully created."}],"errors":[]}');
        }
        System.debug('### TraceLabsAPI uploadQualificationCertificates response: ' + res);
        System.debug('### TraceLabsAPI uploadQualificationCertificates response body: ' + res.getBody());
        
        UploadResponse ur = new UploadResponse();
        try{
            ur.statusCode = res.getStatusCode();
            ur.body = (UploadResponseBody)JSON.deserialize(res.getBody(), UploadResponseBody.class);
        }catch(Exception e){
            System.debug('### TraceLabsAPI uploadQualificationCertificates error: ' + e.getMessage());
        }

        System.debug('### TraceLabsAPI uploadQualificationCertificates: ' + ur);
        return ur;
    }
}