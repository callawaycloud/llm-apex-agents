import { LightningElement, track } from "lwc";
import { subscribe, unsubscribe } from "lightning/empApi";

// Apex methods
import runAgent from "@salesforce/apex/AgentLogController.runAgent";

export default class AgentChat extends LightningElement {
  @track currentAgentId;
  agentObjective;
  @track agentMessages = [];
  isRunning = false;

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
        this.isRunning = true;
      })
      .catch((e) => console.error(e));
  }

  clearCurrentAgent(event) {
    this.currentAgentId = null;
    this.agentObjective = null;
    this.agentMessages = [];
    this.isRunning = false;
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
            this.agentMessages.push({
              id: data.event.replayId,
              title: "Agent",
              text: agent.thoughts.text,
              icon: "standard:bot"
            });
            break;

          case "EXECUTE_ACTION":
            const action = JSON.parse(eventData);

            const args = Object.keys(action.args)
              .map((it) => `- ${it}: ${action.args[it]}`)
              .join("\n");

            this.agentMessages.push({
              id: data.event.replayId,
              title: "Running Action",
              text: `${action.actionClass}: \n ${args}`,
              icon: "standard:apex"
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
            this.isRunning = false;
            break;
          case "AGENT_CRASH":
            this.agentMessages.push({
              id: data.event.replayId,
              title: "Failed",
              text: eventData,
              icon: "standard:incident"
            });
            this.isRunning = false;
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
