public class SentNotificationAgentTool implements IAgentTool {
  public Id notificationTypeId;

  public SentNotificationAgentTool() {
    CustomNotificationType notifType = [
      SELECT Id
      FROM CustomNotificationType
      WHERE DeveloperName = 'Agent_Notification'
    ];
    this.notificationTypeId = notifType.Id;
  }

  public SentNotificationAgentTool(Id notificationTypeId) {
    this.notificationTypeId = notificationTypeId;
  }

  public string getDescription() {
    return 'Send Notification to user';
  }

  public Map<string, string> getParameters() {
    return new Map<string, string>{
      'title' => 'Notification Title',
      'body' => 'Notification Message',
      'to' => 'User Id to send notification to',
      'targetId' => 'Record Id this notification relates to'
    };
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

    notification.setTargetId(targetId);

    notification.send(new Set<String>{ to });
    //Due to what appears to be an SF bug, this does not update the limits.getDMLOperations() count
    AgentQueueable.FORCE_NEW_QUEUEABLE = true;
    return 'Notification Sent';
  }
}
