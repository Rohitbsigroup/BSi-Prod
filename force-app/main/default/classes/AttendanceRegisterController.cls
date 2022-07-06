/*
*  change log
*  PC K2           20-07-18    re-worked controller
*  Maria Dyer      03-01-19    new fields retrieved from Delegate Contact
*/

public class AttendanceRegisterController {

/*
Regular Training Events filter for Training_Event__r.id 
Combined Training Events filter for Training_Event__r.Master_Training_Event__r.Id
*/

    public Training_Event__c trainingEvent {get;set;}
    public String trainingEventName {get;set;}
    public String trainingEventSAPSMONumber {get;set;}
    public List<Enrollment__c> enrollmentList {get;set;}
    public List<List<Date>> pageDateList {get;set;}
    public List<List<Date>> pageDateListKR {get;set;}
    public List<Date> dateList {get;set;}

    private static final Integer PAGE_SIZE = 5;
    private static final Integer PAGE_SIZE_KR = 2;

    public AttendanceRegisterController(){
        String recordId = ApexPages.currentPage().getParameters().get('Id');

        trainingEvent = [
            SELECT 
            Start_Date__c, End_Date_of_Section_1__c, Start_Date_of_Section_2__c, End_Date3__c, Split_Date_Event__c, 
            Name, SAP_SMO_number__c, Event_Country__c, Course_Duration_Days__c, Course_Name_for_Certificate__c, 
            Course__r.Name, 
            Course__r.Training_Translations__r.Attendance_Register_Guide__c, 
            Course__r.Training_Translations__r.Date__c, 
            Course__r.Training_Translations__r.Date_s__c, 
            Course__r.Training_Translations__r.Location__c, 
            Course__r.Training_Translations__r.The_venue__c, 
            Course__r.Training_Translations__r.Time__c, 
            Course__r.Training_Translations__r.To__c, 
            Course__r.Training_Translations__r.Instructor__c, 
            Course__r.Training_Translations__r.Country_code__c, 
            Course__r.Training_Translations__r.Language__c, 
            RecordType.Name, 
            Trainer__r.Name, 
            Training_Venue__r.Name, 
            Training_Venue__r.Training_Office__r.Training_Translations__r.Attendance_Register_Guide__c, 
            Training_Venue__r.Training_Office__r.Training_Translations__r.Date__c, 
            Training_Venue__r.Training_Office__r.Training_Translations__r.Date_s__c, 
            Training_Venue__r.Training_Office__r.Training_Translations__r.Location__c, 
            Training_Venue__r.Training_Office__r.Training_Translations__r.The_venue__c, 
            Training_Venue__r.Training_Office__r.Training_Translations__r.Time__c, 
            Training_Venue__r.Training_Office__r.Training_Translations__r.To__c, 
            Training_Venue__r.Training_Office__r.Training_Translations__r.Instructor__c, 
            Training_Venue__r.Training_Office__r.Training_Translations__r.Country_code__c, 
            Training_Venue__r.Training_Office__r.Training_Translations__r.Language__c, 
            Training_Venue__r.Venue_Country__c 
            FROM Training_Event__c WHERE Id = :recordId];
        trainingEventName = trainingEvent.Name;
        trainingEventSAPSMONumber = trainingEvent.SAP_SMO_number__c;

        String query = 'SELECT Name, Booking_Status__c, Course_Start_Date__c, Training_Event__r.End_Date3__c, Delegate_Name_Characters__c, Delegate_Name__r.Name, Delegate_Name__r.Title, Delegate_Name__r.FirstNameLocal, Delegate_Name__r.LastNameLocal, Delegate_Name__r.Account.Name, Delegate_Name__r.Account.NameLocal, Training_Event__r.Course__r.Name, Training_Event__r.Course_Name_for_Certificate__c, Training_Event__r.Course__r.Product_Name_Local__c ' 
            + 'FROM Enrollment__c WHERE (Booking_Status__c = ' + '\'Booked\' OR Booking_Status__c = ' + '\'Booked - Resit\' OR Booking_Status__c = '  + '\'Booked - Partner\' OR Booking_Status__c = '  + '\'Booked - BSI Employee\' OR Booking_Status__c = '  + '\'Booked - BSI Employee Resit\') '
            + (trainingEvent.RecordType.Name == Label.Global_Training_Event_Combined_Master ? 'AND Training_Event__r.Master_Training_Event__r.Id = \'' + recordId + '\'' : 'AND Training_Event__r.Id = \'' + recordId + '\'');
        enrollmentList = Database.query(query);

        //get all dates
        dateList = new List<Date>();
        if(trainingEvent.Split_Date_Event__c){
            //split date event
            if(trainingEvent.Start_Date__c != null && trainingEvent.End_Date_of_Section_1__c != null){
                Integer section1DaysCount = trainingEvent.Start_Date__c.daysBetween(trainingEvent.End_Date_of_Section_1__c);
                for(Integer i=0; i<=section1DaysCount; i++){
                    dateList.add(trainingEvent.Start_Date__c.addDays(i));
                }
            }
            if(trainingEvent.Start_Date_of_Section_2__c != null && trainingEvent.End_Date3__c != null){
                Integer section2DaysCount = trainingEvent.Start_Date_of_Section_2__c.daysBetween(trainingEvent.End_Date3__c);
                for(Integer i=0; i<=section2DaysCount; i++){
                    dateList.add(trainingEvent.Start_Date_of_Section_2__c.addDays(i));
                }
            }
        }else{
            //non-spit date event
            for(Integer i=0; i<trainingEvent.Course_Duration_Days__c; i++){
                dateList.add(trainingEvent.Start_Date__c.addDays(i));
            } 
        }
        //System.debug('### dateList: ' + dateList);

        pageDateList = new List<List<Date>>();
        pageDateList.add(new List<Date>());
        pageDateListKR = new List<List<Date>>();
        pageDateListKR.add(new List<Date>());

        Integer currentPageDate = 0;
        Integer currentPageSize = 0;
        Integer currentPageDateKR = 0;
        Integer currentPageSizeKR = 0;

        //divide days into pages
        for(Integer i=0; i<dateList.size(); i++){
            currentPageSize++;
            pageDateList[currentPageDate].add(dateList[i]);
            if(i != 0 && Math.mod(currentPageSize, PAGE_SIZE) == 0 && currentPageSize != dateList.size()){
                pageDateList.add(new List<Date>());
                currentPageDate++;
            }

            //Korea
            currentPageSizeKR++;
            pageDateListKR[currentPageDateKR].add(dateList[i]);
            if(i != 0 && Math.mod(currentPageSizeKR, PAGE_SIZE_KR) == 0 && currentPageSizeKR != dateList.size()){
                pageDateListKR.add(new List<Date>());
                currentPageDateKR++;
            }
        }
        //System.debug('### pageDateList: ' + pageDateList);
        //System.debug('### pageDateListKR: ' + pageDateListKR);
    }

}