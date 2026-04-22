import Foundation
import UserNotifications

class NotificationManager {
    
    static let shared = NotificationManager()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("通知授权错误: \(error)")
            }
        }
    }
    
    func scheduleDailyReminder(hour: Int = 20, minute: Int = 0) {
        // 取消旧通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "该背单词了"
        content.body = "今日还有单词等待复习，坚持就是胜利！"
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知设置错误: \(error)")
            }
        }
    }
    
    func scheduleReviewReminder(dueCount: Int) {
        guard dueCount > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "有 \(dueCount) 个单词待复习"
        content.body = "间隔重复是记忆的关键，现在复习效果最好！"
        content.sound = .default
        
        // 15分钟后提醒
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 900, repeats: false)
        let request = UNNotificationRequest(identifier: "review_reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
}
