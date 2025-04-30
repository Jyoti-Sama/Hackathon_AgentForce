public class GoogleSheetsAPI {

    // Method to append data to a Google Sheet
    @future(callout=true)
    public static void appendDataToSheet(String spreadsheetId, String range, String serializedValues) {
        
        // Deserialize the JSON string back into List<List<String>>
        List<List<String>> values = (List<List<String>>)JSON.deserialize(serializedValues, List<List<String>>.class);

        // Create the request body (the data you want to insert)
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('values', values);

        // Convert the request body to JSON
        String jsonBody = JSON.serialize(requestBody);

        // Create a new HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GoogleSheetsAPI/v4/spreadsheets/' + spreadsheetId + '/values/' + range + ':append?valueInputOption=RAW');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        // Set the Authorization header with the access token
        String accessToken = 'YOUR_ACCESS_TOKEN'; // Replace with actual token obtained from your auth provider
        req.setHeader('Authorization', 'Bearer ' + accessToken);

        // Set the body of the request to the JSON data
        req.setBody(jsonBody);

        // Send the request and capture the response
        Http http = new Http();
        HttpResponse res = http.send(req);

        // Handle the response
        if (res.getStatusCode() == 200) {
            System.debug('Data appended successfully: ' + res.getBody());
        } else {
            System.debug('Error appending data: ' + res.getStatusCode() + ' ' + res.getBody());
        }
    }

    // Helper method to invoke the future method with serialized values
    public static void appendDataToSheetAsync(String spreadsheetId, String range, List<List<String>> values) {
        // Serialize the List<List<String>> to a JSON string
        String serializedValues = JSON.serialize(values);

        // Call the future method, passing the serialized data
        appendDataToSheet(spreadsheetId, range, serializedValues);
    }
}