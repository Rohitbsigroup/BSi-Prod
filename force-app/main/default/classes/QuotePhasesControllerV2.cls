/********************************************************************
 * QuotePhasesControllerV2
 *
 * Visualforce Controller used to guide the user within the quote
 *              phases (Send to Customer, Discount Approval, C-Codes Approval).
 * 
 * Author: Richard Jimenez
 * Created: 28-10-2013
 * Changes: 
 *          21-11-2014 RPJ - Added new discount matrix methods
 *                         - Removed redundant / unused code
 *          02-10-2014 KM - Added method reset quote stages to allow
 *                          the customer to return to the first stage
 *          29-09-14 ASD BG - Minor changes to the Generate Conga URL Methods (Fact Validation, Proposal) to replace button press with redirect to new VF page for template selection
 *          10-02-15 KM     - changed show clone boolean
 *          26-06-15 RPJ - Added Operations Team Review Process
 *          04-01-16 JT - Added getIsQuoteReady method
 *          25-01-16 KM - Added getCanAnyoneSendProposal method to check opp status formula.
 *          03-11-16 ADS - SoW027
 *                       - Added methods;
 *                       -   GetQuoteOperationsApprovalQueueMember()
 *                       -   SetQuoteOperationsApprovalQueueMember()
 *                       -   getCanRescindOperationsApproval()
 *                       -   getRequiresOperationsApproval() 
 *                       -   showOpsRescind()
 *                       -   RescindOperationsApproval()
 *                       - Removed use of and references to Operations Team Approver
 *          18-07-17 AV  - Created a new method call autoSkipCustomer. This will help to avoid the creation of the facts validation document based on BSI Permisison Custom settings (Can Skip Fact Validation)
 *          06-09-17 IB  - Check quote has a Contact on Proposal Document as Contact is no longer mandatory on QuoteBulder page
 *          07-09-17 RC  - Added extra functionality around the ps approval button.   
 *          14-09-17 RC  - called function to load approval user from user field on load.       
 *          26-02-18 AV  - Add condition (Configuration Completed == true) on the method autoSkipCustomer.
 ********************************************************************/
public class QuotePhasesControllerV2 {

    // QUOTE VARIABLES
    public Quote__c quote {get; private set;}

    // SETTINGS
    public QuoteSetting__c quoteSettings {get; private set;}

    // BUTTONS LOCK
    public boolean showAddProdsBtn {get; private set;}
    public boolean showConfigureBtn {get; private set;}
    public boolean showCloneBtn {get; private set;}
    public boolean showKeyFactsDocBtn {get; private set;}
    public boolean showCCodeApprovalBtn {get; private set;}
    public boolean showUpdateDiscountBtn {get; private set;}
    public boolean showTechReviewDocBtn {get; private set;}
    public boolean showFinanceApprovalBtn {get; private set;}
    public boolean showProposalDocBtn {get; private set;}
    public boolean showSalesBriefDocBtn {get; private set;}
    public boolean showOperationsApprovalBtn {get; private set;}
    public boolean showRescindOperationsApprovalBtn {get; private set;}
    public boolean showPsProposalBtn {get; private set;}

    // ------ DOCUMENTS ------
    //   KEY FACTS
    public echosign_dev1__SIGN_Agreement__c keyFactsDoc {get; private set;}
    public boolean nokeyFactsDoc {get; private set;}
    //   PROPOSAL
    public echosign_dev1__SIGN_Agreement__c techReviewDoc {get; private set;}
    public boolean noTechReviewDoc {get; private set;}
    //   PROPOSAL
    public echosign_dev1__SIGN_Agreement__c proposalDoc {get; private set;}
    public boolean noProposalDoc {get; private set;}
    
    // WARNINGS
    public boolean noParts {get; private set;}
    public boolean noProducts {get; private set;}
    public boolean noApprovers {get; private set;}
    public boolean noAgentDiscounts {get; private set;}
    public boolean configurationCompleted {get; private set;}
    public boolean readyToQuote {get; private set;}
    public boolean factsExceedDocLimit {get; private set;}

    // TOP PAGE CONTROL
    public boolean reloadNeeded {get; private set;}
    public string reloadPageURL {get; private set;}

    // APPROVERS
    public map<Id, User> UserMap {get; private set;}
    public boolean skipPreApprover {get; set;}
    public boolean showSkipPreApprover {get; set;}  
    public map<string, map<string, User>> discountApproversMap {get; private set;} // new
    public map<Id, Quote_Product_Approval__c> qpaMap {get; private set;}
    public map<string, OptionListWrapper> cCodeApproversMap {get; private set;}
    public boolean showLocalApprovers {get; set;}
    private set<string> allccodes;
    private set<string> ccodesRequired;
    
    private boolean quoteOperationsApprovalQueueMember;

    //This should never be cached as it is changed in the back end by blue zebra
    public transient Integer syncStatus {get; private set;}
    public string syncStatusMessage {get; private set;}

	public boolean canImport {get; set;}
    
    public class OptionListWrapper {
        public list<SelectOption> Options {get;set;}
        public OptionListWrapper(list<SelectOption> optionsList) {
            options = optionsList;
        }
        public integer size { 
            get { return options.size(); } 
        }
    }

    public QuotePhasesControllerV2(ApexPages.StandardController std) {
        /*
            QuotePhasesControllerV2 Constructor
        */
        try {
            // Initialise variables
            Id quoteId = std.getId();
    
            // Get Quote Settings (used by VF page)
            quoteSettings = bg_CustomSettingsUtils.GetQuoteSettings();
    
            // Load Quote
            quote = bg_QuoteUtils.GetQuoteById(quoteId, true);
    
            // Check for Opportunity Id
            if(quote.Opportunity_Name__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Quote must be associated to an Opportunity'));
                return;
            }
    
            // Ensure quote validation is set
            if(bg_StringUtils.IsBlank(quote.ValidationStatus__c)) { quote.ValidationStatus__c = quoteSettings.StatusDraft__c; }
            
            // build user map
            userMap = bg_UserUtils.GetUserMap(false);
                        
            // Check for products & parts (excludes questions)
            noAgentDiscounts = !(bg_DiscountUtils.HasDiscountUserMatrix(quote.ownerId));            
            noProducts = (bg_QuoteUtils.GetQuoteProducts(quote.Id, true).size() == 0);
            noParts = (bg_QuoteUtils.GetQuoteParts(quote.Id).size() == 0);
            configurationCompleted = !(bg_QuoteUtils.ContainsUnconfiguredProducts(quote.Id));

            readyToQuote = (!noParts && configurationCompleted);

            // Setup Documents
            SetupDocuments();
            
            // Set C-Code Status
            SetupCCodeStatus();

            // Setup Discount Status
            SetupDiscountStatus();
        
            // Setup Finance Status
            SetupFinanceStatus();
        
            // Setup Operations Review Status
            SetupOperationsReviewStatus();
            
            // Setup Quote Page Buttons
            SetupQuotePageButtons();

            // Check if the Sync Process Has Errored
            checkSyncError();
            
            canImport = bg_CustomSettingsUtils.GetPermissionSettings().Can_Import_Quote_Parts__c;
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
        }   
    }

