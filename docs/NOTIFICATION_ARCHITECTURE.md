# SalahTrack notification architecture

## Android prayer channel

- Channel ID: `salahtrack_prayer_reminders_v1`
- Visible channel name: localized “Prayer reminders”
- Importance: high
- Sound: enabled and controlled by the Android channel/user setting
- Vibration: enabled and controlled by the Android channel/user setting
- Lock screen and notification shade: governed by normal Android and user settings
- Tap behavior: opens SalahTrack; safe Mark as Prayed and Snooze actions remain available

Initial prayer and Friday/Jumu'ah notifications are dismissible. Grace-period
and snooze reminders can be ongoing while they require attention; they are not
used to launch an Activity automatically. SalahTrack does not use overlay,
accessibility, usage-access, background-location, VPN, or device-administrator
mechanisms to force UI over other applications.

The versioned channel ID is intentional. Android persists channel importance,
sound, and vibration after a channel is first created, so the production
standard-notification architecture must not reuse a channel created for the
earlier alarm-style behavior. The separate `ramadan_reminders` channel remains
in place because it serves a distinct user-configurable category.

## Scheduling

`SCHEDULE_EXACT_ALARM` remains declared. When exact scheduling is available,
SalahTrack uses exact idle-safe alarms; otherwise it falls back to inexact
idle-safe scheduling without crashing. No `USE_EXACT_ALARM` permission is
declared.

Friday/Jumu'ah reminders are one-shot local notifications scheduled one hour
before each effective Friday time. Automatic mode follows calculated Friday
Dhuhr dynamically; a manual mosque-time override is preserved until the user
chooses “Use Dhuhr time.” Rescheduling cancels pending Friday reminders first,
which avoids duplicates after time, location, timezone, or calculation changes.

## iOS

iOS continues to use local Time Sensitive notifications and localized action
categories. Android-specific presentation changes do not introduce an iOS
replacement for alarm-style UI.
