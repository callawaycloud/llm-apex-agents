@isTest
public class zFileCreationAgentToolTest {
    
    @isTest
    private static void test_getDescription() {
        zFileCreationAgentTool tool = new zFileCreationAgentTool();
        String description = tool.getDescription();
        System.assertEquals('Create Salesforce files and optionally link them to Salesforce records', description);
    }
    
    @isTest
    private static void test_getParameters() {
        zFileCreationAgentTool tool = new zFileCreationAgentTool();
        Map<String, String> parameters = tool.getParameters();
        System.assertEquals(3, parameters.size());
        System.assertEquals('The name of the file to be created', parameters.get('fileName'));
        System.assertEquals('File content as a string', parameters.get('fileTextContent'));
        System.assertEquals('The Salesforce record Id to which the file should be linked (optional)', parameters.get('recordId'));
    }
    
    @isTest
    private static void test_execute_missingFileName() {
        zFileCreationAgentTool tool = new zFileCreationAgentTool();
        Map<String, String> args = new Map<String, String> {
            'fileTextContent' => 'Test content'
        };
        
        Test.startTest();
        Exception e = null;
        try {
            tool.execute(args);
        } catch (Exception ex) {
            e = ex;
        }
        Test.stopTest();
        
        System.assertNotEquals(null, e);
        System.assertEquals('Missing required parameter: fileName', e.getMessage());
    }
    
    @isTest
    private static void test_execute_missingFileContent() {
        zFileCreationAgentTool tool = new zFileCreationAgentTool();
        Map<String, String> args = new Map<String, String> {
            'fileName' => 'Test file'
        };
        
        Test.startTest();
        Exception e = null;
        try {
            tool.execute(args);
        } catch (Exception ex) {
            e = ex;
        }
        Test.stopTest();
        
        System.assertNotEquals(null, e);
        System.assertEquals('Missing required parameter: fileTextContent', e.getMessage());
    }
    
    @isTest
    private static void test_execute_withoutRecordId() {
        zFileCreationAgentTool tool = new zFileCreationAgentTool();
        Map<String, String> args = new Map<String, String> {
            'fileName' => 'Test file',
            'fileTextContent' => 'Test content'
        };
        
        Test.startTest();
        String result = tool.execute(args);
        Test.stopTest();
        
        System.assert(result.startsWith('File created with Id: '));
    }
    
    @isTest
    private static void test_execute_withRecordId() {
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;
        
        zFileCreationAgentTool tool = new zFileCreationAgentTool();
        Map<String, String> args = new Map<String, String> {
            'fileName' => 'Test file',
            'fileTextContent' => 'Test content',
            'recordId' => testAccount.Id
        };
        
        Test.startTest();
        String result = tool.execute(args);
        Test.stopTest();
        
        System.assert(result.startsWith('File created with Id: '));
    }
}