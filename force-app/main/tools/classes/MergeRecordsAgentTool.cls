public class MergeRecordsAgentTool implements IAgentTool {
    
    public String getDescription() {
        return 'Merge records of the same sObject type';
    }

    public Map<String, String> getParameters() {
        return new Map<String, String>{
            'sObjectType' => 'The sObject type to merge (e.g., Account, Contact, Lead, Case)',
            'masterRecordId' => 'The ID of the master record to merge into',
            'mergeRecordIds' => 'A comma-separated list of up to two record IDs to merge with the master record'
        };
    }

    public String execute(Map<String, String> args) {
        if (String.isEmpty(args.get('sObjectType')) || String.isEmpty(args.get('masterRecordId')) || String.isEmpty(args.get('mergeRecordIds'))) {
            throw new Agent.ActionRuntimeException('missing required parameters: sObjectType, masterRecordId, mergeRecordIds');
        }

        String sObjectType = args.get('sObjectType');
        Id masterRecordId = Id.valueOf(args.get('masterRecordId'));
        List<String> mergeRecordIdStrings = args.get('mergeRecordIds').split(',');
        List<Id> mergeRecordIds = new List<Id>();
        for (String mergeRecordIdString : mergeRecordIdStrings) {
            mergeRecordIds.add(Id.valueOf(mergeRecordIdString));
        }

        SObject masterRecord = Database.query('SELECT Id FROM ' + sObjectType + ' WHERE Id = :masterRecordId');
        List<SObject> mergeRecords = Database.query('SELECT Id FROM ' + sObjectType + ' WHERE Id IN :mergeRecordIds');

        if (mergeRecords.size() > 2) {
            throw new Agent.ActionRuntimeException('You can only merge up to two records with the master record');
        }

        Database.MergeResult[] mergeResults = Database.merge(masterRecord, mergeRecords, false);

        for (Database.MergeResult mergeResult : mergeResults) {
            if (!mergeResult.isSuccess()) {
                String errorMessage = 'Failed to merge records: ';
                for (Database.Error error : mergeResult.getErrors()) {
                    errorMessage += error.getMessage() + '. ';
                }
                throw new Agent.ActionRuntimeException(errorMessage);
            }
        }

        return 'Records merged successfully';
    }
}