public class SplitStringInvocable {

    public class InputWrapper {
        @InvocableVariable(required=true)
        public String inputString;
    }

    public class OutputWrapper {
        @InvocableVariable
        public List<String> stringCollection;

        public OutputWrapper(List<String> stringCollection) {
            this.stringCollection = stringCollection;
        }
    }

    @InvocableMethod(label='Split Comma-Separated String' description='Splits a comma-separated string into a collection of strings.')
    public static List<OutputWrapper> splitString(List<InputWrapper> inputs) {
        List<OutputWrapper> results = new List<OutputWrapper>();
        
        for (InputWrapper input : inputs) {
            List<String> splitValues = new List<String>();
            if (String.isNotBlank(input.inputString)) {
                splitValues = new List<String>(input.inputString.split(','));
                for (Integer i = 0; i < splitValues.size(); i++) {
                    splitValues[i] = splitValues[i].trim();
                }
            }
            results.add(new OutputWrapper(splitValues));
        }

        return results;
    }
}