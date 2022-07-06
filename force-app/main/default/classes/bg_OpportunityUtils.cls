/********************************************************************
 * bg_OpportunityUtils
 *
 * Utility methods to support opportunity functions
 * 
 * Author: Richard Jimenez
 * Created: 
 * Changes: 
 * 11/11/2014   KM  Added CloneOpportunityWithMasterQuote functionality 
 *                  Added OpportunityCloneResult wrapper class
 * 3/02/2015    KM  Added SyncOpportunityLineItems 
 *                      (this is a modified version of CreateOpportunityLineItems 
 *                      to insert/update/delete where appropriate)
 * 9/04/2015    KM  SyncOpportunityLineItems skips validation
 * 6/05/2015    KM  Out for signature opportunities
 * 25/06/2015   CB  Created following methods
 *                  - ConvertTrainingBookingIfStageClosedProcessing
 *                  - SupersedeQuotes_TrainingBookings_TrainingEvents
 *                  - supercedeQuotes
 *                  Added following static finals
 *                  - OPPORTUNITY_STAGE_CLOSED_PROCESSING
 *                  - OPPORTUNITY_STAGE_CLOSED_WON
 *                  - OPPORTUNITY_STAGE_CLOSED_LOST
 * 7/08/2015    Added Phase__c, Revision__c, Location__c, FeeType__c to opp sync
 * 15-01-16     ASD - Fixed Unit Tests to suit VR rules and WFRs (too many SOQLS)
 * 13/07/2017   MJ - Added isClosed to the fields retrieved from Opportunity and removed QuoteReady__c
 * 14/08/2017   RC - Added extra fields to SyncOpportunityLineItems
 * 08/09/2017   CPE  Removed erroneously created methods - getOpportunitySitesForOppId & getOpportunitySitesForOppIds
 * 19/10/2018   PC K2 modified syncOpportunityLineItems(), createOpportunityLineItem(), syncOpportunityLineItem() to split OLIs
 * 16/01/2019   JS&MD Edited PC changes so that they only apply to public training courses and all other products work the same way as before
 ********************************************************************/
