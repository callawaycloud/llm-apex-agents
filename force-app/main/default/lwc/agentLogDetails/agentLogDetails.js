import { api } from "lwc";
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

    this.eventLog = JSON.parse(this.log.Events__c).map((it) => ({
      ...it,
      data: JSON.parse(it.data)
    }));
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

  get displayDataTable() {
    return this.logs && this.isTableVisible;
  }

  handleClose() {
    this.close("tests");
  }
}
