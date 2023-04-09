# llm-apex-agents

Run Large Language Model agents in Salesforce apex

## What is an Agent

An “Agent” is a technique for instilling the ability for an LLM to “Reason” and take “Action”. This approach is introduced by the [ReAct Paper](https://arxiv.org/pdf/2210.03629.pdf) (Reason → Act) and used in popular libraries like [langchain](https://github.com/hwchase17/langchain) and [auto-gpt](https://github.com/Torantulino/Auto-GPT).

## Library Terminology

- `Model`: LLM/GTP model. Currently only OpenAI GPT Completion & Chat models are supported.
- `Prompt`: The communication "protocal" between the model & system. Currently only ReAct style prompts are supported.
- `Agent`: A instance formed to solve a given objective.
- `Tools`: The commands at the agents disposal
- `Action`: The act of invoking a tool

## WARNING: THIS IS EXPERIMENTAL!

This library is not production ready and may never be:

- The API usage can be relatively expensive if you let it run wild.
- The code itself is likely to undergo significant breaking changes.
- It is not yet optimized for performance and is not yet fully tested.
- Use at your own risk.

## Getting Started

> Run in scratch org or install to developer edition using `sfdx force:mdapi:deploy`

Library comes out of the box with some useful agents and actions.

It's recommended that you use `OpenAIChatModel` & `ReActZeroShotChatPromptManager` and only include the minimum number of tools you need.

### Example

```java
OpenAIChatModel chatLLM = new OpenAIChatModel(
  'YOUR_OPEN_AI_KEY'
);

// setup tools
Map<String, IAgentTool> tools = new Map<String, IAgentTool>{
  'search' => new InternetSearchAgentAction(
    'YOUR_SERP_API_KEY'
  ),
  'find_records' => new SOSLSearchAgentTool(),
  'send_notification' => new SentNotificationAgentTool('0MLDa0000000EMDOA2'),
  'get_fields' => new GetSObjectFieldsAgentTool()
};

// add prompt
ReActZeroShotChatPromptManager prompt = new ReActZeroShotChatPromptManager(
  tools
);

// construct agent
ReActChatAgent agent = new ReActChatAgent(
  'list all the picklist fields on the account object',
  prompt,
  chatLLM
);
agent.maxInvocations = 10;

// run agent.  Also see AgentQueueable
while (agent.getResult() == null) {
  agent.next();
}P
```

## :hammer_and_wrench: Tools

- [x] Internet Search
- [x] Search for records
- [x] Send Custom Notification
- [x] Get SObject Fields
- [ ] List SObjects
- [ ] Draft / Send Email
- [ ] Insert Record
- [ ] Update Record
- [ ] Calculate
- [ ] Approve / Reject Record
- [ ] Launch flow
- [ ] Write/Run SOQL query
- [ ] Read Apex Class
- [ ] Run Tests
- [ ] Run Apex?!
- [ ] create & run other agents
- [ ] ???

### Custom Tools

Creating a custom tool is easy. Just create a class that implements the IAgentTool interface and add it to the map of tools when you create the prompt.

```java
public class GreetingAgentTool implements IAgentTool {
  public string getDescription() {
    return 'Get a greeting';
  }

  public Map<string, string> getParameters() {
    Map<string, string> params = new Map<string, string>();
    params.put('name', 'The name to greet');
    return params;
  }

  public string execute(Map<string, string> args) {
    return 'hello ' + args.get('name');
  }
```

## Custom Prompts

You can write your own ReAct style prompts by implementing `Prompt.IReAct`.

## Contributing

The easiest way to contribute at this stage is to create new "AgentTools" (PR's welcome!) and experiment to see what this thing can do.

Other housekeeping:

- [ ] refactor API tokens to use named credentials
- [ ] Add more documentation
- [ ] improve observability
- [ ] LWC Chat Frontend?
- [ ] add tests
