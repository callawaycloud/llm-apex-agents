public class Prompt {
  public interface IReAct {
    String getInstructions(String objective);
    Agent.Message parseAgentMessage(String message);
    String formatActionResult(String result);
  }

  public interface ICompletionReAct extends IReAct {
    String[] getStopSequence();
  }
}
