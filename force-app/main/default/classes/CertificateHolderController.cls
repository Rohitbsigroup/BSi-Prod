public class CertificateHolderController {

    public Boolean isError { get; private set; }
    public String holderScript { get; private set; } 
    public String currentURL { get; private set; } /* JS added 20210524 for metatags */ 
    public String traceLabsURL { get; private set; } /* JS added 20210524 for metatags */ 

    private String ampeId;
    private String eId;
    private String uId;
    private String portalUserId;
    private TraceLabsAPI tAPI;
    
    private final String PREFIX_ENROLLMENT = 'a26';
    private final String PREFIX_QUALIFICATION = 'a27';
    
    public CertificateHolderController(){
        System.debug('### CertificateHolderController');
        
        /* START JS added 20210524 for metatags */ 
        TraceLabs_Settings__c ts = TraceLabs_Settings__c.getOrgDefaults(); 
        this.traceLabsURL = ts.URL__c; 
    
        this.currentURL = URL.getCurrentRequestUrl().toExternalForm().replace('apex/', ''); 
        System.debug('### TL url:' + this.traceLabsURL + 'current URL:' + this.currentURL);
        /* END JS added 20210524 for metatags */ 
        
        this.isError = false;
        this.ampeId = ApexPages.currentPage().getParameters().get('amp;eId');
        this.eId = ApexPages.currentPage().getParameters().get('eId');
        if(this.eId == null && !String.isBlank(this.ampeId)) this.eId = this.ampeId;
        if(String.isBlank(eId)){
            this.isError = true;
            return;
        }

        this.uId = ApexPages.currentPage().getParameters().get('uId');
        if(String.isBlank(uId)){
            this.isError = true;
            return;
        }
      
        //Enrollment
        if(this.eId.substring(0,3) == PREFIX_ENROLLMENT){
            List<Enrollment__c> eList = [SELECT Share_Certificate__c, Delegate_name__c, Delegate_name__r.Client_Learning_Portal_User_Id__c FROM Enrollment__c WHERE Id = :eId];
            
            //check if Share Certificate is enabled
            if(eList.isEmpty() || !eList[0].Share_Certificate__c || eList[0].Delegate_name__c == null){
                this.isError = true;
                return;
            }
            
            //check if current User is Portal User
            this.portalUserId = eList[0].Delegate_name__r.Client_Learning_Portal_User_Id__c;
            if(UserInfo.getUserId() != this.portalUserId){
                this.isError = true;
                return;
            }
        }

        //Personal Qualification
        if(this.eId.substring(0,3) == PREFIX_QUALIFICATION){
            List<Personal_Qualification__c> pqList = [SELECT Share_Certificate__c, Delegate__c, Delegate__r.Client_Learning_Portal_User_Id__c FROM Personal_Qualification__c WHERE Id = :eId];
            
            //check if Share Certificate is enabled
            if(pqList.isEmpty() || !pqList[0].Share_Certificate__c || pqList[0].Delegate__c == null){
                this.isError = true;
                return;
            }
            
            //check if current User is Portal User
            this.portalUserId = pqList[0].Delegate__r.Client_Learning_Portal_User_Id__c;
            if(UserInfo.getUserId() != this.portalUserId){
                this.isError = true;
                return;
            }
        }
        
        tAPI = new TraceLabsAPI();
        TraceLabsAPI.HolderResponse hr = tAPI.getHolderScript(String.valueOf(uId).substring(0,15), String.valueOf(portalUserId).substring(0,15), String.valueOf(eId).substring(0,15));
        //TraceLabsAPI.HolderResponse hr = tAPI.getHolderScript(uId, enrollmentList[0].Name);
        if(hr != null && !String.isBlank(hr.src)){
            holderScript = hr.src;
        }
    }
}