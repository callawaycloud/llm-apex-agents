@isTest
public class zMergeRecordsAgentToolTest {
    
    @isTest
    static void testGetDescription() {
        zMergeRecordsAgentTool tool = new zMergeRecordsAgentTool();
        String description = tool.getDescription();
        System.assertEquals('Merge records of the same sObject type', description);
    }

    @isTest
    static void testGetParameters() {
        zMergeRecordsAgentTool tool = new zMergeRecordsAgentTool();
        Map<String, String> params = tool.getParameters();
        System.assertEquals(3, params.size());
        System.assertEquals('The sObject type to merge (e.g., Account, Contact, Lead, Case)', params.get('sObjectType'));
        System.assertEquals('The ID of the master record to merge into', params.get('masterRecordId'));
        System.assertEquals('A comma-separated list of up to two record IDs to merge with the master record', params.get('mergeRecordIds'));
    }

    @isTest
    static void testExecute() {
        // Create test records
        Account masterAccount = new Account(Name = 'Master Account');
        insert masterAccount;
        Account mergeAccount1 = new Account(Name = 'Merge Account 1');
        insert mergeAccount1;
        Account mergeAccount2 = new Account(Name = 'Merge Account 2');
        insert mergeAccount2;

        // Test tool
        zMergeRecordsAgentTool tool = new zMergeRecordsAgentTool();
        
        // Test missing parameters
        Map<String, String> missingParams = new Map<String, String>();
        try {
            tool.execute(missingParams);
            System.assert(false, 'Should throw exception for missing parameters');
        } catch (Agent.ActionRuntimeException e) {
            System.assertEquals('missing required parameters: sObjectType, masterRecordId, mergeRecordIds', e.getMessage());
        }

        // Test successful merge
        Map<String, String> mergeParams = new Map<String, String>{
            'sObjectType' => 'Account',
            'masterRecordId' => masterAccount.Id,
            'mergeRecordIds' => mergeAccount1.Id + ',' + mergeAccount2.Id
        };
        String mergeResult = tool.execute(mergeParams);
        System.assertEquals('Records merged successfully', mergeResult);

        // Validate merge
        Account mergedAccount = [SELECT Id, Name FROM Account WHERE Id = :masterAccount.Id];
        System.assertEquals('Master Account', mergedAccount.Name);
        System.assert([SELECT COUNT() FROM Account WHERE Id IN :new List<Id>{mergeAccount1.Id, mergeAccount2.Id}] == 0);
    }

    @isTest
    static void testExecuteMoreThanTwoMergeRecords() {
        // Create test records
        Account masterAccount = new Account(Name = 'Master Account');
        insert masterAccount;
        Account mergeAccount1 = new Account(Name = 'Merge Account 1');
        insert mergeAccount1;
        Account mergeAccount2 = new Account(Name = 'Merge Account 2');
        insert mergeAccount2;
        Account mergeAccount3 = new Account(Name = 'Merge Account 3');
        insert mergeAccount3;

        // Test tool
        zMergeRecordsAgentTool tool = new zMergeRecordsAgentTool();

        // Test more than two merge records
        Map<String, String> mergeParams = new Map<String, String>{
            'sObjectType' => 'Account',
            'masterRecordId' => masterAccount.Id,
            'mergeRecordIds' => mergeAccount1.Id + ',' + mergeAccount2.Id + ',' + mergeAccount3.Id
        };
        try {
            tool.execute(mergeParams);
            System.assert(false, 'Should throw exception for more than two merge records');
        } catch (Agent.ActionRuntimeException e) {
            System.assertEquals('You can only merge up to two records with the master record', e.getMessage());
        }
    }

    @isTest
    static void testExecuteFailedMerge() {
        // Create test records
        Account masterAccount = new Account(Name = 'Master Account');
        insert masterAccount;
        Contact mergeContact1 = new Contact(LastName = 'Merge Contact 1');
        insert mergeContact1;

        // Test tool
        zMergeRecordsAgentTool tool = new zMergeRecordsAgentTool();

        // Test failed merge due to different sObject types
        Map<String, String> mergeParams = new Map<String, String>{
            'sObjectType' => 'Account',
            'masterRecordId' => masterAccount.Id,
            'mergeRecordIds' => mergeContact1.Id
        };
        try {
            tool.execute(mergeParams);
            System.assert(false, 'Should throw exception for failed merge');
        } catch (Agent.ActionRuntimeException e) {
            System.assert(e.getMessage().contains('Failed to merge records: '));
        }
    }
}