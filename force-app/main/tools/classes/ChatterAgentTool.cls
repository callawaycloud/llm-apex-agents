public class ChatterAgentTool implements IAgentTool {
    public String getDescription() {
        return 'Chatter Agent Tool for managing Chatter posts';
    }

    public Map<String, String> getParameters() {
        return new Map<String, String>{
            'operation' => 'The action to be performed: insert, delete, retrieve, update, or upsert on the Chatter post',
            'Id' => 'The unique identifier of the Chatter post to be retrieved, updated, or deleted',
            'parentId' => 'The unique identifier of the parent record, such as the Account record Id for a post on the Account record page',
            'title' => 'The title of the feed item; for LinkPost type, this is the link name; can only be updated on posts of type QuestionPost',
            'body' => 'The main text content of the Chatter post',
            'isRichText' => 'Indicates whether the post body contains rich text formatting: true or false',
            'linkUrl' => 'The web address for LinkPost type.',
            'visibility' => 'The post visibility level: AllUsers (visible to everyone) or InternalUsers (visible only to internal users). Optional. For record posts, Visibility is set to InternalUsers for all internal users by default.',
            'type' => 'The category of the Chatter post: LinkPost, QuestionPost, or TextPost. Usually will be TextPost',
            'lastEditById' => 'The unique identifier of the Salesforce User who made the most recent edit. Optional',
            'lastEditDate' => 'The date and time of the most recent edit, as a DateTime string. Optional.',
            'revision' => 'The version number of the Chatter post as an Integer. Optional.',
            'status' => 'The current state of the Chatter post: Published or PendingReview. The value Published  means publicly available while PendingReview means  awaiting approval.'
        };
    }

    public String execute(Map<String, String> args) {
        String operation = args.get('operation');
        if (String.isEmpty(operation)) {
            throw new Agent.ActionRuntimeException('Missing required parameter: operation');
        }
        operation = operation.toLowerCase();
        switch on operation {
            when 'delete' {
                return deletePost(args.get('Id'));
            }
            when 'retrieve' {
                return retrievePost(args.get('Id'));
            }
            when 'insert','update','upsert' {
                return insertUpdateUpsert(args);
            }
            when else {
                throw new Agent.ActionRuntimeException('Invalid operation: ' + operation);
            }
        }
    }

    private Sobject setFeedItemFields(Sobject sobj, Map<String, String> args) {
        for (String key : args.keySet()) {
            if (args.get(key) != null) {
                if (key == 'isRichText') {
                    sobj.put(key, Boolean.valueOf(args.get(key)));
                } else if (key == 'lastEditDate') {
                    sobj.put(key, DateTime.valueOf(args.get(key)));
                } else if (key == 'revision') {
                    sobj.put(key, Integer.valueOf(args.get(key)));
                } else {
                    sobj.put(key, args.get(key));
                }
            }
        }
        return sobj;
    }

    private String retrievePost(String Id) {
        FeedItem post = [SELECT Id, parentId, Body, isRichText, linkUrl, visibility, type CreatedDate, LastEditById, LastEditDate, Revision, Status FROM FeedItem WHERE Id = :Id];
        return JSON.serialize(post);
    }

    private String deletePost(String Id) {
        FeedItem post = [SELECT Id FROM FeedItem WHERE Id = :Id];
        delete post;
        return 'Post deleted with Id: ' + id;
    }

    private String insertUpdateUpsert(Map<String, String> args) {
        String operation = args.get('operation');
        if(operation == 'insert') {
            if (String.isEmpty(args.get('parentId'))) {
                throw new Agent.ActionRuntimeException('Missing required parameter: parentId');
            }
            if (String.isEmpty(args.get('body'))) {
                throw new Agent.ActionRuntimeException('Missing required parameter: body');
            }
        } else if (operation == 'update' || operation == 'upsert') {
            if (String.isEmpty(args.get('Id'))) {
                throw new Agent.ActionRuntimeException('Missing required parameter: Id');
            }
        }
        FeedItem post = new FeedItem();
        if (operation == 'update' || operation == 'upsert') {
            post.Id = args.get('Id');
        }
        post = setFeedItemFields(post, args);
        if(operation == 'insert') {
            insert post;
            return 'Post inserted with Id: ' + post.Id;
        } else if(operation == 'update') {
            update post;
            return 'Post updated with Id: ' + post.Id;
        } else if (operation == 'upsert') {
            upsert post;
            return 'Post upserted with Id: ' + post.Id;
        }
    }
}