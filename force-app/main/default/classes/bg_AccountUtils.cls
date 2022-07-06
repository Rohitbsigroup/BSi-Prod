/********************************************************************
 * bg_AccountUtils
 *
 * Utility methods to support Accounts
 * Test Class : bg_AccountUtilsTest
 *
 * Author: Antony Daley
 * Created: 30-10-2014 
 ********************************************************************/
public class bg_AccountUtils 
{
	public static Account GetAccountBSIMembership(Id accId)
	{
		/*
			Get Account BSI Membership fields 
		*/
		return [SELECT Id, Name, BSIMembershipNo__c, BSIMembershipExpiryDate__c
				FROM Account
				WHERE Id = :accId];
	}

	public static Account getAccount(Id accId)
	{
		Account retVal = null;
		List<Account> accounts = getAccounts(new Set<Id>{accId});
		if(!accounts.isEmpty())
		{
			retVal = accounts[0]; 
		}
		return retVal;
	}

	public static List<Account> getAccounts(Set<Id> accIds)
	{
		Map<Id, Account> accountsById = getAccountMap(accIds);
		return accountsById.values();
	}

	public static Map<Id,Account> getAccountMap(Set<Id> accIds)
	{
		return new Map<Id,Account>([SELECT Id,
										   Name,
										   TCodeDescr__c,
										   Industry,
										   BillingCountry
								    FROM Account
								    WHERE Id IN :accIds]);
	}
}