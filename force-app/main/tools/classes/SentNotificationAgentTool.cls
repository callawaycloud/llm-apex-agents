public class SentNotificationAgentTool implements IAgentTool {
  public Id notificationTypeId;
  public SentNotificationAgentTool(Id notificationTypeId) {
    this.notificationTypeId = notificationTypeId;
  }

  public string getDescription() {
    return 'Send Notification to user';
  }

  public Map<string, string> getParameters() {
    Map<string, string> params = new Map<string, string>();
    params.put('title', 'notification title');
    params.put('body', 'notification message');
    params.put('to', 'user id to send notification to');
    params.put('targetId', 'record id this notification relates to');
    return params;
  }

  public string execute(Map<string, string> args) {
    String title = args.get('title');
    String body = args.get('body');
    String to = args.get('to');
    String targetId = args.get('targetId');
    Messaging.CustomNotification notification = new Messaging.CustomNotification();

    notification.setTitle(title);
    notification.setBody(body);

    notification.setSenderId(Userinfo.getUserId());
    notification.setNotificationTypeId(this.notificationTypeId);

    notification.setTargetId(targetId); // TODO need this to pass in

    notification.send(new Set<String>{ to });
    //Due to what appears to be an SF bug, this does not update the limits.getDMLOperations() count
    AgentQueueable.FORCE_NEW_QUEUEABLE = true;
    return 'Notification Sent';
  }
}
