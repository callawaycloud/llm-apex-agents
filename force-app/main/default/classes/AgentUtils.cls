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
          '{1}: Command Key:"{0}".  Arguments: {2}',
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
}
