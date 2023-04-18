public class AgentEventProducer implements Agent.EventHandler {
  public void publish(String agentId, string type, Object data) {
    List<Agent_Event__e> agentLogEvents = new List<Agent_Event__e>();
    agentLogEvents.add(
      new Agent_Event__e(
        Agent_Id__c = agentId,
        Type__c = type,
        Data__c = JSON.serialize(data)
      )
    );
    EventBus.publish(agentLogEvents);
  }

  public void onEvent(String agentId, Agent.EventType type, Object data) {
    publish(agentId, type.name(), data);
  }
}
