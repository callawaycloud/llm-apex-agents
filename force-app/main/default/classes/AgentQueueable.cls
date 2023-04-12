// TOOD:
// - Refactor to use agent manager / queue
// - Refactor logging to be part of agent manager / queue
public class AgentQueueable implements Queueable, Database.AllowsCallouts {
  public static boolean FORCE_NEW_QUEUEABLE = false;

  private Agent.I agent;
  public AgentQueueable(Agent.I agent) {
    this.agent = agent;
  }

  public void execute(QueueableContext context) {
    LoggingFinalizer logger = new LoggingFinalizer(this.agent);
    System.attachFinalizer(logger);

    Long calloutMs = 0;

    // run mulitple time, so long as we have a generous capacity to do so
    while (
      Limits.getDmlRows() == 0 &&
      calloutMs < 60000 &&
      agent.getResult() == null &&
      FORCE_NEW_QUEUEABLE == false
    ) {
      System.debug('Running Agent Step');
      Long s = System.currentTimeMillis();
      agent.next();
      Long f = System.currentTimeMillis();
      calloutMs += (f - s);
    }

    if (agent.getResult() == null) {
      System.enqueueJob(new AgentQueueable(agent));
    }
  }

  /** Dump the Agent State so we can recover */
  private class LoggingFinalizer implements Finalizer {
    // internal log buffer
    public Agent.I agent;

    public LoggingFinalizer(Agent.I agent) {
      this.agent = agent;
    }

    /** Store the suspended state if:
     * - The queueable has failed
     * - The agent has completed
     */
    public void execute(FinalizerContext ctx) {
      // Commit the buffer
      System.Debug('committing log records to database');

      if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
        Agent_Log__c log = new Agent_Log__c(
          Agent_Id__c = agent.getId(),
          Error__c = ctx.getException().getMessage(),
          Suspension_State__c = JSON.serialize(agent.suspend())
        );
        upsert log Agent_Id__c;
      }

      if (agent.getResult() != null) {
        Agent_Log__c log = new Agent_Log__c(
          Agent_Id__c = agent.getId(),
          Suspension_State__c = JSON.serialize(agent.suspend())
        );
        upsert log Agent_Id__c;
      }
    }
  }
}
