trigger AgentEventTrigger on Agent_Event__e(after insert) {
  AgentEventHandler handler = new AgentEventHandler();
  handler.handle();
}
