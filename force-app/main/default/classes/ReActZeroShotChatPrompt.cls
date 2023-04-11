public class ReActZeroShotChatPrompt implements Prompt.IReAct {
  public Map<string, IAgentTool> tools;

  public ReActZeroShotChatPrompt(Map<string, IAgentTool> tools) {
    this.tools = tools;
  }

  public Agent.Message parseAgentMessage(String agentMessage) {
    try {
      Agent.Message msg = new Agent.Message();

      Map<String, Object> agentResponse = (Map<String, Object>) JSON.deserializeUntyped(
        agentMessage
      );

      Object complete = agentResponse.get('complete');
      Object result = agentResponse.get('result');

      //Check if done
      if (
        complete instanceof Boolean &&
        (Boolean) complete == true &&
        result != null
      ) {
        if (result instanceof String) {
          msg.result = (String) result;
        } else {
          msg.result = JSON.serialize(result);
        }
      }

      Object cmd = agentResponse.get('command');
      try {
        Map<string, Object> command = (Map<string, Object>) cmd;

        String commandName = (String) command?.get('name');
        msg.action.command = tools.get(commandName);

        if (msg.action.command != null && command?.get('args') != null) {
          Map<string, Object> argsUntyped = (Map<string, Object>) command.get(
            'args'
          );

          Map<string, string> args = new Map<string, string>();
          for (String key : argsUntyped.keySet()) {
            args.put(key, (String) argsUntyped.get(key));
          }

          // Parse Action

          msg.action.args = args;
        }
      } catch (Exception e) {
        System.debug('Failed to parse command: \n' + JSON.serialize(cmd));
      }
      return msg;
    } catch (Exception e) {
      System.debug('Failed to parse agent response: ' + e.getMessage());
      System.debug(agentMessage);
      throw e;
    }
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
      'PERFORMANCE EVALUATION:\n' +
      'You must always provide a valid "command".  When you are done, use the final command "exit" \n' +
      'When you can complete the next step on you own, do so immediately.  Use commands for things you cannot perform yourself.\n' +
      'Continuously review and analyze your actions to ensure you are performing to the best of your abilities.\n' +
      'Reflect on past decisions and strategies to refine your approach.\n' +
      'Every command has a cost, so be smart and efficient. Aim to complete tasks in the least number of steps.\n' +
      'Wait for a response from all commands before setting "complete": true.\n' +
      'You should only respond in JSON format as described below.\n' +
      'RESPONSE FORMAT:\n' +
      '{\n' +
      '  "thoughts":\n' +
      '  {\n' +
      '    "text": "thought",\n' +
      '    "reasoning": "reasoning",\n' +
      '    "plan": "- short bulleted\\n- list that conveys\\n- long-term plan"\n' +
      '  },\n' +
      '  "internal_processing": "Result of any work you should do before running the next command",\n' +
      '  "command": {\n' +
      '    "name": "command name",\n' +
      '    "args":{\n' +
      '      "arg name": "value"\n' +
      '    }\n' +
      '  },\n' +
      '  "complete": "`true` when the objective has been met", \n' +
      '  "result": "The final answer to the objective" \n' +
      '}';

    return prompt;
  }

  public class AgentResponse {
    public ActionCommand command;
    public Object result;
  }

  public class ActionCommand {
    public String name;
    public Map<String, String> args;
  }
}
