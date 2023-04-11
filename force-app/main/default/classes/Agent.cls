public class Agent {
  public interface I {
    string getObjective();
    string getResult();
    void next();
    Object[] getMessages();
  }

  public class Message {
    public Message() {
      this.action = new NextAgentAction();
    }
    public String result;
    public NextAgentAction action;
  }

  public class NextAgentAction {
    public IAgentTool command;
    public Map<String, String> args;
  }
}
