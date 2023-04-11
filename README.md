# llm-apex-agents

Run Large Language Model (GPT) agents in Salesforce apex.

## :shipit: What is an Agent?

An “Agent” is a technique for instilling the ability for an LLM to “Reason” and take “Action”. This approach is introduced by the [ReAct Paper](https://arxiv.org/pdf/2210.03629.pdf) (Reason → Act) and used in popular libraries like [langchain](https://github.com/hwchase17/langchain) and [auto-gpt](https://github.com/Torantulino/Auto-GPT).

## Library Terminology

- `Model`: LLM/GTP model. Currently only OpenAI GPT Completion & Chat models are supported.
- `Prompt`: The communication "protocal" between the model & system. Currently only ReAct style prompts are supported.
- `Agent`: A instance formed to solve a given objective.
- `Tools`: The commands at the agents disposal
- `Action`: The act of invoking a tool

## Getting Started

> Run in scratch org or install to developer edition using `sfdx force:mdapi:deploy`

### :exclamation: WARNING: THIS IS EXPERIMENTAL!

This library is not production ready and may never be:

- The API usage can be relatively expensive if you let it run wild.
- The code itself is likely to undergo significant breaking changes.
- It is not yet optimized for performance and is not yet fully tested.
- Use at your own risk.

Library comes out of the box with some useful agents and actions.

For best results, it's recommended that you use `OpenAIChatModel` with `gpt-4` & `ReActZeroShotChatPromptManager` and only include the minimum number of tools you need.

### Example

```java
OpenAIChatModel chatLLM = new OpenAIChatModel(
  'YOUR_OPEN_AI_KEY'
);

// setup tools
Map<String, IAgentTool> tools = new Map<String, IAgentTool>{
  'search' => new InternetSearchAgentTool(
    'YOUR_SERP_API_KEY'
  ),
  'find_records' => new SOSLSearchAgentTool(),
  'send_notification' => new SentNotificationAgentTool('0MLDa0000000EMDOA2'),
  'get_fields' => new GetSObjectFieldsAgentTool(),
  'create_records' => new CreateRecordAgentTool(),
  'get_fields' => new GetSObjectFieldsAgentTool(),
  'list_custom_objects' => new ListSObjectAgentTool(),
  'execute_soql' => new RunSQLAgentTool(),
  'get_current_user' => new GetCurrentUserAgentTool()
};

// add prompt
ReActZeroShotChatPrompt prompt = new ReActZeroShotChatPrompt(
  tools
);

// construct agent
ReActChatAgent agent = new ReActChatAgent(
  'See if you can fill in any missing information on the amazon account. Send me a notification with the summary',
  prompt,
  chatLLM
);
agent.maxInvocations = 15;

AgentQueueable queuable = new AgentQueueable(agent);
System.enqueueJob(queuable);
}
```

**Tested Prompts:**

- :white_check_mark: `Search for accounts containing the word "sample" and send a notification to the user with name = "charlie jonas", notifying them that they should remove the account.`
- :white_check_mark: `write a SOQL query that returns all billing related fields for an account. Send me a notification with the results of the query`
- :white_check_mark: `Get the weather tomorrow in Lander, wyoming.  Send a notification to Charlie Jonas letting him know how to dress`
- :white_check_mark: `Research 3 companies that offer leading edge solutions for building API.  Insert the new account with basic information about the business, but only if the account does not already exist.`
- :white_check_mark: `Find out how many employees work at amazon and update the account`
- :white_check_mark: `query 3 accounts that do not have Number of Employees set.  Update the account with the number of employees from the internet.`
- :white_check_mark: `See if you can fill in any missing information on the amazon account. Send me a notification with the summary`
- :white_check_mark: `Search for accounts containing the word "sample". Create a task assigned to me with the subject "Remove Sample Account`
- :white_check_mark: `write a SOQL query to group invoice total by project name.  Send me the results in a notification`


## :hammer_and_wrench: Tools

#### Native SF Tools

- [x] Search for records
- [x] Send Custom Notification
- [x] Get SObject Fields
- [x] List SObjects
- [x] Write SOQL query
- [x] Execute SOQL query
- [x] Insert Record
- [x] Update Record
- [x] Get current user
- [ ] Draft / Send Email
- [ ] Post to chatter
- [ ] create file/attachment
- [ ] Search KB
- [ ] create platform event
- [ ] Approvals?
- [ ] Launch flow
- [ ] Delete flows :trollface:
- [ ] Read Apex Class
- [ ] Write Apex class
- [ ] Run Apex :trollface:
- [ ] Run Tests

#### Internet/API tools

- [x] Internet Search (limited)
- [ ] Calculate

#### GPT tools
- [ ] Summarize text
- [ ] Categorization
- [ ] Sentiment Analysis

#### Other
- [ ] User feedback
- [x] create & run other agents (limited)
- [ ] ???


### Writing Custom Tools

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

*Tips:* 
- You can return JSON or YAML using `JSON.serialize`
- Make your input as forgiving as possible and return helpful error messages back if the input is invalid.

## Custom Prompts

You can write your own ReAct style prompts by implementing `Prompt.IReAct`.

## Logging

Currently there is some primitive logging place to an Object call `Agent_Log__c`.  


## Contributing

The easiest way to contribute at this stage is to create new "AgentTools" (PR's welcome!) and experiment to see what this thing can do.

Other improvements:

- [ ] refactor API tokens to use named credentials
- [ ] improve observability (lwc component?)
- [ ] suspend/reanimate agent
- [ ] LWC Chat Frontend
- [ ] Support for Few Shot prompts
- [ ] Support for long term memory
- [ ] add tests (have agent write them)
- [ ] use GPT-3.5 to reduce returned tokens to agent
    - `{thought/reasoning} {action_result}` 