public class CertificateVerificationController {

    public String currentURL { get; private set; }
    public String portalUserId { get; private set; }
    public String traceLabsURL { get; private set; }
    public String verifierScript { get; private set; }

    private String shareId;
    private TraceLabsAPI tAPI;
    
    public CertificateVerificationController(){
        TraceLabs_Settings__c ts = TraceLabs_Settings__c.getOrgDefaults();
        this.traceLabsURL = ts.URL__c;
    
        this.currentURL = URL.getCurrentRequestUrl().toExternalForm().replace('apex/', '');
        
        List<User> userList = [SELECT ContactId, Contact.Client_Learning_Portal_User__c FROM User WHERE Id = :UserInfo.getUserId()];
        if(!userList.isEmpty() && userList[0].ContactId != null){
            this.portalUserId = userList[0].Contact.Client_Learning_Portal_User__c;
        }
    
        this.shareId = ApexPages.currentPage().getParameters().get('shareId');
        if(String.isBlank(shareId)) return;
        
        tAPI = new TraceLabsAPI();
        TraceLabsAPI.VerifierResponse vr = tAPI.getVerifierScript(shareId);
        if(vr != null && !String.isBlank(vr.src)){
            verifierScript = vr.src;
        }
        
    }
}