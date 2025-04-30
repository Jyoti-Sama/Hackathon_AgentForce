public class GetSlackChannelAction {
          
    /**
    * Input class for the Flow action
    * Requires both workspace name and channel name to perform the search
    * Default channel name is 'Hackathon' if not provided
    */
    public class ChannelSearchInput {
        @InvocableVariable(required=false description='Name of the Slack channel to search for')
        public String channel_name = 'Hackathon';  // Default value 'Hackathon'
              
        @InvocableVariable(required=true description='Name of the Slack workspace')
        public String workspace_name;
    }
          
    /**
    * Output class containing channel details or error information
    * Returns basic channel information including ID, name, member count, and topic
    */
    public class ChannelSearchOutput {
        @InvocableVariable(description='Channel ID')
        public String channel_id;
              
        @InvocableVariable(description='Channel Name')
        public String channel_name;
              
        @InvocableVariable(description='Number of members in the channel')
        public Integer num_members;
              
        @InvocableVariable(description='Channel topic')
        public String topic;
              
        @InvocableVariable(description='Error message if search failed')
        public String error_message;
              
        @InvocableVariable(description='List of similar channel names')
        public List<String> similar_channels; // To return similar channels
    }
          
    // ------------------------  
    // API Response Structures
    // ------------------------

    // Same response structures for Slack API, no changes here
    private class TeamsListResponse {
        public Boolean ok;
        public List<Team> teams;
        public ResponseMetadata response_metadata;
        public String error;
    }
          
    private class Team {
        public String id;
        public String name;
    }
          
    private class SlackResponse {
        public Boolean ok;
        public List<Channel> channels;
        public ResponseMetadata response_metadata;
        public String error;
    }
          
    private class ResponseMetadata {
        public String next_cursor;
    }
          
    private class Channel {
        public String id;
        public String name;
        public Integer num_members;
        public Topic topic;
    }
          
    private class Topic {
        public String value;
    }
          
    /**
    * Main invocable method for the Flow action
    * Processes a list of inputs (bulk processing support) and returns corresponding outputs
    */
    @InvocableMethod(label='Get Slack Channel' 
                    description='Searches for a Slack channel by name in specified workspace and returns its details')
    public static List<ChannelSearchOutput> searchChannel(List<ChannelSearchInput> inputs) {
        List<ChannelSearchOutput> outputs = new List<ChannelSearchOutput>();
              
        // Process each input in the list (supporting bulk operations)
        for(ChannelSearchInput input : inputs) {
            ChannelSearchOutput output = new ChannelSearchOutput();
            output.similar_channels = new List<String>(); // Initialize similar channels list
                   
            try {
                // Step 1: Get the workspace ID from the workspace name
                String teamId = getWorkspaceId(input.workspace_name);
                       
                if (teamId == null) {
                    output.error_message = 'Workspace "' + input.workspace_name + '" not found';
                    outputs.add(output);
                    continue;
                }
                       
                // Step 2: Search for the channel in the identified workspace
                Channel foundChannel = searchAllChannels(input.channel_name, teamId, output);
                       
                // Step 3: Process results
                if (foundChannel != null) {
                    // Channel found - populate output with channel details
                    output.channel_id = foundChannel.id;
                    output.channel_name = foundChannel.name;
                    output.num_members = foundChannel.num_members;
                           
                    if (foundChannel.topic != null) {
                        output.topic = foundChannel.topic.value;
                    }
                } else {
                    // No exact match found, return similar channels
                    if (output.similar_channels.isEmpty()) {
                        output.error_message = 'No exact match found. Found similar channels: ' + String.join(output.similar_channels, ', ');
                    } else {
                        output.error_message = 'Channel not found. Similar channels: ' + String.join(output.similar_channels, ', ');
                    }
                }
                       
            } catch(Exception e) {
                // Handle any errors that occur during processing
                output.error_message = 'Error: ' + e.getMessage();
                System.debug('Error details: ' + e.getStackTraceString());
            }
                   
            outputs.add(output);
        }
              
        return outputs;
    }
          
    /**
    * Gets the workspace ID for a given workspace name using auth.teams.list
    * This method handles the Enterprise Grid workspace lookup
    * 
    * @param workspaceName The name of the workspace to find
    * @return The workspace ID if found, null if not found
    */
    private static String getWorkspaceId(String workspaceName) {
        // Initialize HTTP request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Slack_API/auth.teams.list');
        request.setMethod('GET');
              
        // Make the API call
        HttpResponse response = http.send(request);
              
        // Check for successful response
        if (response.getStatusCode() != 200) {
            throw new CalloutException('Teams list failed with status code: ' + response.getStatusCode());
        }
              
        // Parse the response
        TeamsListResponse teamsResponse = (TeamsListResponse)JSON.deserialize(
            response.getBody(), 
            TeamsListResponse.class
        );
              
        if (!teamsResponse.ok) {
            throw new CalloutException('Teams list not OK: ' + teamsResponse.error);
        }
              
        // Search for matching workspace name
        for (Team team : teamsResponse.teams) {
            if (team.name.equalsIgnoreCase(workspaceName)) {
                return team.id;
            }
        }
              
        // No matching workspace found
        return null;
    }
          
    /**
    * Searches for a channel by name within a specific workspace
    * Handles pagination to search through all available channels
    * Returns a list of similar channel names if exact match is not found
    * 
    * @param channelName The name of the channel to find
    * @param teamId The ID of the workspace to search in
    * @return Channel object if found, null if not found
    */
    private static Channel searchAllChannels(String channelName, String teamId, ChannelSearchOutput output) {
        String cursor = null;
              
        do {
            // Construct endpoint URL with team_id and pagination cursor
            String endpoint = 'callout:Slack_API/conversations.list?team_id=' + teamId;
            if (String.isNotBlank(cursor)) {
                endpoint += '&cursor=' + EncodingUtil.urlEncode(cursor, 'UTF-8');
            }
                   
            // Initialize HTTP request
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
                   
            // Make the API call
            HttpResponse response = http.send(request);
                   
            // Check for successful response
            if (response.getStatusCode() != 200) {
                throw new CalloutException('Failed with status code: ' + response.getStatusCode());
            }
                   
            // Parse the response
            SlackResponse slackResponse = (SlackResponse)JSON.deserialize(
                response.getBody(), 
                SlackResponse.class
            );
                   
            if (!slackResponse.ok) {
                throw new CalloutException('Slack API response not OK: ' + slackResponse.error);
            }
                   
            // Search through current page of channels
            for (Channel channel : slackResponse.channels) {
                if (channel.name.equalsIgnoreCase(channelName)) {
                    return channel;  // Exact match found
                } else {
                    // Add similar channels to the output
                    if (!output.similar_channels.contains(channel.name)) {
                        output.similar_channels.add(channel.name);
                    }
                }
            }
                   
            // Get cursor for next page of results
            cursor = (slackResponse.response_metadata != null) ? 
                    slackResponse.response_metadata.next_cursor : null;
                          

        } while (String.isNotBlank(cursor)); // Continue while there are more pages
              
        // No channel found after searching all pages
        return null;
    }
}