// TOOD: Refactor to use agent manager / queue
public class SpawnAgentTool implements IAgentTool {
  private ChatModel.I chatModel;
  private Map<String, IAgentTool> tools;

  //TODO: Refactor how this works so it can be constructed
  public ReActChatAgent parentAgent;

  public String toolDescription;
  public Map<String, String> toolParameters;

  public SpawnAgentTool(
    string toolDescription,
    Map<String, String> toolParameters,
    ChatModel.I chatModel,
    Map<String, IAgentTool> tools
  ) {
    this.toolDescription = toolDescription;
    this.chatModel = chatModel;
    this.tools = tools;
    this.toolParameters = toolParameters;
  }

  public String execute(Map<String, String> args) {
    ReActZeroShotChatPrompt prompt = new ReActZeroShotChatPrompt(tools);
    String objective =
      'Your job is to ' +
      this.toolDescription +
      '.  Here are the parameters of the task: \n' +
      formatInputParameters(args);
    ReActChatAgent agent = new ReActChatAgent(objective, prompt, chatModel);
    this.parentAgent.spawnedAgent = agent;
    return ReActChatAgent.NO_RESPONSE;
  }

  public String getDescription() {
    return this.toolDescription;
  }

  public Map<String, String> getParameters() {
    return toolParameters;
  }

  private string formatInputParameters(Map<string, String> input) {
    String[] inputDescriptions = new List<String>{};
    for (String argKey : input.keySet()) {
      String argDescription = toolParameters.get(argKey);

      inputDescriptions.add(argDescription + ': ' + input.get(argKey));
    }
    return String.join(inputDescriptions, '\n');
  }
}
