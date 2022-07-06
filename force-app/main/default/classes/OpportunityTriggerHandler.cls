/**
*
* Author:       Carmine Barbuto / Andrew Mahood
* Company:    Tquila
* Date:         25/01/2012
* Description:  Handler class for Opportunity Trigger.
* Change Log:
*
*  CPE 01-09-17  Moved GetUserCountryMap to bg_UserUtils and removed no-longer used private method maxTwoValuesBD.      
**/
public class OpportunityTriggerHandler {
  
  private Boolean isExecuting = false;
  private Integer BatchSize = 0;
  private SystemSetting__c sys = SystemSetting__c.getInstance();
  
  // Variable set while sync OppLineImtes from Quote
  public static Boolean syncOppLines = false;

  private static Map<Id,User> countryMap {get; set;}
  
  // CONSTRUCTOR
  public OpportunityTriggerHandler(Boolean isExecuting, Integer size) {
    isExecuting = isExecuting;
    BatchSize = size;
  }


  
  // BEFORE INSERT
  public void OnBeforeInsert(Opportunity[] newList, 
                Opportunity[] oldList, 
                Map<ID, Opportunity> newMap, 
                Map<ID, Opportunity> oldMap) {
    if (!Utility.lockOptyTrigger) {
      assignTerritory(newList);
      assignSalesAdmin(newList);
      //maxTwoValuesBD(newList);
      salesAdminEmail(newList);
      bg_ProductUtils.UpdateProductClassification(newList, null);
      
      if(newMap != null)
        bg_OpportunityUtils.numberOfSites(newMap.values());
    }
  }
  
  // BEFORE UPDATE
  public void OnBeforeUpdate(Opportunity[] newList, 
                Opportunity[] oldList, 
                Map<ID, Opportunity> newMap, 
                Map<ID, Opportunity> oldMap) {
    
    if (!Utility.lockOptyTrigger) {      
      if (!Utility.lockassignTerritory) { 
        assignTerritory(newList);
      }
      assignSalesAdmin(newList);            
      salesAdminEmail(newList);
      rollupTrainingProductNames(newMap, oldMap);
      //maxTwoValuesBD(newList);
      bg_ProductUtils.UpdateProductClassification(newList, oldMap);
      updateStageModifiedDate(newMap, oldMap);
      
      bg_OpportunityUtils.numberOfSites(newMap.values());
      createFulfillmentRecords(newMap, oldMap);
    }
  }
  
  // AFTER UPDATE
  public void OnAfterUpdate(Opportunity[] newList, 
                Opportunity[] oldList, 
                Map<ID, Opportunity> newMap, 
                Map<ID, Opportunity> oldMap) {
    
    if (!Utility.lockOptyTrigger) {              
      createFollowUpOpportunities(newMap, oldMap);
      chatWonOpps(newMap, oldMap);      
    }
  }

  // BUSINESS LOGIC

  
  // DEFAULT SALES ADMIN EMAIL BASED ON COUNTRY - USED IN WORKFLOW RULES
  private void salesAdminEmail(List<Opportunity> newList) {
    set<Id> ownerids = new Set<Id>(); 
    for (Opportunity curr:newList) {
      ownerids.add(curr.OwnerId);
    }
    System.debug('country map = ' + countryMap);
    countryMap = bg_UserUtils.GetCountryMap(ownerids);
    for (Opportunity curr:newList) {
      if(countryMap.get(curr.OwnerId).OperationCountry__c != null) {
        ConversionScore__c cs = ConversionScore__c.getInstance(countryMap.get(curr.OwnerId).OperationCountry__c);
        if(cs != null) {
          if(!bg_StringUtils.IsBlank(cs.CountrySalesAdminEmail__c) && cs.CountrySalesAdminEmail__c != curr.CountrySalesAdminEmail__c) {
            curr.CountrySalesAdminEmail__c = cs.CountrySalesAdminEmail__c;
          }
          if(!bg_StringUtils.IsBlank(cs.CountryPlanningEmail__c) && cs.CountryPlanningEmail__c != curr.CountryPlanningEmail__c) {
            curr.CountryPlanningEmail__c = cs.CountryPlanningEmail__c;
          }
          if(!bg_StringUtils.IsBlank(cs.CountryEntropyAdminEmail__c) && cs.CountryEntropyAdminEmail__c != curr.CountryEntropyAdminEmail__c) {
            curr.CountryEntropyAdminEmail__c = cs.CountryEntropyAdminEmail__c;
          }
          if(!bg_StringUtils.IsBlank(cs.CountryTrainingAdminEmail__c) && cs.CountryTrainingAdminEmail__c != curr.CountryTrainingAdminEmail__c) {
            curr.CountryTrainingAdminEmail__c = cs.CountryTrainingAdminEmail__c;
          }
          if(!bg_StringUtils.IsBlank(cs.Country_CE_Admin_Email__c) && cs.Country_CE_Admin_Email__c != curr.CountryCEAdminEmail__c) {
            curr.CountryCEAdminEmail__c = cs.Country_CE_Admin_Email__c;
          }
          if(!bg_StringUtils.IsBlank(cs.Country_Medical_Devices_Admin_Email__c) && cs.Country_Medical_Devices_Admin_Email__c != curr.Country_Medical_Devices_Admin_Email__c) {
            curr.Country_Medical_Devices_Admin_Email__c = cs.Country_Medical_Devices_Admin_Email__c;
          }
        }
      }
    }
  }
  
