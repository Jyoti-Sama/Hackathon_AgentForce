@IsTest
private class SplitStringInvocableTest {
    @IsTest
    static void testSplitString() {
        SplitStringInvocable.InputWrapper input = new SplitStringInvocable.InputWrapper();
        input.inputString = 'apple, banana, cherry';

        List<SplitStringInvocable.InputWrapper> inputs = new List<SplitStringInvocable.InputWrapper>{ input };
        List<SplitStringInvocable.OutputWrapper> results = SplitStringInvocable.splitString(inputs);

        System.assertEquals(1, results.size());
        System.assertEquals(3, results[0].stringCollection.size());
        System.assertEquals('apple', results[0].stringCollection[0]);
        System.assertEquals('banana', results[0].stringCollection[1]);
        System.assertEquals('cherry', results[0].stringCollection[2]);
    }
}