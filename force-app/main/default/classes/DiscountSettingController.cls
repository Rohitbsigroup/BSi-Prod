/**
*
* Author:       Radoslava Radkova
* Modified by:	Carmine Barbuto
* Company:		Tquila
* Date:         28/11/2012
* Description:  Visualforce Controller used to easily set up Custom Setting for US
*				discounts. 
*
*       
**/
public class DiscountSettingController {
	
	public ConversionScore__c score {get; set;}
	public boolean isUS;
	public Territory__c ApproverId11 {get; set;}
	public Territory__c ApproverId21 {get; set;}
	public Territory__c ApproverId31 {get; set;}
	public Territory__c ApproverId41 {get; set;}
	public Territory__c ApproverId42 {get; set;}

	public DiscountSettingController(){
		
		String country = ApexPages.currentPage().getParameters().get('country');
		score = ConversionScore__c.getInstance(country);
		
		ApproverId11 = new Territory__c();
		ApproverId21 = new Territory__c();
		ApproverId31 = new Territory__c();
		ApproverId41 = new Territory__c();
		ApproverId42 = new Territory__c();
		
		ApproverId11.AssignedTo__c = score.DiscountLevel1User1__c;
		ApproverId21.AssignedTo__c = score.DiscountLevel2User1__c;
		ApproverId31.AssignedTo__c = score.DiscountLevel3User1__c;
		ApproverId41.AssignedTo__c = score.DiscountLevel4User1__c;
		ApproverId42.AssignedTo__c = score.DiscountLevel4User2__c; 
		
	}	
	
	public PageReference saveAll() {
		String quoteId = ApexPages.currentPage().getParameters().get('quoteID');
		score.DiscountLevel1User1__c = ApproverId11.AssignedTo__c;
		score.DiscountLevel2User1__c = ApproverId21.AssignedTo__c;
		score.DiscountLevel3User1__c = ApproverId31.AssignedTo__c;
		score.DiscountLevel4User1__c = ApproverId41.AssignedTo__c;
		score.DiscountLevel4User2__c = ApproverId42.AssignedTo__c;
		update score;
		
		PageReference retPage = new PageReference('/' + quoteId);
		return retPage;
		
	}
	
	public PageReference cancel(){
		String quoteId = ApexPages.currentPage().getParameters().get('quoteID');
		PageReference retPage = new PageReference('/' + quoteId);
		return retPage;
		
	}
	
	

}