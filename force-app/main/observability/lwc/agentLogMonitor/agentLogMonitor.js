import { LightningElement, track } from "lwc";
import CurrentUserId from "@salesforce/user/Id";
import { subscribe, unsubscribe } from "lightning/empApi";

// LWCs
import LogDetailsModal from "c/agentLogDetails";

// Apex methods
import getAgentLogRecords from "@salesforce/apex/AgentLogController.getAgentLogRecords";
import getSingleRecord from "@salesforce/apex/AgentLogController.getSingleRecord";

// Datatable
const actions = [{ label: "View", name: "view" }];

const columns = [
  { label: "Input", fieldName: "Input__c" },
  {
    label: "Last Updated",
    fieldName: "Last_Agent_Update__c",
    type: "date",
    typeAttributes: {
      month: "2-digit",
      day: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit"
    }
  },
  {
    type: "action",
    typeAttributes: { rowActions: actions }
  }
];

export default class AgentLogSubscriber extends LightningElement {
  @track logs = [];
  columns = columns;
  subscription = {};

  connectedCallback() {
    this.handleSubscribe();

    getAgentLogRecords()
      .then((agentLogs) => {
        this.logs = agentLogs;
      })
      .catch((e) => console.error(e));
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
            const existingLogIndex = this.logs.findIndex(
              (element) => element.Id === log.Id
            );

            if (existingLogIndex !== -1) {
              this.logs[existingLogIndex] = log;
            } else {
              this.logs.push(log);
            }

            this.logs.sort(
              (a, b) =>
                new Date(b.Last_Agent_Update__c || 0) -
                new Date(a.Last_Agent_Update__c || 0)
            );

            // LWC data binding doesn't detect a call to push.
            // Basically kicking it to refresh right here.
            // Keeping the cap at 10 agent logs here so it works out.
            this.logs = this.logs.slice(0, 10);
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

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    switch (actionName) {
      case "view":
        this.viewLogDetails(row);
        break;
      default:
    }
  }

  async viewLogDetails(log) {
    const result = await LogDetailsModal.open({
      size: "medium",
      description: "Accessible description of modal's purpose",
      log: log
    });
    // if modal closed with X button, promise returns result = 'undefined'
    // if modal closed with OK button, promise returns result = [data]
    console.log("modal response", result);
  }
}
