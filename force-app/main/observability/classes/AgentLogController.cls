//Written by GPT-4
public without sharing class AgentLogController {
  @AuraEnabled
  public static List<Agent_Log__c> getAgentLogRecords() {
    return [
      SELECT
        Id,
        Agent_Id__c,
        Input__c,
        Result__c,
        Error__c,
        Log__c,
        Last_Agent_Update__c
      FROM Agent_Log__c
      ORDER BY Last_Agent_Update__c DESC NULLS LAST
      LIMIT 10
    ];
  }

  @AuraEnabled
  public static Agent_Log__c getSingleRecord(Id id) {
    Agent_Log__c log = [
      SELECT
        Id,
        Agent_Id__c,
        Input__c,
        Result__c,
        Error__c,
        Log__c,
        Last_Agent_Update__c
      FROM Agent_Log__c
      WHERE Id = :id
    ];
    return log;
  }

  // Run an agent (in it's entirety) for a given objective
  @AuraEnabled
  public static void runAgent(string objective) {
    OpenAIChatModel chatLLM = new OpenAIChatModel(
      'TODO: APIKEY NEEDS TO BE MOVED TO NAMED CRED BEFORE THIS CAN WORK HERE'
    );

    SpawnAgentTool agentSpawner = new SpawnAgentTool(
      'Write SOQL Query, given any natural language query. Capable of finding fields and objects in the org.',
      new Map<String, string>{
        'natural_query' => 'Translates a Natural query to translate to a SOQL query'
      },
      chatLLM,
      new Map<String, IAgentTool>{
        'get_fields' => new GetSObjectFieldsAgentTool(),
        'list_custom_objects' => new ListSObjectAgentTool()
      }
    );

    Map<String, IAgentTool> tools = new Map<String, IAgentTool>{
      'write_soql_statement' => agentSpawner,
      'search_internet' => new InternetSearchAgentTool(
        'TODO: APIKEY NEEDS TO BE MOVED TO NAMED CRED BEFORE THIS CAN WORK HERE'
      ),
      'find_records' => new SOSLSearchAgentTool(),
      'send_notification' => new SentNotificationAgentTool(
        '0ML8F000000CgTeWAK' // custom label? Or just query a random notification type
      ),
      'create_records' => new CreateRecordAgentTool(),
      'get_fields' => new GetSObjectFieldsAgentTool(),
      'list_custom_objects' => new ListSObjectAgentTool(),
      'execute_soql' => new RunSQLAgentTool(),
      'get_current_user' => new GetCurrentUserAgentTool()
    };
    ReActZeroShotChatPrompt prompt = new ReActZeroShotChatPrompt(tools);
    ReActChatAgent agent = new ReActChatAgent(objective, prompt, chatLLM);

    //run
    AgentQueueable queuable = new AgentQueueable(agent);
    System.enqueueJob(queuable);
  }
}

/** Register pushtopic

  delete [SELECT Id FROM PushTopic WHERE Name = 'Agent_Log_Channel'];
  PushTopic agentLogPushTopic = new PushTopic();
  agentLogPushTopic.Name = 'Agent_Log_Channel';
  agentLogPushTopic.Query = 'SELECT Id, Agent_Id__c, Last_Agent_Update__c FROM Agent_Log__c';
  agentLogPushTopic.ApiVersion = 52.0;
  agentLogPushTopic.NotifyForOperationCreate = true;
  agentLogPushTopic.NotifyForOperationUpdate = true;
  agentLogPushTopic.NotifyForOperationUndelete = false;
  agentLogPushTopic.NotifyForOperationDelete = false;
  agentLogPushTopic.NotifyForFields = 'Referenced';

  insert agentLogPushTopic;
 */

