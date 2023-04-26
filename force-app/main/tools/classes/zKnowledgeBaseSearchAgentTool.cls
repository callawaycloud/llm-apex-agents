public class zKnowledgeBaseSearchAgentTool implements IAgentTool {
    public String getDescription() {
        return 'Returns a list of Salesforce Knowledge articles or SObject records whose names or titles match the user’s search query string';
    }

    public Map<String, String> getParameters() {
        return new Map<String, String>{
            'searchText' => 'The text to search for in Knowledge Articles',
            'nbResult' => 'The maximum number of results to return',
            'objectType' => 'Use KnowledgeArticleVersion for Knowledge Base Articles. KnowledgeArticleVersion, Account, Contact, etc. ',
            'language' => 'For Knowledge Base Articles, The language to filter the articles by: en_US, es, fr, etc',
            'publishStatus' => 'For Knowledge Base Articles, The publishing status of the articles to filter: Online, Draft, or Archived'
        };
    }

    public String execute(Map<String, String> args) {
        String searchText = args.get('searchText');
        if (String.isEmpty(searchText)) {
            throw new Agent.ActionRuntimeException('missing required parameter: searchText');
        }
        
        String language = args.get('language');
        if (String.isEmpty(language)) {
            throw new Agent.ActionRuntimeException('missing required parameter: language');
        }
        
        String objectType = args.get('objectType');
        if (String.isEmpty(objectType)) {
            throw new Agent.ActionRuntimeException('missing required parameter: objectType');
        }
        
        String publishStatus = args.get('publishStatus');
        if (String.isEmpty(publishStatus)) {
            throw new Agent.ActionRuntimeException('missing required parameter: publishStatus');
        }
        
        String nbResultStr = args.get('nbResult');
        if (String.isEmpty(nbResultStr)) {
            throw new Agent.ActionRuntimeException('missing required parameter: nbResult');
        }
        
        Integer nbResult;
        try {
            nbResult = Integer.valueOf(nbResultStr);
        } catch (Exception e) {
            throw new Agent.ActionRuntimeException('invalid value for parameter: nbResult');
        }
        
        Search.SuggestionOption options = new Search.SuggestionOption();
        if (objectType == 'KnowledgeArticleVersion') {
            Search.KnowledgeSuggestionFilter filters = new Search.KnowledgeSuggestionFilter();
            filters.setLanguage(language);
            filters.setPublishStatus(publishStatus);
            options.setFilter(filters);
        }
        options.setLimit(nbResult);
        
        Search.SuggestionResults suggestionResults = Search.suggest(searchText, objectType, options);
        
        String result = 'Results:\n';
        for (Search.SuggestionResult searchResult : suggestionResults.getSuggestionResults()) {
            if (objectType == 'KnowledgeArticleVersion') {
                if(searchResult.getSobject().isSet('Title')) { //KnowledgeArticleVersion
                	result += '- ' + searchResult.getSobject().get('Title') + ' (' + searchResult.getSobject().get('Id') + ')\n';
                }
            } else {
                if(searchResult.getSobject().isSet('Name')) {// Other SObject
                    result += '- ' + searchResult.getSobject().get('Name') + ' (' + searchResult.getSobject().get('Id') + ')\n';
                } else { // Should not happen
                    result += '- ' + searchResult.getSobject().get('Id') + '\n';
                }
            }
        }
        return result;
    }
}