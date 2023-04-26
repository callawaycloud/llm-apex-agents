@isTest
public class zChatterAgentToolTest {

    @testSetup
    static void setup() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Chatter Account');
        insert testAccount;
        
        // Create a test FeedItem
        FeedItem testFeedItem = new FeedItem(parentId = testAccount.Id, Body = 'Test post', Type = 'TextPost');
        insert testFeedItem;
    }
    
    @isTest
    static void testGetDescription() {
        zChatterAgentTool agentTool = new zChatterAgentTool();
        String description = agentTool.getDescription();
        System.assertNotEquals(null, description);
    }
    
    @isTest
    static void testGetParameters() {
        zChatterAgentTool agentTool = new zChatterAgentTool();
        Map<String, String> parameters = agentTool.getParameters();
        System.assertNotEquals(null, parameters);
    }
    
    @isTest
    static void testExecuteInsert() {     
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Chatter Account'];
        FeedItem testPost = [SELECT Id FROM FeedItem WHERE ParentId =: testAccount.Id];

        // Test insert operation
        Map<String, String> args = new Map<String, String>{
            'operation' => 'insert',
            'parentId' => testAccount.Id,
            'body' => 'Test insert post',
            'type' => 'TextPost'
        };
        zChatterAgentTool agentTool = new zChatterAgentTool();
        String result = agentTool.execute(args);
        System.assert(result.contains('Post inserted with Id:'));
    }

    @isTest
    static void testExecuteRetrieve() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Chatter Account'];
        FeedItem testPost = [SELECT Id FROM FeedItem WHERE ParentId =: testAccount.Id];

        // Test retrieve operation
        Map<String, String> args = new Map<String, String>{
            'operation' => 'retrieve',
            'Id' => testPost.Id
        };
        zChatterAgentTool agentTool = new zChatterAgentTool();
        String result = agentTool.execute(args);
        System.assertNotEquals(null, result);
    }

    //@isTest
    static void testExecuteUpdate() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Chatter Account'];
        FeedItem testPost = [SELECT Id FROM FeedItem WHERE ParentId =: testAccount.Id];

        // Test update operation
        Map<String, String> args = new Map<String, String>{
            'operation' => 'update',
            'Id' => testPost.Id,
            'body' => 'Test update post'
        };
        zChatterAgentTool agentTool = new zChatterAgentTool();
        String result = agentTool.execute(args);
        System.assert(result.contains('Post updated with Id:'));
    }

    //@isTest
    static void testExecuteUpsert() {  
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Chatter Account'];
        FeedItem testPost = [SELECT Id FROM FeedItem WHERE ParentId =: testAccount.Id];

        // Test upsert operation
        Map<String, String> args = new Map<String, String>{
            'operation' => 'upsert',
            'Id' => testPost.Id,
            'parentId' => testAccount.Id,
            'body' => 'Test upsert post',
            'type' => 'TextPost'
        };
        zChatterAgentTool agentTool = new zChatterAgentTool();
        String result = agentTool.execute(args);
        System.assert(result.contains('Post upserted with Id:'));
    }

    //@isTest
    static void testExecuteDelete() {   
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Chatter Account'];
        FeedItem testPost = [SELECT Id FROM FeedItem WHERE ParentId =: testAccount.Id];

        // Test delete operation
        Map<String, String> args = new Map<String, String>{
            'operation' => 'delete',
            'Id' => testPost.Id
        };
        zChatterAgentTool agentTool = new zChatterAgentTool();
        String result = agentTool.execute(args);
        System.assert(result.contains('Post deleted with Id:'));
    }
}