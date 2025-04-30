trigger OpportunityTrigger on Opportunity (after update) {

    // List to hold the data we will send to Google Sheets
    List<List<String>> valuesToSend = new List<List<String>>();

    // Loop through all the updated Opportunities
    for (Opportunity opp : Trigger.new) {
        // Check if the Opportunity Stage is updated to 'Closed Won'
        if (opp.StageName == 'Closed Won' && Trigger.oldMap.get(opp.Id).StageName != 'Closed Won') {

            // Get all the Opportunity Line Items related to this Opportunity
            List<OpportunityLineItem> oppLineItems = [SELECT id, OpportunityId, Product2.ProductCode, Opportunity.AccountId, Opportunity.Account.Name
                                                      FROM OpportunityLineItem 
                                                      WHERE OpportunityId = :opp.Id];

            // Loop through the Opportunity Line Items and prepare the data for Google Sheets
            for (OpportunityLineItem oli : oppLineItems) {
                // Create a new list with the Account ID and Product Code
                List<String> row = new List<String>{
                    String.valueOf(oli.Opportunity.AccountId), // Account ID
                    oli.Product2.ProductCode,  // Product Code
                        oli.Id,
                        oli.Opportunity.Account.Name
                };

                // Add this row to the list of values
                valuesToSend.add(row);
            }
        }
    }

    // If there are any rows to send, call the GoogleSheetsAPI class
    if (!valuesToSend.isEmpty()) {
        // Specify your Google Spreadsheet ID and range
        String spreadsheetId = '1ne-SAxZzKdwrGwOyRetCcV1YG-AUZQL8LPbRNWcaXV8'; // Replace with your actual Google Sheet ID
        String range = 'Sheet2!A2'; // Start from the second row (after the header)

        // Call the method to append data to the Google Sheet
        GoogleSheetsAPI.appendDataToSheetAsync(spreadsheetId, range, valuesToSend);
    }
}