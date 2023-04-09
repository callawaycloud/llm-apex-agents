public class CompletionModelChatAdapter implements ChatModel.I {
  public CompletionModel.I model;
  public String[] stopSequence;

  public CompletionModelChatAdapter(
    CompletionModel.I model,
    String[] stopSequence
  ) {
    this.model = model;
    this.stopSequence = stopSequence;
  }

  public String chat(ChatModel.Message[] messages) {
    // join messages content into string
    String content = '';
    for (ChatModel.Message m : messages) {
      content += m.content;
    }
    // call completion model
    return model.complete(content, stopSequence);
  }
}
