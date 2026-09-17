package com.mich.remotecommandcenter.test;

import com.android.uiautomator.core.UiObject;
import com.android.uiautomator.core.UiScrollable;
import com.android.uiautomator.core.UiSelector;
import com.android.uiautomator.testrunner.UiAutomatorTestCase;
import android.graphics.Rect;

public final class RemoteCommandCenterUiTest extends UiAutomatorTestCase {
    public void testWhatChangedDialogShowsInstalledBuildSummary() throws Exception {
        String packageName = "com.mich.remotecommandcenter";
        UiObject updateInfo = new UiObject(new UiSelector()
                .packageName(packageName)
                .description("Show changes included in the installed update")
                .clickable(true));
        assertTrue("Update summary control was not rendered", updateInfo.waitForExists(5000));
        assertTrue("Update summary control did not respond to a tap", updateInfo.click());

        UiObject dialogTitle = new UiObject(new UiSelector()
                .packageName(packageName)
                .textContains("What changed — "));
        assertTrue("Versioned update dialog did not appear", dialogTitle.waitForExists(3000));
        String title = dialogTitle.getText();
        assertTrue("Update dialog title omitted the installed version/build: " + title,
                title != null && title.contains("(build "));

        UiObject authSummary = new UiObject(new UiSelector()
                .packageName(packageName)
                .textContains("strict authenticated action allowlist"));
        UiObject visibilitySummary = new UiObject(new UiSelector()
                .packageName(packageName)
                .textContains("every three seconds while this screen is visible"));
        assertTrue("Update dialog omitted the authentication summary", authSummary.exists());
        assertTrue("Update dialog omitted the foreground polling summary", visibilitySummary.exists());

        UiObject close = new UiObject(new UiSelector().packageName(packageName).text("Close"));
        assertTrue("Update dialog has no Close button", close.exists());
        assertTrue("Update dialog did not close", close.click());
        System.out.println("REMOTE_COMMAND_CENTER_UPDATE_SUMMARY_PASS");
    }

    public void testShutdownRequiresConfirmationAndCanBeCancelled() throws Exception {
        assertDestructivePcActionCanBeCancelled(
                "Shut down PC", "Confirm PC shutdown", "Shut down PC", "force-closes open apps");
    }

    public void testForceRebootRequiresConfirmationAndCanBeCancelled() throws Exception {
        assertDestructivePcActionCanBeCancelled(
                "Force reboot now", "Confirm PC reboot", "Force reboot now", "force-closes open apps");
    }

    public void testLogoffRequiresConfirmationAndCanBeCancelled() throws Exception {
        assertDestructivePcActionCanBeCancelled(
                "Log out and back in", "Confirm sign-out and sign-in", "Log out and back in",
                "force-closes open apps");
    }

    public void testBiosRestartRequiresConfirmationAndCanBeCancelled() throws Exception {
        assertDestructivePcActionCanBeCancelled(
                "Reboot to BIOS", "Confirm BIOS restart", "Reboot to BIOS", "force-closes open apps");
    }

    public void testRestartCodexRequiresConfirmationAndCanBeCancelled() throws Exception {
        assertDestructivePcActionCanBeCancelled(
                "Restart Codex", "Confirm Codex restart", "Restart Codex", "task may disconnect briefly");
    }

    private void assertDestructivePcActionCanBeCancelled(
            String buttonDescription, String dialogTitle, String actionLabel, String warningText) throws Exception {
        String packageName = "com.mich.remotecommandcenter";
        UiSelector actionSelector = new UiSelector()
                .packageName(packageName)
                .description(buttonDescription)
                .clickable(true);
        UiScrollable scroll = new UiScrollable(new UiSelector()
                .packageName(packageName)
                .scrollable(true));
        if (scroll.exists()) {
            scroll.setAsVerticalList();
            try {
                scroll.scrollIntoView(actionSelector);
            } catch (com.android.uiautomator.core.UiObjectNotFoundException ignored) {
                // The control may already be visible.
            }
        }

        UiObject action = new UiObject(actionSelector);
        assertTrue("Destructive PC control was not rendered: " + buttonDescription,
                action.waitForExists(5000));
        assertTrue("Destructive PC control did not respond to a tap: " + buttonDescription,
                action.click());

        UiObject title = new UiObject(new UiSelector()
                .packageName(packageName)
                .text(dialogTitle));
        assertTrue("Destructive PC action did not require explicit confirmation: " + actionLabel,
                title.waitForExists(3000));
        UiObject warning = new UiObject(new UiSelector()
                .packageName(packageName)
                .textContains(warningText));
        assertTrue("Confirmation omitted the destructive action warning: " + actionLabel,
                warning.exists());

        UiObject cancel = new UiObject(new UiSelector()
                .packageName(packageName)
                .text("Cancel"));
        assertTrue("Confirmation had no Cancel button: " + actionLabel, cancel.exists());
        assertTrue("Confirmation could not be cancelled: " + actionLabel, cancel.click());
        assertFalse("Cancelled confirmation remained visible: " + actionLabel,
                title.waitForExists(1500));

        UiObject actionStatus = new UiObject(new UiSelector()
                .packageName(packageName)
                .description("Remote Command Center action status"));
        assertTrue("Application action status was not rendered", actionStatus.waitForExists(3000));
        String status = actionStatus.getText();
        assertTrue("Cancelling dispatched the destructive PC action: " + status,
                status == null || (!status.contains("Sending " + actionLabel)
                        && !status.contains("Completed: " + actionLabel)
                        && !status.contains("Unconfirmed: " + actionLabel)));
        System.out.println("REMOTE_COMMAND_CENTER_DESTRUCTIVE_CONFIRM_CANCEL_PASS " + actionLabel);
    }

