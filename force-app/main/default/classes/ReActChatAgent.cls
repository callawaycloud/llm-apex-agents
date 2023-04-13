public class ReActChatAgent implements Agent.I {
  //allows actions to return without generating a user response to agent
  public static string NO_RESPONSE = '___NO_RESPONSE';

  public Prompt.IReAct prompt;
  public ChatModel.I chatModel;
  public List<ChatModel.Message> thread;
  public ChatModel.Message nextUserMessage;
  public String objective;
  public String result;
  public Integer invocations;
  public Integer maxInvocations = 1000;
  public Agent.EventHandler onEvents;

  // TODO: reactor this to agent manager / stack
  public Agent.I spawnedAgent;
  public string Id;

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
    id = AgentUtils.createAgentId();

    this.thread = new List<ChatModel.Message>{
      new ChatModel.Message(
        'system',
        'You are an helpful assistent running in the Salesforce platform.  You have access to Commands to help you do your job. After running a command, you will recieve the output as a response.'
      )
    };
    this.nextUserMessage = new ChatModel.Message('user', instructions);
  }

  // Constructor for completion model
  public ReActChatAgent(
    String objective,
    Prompt.ICompletionReAct prompt,
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

  public string getId() {
    return id;
  }

  public void setEventHandler(Agent.EventHandler handler) {
    this.onEvents = handler;
  }

  public void hydrate(String state) {
    ChatAgentState stateObj = (ChatAgentState) JSON.deserialize(
      state,
      ChatAgentState.class
    );
    this.objective = stateObj.objective;
    this.result = stateObj.result;
    this.invocations = stateObj.invocations;
    this.thread = stateObj.thread;
    this.nextUserMessage = stateObj.nextUserMessage;
  }

  public String suspend() {
    ChatAgentState state = new ChatAgentState();
    state.objective = this.objective;
    state.result = this.result;
    state.invocations = this.invocations;
    state.thread = this.thread;
    state.nextUserMessage = this.nextUserMessage;
    return JSON.serialize(state);
  }

  public String getObjective() {
    return objective;
  }

  public String getResult() {
    return result;
  }

  private void sendEvent(Agent.EventType type, Object data) {
    if (onEvents != null) {
      onEvents.onEvent(this.id, type, data);
    }
  }

  /** Send the next message to the model and get a response */
  private string send() {
    if (this.nextUserMessage == null) {
      //Should we instead just ask it to continue with the next step?
      throw new Agent.FatalException('No message to send!');
    }

    try {
      ChatModel.Message[] reqMessages = new List<ChatModel.Message>(
        this.thread
      );
      reqMessages.add(this.nextUserMessage);

      sendEvent(Agent.EventType.SENT, this.nextUserMessage.content);
      String response = chatModel.chat(reqMessages);
      System.debug(response);
      sendEvent(Agent.EventType.RECEIVED, response);

      thread.add(this.nextUserMessage);
      this.nextUserMessage = null;
      thread.add(new ChatModel.Message('assistant', response));
      return response;
    } catch (Exception e) {
      throw e;
    }
  }

  /** Execute the action returned by the agents response.
   * If the response action is invalid, or the action execution fails, return an error message to the agent */
  private ChatModel.Message executeAction(Agent.Message agentResponse) {
    try {
      if (agentResponse.action.command == null) {
        String msg = 'No command found! Please provide a valid command or continue with the next step.';
        // sendEvent(Agent.EventType.INVALID_AGENT_RESPONSE, msg);
        return new ChatModel.Message('user', msg);
      }

      sendEvent(
        Agent.EventType.EXECUTE_ACTION,
        JSON.serializePretty(
          new Map<string, Object>{
            'actionClass' => String.valueOf(agentResponse.action.command)
              .split(':')[0],
            'args' => agentResponse.action.args
          }
        )
      );

      //excute the agents command
      String actionResult = agentResponse.action.command.execute(
        agentResponse.action.args
      );

      // sendEvent(Agent.EventType.ACTION_RESULT, actionResult);

      if (actionResult == NO_RESPONSE) {
        //special responses type
        return null;
      }

      return new ChatModel.Message(
        'user',
        prompt.formatActionResult(actionResult)
      );
    } catch (Exception e) {
      sendEvent(Agent.EventType.ACTION_ERROR, e.getMessage());
      return new ChatModel.Message(
        'user',
        'Failed to execute command: ' + e.getMessage()
      );
    }
  }

  public void next() {
    if (thread.size() == 1) {
      // only have system message
      sendEvent(Agent.EventType.AGENT_CREATED, this.objective);
    }

    /** Run Spawned agent to completion first */
    if (this.spawnedAgent != null) {
      if (this.spawnedAgent.getResult() == null) {
        spawnedAgent.next();
        return;
      }
      this.nextUserMessage = new ChatModel.Message(
        'user',
        spawnedAgent.getResult()
      );
      this.spawnedAgent = null;
      return;
    }

    if (invocations > maxInvocations) {
      // max iterations > current iterations
      //todo
      throw new Agent.FatalException('Exceeded max iterations!');
    }
    invocations++;

    if (this.result != null) {
      throw new Agent.FatalException('Agent has completed objective!');
    }

    string response = send();

    try {
      Agent.Message agentResponse = prompt.parseAgentMessage(response);

      /** Great Success! */
      if (agentResponse.result != null) {
        result = agentResponse.result;
        sendEvent(Agent.EventType.AGENT_COMPLETED, this.result);
        return;
      }

      this.nextUserMessage = executeAction(agentResponse);
    } catch (Agent.FatalException e) {
      throw e;
    } catch (Exception e) {
      // sendEvent(Agent.EventType.INVALID_AGENT_RESPONSE, e.getMessage());
      this.nextUserMessage = new ChatModel.Message(
        'user',
        'Your last response provided was invalid. ' + e.getMessage()
      );

      return;
    }
  }
  private class ChatAgentState {
    public String objective;
    public String result;
    public Integer invocations;
    public ChatModel.Message nextUserMessage;
    public List<ChatModel.Message> thread;
  }
}