    private void SetupPsProposalLookup()
    {
        quote.PS_Proposal_Approval_User__c = bg_UserUtils.GetUserById(UserInfo.getUserId()).PS_Approval_User__c;

    }

    public void submitProposalForApproval()
    {
        try
        {
            //update the user object.
            bg_UserUtils.UpdateUserRecordForPs(quote.PS_Proposal_Approval_User__c);

            //update the approver field if it gets approved display on the screen.
            quote.PS_Proposal_Approver__c = quote.PS_Proposal_Approval_User__c;
            
            quote.PS_Proposal_Approval_Status__c = bg_QuoteApprovalUtils.APPROVAL_STATUS_SUBMITTED;
            // Save Quote
            bg_QuoteUtils.SaveQuote(quote);
            bg_QuoteApprovalUtils.SubmitForApproval(quote.Id, 'Submitting Proposal for Approval.');

            ReloadQuotePage();
        } 
        catch (Exception ex) 
        {
            Apexpages.addMessages(ex);
        }
    }

    private boolean showConfigure()
    {
        return !getValidationStatusNA() && getValidationStatusDraft() 
        || (getValidationStatusRejected() && 
            !getCCodeStatusApproved() && !getCCodeStatusPending() &&
            !getDiscountStatusApproved() && !getDiscountStatusPending() &&
            !getTechReviewStatusApproved() && !getTechReviewStatusPending() &&
            !getFinanceStatusApproved() && !getFinanceStatusPending() &&
            !getOperationsReviewStatusApproved() && !getOperationsReviewStatusPending() &&
            noProposalDoc);
    }
    
    private boolean showClone()
    {
        return !noParts && quote.Is_Clonable__c;
    }
    
    private boolean showKeyFactValidation()
    {
        return readyToQuote && showConfigure();
    }

    private boolean showTechReview()
    {
        return getCustomerComplete() && getCCodeComplete() && getDiscountComplete()
            && !getTechReviewComplete() && !getTechReviewStatusPending();
    }

    private boolean showFinanceReview()
    {

        return getCustomerComplete() && getCCodeComplete() && getDiscountComplete() && getTechReviewComplete()
            && !getFinanceStatusComplete() && !getFinanceStatusPending();
    }

    private boolean showOpsReview()
    {
        return getCustomerComplete() && 
            getCCodeComplete() && 
            getDiscountComplete() && 
            getTechReviewComplete() && 
            getFinanceStatusComplete() && 
            !getOperationsReviewStatusComplete() && 
            !getOperationsReviewStatusPending() &&
            getRequiresOperationsApproval();
    }
    
    private boolean showOpsRescind()
    {
        return getCustomerComplete() && 
            getCCodeComplete() && 
            getDiscountComplete() && 
            getTechReviewComplete() && 
            getFinanceStatusComplete() &&
            getOperationsReviewStatusComplete() &&
            !getOperationsReviewStatusPending() &&
            getCanRescindOperationsApproval();
    } // showOpsRescind

    private boolean showProposal()
    {
        return getCustomerComplete() && getCCodeComplete() && getDiscountComplete() && getTechReviewComplete() && getFinanceStatusComplete()
            && !getProposalStatusComplete() && getCanSendProposal();
    }  

    private boolean showPsProosal()
    {
        return bg_CustomSettingsUtils.GetPermissionSettings().Can_See_Ps_Approval_Propsal_Button__c;
    }     

    private boolean showSOW()
    {
        return getProposalStatusComplete() && getCanSendProposal();
    }

    private void SetupQuotePageButtons() {
        /*
            Setup Quote Page Buttons
        */

        // Show Add Products Button
        showAddProdsBtn = showConfigure();                          

        // Show Configure Button
        showConfigureBtn = showConfigure();

        // Show Clone button
        showCloneBtn = showClone();

        // Show Key Facts Document Button
        showKeyFactsDocBtn = showKeyFactValidation();

        // Show Tech Review Document Button
        showTechReviewDocBtn = showTechReview();

        // Show Finance Approval Button
        showFinanceApprovalBtn = showFinanceReview();

        // Show Ops Review Button
        showOperationsApprovalBtn = showOpsReview();
        
        // Show Ops Rescind Button
        showRescindOperationsApprovalBtn = showOpsRescind();

        // Show Proposal Document Button
        showProposalDocBtn = showProposal();
        
        // Show Sales Brief Document Button
        showSalesBriefDocBtn = showSOW();

        //show the proposal button
        showPsProposalBtn = showPsProosal();

        //setup lookup to point to user preferences
        SetupPsProposalLookup();
    }

    private void SetupDocuments() {
        /*
            Setup Documents
        */
        // Set warning if facts exceed template limit
        factsExceedDocLimit = bg_DocumentUtils.CheckFactsExceedsDocLimit(quote.Id);
        
        // Check for key facts document - should match name of quote
        keyFactsDoc =  bg_DocumentUtils.GetLatestAgreement(quote.Id, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION);
        nokeyFactsDoc = (keyFactsDoc == null);

        // Check for Proposal document - should match name of quote
        proposalDoc =  bg_DocumentUtils.GetLatestAgreement(quote.Id, bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL);
        noProposalDoc = (proposalDoc == null);

        // Check for Tech Review document - should match name of quote
        techReviewDoc =  bg_DocumentUtils.GetLatestAgreement(quote.Id, bg_DocumentUtils.DOCUMENT_TYPE_TECH_REVIEW);
        noTechReviewDoc = (techReviewDoc == null);
    }

    public boolean getCustomerComplete() {
        /* Return Customer Complete */
        return getValidationStatusApproved() || getValidationStatusNA() 
            || getValidationStatusPending() || getValidationStatusRejected();
    }

    public boolean getDiscountComplete() {
        /* Return Discount Complete */
        return getDiscountStatusApproved() || getDiscountStatusNA();
    }
    
