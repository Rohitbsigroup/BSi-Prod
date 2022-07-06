public without sharing class ShowingCertificationCmpController {
    
    @TestVisible private static final String PERSONAL_QUALIFICATION_OBJECT_API_NAME = 'Personal_Qualification__c';
    @TestVisible private static final String ENROLLMENT_OBJECT_API_NAME = 'Enrollment__c';
    private static final String ENROLLMENT_SERTIFICATE_SENT_STATUS = 'Sent';

    @AuraEnabled
    public static ResultWrapper checkShowCertConditionValidity(Id recordId) {
        List<User> currentUser = [
            SELECT Id, OperationCountry__c
            FROM User 
            WHERE Id = :UserInfo.getUserId() 
            LIMIT 1
        ];
        List<String> countryCodes = new List<String>();
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        if (!currentUser.isEmpty()) {
            if (sObjName == PERSONAL_QUALIFICATION_OBJECT_API_NAME) {
                List<Personal_Qualification__c> personalQualifications = [
                    SELECT Id,
                           Show_Certificate_Holder__c,
                           Share_Certificate__c,
                           Training_Translations__r.Certificate_verification__c
                    FROM Personal_Qualification__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                Boolean isPersonalQualificationShareCertificate =
                    personalQualifications[0].Show_Certificate_Holder__c == true &&
                    personalQualifications[0].Training_Translations__r.Certificate_verification__c == true;
                if (isPersonalQualificationShareCertificate) {
                    return new ResultWrapper(PERSONAL_QUALIFICATION_OBJECT_API_NAME, true, personalQualifications[0].Share_Certificate__c);
                }
                return new ResultWrapper(PERSONAL_QUALIFICATION_OBJECT_API_NAME, false, personalQualifications[0].Share_Certificate__c);
            } else if (sObjName == ENROLLMENT_OBJECT_API_NAME) {
                List<Enrollment__c> enrollments = [
                    SELECT Id,
                           Show_Certificate_Holder__c,
                           Share_Certificate__c,
                           Training_Translations__r.Certificate_verification__c
                    FROM Enrollment__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                Boolean isEnrollmentsShareCertificate =
                    enrollments[0].Show_Certificate_Holder__c == true &&
                    enrollments[0].Training_Translations__r.Certificate_verification__c == true;
                if (isEnrollmentsShareCertificate) {
                    return new ResultWrapper(ENROLLMENT_OBJECT_API_NAME, true, enrollments[0].Share_Certificate__c);
                }
                return new ResultWrapper(ENROLLMENT_OBJECT_API_NAME, false, enrollments[0].Share_Certificate__c);
            }
            return new ResultWrapper(null, false, false);
        } 
        return new ResultWrapper(null, false, false);
    }

    @AuraEnabled
    public static void udpateShareCertificateCheckboxOnRecord(Id recordId) {
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        if (sObjName == PERSONAL_QUALIFICATION_OBJECT_API_NAME) {
            List<Personal_Qualification__c> personalQualifications = [
                SELECT Id, Share_Certificate__c
                FROM Personal_Qualification__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            personalQualifications[0].Share_Certificate__c = !personalQualifications[0].Share_Certificate__c;
            update personalQualifications;
        } else if (sObjName == ENROLLMENT_OBJECT_API_NAME) {
            List<Enrollment__c> enrollments = [
                SELECT Id, Share_Certificate__c
                FROM Enrollment__c 
                WHERE Id = :recordId
                LIMIT 1
            ];
            enrollments[0].Share_Certificate__c = !enrollments[0].Share_Certificate__c;
            update enrollments;
        }
    }
    
    public class ResultWrapper{
        @AuraEnabled
        public String objectApiName;
        @AuraEnabled
        public Boolean isValidity;
        @AuraEnabled
        public Boolean isShareCert;
        
        public ResultWrapper(String objectApiName, Boolean isValidity, Boolean isShareCert) {
            this.objectApiName = objectApiName;
            this.isValidity = isValidity;
            this.isShareCert = isShareCert;
        }
    }
    
}