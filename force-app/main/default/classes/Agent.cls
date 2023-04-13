public class Agent {
  public interface I {
    string getId();
    string getObjective();
    string getResult();
    void next();
    Object[] getMessages();
    string suspend();
    void hydrate(string state);
    void setEventHandler(EventHandler handler);
  }

  public interface EventHandler {
    void onEvent(string AgentId, EventType type, Object data);
  }

  public enum EventType {
    LOG_INIT,
    AGENT_CREATED,
    SENT,
    RECEIVED,
    EXECUTE_ACTION,
    ACTION_RESULT,
    ACTION_ERROR,
    INVALID_AGENT_RESPONSE,
    AGENT_COMPLETED,
    AGENT_CRASH
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

  public class ResponseException extends Exception {
  }

  public class FatalException extends Exception {
  }
}
