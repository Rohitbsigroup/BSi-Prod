/*
Created By : PC K2 (February 2020)
This class will schedule Litmos User Creation callout
*/

global class LitmosEnrollmentSchedule implements Schedulable {

    private String companyName;
    private String countryCode;
    private String delegateId;
    private String enrollmentId;
    private String email;
    private String firstName;
    private String lastName;
    private String language;
    private String litmosUserId;
    private String taxonomyCode;
    private String username;

    public LitmosEnrollmentSchedule(String litmosUserId, String email, String username, String firstName, String lastName, String companyName, String taxonomyCode, String countryCode, String language, String enrollmentId, String delegateId){
        this.companyName = companyName;
        this.countryCode = countryCode;
        this.delegateId = delegateId;
        this.enrollmentId = enrollmentId;
        this.email = email;
        this.firstName = firstName;
        this.lastName = lastName;
        this.language = language;
        this.litmosUserId = litmosUserId;
        this.taxonomyCode = taxonomyCode;
        this.username = username;
    }

    global void execute(SchedulableContext sc){
        System.debug('### LitmosEnrollmentSchedule.execute');
        System.debug('### CronTriggerId: ' + sc.getTriggerId());

        //synchronous callouts from scheduled Apex are not supported, running future callout
        EnrollmentTrigHandler.LitmosUser(litmosUserId, email, username, firstName, lastName, companyName, taxonomyCode, countryCode, language, enrollmentId, delegateId, sc.getTriggerId());
    }
}