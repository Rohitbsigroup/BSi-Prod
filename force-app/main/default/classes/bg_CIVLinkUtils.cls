/********************************************************************
 * bg_CIVLinkUtils
 *
 * Utility class to support CIV Links
 * 
 * 
 * Author: Richard Jimenez
 * Created: 10-10-2014
 * Changes: 
 ********************************************************************/
public class bg_CIVLinkUtils {

	public static CIV_Link__c GetLink(Id objectId) {
		/*
			Get Link
		*/
    	if(objectId != null ) {
			string objectType = objectId.getSObjectType().getDescribe().getName();
	
	    	string query = 'SELECT Id, objectType__c, objectId__c, ';
	    	query += 'Lead__c, Account__c, Opportunity__c, Contact__c, Parent__c ';
	    	query += 'FROM CIV_Link__c WHERE ';
			query += objectType + '__c = :objectId';
			
			list<CIV_Link__c> links = database.query(query);
			if(links.size() > 0) {
				return links[0];
			}
    	}		
		return null;
	}

	public static CIV_Link__c CreateLink(Id objectId, Id parentId) {
		/*
			Create Link
		*/
		string objectType = objectId.getSObjectType().getDescribe().getName();
    	CIV_Link__c link = new CIV_Link__c();
    	link.Type__c = 'Link';
    	link.put(objectType + '__c', objectId);
    	link.parent__c = parentId;
    	insert link;
    	return link;
	}

	public static CIV_Link__c CreateParentLink() {
		/*
			Create Parent Link
		*/
		CIV_Link__c parentlink = new CIV_Link__c();
		parentlink.Type__c = 'Parent';
		insert parentlink;
		return parentlink;
	}

	public static list<CIV_Link__c> GetLinks(Id parentId) {
		/* Get Links */
		return GetLinks(parentId, null);
	}
		
	public static list<CIV_Link__c> GetLinks(Id parentId, string objectType) {
		/*
			Get Link
		*/
    	string query = 'SELECT Id, Parent__c, ObjectId__c, Lead__c, Account__c, Opportunity__c, Contact__c ';
    	query += 'FROM CIV_Link__c ';
		query += 'WHERE Parent__c = :parentId ';
		if(!bg_StringUtils.IsBlank(objectType)) {
			query += 'AND ObjectType__c = :objectType ';	
		}
		return database.query(query);
	}

	public static map<Id, CIV_Link__c> GetLinkMap(Id objectId) {
		/* Get Link Map */
		return GetLinkMap(objectId, null);
	}
	
	public static map<Id, CIV_Link__c> GetLinkMap(Id objectId, string linkObjectType) {
		/*
			Get Link Map
		*/
		map<Id, CIV_Link__c> linkMap = new map<Id, CIV_Link__c>(); 
		CIV_Link__c link = GetLink(objectId);

		system.debug('GetLinkMap: ' + link);

		if(link != null) {
			list<CIV_Link__c> links = GetLinks(link.Parent__c, linkObjectType); 

			system.debug('GetLinkMap: ' + links);

			for(CIV_Link__c l : links) {
				linkMap.put(l.ObjectId__c, l);
			}
		}
		return linkMap;
	}

	public static void TransferLinks(Id oldParentId, Id newParentId) {
		/*
			Transfer Links from old parent to new parent
		*/
    	if(oldParentId != null && newParentId != null) {
			list<CIV_Link__c> links = GetLinks(oldParentId);
			for(CIV_Link__c link : links) {
				link.Parent__c = newParentId;
			}
			update links;
	
			// delete old parent parent
			delete (new CIV_Link__c(Id = oldParentId));											
    	}
	}
	
