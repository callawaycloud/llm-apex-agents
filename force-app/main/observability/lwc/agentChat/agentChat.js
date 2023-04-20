import { LightningElement, track } from "lwc";
import { subscribe, unsubscribe } from "lightning/empApi";

// Apex methods
import runAgent from "@salesforce/apex/AgentLogController.runAgent";

export default class AgentChat extends LightningElement {
  @track currentAgentId;
  agentObjective;
  @track agentMessages = [];

  connectedCallback() {
    this.handleSubscribe();
  }

  disconnectedCallback() {
    this.handleUnsubscribe();
  }

  handleClick(event) {
    const element = this.template.querySelector("lightning-textarea");
    this.agentObjective = element.value;

    runAgent({ objective: element.value })
      .then((response) => {
        this.currentAgentId = response;
      })
      .catch((e) => console.error(e));
  }

  clearCurrentAgent(event) {
    this.currentAgentId = null;
    this.agentObjective = null;
    this.agentMessages = [];
  }

  handleSubscribe() {
    const messageCallback = ({ data }) => {
      try {
        console.log("subscription data", JSON.parse(JSON.stringify(data)));

        // // Only track agent logs of current user
        if (this.currentAgentId !== data.payload.Agent_Id__c) {
          return;
        }

        const eventData = JSON.parse(data.payload.Data__c);
        switch (data.payload.Type__c) {
          case "RECEIVED":
            const agent = JSON.parse(eventData);
            const lastMessage =
              this.agentMessages[this.agentMessages.length - 1];
            if (lastMessage && lastMessage.title === "Agent") {
              lastMessage.id = data.event.replayId;
              lastMessage.text = agent.thoughts.text;
            }
            this.agentMessages = [...this.agentMessages];
            break;

          case "EXECUTE_ACTION":
            const action = JSON.parse(eventData);

            const args = action.args
              ? Object.keys(action.args)
                  .map((it) => `- ${it}: ${action.args[it]}`)
                  .join("\n")
              : "";

            this.agentMessages.push({
              id: data.event.replayId,
              title: "Running Action",
              text: `${action.actionClass}: \n ${args}`,
              icon: "standard:apex"
            });
            break;
          case "ACTION_ERROR":
            this.agentMessages.push({
              id: data.event.replayId,
              title: "Action Error",
              text: eventData,
              icon: "standard:process_exception"
            });
            break;
          case "AGENT_COMPLETED":
            console.log("Agent Complete: ", eventData);
            this.agentMessages.push({
              id: data.event.replayId,
              title: "Complete",
              text: eventData,
              icon: "standard:task2"
            });
            break;
          case "SENT":
            this.agentMessages.push({
              id: data.event.replayId,
              title: "Agent",
              text: "thinking...",
              icon: "standard:bot"
            });
            break;
          case "AGENT_CRASH":
            this.agentMessages.push({
              id: data.event.replayId,
              title: "Failed",
              text: eventData,
              icon: "standard:incident"
            });
            break;
        }
      } catch (e) {
        console.error("subscription err", e);
      }
    };

    subscribe("/event/Agent_Event__e", -1, messageCallback).then((response) => {
      console.log(
        "Subscription request sent to: ",
        JSON.stringify(response.channel)
      );
      this.subscription = response;
    });
  }

  handleUnsubscribe() {
    unsubscribe(this.subscription, (response) => {
      console.log("Unsubscribed from channel:", response.subscription);
    });
  }
}
