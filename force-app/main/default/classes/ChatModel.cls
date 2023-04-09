public class ChatModel {
  public interface I {
    String chat(Message[] messages);
  }

  public class Message {
    public Message(String role, string content) {
      this.role = role;
      this.content = content;
    }
    public String role;
    public String content;
  }
}