    public static map<Id, CIV_Link__c> AddLink(Id objectId1, Id objectId2) {
    	/*
    		Add CIV Link 
    	*/
		// Link Map
    	map<Id, CIV_Link__c> linkMap;
    	
    	if(objectId1 != null && objectId2 != null) {
	    	// Try to get link1
			CIV_Link__c link1 = GetLink(objectId1);
	    	// Try to get link2
			CIV_Link__c link2 = GetLink(objectId2);
	
			/* Both links dont exist */
			if(link1 == null && link2 == null) {
				// Create new parent
	    		CIV_Link__c parentlink = CreateParentLink();
				// Create link 1
		    	link1 = CreateLink(objectId1, parentlink.Id);
				// Create link 2
		    	link2 = CreateLink(objectId2, parentlink.Id);		
	
			/* Link 1, no Link 2 */
			} else if(link1 != null && link2 == null) {
				// create new link 2
				link2 = CreateLink(objectId2, link1.Parent__c);
	
			/* Link 2, no Link 1 */
			} else if(link2 != null && link1 == null) {
				// create new link 1
				link1 = CreateLink(objectId1, link2.Parent__c);
	
			/* Transfer Link 2 and Link 1 */
			} else {			
				// transfer links for link2 parent to link1 parent
				TransferLinks(link2.Parent__c, link1.Parent__c);
			}

			linkMap = new map<Id, CIV_Link__c>();
			if(link1 != null) { linkMap.put(objectId1, link1); }
			if(link2 != null) { linkMap.put(objectId2, link2); }
	
			// Create Chatter Post
			CreateLinkChatterPost(objectId1, objectId2, Label.CIV_ChatterPostMessageRecordsLinked);
    	}
    	
		return linkMap;
    }
	
    public static void RemoveLink(Id objectId, Id linkObjectId) {
    	/*
    		Remove CIV Link 
    	*/
		// Delete link
    	CIV_Link__c link = GetLink(objectId);
		Id parentId = link.Parent__c;
    	delete link;
    	
    	// Delete parent
    	list<CIV_Link__c> childLinks = [SELECT Id FROM CIV_Link__c WHERE Parent__c = :parentId LIMIT 2];

    	if(childLinks.size() < 2) {
    		delete childLinks;
    		CIV_Link__c parentLink = new CIV_Link__c(Id = parentId);
    		delete parentLink;
    	}

		// Create Chatter Post
		CreateLinkChatterPost(linkObjectId, objectId, Label.CIV_ChatterPostMessageRecordsUnLinked);
    }

	public static void CreateLinkChatterPost(Id parentId, Id targetId, string message) {
		/*
			Create Link / Unlink chatter post
		*/
		try {
			insert bg_ChatterUtils.GetChatterPost(parentId, 
													Label.CIV_ChatterPostTitleLinkUpdated, 
													'/' + targetId, 
													bg_ChatterUtils.CHATTER_POSTTYPE_LINKPOST,
													message);
		} catch (Exception ex) {}		
	}
	
    @future
    public static void CleanUpLinks() {
    	/*
    		Clean up empty links
    	*/
    	list<CIV_Link__c> emptylinks 
    		= [SELECT Id, Parent__c FROM CIV_Link__c
    				WHERE Type__c = 'Link'
    					AND ObjectId__c = ''];

		if(!emptylinks.isEmpty()) {
			set<Id> parentIds = new set<Id>();
			for(CIV_Link__c link : emptylinks) {
				parentIds.add(link.Parent__c);
			}
	
	    	if(!emptylinks.isEmpty()) {
	    		delete emptylinks;
	    	}

	    	for(CIV_Link__c link : [SELECT Parent__c FROM CIV_Link__c WHERE Parent__c IN :parentIds]) {
	    		parentIds.remove(link.Parent__c);
	    	}
	
			if(!parentIds.isEmpty()) {
				list<CIV_Link__c> parentLinks = new list<CIV_Link__c>();
				for(Id parentId : parentIds) {
					parentLinks.add(new CIV_Link__c(Id = parentId));
				}
				delete parentLinks;
			}
		}
    }
}