    public void testTerminalImeWaitsForPowerShellLineReturn() throws Exception {
        String packageName = "com.mich.remotecommandcenter";
        UiSelector inputSelector = new UiSelector()
                .packageName(packageName)
                .description("PowerShell command line");
        UiScrollable scroll = new UiScrollable(new UiSelector()
                .packageName(packageName)
                .scrollable(true));
        if (scroll.exists()) {
            scroll.setAsVerticalList();
            try {
                scroll.scrollIntoView(inputSelector);
            } catch (com.android.uiautomator.core.UiObjectNotFoundException ignored) {
                // The field may already be visible in layouts with no scrollable parent.
            }
        }

        UiObject input = new UiObject(inputSelector);
        assertTrue("PC Terminal input was not rendered", input.waitForExists(5000));
        UiObject actionStatus = new UiObject(new UiSelector()
                .packageName(packageName)
                .description("Remote Command Center action status"));
        assertTrue("Application action status was not rendered", actionStatus.waitForExists(5000));
        assertTrue("PC Terminal input could not be focused", input.click());
        assertTrue("PC Terminal input rejected a harmless acceptance line",
                input.setText("Write-Output RCC_TERMINAL_IME_ACCEPTANCE"));
        assertTrue("IME Enter did not submit the terminal line", getUiDevice().pressEnter());

        String finalStatus = actionStatus.getText();
        long deadline = System.currentTimeMillis() + 60000;
        while ((finalStatus == null || !finalStatus.matches(
                "Line returned: PC Terminal \\(effects not verified\\) \\([A-Za-z0-9_-]{8}\\)"))
                && System.currentTimeMillis() < deadline) {
            Thread.sleep(200);
            finalStatus = actionStatus.getText();
        }
        assertTrue("PC Terminal did not report the returned line: " + finalStatus,
                finalStatus != null && finalStatus.matches(
                        "Line returned: PC Terminal \\(effects not verified\\) \\([A-Za-z0-9_-]{8}\\)"));
        System.out.println("REMOTE_COMMAND_CENTER_TERMINAL_IME_COMPLETION_PASS");
    }

    public void testClickYouTubeButtonOnce() throws Exception {
        UiSelector youtubeSelector = new UiSelector()
                .packageName("com.mich.remotecommandcenter")
                .description("YouTube")
                .clickable(true);

        UiScrollable scroll = new UiScrollable(
                new UiSelector()
                        .packageName("com.mich.remotecommandcenter")
                        .scrollable(true));
        scroll.setAsVerticalList();
        scroll.scrollIntoView(youtubeSelector);

        UiObject youtube = new UiObject(youtubeSelector);
        assertTrue("Rendered YouTube button was not found", youtube.waitForExists(5000));
        Rect bounds = youtube.getVisibleBounds();
        for (int attempt = 0;
                attempt < 6 && bounds.centerY() >= getUiDevice().getDisplayHeight() - 150;
                attempt++) {
            scroll.scrollForward(30);
            youtube = new UiObject(youtubeSelector);
            assertTrue("YouTube button disappeared while scrolling", youtube.waitForExists(2000));
            bounds = youtube.getVisibleBounds();
        }
        assertEquals("com.mich.remotecommandcenter", youtube.getPackageName());
        assertTrue("Rendered YouTube button was not enabled", youtube.isEnabled());
        assertTrue("Rendered YouTube button was not fully visible: " + bounds,
                bounds.height() > 100 && bounds.centerY() < getUiDevice().getDisplayHeight() - 150);
        UiObject actionStatus = new UiObject(new UiSelector()
                .packageName("com.mich.remotecommandcenter")
                .description("Remote Command Center action status"));
        assertTrue("Application action status was not rendered", actionStatus.waitForExists(5000));
        String initialStatus = actionStatus.getText();
        assertTrue("Rendered YouTube button click was not injected", youtube.click());
        String finalStatus = actionStatus.getText();
        long deadline = System.currentTimeMillis() + 30000;
        while ((finalStatus == null || !finalStatus.matches("Completed: YouTube \\([A-Za-z0-9_-]{8}\\)"))
                && System.currentTimeMillis() < deadline) {
            Thread.sleep(150);
            finalStatus = actionStatus.getText();
        }
        assertFalse("YouTube click left the action status unchanged: " + finalStatus,
                initialStatus.equals(finalStatus));
        assertTrue("YouTube action did not complete at the receiver: " + finalStatus,
                finalStatus != null && finalStatus.matches("Completed: YouTube \\([A-Za-z0-9_-]{8}\\)"));
        System.out.println("REMOTE_COMMAND_CENTER_YOUTUBE_ACTION_COMPLETED bounds=" + bounds);
    }
}
