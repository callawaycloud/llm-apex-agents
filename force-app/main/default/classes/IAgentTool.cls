public interface IAgentTool {
  String execute(Map<string, string> args);
  string getDescription();
  Map<string, string> getParameters(); // TODO consider using a class for Parameter
}
