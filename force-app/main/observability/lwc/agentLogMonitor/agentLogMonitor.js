// agentLogSubscriber.js
import { LightningElement, track } from "lwc";
import {
  subscribe,
  unsubscribe,
  onError,
  setDebugFlag,
  isEmpEnabled
} from "lightning/empApi";
import getAgentLogRecords from "@salesforce/apex/AgentLogController.getAgentLogRecords";
import getSingleRecord from "@salesforce/apex/AgentLogController.getSingleRecord";

export default class AgentLogSubscriber extends LightningElement {
  @track logs = [];
  @track selectedLog;
  scrollLock = true;
  subscription = {};

  // Initialize the component
  async connectedCallback() {
    this.handleSubscribe();

    // preload last 10 logs
    this.logs = (await getAgentLogRecords()).map(getLogRecord);
  }

  renderedCallback() {
    //if a detail is open, lock the scroll to the bottom so you can see updates
    const logContent = this.template.querySelector(".log-scroll");
    if (this.selectedLog && logContent && this.scrollLock) {
      scrollToBottom(logContent);
    }
  }

  // Cleanup the component
  disconnectedCallback() {
    this.handleUnsubscribe();
  }

  handleRecordClick(event) {
    const logId = event.currentTarget.dataset.id;
    this.selectedLog = this.logs.find((log) => log.id === logId);
  }

  handleCloseModal() {
    this.selectedLog = null;
    this.scrollLock = true;
  }

  handleScrollLockToggle(event) {
    this.scrollLock = event.target.checked;
    if (this.scrollLock) {
      this.scrollToBottom();
    }
  }

  // Subscribe to the PushTopic
  handleSubscribe() {
    const messageCallback = ({ data }) => {
      try {
        getSingleRecord({ id: data.sobject.Id })
          .then((log) => {
            const existingRecord = this.logs.find((it) => it.id === log.Id);
            const newRecord = getLogRecord(log);

            if (existingRecord) {
              console.log("update existing record");
              for (const key in newRecord) {
                if (newRecord.hasOwnProperty(key)) {
                  existingRecord[key] = newRecord[key];
                }
              }
            } else {
              console.log("add new record");
              this.logs.push(newRecord);
            }

            //sort by lastUpdate desc
            this.logs.sort(
              (a, b) =>
                new Date(b.lastUpdate || 0) - new Date(a.lastUpdate || 0)
            );

            // if(this.selectedLog && this.selectedLog.id === newRecord.id){
            //     console.log('detailed element updated');
            //     const logContent = this.template.querySelector('#modal-content-id-1');
            //     if(logContent){
            //         scrollToBottom(logContent);
            //     }else{
            //         console.error('logContent not found');
            //     }

            // }
          })
          .catch(console.error);
      } catch (e) {
        console.error("err", e);
      }
    };

    subscribe("/topic/Agent_Log_Channel", -1, messageCallback).then(
      (response) => {
        console.log("Successfully subscribed to PushTopic:", response.channel);
        this.subscription = response;
      }
    );
  }

  // Unsubscribe from the PushTopic
  handleUnsubscribe() {
    unsubscribe(this.subscription, (response) => {
      console.log("Unsubscribed from channel:", response.subscription);
    });
  }
}

function getLogRecord(log) {
  return {
    id: log.Id,
    agentId: log.Agent_Id__c,
    input: log.Input__c,
    error: log.Error__c,
    result: log.Result__c,
    logDetails: log.Log__c,
    lastUpdate: log.Last_Agent_Update__c
  };
}

function scrollToBottom(element) {
  element.scrollTop = element.scrollHeight;
}