    public boolean getCCodeComplete() {
        /* Return C-Code Complete */
        return getCCodeStatusApproved() || getCCodeStatusNA();
    }

    public boolean getRequiresDiscountPreApprover() {
        /* Return if Discount Pre Approver is required */
        return (discountApproversMap != null && discountApproversMap.get(bg_DiscountUtils.PREAPPROVER_FIELD_NAME).size() > 0);  
    }
    
    private void SetupDiscountStatus() {
        /*
            Setup Discount Status
        */
        try {
            skipPreApprover = false;
            discountApproversMap = bg_DiscountUtils.GetQuoteDiscountApprovers(quote.Id);
            showSkipPreApprover = bg_DiscountUtils.RequiresPreApproval(discountApproversMap);
            quote.DiscountStatus__c = bg_DiscountUtils.SetDiscountStatus(quote.DiscountStatus__c, discountApproversMap);

            // Show Discount Button if not set, NA, Draft or Rejected
            showUpdateDiscountBtn  = getDiscountStatusNA() || getDiscountStatusDraft() || getDiscountStatusRejected();

            // Also, not approved / pending
            showUpdateDiscountBtn = showUpdateDiscountBtn &&
                                        !getFinanceStatusApproved() && !getFinanceStatusPending() &&
                                        !getOperationsReviewStatusApproved() && !getOperationsReviewStatusPending() &&
                                        !getProposalStatusApproved() && !getProposalStatusPending();

        } catch (Exception ex) {
            quote.DiscountStatus__c = '';
            ApexPages.addMessages(ex);
        }
    }

    public void SkipTechReview() {
        /*
            Skip Tech Review
        */
        try {
            bg_QuoteUtils.SkipTechReview(quote);

            ReloadQuotePage();

        } catch (DmlException ex) {
            Apexpages.addMessages(ex);
        }
    }

    private void SetupCCodeStatus() {
        /*
            Setup CCode Status
        */
        //try {
            // Get Quote Product Approval Map
            showLocalApprovers = true;
            qpaMap = bg_QuoteApprovalUtils.GetQuoteProductApprovalsMap(quote.Id);
            allccodes = new set<string>();
            ccodesRequired = new set<string>();
            for(Quote_Product_Approval__c qpa : qpaMap.values()) {
                //allccodes.add(qpa.Product__r.CCode__c);
                if(!bg_StringUtils.IsBlank(qpa.Product__r.CCode__c)) {
                    allccodes.add(qpa.Product__r.CCode__c);
                    if(qpa.CCodeStatus__c != quoteSettings.StatusApproved__c) {
                        ccodesRequired.add(qpa.Product__r.CCode__c);
                    }
                }
            }

            // UpdateCCodeStatus
            map<string, set<CCode_Profile__c>> userCCodes = bg_QuoteApprovalUtils.GetCCodeApprovers(allccodes, quote.OwnerId);
            ccodesRequired = bg_QuoteApprovalUtils.UpdateCCodeStatus(quote, userCCodes, ccodesRequired, qpaMap.values());

            // Get C-Code Approvers
            GetCCodeApprovers();

            showCCodeApprovalBtn = (quote.CCodeStatus__c == quoteSettings.StatusRejected__c || quote.CCodeStatus__c == quoteSettings.StatusDraft__c);
        //} catch (Exception ex) {
            //ApexPages.addMessages(ex);
        //}     
    }
    
    public void GetCCodeApprovers() {
        /*
            Get C-Code Approvers
        */
        string countryCode = (showLocalApprovers?userMap.get(quote.OwnerId).OperationCountry__c:'');
        map<string, set<CCode_Profile__c>> ccaMap = bg_QuoteApprovalUtils.GetCCodeApprovers(allccodes, null, countryCode);
        cCodeApproversMap = new map<string, OptionListWrapper>();
        noApprovers = false;
        for(string ccode : allccodes) {
            //if(ccodesRequired.contains(ccode)) {
                if(ccaMap.containsKey(ccode)) {
                    set<Id> approverIds = new set<Id>();
                    for(CCode_Profile__c ccp : ccaMap.get(ccode)) {
                        approverIds.add(ccp.User__c);
                    }
                    cCodeApproversMap.put(ccode, new OptionListWrapper(bg_ControllerUtils.CreateSelectOptions(approverIds, userMap, 'Id', 'name', true, true)));                
                } else if(!ccodesRequired.contains(ccode)) {
                    cCodeApproversMap.put(ccode, new OptionListWrapper(new list<SelectOption>()));
                } else {
                    cCodeApproversMap.put(ccode, new OptionListWrapper(new list<SelectOption>()));
                    noApprovers = true;
                }
            //}
        }
    }
    
    public boolean getCanSkipFactValidation() {
        /*
            Return if Fact Valiation can be skipped
        */
        return readyToQuote && !getCustomerComplete() && !getValidationStatusPending(); //(!getCustomerComplete() && !bg_StringUtils.IsBlank(quote.Proposal_Scope__c));
    }
    
    public void ResetQuoteStages() {
        /*
            Reset quote stages clears quote fields to move back to stage 1
        */
        try {
            if(getResetVisibility()) {
                bg_QuoteUtils.ResetQuoteStages(quote); 
                ReloadQuotePage(); 
            } else {
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Quote_Reset_Proposal_Exists));
            }
        } catch (Exception ex) {
            Apexpages.addMessages(ex);
        }
    }
