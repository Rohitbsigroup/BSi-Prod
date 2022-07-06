/********************************************************************
 * QuoteTriggerHandler
 *
 * Handler class for Quote Trigger
 *
 *
 * Author: Richard Jimenez
 * Created: 09-12-2013
 * Changes:
 *          25/07/16 JA - added call to bg_QuoteUtils.SetOfflineSignedQuoteToMainQuote
 ********************************************************************/
public without sharing class QuoteTriggerHandler {

    private boolean isExecuting = false;
    private integer BatchSize = 0;

    // CONSTRUCTOR
    public QuoteTriggerHandler(boolean isExecuting, integer size){
        isExecuting = isExecuting;
        BatchSize = size;
    }

    // BEFORE INSERT
    public void OnBeforeInsert(Quote__c[] newQuotes) {
        // Set & Clear any existing Main Quote Flags
        bg_QuoteUtils.SetMainQuotes(newQuotes,true);

        // Create Opportunity Line Items
        bg_OpportunityUtils.SyncOpportunityLineItems(newQuotes);

        // Create Quote Approval Products
        //bg_QuoteApprovalUtils.CreateQuoteProductApprovalLines(newQuotes);
    }

    // BEFORE UPDATE
    public void OnBeforeUpdate(Map<ID, Quote__c> updatedQuotes, Map<ID, Quote__c> oldQuotes) {
        if (!Utility.lockQuoteTrigger) {

            // Try to set main quotes if ProposalSignedOffline__c becomes checked
            List<Quote__c> quotesSignedOffline = new List<Quote__c>();
            for (Quote__c q : updatedQuotes.values())
            {
                Quote__c oldQuote = oldquotes.get(q.Id);
                if (oldQuote.ProposalSignedOffline__c == false &&
                    q.ProposalSignedOffline__c == true)
                {
                    quotesSignedOffline.add(q);
                }
            }
            if(!quotesSignedOffline.isEmpty())
            {
                bg_QuoteUtils.SetOfflineSignedQuoteToMainQuote(quotesSignedOffline);
            }

            // Create Opportunity Line Items
            bg_OpportunityUtils.SyncOpportunityLineItems(updatedQuotes.values());

            // Create Quote Approval Products
            bg_QuoteApprovalUtils.CreateQuoteProductApprovalLines(updatedQuotes.values());
        }
    }
}