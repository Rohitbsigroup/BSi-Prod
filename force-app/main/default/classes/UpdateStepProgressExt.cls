public class UpdateStepProgressExt {
    public List<Step_Progress__c> selectedProgressList{get;set;}
    public set<Id> stepProgressIdSet;

    // Constructor
    public UpdateStepProgressExt(ApexPages.StandardSetController cntlr){    
        List<Step_Progress__c> selectedStepProgressList;
        selectedStepProgressList = cntlr.getSelected(); 
        selectedProgressList = new List<Step_Progress__c>();
        stepProgressIdSet = new set<Id>();
        stepProgressIdSet = ((new Map<Id,Step_Progress__c>((List<Step_Progress__c>)cntlr.getSelected())).keySet());
        selectedProgressList = [select id,name,Name__c,Name_Local__c,Progress__c,Evidence__c,EvidenceReviewer__c,Order__c,Personal_Qualification__c  from Step_Progress__c where id in:stepProgressIdSet order by Order__c];
    } 
    public PageReference save(){
        try{
            update selectedProgressList;
        }catch(DMLException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage()));
        }
        //PageReference returnPage = new PageReference(URL.getSalesforceBaseUrl().toExternalForm() + '/'+ 'lightning/r/Personal_Qualification__c/' + selectedProgressList[0].Personal_Qualification__c + '/related/Steps__r/view');  //Use if lightning
        PageReference returnPage = new PageReference(URL.getSalesforceBaseUrl().toExternalForm() + '/'+ selectedProgressList[0].Personal_Qualification__c );
       
        return returnPage;
    }
    
    public PageReference quicksave(){
        try{
            update selectedProgressList;
        }catch(DMLException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage()));
        }
        return null;
    }
    
}