/*
    This will automatically skip the facts validation based on the Custom settings permission when the page is loaded
*/
    public void autoSkipCustomer()
    {
        System.debug('autoSkipCustomer: bg_CustomSettingsUtils.GetPermissionSettings().Can_Skip_Fact_Validation__c && !quote.SkipCustomer__c && quote.Configuration_Completed__c:' + bg_CustomSettingsUtils.GetPermissionSettings().Can_Skip_Fact_Validation__c + ' --- ' + !quote.SkipCustomer__c + ' --- ' + quote.Configuration_Completed__c);
        if (bg_CustomSettingsUtils.GetPermissionSettings().Can_Skip_Fact_Validation__c && !quote.SkipCustomer__c && quote.Configuration_Completed__c)
        {
            SkipCustomer();
        }
    }
    public void SkipCustomer() {
        /*
            Skip Customer
        */
        try {
            if(!checkSyncError())
            {
                // Skip Facts validation
                bg_QuoteUtils.SkipFactsValidationByCustomer(quote);

                // Sync quote with opportunity
                bg_QuoteUtils.SyncQuoteWithOpportunity(quote.Id);       
                            
                showKeyFactsDocBtn = false;
                
                SetupQuotePageButtons();
            }
        } catch (DmlException ex) {
            Apexpages.addMessages(ex);
        }
    }
    
    private void SetupFinanceStatus() {
        /*
            Setup Finance Status
        */
        if(bg_StringUtils.IsBlank(quote.Finance_Director__c)) {
            bg_QuoteUtils.SetFinanceDirector(quote);
        }
        
        if(bg_StringUtils.IsBlank(quote.FinanceStatus__c)) {
            if(bg_QuoteApprovalUtils.IsFinanceApprovalRequired(quote)) {
                quote.FinanceStatus__c = quoteSettings.StatusDraft__c;
            } else {            
                quote.FinanceStatus__c = quoteSettings.StatusNA__c;
            }
        }
    }
 
    /*
            Setup Operation Review Status
    */
    private void SetupOperationsReviewStatus()
    {
        
        if(String.isBlank(quote.OperationsReviewStatus__c)) {
            if(bg_QuoteApprovalUtils.IsOperationsReviewRequired(quote)) {
                quote.OperationsReviewStatus__c = quoteSettings.StatusDraft__c;
                quote.OperationsToSendProposal__c = true;
            } else {            
                quote.OperationsReviewStatus__c = quoteSettings.StatusNA__c;
            }
        }        
        
        SetQuoteOperationsApprovalQueueMember();
    }
    
    private void ReloadQuotePage() {
        /*
            Reload Quote Page
        */
        ReloadPage(getQuotePageUrl());
    }

    private void ReloadPage(string pageUrl) {
        /*
            Reload Page
        */
        reloadNeeded = true;
        reloadPageURL = pageUrl;
    }
    
    public Boolean getResetVisibility() {
        /*
            Gets the visiblity state for the reset button at stage 1 of the detail page
        */
        
        
        return  !getCanSkipFactValidation() &&
                !getValidationStatusPending() && !getValidationStatusApproved() &&
                noProposalDoc && !getProposalSignedOffline() &&
                !bg_QuoteUtils.CheckAnyQuoteStatusPending(quote) && 
                !bg_QuoteApprovalUtils.CheckQuoteApprovalsPending(quote.id) &&
                !getOperationsReviewStatusApproved() &&
                !ShowConfigure();
    }

    /*--------------------------------------------*/
    /* FACT VALIDATION STATUS                     */
    public boolean getValidationStatusNA() {
        /* Return Validation Status NA */
        return quote.SkipCustomer__c;
    }

    public boolean getValidationStatusApproved() {
        /* Return Validation Status approved */
        return (keyFactsDoc != null && bg_documentUtils.CheckDocumentStatus(keyFactsDoc, bg_documentUtils.DOCUMENT_STATUS_SIGNED));
    }
    
    public boolean getValidationStatusRejected() {
        /* Return Validation Status rejected */
        return (keyFactsDoc != null && bg_documentUtils.CheckDocumentStatus(keyFactsDoc, bg_documentUtils.DOCUMENT_STATUS_REJECTED));
    }

    public boolean getValidationStatusDraft() {
        /* Return Validation Status Draft */
        return (keyFactsDoc == null || bg_documentUtils.CheckDocumentStatus(keyFactsDoc, new set<string>{bg_documentUtils.DOCUMENT_STATUS_DRAFT, bg_documentUtils.DOCUMENT_STATUS_NOT_SENT}));
    }

    public boolean getValidationStatusPending() {
        /* Return Validation Status Pending */
        return (keyFactsDoc != null && bg_documentUtils.CheckDocumentStatus(keyFactsDoc, bg_documentUtils.DOCUMENT_STATUS_PENDING));
    }
    
    /*--------------------------------------------*/
    /* DISCOUNT STATUS                            */    
    public boolean getNoDiscountApprover() {
        /* Return if discount approver is missing */
        //return discountApproverRole == bg_QuoteApprovalUtils.DISCOUNT_APPROVER_NONE;
        return bg_StringUtils.IsBlank(quote.DiscountStatus__c); 
    }

    public boolean getDiscountStatusNA() {
        /* Return Discount Status NA */
        //return getDiscountsSet() && quote.DiscountStatus__c == quoteSettings.StatusNA__c;
        return quote.DiscountStatus__c == quoteSettings.StatusNA__c;
    }
    
    public boolean getDiscountStatusApproved() {
        /* Return Discount Status Approved */
        return quote.DiscountStatus__c == quoteSettings.StatusApproved__c;      
    }
    
    public boolean getDiscountStatusPending() {
        /* Return Discount Status Pending */
        return quote.DiscountStatus__c == quoteSettings.StatusWaiting__c;
    }
    
    public boolean getDiscountStatusRejected() {
        /* Return Discount Status Rejected */
        return quote.DiscountStatus__c == quoteSettings.StatusRejected__c;
    }
    
    public boolean getDiscountStatusDraft() {
        /* Return Discount Status Draft */
        return quote.DiscountStatus__c == quoteSettings.StatusDraft__c;
    }
    
    public decimal getNoDiscountableParts() {
        return bg_QuoteApprovalUtils.NO_DISCOUNTABLE_PRODUCTS;
    }   

    /*--------------------------------------------*/
    /* C-CODE STATUS                              */    
    public boolean getCCodeStatusNA() {
        /* Return Discount Status NA */
        return quote.CCodeStatus__c == quoteSettings.StatusNA__c;
    }
    
    public boolean getCCodeStatusApproved() {
        /* Return Discount Status Approved */
        return quote.CCodeStatus__c == quoteSettings.StatusApproved__c;     
    }
    
    public boolean getCCodeStatusPending() {
        /* Return Discount Status Pending */
        return quote.CCodeStatus__c == quoteSettings.StatusWaiting__c;
    }
    
    public boolean getCCodeStatusRejected() {
        /* Return Discount Status Rejected */
        return quote.CCodeStatus__c == quoteSettings.StatusRejected__c;
    }
    
    public boolean getCCodeStatusDraft() {
        /* Return Discount Status Draft */
        return quote.CCodeStatus__c == quoteSettings.StatusDraft__c;
    }

    /*--------------------------------------------*/
    /* TECHNICAL REVIEW STATUS                    */
    public boolean getTechReviewStatusNA() {
        /* Return Technical Review Status NA */
        return !(bg_QuoteApprovalUtils.IsTechReviewRequired(quote) && !quote.SkipTechReview__c);
    }

    public boolean getTechReviewStatusApproved() {
        /* Return Technical Review Status approved */
        return (techReviewDoc != null && bg_documentUtils.CheckDocumentStatus(techReviewDoc, bg_documentUtils.DOCUMENT_STATUS_SIGNED));
    }
    
    public boolean getTechReviewStatusRejected() {
        /* Return Technical Review Status rejected */
        return (techReviewDoc != null && bg_documentUtils.CheckDocumentStatus(techReviewDoc, bg_documentUtils.DOCUMENT_STATUS_REJECTED));
    }
    
    public boolean getTechReviewStatusDraft() {
        /* Return Technical Review Status Draft */
        return (!getTechReviewStatusNA() && (techReviewDoc == null || bg_documentUtils.CheckDocumentStatus(techReviewDoc, new set<string>{bg_documentUtils.DOCUMENT_STATUS_DRAFT, bg_documentUtils.DOCUMENT_STATUS_NOT_SENT})));
    }

    public boolean getTechReviewStatusPending() {
        /* Return Technical Review Status Pending */
        return (techReviewDoc != null && bg_documentUtils.CheckDocumentStatus(techReviewDoc, bg_documentUtils.DOCUMENT_STATUS_PENDING));
    }
    
    public boolean getTechReviewComplete() {
        /* Return Tech Review Complete */
        return getTechReviewStatusApproved() || getTechReviewStatusNA();
    }
        
    public list<SelectOption> getTechReviewTeams() {
        /* Return list of Technical Review Teams */
        list<Contact> techTeamContacts = bg_ContactUtils.GetContactsByRecordType(bg_ContactUtils.RECORD_TYPE_NAME_TECH_REVIEW_TEAM);
        return bg_ControllerUtils.CreateSelectOptions(techTeamContacts, 'Id', 'name', true, true);      
    }

    /*--------------------------------------------*/
    /* PROPOSAL STATUS                     */
    public boolean getProposalStatusNA() {
        /* Return Proposal Status NA */
        return false;
    }

    public boolean getProposalStatusApproved() {
        /* Return Proposal Status approved */
        return (proposalDoc != null && bg_documentUtils.CheckDocumentStatus(proposalDoc, bg_documentUtils.DOCUMENT_STATUS_SIGNED));
    }

    public boolean getProposalStatusRejected() {
        /* Return Proposal Status rejected */
        return !getProposalSignedOffline() && (proposalDoc != null && bg_documentUtils.CheckDocumentStatus(proposalDoc, bg_documentUtils.DOCUMENT_STATUS_REJECTED));
    }
    
    public boolean getProposalStatusDraft() {
        /* Return Proposal Status Draft */
        return !getProposalSignedOffline() && (proposalDoc == null || bg_documentUtils.CheckDocumentStatus(proposalDoc, new set<string>{bg_documentUtils.DOCUMENT_STATUS_DRAFT, bg_documentUtils.DOCUMENT_STATUS_NOT_SENT}));
    }

    public boolean getProposalStatusPending() {
        /* Return Proposal Status Pending */
        return !getProposalSignedOffline() && (proposalDoc != null && bg_documentUtils.CheckDocumentStatus(proposalDoc, bg_documentUtils.DOCUMENT_STATUS_PENDING));
    }

    public boolean getProposalStatusComplete() {
        /* Return Tech Review Complete */
        return getProposalStatusApproved() || getProposalSignedOffline();
    }
    
    public boolean getProposalSignedOffline() {
        /* Return Proposal Signed Offline */
        return (quote.ProposalSignedOffline__c);
    }
 
    /*--------------------------------------------*/
    /* PS ONLY PROPOSAL APPROVAL STATUS                   */ 
    public boolean getPSProposalStatusApproved() {
        /* Return Finance Status Approved */
        return quote.PS_Proposal_Approval_Status__c == quoteSettings.StatusApproved__c;       
    }
    public boolean getPSProposalStatusPending() {
        /* Return Finance Status Pending */
        return quote.PS_Proposal_Approval_Status__c == quoteSettings.StatusWaiting__c;
    }
    
    public boolean getPSProposalStatusRejected() {
        /* Return Finance Status Rejected */
        return quote.PS_Proposal_Approval_Status__c == quoteSettings.StatusRejected__c;
    }
    
    public boolean getPSProposalStatusDraft() {
        /* Return Finance Status Draft */
        return quote.PS_Proposal_Approval_Status__c == quoteSettings.StatusDraft__c;
    }
    
    /*--------------------------------------------*/
    /* FINANCE STATUS                            */ 
    public boolean getFinanceStatusNA() {
        /* Return Finance Status NA */
        return !bg_QuoteApprovalUtils.IsFinanceApprovalRequired(quote);
        //return quote.FinanceStatus__c == quoteSettings.StatusNA__c;
    }
    
    public boolean getFinanceStatusApproved() {
        /* Return Finance Status Approved */
        return quote.FinanceStatus__c == quoteSettings.StatusApproved__c;       
    }
    
    public boolean getFinanceStatusPending() {
        /* Return Finance Status Pending */
        return quote.FinanceStatus__c == quoteSettings.StatusWaiting__c;
    }
    
    public boolean getFinanceStatusRejected() {
        /* Return Finance Status Rejected */
        return quote.FinanceStatus__c == quoteSettings.StatusRejected__c;
    }
    
    public boolean getFinanceStatusDraft() {
        /* Return Finance Status Draft */
        return quote.FinanceStatus__c == quoteSettings.StatusDraft__c;
    }
    
    public boolean getFinanceStatusComplete() {
        /* Return Finance Status Complete */
        return getFinanceStatusApproved() || getFinanceStatusNA();
    }

    /*--------------------------------------------*/
    /* OPS REVIEW STATUS                          */
    public boolean getOperationsReviewStatusNA() {
        /* Return Operations Review Status Status NA */
        return quote.OperationsReviewStatus__c == quoteSettings.StatusNA__c;
    }

    public boolean getOperationsReviewStatusApproved() {
        /* Return Operations Review Status approved */
        return quote.OperationsReviewStatus__c == quoteSettings.StatusApproved__c;
    }

    public boolean getOperationsReviewStatusRejected() {
        /* Return Operations Review Status rejected */
        return quote.OperationsReviewStatus__c == quoteSettings.StatusRejected__c;
    }
    
    public boolean getOperationsReviewStatusDraft() {
        /* Return Operations Review Status Draft */
        return quote.OperationsReviewStatus__c == quoteSettings.StatusDraft__c;
    }

    public boolean getOperationsReviewStatusPending() {
        /* Return Operations Review Status Pending */
        return quote.OperationsReviewStatus__c == quoteSettings.StatusWaiting__c;
    }

    public boolean getOperationsReviewStatusComplete() {
        /* Return Operations Review Status Complete */
        return getOperationsReviewStatusApproved() || getOperationsReviewStatusNA();
    }

    /* Method to return if operation are to send the proposal */
    public boolean getCanSendProposal()
    {
        // or can change to closed won
        return  !quote.OperationsToSendProposal__c ||
                (quote.OperationsToSendProposal__c && 
                (getOperationsReviewStatusPending() || getOperationsReviewStatusApproved()) &&
                 GetQuoteOperationsApprovalQueueMember());
    }

    /* Method to return if the proposal can be sent by anyone*/
    public boolean getCanAnyoneSendProposal()
    {
        return quote.Opportunity_Name__r.Can_Send_Proposal__c;
    }
    
    /* Method to return if the User can rescind the Operation Approval */
    public boolean getCanRescindOperationsApproval()
    {
        return !getProposalStatusApproved() &&
            !quote.ProposalSignedOffline__c &&
            GetQuoteOperationsApprovalQueueMember();
    } // getCanRescindOperationsApproval
    
    /* Method to return if the User requires Operation Approval */
    public boolean getRequiresOperationsApproval()
    {
        return userMap.get(UserInfo.getUserId()).Requires_Operations_Approval__c;
    } // getRequiresOperationsApproval

    // ----------------- NAVIGATION BUTTONS ----------------- //

    private string getQuotePageUrl() {
        /*
            Reload the full page
        */
        ApexPages.StandardController sc = new ApexPages.StandardController(quote);  
        PageReference pageRef = sc.view();
        return pageRef.getUrl();    
    }
    
    public void RequestDiscountApproval() {
        /*
            Request Discount Approval
        */
        try {
            if(retrieveQuoteStatus())
            {
                // Populate discount approvers on the quote
                bg_DiscountUtils.PopulateQuoteDiscountApprovers(quote, discountApproversMap, skipPreApprover);
                // Save Quote
                bg_QuoteUtils.SaveQuote(quote);
                // Sync quote with opportunity
                bg_QuoteUtils.SyncQuoteWithOpportunity(quote.Id);   
                // Submit for approval & check success
                if(bg_QuoteApprovalUtils.SubmitForApproval(quote.Id, 'Submitting request for Discount approval.').isSuccess()) {
                    ReloadQuotePage(); 
                }
            }
        } catch (Exception ex) {
            string chkMsg = ex.getMessage();
            if (chkMsg.contains('No applicable approval process found'))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No applicable approval process found OR you are not the Quote Owner.'));
            }
            else
            {
                Apexpages.addMessages(ex);
            }
        }
    }

    public void RequestFinanceApproval() {
        /*
            Request Finance Approval
        */
        try {
            if(retrieveQuoteStatus())
            {
                // Set Status to submitted
                quote.FinanceStatus__c = bg_QuoteApprovalUtils.APPROVAL_STATUS_SUBMITTED;
                // Save Quote
                bg_QuoteUtils.SaveQuote(quote);
                // Sync quote with opportunity
                bg_QuoteUtils.SyncQuoteWithOpportunity(quote.Id);       
                // Submit for approval & check success
                if(bg_QuoteApprovalUtils.SubmitForApproval(quote.Id, 'Submitting request for Finance approval.').isSuccess()) 
                {
                    ReloadQuotePage(); 
                }
            }
        } catch (Exception ex) {
            Apexpages.addMessages(ex);
        }
    }

    /*
        Request Operations Approval
    */
    public void RequestOperationsApproval() {
        try {
            if(retrieveQuoteStatus())
            {
                // Set Status to submitted
                quote.OperationsReviewStatus__c = bg_QuoteApprovalUtils.APPROVAL_STATUS_SUBMITTED;
                // Save Quote
                bg_QuoteUtils.SaveQuote(quote);
                // Sync quote with opportunity
                bg_QuoteUtils.SyncQuoteWithOpportunity(quote.Id);       
                // Submit for approval & check success
                if(bg_QuoteApprovalUtils.SubmitForApproval(quote.Id, 'Submitting request for Operations approval.').isSuccess()) {
                    ReloadQuotePage(); 
                }
            }
        } catch (Exception ex) {
            Apexpages.addMessages(ex);
        }   
    }
    
    public void RescindOperationsApproval()
    {

        try
        {

            if (retrieveQuoteStatus())
            {
                
                // Set Status to not declined (inline with approval process rejection actions)
                quote.OperationsReviewStatus__c = bg_QuoteApprovalUtils.APPROVAL_STATUS_DECLINED;
                // Set the 'Date/Time Declined [Operations]'
                quote.OperationsDateTimeDeclined__c = Datetime.now();
                // Reset the 'Date/Time Submitted [Operations]'
                quote.OperationsDateTimeSubmitted__c = null;
                // Reset the 'Date/Time Approved [Operations]'
                quote.OperationsDateTimeApproved__c = null;
                // Reset the 'Operation Approval Queue'
                quote.Operations_Approval_Queue__c = null;                
                // Reset 'Generate Offline Copy?' for offline proposals
                quote.CongaOfflineDoc__c = false;                
                // Cancel open proposals
                if (!noProposalDoc)
                {
                    delete proposalDoc;                                         
                }
                // Save Quote
                bg_QuoteUtils.SaveQuote(quote);
                // Sync quote with opportunity
                bg_QuoteUtils.SyncQuoteWithOpportunity(quote.Id); 
                ReloadQuotePage();                
            }
        }
        catch (Exception e)
        {
            Apexpages.addMessages(e);
        }
        
    } // RescindOperationsApproval
    
    public void ApproveCCode() {
        /*
            Request CCode Approval
        */
        try {
            if(retrieveQuoteStatus())
            {
                // Save Quote
                bg_QuoteUtils.SaveQuote(quote);
                
                // Save Quote Approval Records
                bg_QuoteApprovalUtils.SaveQuoteProductApprovals(qpaMap.values());       

                // submit all quote product approval records
                for(Quote_Product_Approval__c qpa : qpaMap.values()) {
                    if(!bg_StringUtils.IsBlank(qpa.CCodeApprover__c) && 
                        (qpa.CCodeStatus__c == quoteSettings.StatusRejected__c ||
                         qpa.CCodeStatus__c == quoteSettings.StatusDraft__c)) { 
                        // Submit for approval
                        System.debug('Testinggggggggggggggggggg');
                        bg_QuoteApprovalUtils.SubmitForApproval(qpa.Id, 'Submitting request for CCode approval.');
                    }
                }
                ReloadQuotePage();
            }
        } catch (Exception ex) {
            Apexpages.addMessages(ex);
        }       
    }

    public PageReference CloneQuote() {
        /*
            Clone Quote and redirect to clone
        */
        pageReference retPage;
        try {
            if(showCloneBtn){
                // make sure quote is saved
                bg_QuoteUtils.SaveQuote(quote);
                // make new quote
                Quote__c cloneQuote = bg_QuoteUtils.CloneQuote(quote.Id, true, true);
                retPage = new pageReference(bg_BluePrintUtils.BuildConfigureQuoteProductURL(quote.Id, null, cloneQuote.Id, '/' + cloneQuote.Id));
            }
        } catch (Exception ex) {
            Apexpages.addMessages(ex);
        }
        return retPage;
    }

    public PageReference ConfigureQuote() {
        /*
            Configure Quote and add products
        */      
        return new pageReference('/' + bg_QuoteUtils.BuildNewQuoteURL(quote.Account__c, quote.Opportunity_Name__c, quote.Id));
    }

    public PageReference ConfigureProducts() {
        /*
            Configure the Quote Products (2nd grid)
        */
        return new pageReference('/' + bg_QuoteUtils.BuildNewQuoteGridURL(quote.Account__c, quote.Opportunity_Name__c, quote.Id, showConfigureBtn));
    }

    /******************************************************************/
    /* Keys Facts Template                                            */
    public PageReference BrowseKeysFactsTemplate() {
        /* Browse Fact Validation Document */
        if(retrieveQuoteStatus())
        {
            return KeyFactTemplate(true);
        }
        return null;
    }
    
    public PageReference GenerateKeyFactsDocument() {   
        /* Generate Fact Validation Document */
        return KeyFactTemplate(false);
    }

    private PageReference KeyFactTemplate(boolean browseTemplates) {
        /*
            Generate / Browse Fact Validation Document
        */
        PageReference retPage = null;
        try {
            // Check Quote Sync is finished - all fact required before running the doc
            bg_QuoteUtils.CheckQuoteSyncStatus(quote.Id);
            
            // Sync quote with opportunity
            bg_QuoteUtils.SyncQuoteWithOpportunity(quote.Id);

            // Sequence facts information
            bg_PropertyValueUtils.UpdatePropertyValuesSequence(quote.Id);

            list<Id> recipientContactIds = bg_DocumentUtils.GetRecipientContactIds(bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION, quote);
            
            if ( recipientContactIds == null || recipientContactIds.size() == 0 || recipientContactIds[0] == null)
            {
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.NoQuoteContact));
            }
            else
            {
                retPage = Page.bg_TemplateSelection;
                retPage.getParameters().put('quoteId', quote.Id);
                retPage.getParameters().put('docType', bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION);
                retPage.getParameters().put('recCont', bg_StringUtils.convertListOfIdsToString(recipientContactIds));
            }
            
        } catch (Exception ex) 
        {
            Apexpages.addMessages(ex);
        }
        return retPage;     
    }

    /******************************************************************/
    /* Proposal Template                                              */        
    public PageReference BrowseProposalTemplate() { 
        /* Generate Proposal Document */
        if(retrieveQuoteStatus()) 
        {
            return ProposalTemplate(true);
        }
        return null;
    }

    public PageReference GenerateProposalDocument() {   
        /* Generate Proposal Document */
        return ProposalTemplate(false);
    }

    public PageReference ProposalTemplate(boolean browseTemplates) {    
        /*
            Generate Proposal Document
        */
        PageReference retPage = null;
        try {
            // Check Quote Sync is finished - all fact required before running the doc
            bg_QuoteUtils.CheckQuoteSyncStatus(quote.Id);

            // Sync quote with opportunity
            bg_QuoteUtils.SyncQuoteWithOpportunity(quote.Id);           

            // Sequence facts information
            bg_PropertyValueUtils.UpdatePropertyValuesSequence(quote.Id, bg_DocumentUtils.DOCUMENT_TYPE_FACT_VALIDATION);

            list<String> recipientContactIds = bg_DocumentUtils.GetRecipientContactIds(bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL, quote);
            if ( recipientContactIds == null || recipientContactIds.size() == 0 || recipientContactIds[0] == null)
            {
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.NoQuoteContact));
            }
            else
            {
                retPage = Page.bg_TemplateSelection;
                retPage.getParameters().put('quoteId', quote.Id);
                retPage.getParameters().put('docType', bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL);
                retPage.getParameters().put('recCont', bg_StringUtils.convertListOfIdsToString(recipientContactIds));
            }

            //future proof - this works by choing template but would need new boolean to turn off tempalteselection retPage = new pageReference(bg_DocumentUtils.GetDocumentURL(quote.Id, templateIds, bg_DocumentUtils.DOCUMENT_TYPE_PROPOSAL, recipientContactIds, false, true, !browseTemplates));
        } catch (Exception ex) {
            Apexpages.addMessages(ex);
        }
        return retPage;
    }

    /******************************************************************/
    /* Tech Review Template                                           */        
    public PageReference GenerateTechReviewDocument() {
        /* Generate Technical Review Document */
        return TechReviewTemplate(false);
    }

    public PageReference BrowseTechReviewTemplate() {
        /* Browse Technical Review Document */
        return TechReviewTemplate(true);
    }

    public PageReference TechReviewTemplate(boolean browseTemplates) {
        /*
            Generate Technical Review Document
        */
        // TODO: Identify PRODUCTS REQUIRING TECH REVIEW
        PageReference retPage = null;
        try {
            if(!bg_StringUtils.IsBlank(quote.Tech_Review_Team__c)) {
                // Save selected tech team
                bg_QuoteUtils.SaveQuote(quote);
                
                // Check Quote Sync is finished - all fact required before running the doc
                bg_QuoteUtils.CheckQuoteSyncStatus(quote.Id);
    
                // Sync quote with opportunity
                bg_QuoteUtils.SyncQuoteWithOpportunity(quote.Id);           
    
                // Sequence facts information
                bg_PropertyValueUtils.UpdatePropertyValuesSequence(quote.Id, bg_DocumentUtils.DOCUMENT_TYPE_TECH_REVIEW);
                
                // generate template
                list<Id> recipientContactIds = bg_DocumentUtils.GetRecipientContactIds(bg_DocumentUtils.DOCUMENT_TYPE_TECH_REVIEW, quote);
                
                // RJ: CC option not supported with template selection page 
                // Get list of CC: email addresses & build email list
//              list<Contact> ccContacts = bg_ContactUtils.GetOtherAccountContacts(recipientContactIds);
//              list<string> ccEmails = bg_ContactUtils.GetContactEmailList(ccContacts);
                
                retPage = Page.bg_TemplateSelection;
                retPage.getParameters().put('quoteId', quote.Id);
                retPage.getParameters().put('docType', bg_DocumentUtils.DOCUMENT_TYPE_TECH_REVIEW);
                retPage.getParameters().put('recCont', bg_StringUtils.convertListOfIdsToString(recipientContactIds));

            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please select a Tech Review Team'));
            }
        } catch (Exception ex) {
            Apexpages.addMessages(ex);
        }
        return retPage;
    }

    /******************************************************************/
    /* Sales Brief Template                                     */      
    public PageReference BrowseSalesBriefTemplate() {   
        /* Browse Sales Brief Template */
        return SalesBriefTemplate(true);
    }

    public PageReference GenerateSalesBriefDocument() { 
        /* Generate Sales Brief Document */
        return SalesBriefTemplate(false);
    }

    public PageReference SalesBriefTemplate(boolean browseTemplates) {  
        /*
            Generate Fact Validation Document
        */
        PageReference retPage = null;
        try {
            list<String> recipientContactIds = bg_DocumentUtils.GetRecipientContactIds(bg_DocumentUtils.DOCUMENT_TYPE_SALES_BRIEF, quote);
            
            if ( recipientContactIds == null || recipientContactIds.size() == 0)
            {
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.NoQuoteContact));
            }
            else
            {
                retPage = Page.bg_TemplateSelection;
                retPage.getParameters().put('quoteId', quote.Id);
                retPage.getParameters().put('docType', bg_DocumentUtils.DOCUMENT_TYPE_SALES_BRIEF);
                retPage.getParameters().put('recCont', bg_StringUtils.convertListOfIdsToString(recipientContactIds));
            }
        } catch (Exception ex) {
            Apexpages.addMessages(ex);
        }
        return retPage;                     
    }

    public void ConfigurePrices() {
        /* Redirect to Configure Prices - Quote Part Grid */
        if (retrieveQuoteStatus())
        {
            ReloadPage('/' + bg_QuoteUtils.BuildQuotePartGridURL(quote.Id));
        }
    }

    /******************************************************************/
    /* Quote Sync Status Area
     * Covers the form so that propsals cannot be generated until all 
     * quote products and thier property values have been generated
     *
    */

    /*
        Queries the sync status
        If this is in the error status, an error is added to the page
    */
    public boolean checkSyncError()
    {
        Integer status = bg_QuoteUtils.GetQuoteSyncStatus(quote.Id);
        if(checkSyncError(status))
        {
            bg_ApexPageUtils.AddErrorMessageToPage(bg_QuoteUtils.SYNC_ERROR_MESSAGE);
            return true;
        }
        return false;
    }

    /*
        Takes the sync status as a parameter, if this is in an error status, true is returned.
    */
    private Boolean checkSyncError(Integer status)
    {
        return bg_QuoteUtils.SYNC_STATUS_ERROR == status;
    }

    /*
        Returns true if the quote sync is in progress
    */
    public Boolean getQuoteSyncRunning()
    {
        return syncStatus == bg_QuoteUtils.SYNC_STATUS_RUNNING;
    }

    /*
        If the quote is syncing, the message is set to the sync message.
        Sets the syncStatus enum to the correct value to be used in VF
        Called from actionPoller 
        No return value as called from actionPoller
    */  
    public void retrieveQuoteStatus_Action() 
    {        
        retrieveQuoteStatus();
    }

    /*
        If the quote is syncing, the message is set to the sync message.
        Sets the syncStatus enum to the correct value to be used in VF
    */
    private Boolean retrieveQuoteStatus()
    {
        Boolean returnVal = false;
        syncStatus = bg_QuoteUtils.GetQuoteSyncStatus(quote.Id);

        if (bg_QuoteUtils.SYNC_STATUS_RUNNING == syncStatus)
        {
            syncStatusMessage = Label.Quote_wait_message;
        }
        else if(checkSyncError(syncStatus))
        {
            bg_ApexPageUtils.AddErrorMessageToPage(bg_QuoteUtils.SYNC_ERROR_MESSAGE);
        }
        else
        {
            returnVal = true;
        } 

        return returnVal;
    }
    
    /*
        Queries the Quote Operation Approval Queue to see if the current User is a Queue Member
    */     
    private boolean GetQuoteOperationsApprovalQueueMember()
    {
        
        if (null == quoteOperationsApprovalQueueMember)
        {
            SetQuoteOperationsApprovalQueueMember();
        }
        
        return quoteOperationsApprovalQueueMember;
    } // GetQuoteOperationsApprovalQueueMember

    /*
        Queries the Quote Operation Approval Queue to see if the current User is a Queue Member
    */         
    private void SetQuoteOperationsApprovalQueueMember()
    {
        quoteOperationsApprovalQueueMember = bg_QuoteApprovalUtils.IsQuoteOperationsApprovalQueueMember(quote);        
    } // SetQuoteOperationsApprovalQueueMember
    
    public PageReference importQuoteParts() {
    	Attachment a = [SELECT id, body FROM attachment WHERE name = :quote.Name +'.txt'];
		
		if(a == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO , 'Cannot find the Quote Part attachment. Please upload the file to Attachments.'));
			return new PageReference('/' + quote.Id);
		}
		String content = a.body.toString().replace('"TopLevelPart__c":"1"', '"TopLevelPart__c":true')
		    .replace('"TopLevelPart__c":"0"', '"TopLevelPart__c":false')
		    .replace('"IsDeleted":"FALSE"', '"IsDeleted":false')
		    .replace('"IsDeleted":"TRUE"', '"IsDeleted":true')
		    .replace('"00:00.0"', '"1900-01-01"');
		List<Quote_Part__c> quoteParts = (List<Quote_Part__c>) Json.deserialize(content, List<Quote_Part__c>.class);
		
		insert quoteParts;
		
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO , 'Quote Parts are imported successfully.'));
		return new PageReference('/' + quote.Id);
    }
    
    public void onApproverSelect() {
    	String approverId = qpaMap.get(ApexPages.currentPage().getParameters().get('qpaId')).CCodeApprover__c;
    	
    	if(String.isEmpty(approverId))
    		return;
    	
    	User user = [SELECT FirstName, LastName, OutofOffice__c FROM User WHERE Id = :approverId];
    	
    	if(user.OutofOffice__c)
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO , 'Approver '+ user.FirstName + ' ' + user.LastName + ' is Out of office'));
    }
        
}