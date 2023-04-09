public class ReActChatAgent implements IAgent {
  public Prompt.IReAct config;
  public ChatModel.I chatModel;
  public List<ChatModel.Message> thread;
  public String objective;
  public String result;
  public Integer invocations;
  public Integer maxInvocations = 1000;

  // Constructor for completion model
  public ReActChatAgent(
    String objective,
    Prompt.ICompletionReAct config, // refactor to PromptManager
    CompletionModel.I completionModel
  ) {
    this(
      objective,
      config,
      new CompletionModelChatAdapter(completionModel, config.getStopSequence())
    );
  }

  public ReActChatAgent(
    String objective,
    Prompt.IReAct config, // refactor to PromptManager
    ChatModel.I chatModel
  ) {
    this.objective = objective;
    this.config = config;
    this.chatModel = chatModel;
    this.invocations = 0;
    String instructions = config.getInstructions(objective);
    System.debug(instructions);
    this.thread = new List<ChatModel.Message>{
      new ChatModel.Message('user', instructions)
    };
  }

  public String getResult() {
    return result;
  }

  public void next() {
    if (invocations > maxInvocations) {
      // max iterations > current iterations
      //todo
      throw new AgentException('Exceeded max iterations!');
    }
    invocations++;

    if (result != null) {
      throw new AgentException('Agent has completed objective!');
    }

    String response = chatModel.chat(thread);
    System.debug(response);

    thread.add(new ChatModel.Message('assistant', response));

    Agent.Message agentResponse = config.parseAgentMessage(response);

    if (agentResponse.result != null) {
      System.debug(result);
      result = agentResponse.result;
      return;
    }

    if (agentResponse.action.command == null) {
      System.debug('Invalid Reponse Format.  Please follow your instructions!');
      thread.add(
        new ChatModel.Message(
          'user',
          'Invalid Reponse Format.  Please follow your instructions!'
        )
      );
      return;
    }

    // Run Action
    try {
      String result = agentResponse.action.command.execute(
        agentResponse.action.args
      );
      System.debug(result);
      thread.add(
        new ChatModel.Message('user', config.formatActionResult(result))
      );
    } catch (Exception e) {
      System.debug(e.getMessage() + '\n\n' + e.getStackTraceString());
      thread.add(
        new ChatModel.Message(
          'user',
          'Failed to Execute Action: ' + e.getMessage()
        )
      );
      return;
    }
  }

  public class AgentException extends Exception {
  }
}

//** AgentConfig: Identity, tools, reasoning framework.  Shared by different AgentTypes */