  // TERRITORY ASSIGNMENT - SAME AS HQ ACCOUNT (OLD RULE = SAME AS HQ SITE OR RELATED ACCOUNT)
  public void assignTerritory(List<Opportunity> optys) {
    // Filter only for opportunity not closed (won/lost)
    SiteSetting__c setting = SiteSetting__c.getInstance();
    List<Opportunity> optyNotClosed = new List<Opportunity>();
    for (Opportunity curr : optys)
      if (!curr.isClosed) optyNotClosed.add(curr);
    
    Set<Id> accIds = new Set<Id>();
    for (Opportunity curr : optyNotClosed)
      accIds.add(curr.AccountId);
    
    List<Site__c> sites = [SELECT Account__c,Territory__c FROM Site__c WHERE Account__c IN :accIds and Type__c = :setting.HQLabel__c];
    Map<Id,Site__c> mapHQs = new Map<Id,Site__c>();
    for (Site__c curr : sites) {
      mapHQs.put(curr.Account__c,curr);
    }
    for (Opportunity o : optyNotClosed) {
      if (mapHQs.get(o.AccountId) != null) o.Territory__c = mapHQs.get(o.AccountId).Territory__c;
    }
  }  
  
  // SALES ADMIN ASSIGNMENT [WORKFLOW EMAIL REQUIREMENT]
  public void assignSalesAdmin(List<Opportunity> optys) {
    Set<Id> ownerIds = new Set<Id>();
    for (Opportunity curr : optys) {
      ownerIds.add(curr.OwnerId);
    }
    Map<Id,User> managerMap = new Map<Id,User>([SELECT SalesAdmin__c FROM User WHERE Id IN :ownerIds]);
    for (Opportunity curr : optys) {
      if (managerMap.get(curr.OwnerId) != null) {
        curr.SalesAdmin__c = managerMap.get(curr.OwnerId).SalesAdmin__c;
      } else {
        curr.SalesAdmin__c = null;
      }
    }
  }
  
