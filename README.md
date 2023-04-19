# llm-apex-agents

Run Large Language Model (GPT) agents in Salesforce apex.

<img width="1506" alt="Screen_Recording_2023-04-18_at_4_09_13_PM_mov" src="https://user-images.githubusercontent.com/5217568/232917551-a0e53a4a-65a7-4b8b-ad74-0f9860dce1cc.png">


## :shipit: What is an Agent?

An “Agent” is a technique for instilling the ability for an LLM to “Reason” and take “Action”. This approach is introduced by the [ReAct Paper](https://arxiv.org/pdf/2210.03629.pdf) (Reason → Act) and used in popular libraries like [langchain](https://github.com/hwchase17/langchain) and [auto-gpt](https://github.com/Torantulino/Auto-GPT).


## Library Terminology

- `Model`: LLM/GTP model. Currently only OpenAI GPT Completion & Chat models are supported.
- `Prompt`: The communication "protocol" between the model & system. Currently only ReAct style prompts are supported.
- `Agent`: A instance formed to solve a given objective.
- `Tools`: The commands at the agents disposal
- `Action`: The act of invoking a tool

## Getting Started

1. install in a scratch org (`force:source:push`) or to a developer edition (`force:mdapi:deploy`)

> **Warning**
> Scratch & developer orgs have a limit of 5 chained queueable jobs, which will limit how much work the agent can do.

2. Assign yourself to the `Apex Agent` permission set. `sfdx force:user:permset:assign -n Apex_Agents`

3. Open `Setup -> Named Credential -> External Credential -> OpenAI`.  Edit the "Permission Set Mapping" to add a "Authentication Parameters" with name of `API_KEY` and your OpenAI API Key as the value

4. (Optional) Open `Setup -> Custom Settings -> Apex Agent Settings	-> manage` and add your [SERP API key](https://serpapi.com/dashboard) & [ExtactorAPI key](https://extractorapi.com/).  This is required to enable the internet search capabilities. Both have free tiers.

5. Navigate to the "Apex Agents" app (from app launcher) and run a task.  Or start the agent using example code below.



### :exclamation: WARNING: THIS IS EXPERIMENTAL!

This library is not production ready and may never be:

- The API usage can be relatively expensive if you let it run wild. 
- The code itself is likely to undergo significant breaking changes.
- It is not yet optimized for performance and is not yet fully tested.
- Use at your own risk.

> **Warning**
> Salesforce seems to have a bug with `aborting` queueable jobs with long running HTTP callouts.  If you abort a job, it will still run to completion, and continue to schedule the following jobs!


### Example Code

```java
  OpenAIChatModel chatLLM = new OpenAIChatModel();

  // chatLLM.model = 'gpt-3.5-turbo';
  chatLLM.model = 'gpt-4';

  SerpAPIKey__c mc = SerpAPIKey__c.getInstance(UserInfo.getUserId());
  Map<String, IAgentTool> tools = new Map<String, IAgentTool>{
    'search_internet' => new InternetSearchAgentTool(mc.API_Key__c),
    'find_records' => new SOSLSearchAgentTool(),
    'send_notification' => new SentNotificationAgentTool(),
    'create_records' => new CreateRecordAgentTool(),
    'get_fields' => new GetSObjectFieldsAgentTool(),
    'list_custom_objects' => new ListSObjectAgentTool(),
    'execute_soql' => new RunSQLAgentTool()
  };
  ReActZeroShotChatPrompt prompt = new ReActZeroShotChatPrompt(tools);
  ReActChatAgent agent = new ReActChatAgent('Find 3 accounts with missing phone numbers and try to populate them from the internet', prompt, chatLLM);
  agent.maxInvocations = 15;

  AgentQueueable manager = new AgentQueueable(agent);
  manager.startAgent();
```

> **Note**
> For best results, it's recommended that you use `OpenAIChatModel` with `gpt-4` & `ReActZeroShotChatPromptManager` and only include the minimum number of tools you need.


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
- [x] Draft / Send Email
- [ ] Post to chatter
- [ ] merge records
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
- [x] Extract info from web page
- [ ] Calculate (wolfram alpha)
- [ ] [Stonks](https://github.com/public-apis/public-apis#finance)
- [ ] [Company lookup](https://api.orb-intelligence.com/docs/)
- [ ] [news](https://github.com/public-apis/public-apis#news)
- [ ] [link preview](LinkPreview) | [microlink](https://microlink.io/)

#### GPT tools
- [ ] Batch Summarize text
- [ ] Categorization
- [ ] Sentiment Analysis
- [ ] load/save Memory

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
    return new Map<string, string>({
      'name' => 'The name to greet'
    });
  }

  public string execute(Map<string, string> args) {
    if(String.isEmpty(args.get('name')){ 
       // throw an error with instructions so the agent can self correct
       throw new Agent.ActionRuntimeException('missing required parameter: name');
    }
    return 'hello ' + args.get('name');
  }
```

*Tips:* 
- You can return JSON or YAML using `JSON.serialize`
- Make your input as forgiving as possible and always return helpful error messages back if the input is invalid.

## Custom Prompts

You can write your own ReAct style prompts by implementing `Prompt.IReAct`.

## Logging

Currently there is some primitive logging place to an Object call `Agent_Log__c`.  Agent steps fire Agent_Event__e immediate platform events, which result in the log being updated in realtime.

## Other Planned Improvements:

- [ ] ask for permission to run actions
- [ ] suspend/reanimate agent
- [ ] Support for Few Shot prompts
- [ ] Support for long term memory
- [ ] add tests (have agent write them)
- [ ] use GPT-3.5 to reduce returned tokens to agent
    - `{thought/reasoning} {action_result}` 
- [x] refactor API tokens to use named credentials
- [x] improve observability (lwc dashboard)
- [x] LWC Chat Frontend (first pass)

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

## Contributing

The easiest way to contribute at this stage is to create new "AgentTools" (PR's welcome!) and experiment to see what this thing can do.

