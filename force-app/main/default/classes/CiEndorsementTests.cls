@isTest
private class CiEndorsementTests {

    static testMethod void myUnitTest() {
        
        // Create a local CI Account
        CI_Account__c acc1 = CiTestUtility.createTestAccount('12345');

        // Create a local CI Endorsement with Attachment        
        CI_Endorsement__c end1 = new Ci_Endorsement__c();
        end1.Name = 'Test Endorsement';
        end1.CI_Account__c = acc1.Id;
        end1.Document_Type__c = 'Case Study';
        end1.Format__c = 'PDF';
        end1.Language__c = 'English';
        end1.Availability__c = 'External Use';
        end1.Valid_From__c = Date.today();
        end1.Valid_To__c = Date.today().addYears(3);
        end1.Substreams__c = 'Advisory';
        end1.Families__c = 'Action Manager';
        end1.Hyperlink__c = 'www.bbc.co.uk';
        end1.Content__c = 'Test content';
        end1.Survey_Id__c = '';
        end1.Source__c = 'CAER';
        insert end1;
        Attachment att1 = new Attachment();
        att1.Name = 'Test.pdf';
        att1.ParentId = end1.Id;
        att1.Description = 'Test description';
        att1.ContentType = 'application/pdf';
        att1.Body = Blob.valueOf('');
        insert att1;
        
        // Create a remote CI Endorsement with Attachment
        CI_Endorsement__c end2 = new Ci_Endorsement__c();
        end2.Name = 'Test Endorsement';
        end2.CI_Account__c = acc1.Id;
        end2.Document_Type__c = 'Case Study';
        end2.Format__c = 'PDF';
        end2.Language__c = 'English';
        end2.Availability__c = 'External Use';
        end2.Valid_From__c = Date.today();
        end2.Valid_To__c = Date.today().addYears(3);
        end2.Substreams__c = 'Advisory';
        end2.Families__c = 'Action Manager';
        end2.Hyperlink__c = 'www.bbc.co.uk';
        end2.Content__c = 'Test content';
        end2.Survey_Id__c = '';
        end2.Source__c = 'GLOB';
        end2.Source_Id__c = 'a1nc00000011ml2AAl';
        insert end2;
        Attachment att2 = new Attachment();
        att2.Name = 'Test.pdf';
        att2.ParentId = end2.Id;
        att2.Description = '00Pc0000001FBNYEA4: Test description';
        att2.ContentType = 'application/pdf';
        att2.Body = Blob.valueOf('xyz');
        insert att2;
        
        // Create a remote CI Endorsement with Attachment
        CI_Endorsement__c end3 = new Ci_Endorsement__c();
        end3.Name = 'Test Endorsement';
        end3.CI_Account__c = acc1.Id;
        end3.Document_Type__c = 'Case Study';
        end3.Format__c = 'PDF';
        end3.Language__c = 'English';
        end3.Availability__c = 'External Use';
        end3.Valid_From__c = Date.today();
        end3.Valid_To__c = Date.today().addYears(3);
        end3.Substreams__c = 'Advisory';
        end3.Families__c = 'Action Manager';
        end3.Hyperlink__c = 'www.bbc.co.uk';
        end3.Content__c = 'Test content';
        end3.Survey_Id__c = '';
        end3.Source__c = 'GLOB';
        end3.Source_Id__c = 'a1nc00000011ml3AAl';
        insert end3;
        Attachment att3 = new Attachment();
        att3.Name = 'Test.pdf';
        att3.ParentId = end3.Id;
        att3.Description = '00Pc0000001FBNZEA4: Test description';
        att3.ContentType = 'application/pdf';
        att3.Body = Blob.valueOf('abc');
        insert att3;
        
		// Start the tests
		Test.startTest();

		// Test data sending
		List<CiEndorsementServices.CiEndorsement> ends = CiEndorsementServices.FetchEndorsements();
		System.assertEquals(1, ends.size());
		List<CiEndorsementServices.CiAttachmentDetail> atts = CiEndorsementServices.FetchAttachmentDetails();
		System.assertEquals(1, atts.size());
		List<CiEndorsementServices.CiAttachmentBody> bods = CiEndorsementServices.FetchAttachmentBodies(new List<Id> { att1.Id });
		System.assertEquals(1, bods.size());

		// Test Endorsement sync functionality with one insert and one update
		List<CiEndorsementServices.CiEndorsement> remoteEnds = new List<CiEndorsementServices.CiEndorsement>();
		CiEndorsementServices.CiEndorsement end2remote = new CiEndorsementServices.CiEndorsement();
		end2remote.id = 'a1nc00000011ml2AAl';
        end2remote.name = 'Test Endorsement updated';
        end2remote.account = '12345';
        end2remote.documentType = 'Case Study';
        end2remote.format = 'PDF';
        end2remote.language = 'English';
        end2remote.availability = 'External Use';
        end2remote.validFrom = Date.today();
        end2remote.validTo = Date.today().addYears(3);
        end2remote.substreams = 'Advisory';
        end2remote.families = 'Action Manager';
        end2remote.hyperlink = 'www.bbc.co.uk';			
        end2remote.content = 'Test content';
        end2remote.surveyId = '';
		remoteEnds.add(end2remote);
		CiEndorsementServices.CiEndorsement end4remote = new CiEndorsementServices.CiEndorsement();
		end4remote.id = 'a1nc00000011ml4AAl';
        end4remote.name = 'Test Endorsement new';
        end4remote.account = '12345';
        end4remote.documentType = 'Case Study';
        end4remote.format = 'PDF';
        end4remote.language = 'English';
        end4remote.availability = 'External Use';
        end4remote.validFrom = Date.today();
        end4remote.validTo = Date.today().addYears(3);
        end4remote.substreams = 'Advisory';
        end4remote.families = 'Action Manager';
        end4remote.hyperlink = 'www.bbc.co.uk';			
        end4remote.content = 'Test content';
        end4remote.surveyId = '';
		remoteEnds.add(end4remote);		
		CiEndorsementServices.SyncEndorsements(remoteEnds);

		// Test Attachment bodies functionality with one insert and one update
		List<CiEndorsementServices.CiAttachmentDetail> remoteAtts = new List<CiEndorsementServices.CiAttachmentDetail>();
		CiEndorsementServices.CiAttachmentDetail att2remote = new CiEndorsementServices.CiAttachmentDetail();
		att2remote.id = '00Pc0000001FBNYEA4';
		att2remote.name = 'Test.pdf';
        att2remote.parentId = 'a1nc00000011ml2AAl';
        att2remote.description = 'Test description';
        att2remote.contentType = 'application/pdf';
        att2remote.bodyLength = 100;
		remoteAtts.add(att2remote);
		CiEndorsementServices.CiAttachmentDetail att4remote = new CiEndorsementServices.CiAttachmentDetail();
		att4remote.id = '00Pc0000001FBNWEA4';
		att4remote.name = 'Test.pdf';
        att4remote.parentId = 'a1nc00000011ml4AAl';
        att4remote.description = 'Test description';
        att4remote.contentType = 'application/pdf';
        att4remote.bodyLength = 100;
		remoteAtts.add(att4remote);		
		List<Id> requiredIds = CiEndorsementServices.IdentifyBodies(remoteAtts);
		System.assertEquals(2, requiredIds.size());

		// Test Attachment sync functionality with one insert and one update
		List<CiEndorsementServices.CiAttachmentBody> remoteBods = new List<CiEndorsementServices.CiAttachmentBody>();
		CiEndorsementServices.CiAttachmentBody bod2remote = new CiEndorsementServices.CiAttachmentBody();
		bod2remote.id = '00Pc0000001FBNYEA4';
        bod2remote.body = EncodingUtil.base64Encode(Blob.valueOf('xyz'));
		remoteBods.add(bod2remote);
		CiEndorsementServices.CiAttachmentBody bod4remote = new CiEndorsementServices.CiAttachmentBody();
		bod4remote.id = '00Pc0000001FBNWEA4';
        bod4remote.body = EncodingUtil.base64Encode(Blob.valueOf('pqr'));
		remoteBods.add(bod4remote);
		CiEndorsementServices.SyncAttachments(remoteAtts, remoteBods);
				
		// Stop the test (and the job should start straight away)
		Test.stopTest();
    }
}