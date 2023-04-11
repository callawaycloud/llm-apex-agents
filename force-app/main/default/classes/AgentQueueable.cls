// TOOD:
// - Refactor to use agent manager / queue
// - Refactor logging to be part of agent manager / queue
public class AgentQueueable implements Queueable, Database.AllowsCallouts {
  public static boolean FORCE_NEW_QUEUEABLE = false;

  private Agent.I agent;
  private Agent_Log__c log;
  public AgentQueueable(Agent.I agent) {
    this.agent = agent;
    this.log = new Agent_Log__c(
      Input__c = agent.getObjective(),
      Agent_Id__c = AgentUtils.createAgentId()
    );
  }

  public AgentQueueable(Agent.I agent, Agent_Log__c log) {
    this.agent = agent;
    this.log = log;
  }

  public void execute(QueueableContext context) {
    LoggingFinalizer logger = new LoggingFinalizer(this.log);
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
      logger.setLog(agent.getMessages());
    }

    if (agent.getResult() == null) {
      System.enqueueJob(new AgentQueueable(agent, logger.logRecord));
    } else {
      logger.setResult(agent.getResult());
    }
  }

  private class LoggingFinalizer implements Finalizer {
    // internal log buffer
    public Agent_Log__c logRecord;

    public LoggingFinalizer(Agent_Log__c log) {
      logRecord = log;
    }

    public void execute(FinalizerContext ctx) {
      // Commit the buffer
      System.Debug('committing log records to database');

      if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
        logRecord.Error__c =
          ctx.getException().getMessage() +
          '\n' +
          ctx.getException().getStackTraceString();
      }
      upsert logRecord Agent_Id__c;
    }

    public void setResult(string result) {
      logRecord.Result__c = result;
    }

    public void setLog(Object[] messages) {
      String log = '';
      if (messages instanceof ChatModel.Message[]) {
        for (ChatModel.Message message : (ChatModel.Message[]) messages) {
          log +=
            '===' +
            message.role?.toUpperCase() +
            '===\n' +
            message.content +
            '\n\n';
        }
      } else {
        for (Object message : messages) {
          log += JSON.serialize(message);
        }
      }
      logRecord.Log__c = log;
    }
  }
}
