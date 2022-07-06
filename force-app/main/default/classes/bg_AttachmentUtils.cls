/********************************************************************
 * bg_AttachmentUtils
 *
 * Utility methods to support Attachments
 * 
 * Author: Richard Jimenez
 * Created: 24-10-2013
 * Changes: 
 * 11/11/2014	KM	Clone opportuntiy attachments method
 ********************************************************************/
public with sharing class bg_AttachmentUtils {

	public static final string KEY_FACTS_DOCUMENT_PREFIX = 'KFD';
	public static final string PROPOSAL_DOCUMENT_PREFIX  = 'PRD';
	public static final string SOW_DOCUMENT_PREFIX       = 'SOW';

	public static final string FILE_TYPE_PDF = 'pdf';
	public static final string FILE_TYPE_DOC = 'doc';

	public static list<Attachment> GetAttachments(Id parentId) {
		/* Return list of attachments */
		return GetAttachments(parentId, null);
	}

	public static list<Attachment> GetAttachments(Id parentId, string name) {
		/* 
			Return list of attachments
		*/
		string query = 'SELECT Name, ContentType, CreatedDate ' +  
						'FROM Attachment ' + 
						'WHERE ParentId = :parentId ';
		// name ?		
		if(!bg_StringUtils.IsBlank(name)) {
			name += '%'; 
			query += 'AND Name LIKE :name ';
		}
		// order by				
		query += 'ORDER BY CreatedDate DESC';
		// return attachments
		return database.query(query);
	}
	
	public static void CloneOpportunityAttachments(Id oldOppId, Id newOppId){
		/*
			Clones and inserts attachments from oldOpp to the specified new Opp
			This method may use multiple dml statements if there are large attachments
		*/
		
		List<List<Id>> batches = new List<List<Id>>();
		List<Integer> batchSizes = new List<Integer>();

		//Organise attachments into batches
		for(Attachment attachment : [SELECT Id, BodyLength FROM Attachment WHERE ParentId = :oldOppId]){ 
		    Boolean batched = false;
					
		    for(Integer i = 0; i < batches.size(); i++){
		        Integer batchSize = batchSizes[i];
		
		        if(batchSize + attachment.BodyLength < 10000000){
		            batches[i].add(attachment.Id);
		            batchSizes[i] += attachment.BodyLength;
		            batched = true;
		            break;
		        }
		    }
		
		    if(!batched){
		        batches.add(new List<Id>{attachment.Id});
		        batchSizes.add(attachment.BodyLength);
		    }
		
		}
		
		//For each batch SOQL the required records, clone and insert.
		for(List<Id> batchIds : batches){
		    List<Attachment> attachmentsToInsert = new List<Attachment>();
		
		    for(Attachment attachment : [SELECT Name, Body FROM Attachment WHERE Id IN :batchIds]){
		        attachmentsToInsert.add(new Attachment(Name = attachment.Name, Body = attachment.Body, ParentId = newOppId));
		    }
		
		    insert attachmentsToInsert;
		}
	}
/*
	public static string GetDocumentFileName(string prefix) {
		/ * Return Document File Name * /
		return GetDocumentFileName(prefix, null);		
	}
	
	public static string GetDocumentFileName(string prefix, string name) {
		/ * Return Document File Name * /
		return GetDocumentFileName(prefix, name, null);
	}
	
	public static string GetDocumentFileName(string prefix, string name, string fileType) {
		/ *
			Return Document File Name
		* /
		string fileName = prefix;
		if(!bg_StringUtils.IsBlank(name))     { fileName += ' ' + name; }
		if(!bg_StringUtils.IsBlank(fileType)) { fileName += '.' + fileType; }
		return fileName;
	}
*/
	/************************************************************************/
	/* TEST METHODS - bg_AttachmentUtilsTest                                */	
	/************************************************************************/	
}