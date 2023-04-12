import { api } from "lwc";
import LightningModal from "lightning/modal";
import CurrentUserId from "@salesforce/user/Id";
import { subscribe, unsubscribe } from "lightning/empApi";

// Apex methods
import getSingleRecord from "@salesforce/apex/AgentLogController.getSingleRecord";

export default class AgentLogDetails extends LightningModal {
  @api log;

  connectedCallback() {
    this.handleSubscribe();
  }

  disconnectedCallback() {
    this.handleUnsubscribe();
  }

  handleSubscribe() {
    const messageCallback = ({ data }) => {
      try {
        console.log("subscription data", JSON.parse(JSON.stringify(data)));

        // Only track agent logs of current user
        if (CurrentUserId !== data.payload.CreatedById) {
          return;
        }

        getSingleRecord({ id: data.payload.Agent_Log_Id__c })
          .then((log) => {
            this.log = log;
          })
          .catch((e) => {
            console.error("getSingleRecord error", e);
          });
      } catch (e) {
        console.error("subscription err", e);
      }
    };

    subscribe("/event/Agent_Log_Event__e", -1, messageCallback).then(
      (response) => {
        console.log(
          "Subscription request sent to: ",
          JSON.stringify(response.channel)
        );
        this.subscription = response;
      }
    );
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
