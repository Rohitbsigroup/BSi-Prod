public with sharing class ViesValidation
{
	// Validate a VAT number string
	public static ViesValidationResponse validate(String input)
	{
		// Perform basic format validation
		String regex = '[A-Z]{2}[0-9A-Za-z\\+\\*\\.]{2,12}';
		Pattern pattn = Pattern.compile(regex);
		Matcher match = pattn.matcher(input);
		if (match.matches())
		{
			// Parse the input
			String countryString = input.substring(0, 2);
			String vatNumber = input.substring(2, input.length());

			try
			{
				// Submit to web service for full validation
				ViesWebService.checkVatPort port = new ViesWebService.checkVatPort();
    	    	ViesWebService.checkVatResponse_element resp = port.checkVat(countryString, vatNumber);
        		if (resp.valid)
        		{
        			return new ViesValidationResponse(true, true, '');
        		}
        		else
        		{
        			return new ViesValidationResponse(true, false, 'Not found');
        		}
			}
			catch(Exception ex)
			{
				if (ex.getMessage() == 'INVALID_INPUT')
				{
					return new ViesValidationResponse(true, false, 'Country error');
				}
				else
				{
					return new ViesValidationResponse(false, false, 'Service error');
				}
			}
		}
		else
		{
			// Failed basic format validation
			return new ViesValidationResponse(true, false, 'Format error');
		}
	}

	// Wrapper class for validation response	
	public class ViesValidationResponse
	{
		public Boolean isChecked { get; set; }
		public Boolean isValid { get; set; }
		public String message { get; set; }
		
		ViesValidationResponse(Boolean chked, Boolean valid, String messge)
		{
			this.isChecked = chked;
			this.isValid = valid;
			this.message = messge;
		}
	}
}