public with sharing class bg_OpportunityUtils {

    public static final string OPPORTUNITY_STAGE_NEGOTIATION = 'Negotiation/Review';
    public static final string OPPORTUNITY_STAGE_AGREEMENT_ESTABLISHED = 'Agreement Established';
    public static final string OPPORTUNITY_STAGE_CLOSED_PROCESSING = 'Closed Processing';
    public static final string OPPORTUNITY_STAGE_CLOSED_WON = 'Closed Won';
    public static final string OPPORTUNITY_STAGE_CLOSED_LOST = 'Closed Lost';

    public static final string CANCELLED_STATUS = 'Cancelled';
    
    public static string PRICEBOOK_PART_EXCLUSIVE = 'Exclusive';
    public static string PRICEBOOK_PART_INCLUSIVE = 'Inclusive';

    public static boolean firstRun = true;
    public static Boolean IGNORE_OPP_TRIGGER {get; set;}

    public class OpportunityCloneResult {
    /*
        KM - Wrapper to return multiple fields from the Opportunity Related List clone
    */
        public Id oldQuoteId {get; set;}
        public Id clonedQuoteId {get; set;}
        public Id oldOpportunityId {get; set;}
        public Id clonedOpportunityId {get; set;}
        
        public OpportunityCloneResult(){
        }
    }
    
    public static Opportunity GetOpportunityById(Id oppId) {
        /*
            Get Opportunity by Id
        */
        Opportunity opp = [SELECT Id, CurrencyISOCode, Name, PrimaryContact__c, Portfolio_Interests__c, Product_Area_Interests__c, Product_Interests__c,
                                Pricebook2Id, isClosed, ScopeofRegistration__c, MainQuotePDFid__c, RegistrationPath__c,
                                AccountId, Account.Name, PrimaryContact__r.Name, Cloned_From_Opportunity__c, Clone_Available__c,
                                Contract_Review_Completed__c, Full_Standard__c, OpportunityID2__c //, Full_Standard__r.ProductConfigurator__r.Name, Full_Standard__r.Name
                            FROM Opportunity 
                            WHERE Id = :oppId];
        return opp;
    }
    
    public static list<OpportunityLineItem> GetOpportunityLineItemsList(Set<Id> opportunityIds) {
        /*
            Get OLIs by opportunity id
            (Use this if you don't need opportunity to OLI mapping)
        */
        return new list<OpportunityLineItem> ([SELECT Id, Quote_Part__c, OpportunityId, Quote_Part__r.Quote_Ref__r.Main_Quote__c
                                                FROM OpportunityLineItem
                                                WHERE OpportunityId =: opportunityIds]);
    }

    public static void SaveOpportunity(Opportunity opp) {
        /* Save Opportunity */
        SaveOpportunities(new list<Opportunity> {opp});
    }
    
    public static void SaveOpportunities(list<Opportunity> updOpps) {
        /*
            Method to Save Opportunities
        */
        upsert updOpps; 
    }
    
    public static boolean PopulateOpportunityDefaults(Opportunity opp, boolean isNewQuote, Id primaryContactId) {
        /*
            Populate New Quote Opportunity defaults
        */
        boolean result = false;

        // Set Primary Contact?
        if(opp.PrimaryContact__c != primaryContactId) {
            opp.PrimaryContact__c = primaryContactId;
            result = true;
        }

        // Reset Main Quote PDF Id
        if(isNewQuote && !bg_StringUtils.IsBlank(opp.MainQuotePDFid__c)) {
            opp.MainQuotePDFid__c = null;
            result = true;
        }
        return result;
    }
    
    public static void syncOpportunityLineItems(List<Quote__c> quotes) {
        /*
            Method to sync opportunity line items with quote & quote parts
        */
        System.debug('### bg_OpportunityUtils.syncOpportunityLineItems');
        // Check only main quotes
        Map<Id, Quote__c> oppQuoteMap = new Map<Id, Quote__c>();
        Set<Opportunity> opportunities = new Set<Opportunity>();
        
        for(Quote__c quote : quotes) {
            if(quote.Main_Quote__c && quote.SyncWithOpportunity__c) {
                oppQuoteMap.put(quote.Opportunity_Name__c, quote); // create list of opp ids
                opportunities.add(new Opportunity(Id = quote.Opportunity_Name__c)); //Get a set of all related opps so we can skip validation
            }
            quote.SyncWithOpportunity__c = false;
        }
        
        if(!oppQuoteMap.KeySet().isEmpty()) {
            //can't soql standard pb if unit test is running
            Id standardPBId;
            if(test.isRunningTest()) {
                standardPBId = Test.GetStandardPricebookId();   
            } else {
                standardPBId = bg_PricebookUtils.GetGlobalPricebook().Id;
            }
            
            // Select all quote parts - JS 20190104 addded Course Delivery from PRoduct2
            List<Quote_Part__c> quoteParts = [SELECT Id, Number__c, Price__c, Total_Price_In_Currency__c, Customer_Code__c, 
                                                ProductAttribute__c, Product2__c, Part_Extended_Value__c, Total_Gross_Price__c,
                                                Quote_Product__r.Product_Name__c,                                           
                                                Quote_Ref__r.Opportunity_Name__c, 
                                                Quote_Ref__r.PriceBook2Id__c, 
                                                Quote_Ref__r.Opportunity_Name__r.CurrencyIsoCode,
                                                Product2__r.ProductArea__c,
                                                Quote_Product__r.Site__c,
                                                Quote_Product__r.Registration_Path__c,
                                                RegistrationPath__c,
                                                Quote_Product__r.LifeCycle__c,
                                                Product2__r.ProductCode,
                                                Product2__r.Course_Delivery__c,
                                                InfoTxt__c,
                                                Notes__c, Info__c,
                                                Phase__c, Revision__c, Location__c, FeeType__c,
                                                Training_Booking__r.Training_Event__r.Start_date__c,
                                                Project__c,
                                                Phase_Name__c,Phase_Start_Date__c,Phase_End_Date__c,
                                                Phase_Description__c, Billing_Category__c, Task_Detail__c,
                                                Task_End_Date__c,Task_Start_Date__c, Task_Assignment__c,
                                                EHSTheme__c, EHSSpecialization__c, DeliveryLocation__c, Accreditation__c, Designation__c, NotifiedBody__c
                                            FROM Quote_Part__c 
                                            WHERE Quote_Ref__c IN :quotes
                                                AND IsQuestion__c = false];

            Set<Id> productIds = new Set<Id>();
            for(Quote_Part__c quotePart : quoteParts) {
                productIds.add(quotePart.Product2__c);
            }
                    
            // Create the Pricebook Entry map
            Map<String, PricebookEntry> pbeMap = new Map<String, PricebookEntry>();
            for(PricebookEntry pbe : [  SELECT Id, Name, Product2Id, Pricebook2Id, CurrencyIsoCode, Pricebook2.IsStandard 
                                        FROM PricebookEntry 
                                        WHERE IsActive = true  
                                            AND Pricebook2Id = :standardPBId
                                            AND Product2Id IN :productIds]) {
                pbeMap.put(GetProductCurrencyKey(pbe), pbe);    
            }
            
            List<OpportunityLineItem> oliToDelete = new List<OpportunityLineItem>();
            List<OpportunityLineItem> oliToUpdate = new List<OpportunityLineItem>();
            List<OpportunityLineItem> oliToInsert = new List<OpportunityLineItem>();
            
            Map<Id, List<OpportunityLineItem>> quotePartToOli = new Map<Id, List<OpportunityLineItem>>();

            //Build a set of line items to delete and update
            for(OpportunityLineItem lineItem : getOpportunityLineItemsList(oppQuoteMap.keySet())) {
                if(lineItem.Quote_Part__c == null || lineItem.Quote_Part__r.Quote_Ref__r.Main_Quote__c == false) {
                    oliToDelete.add(lineItem);
                } else {
                    //used to work out which quote parts don't have OLIs
                    //PC K2 20181019 single QuotePart can create many OLIs
                    //quotePartToOli.put(lineItem.Quote_Part__c, lineItem);
                    if(quotePartToOli.containsKey(lineItem.Quote_Part__c)){
                        quotePartToOli.get(lineItem.Quote_Part__c).add(lineItem);
                    }else{
                        quotePartToOli.put(lineItem.Quote_Part__c, new List<OpportunityLineItem>{lineItem});
                    }
                }
            }

            //Handle the OLIs that need to be inserted/edited
            for(Quote_Part__c quotePart : quoteParts) {
                String productKey = getProductCurrencyKey(quotePart);
                //system.debug('ProductKey: ' + productKey);

                if(pbeMap.containsKey(productKey)){
                    PricebookEntry pbe = pbeMap.get(productKey);
                    if(quotePartToOli.KeySet().contains(quotePart.Id)) {
                        //PC K2 20181910 rework to OLI creation
                        //oliToUpdate.add(syncOpportunityLineItem(pbe.Id, pbe.Name, quotePart, quotePartToOli.get(quotePart.Id)));
                        oliToUpdate.addAll(syncOpportunityLineItem(pbe.Id, pbe.Name, quotePart, quotePartToOli.get(quotePart.Id)));
                        
                    } else {
                        //PC K2 20181910 rework to OLI creation
                        //oliToInsert.add(createOpportunityLineItem(pbe.Id, pbe.Name, quotePart));
                        oliToInsert.addAll(createOpportunityLineItem(pbe.Id, pbe.Name, quotePart));
                    }
                } else {
                    //Pricebook entry not found - should never run as this is required to create the quote part 
                    List<String> parameters = new List<String>();
                    parameters.add(String.valueOf(quotePart.Product2__c));
                    parameters.add(quotePart.Quote_Ref__r.Opportunity_Name__r.CurrencyIsoCode);
                    String errorMessage = String.format(Label.BG_PBE_not_found_for_product_sync, parameters);
                    oppQuoteMap.get(quotePart.Quote_Ref__r.Opportunity_Name__c).addError(errorMessage);
                }
            }

            // Do not fire opportunity trigger code
            Utility.lockOptyTrigger = true;
            Utility.lockQuoteTrigger = true;
            
            SetOpportunitySyncFlag(opportunities);

            if(!oliToInsert.isEmpty()) {
                insert oliToInsert;
            }
            if(!oliToUpdate.isEmpty()) {
                update oliToUpdate;
            }
            if(!oliToDelete.isEmpty()) {
                delete oliToDelete;
            }
            ClearOpportunitySyncFlag(opportunities);
        }
        
        List<Opportunity> listOpps = new List<Opportunity>();
        listOpps.addAll(opportunities);
        numberOfSites(listOpps);
        update listOpps;
    }
    
    public @testVisible static void SetOpportunitySyncFlag(set<Opportunity> opportunities)
    {
        /*
            Sets the sync flag on opportunity to stop some validation rules firing
        */
        
        for(Opportunity opportunityIterator : opportunities)
        {
            opportunityIterator.Sync_in_Progress__c = true;
        }
        update new list<Opportunity> (opportunities);
    }
    
    public @testVisible static void ClearOpportunitySyncFlag(set<Opportunity> opportunities)
    {
        /*
            Clears the sync flag on opportunity to allow the validation rules to fire
        */
        
        for(Opportunity opportunityIterator : opportunities)
        {
            opportunityIterator.Sync_in_Progress__c = false;
        }
        update new list<Opportunity>(opportunities);
    }

    /*
    public static OpportunityLineItem CreateOpportunityLineItem(Id pbeId, string name, Quote_Part__c quotePart) {
        System.debug('### CreateOpportunityLineItem');
        System.debug('### CreateOpportunityLineItem quotePart: ' + quotePart);
        OpportunityLineItem oli = new OpportunityLineItem();                    
        oli.PricebookEntryId = pbeId;
        oli.OpportunityId = quotePart.Quote_Ref__r.Opportunity_Name__c;
        return SyncOpportunityLineItem(pbeId, name, quotePart, oli);
    }
    */
    /*  Create OpportunityLineItem (s) - JS 20190104 above is old before PC changes - below edited to do iterated list for Public training, but do what did before for everything else   */
    public static List<OpportunityLineItem> createOpportunityLineItem(Id pbeId, String name, Quote_Part__c quotePart){
        System.debug('### CreateOpportunityLineItem');
        System.debug('### CreateOpportunityLineItem quotePart: ' + quotePart);
        if(quotePart.Product2__r.Course_Delivery__c == 'Public') {        
                List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
                for(Integer i = 0; i < quotePart.Number__c; i++){
                    OpportunityLineItem oli = new OpportunityLineItem(); 
                    oli.PricebookEntryId = pbeId;
                    oli.OpportunityId = quotePart.Quote_Ref__r.Opportunity_Name__c;
                    oliList.add(oli);
                    }
                   return SyncOpportunityLineItem(pbeId, name, quotePart, oliList);
           } else {           
                List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();                    
                for(Integer i = 0; i < quotePart.Number__c/quotePart.Number__c; i++){
                    OpportunityLineItem oli = new OpportunityLineItem();
                    oli.PricebookEntryId = pbeId;
                    oli.OpportunityId = quotePart.Quote_Ref__r.Opportunity_Name__c;
                    oliList.add(oli);
                   }
                    return SyncOpportunityLineItem(pbeId, name, quotePart, oliList);        
           }         
    }

    /*    
    public static OpportunityLineItem SyncOpportunityLineItem(Id pbeId, string name, Quote_Part__c quotePart, OpportunityLineItem oli) {
        System.debug('### SyncOpportunityLineItem');
        System.debug('### SyncOpportunityLineItem quotePart: ' + quotePart);
        System.debug('### quotePart.Number__c: ' + quotePart.Number__c);
        oli.Quantity = quotePart.Number__c;
        oli.ProductAttribute__c = quotePart.ProductAttribute__c;
        oli.TotalPrice = quotePart.Total_Price_In_Currency__c; // Price in quote currency
        oli.ProductDescriptionCustomerVersion__c = quotePart.Customer_Code__c + GetProductDescription(name);
        oli.Part_Extended_Value__c = quotePart.Part_Extended_Value__c;
        oli.Product_Name__c = quotePart.Quote_Product__r.Product_Name__c;
        oli.TotalGrossPrice__c = quotePart.Total_Gross_Price__c;
        oli.Site__c = quotePart.Quote_Product__r.Site__c;
        oli.Registration_Path__c = quotePart.Quote_Product__r.Registration_Path__c;
        oli.LifeCycle__c = quotePart.Quote_Product__r.LifeCycle__c;
        oli.Notes__c = quotePart.Notes__c;
        oli.Quote_Part__c = quotePart.id;
        oli.Info__c = quotePart.Info__c;
        oli.Revision__c = quotePart.Revision__c;
        oli.Location__c = quotePart.Location__c;
        oli.Phase__c = quotePart.Phase__c;
        oli.FeeType__c = quotePart.FeeType__c;
        oli.Project__c = quotePart.Project__c;
        oli.Phase_Name__c = quotePart.Phase_Name__c;
        oli.Phase_Start_Date__c = quotePart.Phase_Start_Date__c;
        oli.Phase_End_Date__c = quotePart.Phase_End_Date__c;
        oli.Phase_Description__c = quotePart.Phase_Description__c;
        oli.Billing_Category__c = quotePart.Billing_Category__c;
        oli.Task_Detail__c = quotePart.Task_Detail__c;
        oli.Task_Start_Date__c = quotePart.Task_Start_Date__c;
        oli.Task_End_Date__c = quotePart.Task_End_Date__c;
        oli.Task_Assignment__c = quotePart.Task_Assignment__c;

        Map<String,String> infoMap = bg_TrainingUtils.fetchInfovalueMap(quotePart);
        if(infoMap.containsKey(bg_TrainingUtils.INFO_PARAM_EVENT_CODE))
        {
            if(infoMap.get(bg_TrainingUtils.INFO_PARAM_EVENT_CODE) == bg_TrainingUtils.INHOUSE_TRAINING || infoMap.get(bg_TrainingUtils.INFO_PARAM_EVENT_CODE) == bg_TrainingUtils.ADHOC_TRAINING)
            {
                oli.SMOScheduledDate__c = quotePart.Training_Booking__r.Training_Event__r.Start_date__c;
            }
        }
        
        // Partbuilder - copy info txt field as the customer description
        if(quotePart.Product2__r.ProductCode == 'PRTBUILD' ||
                (!bg_StringUtils.IsBlank(quotePart.Customer_Code__c) && 
                quotePart.Customer_Code__c.startsWith('Training - AdHoc - LineItemPart'))) { 
            oli.ProductDescriptionCustomerVersion__c = quotePart.InfoTxt__c;
        }

        return oli;
    }
    */
    /*            Sync OpportunityLineItem   - JS 20190104 edited PC edits so uses 1 for public training, but the full number for other products        */
    public static List<OpportunityLineItem> syncOpportunityLineItem(Id pbeId, String name, Quote_Part__c quotePart, List<OpportunityLineItem> oliList) {
        System.debug('### SyncOpportunityLineItem');
        System.debug('### SyncOpportunityLineItem quotePart: ' + quotePart);
        System.debug('### quotePart.Number__c: ' + quotePart.Number__c);
        Map<String,String> infoMap = bg_TrainingUtils.fetchInfovalueMap(quotePart);

        for(OpportunityLineItem oli : oliList){
            if(quotePart.Product2__r.Course_Delivery__c == 'Public') {
                oli.Quantity = 1;
                oli.TotalGrossPrice__c = quotePart.Total_Gross_Price__c / quotePart.Number__c;
                oli.TotalPrice = quotePart.Total_Price_In_Currency__c / quotePart.Number__c; //Price in quote currency
            } else{
                oli.Quantity = quotePart.Number__c;
                oli.TotalPrice = quotePart.Total_Price_In_Currency__c; // Price in quote currency
                oli.TotalGrossPrice__c = quotePart.Total_Gross_Price__c;
            }
            oli.ProductDescriptionCustomerVersion__c = quotePart.Customer_Code__c + GetProductDescription(name);
            oli.ProductAttribute__c = quotePart.ProductAttribute__c;
            oli.Part_Extended_Value__c = quotePart.Part_Extended_Value__c;
            oli.Product_Name__c = quotePart.Quote_Product__r.Product_Name__c;
            oli.Site__c = quotePart.Quote_Product__r.Site__c;
            oli.Registration_Path__c = quotePart.RegistrationPath__c;
            oli.LifeCycle__c = quotePart.Quote_Product__r.LifeCycle__c;
            oli.Notes__c = quotePart.Notes__c;
            oli.Quote_Part__c = quotePart.Id;
            oli.Info__c = quotePart.Info__c;
            oli.Revision__c = quotePart.Revision__c;
            oli.Location__c = quotePart.Location__c;
            oli.Phase__c = quotePart.Phase__c;
            oli.FeeType__c = quotePart.FeeType__c;
            oli.Project__c = quotePart.Project__c;
            oli.Phase_Name__c = quotePart.Phase_Name__c;
            oli.Phase_Start_Date__c = quotePart.Phase_Start_Date__c;
            oli.Phase_End_Date__c = quotePart.Phase_End_Date__c;
            oli.Phase_Description__c = quotePart.Phase_Description__c;
            oli.Billing_Category__c = quotePart.Billing_Category__c;
            oli.Task_Detail__c = quotePart.Task_Detail__c;
            oli.Task_Start_Date__c = quotePart.Task_Start_Date__c;
            oli.Task_End_Date__c = quotePart.Task_End_Date__c;
            oli.Task_Assignment__c = quotePart.Task_Assignment__c;
            oli.Billing_Category__c = quotePart.Billing_Category__c;
            oli.Theme__c = quotePart.EHSTheme__c;
            oli.Specialization__c= quotePart.EHSSpecialization__c;
            
            if(String.isNotBlank(quotePart.DeliveryLocation__c))
            	oli.Location__c = quotePart.DeliveryLocation__c;
            oli.Accreditation__c = quotePart.Accreditation__c;
            oli.Designation__c = quotePart.Designation__c;
            oli.NotifiedBody__c = quotePart.NotifiedBody__c;            

            if(infoMap.containsKey(bg_TrainingUtils.INFO_PARAM_EVENT_CODE)){
                if(infoMap.get(bg_TrainingUtils.INFO_PARAM_EVENT_CODE) == bg_TrainingUtils.INHOUSE_TRAINING || infoMap.get(bg_TrainingUtils.INFO_PARAM_EVENT_CODE) == bg_TrainingUtils.ADHOC_TRAINING){
                    oli.SMOScheduledDate__c = quotePart.Training_Booking__r.Training_Event__r.Start_date__c;
                }
            }

            // Partbuilder - copy info txt field as the customer description
            if(quotePart.Product2__r.ProductCode == 'PRTBUILD' || (!bg_StringUtils.IsBlank(quotePart.Customer_Code__c) && quotePart.Customer_Code__c.startsWith('Training - AdHoc - LineItemPart'))){ 
                oli.ProductDescriptionCustomerVersion__c = quotePart.InfoTxt__c;
            }
        }

        return oliList;
    }

    public static string GetProductDescription(string name) {
        /*
            Get Product Description - Exclusive-Inclusive Rule
        */
        string description = '';
        if(name.contains(PRICEBOOK_PART_EXCLUSIVE)) {
            description = ' - ' + Label.ExclusiveCustomerDescription;
        } else if (name.contains(PRICEBOOK_PART_INCLUSIVE)) { 
            description = ' - ' + Label.InclusiveCustomerDescription;
        }
        return description;
    }

    public static OpportunityCloneResult CloneRelatedObjects(Id oldOppId, Id newOppId, Boolean notesAttachments, Boolean contactRoles, Boolean masterQuote, Boolean tasksAndEvents) {
        /*
            Creates a clone of opportunity sites and optionally contact roles, attachments and the master quote
            Returns the new and old opportunity/quote Id's
        */

        //If Opportunity doesn't have a cloned from opportunity return, otherwise make it null and clone (prevents duplicate clones)
        Opportunity newOpp = GetOpportunityById(newOppId);  
        
        //Instantiate result
        OpportunityCloneResult result = new OpportunityCloneResult();
        result.clonedOpportunityId = newOppId;
        result.oldOpportunityId = oldOppId;
        
        //If Cloned from opportunity is populated and the clone hasn't already taken place
        if(newOpp.Cloned_From_Opportunity__c != null && newOpp.Clone_Available__c){
            //Initialise insert list
            List<SObject> toInsert = new List<SObject>();
            
            //Prevent duplicate clones
            newOpp.Clone_Available__c = false;      
                
            //Map old opportunity sites to new opportunity sites
            map<Id, OpportunitySite__c> oldSitesToNewSites = bg_OpportunitySiteUtils.CloneOpportunitySites(oldOppId, newOppId);
            toInsert.addAll((List<SObject>) oldSitesToNewSites.values());
            
            //Clone tasks and events
            if(tasksAndEvents){
                toInsert.addAll((List<SObject>) bg_EventUtils.CloneEvents(oldOppId, newOppId));
                toInsert.addAll((List<SObject>) bg_TaskUtils.CloneTasks(oldOppId, newOppId));
            }
            
            //Clone contact roles, reparent to new opportunity and add to insert list.
            if(contactRoles){
                toInsert.addAll((List<SObject>) bg_ContactOpportunityUtils.CloneContactOpportunities(oldOppId, newOppId));
            }
            
            //Create a savepoint as all DML (Update/Inserts occur in here)
            SavePoint s =  Database.setSavepoint();
            try{        
                if(notesAttachments){
                    //Cloning attachments also inserts due to their potential size
                    bg_AttachmentUtils.CloneOpportunityAttachments(oldOppId, newOppId);
                    //Clone notes
                    toInsert.addAll((List<SObject>) bg_NoteUtils.CloneNotes(oldOppId, newOppId));
                }   
                
                //Insert needs to be before clone quote as opportunity sites need to have Id's  
                if(!toInsert.isEmpty()){
                    insert toInsert;
                }
                
                //Commit the removal of the cloned from opportunity field
                update newOpp;  
                            
                //Clone the main quote to the new opportunity and populate fields in result
                if(masterQuote){
                    Id mainQuoteId = bg_QuoteUtils.GetMainQuoteId(oldOppId);
                    if(mainQuoteId != null){
                        Id clonedQuoteId = (bg_QuoteUtils.CloneQuote(mainQuoteId, true, true, newOppId, oldSitesToNewSites)).Id;
                        result.clonedQuoteId = clonedQuoteId;
                        result.oldQuoteId = mainQuoteId;
                    }
                }
            }catch(Exception e){
                //Exception will be thrown up to calling method automatically
                Database.rollback(s);
                throw e;
            }
        }
        return result;
    }

    public static void DeleteOpportunityLineItems(set<Id> oppIds) {
        /*
            Delete Opportunity Line Items
        */
        // Select all opty line items to delete and replace with new ones
        list<OpportunityLineItem> oppLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN :oppIds];
        if(!oppLineItems.isEmpty()) { delete oppLineItems; }
    }
    
    public static void SetOppsClosedProcessing(set<Id> oppIds) {
        /*
            Update Opportunity stage to signed closed processing
        */
        list<Opportunity> opps = [SELECT Id, StageName, hasSignedAgreement__c FROM Opportunity WHERE Id IN :oppIds]; 
        SetOppsClosedProcessing(opps);
        // update opportunities
        update opps;
    }
    
    public static void SetOppsClosedProcessing(list<Opportunity> opps) {
        /*
            Change Opportunity stage to closed processing
        */
        for(Opportunity opp : opps) {
            opp.StageName = bg_OpportunityUtils.OPPORTUNITY_STAGE_CLOSED_PROCESSING;
            //ASD 23414 Addition
            opp.HasSignedAgreement__c = True;
        }
    }

    public static void UpdateOpportunitiesOutForSignature(map<Id, Quote__c> oppToQuote){
        /*
            When the main quote for an opportunity is out for signature, set the quote sent, 
            stage name, first quotation date and quote expiration date fields. 
        */
        list<Opportunity> opps = [SELECT QuoteSent__c, StageName, FirstQuotationDate__c FROM Opportunity WHERE Id IN :oppToQuote.keySet()]; 
        UpdateOpportunitiesOutForSignature(oppToQuote, opps);
        // update opportunities
        update opps;
    }

    public static void UpdateOpportunitiesOutForSignature(map<Id, Quote__c> oppToQuote, list<Opportunity> opps){
        /*
            When the main quote for an opportunity is out for signature, set the quote sent, 
            stage name, first quotation date and quote expiration date fields. 
        */
        for(Opportunity opp : opps) {
            opp.QuoteSent__c = true;
            opp.StageName = bg_OpportunityUtils.OPPORTUNITY_STAGE_NEGOTIATION;
            opp.FirstQuotationDate__c = Date.today();
            
            Quote__c quote = oppToQuote.get(opp.Id);
            opp.QuoteExpirationDate__c = Date.today().addDays(quote.Expiry_Days__c.intValue());
        }
    }


    private static string GetProductPricebookKey(Quote_Part__c quotePart, Id pricebookId) {
        /* Return KEY: ProductId#Pricebook2Id#CurrencyIsoCode */ 
        return quotePart.Product2__c + '#' + pricebookId + '#' + quotePart.Quote_Ref__r.Opportunity_Name__r.CurrencyIsoCode;
    }
    
    private static string GetProductPriceBookKey(PricebookEntry pbe) {
        /* Return KEY: ProductId#Pricebook2Id#CurrencyIsoCode */ 
        return pbe.Product2Id + '#' + pbe.Pricebook2Id + '#' + pbe.CurrencyIsoCode;
    } 

    private static string GetProductCurrencyKey(Quote_Part__c quotePart) {
        /* Return KEY: ProductId#Pricebook2Id#CurrencyIsoCode */ 
        return quotePart.Product2__c + '#' + quotePart.Quote_Ref__r.Opportunity_Name__r.CurrencyIsoCode;
    }
    
    private static string GetProductCurrencyKey(PricebookEntry pbe) {
        /* Return KEY: ProductId#Pricebook2Id#CurrencyIsoCode */ 
        return pbe.Product2Id + '#' + pbe.CurrencyIsoCode;
    } 
