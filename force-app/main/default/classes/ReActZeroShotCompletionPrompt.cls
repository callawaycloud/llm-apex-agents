public class ReActZeroShotCompletionPrompt implements Prompt.ICompletionReAct {
  public Map<string, IAgentTool> tools;

  public ReActZeroShotCompletionPrompt(Map<string, IAgentTool> tools) {
    this.tools = tools;
  }

  public Agent.Message parseAgentMessage(String agentMessage) {
    Agent.Message msg = new Agent.Message();

    String[] lines = agentMessage.split('\n');

    String action = null;
    Map<String, String> actionInput;
    string result = null;
    for (String line : lines) {
      if (line.startsWith('Action:')) {
        action = line.replace('Action:', '').trim();
      }
      if (line.startsWith('Action Input:')) {
        actionInput = (Map<String, String>) JSON.deserialize(
          line.replace('Action Input:', '').trim(),
          Map<String, String>.class
        );
      }
      if (line.startsWith('Final Answer:')) {
        result = line.replace('Final Answer:', '').trim();
      }
    }

    //Check if done
    if (result != null) {
      msg.result = result;
    }

    // Parse Action
    msg.action.command = tools.get(action);
    msg.action.args = actionInput;
    System.debug(actionInput);
    return msg;
  }

  public String formatActionResult(String result) {
    return 'Observation: ' + result;
  }

  public String getInstructions(String objective) {
    Map<String, String> toolDescriptions = AgentUtils.getActionDescriptions(
      this.tools
    );

    return 'Answer the following questions as best you can. You have access to the following tools: \n' +
      String.join(toolDescriptions.values(), '\n') +
      '\n\nUse the following format: \n' +
      'Question: the input question you must answer \n' +
      'Thought: you should always think about what to do. Plan out the remaining steps careful detail \n' +
      'Action: the next action to take, should be one of [' +
      String.join(new List<String>(toolDescriptions.keySet()), ',') +
      '] \n' +
      'Action Input: {"arg1":"value1", "arg2":"value2"} \n' +
      'Observation: an observation of the result \n' +
      '... (this Thought/Action/Action Input/Observation can repeat N times) \n' +
      'Thought: I now know the final answer \n' +
      'Final Answer: the final answer to the original input question \n' +
      'Begin! \n\n' +
      'Question: \n """' +
      objective +
      '"""\n';
  }

  public String[] getStopSequence() {
    return new List<String>{ 'Observation:' };
  }
}
