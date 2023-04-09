public class AgentQueueable implements Queueable, Database.AllowsCallouts {
  private IAgent agent;
  public AgentQueueable(IAgent agent) {
    this.agent = agent;
  }

  public void execute(QueueableContext context) {
    System.debug('Running Agent Step');
    agent.next();

    if (agent.getResult() == null) {
      System.enqueueJob(new AgentQueueable(agent));
    }
  }
}
