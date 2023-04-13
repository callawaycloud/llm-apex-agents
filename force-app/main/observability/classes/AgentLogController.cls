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
        Events__c,
        Last_Agent_Update__c
      FROM Agent_Log__c
      ORDER BY Last_Agent_Update__c DESC NULLS LAST
      LIMIT 10
    ];
  }

  @AuraEnabled
  public static Agent_Log__c getSingleRecord(String agentId) {
    Agent_Log__c log = [
      SELECT
        Id,
        Agent_Id__c,
        Input__c,
        Result__c,
        Error__c,
        Log__c,
        Events__c,
        Last_Agent_Update__c
      FROM Agent_Log__c
      WHERE Agent_Id__c = :agentId
    ];
    return log;
  }

  // Run an agent (in it's entirety) for a given objective
  @AuraEnabled
  public static string runAgent(string objective) {
    OpenAIChatModel chatLLM = new OpenAIChatModel();

    // chatLLM.model = 'gpt-3.5-turbo';
    chatLLM.model = 'gpt-4';

    Map<String, IAgentTool> tools = new Map<String, IAgentTool>{
      'find_records' => new SOSLSearchAgentTool(),
      'send_notification' => new SentNotificationAgentTool(
        '0ML8F000000CgTeWAK' // custom label? Or just query a random notification type
      ),
      'create_records' => new CreateRecordAgentTool(),
      'get_fields' => new GetSObjectFieldsAgentTool(),
      'list_custom_objects' => new ListSObjectAgentTool(),
      'execute_soql' => new RunSQLAgentTool()
    };
    ReActZeroShotChatPrompt prompt = new ReActZeroShotChatPrompt(tools);
    ReActChatAgent agent = new ReActChatAgent(objective, prompt, chatLLM);

    AgentQueueable manager = new AgentQueueable(agent);
    manager.startAgent();
    return agent.getId();
  }
}
