/*
Created By : Vimlesh Azad (June 2017)
This class will run an auto scheduler to update Litmos details to SFDC related enrollment.

* changelog
* PC K2           10-06-2020    set batch size to maximum value of 2000
*/

global class LitmosSchedule implements Schedulable{
   global void execute(SchedulableContext sc) {
      LitmosBatchUpdate b = new LitmosBatchUpdate(); 
      database.executeBatch(b, LitmosBatchUpdate.MAX_SCOPE);
   }
   
}