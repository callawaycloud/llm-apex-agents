public class ReActChatAgent implements Agent.I {
  //allows actions to return without generating a user response to agent
  public static string NO_RESPONSE = '___NO_RESPONSE';

  public Prompt.IReAct prompt;
  public ChatModel.I chatModel;
  public List<ChatModel.Message> thread;
  public String objective;
  public String result;
  public Integer invocations;
  public Integer maxInvocations = 1000;

  // TODO: reactor this to agent manager / stack
  public Agent.I spawnedAgent;

  // Constructor for completion model
  public ReActChatAgent(
    String objective,
    Prompt.ICompletionReAct prompt, // refactor to PromptManager
    CompletionModel.I completionModel
  ) {
    this(
      objective,
      prompt,
      new CompletionModelChatAdapter(completionModel, prompt.getStopSequence())
    );
  }

  public List<ChatModel.Message> getMessages() {
    return thread;
  }

  public String getObjective() {
    return objective;
  }

  public ReActChatAgent(
    String objective,
    Prompt.IReAct config, // refactor to PromptManager
    ChatModel.I chatModel
  ) {
    this.objective = objective;
    this.prompt = config;
    this.chatModel = chatModel;
    this.invocations = 0;
    String instructions = config.getInstructions(objective);
    System.debug(instructions);
    this.thread = new List<ChatModel.Message>{
      new ChatModel.Message(
        'system',
        'You are an helpful assistent running in the Salesforce platform.  You have access to Commands to help you do your job. After running a command, you will recieve the output as a response.'
      ),
      new ChatModel.Message('user', instructions)
    };
  }

  public String getResult() {
    return result;
  }

  public void next() {
    /** Run Spawned agent to completion first */
    if (this.spawnedAgent != null) {
      if (this.spawnedAgent.getResult() == null) {
        spawnedAgent.next();
        return;
      }

      thread.add(new ChatModel.Message('user', spawnedAgent.getResult()));
      this.spawnedAgent = null;
      return;
    }

    if (invocations > maxInvocations) {
      // max iterations > current iterations
      //todo
      throw new AgentException('Exceeded max iterations!');
    }
    invocations++;

    if (this.result != null) {
      throw new AgentException('Agent has completed objective!');
    }

    String response = chatModel.chat(thread);
    System.debug(response);

    thread.add(new ChatModel.Message('assistant', response));

    try {
      Agent.Message agentResponse = prompt.parseAgentMessage(response);

      if (agentResponse.result != null) {
        result = agentResponse.result;
        return;
      }

      if (agentResponse.action.command == null) {
        String msg = 'No command found! Please provide a valid command or continue with the next step.';
        thread.add(new ChatModel.Message('user', msg));
        System.debug(msg);
        return;
      }

      // Run Action
      try {
        String actionResult = agentResponse.action.command.execute(
          agentResponse.action.args
        );
        System.debug(actionResult);
        if (actionResult != NO_RESPONSE) {
          thread.add(
            new ChatModel.Message(
              'user',
              prompt.formatActionResult(actionResult)
            )
          );
        }
      } catch (Exception e) {
        System.debug(e.getMessage() + '\n\n' + e.getStackTraceString());
        thread.add(
          new ChatModel.Message(
            'user',
            'Failed to execute command: ' + e.getMessage()
          )
        );
        return;
      }
    } catch (Exception e) {
      System.debug(e.getMessage() + '\n\n' + e.getStackTraceString());
      thread.add(
        new ChatModel.Message(
          'user',
          'The response you provided is invalid' + e.getMessage()
        )
      );
      return;
    }
  }

  public class AgentException extends Exception {
  }
}

//** AgentConfig: Identity, tools, reasoning framework.  Shared by different AgentTypes */