  private void rollupTrainingProductNames(Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
    /*
    if opp has training products then their names are listed in TrainingProducts__c field
    this is then used by informatica to create a lead in Darkside.
    */
    
    Map<ID, Opportunity> oppsWithTraining = new Map<ID, Opportunity>();
    
    //put all opps with training products just set into a map
    for (Opportunity newOpp:newMap.values()) {
      Opportunity oldOpp = oldMap.get(newOpp.Id);
      if (newOpp.NoOfTrainingProducts__c>=1 &&
        (newOpp.NoOfTrainingProducts__c!=oldOpp.NoOfTrainingProducts__c)) {
          
        //if opp has training products and they were just added (rolledup)
        oppsWithTraining.put(newOpp.ID, newOpp);
      }
    }
    
    system.debug('oppsWithTraining...' + oppsWithTraining);
    
    if (!oppsWithTraining.isEmpty()) {
      //get training products from opps with products jsut added
      List<OpportunityLineItem> trainingOlis = new List<OpportunityLineItem>();
      trainingOlis = [SELECT Id, 
                   PricebookEntry.Product2.Name, 
                   PricebookEntry.Product2.TrainingTaxonomyCode__c,
                   Opportunity.ID,
                   Opportunity.CurrencyISOCode,
                   Quantity,
                   TotalPrice
              FROM OpportunityLineItem
              WHERE Opportunity.Id IN :oppsWithTraining.keyset() AND
              IsTraining__c = true];
              
      system.debug('trainingOlis...' + trainingOlis);
      
      if (!trainingOlis.isEmpty()) {
        //iterate over lineitems building map of opps to lineitems
        Map<ID, List<OpportunityLineItem>> oppToLineItems = new Map<ID, List<OpportunityLineItem>>();    
        for (OpportunityLineItem lineItem:trainingOlis) {
          List<OpportunityLineItem> lineItems = oppToLineItems.get(lineItem.Opportunity.ID);
          if (lineItems==null) {
            lineItems = new List<OpportunityLineItem>();
          }
          lineItems.add(lineItem);
          oppToLineItems.put(lineItem.Opportunity.ID, lineItems);
        }
        
        //iterate of map updating TraingProducts__c on Opp
        for (ID oppID:oppToLineItems.keyset()) {
          List<OpportunityLineItem> lineItems = oppToLineItems.get(oppID);
          Opportunity opp = newMap.get(oppID);
          
          opp.TrainingProducts__c='';//clear fields to be populated
          for (OpportunityLineItem lineItem:lineItems) {
            //concatenate training names into field
            opp.TrainingProducts__c+=lineItem.PricebookEntry.Product2.Name;
            opp.TrainingProducts__c+=' (' + lineItem.PricebookEntry.Product2.TrainingTaxonomyCode__c + ')';
            opp.TrainingProducts__c+=' x ';
            opp.TrainingProducts__c+=lineItem.Quantity;
            opp.TrainingProducts__c+=' = ';
            opp.TrainingProducts__c+=opp.CurrencyISOCode + ' ';
            opp.TrainingProducts__c+=lineItem.TotalPrice;
            
            opp.TrainingProducts__c+='\n';
          }
        }
      }
    }
  }
   
  
  private void chatWonOpps(Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
    
    List<FeedItem> chatterPosts = new List<FeedItem>();
    
    for (Opportunity newOpp:newMap.values()) {
      //look for recently closed/lost opps
      //check if they need follow up
      Opportunity oldOpp = oldMap.get(newOpp.Id);
      if (newOpp.IsClosed && newOpp.StageName == 'Closed Won' && 
        (newOpp.IsClosed != oldOpp.IsClosed)) {
            
        String message = 'Just Won ';
        message+=newOpp.Name;
        if (newOpp.Amount!=null) {
          message+=' ' + newOpp.CurrencyISOCode + newOpp.Amount;
        }
        message+='!!!';
        
        system.debug('chatWonOpps...message...' + message);
        
        //if opp was just closed, and stage is closed - won
        FeedItem chatterPost = new FeedItem();
        chatterPost.ParentId = newOpp.OwnerId;//UserInfo.getUserId();
        chatterPost.Type = 'LinkPost';
        chatterPost.Body = message;
        chatterPost.LinkUrl = '/' + newOpp.Id;
        chatterPost.Title = newOpp.Name;
        chatterPosts.add(chatterPost);
      }
    }
    
    if (!chatterPosts.isEmpty()) {
      insert chatterPosts;
    }
  }

  private void createFollowUpOpportunities(Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
    
    List<Opportunity> toBuildFollowUp = new List<Opportunity>();
    Set<Id> accountIds = new Set<Id>();
    
    for (Opportunity newOpp:newMap.values()) {
      //look for recently closed/lost opps
      //check if they need follow up
      Opportunity oldOpp = oldMap.get(newOpp.Id);
      if (newOpp.CreateFollowupOpp__c == 'Yes' &&
        (newOpp.CreateFollowupOpp__c != oldOpp.CreateFollowupOpp__c)) {
        
        toBuildFollowUp.add(newOpp);
        accountIds.add(newOpp.AccountId);
      }
    }
    
    if (toBuildFollowUp!= null && !toBuildFollowUp.isEmpty()) {
      Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name
                                FROM Account
                                WHERE Id IN :accountIds]);
      
