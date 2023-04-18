/** Takes PE and updates log */
public with sharing class AgentEventHandler {
  public void handle() {
    Map<String, Agent_Event__e[]> eventsByAgentId = new Map<String, Agent_Event__e[]>();
    for (Agent_Event__e evt : (Agent_Event__e[]) Trigger.new) {
      //these are just used to trigger the UI update ASAP
      if (evt.Type__c == Agent.EventType.LOG_INIT.name()) {
        continue;
      }
      if (!eventsByAgentId.containsKey(evt.Agent_Id__c)) {
        eventsByAgentId.put(evt.Agent_Id__c, new List<Agent_Event__e>{ evt });
      } else {
        eventsByAgentId.get(evt.Agent_Id__c).add(evt);
      }
    }

    Agent_Log__c[] logs = [
      SELECT Agent_Id__c, Events__c
      FROM Agent_Log__c
      WHERE Agent_Id__c IN :eventsByAgentId.keySet()
    ];

    Map<String, Agent_Log__c> logsByAgentId = new Map<String, Agent_Log__c>();
    for (Agent_Log__c log : logs) {
      logsByAgentId.put(log.Agent_Id__c, log);
    }
    Agent_Log__c[] logsToUpsert = new List<Agent_Log__c>{};
    for (String agentId : eventsByAgentId.keySet()) {
      Agent_Log__c log = logsByAgentId.get(agentId);

      if (log == null) {
        log = new Agent_Log__c();
        log.Agent_Id__c = agentId;
      }
      AgentEventLog[] events = new List<AgentEventLog>{};

      if (log.Events__c != null) {
        try {
          events = (AgentEventLog[]) JSON.deserialize(
            log.Events__c,
            List<AgentEventLog>.class
          );
        } catch (Exception e) {
          System.debug('failed to deserialize events');
          System.debug(e);
        }
      }

      for (Agent_Event__e newEvent : eventsByAgentId.get(agentId)) {
        events.add(new AgentEventLog(newEvent));

        if (newEvent.Type__c == Agent.EventType.AGENT_CREATED.name()) {
          log.Input__c = newEvent.Data__c;
          log.Status__c = 'In Progress';
        } else if (newEvent.Type__c == Agent.EventType.AGENT_COMPLETED.name()) {
          log.Result__c = newEvent.Data__c;
          log.Status__c = 'Completed';
        } else if (newEvent.Type__c == Agent.EventType.AGENT_CRASH.name()) {
          log.Error__c = newEvent.Data__c;
          log.Status__c = 'Error';
        }
        log.Last_Agent_Update__c = newEvent.CreatedDate;
      }

      log.Events__c = JSON.serialize(events);

      logsToUpsert.add(log);
    }
    upsert logsToUpsert Agent_Id__c;
  }

  public class AgentEventLog {
    public string eventType;
    public string data;
    public DateTime timestamp;

    public AgentEventLog() {
    }
    public AgentEventLog(Agent_Event__e evt) {
      this.eventType = evt.Type__c;
      this.data = evt.Data__c;
      this.timestamp = evt.CreatedDate;
    }
  }
}
