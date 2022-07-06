/**
*	Author		: Prasad JN
*	Description	: Custom APEX for setting out of office for approvers
*/
public with sharing class emq_OutofOffice {
    
    public Boolean outofOffice { get; set; }
    
    public emq_OutofOffice(ApexPages.StandardController stdController){
    	Id id = UserInfo.getUserId();
    	
    	User user = [SELECT OutofOffice__c FROM User WHERE Id = :Id];
    	outofOffice = user.OutofOffice__c;
    }
    
    public PageReference unsetOutofOffice() {
    	Id id = UserInfo.getUserId();
    	User user = [SELECT Id, OutofOffice__c FROM User WHERE Id = :Id];
    	user.OutofOffice__c = false;
    	update user;
    	
    	PageReference curPage = ApexPages.currentPage();
		curPage.setRedirect(true);
		return curPage;
    }
    
    public PageReference setOutofOffice() {
    	Id id = UserInfo.getUserId();
    	User user = [SELECT Id, OutofOffice__c FROM User WHERE Id = :Id];
    	user.OutofOffice__c = true;
    	update user;
    	
    	PageReference curPage = ApexPages.currentPage();
		curPage.setRedirect(true);
		return curPage;
    }
}