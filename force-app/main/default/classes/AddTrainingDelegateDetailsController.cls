public with sharing class AddTrainingDelegateDetailsController {

    public ApexPages.StandardSetController ssc {get; set;}

    public AddTrainingDelegateDetailsController(ApexPages.StandardSetController controller){
        ssc = controller;
    }
   
    public PageReference updateDelegates(){
        System.debug('### updateDelegates');
        try{
            update ssc.getSelected();
            String s = ssc.getRecords().size()>1 ? 's' : '';
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, ssc.getRecords().size() + ' record' + s + ' updated at ' + System.now()));
        }catch(Exception e){
            System.debug('exception: ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }
}