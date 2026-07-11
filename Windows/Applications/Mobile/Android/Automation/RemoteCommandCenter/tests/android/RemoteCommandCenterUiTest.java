package com.mich.remotecommandcenter.test;

import com.android.uiautomator.core.UiObject;
import com.android.uiautomator.core.UiScrollable;
import com.android.uiautomator.core.UiSelector;
import com.android.uiautomator.testrunner.UiAutomatorTestCase;
import android.graphics.Rect;

public final class RemoteCommandCenterUiTest extends UiAutomatorTestCase {
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
        assertTrue("Rendered YouTube button click was not injected", youtube.click());
        UiObject actionStatus = new UiObject(new UiSelector()
                .packageName("com.mich.remotecommandcenter")
                .textMatches(".*(TizenTube|YouTube).*"));
        assertTrue("YouTube click listener did not update application status",
                actionStatus.waitForExists(5000));
        System.out.println("REMOTE_COMMAND_CENTER_YOUTUBE_VIEW_CLICK_INJECTED bounds=" + bounds);
    }
}
