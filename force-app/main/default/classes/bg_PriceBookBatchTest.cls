/********************************************************************
 * bg_PriceBookBatchTest
 *
 * Test class for bg_PriceBookBatch
 * 
 * 
 * Author: Richard Cave
 * Created: 30-05-2017
 * 08-09-2017 - Added bulk test.
 ********************************************************************/
@isTest
private class bg_PriceBookBatchTest 
{

    // Utility method that can be called by Apex tests to create price book entries.
    public static void addPricebookEntries(Date End_Date, integer numPriceBooks) 
    {
        //insert permission set to allow creation of MSA records.
        List<PermissionSet> ps = [SELECT ID From PermissionSet WHERE Name = 'PS_Super_User'];

        //check to see if the permission set is already assigned
        List<PermissionSetAssignment> psa = [select AssigneeId, PermissionSetId FROM PermissionSetAssignment 
                                        WHERE PermissionSetId=:ps[0].Id AND AssigneeId=:UserInfo.getUserId()];


        if(psa.isEmpty())
        {
            insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = ps[0].Id );
        }


        User u = [Select id from User where id=:UserInfo.getUserId()];
        // First, set up test price book entries.
        // Insert a test product.

        List<Pricebook2> pricebooksList = new List<Pricebook2>();
        System.runAs (u) 
        {
            Product2 prod = new Product2(Name = 'nnnn');
            insert prod;
        
            // Get standard price book ID.
            Id pricebookId = Test.getStandardPricebookId();
        
            // Create a custom price book
            //query the record type name should only be 1
            Id priceBooksRT = [SELECT  Id
                                        FROM RecordType
                                        Where SobjectType='Pricebook2'
                                        AND DeveloperName=:Label.BG_MSA_DEVELOPER_NAME].Id;

            for(Integer i=0; i<numPriceBooks; i++)
            {
                Pricebook2 customPB = new Pricebook2(Name='New Pricebook' + i, isActive=true, RecordTypeId=priceBooksRT,
                Year__c= String.ValueOf(System.Today().year()),
                End_Date__c = End_Date);
                pricebooksList.add(customPB);

            }                            
            if(!pricebooksList.isEmpty())
            {
                insert pricebooksList;
            }    
        }
    }

    static testmethod void TestBulkPriceBookBatch()
    {
        addPricebookEntries(System.Today()-1,200);
        Test.startTest();
        bg_PriceBookBatch b =new bg_PriceBookBatch();
        Database.executeBatch(b,200);
        Test.stopTest();
        //query them all and make sure they all inactive
        List<Pricebook2> pb_query = [Select Id, IsActive FROM Pricebook2];

        for(Pricebook2 pb2 : pb_query)
        {
            System.assertEquals(false, pb2.IsActive);

        }
    }

    static testmethod void TestPriceBookScheduler()
    {
        addPricebookEntries(System.Today()-1,1);
        String cronExpr = '0 0 0 15 3 ? 2042'; // JS adjusted date from 2022 to 2042 on 23032022
   
        Test.startTest();
        bg_PriceBookBatch bgp= new bg_PriceBookBatch();
        String jobId = System.schedule('myJobTestJobName', cronExpr, bgp);  // If this line fails check  String cronExpr = '0 0 0 15 3 ? 2022'; is in future (line 87)
        bgp.execute(null);
        Test.stopTest();
        //Re query to make sure it has gone inactive
        Pricebook2 pb_query = [Select Id, IsActive FROM Pricebook2];
        System.assertEquals(false, pb_query.IsActive);
    }

    static testmethod void TestPriceBookBatchPositiveOutcome()
    {
        addPricebookEntries(System.Today()-1,1);
   
        Test.startTest();
        bg_PriceBookBatch b =new bg_PriceBookBatch();
        Database.executeBatch(b,200);
        Test.stopTest();

        //Re query to make sure it has gone inactive
        Pricebook2 pb_query = [Select Id, IsActive FROM Pricebook2];
        System.assertEquals(false, pb_query.IsActive);
    }

    static testmethod void TestPriceBookBatchNegativeOutcome()
    {
        addPricebookEntries(System.Today(),1);

        Test.startTest();
        bg_PriceBookBatch b =new bg_PriceBookBatch();
        Database.executeBatch(b,200);
        Test.stopTest();

        //should not have changed as the date is not less than today.
        Pricebook2 pb_query = [Select Id, IsActive FROM Pricebook2];
        System.assertEquals(true, pb_query.IsActive);

    }
}