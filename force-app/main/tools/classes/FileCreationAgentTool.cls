public class FileCreationAgentTool implements IAgentTool {
    public String getDescription() {
        return 'Create Salesforce files and optionally link them to Salesforce records';
    }

    public Map<String, String> getParameters() {
        return new Map<String, String>({
            'fileName' => 'The name of the file to be created',
            'fileContent' => 'The string content of the file',
            'recordId' => 'The Salesforce record Id to which the file should be linked (optional)'
        });
    }

    private String base64Encode(String data) {
        Blob inputBlob = Blob.valueOf(data);
        String base64EncodedData = EncodingUtil.base64Encode(inputBlob);
        return base64EncodedData;
    }

    public String execute(Map<String, String> args) {
        if (String.isEmpty(args.get('fileName'))) {
            throw new Agent.ActionRuntimeException('Missing required parameter: fileName');
        }

        if (String.isEmpty(args.get('fileContent'))) {
            throw new Agent.ActionRuntimeException('Missing required parameter: fileContent');
        }

        String fileName = args.get('fileName');
        String fileContent = args.get('fileContent');
        String recordId = args.get('recordId');

        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = base64Encode(fileContent);
        cv.IsMajorVersion = true;
        insert cv;

        if (!String.isEmpty(recordId)) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = recordId;
            cdl.ContentDocumentId = cv.Id;
            cdl.shareType = 'V';
            insert cdl;
        }

        return 'File created with Id: ' + conDocId;
    }
}