public with sharing class SmoUpdateTriggerHandler
{
    public static boolean firstRun = true;
    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
    
    // Constructor
    public SmoUpdateTriggerHandler(boolean isExecuting, integer size)
    {
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

    // Before insert logic
    //public void OnBeforeInsert(SMO_Update__c[] newSmoUpdates)
    //{
    //}

    // After insert logic
    public void OnAfterInsert(SMO_Update__c[] newSmoUpdates, Map<ID, SMO_Update__c> mappedSmoUpdates)
    {
        // Remember that we have run once
        firstRun = false;
        
        // Process batch
        ProcessBatch(mappedSmoUpdates.keySet());
    }
    
    // Before update logic
    //public void OnBeforeUpdate(SMO_Update__c[] oldSmoUpdates, SMO_Update__c[] updatedSmoUpdates, Map<ID, SMO_Update__c> mappedSmoUpdates)
    //{
    //}

    // After update logic
    public void OnAfterUpdate(SMO_Update__c[] oldSmoUpdates, SMO_Update__c[] updatedSmoUpdates, Map<ID, SMO_Update__c> mappedSmoUpdates)
    {
        // Abort if trigger is firing recursively or after a post-trigger workflow
        if (firstRun)
        {
            firstRun = false;
        }
        else
        {
            return;
        }
        
        // Process batch
        ProcessBatch(mappedSmoUpdates.keySet());
    }
    
    // Before delete logic
    //public void OnBeforeDelete(SMO_Update__c[] deletingSmoUpdates, Map<ID, SMO_Update__c> mappedSmoUpdates)
    //{
    //}

    // After delete logic
    //public void OnAfterDelete(SMO_Update__c[] deletedSmoUpdates, Map<ID, SMO_Update__c> mappedSmoUpdates)
    //{
    //}
    
    // After undelete logic
    //public void OnUndelete(SMO_Update__c[] restoredSmoUpdates)
    //{
    //}

    // Is this invoked from a trigger (or VisualForce, WebService, etc.)
    //public boolean IsTriggerContext
    //{
    //    get{return m_isExecuting;}
    //}
 
    // Handle the SAP updates   
    @future(callout=true) private static void ProcessBatch(Set<ID> mySmoUpdateIDs)
    {
        // Remember that we have run once
        firstRun = false;

        // Retrieve list using Ids
        List<SMO_Update__c> smoUpdates = [select ID, SMO_Number__c, Returned_Status__c, Returned_Message__c, New_Status__c, New_Start_Date__c, New_Ship_to__c, New_Instructor_1__c, New_Instructor_2__c, New_Instructor_3__c, New_Description__c from SMO_Update__c where Returned_Status__c in ('Pending') and ID in :mySmoUpdateIDs];
        
        if (smoUpdates.size() > 0)
        {
            for (SMO_Update__c smoUpdate : smoUpdates)
            {
                try
                {
                    // Create a web service call
                    PgPlus.Service1Soap call = new PgPlus.Service1Soap();
                    call.timeout_x = 90000;
                    
                    // Add the web service header
                    PgPlus.TrainingSMOServiceHeader header = new PgPlus.TrainingSMOServiceHeader();
                    SystemSetting__c ss = bg_CustomSettingsUtils.GetSystemSettings();
                    header.UserName = ss.Pointglobal_Username__c;
                    header.Password = ss.Pointglobal_Password__c;
                    call.TrainingSMOServiceHeader = header;

                    // Build inputs
                    Integer smo = smoUpdate.SMO_Number__c != null ? integer.valueOf(smoUpdate.SMO_Number__c) : 0;
                    Boolean cancel = (smoUpdate.New_Status__c == 'Cancelled');
                    Integer shipto = smoUpdate.New_Ship_to__c != null ? integer.valueOf(smoUpdate.New_Ship_to__c) : 0;
                    String description = smoUpdate.New_Description__c != null ? smoUpdate.New_Description__c : '';
                    DateTime startDate = smoUpdate.New_Start_Date__c;
                    Integer instructor1 = smoUpdate.New_Instructor_1__c != null ? smoUpdate.New_Instructor_1__c.intValue() : 0;
                    Integer instructor2 = smoUpdate.New_Instructor_2__c != null ? smoUpdate.New_Instructor_2__c.intValue() : 0;
                    Integer instructor3 = smoUpdate.New_Instructor_3__c != null ? smoUpdate.New_Instructor_3__c.intValue() : 0;

                    // Receive results                  
                    PgPlus.TrainingSmoResult result = call.TrainingSMOAmend(smo, cancel, shipto, description, startDate, instructor1, instructor2, instructor3);
                    if (result.ErrorMessage != 'Successfully updated')
                    {
                        smoUpdate.Returned_Status__c = 'Errored';
                        smoUpdate.Returned_Message__c = result.ErrorMessage;
                    }
                    else
                    {
                        // Set returned values
                        smoUpdate.Returned_Status__c = 'Completed';
                        smoUpdate.Returned_Message__c = 'Successfully updated';
                    }
                }
                catch(Exception ex)
                {
                    // Record call as a failure
                    smoUpdate.Returned_Status__c = 'Errored';
                    smoUpdate.Returned_Message__c = String.valueOf(ex);
                }
            }
        
            // Update with returned values
            update smoUpdates;
        }
    }
}