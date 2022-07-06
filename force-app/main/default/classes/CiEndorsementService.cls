global with sharing class CiEndorsementService
{
    WebService static Attachment retrieve(string endorsementId)
    {
        // Select the Attachment
        List<Attachment> atts = [
            SELECT Id, Name, Body, BodyLength, ContentType, Description, ParentId
            FROM Attachment
            WHERE ParentId = :endorsementId
            LIMIT 1
        ];
        
        // Return if found
        if (!atts.isEmpty()) {
            return atts[0];
        } else {
            return null;
        } 
    }
}