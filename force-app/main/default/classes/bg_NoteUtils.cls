/********************************************************************
 * bg_NoteUtils
 *
 * Utility methods to support note functions
 * 
 * Author: Kieran Maguire
 * Created: 14/11/2014
 * Changes:  
 *					
 *
 ********************************************************************/
public class bg_NoteUtils {

	public static List<Note> GetCloneNotes(Id oppId){
		/*
			Returns all fields of notes that match an opportunity
		*/
		return new List<Note>([	SELECT 	Body, CreatedById, CreatedDate, IsDeleted, LastModifiedById, LastModifiedDate, Id, 
										OwnerId, ParentId, IsPrivate, SystemModstamp, Title 
								FROM 	Note 
								WHERE	ParentId = :oppId]);
	}

	public static List<Note> CloneNotes(Id oldOppId, Id newOppId){
		/*
			Creates a copy and reparents all notes to the new opportunity
		*/
		List<Note> cloneNotes = new List<Note>();
		for(Note oldNote : GetCloneNotes(oldOppId)){
			Note newNote = new Note(Body = oldNote.Body, Title = oldNote.Title, ParentId = newOppId);
			cloneNotes.add(newNote);		
		}
		return cloneNotes;
	}

}