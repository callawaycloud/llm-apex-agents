public class KnowledgeArticleAgentTool implements IAgentTool {
    public String getDescription() {
        return 'Returns a list of SObject records or Salesforce Knowledge articles whose names or titles match the user’s search query string';
    }

    public Map<String, String> getParameters() {
        return new Map<String, String>({
            'searchText' => 'The text to search for in Knowledge Articles',
            'nbResult' => 'The maximum number of results to return',
            'objectType' => 'The SObject to search: KnowledgeArticleVersion, Account, Contact, etc. Use KnowledgeArticleVersion for Knowledge Base Articles.',
            'language' => 'For Knowledge Base Articles, The language to filter the articles by: en_US, es, fr, etc',
            'publishStatus' => 'For Knowledge Base Articles, The publishing status of the articles to filter: Online, Draft, or Archived'
        });
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
        
        List<Search.Suggestion> suggestionResults = searchKnowledgeArticles(searchText, objectType, language, publishStatus, nbResult);
        return formatResults(suggestionResults);
    }
    
    private List<Search.Suggestion> searchKnowledgeArticles(String searchText, String objectType, String language, String publishStatus, Integer nbResult) {
        Search.SuggestionOption options = new Search.SuggestionOption();
        if (objectType == 'KnowledgeArticleVersion') {
            Search.KnowledgeSuggestionFilter filters = new Search.KnowledgeSuggestionFilter();
            filters.setLanguage(language);
            filters.setPublishStatus(publishStatus);
            options.setFilter(filters);
        }
        options.setLimit(nbResult);
        return Search.suggest(searchText, objectType, options);
    }
    
    private String formatResults(List<Search.Suggestion> suggestionResults) {
        String result = 'Results:\n';
        for (Search.Suggestion suggestion : suggestionResults) {
            if(suggestion.getSobject().isSet('Title')) { //KnowledgeArticleVersion
                result += '- ' + suggestion.getSobject().get('Title') + ' (' + suggestion.getSobject().get('Id') + ')\n';
            } else if(suggestion.getSobject().isSet('Name')) {// Other SObject
                result += '- ' + suggestion.getSobject().get('Name') + ' (' + suggestion.getSobject().get('Id') + ')\n';
            } else { // Should not happen
                result += '- ' + suggestion.getSobject().get('Id') + '\n';
            }
        }
        return result;
    }
}