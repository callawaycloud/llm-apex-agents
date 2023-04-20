public class ReActZeroShotChatPrompt implements Prompt.IReAct {
  public Map<string, IAgentTool> tools;

  public ReActZeroShotChatPrompt(Map<string, IAgentTool> tools) {
    this.tools = tools;
  }

  private Map<String, Object> deserialize(String agentMessage) {
    if (!agentMessage.startsWith('{')) {
      Integer startIndex = agentMessage.indexOf('{');
      Integer endIndex = agentMessage.lastIndexOf('}');
      if (startIndex == -1 || endIndex == -1) {
        throw new Agent.ResponseException(
          'Your response must be JSON and match the provided format'
        );
      }
      agentMessage = agentMessage.substring(startIndex, endIndex + 1);
    }

    try {
      return (Map<String, Object>) JSON.deserializeUntyped(agentMessage);
    } catch (Exception e) {
      throw new Agent.ResponseException(
        'Your response must be JSON and match the provided format'
      );
    }
  }

  public Agent.Message parseAgentMessage(String agentMessage) {
    try {
      Agent.Message msg = new Agent.Message();

      Map<String, Object> agentResponse = deserialize(agentMessage);

      Object cmd = agentResponse.get('command');
      try {
        Map<string, Object> command = (Map<string, Object>) cmd;

        String commandName = (String) command?.get('name');

        if (commandName == 'completeAssignment') {
          Map<string, Object> answerArgs = (Map<string, Object>) command.get(
            'args'
          );
          Object answer = answerArgs.get('answer');
          if (answer instanceof String) {
            msg.result = (String) answer;
          } else {
            msg.result = JSON.serialize(answer);
          }
          return msg;
        }

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
      'Today is ' +
      Date.today().format() +
      '. ' +
      'You are assisting User ' +
      UserInfo.getFirstName() +
      ' ' +
      UserInfo.getLastName() +
      '(Id: ' +
      UserInfo.getUserId() +
      ', Email: ' +
      UserInfo.getUserEmail() +
      ').\n\n' +
      'Your Assignment: \n"""' +
      objective +
      '"""\n\n' +
      'COMMANDS:\n' +
      String.join(actionDescriptions.values(), '\n') +
      '\n`completeAssignment`: Run when the task is completed. Arguments: "answer": The answer or result of the assigned task. \n' +
      '\n\n' +
      'PERFORMANCE EVALUATION:\n' +
      'You must always provide a valid "command".  When the task is complete make sure to run `completeAssignment` \n' +
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
      '  }\n' +
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
