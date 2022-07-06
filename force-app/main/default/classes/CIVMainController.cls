/********************************************************************
 * CIVMainController
 *
 * Controller class for civ Main component
 * 
 * Author: Richard Jimenez
 * Created: 10-09-2014
 * Changes: 
 ********************************************************************/
public with sharing class CIVMainController {
	public sObject record {get; set;}
	public string recordNameValue {get; set;}
	public string recordCompanyValue {get; set;}
	public string recordEmailValue {get; set;}
	public string recordPostcodeValue {get; set;}
	public string recordPhoneValue {get; set;}
	public string recordAccountId {get; set;}
	public string recordContactId {get; set;}
}