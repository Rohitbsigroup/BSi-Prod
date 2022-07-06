/********************************************************************
 * bg_Enrolment_AU
 *
 * After Update trigger for Enrollment__c object
 * 
 * Author: Alexis Lignereux
 * Created: 06-01-2015
 * Changes: Nick Fisher - Method calls added:
                - bg_TrainingUtils.cancelEnrolments
                - bg_TrainingUtils.processOnHoldEnrolments
 ********************************************************************/
trigger bg_Enrolment_AU on Enrollment__c (after update) {

}