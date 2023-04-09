public class Agent {
  public interface I {
    string getResult();
    void next();
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
