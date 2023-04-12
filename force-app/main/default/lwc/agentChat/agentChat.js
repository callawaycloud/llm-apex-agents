import { LightningElement } from "lwc";

// Apex methods
import runAgent from "@salesforce/apex/AgentLogController.runAgent";

export default class AgentChat extends LightningElement {
  handleClick(event) {
    const element = this.template.querySelector("lightning-textarea");

    runAgent({ objective: element.value })
      .then((response) => {
        console.log("response", response);
      })
      .catch((e) => console.error(e));
  }
}
