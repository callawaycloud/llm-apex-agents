public class ReActZeroShotChatPromptManager implements Prompt.IReAct {
  public Map<string, IAgentTool> tools;

  public ReActZeroShotChatPromptManager(Map<string, IAgentTool> tools) {
    this.tools = tools;
  }

  public Agent.Message parseAgentMessage(String agentMessage) {
    Agent.Message msg = new Agent.Message();
    AgentResponse agentResponse = (AgentResponse) JSON.deserialize(
      agentMessage,
      AgentResponse.class
    );

    //Check if done
    if (agentResponse.result != null) {
      msg.result = agentResponse.result;
    }

    // Parse Action
    msg.action.command = tools.get(agentResponse.command.name);
    msg.action.args = agentResponse.command.args;
    return msg;
  }

  public String formatActionResult(String result) {
    return result;
  }

  public String getInstructions(String objective) {
    Map<String, String> actionDescriptions = AgentUtils.getActionDescriptions(
      this.tools
    );

    String prompt =
      'Your Objective: """' +
      objective +
      '"""\n\n' +
      'COMMANDS:\n' +
      String.join(actionDescriptions.values(), '\n') +
      '\n\n' +
      'PERFORMANCE EVALUATION:' +
      '\n' +
      'Continuously review and analyze your actions to ensure you are performing to the best of your abilities.' +
      '\n' +
      'Constructively self-criticize your big-picture behavior constantly.' +
      '\n' +
      'Reflect on past decisions and strategies to refine your approach.' +
      '\n' +
      'Every command has a cost, so be smart and efficient. Aim to complete tasks in the least number of steps.' +
      '\n' +
      'Set the result as soon as you have enough information to do so.  Remeber you are a powerful and capable GPT model!' +
      '\n' +
      'You should only respond in JSON format as described below' +
      '\n\n' +
      'RESPONSE FORMAT:' +
      '\n' +
      '{' +
      '\n' +
      '  "thoughts":' +
      '\n' +
      '  {' +
      '\n' +
      '    "text": "thought",' +
      '\n' +
      '    "reasoning": "reasoning",' +
      '\n' +
      '    "plan": "- short bulleted\\n- list that conveys\\n- long-term plan",' +
      '\n' +
      '    "criticism": "constructive self-criticism"' +
      '\n' +
      '  },' +
      '\n' +
      '  "command": {' +
      '\n' +
      '    "name": "command name",' +
      '\n' +
      '    "args":{' +
      '\n' +
      '      "arg name": "value"' +
      '\n' +
      '    }\n' +
      '  },\n' +
      '  "result": "The answer to the original query.  Null if still work in progress" \n' +
      '}';

    return prompt;
  }

  public class AgentResponse {
    public ActionCommand command;
    public String result;
  }

  public class ActionCommand {
    public String name;
    public Map<String, String> args;
  }
}
