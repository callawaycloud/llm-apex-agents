//Written by GPT-4
public without sharing class AgentLogController {
  @AuraEnabled(cacheable=true)
  public static List<Agent_Log__c> getAgentLogRecords() {
    return [
      SELECT
        Id,
        Agent_Id__c,
        Input__c,
        Result__c,
        Error__c,
        Log__c,
        LastModifiedDate
      FROM Agent_Log__c
      ORDER BY LastModifiedDate DESC
    ];
  }
}
