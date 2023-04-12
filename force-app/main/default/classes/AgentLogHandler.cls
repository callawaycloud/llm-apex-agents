public with sharing class AgentLogHandler {
  public static void handleAgentLog(List<Agent_Log__c> agentLogs) {
    List<Agent_Log_Event__e> agentLogEvents = new List<Agent_Log_Event__e>();
    for (Agent_Log__c agentLog : agentLogs) {
      agentLogEvents.add(new Agent_Log_Event__e(Agent_Log_Id__c = agentLog.Id));
    }
    EventBus.publish(agentLogEvents);
  }
}
