/********************************************************************
 * bg_Globals
 *
 * Org-Wide Globals
 * 
 * 
 * Author: Richard Jimenez
 * Created: 28-10-2013
 * Changes: 
 *         RJ - 29-07-2015 Added REGISTRAION_PATH_TRANSITION
 ********************************************************************/
public class bg_Globals {

	// Currency Code
	public static final string CURRENCY_CODE_USD = 'USD';
	public static final string CURRENCY_CODE_GBP = 'GBP';
	public static final string CURRENCY_CODE_EUR = 'EUR';
	
	// Lanuage Codes (e.g. used in templates)
	public static final string LANGUAGE_EN = 'EN';
	
	// Global Regions
	public static final string REGION_EMEA 		= 'EMEA';
	public static final string REGION_US   		= 'US';
	public static final string REGION_ASIAPAC   = 'ASIA-PAC';

	// Registration Paths
	public static final string REGISTRAION_PATH_TRANSITION = 'Transition';
	public static final set<string> HQ_ONLY_REG_PATHS = new set<string>{REGISTRAION_PATH_TRANSITION};
}