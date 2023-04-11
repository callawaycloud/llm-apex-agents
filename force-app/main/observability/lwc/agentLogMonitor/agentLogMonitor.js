//Written by GPT-4
import { LightningElement, wire, track } from 'lwc';
import getAgentLogRecords from '@salesforce/apex/AgentLogController.getAgentLogRecords';

export default class AgentLogList extends LightningElement {
    @track logRecords;
    @track selectedRecord;

    @wire(getAgentLogRecords)
    loadAgentLogRecords({ error, data }) {
        if (data) {
            this.logRecords = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.logRecords = undefined;
        }
    }

    handleRecordClick(event) {
        const recordId = event.currentTarget.dataset.id;
        this.selectedRecord = this.logRecords.find(record => record.Id === recordId);
    }
}