      if (accountMap!= null && !accountMap.isEmpty()) {
        
        List<Opportunity> toCreateFollowUp = new List<Opportunity>();
        for (Opportunity closedOpp: toBuildFollowUp) {
          Account closedOppAcc = accountMap.get(closedOpp.AccountId);
          
          if (closedOppAcc!=null) {
            //build new opportunity copying some info from source opp
            Opportunity followUpOpp = new Opportunity();
            followUpOpp.CloseDate = date.today().addDays(60);
            followUpOpp.StageName = 'Sales Engaged';
            followUpOpp.Name = closedOppAcc.Name + ' - Follow-up';
            followUpOpp.AccountId = closedOpp.AccountId;
            followUpOpp.LeadSource = 'Follow-up'; 
            followUpOpp.RegistrationPath__c = closedOpp.RegistrationPath__c;
            followUpOpp.CurrencyIsoCode = closedOpp.CurrencyIsoCode;
            followUpOpp.OwnerId = closedOpp.OwnerId;
            followUpOpp.SourceOpportunity__c = closedOpp.Id; //link from new to orig
            followUpOpp.Territory__c = closedOpp.Territory__c;
            
            toCreateFollowUp.add(followUpOpp);
          }
        }
        
        if (!toCreateFollowUp.IsEmpty()) {
          insert toCreateFollowUp;
        
          List<FeedItem> chatterPosts = new List<FeedItem>();
          for (Opportunity insertedOpp:toCreateFollowUp) {
            if (insertedOpp.Id!=null) {
              FeedItem chatterPost = new FeedItem();
              chatterPost.ParentId = insertedOpp.SourceOpportunity__c;
              chatterPost.Type = 'LinkPost';
              chatterPost.Body = 'Follow-up Opportunity created.';
              chatterPost.LinkUrl = '/' + insertedOpp.Id;
              chatterPost.Title = insertedOpp.Name;
              chatterPosts.add(chatterPost);
            }
          }
          
          if (!chatterPosts.isEmpty()) {
            insert chatterPosts;
          }
        }
      }
    }
  }
  
  public void updateStageModifiedDate(Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap){
    for (Opportunity newOpp:newMap.values()) {
      Opportunity oldOpp = oldMap.get(newOpp.Id);
      
      if(newOpp.StageName != oldOpp.StageName)
        newOpp.StageModifiedDate__c = Date.Today();
    }
  }
  
  public void OnBeforeDelete(Opportunity[] newList, 
                Opportunity[] oldList, 
                Map<ID, Opportunity> newMap, 
                Map<ID, Opportunity> oldMap) {
    if (!Utility.lockOptyTrigger && syncOppLines) {
      //oldList[0].addError('You do not have permission to delete this record');
    }
  }
  
  public void createFulfillmentRecords(Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
    
    for(Opportunity opp:newMap.values()){
      if((opp.StageName == 'Closed Processing' || opp.StageName == 'Closed Won')
        && (oldMap.get(opp.Id).StageName != opp.StageName)) {
        createFulfilmentRecord(opp);
      }else
        continue;
    }
  }
  
  private void createFulfilmentRecord(Opportunity opp){
    List<String> listProductCodes = sys.Product_to_Exclude_in_Fulfillment_Status__c != null ? sys.Product_to_Exclude_in_Fulfillment_Status__c.split(',') : null;
      
      List<OpportunityLineItem> oppLineItems = [SELECT SMONumber__c, SMO_Cancelled__c, TotalPrice, Product_Group__c, ProductCode, Product_Name__r.Main_Product_Name__c, 
        Opportunity.CurrencyISOCode, Quote_Part__r.ProductClassification__r.Product_Type__c, Quote_Part__r.Quote_Product_Group_Number__c, LastModifiedDate, Phase__c, FeeType__c, Registration_Path__c, ScheduleCycle__c, ProductClassification__c
        FROM OpportunityLineItem WHERE OpportunityId = :opp.Id ORDER BY Quote_Part__r.Quote_Product_Group_Number__c];
      
      // If this opp doesnt have line items skip
      if(oppLineItems == null || oppLineItems.size() == 0) return;
      
      // If already fulfillment records are created skip this opportunity
    List<Fulfillment_Status__c> fsList = [SELECT Id FROM Fulfillment_Status__c WHERE Opportunity__c = :opp.Id];
    if(fsList !=null && fsList.size() > 0) return;
    
    opp.Open_Amount__c = 0;
    opp.Scheduled_Amount__c = 0;
    opp.Cancelled_Amount__c = 0;
    
    Map<Decimal, Fulfillment_Status__c> rolledupLineItems = new Map<Decimal, Fulfillment_Status__c>();
    
    List<Quote__c> quote = [SELECT Id FROM Quote__c WHERE Opportunity_Name__c = :opp.Id AND Main_Quote__c = true];

      Map<Decimal, String> scheduledGroups = new Map<Decimal, String>();

    Fulfillment_Status__c item;
      // Loop through all Opportunity Line Items and findout any one item in the Group is scheduled
      // Create Grouped Fulfillment Status Record
      for(OpportunityLineItem oli : oppLineItems) {
        // Check for exclude product codes and skip
        if(listProductCodes != null && listProductCodes.contains(oli.ProductCode))
          continue;
        
      if(scheduledGroups.get(oli.Quote_Part__r.Quote_Product_Group_Number__c) == null){
        item = new Fulfillment_Status__c();
        item.Product_Group__c = oli.Product_Group__c;
        item.Product_Name__c = oli.Product_Name__r.Main_Product_Name__c;
        item.Product_Type__c = oli.Quote_Part__r.ProductClassification__r.Product_Type__c;
        item.Group_Number__c = oli.Quote_Part__r.Quote_Product_Group_Number__c;
        item.Name = oli.Product_Group__c != null ? oli.Product_Group__c : oli.Product_Name__r.Main_Product_Name__c;
        item.Amount__c = oli.TotalPrice;
        item.CurrencyIsoCode = oli.Opportunity.CurrencyIsoCode;
        item.Account__c = opp.AccountId;
        item.Opportunity__c = opp.Id;
        item.Quotes_Orders__c = (quote == null || quote.size() == 0) ? null : quote.get(0).Id; 
        item.Modified_Date__c = oli.LastModifiedDate;
        item.Registration_Path__c = oli.Registration_Path__c;
        item.ProductClassification__c = oli.ProductClassification__c;
        item.recordTypeId = Schema.SObjectType.Fulfillment_Status__c.getRecordTypeInfosByName().get('Fulfillment Status').getRecordTypeId();

        rolledupLineItems.put(oli.Quote_Part__r.Quote_Product_Group_Number__c, item);
      } else {
        item = rolledupLineItems.get(oli.Quote_Part__r.Quote_Product_Group_Number__c);
        if(item != null) {
          item.Amount__c = item.Amount__c + oli.TotalPrice;
          if(item.Modified_Date__c < oli.LastModifiedDate)
            item.Modified_Date__c = oli.LastModifiedDate;
          rolledupLineItems.put(oli.Quote_Part__r.Quote_Product_Group_Number__c, item);
        }
      }
      
        if(oli.SMONumber__c != null && !oli.SMO_Cancelled__c)
          scheduledGroups.put(oli.Quote_Part__r.Quote_Product_Group_Number__c, 'Scheduled');
        else if(oli.SMO_Cancelled__c)
          scheduledGroups.put(oli.Quote_Part__r.Quote_Product_Group_Number__c, 'Cancelled');
        else
          scheduledGroups.put(oli.Quote_Part__r.Quote_Product_Group_Number__c, 'Open');
      }
      
      for(Fulfillment_Status__c fs: rolledupLineItems.values()){
        opp.Open_Amount__c = opp.Open_Amount__c + fs.Amount__c;
        fs.Status__c = scheduledGroups.get(fs.Group_Number__c);
      }
            
      insert rolledupLineItems.values();
      
      List<Fulfillment_Status__c> fsLineItems = new List<Fulfillment_Status__c>();
      // Create Individual Fulfillment Status Record
      for(OpportunityLineItem oli : oppLineItems) {
        Fulfillment_Status__c fsLineItem = new Fulfillment_Status__c();
        fsLineItem.recordTypeId = Schema.SObjectType.Fulfillment_Status__c.getRecordTypeInfosByName().get('Fulfillment Status Line Items').getRecordTypeId();
        fsLineItem.Product_Group__c = oli.Product_Group__c;
          fsLineItem.Product_Name__c = oli.Product_Name__r.Main_Product_Name__c;
          fsLineItem.Product_Type__c = oli.Quote_Part__r.ProductClassification__r.Product_Type__c;
          fsLineItem.Group_Number__c = oli.Quote_Part__r.Quote_Product_Group_Number__c;
          fsLineItem.Name = oli.Product_Group__c != null ? oli.Product_Group__c : oli.Product_Name__r.Main_Product_Name__c;
          fsLineItem.Amount__c = oli.TotalPrice;
          fsLineItem.CurrencyIsoCode = oli.Opportunity.CurrencyIsoCode;
          fsLineItem.Account__c = opp.AccountId;
          fsLineItem.Opportunity__c = opp.Id;
          fsLineItem.Quotes_Orders__c = (quote == null || quote.size() == 0) ? null : quote.get(0).Id; 
          fsLineItem.Modified_Date__c = oli.LastModifiedDate;
          fsLineItem.Status__c = rolledupLineItems.get(oli.Quote_Part__r.Quote_Product_Group_Number__c).Status__c;
          fsLineItem.Phase__c = oli.Phase__c;
          fsLineItem.FeeType__c = oli.FeeType__c;
          fsLineItem.Registration_Path__c = oli.Registration_Path__c;
          fsLineItem.ScheduleCycle__c = oli.ScheduleCycle__c;
          fsLineItem.ProductClassification__c = oli.ProductClassification__c;
          fsLineItem.RolledupFulfillmentStatus__c = rolledupLineItems.get(oli.Quote_Part__r.Quote_Product_Group_Number__c).Id;
          fsLineItems.add(fsLineItem);
      }
      insert fsLineItems;
  }
}