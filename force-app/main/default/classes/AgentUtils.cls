public class AgentUtils {
  public static Map<String, String> getActionDescriptions(
    Map<String, IAgentTool> actions
  ) {
    Map<String, String> toolDescriptions = new Map<String, String>();
    for (String actionKey : actions.keySet()) {
      IAgentTool action = actions.get(actionKey);
      /** Start GPT Agent: "start_agent", args: "name": "<name>", "task": "<short_task_desc>", "prompt": "<prompt>" */
      String[] args = new List<String>{};
      for (string key : action.getParameters().keySet()) {
        args.add(
          '"' + key + '": ' + '<' + action.getParameters().get(key) + '>'
        );
      }

      toolDescriptions.put(
        actionKey,
        String.format(
          '`{0}`: {1}. Arguments: {2}',
          new List<Object>{
            actionKey,
            action.getDescription(),
            String.join(args, ',')
          }
        )
      );
    }
    return toolDescriptions;
  }

  public static string createAgentId() {
    Blob b = Crypto.GenerateAESKey(128);
    String h = EncodingUtil.ConvertTohex(b);
    String guid =
      h.SubString(0, 8) +
      '-' +
      h.SubString(8, 12) +
      '-' +
      h.SubString(12, 16) +
      '-' +
      h.SubString(16, 20) +
      '-' +
      h.substring(20);
    return guid;
  }
}
