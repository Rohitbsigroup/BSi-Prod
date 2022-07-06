public class attendanceRegisterControllerRank {

public List <rEnrollment> rEnrollmentList {get; set;}
public Id TrainingEventId {get;set;}
public Integer RInt {get;set;}


/* 
*The aim is to create a wrapper class of the enrollments and add two extra 'fields', a rank and a rank choice.  By creating a map of the soql aggregate of enrollments by training event course name
*we first get an array/list of the result of courseNames and as the aggregate query is only grouping on the one field these are unique but we have also ordered these by dates in a manner meaningful to
*how we want to the present a series of a components repeated on an email template. Hence use of map rather than set.  Note the component will get repeated!
*So we put the list of course names into the rankMap map but as the key!  The value is given through iteration, such that the first course name in the map is key to a value of 1, the second 2 etc
*having done this we run through a list of enrollments to add them to a wrapper class with one of the extra 'fields' picking up from the map by course name the rank number e.g 1,2,3 etc
*the expectation is this is used for combinded courses unlikely to be over 3
*we also have a second extra 'field' courseRankChoice, this is going to be something passed back from the calling email template to limit the returned records
*to appreciate this effect look at the associated components and email template and see how the same component will be call in series but each time there will be
*a different number for the rank choices.  Component: CombinedEventDelegatesRank  EmailTemplate: Tutor_Information_Email_Com_Events_Rank
*/

public List<rEnrollment>getEnrollments(){

                AggregateResult[] ars = [SELECT Training_Event__r.Course__r.Name courseName FROM Enrollment__c where Training_Event__r.Master_Training_Event__r.Id= :TrainingEventId  GROUP BY Training_Event__r.Course__r.Name, Training_Event__r.Start_Date__c ORDER BY Training_Event__r.Start_Date__c ASC];
                
                map<string,integer> rankMap = new map<string,integer>();
                
                Integer i=1;    
                for(AggregateResult ar : ars){
                rankMap.put((string) ar.get('courseName'), (integer) i);
                i++;    
                }

if(rEnrollmentList==null){
    rEnrollmentList=new List<rEnrollment>();
        
             for(Enrollment__c e: [select Id, Name,Course_Start_Date__c, Training_Event__r.End_Date3__c, Training_Event__r.Name , Training_Event__r.SAP_SMO_number__c,  Training_Event__r.Course__r.Name, delegate_name__r.name, delegate_name__r.phone, delegate_name__r.title,delegate_name__r.Account.Name from Enrollment__c where Booking_Status__c Like 'Booked%' AND Training_Event__r.Master_Training_Event__r.Id=:TrainingEventId
             ORDER BY Training_Event__r.Start_Date__c, Training_Event__r.Course__r.Name, Delegate_name__r.Name ASC]) {
                Integer j = Rint;
                // As each enrollment is processed we create a new eEnrollment object and add it to the enrollmentList
                rEnrollmentList.add(new rEnrollment(e,rankMap.get(e.Training_Event__r.Course__r.Name),j));
                                 
            }
        }
        return rEnrollmentList;
    }

//Wrapper class to take Enrollments and add rank number from Training Events grouped
public class rEnrollment{
    public Enrollment__c enr {get; set;}
    public integer courseRank {get; set;}
    public integer courseRankChoice {get;set;}

//constructor method on rEnrollement taking Enrollment and array as parameters

public rEnrollment(Enrollment__c e, Integer rkMap,Integer intRint){
enr = e;
courseRank = rkMap;
courseRankChoice = intRint;

}

}

}