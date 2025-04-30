/**
* SendSlackMessageAction
* 
* Invocable Apex action that sends a message to a Slack channel.
* Requires direct Channel ID and Workspace ID rather than names.
* Uses Named Credential 'Slack_API' for authentication.
*/
public class SendSlackMessageAction {
          
    /**
    * Invocable method input class
    */
    public class MessageInput {        
        @InvocableVariable(required=true description='ID of the channel to send to')
        public String channel_id;

        @InvocableVariable(required=true description='ID of the workspace to send to')
        public String workspace_id;
              
        @InvocableVariable(required=true description='Message text to send')
        public String text;
    }
          
    /**
    * Invokable method output class returned to Flow/Process Builder
    * Provides message send status, timestamp for reference, and any error details
    * Message timestamp (ts) can be used as a message identifier for later updates/deletion
    */
    public class MessageOutput {
        @InvocableVariable(description='True if message was sent successfully')
        public Boolean is_success;
              
        @InvocableVariable(description='Timestamp of sent message')
        public String message_ts;
              
        @InvocableVariable(description='Error message if send failed')
        public String error_message;
    }
          
    /**
    * Main invocable method to send a message to Slack
    * Handles a list of inputs for bulk processing but typically receives one input
    * Returns a corresponding list of outputs with success/failure details
    * 
    * @param inputs List of MessageInput objects containing message details
    * @return List<MessageOutput> Results of the message send operation(s)
    */
    @InvocableMethod(label='Send Slack Message To Channel')
    public static List<MessageOutput> sendMessage(List<MessageInput> inputs) {
        List<MessageOutput> outputs = new List<MessageOutput>();
              
        // Process each input (usually just one)
        for(MessageInput input : inputs) {
            MessageOutput output = new MessageOutput();
            output.is_success = false; // Default to false until success confirmed
                  
            try {
                // Setup HTTP request to Slack API
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Slack_API/chat.postMessage');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                      
                // Construct message payload
                Map<String, String> body = new Map<String, String>{
                    'channel' => input.channel_id,
                    'text' => input.text,
                    'team_id' => input.workspace_id
                };
                      
                request.setBody(JSON.serialize(body));
                      
                // Send message to Slack
                HttpResponse response = http.send(request);
                      
                // Parse the JSON response
                Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                      
                // Check for success and process results
                if(response.getStatusCode() == 200 && responseBody.get('ok') == true) {
                    output.is_success = true;
                    output.message_ts = (String)responseBody.get('ts');
                } else {
                    // Capture API error message if present
                    output.error_message = 'API Error: ' + responseBody.get('error');
                }
                      
            } catch(Exception e) {
                // Handle any exceptions (callout errors, parsing errors, etc)
                output.error_message = 'Error: ' + e.getMessage();
                System.debug('Error details: ' + e.getStackTraceString());
            }
                  
            outputs.add(output);
        }
              
        return outputs;
    }
}