/*
RJ NOT USED
    private static List<Contact> getCountryIsoCodeForContacts (List<Contact> contacts, Set<String> countries)
    {
        List<Country_Currency__c> countryList = [SELECT Name, Country_Name__c
           FROM Country_Currency__c
           WHERE Country_Name__c in :countries];

        Map<String,String> countryMap = new Map<String,String>();
        for (Country_Currency__c cc : countryList)
        {
            countryMap.put(cc.Country_Name__c, cc.Name);
        }

        for (Contact c : contacts)
        {
            if (countryMap.containsKey(c.MailingCountry))
            {
                c.MailingCountry = countryMap.get(c.MailingCountry);
            }
            if (countryMap.containsKey(c.Local_Countyr__c))
            {
                c.Local_Countyr__c = countryMap.get(c.Local_Countyr__c);
            }
        }
        return contacts;
    }
*/

    private static void insertContactsAndUpdateDelegates(List<Contact> contacts, List<TrainingBooking__c> bookings, 
            List<TrainingDelegate__c> delegatesToUpdate, Map<Id,Contact> delegateContacts)
    {
        if (!contacts.isEmpty())
        {
            insert contacts;

            // update delegate and enrolment with contact id
            for (TrainingBooking__c booking : bookings)
            {
                for (TrainingDelegate__c delegate : booking.Training_Delegates__r)
                {
                    for (Id delegateId : delegateContacts.keySet())
                    {
                        if (delegateId == delegate.Id)
                        {
                            delegate.Conversion_Contact__c = delegateContacts.get(delegateId).Id;
                            delegatesToUpdate.add(delegate);
                        }
                    }
                }
            }

            if (!delegatesToUpdate.isEmpty())
            {
                update delegatesToUpdate;
            }
        }
    }

    private static void insertEnrolments(Map<Enrollment__c,Contact> enrolmentContacts, List<Contact> contacts, List<Enrollment__c> enrolments)
    {
        if (!enrolmentContacts.isEmpty())
        {
            // get contact id
            for (Enrollment__c e : enrolmentContacts.keySet())
            {
                for (Contact c : contacts)
                {
                    if (enrolmentContacts.get(e) != null)
                    {
                        if (c.id == enrolmentContacts.get(e).Id)
                        {
                            e.Delegate_name__c = c.Id;
                            break;
                        }
                    }
                }
                enrolments.add(e);
            }
        }

        if (!enrolments.isEmpty())
        {
            insert enrolments;
        }
    }
    
    public static void ConvertTrainingBookingIfStageClosedProcessing(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap){
        Set<Id> opportunityIds = new Set<Id>();
        Set<Opportunity> oppsToSync = new Set<Opportunity>();
        List<OpportunityLineItem> oppLineItemsForUpdate = new List<OpportunityLineItem>();
        for (Id opportunityId : newMap.keySet())
        {
            Opportunity oldOpp = oldMap.get(opportunityId);
            Opportunity newOpp = newMap.get(opportunityId);
            if (oldOpp.StageName != newOpp.StageName)
            {
                if (newOpp.StageName == bg_OpportunityUtils.OPPORTUNITY_STAGE_CLOSED_PROCESSING) {
                    opportunityIds.add(opportunityId);
                }
            }
        }
        Map<Id,Quote__c> relatedQuoteMap = new Map<Id,Quote__c>([SELECT Id
                                                                 FROM Quote__c
                                                                 WHERE Opportunity_Name__c IN : opportunityIds
                                                                 AND Main_Quote__c = true]);
        Set<Id> trainingBookingIds = new Set<Id>();
        for(TrainingBooking__c tb :[SELECT Id 
                                    FROM TrainingBooking__c 
                                    WHERE Conversion_Opportunity__c IN :opportunityIds
                                    AND Converted__c = false
                                    AND Quote__c IN :relatedQuoteMap.keySet()])
        {
            trainingBookingIds.add(tb.Id);
        }
        // if we have training bookings then convert them
        if(!trainingBookingIds.isEmpty())
        {
            TrainingBookingFunctionsV3 conversionObj = new TrainingBookingFunctionsV3(trainingBookingIds);
            conversionObj.convert();
        }
        // if we converted training bookings the related opp products SMO Scheduled date will have been set
        // SMO Scheduled dates need to calculated for opp line items not associated to a training booking
        // the below will update these
        for(OpportunityLineItem oli : [SELECT Id,
                                              OpportunityId,
                                              Opportunity.CloseDate 
                                       FROM OpportunityLineItem
                                       WHERE OpportunityId IN : opportunityIds
                                       AND SMOScheduledDate__c = null
                                       AND PricebookEntry.Product2.Course_Format__c = 'Other'
                                       AND (
                                              PricebookEntry.Product2.Training_Product_Type__c = 'Certificate' 
                                           OR PricebookEntry.Product2.Training_Product_Type__c = 'Standard' 
                                           OR PricebookEntry.Product2.Training_Product_Type__c = 'Extra Materials' 
                                           OR PricebookEntry.Product2.Training_Product_Type__c = 'Expenses' 
                                           OR PricebookEntry.Product2.Training_Product_Type__c = 'Exam Marking'
                                           )
                                       ])
        {
            Opportunity oliParentOpp = new Opportunity(Id=oli.OpportunityId);
            oppsToSync.add(oliParentOpp);
            oli.SMOScheduledDate__c = oli.Opportunity.CloseDate;
            oppLineItemsForUpdate.add(oli);
        }
        // set sync flag for related opportunities so we can update the line items.
        SetOpportunitySyncFlag(oppsToSync);
        update oppLineItemsForUpdate;
        ClearOpportunitySyncFlag(oppsToSync);
     }

     public static void SupersedeQuotes_TrainingBookings_TrainingEvents(Map<Id,Opportunity> pOldMap, Map<Id,Opportunity> pNewMap)
     {
        Set<Id> oppIdsForClearDown = new Set<Id>();
        Set<Id> eventIdsForClearDown = new Set<Id>();
        String trainingBookingCancellationReason = '';
        for(Id oppId : pNewMap.KeySet())
        {
            opportunity oldopp = pOldMap.get(oppId);
            opportunity newOpp = pNewMap.get(oppId);
            if(OPPORTUNITY_STAGE_CLOSED_WON != oldOpp.StageName && OPPORTUNITY_STAGE_CLOSED_WON == newOpp.StageName)
            {
                oppIdsForClearDown.add(oppId);
                trainingBookingCancellationReason = 'Quote Superceded';
            }
            else if(OPPORTUNITY_STAGE_CLOSED_LOST != oldOpp.StageName && OPPORTUNITY_STAGE_CLOSED_LOST == newOpp.StageName)
            {
                oppIdsForClearDown.add(oppId);
                trainingBookingCancellationReason = 'Opportunity Lost';
            }
        }
        if(!oppIdsForClearDown.isEmpty())
        {
            supercedeQuotes(oppIdsForClearDown, trainingBookingCancellationReason);
        }
     }

    /*
        Method to cancel training bookings and events on non-main quotes
    */
    public static void supercedeQuotes(Set<Id> pOppIds, String pTrainingBookingCancellationReason)
    {
        Set<Id> eventIdsForClearDown = new Set<Id>();
/*
        RJ: CHECK WE NEED TO DO THIS FOR ALL QUOTES?        
        List<Quote__c> quotesForClearDown = [SELECT Id
                                             FROM Quote__c
                                             WHERE Opportunity_Name__c IN :pOppIds
                                             AND Main_Quote__c = false
                                             AND Status__c != 'Closed - Cancelled'];
*/
        List<TrainingBooking__c> tbsForClearDown = [SELECT Id,
                                                           Training_Event__c
                                                    FROM TrainingBooking__c
                                                    WHERE Status__c != :CANCELLED_STATUS
                                                    AND Conversion_Opportunity__c IN :pOppIds
                                                    AND Converted__c = false
                                                    AND (Quote__r.Main_Quote__c = false OR Conversion_Opportunity__r.StageName = :bg_OpportunityUtils.OPPORTUNITY_STAGE_CLOSED_LOST)]; // RJ: Added to only clear down Tb on non-main quote

        for(TrainingBooking__c tb : tbsForClearDown)
        {
            eventIdsForClearDown.add(tb.Training_Event__c);
        }

        List<Training_Event__c> tesForClearDown = [SELECT Id
                                                   FROM Training_Event__c
                                                   WHERE Id IN :eventIdsForClearDown
                                                   AND Event_status__c != :CANCELLED_STATUS
                                                   AND Course__r.Course_Delivery__c = 'In-House'];

        for(TrainingBooking__c tb : tbsForClearDown)
        {
            tb.Status__c = CANCELLED_STATUS;
            tb.Reason_for_Cancelling__c = pTrainingBookingCancellationReason;
        }
        for(Training_Event__c te : tesForClearDown)
        {
            te.Event_status__c = CANCELLED_STATUS;
        }

        update tbsForClearDown;
        update tesForClearDown;
    }

    public static void CalculateEventRevenue(Map<Id,Opportunity> pOldMap, Map<Id,Opportunity> pNewMap)
    {
        // Create a Set to hold the Id of each updated Opportunity
        Set<Id> refOpportunities = new Set<Id>();
        
        // Step though each Opportunity in the trigger set and remember those where IsWon has changed
        for (Opportunity newOpp : pNewMap.Values())
        {
            Opportunity oldOpp = pOldMap.get(newOpp.Id);
            if ( ((oldOpp.IsWon != newOpp.IsWon) || (oldOpp.StageName != OPPORTUNITY_STAGE_CLOSED_PROCESSING && newOpp.StageName == OPPORTUNITY_STAGE_CLOSED_PROCESSING) || (oldOpp.StageName == OPPORTUNITY_STAGE_CLOSED_PROCESSING && newOpp.StageName != OPPORTUNITY_STAGE_CLOSED_PROCESSING)) && (!refOpportunities.contains(oldOpp.Id)) )
            {
                refOpportunities.add(oldOpp.Id);
            }
        }
        // Create a Set to hold the Id of any associated Training Events
        Set<Id> refEvents = new Set<Id>();
        for (AggregateResult ar : [select Training_Event__c from OpportunityLineItem where Opportunity.Id in :refOpportunities group by Training_Event__c])
        {
            Id trainingEventId = (Id)ar.get('Training_Event__c');
            if(null!=trainingEventId)
            {
                refEvents.add(trainingEventId);
            }
        }
        // Process if any Training Events have been referenced
        if (refEvents.size() > 0)
        {
            updateEventRevenue(refEvents);
        }
    }

    public static void CalculateEventRevenue(Map<Id,OpportunityLineItem> pOldMap, Map<Id,OpportunityLineItem> pNewMap, Boolean pIsDelete, Boolean pIsUpdate)
    {
        // Create a Set to hold the Id of each referenced Training Event
        Set<Id> refEvents = new Set<Id>();
        OpportunityLineItem oldOli = null;
        // Step though each OpportunityLineItem in the trigger set
        if(pIsDelete)
        {
            for (OpportunityLineItem oldMapOli : pOldMap.values())
            {
                if (oldMapOli.Training_Event__c != null && !refEvents.contains(oldMapOli.Training_Event__c))
                {
                    refEvents.add(oldMapOli.Training_Event__c);
                }
            }

        }
        else{
            for (OpportunityLineItem newOli : pNewMap.values())
            {
                if(null!=pOldMap)
                {
                    oldOli = pOldMap.get(newOli.Id);
                }
                // For updates, check the old values for Training Event references and check the new values for Training Event references
                if (pIsUpdate)
                {
                    if(oldOli.Training_Event__c != null)
                    {
                        if(!refEvents.contains(oldOli.Training_Event__c))
                        {
                            refEvents.add(oldOli.Training_Event__c);    
                        }
                    }
                    if(newOli.Training_Event__c != null)
                    {
                        if(!refEvents.contains(newOli.Training_Event__c))
                        {
                            refEvents.add(newOli.Training_Event__c);    
                        }
                    }
                }
                // For inserts, undeletes, check the new values for Training Event references
                else
                {
                    if (newOli.Training_Event__c != null && !refEvents.contains(newOli.Training_Event__c))
                    {
                        refEvents.add(newOli.Training_Event__c);
                    }
                }
            }   
        }
        
        // Process if any Training Events have been referenced
        if (refEvents.size() > 0)
        {
            updateEventRevenue(refEvents);
        }
    }

    private static void updateEventRevenue(Set<Id> pTrainingEventIds)
    {
        // Create an empty List to hold the Training Events that do need to be updated
        List<Training_Event__c> modEvents = new List<Training_Event__c>();

        // Populate a Map with the total revenue for each referenced Training Event (don't use aggregation because of multi-currency)
        Map<Id, Decimal> newRevenues = new Map<Id, Decimal>();
        for (OpportunityLineItem op : [SELECT Training_Event__c,
                                              TotalPrice
                                       FROM OpportunityLineItem
                                       WHERE Item_Cancelled__c = false 
                                       AND (Opportunity.StageName = :OPPORTUNITY_STAGE_CLOSED_WON OR Opportunity.StageName = :OPPORTUNITY_STAGE_CLOSED_PROCESSING) 
                                       AND Training_Event__c IN :pTrainingEventIds])
        {
            newRevenues.put(op.Training_Event__c, newRevenues.ContainsKey(op.Training_Event__c) ? newRevenues.get(op.Training_Event__c) + op.TotalPrice : op.TotalPrice);
        }

        // Step through the referenced training events and check whether the total revenue has changed
        for (Training_Event__c event : [select id, Event_Revenue__c, CurrencyIsoCode from Training_Event__c where id in :pTrainingEventIds])
        {
            // Retrieve the new value from the Map
            Decimal newRevenue = newRevenues.ContainsKey(event.id) ? newRevenues.Get(event.id) : 0;

            // Update the total revenue and record to List if it needs to be updated
            if (event.Event_Revenue__c != newRevenue)
            {
                event.Event_Revenue__c = newRevenue;
                modEvents.add(event);
            }
        }
        update modEvents;
    }

    // Calculates the number of sites & unique countries from the Opportunity Line Item 
    public static void numberOfSites(List<Opportunity> newMap){
        for (Opportunity newOpp:newMap) {
            List<OpportunityLineItem> oppLineItems = [SELECT Site__c, Site__r.Country_Code__c, Product_Name__c, Product_Name__r.Product_Type__c, Quote_Part__r.Quote_Product__c FROM OpportunityLineItem WHERE OpportunityId = :newOpp.Id];
            
            Set<String> countryCode = new Set<String>();
            Set<String> sitesUnique = new Set<String>();
            Set<String> sitesConfigured = new Set<String>();
            
            for(OpportunityLineItem oli: oppLineItems){
                //Exclude question product types
                if(oli.Site__c != null  && oli.Site__r.Country_Code__c != NULL && oli.Product_Name__r.Product_Type__c != 'Question')
                    countryCode.add(oli.Site__r.Country_Code__c);
                    
                if(oli.Site__c != null && oli.Product_Name__r.Product_Type__c != 'Question'){
                    sitesUnique.add(oli.Site__c);
                    // Combination of quote product & site is unique
                    sitesConfigured.add(oli.Quote_Part__r.Quote_Product__c + '_' + oli.Site__c);
                }
            }
            
            newOpp.SiteNumber__c = sitesUnique.size();
            newOpp.Number_of_Sites_Configured__c = sitesConfigured.size();
            newOpp.Number_of_Countries__c = countryCode.size();
        }
    }

}