/********************************************************************
 * bg_ChatterUtils
 *
 * Utility methods to support opportunity functions
 * 
 * Author: Richard Jimenez
 * Created: 
 * Changes:  
 *
 ********************************************************************/
public with sharing class bg_ChatterUtils {

	public static final string CHATTER_POSTTYPE_LINKPOST = 'LinkPost';

	public static FeedItem GetChatterPost(Id parentId, string title, string linkURL, string postType, string postBody) {
		/* Method to create a chatter post */		
		return GetChatterPost(parentId, title, linkURL, postType, postBody, UserInfo.getUserId());
	}

	public static FeedItem GetChatterPost(Id parentId, string title, string linkURL, string postType, string postBody, Id createdById) {
		/*
			Method to create a chatter post
		*/
		FeedItem fi = new FeedItem();
		fi.ParentId = parentId;
		fi.Title    = title;
		fi.LinkUrl  = linkURL;
		fi.Type     = postType;
		fi.Body     = postBody;

		if(createdById != null) {
			fi.CreatedById = createdById;
		} 

		return fi;
	}
}