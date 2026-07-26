//
//  NotificationService.swift
//  LCVI DECA Study App
//
//  Local reminders only — no server, no account, no network.
//

import Combine
import Foundation
import UserNotifications

enum NotificationAuthState: Equatable {
    case notDetermined
    case authorized
    case provisional
    case denied
}

@MainActor
final class NotificationService: ObservableObject {
    static let dailyReminderID = "deca.daily.reminder"

    @Published private(set) var authState: NotificationAuthState = .notDetermined

    private let center = UNUserNotificationCenter.current()

    func refreshAuthorization() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .ephemeral:  authState = .authorized
        case .provisional:             authState = .provisional
        case .denied:                  authState = .denied
        default:                       authState = .notDetermined
        }
    }

    /// Requests permission. Callers must explain the benefit first.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorization()
            return granted
        } catch {
            await refreshAuthorization()
            return false
        }
    }

    /// Schedules (or reschedules) the daily reminder.
    func scheduleDailyReminder(hour: Int, minute: Int, goal: Int, style: ReminderStyle) async {
        cancelDailyReminder()
        guard authState == .authorized || authState == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = "DECA practice"
        content.body = style.body(goal: goal, remaining: goal)
        content.sound = .default
        content.threadIdentifier = "deca-daily"

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.dailyReminderID,
                                            content: content,
                                            trigger: trigger)
        try? await center.add(request)
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderID])
    }

    /// If the goal is already met today, skip today's reminder by scheduling a
    /// one-off for tomorrow instead of the repeating notification.
    func suppressTodayIfGoalMet(hour: Int, minute: Int, goal: Int, style: ReminderStyle) async {
        guard authState == .authorized || authState == .provisional else { return }

        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = hour
        comps.minute = minute

        guard let todayFire = cal.date(from: comps), todayFire > now else { return }

        // Replace the repeating request with one starting tomorrow.
        cancelDailyReminder()

        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: todayFire) else { return }

        let content = UNMutableNotificationContent()
        content.title = "DECA practice"
        content.body = style.body(goal: goal, remaining: goal)
        content.sound = .default
        content.threadIdentifier = "deca-daily"

        let fireComps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: tomorrow)
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComps, repeats: false)
        let request = UNNotificationRequest(identifier: Self.dailyReminderID + ".tomorrow",
                                            content: content,
                                            trigger: trigger)
        try? await center.add(request)
    }

    /// Re-arms the standard repeating reminder (called on next launch).
    func restoreRepeatingReminder(hour: Int, minute: Int, goal: Int, style: ReminderStyle) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderID + ".tomorrow"])
        await scheduleDailyReminder(hour: hour, minute: minute, goal: goal, style: style)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
