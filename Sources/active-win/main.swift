import AppKit

func getActiveBrowserTabURLAppleScriptCommand(_ appName: String) -> String? {
	switch appName {
	case "Google Chrome", "Brave Browser", "Microsoft Edge":
		return "tell app \"\(appName)\" to get the URL of active tab of front window"
	case "Safari":
		return "tell app \"Safari\" to get URL of front document"
	default:
		return nil
	}
}

let frontmostAppPID = NSWorkspace.shared.frontmostApplication!.processIdentifier
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]

// Show screen recording permission prompt if needed. Required to get the complete window title.
if !hasScreenRecordingPermission() {
	print("active-win requires the screen recording permission in “System Preferences › Security & Privacy › Privacy › Screen Recording”.")
	exit(1)
}

for window in windows {
	let windowOwnerPID = window[kCGWindowOwnerPID as String] as! Int

	if windowOwnerPID != frontmostAppPID {
		continue
	}

	// Skip transparent windows, like with Chrome.
	if (window[kCGWindowAlpha as String] as! Double) == 0 {
		continue
	}

	let bounds = CGRect(dictionaryRepresentation: window[kCGWindowBounds as String] as! CFDictionary)!

	// Skip tiny windows, like the Chrome link hover statusbar.
	let minWinSize: CGFloat = 50
	if bounds.width < minWinSize || bounds.height < minWinSize {
		continue
	}

	let appPid = window[kCGWindowOwnerPID as String] as! pid_t

	// This can't fail as we're only dealing with apps.
	let app = NSRunningApplication(processIdentifier: appPid)!

	let appName = window[kCGWindowOwnerName as String] as! String

	var dict: [String: Any] = [
		"title": window[kCGWindowName as String] as? String ?? "",
		"id": window[kCGWindowNumber as String] as! Int,
		"bounds": [
			"x": bounds.origin.x,
			"y": bounds.origin.y,
			"width": bounds.width,
			"height": bounds.height
		],
		"owner": [
			"name": appName,
			"processId": appPid,
			"bundleId": app.bundleIdentifier!,
			"path": app.bundleURL!.path
		],
		"memoryUsage": window[kCGWindowMemoryUsage as String] as! Int
	]

	// Only run the AppleScript if active window is a compatible browser.
	if
		let script = getActiveBrowserTabURLAppleScriptCommand(appName),
		let url = runAppleScript(source: script)
	{
		dict["url"] = url
	}

	print(try! toJson(dict))
	exit(0)
}

print("null")
exit(0)
