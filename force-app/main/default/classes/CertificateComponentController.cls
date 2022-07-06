public class CertificateComponentController {

    //finals
    private final String OBJECT_ENROLLMENT = 'enrollment';
    private final String OBJECT_QUALIFICATION = 'qualification';
    private final String PREFIX_ENROLLMENT = 'a26';
    private final String PREFIX_QUALIFICATION = 'a27';

    //objects
    public String objectType { get; private set; }    
    public Enrollment__c enrollment { get; private set; }
    public Personal_Qualification__c qualification { get; private set; }
    
    //unified data
    public String bsiTrainingAcademy { get; private set; }
    public String certificateLanguage { get; private set; }
    public String certifiedCourse { get; private set; }
    public String officeAddress { get; private set; }
    public String royalCharter { get; private set; }
    public String trainingManager { get; private set; }
    public String translationName { get; private set; }
    
    //params
    public Boolean showBackground { get; set; }
    public Id id { 
        get;
        set {
            id = value;
            if(id == null) return;
            if(String.valueOf(id).substring(0,3) == PREFIX_ENROLLMENT){
                objectType = OBJECT_ENROLLMENT;
                List<Enrollment__c> eList = [
                    SELECT
                        Booking_status__c,
                        Certificate_Language__c,
                        Course_Start_Date__c,
                        Delegate_Name__r.CQI_ID__c,
                        Delegate_Name__r.Birthdate,
                        Delegate_name__r.FirstName,
                        Delegate_name__r.FirstNameLocal,
                        Delegate_name__r.LastName,
                        Delegate_name__r.LastNameLocal,
                        Delegate_name__r.Name,
                        Delegate_name__r.Salutation,                    
                        Distance_Learning_Overall_Status__c,
                        Exam_results__c,
                        Master_Enrollment__c,
                        Master_Enrollment__r.Training_Event__r.Course_Duration_Days__c,
                        Master_Enrollment__r.Training_Event__r.End_Date_of_Section_1__c,
                        Master_Enrollment__r.Training_Event__r.End_Date3__c,
                        Master_Enrollment__r.Training_Event__r.Event_Country__c,
                        Master_Enrollment__r.Training_Event__r.Module_Event__c,
                        Master_Enrollment__r.Training_Event__r.Start_date__c,
                        Master_Enrollment__r.Training_Event__r.Start_Date_of_Section_2__c,
                        Master_Enrollment__r.Training_Event__r.Split_Date_Event__c,
                        Module_List_2__c,
                        Name,
                        Online_Training_Completed_Date__c,
                        Original_IRCA_Course_Enrollment__c,
                        Original_IRCA_Course_Enrollment__r.Training_Event__r.Additional_Logo__c,
                        Original_IRCA_Course_Enrollment__r.Training_Event__r.Course_Duration_Days__c,
                        Original_IRCA_Course_Enrollment__r.Training_Event__r.Course_Name_for_Certificate__c,
                        Original_IRCA_Course_Enrollment__r.Training_Event__r.Dates_for_Certificate__c,
                        Original_IRCA_Course_Enrollment__r.Training_Event__r.End_Date_of_Section_1__c,
                        Original_IRCA_Course_Enrollment__r.Training_Event__r.End_Date3__c,
                        Original_IRCA_Course_Enrollment__r.Training_Event__r.Event_Country__c,
                        Original_IRCA_Course_Enrollment__r.Training_Event__r.Module_Event__c,
                        Original_IRCA_Course_Enrollment__r.Training_Event__r.Start_date__c,
                        Original_IRCA_Course_Enrollment__r.Training_Event__r.Start_Date_of_Section_2__c,
                        Original_IRCA_Course_Enrollment__r.Training_Event__r.Split_Date_Event__c,
                        RABQSA_Certificate__c,
                        RecordType.Name,
                        Training_Event__r.Additional_Logo__c,
                        Training_Event__r.Bespoke_Course_Name_for_Certificate__c,
                        Training_Event__r.Course_Duration_Days__c,
                        Training_Event__r.Course_Duration_Hours__c,
                        Training_Event__r.Course_Format_Formula__c,
                        Training_Event__r.Course_Name_for_Certificate__c,                        
                        Training_Event__r.Course_Type_Formula__c,
                        Training_Event__r.Dates_for_Certificate__c,
                        Training_Event__r.End_Date_of_Section_1__c,
                        Training_Event__r.End_Date3__c,
                        Training_Event__r.English_Course_Name_for_CertificateF__c,
                        Training_Event__r.English_Course_Name_for_Certificatetxt__c,
                        Training_Event__r.Event_Country__c,
                        Training_Event__r.Module_Event__c,
                        Training_Event__r.RecordType.Name,
                        Training_Event__r.Start_date__c,
                        Training_Event__r.Start_Date_of_Section_2__c,
                        Training_Event__r.Special_Course_Name_for_Certificate__c,
                        Training_Event__r.Split_Date_Event__c,
                        Training_Event__r.Venue_City__c,
                        Training_Event__r.Course__r.Agenda_for_Certificate__c,
                        Training_Event__r.Course__r.Bespoke_Event__c,
                        Training_Event__r.Course__r.Certified_Course__c,
                        Training_Event__r.Course__r.Course_Has_Exam__c,
                        Training_Event__r.Course__r.Course_Name_English__c,
                        Training_Event__r.Course__r.Course_Type__c,
                        Training_Event__r.Course__r.IRCA_Number__c,
                        Training_Event__r.Course__r.Japanese_Course_Name_for_Certificates__c,
                        Training_Event__r.Course__r.Joint_Delivery__c,
                        Training_Event__r.Course__r.Product_Name_Local__c,
                        Training_Event__r.Course__r.Training_Taxonomy_Code__c,
                        Training_Event__r.Course__r.Is_Litmos__c,
                        Training_Event__r.Training_Venue__r.Name,
                        Training_Translations__r.Assessment_Failed__c,
                        Training_Translations__r.Assessment_Passed__c,
                        Training_Translations__r.BSI_Training_Academy__c,
                        Training_Translations__r.Cert_of_Attendance_for_Certs__c,
                        Training_Translations__r.Certificate_Number__c,
                        Training_Translations__r.Course_Dates__c,
                        Training_Translations__r.Date__c,
                        Training_Translations__r.Duration_For_Certificates__c,
                        Training_Translations__r.Examination_Completed__c,
                        Training_Translations__r.eLearning_Attendance__c,
                        Training_Translations__r.IN_Six_Sigma_Pass__c,
                        Training_Translations__r.IN_Yellow_Six_Sigma__c,
                        Training_Translations__r.Issue_Date__c,
                        Training_Translations__r.JATA_Pass_text__c,
                        Training_Translations__r.JP_Attended_and_Fail__c,
                        Training_Translations__r.JP_Attended_and_Pass__c,
                        Training_Translations__r.JP_Cert_Header_1__c,
                        Training_Translations__r.JP_Cert_Header_2__c,
                        Training_Translations__r.JRCA_Fail_Text__c,
                        Training_Translations__r.JRCA_Fail_text_VILT__c,
                        Training_Translations__r.JRCA_Pass_text__c,
                        Training_Translations__r.Location_for_cert__c,
                        Training_Translations__r.Name,
                        Training_Translations__r.Office_Address__c,
                        Training_Translations__r.OnDemand_Course_and_Exam_Pass__c,
                        Training_Translations__r.Online_Exam_Pass__c,
                        Training_Translations__r.Online_Exam_Text_Box_1__c,
                        Training_Translations__r.RABQSA_Text1__c,
                        Training_Translations__r.RABQSA_Text2__c,
                        Training_Translations__r.Royal_Charter__c,
                        Training_Translations__r.Signature__c,
                        Training_Translations__r.Signature_Image__c,
                        Training_Translations__r.Text_Box_1__c,
                        Training_Translations__r.Text_Box_2__c,
                        Training_Translations__r.Text_box_3__c,
                        Training_Translations__r.Training_Manager__c,
                        Training_Translations__r.X14_Cht_space__c,
                        Translation_Formula__c
                    FROM Enrollment__c WHERE Id = :this.id
                ];
                if(!eList.isEmpty()){
                    enrollment = eList[0];
                    bsiTrainingAcademy = enrollment.Training_Translations__r.BSI_Training_Academy__c;
                    certificateLanguage = enrollment.Certificate_Language__c;
                    certifiedCourse = enrollment.Training_Event__r.Course__r.Certified_Course__c;
                    officeAddress = enrollment.Training_Translations__r.Office_Address__c;
                    royalCharter = enrollment.Training_Translations__r.Royal_Charter__c;
                    trainingManager = enrollment.Training_Translations__r.Training_Manager__c;
                    translationName = enrollment.Translation_Formula__c;
                }
            }
            
            if(String.valueOf(id).substring(0,3) == PREFIX_QUALIFICATION){
                objectType = OBJECT_QUALIFICATION;
                List<Personal_Qualification__c> pqList = [
                    SELECT
                        Certificate_Language__c,
                        Certificate_Logo__c,
                        Date_Qualification_Completed__c,                        
                        Delegate__r.Delegate_Number__c,
                        Delegate__r.FirstName,
                        Delegate__r.FirstNameLocal,
                        Delegate__r.LastName,
                        Delegate__r.LastNameLocal,
                        Delegate__r.Name,
                        Delegate__r.Salutation,
                        Expiry_Date__c,
                        Name,
                        RecordType.Name,
                        StaticResource__c,
                        Qualification_Code__c,
                        Qualification_Name__c,
                        Qualification__r.Country__c,
                        Qualification__r.Level__c,
                        Qualification__r.Master_Qualification__r.Certificate_Logo__c,
                        Qualification__r.Master_Qualification__r.Level__c,
                        Qualification__r.Master_Qualification__r.Name,
                        Training_Translations__r.AQF_Logo__c,
                        Training_Translations__r.BSI_Training_Academy__c,
                        Training_Translations__r.Certificate_Number__c,
                        Training_Translations__r.Certificate_Property__c,
                        Training_Translations__r.Date__c,
                        Training_Translations__r.eLearning_Attendance__c,
                        Training_Translations__r.Expiry_Date__c,
                        Training_Translations__r.Name,
                        Training_Translations__r.NRT_Logo__c,
                        Training_Translations__r.Office_Address__c,
                        Training_Translations__r.Qualification_success__c,
                        Training_Translations__r.Royal_Charter__c,
                        Training_Translations__r.Signature__c,
                        Training_Translations__r.Signature_Image__c,
                        Training_Translations__r.Text_Box_1__c,
                        Training_Translations__r.Text_Box_2__c,
                        Training_Translations__r.Text_Box_3__c,
                        Training_Translations__r.Training_Manager__c
                    FROM Personal_Qualification__c WHERE Id = :this.id
                ];
                if(!pqList.isEmpty()){
                    qualification = pqList[0];
                    bsiTrainingAcademy = qualification.Training_Translations__r.BSI_Training_Academy__c;
                    certificateLanguage = qualification.Certificate_Language__c;
                    officeAddress = qualification.Training_Translations__r.Office_Address__c;
                    royalCharter = qualification.Training_Translations__r.Royal_Charter__c;
                    trainingManager = qualification.Training_Translations__r.Training_Manager__c;
                    translationName = qualification.Training_Translations__r.Name;
                }
            }
        } 
    }

    

}