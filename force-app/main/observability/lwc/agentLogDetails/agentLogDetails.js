import { api, track } from "lwc";
import LightningModal from "lightning/modal";
import CurrentUserId from "@salesforce/user/Id";
import { subscribe, unsubscribe } from "lightning/empApi";

// Apex methods
import getSingleRecord from "@salesforce/apex/AgentLogController.getSingleRecord";

export default class AgentLogDetails extends LightningModal {
  @api log;
  eventLog = [];

  connectedCallback() {
    this.handleSubscribe();
    this.parseEventLog();
  }

  disconnectedCallback() {
    this.handleUnsubscribe();
  }

  parseEventLog() {
    if (!this.log.Events__c) {
      return;
    }

    this.eventLog = JSON.parse(this.log.Events__c)
      .map((it) => ({
        ...it,
        data: JSON.parse(it.data),
        ...getEventExtraProps(it)
      }))
      .reverse();
  }

  handleSubscribe() {
    const messageCallback = ({ data }) => {
      try {
        console.log("subscription data", JSON.parse(JSON.stringify(data)));

        // Only track agent logs of current user
        if (CurrentUserId !== data.payload.CreatedById) {
          return;
        }

        getSingleRecord({ agentId: data.payload.Agent_Id__c })
          .then((result) => {
            this.log = result;
            this.parseEventLog();
          })
          .catch((e) => {
            console.error("getSingleRecord error", e);
          });
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

  handleClose() {
    this.close("tests");
  }
}

function getEventExtraProps(evt) {
  return (() => {
    switch (evt.eventType) {
      case "AGENT_COMPLETED":
        return {
          icon: "standard:answer_public"
        };
      case "RECEIVED":
        return {
          icon: "standard:product_consumed"
        };
      case "SENT":
        return {
          icon: "standard:logging"
        };
      case "EXECUTE_ACTION":
        return {
          icon: "standard:apex"
        };
      case "AGENT_CREATED":
        return {
          icon: "standard:messaging_user"
        };
      default:
        return {
          icon: ""
        };
    }
  })();
}
