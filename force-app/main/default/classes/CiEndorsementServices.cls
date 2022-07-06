global with sharing class CiEndorsementServices
{
	// CLASS DEFINITIONS ======================================================================================================================
	
	
	// Object used to deliver Endorsement via SOAP
	global class CiEndorsement {
		webservice Id id;
		webservice String name;
		webservice String account;
		webservice String documentType;
		webservice String format;
		webservice String language;
		webservice String availability;
		webservice Date validFrom;
		webservice Date validTo;
		webservice String substreams;
		webservice String families;
		webservice String hyperlink;
		webservice String content;
		webservice String surveyId;
	}
	
	// Object used to deliver Attachment detail via SOAP
	global class CiAttachmentDetail {
		webservice Id id;
		webservice Id parentId;
		webservice String name;
		webservice String description;
		webservice String contentType;
		webservice Integer bodyLength;
	}

	// Object used to deliver Attachment body via SOAP
	global class CiAttachmentBody {
		webservice Id id;
		webservice String body;
	}


	// WEB SERVICES TO PASS LOCAL DATA TO THE REMOTE SYSTEM ===================================================================================


	// Web service to deliver a list of all local Endorsements
    WebService static List<CiEndorsement> FetchEndorsements()
    {
        // Step through the local Endorsements
    	List<CiEndorsement> localEnds = new List<CiEndorsement>();
        for (CI_Endorsement__c sfdcEnd : [
            SELECT	Id,
            		Name,
					CI_Account__r.Account_Id__c,
					Document_Type__c,
					Format__c,
					Language__c,
					Availability__c,
            		Valid_From__c,
            		Valid_To__c,
            		Substreams__c,
					Families__c,
					HyperLink__c,
					Content__c,
					Survey_Id__c
            FROM	CI_Endorsement__c
            WHERE	Source__c = 'CAER'
        ]) {
        	// Add one SOAP version
        	CiEndorsement soapEnd = new CiEndorsement();
        	soapEnd.id = sfdcEnd.Id;	
        	soapEnd.name = sfdcEnd.Name;
        	soapEnd.account = sfdcEnd.CI_Account__r.Account_Id__c;
        	soapEnd.documentType = sfdcEnd.Document_Type__c;
        	soapEnd.format = sfdcEnd.Format__c;
        	soapEnd.language = sfdcEnd.Language__c;
        	soapEnd.availability = sfdcEnd.Availability__c;
        	soapEnd.validFrom = sfdcEnd.Valid_From__c;
        	soapEnd.validTo = sfdcEnd.Valid_To__c;
        	soapEnd.substreams = sfdcEnd.Substreams__c;
        	soapEnd.families = sfdcEnd.Families__c;
        	soapEnd.hyperlink = sfdcEnd.HyperLink__c;
        	soapEnd.content = sfdcEnd.Content__c;
        	soapEnd.surveyId = sfdcEnd.Survey_Id__c;
        	localEnds.add(soapEnd);
        }
        
        // Return results
        return localEnds;
	}

	// Web service to deliver a list of all local Attachment details
    WebService static List<CiAttachmentDetail> FetchAttachmentDetails()
    {    	
        // Get a list of all the Endorsement Ids
        Set<Id> localEnds = new Set<Id>();
        for (CI_Endorsement__c sfdcEnd : [
            SELECT	Id
            FROM	CI_Endorsement__c
            WHERE	Source__c = 'CAER'
        ]) localEnds.add(sfdcEnd.Id);

    	// Build list of Attachments (without body)
    	List<CiAttachmentDetail> localAtts = new List<CiAttachmentDetail>();
        for (Attachment sfdcAtt : [
            SELECT	Id,
            		ParentId,
            		Name,
					Description,
					ContentType,
					BodyLength
            FROM	Attachment
            WHERE	ParentId IN :localEnds
        ]) {
        	// Add one SOAP version
        	CiAttachmentDetail soapAtt = new CiAttachmentDetail();
        	soapAtt.id = sfdcAtt.Id;	
        	soapAtt.parentId = sfdcAtt.ParentId;	
        	soapAtt.name = sfdcAtt.Name;
        	soapAtt.description = sfdcAtt.Description;
        	soapAtt.contentType = sfdcAtt.ContentType;
        	soapAtt.bodyLength = sfdcAtt.BodyLength;
        	localAtts.add(soapAtt);
        }
        
        // Return results
        return localAtts;
	}

	// Web service to deliver a list of the requested Attachment bodies
    WebService static List<CiAttachmentBody> FetchAttachmentBodies(List<Id> requestedIds)
    {
        // Select the requested local Attachments
        List<CiAttachmentBody> localBods = new List<CiAttachmentBody>();
        Integer totalSize = 0;
        for (Attachment sfdcBod : [
            SELECT	Id,
            		BodyLength,
            		Body
			FROM	Attachment
            WHERE	Id IN :requestedIds AND BodyLength < 5000000 // Attachments < 5MB
        ]) {
        	// Add one SOAP version
        	if (totalSize + sfdcBod.BodyLength < 5000000) { // Total size < 5MB
	        	CiAttachmentBody soapBod = new CiAttachmentBody();
    	    	soapBod.id = sfdcBod.Id;
        		soapBod.body = EncodingUtil.base64Encode(sfdcBod.Body);
        		localBods.add(soapBod);
        		totalSize += sfdcBod.BodyLength;
        	}
        }
        
        // Return results
    	return localBods;
    }


	// WEB SERVICES TO UPDATE LOCAL COPIES OF REMOTE DATA =====================================================================================


	// Web service to update local copies of remote Endorsements
    WebService static void SyncEndorsements(List<CiEndorsement> remoteEnds)
    {
    	// Build map to translate GoldenCompany to CI Account Id
    	Set<String> goldenCoReferences = new Set<String>();
    	Map<String, Id> goldenCoLookup = new Map<String, Id>();
    	for (CiEndorsement e : remoteEnds) {
    		if (String.isNotBlank(e.account)) goldenCoReferences.add(e.account);
    	}
    	for (CI_Account__c a : [
    		SELECT	Id,
    				Account_Id__c
    		FROM	CI_Account__c
    		WHERE	Account_Id__c IN :goldenCoReferences
    	]) {
    		goldenCoLookup.put(a.Account_Id__c, a.Id);
    	}

   		// Build a map of local copies of remote endorsements
   		Map<Id, CI_Endorsement__c> myRemoteEnds = new Map<Id, CI_Endorsement__c>();
   		for (CI_Endorsement__c e : [
            SELECT	Id,
            		Name,
            		CI_Account__c,
					CI_Account__r.Account_Id__c,
					Document_Type__c,
					Format__c,
					Language__c,
					Availability__c,
            		Valid_From__c,
            		Valid_To__c,
            		Substreams__c,
					Families__c,
					HyperLink__c,
					Content__c,
					Survey_Id__c,
            		Source_Id__c
            FROM	CI_Endorsement__c
            WHERE	Source__c = 'GLOB' AND Source_Id__c <> ''
   		]) {
   			myRemoteEnds.put(Id.valueOf(e.Source_Id__c), e);
   		}
   		
   		// Initialize action lists
   		Set<Id> remoteEndIds = new Set<Id>();
   		List<CI_Endorsement__c> endInserts = new List<CI_Endorsement__c>();
   		List<CI_Endorsement__c> endUpdates = new List<CI_Endorsement__c>();
   		List<CI_Endorsement__c> endDeletes = new List<CI_Endorsement__c>();

   		// Check whether remote Endorsements exist locally
   		for (CiEndorsement e : remoteEnds) {
   			
   			// Remember Id
			remoteEndIds.add(e.id);
   			
   			// Check it
   			if (!myRemoteEnds.containsKey(e.id)) {

   				// Add an insert
   				CI_Endorsement__c newEnd = new CI_Endorsement__c();
       		 	newEnd.Name = e.name;
       		 	newEnd.CI_Account__c = goldenCoLookup.containsKey(e.account) ? goldenCoLookup.get(e.account) : null; 
        		newEnd.Document_Type__c = e.documentType;
        		newEnd.Format__c = e.format;
        		newEnd.Language__c = e.language;
        		newEnd.Availability__c = e.availability;
        		newEnd.Valid_From__c = e.validFrom;
        		newEnd.Valid_To__c = e.validTo;
        		newEnd.Substreams__c = e.substreams;
        		newEnd.Families__c = e.families;
        		newEnd.HyperLink__c = e.hyperlink;
        		newEnd.Content__c = e.content;
        		newEnd.Survey_Id__c = e.surveyId;
        		newEnd.Source__c = 'GLOB';
        		newEnd.Source_Id__c = e.id;
        		endInserts.add(newEnd);

   			} else {
   				
   				// Check for updates
   				CI_Endorsement__c oldEnd = myRemoteEnds.get(e.id);
   				Id accountId = goldenCoLookup.containsKey(e.account) ? goldenCoLookup.get(e.account) : null;
				if (oldEnd.Name != e.name || oldEnd.CI_Account__c != accountId || oldEnd.Document_Type__c != e.documentType || oldEnd.Format__c != e.format || oldEnd.Language__c != e.language || oldEnd.Availability__c != e.availability || oldEnd.Valid_From__c != e.validFrom || oldEnd.Valid_To__c != e.validTo || oldEnd.Substreams__c != e.substreams || oldEnd.Families__c != e.families || oldEnd.HyperLink__c != e.hyperlink || oldEnd.Content__c != e.content || oldEnd.Survey_Id__c != e.surveyId) {

					// Add an update
					oldEnd.Name = e.name;
       		 		oldEnd.CI_Account__c = accountId;
        			oldEnd.Document_Type__c = e.documentType;
        			oldEnd.Format__c = e.format;
        			oldEnd.Language__c = e.language;
        			oldEnd.Availability__c = e.availability;
        			oldEnd.Valid_From__c = e.validFrom;
        			oldEnd.Valid_To__c = e.validTo;
        			oldEnd.Substreams__c = e.substreams;
        			oldEnd.Families__c = e.families;
        			oldEnd.HyperLink__c = e.hyperlink;
        			oldEnd.Content__c = e.content;
        			oldEnd.Survey_Id__c = e.surveyId;
					endUpdates.add(oldEnd);
				}
   			}
   		}
   		
   		// Check for deletions
   		for (Id myRemoteEndId : myRemoteEnds.keySet()) {
   			if (!remoteEndIds.contains(myRemoteEndId)) endDeletes.add(myRemoteEnds.get(myRemoteEndId));
   		}
   		
   		// Carry out actions
   		if (!endInserts.isEmpty()) insert endInserts;
   		if (!endUpdates.isEmpty()) update endUpdates;
   		if (!endDeletes.isEmpty()) delete endDeletes;
	}

	// Web service to identify required Attachment bodies
    WebService static List<Id> IdentifyBodies(List<CiAttachmentDetail> remoteAtts)
    {
   		// Build a set of local copies of remote Endorsements
   		Set<Id> myRemoteEndIds = new Set<Id>();
   		for (CI_Endorsement__c e : [
            SELECT	Id
            FROM	CI_Endorsement__c
            WHERE	Source__c = 'GLOB' AND Source_Id__c <> ''
   		]) {
   			myRemoteEndIds.add(e.Id);
   		}
   		
   		// Build a map of local copies of remote Attachments
   		Map<Id, Attachment> myRemoteAtts = new Map<Id, Attachment>();
   		for (Attachment a : [
            SELECT	Id,
            		ParentId,
            		Name,
					Description,
					ContentType,
					BodyLength
            FROM	Attachment
            WHERE	ParentId IN :myRemoteEndIds
   		]) {
   			myRemoteAtts.put(Id.valueOf(a.Description.left(18)), a);
   		}

		// Get the bodies for new/changed remote Attachments
   		List<Id> neededAttIds = new List<Id>();
   		for (CiAttachmentDetail a : remoteAtts) {

   			// Check for new
   			if (!myRemoteAtts.containsKey(a.id)) {
				neededAttIds.add(a.Id);
   			} else {

   				// Check for file changed
   				Attachment oldAtt = myRemoteAtts.get(a.id);
				if (oldAtt.Name != a.name || oldAtt.ContentType != a.contentType || oldAtt.BodyLength != a.bodyLength) neededAttIds.add(a.Id);
   			}
   		}
   		
   		// Return values
   		return neededAttIds;
    }

	// Web service to update local copies of remote Attachment bodies
    WebService static void SyncAttachments(List<CiAttachmentDetail> remoteAtts, List<CiAttachmentBody> remoteBods)
    {
   		// Build a map/set of local copies of remote Endorsements
   		Map<Id, CI_Endorsement__c> myRemoteEnds = new Map<Id, CI_Endorsement__c>();
   		Set<Id> myRemoteEndIds = new Set<Id>();
   		for (CI_Endorsement__c e : [
            SELECT	Id,
            		Source_Id__c
            FROM	CI_Endorsement__c
            WHERE	Source__c = 'GLOB' AND Source_Id__c <> ''
   		]) {
   			myRemoteEnds.put(Id.valueOf(e.Source_Id__c), e);
   			myRemoteEndIds.add(e.Id);
   		}
   		
   		// Build a map of local copies of remote Attachments
   		Map<Id, Attachment> myRemoteAtts = new Map<Id, Attachment>();
   		for (Attachment a : [
            SELECT	Id,
            		ParentId,
            		Name,
					Description,
					ContentType,
					BodyLength
            FROM	Attachment
            WHERE	ParentId IN :myRemoteEndIds
   		]) {
   			myRemoteAtts.put(Id.valueOf(a.Description.left(18)), a);
   		}
   		
   		// Build a map of new/updated bodies
   		Map<Id, Blob> remoteBodLookup = new Map<Id, Blob>();
   		for (CiAttachmentBody b : remoteBods) remoteBodLookup.put(b.id, EncodingUtil.base64Decode(b.body));		

   		// Initialize action lists
   		Set<Id> remoteAttIds = new Set<Id>();
   		List<Attachment> attInserts = new List<Attachment>();
   		List<Attachment> attUpdates = new List<Attachment>();
   		List<Attachment> attDeletes = new List<Attachment>();

   		// Check whether remote Attachments exist locally
   		for (CiAttachmentDetail a : remoteAtts) {

   			// Remember Id
			remoteAttIds.add(a.id);

   			// Check it
   			if (!myRemoteAtts.containsKey(a.id)) {

   				// Add an insert
				Attachment newAtt = new Attachment();
				newAtt.ParentId = myRemoteEnds.get(a.parentId).Id;
				newAtt.Name = a.name;
				newAtt.Description = a.id + (String.isNotBlank(a.description) ? ': ' + a.description : '');
				newAtt.ContentType = a.contentType;
				newAtt.Body = remoteBodLookup.containsKey(a.id) ? remoteBodLookup.get(a.id) : Blob.valueOf('');
				attInserts.add(newAtt);

   			} else {

   				// Check for updates
   				Attachment oldAtt = myRemoteAtts.get(a.id);
				if (oldAtt.Name != a.name || oldAtt.Description != (a.id + (String.isNotBlank(a.description) ? ': ' + a.description : '')) || oldAtt.ContentType != a.contentType || oldAtt.BodyLength != a.bodyLength) {

					// Add an update
					Attachment updAtt = new Attachment(Id = oldAtt.Id);
					updAtt.Name = a.name;
					updAtt.Description = a.id + (String.isNotBlank(a.description) ? ': ' + a.description : '');
					updAtt.ContentType = a.contentType;
					if (remoteBodLookup.containsKey(a.id)) updAtt.Body = remoteBodLookup.get(a.id);
					attUpdates.add(updAtt);
				}
   			}
   		}

   		// Check for deletions
   		for (Id myRemoteAttId : myRemoteAtts.keySet()) {
   			if (!remoteAttIds.contains(myRemoteAttId)) attDeletes.add(myRemoteAtts.get(myRemoteAttId));
   		}

   		// Carry out Attachment actions
   		if (!attInserts.isEmpty()) insert attInserts;
   		if (!attUpdates.isEmpty()) update attUpdates;
   		if (!attDeletes.isEmpty()) delete attDeletes;
    }
}