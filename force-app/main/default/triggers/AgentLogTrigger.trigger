trigger AgentLogTrigger on Agent_Log__c(after insert, after update) {
  AgentLogHandler.handleAgentLog(Trigger.new);
}
