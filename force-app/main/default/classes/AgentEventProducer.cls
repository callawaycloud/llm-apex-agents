public class AgentEventProducer implements Agent.EventHandler {
  private string agentId;
  public AgentEventProducer(String agentId) {
    this.agentId = agentId;
  }
  public void publish(string type, Object data) {
    List<Agent_Event__e> agentLogEvents = new List<Agent_Event__e>();
    agentLogEvents.add(
      new Agent_Event__e(
        Agent_Id__c = this.agentId,
        Type__c = type,
        Data__c = JSON.serialize(data)
      )
    );
    EventBus.publish(agentLogEvents);
  }

  public void onEvent(Agent.EventType type, Object data) {
    publish(type.name(), data);
  }
}
