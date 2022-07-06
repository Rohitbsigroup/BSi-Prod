@isTest
private class ReportComponentControllerTest {
    
    @isTest(seeAllData=true) static void getReportData_validID(){
        Report aReport = [ SELECT Id, Name FROM Report LIMIT 1];
        Account anAccount=[ SELECT Id, Name FROM Account LIMIT 1];
        Test.startTest();
            String reportJSON = ReportComponentController.getReportData(aReport.Id, anAccount.Id, 'None');
        Test.stopTest();

        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(reportJSON);
        Map<String, Object> n = (Map<String, Object>)m.get('reportResults');
        Map<String, Object> reportData = (Map<String, Object>)m.get('reportData');
        
        if(reportData != null)
            System.assertEquals( aReport.Name, reportData.get('name'), 'The correct report should be returned' );
    }

    @isTest static void getReportMetadata_invalidID(){
        Account acc = TestData.getTestAccount();
        insert acc;
        
        Id bogusId = acc.id;
                
        Account anAccount=[ SELECT Id, Name FROM Account LIMIT 1];
        NoDataFoundException expectedEx;
        String reportJSON;
        try{
            Test.startTest();
                reportJSON = ReportComponentController.getReportData(bogusId, anAccount.Id,'None');
            Test.stopTest();
        } catch( NoDataFoundException ex ){
            expectedEx = ex;
        }

        System.assertEquals( null, reportJSON, 'No report json should be returned' );
        System.assertNotEquals( null, expectedEx, 'An exception should been thronw to be handled by the front-end' );
    }
}