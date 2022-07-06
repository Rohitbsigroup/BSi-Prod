public class CertificateControllerUniversal{

    //finals
    private final String PREFIX_ENROLLMENT = 'a26';
    private final String PREFIX_QUALIFICATION = 'a27';

    //url params
    public String bg { get; private set; }
    public String id { get; private set; }
      
    //unified data
    public Boolean showBackground { get; private set; }
    public Boolean showCertificate { get; private set; }
    public String certificateError { get; private set; }
    public String translationName { get; private set; }
    
    public CertificateControllerUniversal(){
        this.id = ApexPages.currentPage().getParameters().get('id');
        if(String.isBlank(this.id)) return;

        this.showBackground = true;
        if(ApexPages.currentPage().getParameters().get('bg') == '0'){
            this.showBackground = false;
        }

        String userId = UserInfo.getUserId();
        String userName = UserInfo.getName();
        String userProfileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        showCertificate = true;
        
        //Enrollment
        if(this.id.substring(0,3) == PREFIX_ENROLLMENT){
            List<Enrollment__c> eList = [
                SELECT Share_Certificate__c, Translation_Formula__c, Training_Translations__r.Cert_Access_Error__c, Delegate_name__r.Client_Learning_Portal_User_Id__c
                FROM Enrollment__c 
                WHERE Id = :this.id
            ];

            if(!eList.isEmpty()){
                //guest user
                if(userName.contains('Site Guest User') && !eList[0].Share_Certificate__c){
                    showCertificate = false;
                }

                //portal 
                if(!userName.contains('Site Guest User')){
                    if(userId != eList[0].Delegate_name__r.Client_Learning_Portal_User_Id__c){
                        showCertificate = false;
                    }
                }

                certificateError = eList[0].Training_Translations__r.Cert_Access_Error__c;
                translationName = eList[0].Translation_Formula__c;
            }
        }
        
        //Personal Qualification
        if(this.id.substring(0,3) == PREFIX_QUALIFICATION){
            List<Personal_Qualification__c> pqList = [
                SELECT Share_Certificate__c, Training_Translations__r.Cert_Access_Error__c, Training_Translations__r.Name, Delegate__r.Client_Learning_Portal_User_Id__c 
                FROM Personal_Qualification__c 
                WHERE Id = :this.id
            ];

            if(!pqList.isEmpty()){
                //guest user
                if(userName.contains('Site Guest User') && !pqList[0].Share_Certificate__c){
                    showCertificate = false;
                }
                
                //portal 
                if(!userName.contains('Site Guest User')){
                    if(userId != pqList[0].Delegate__r.Client_Learning_Portal_User_Id__c){
                        showCertificate = false;
                    }
                }
                
                certificateError = pqList[0].Training_Translations__r.Cert_Access_Error__c;
                translationName = pqList[0].Training_Translations__r.Name;
            }
        }
        
        //overwrite permissions for these Profiles
        if(userProfileName == 'System Administrator' || userProfileName == 'BSI Global Training Operations'){
            showCertificate = true;
        }
    }
}