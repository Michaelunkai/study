package com.mich.remotecommandcenter;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.provider.Settings;
import android.text.InputType;
import android.util.Log;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.Button;
import android.widget.EditText;
import android.widget.GridLayout;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.NumberPicker;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

public class MainActivity extends Activity {
    private static final String TAG = "RemoteCommandCenter";
    private static final String CONFIRM = "REMOTE_COMMAND_CENTER_EXECUTE";
    private static final String PREFS = "remote_command_center_state";
    private static final String KEY_EXPECTED_PC_STATE = "expected_pc_state";
    private static final String KEY_TV_VOLUME = "tv_volume";
    private static final String STATE_READY = "ready";
    private static final String STATE_SLEEPING = "sleeping";
    private static final String STATE_OFF_OR_UNKNOWN = "off_or_unknown";

    private final SecureRandom random = new SecureRandom();
    private JSONObject config;
    private View pcStatusDot;
    private TextView pcStatusLabel;
    private TextView status;
    private EditText terminalInput;
    private final ArrayList<TextView> buttons = new ArrayList<>();
    private final AtomicBoolean volumeHeld = new AtomicBoolean(false);
    private final AtomicBoolean wakeSendInFlight = new AtomicBoolean(false);
    private final ConcurrentHashMap<String, AtomicBoolean> actionSendInFlight = new ConcurrentHashMap<>();
    private final AtomicLong directTvRetryAfterMs = new AtomicLong(0);
    private final AtomicLong relayRetryAfterMs = new AtomicLong(0);
    private final Handler statusHandler = new Handler(Looper.getMainLooper());
    private volatile boolean destroyed;
    private final Runnable statusPoller = new Runnable() {
        @Override
        public void run() {
            if (destroyed) return;
            checkPcStatusAsync();
            statusHandler.postDelayed(this, 600);
        }
    };

    private static class Command {
        final String id;
        final String label;
        final int iconRes;
        final int color;
        final boolean local;
        final boolean textOverlay;

        Command(String id, int iconRes, String label, int color) {
            this(id, iconRes, label, color, false);
        }

        Command(String id, int iconRes, String label, int color, boolean local) {
            this(id, iconRes, label, color, local, false);
        }

        Command(String id, int iconRes, String label, int color, boolean local, boolean textOverlay) {
            this.id = id;
            this.iconRes = iconRes;
            this.label = label;
            this.color = color;
            this.local = local;
            this.textOverlay = textOverlay;
        }
    }

    private class RoundIconTextView extends TextView {
        private final int iconRes;
        private final int fallbackColor;
        private final RectF oval = new RectF();
        private final Path clipPath = new Path();
        private final Paint fillPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint scrimPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint borderPaint = new Paint(Paint.ANTI_ALIAS_FLAG);

        RoundIconTextView(Context context, int iconRes, int fallbackColor) {
            super(context);
            this.iconRes = iconRes;
            this.fallbackColor = fallbackColor;
            setWillNotDraw(false);
            fillPaint.setStyle(Paint.Style.FILL);
            scrimPaint.setColor(Color.argb(54, 0, 0, 0));
            scrimPaint.setStyle(Paint.Style.FILL);
            borderPaint.setColor(Color.argb(215, 255, 255, 255));
            borderPaint.setStyle(Paint.Style.STROKE);
            borderPaint.setStrokeWidth(dp(3));
        }

        @Override
        protected void onDraw(Canvas canvas) {
            int width = getWidth();
            int height = getHeight();
            if (width <= 0 || height <= 0) {
                super.onDraw(canvas);
                return;
            }

            oval.set(0, 0, width, height);
            clipPath.reset();
            clipPath.addOval(oval, Path.Direction.CW);

            int save = canvas.save();
            canvas.clipPath(clipPath);
            fillPaint.setColor(fallbackColor);
            canvas.drawOval(oval, fillPaint);

            Drawable icon = getDrawable(iconRes);
            if (icon != null) {
                icon.setBounds(0, 0, width, height);
                icon.draw(canvas);
            }
            canvas.drawOval(oval, scrimPaint);
            canvas.restoreToCount(save);

            float inset = dp(2);
            oval.inset(inset, inset);
            canvas.drawOval(oval, borderPaint);
            oval.inset(-inset, -inset);

            super.onDraw(canvas);
        }
    }

    private final Command[] powerCommands = new Command[] {
            new Command("sleep_pc", R.drawable.ic_power_sleep_bg, "Actual Sleep", Color.rgb(99, 102, 241)),
            new Command("wake_pc", R.drawable.ic_power_wake_bg, "Wake", Color.rgb(20, 184, 166)),
            new Command("force_reboot_now", R.drawable.ic_power_reboot_bg, "Force reboot now", Color.rgb(239, 68, 68)),
            new Command("shutdown_pc", R.drawable.ic_power_shutdown_bg, "Shut down PC", Color.rgb(220, 38, 38)),
            new Command("reboot_to_bios", R.drawable.ic_power_bios_bg, "Reboot to BIOS", Color.rgb(190, 18, 60)),
            new Command("refresh2_logoff", R.drawable.ic_power_relogin_bg, "Log out and back in", Color.rgb(217, 119, 6), false, true)
    };

    private final Command[] systemCommands = new Command[] {
            new Command("explorer_refresh_gpu", R.drawable.ic_explorer_refresh_gpu, "Explorer + Refresh GPU", Color.rgb(34, 197, 94), false, true),
            new Command("night_mode_toggle", R.drawable.img_night_mode, "Night mode on/off", Color.rgb(59, 130, 246))
    };

    private final Command[] tvCommands = new Command[] {
            new Command("youtube_tizen", R.drawable.appicon_youtube, "YouTube", Color.rgb(220, 38, 38), false, true),
            new Command("moonlight_toggle", R.drawable.appicon_moonlight, "Moonlight", Color.rgb(14, 165, 233), false, true),
            new Command("open_stremio_tv", R.drawable.appicon_stremio, "Stremio", Color.rgb(115, 91, 255), false, true)
    };

    private final Command[] tvControlCommands = new Command[] {
            new Command("tv_power_toggle", R.drawable.ic_power_shutdown_bg, "Power", Color.rgb(220, 38, 38), false, true),
            new Command("tv_force_reboot", R.drawable.ic_power_reboot_bg, "Reboot", Color.rgb(190, 18, 60), false, true),
            new Command("tv_mute", R.drawable.ic_terminal_send_bg, "Mute", Color.rgb(234, 179, 8), false, true),
            new Command("tv_set_volume", R.drawable.ic_power_wake_bg, "Volume", Color.rgb(34, 197, 94), false, true),
            new Command("tv_home", R.drawable.ic_launcher, "Home", Color.rgb(14, 165, 233), false, true)
    };

    private final Command[] applicationCommands = new Command[] {
            new Command("restart_codex", R.drawable.appicon_codex, "Restart Codex", Color.rgb(245, 158, 11)),
            new Command("open_wand_wemod", R.drawable.appicon_wand_wemod, "Open Wand / WeMod", Color.rgb(217, 119, 6)),
            new Command("toggle_openspeedy", R.drawable.appicon_openspeedy, "OpenSpeedy", Color.rgb(14, 165, 233)),
            new Command("toggle_qbittorrent", R.drawable.appicon_qbittorrent, "qBittorrent", Color.rgb(37, 99, 235))
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        config = loadConfig();
        buildUi();
        startStatusPolling();
        handleIntent(getIntent());
    }

    @Override
    protected void onResume() {
        super.onResume();
        checkPcStatusAsync();
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        handleIntent(intent);
    }

    @Override
    protected void onDestroy() {
        destroyed = true;
        statusHandler.removeCallbacksAndMessages(null);
        super.onDestroy();
    }

    private void buildUi() {
        ScrollView scroll = new ScrollView(this);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(14), dp(18), dp(14), dp(112));
        GradientDrawable rootBackground = new GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                new int[] { Color.rgb(5, 11, 22), Color.rgb(10, 27, 47), Color.rgb(8, 17, 31) });
        root.setBackground(rootBackground);
        scroll.setClipToPadding(false);
        scroll.addView(root);

        LinearLayout statusRow = new LinearLayout(this);
        statusRow.setOrientation(LinearLayout.HORIZONTAL);
        statusRow.setGravity(Gravity.CENTER);
        statusRow.setPadding(0, 0, 0, dp(8));
        pcStatusDot = new View(this);
        pcStatusDot.setContentDescription("PC status: checking");
        LinearLayout.LayoutParams dotParams = new LinearLayout.LayoutParams(dp(14), dp(14));
        dotParams.setMargins(0, 0, dp(7), 0);
        statusRow.addView(pcStatusDot, dotParams);

        pcStatusLabel = new TextView(this);
        pcStatusLabel.setText("PC");
        pcStatusLabel.setTextColor(Color.rgb(203, 213, 225));
        pcStatusLabel.setTextSize(12);
        pcStatusLabel.setTypeface(Typeface.DEFAULT_BOLD);
        statusRow.addView(pcStatusLabel, new LinearLayout.LayoutParams(-2, -2));
        root.addView(statusRow, new LinearLayout.LayoutParams(-1, -2));
        updatePcIndicator(false);

        TextView title = new TextView(this);
        title.setText("Remote Command Center");
        title.setTextColor(Color.WHITE);
        title.setTextSize(26);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        title.setGravity(Gravity.CENTER);
        root.addView(title, new LinearLayout.LayoutParams(-1, -2));

        TextView subtitle = new TextView(this);
        subtitle.setText("Fast, reliable control for your PC and TV");
        subtitle.setTextColor(Color.rgb(125, 211, 252));
        subtitle.setTextSize(12);
        subtitle.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams subtitleParams = new LinearLayout.LayoutParams(-1, -2);
        subtitleParams.setMargins(0, dp(3), 0, 0);
        root.addView(subtitle, subtitleParams);

        status = new TextView(this);
        status.setText("Ready.");
        status.setTextColor(Color.rgb(203, 213, 225));
        status.setTextSize(14);
        status.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams statusParams = new LinearLayout.LayoutParams(-1, -2);
        statusParams.setMargins(0, dp(8), 0, dp(14));
        root.addView(status, statusParams);

        addPowerStrip(root);
        addSection(root, "Controls", "Windows repair, terminal, and display controls", systemCommands);
        addTerminalPanel(root);
        addTvSection(root);
        if (applicationCommands.length > 0) {
            addSection(root, "Applications", "Bring tools forward or send them back to tray", applicationCommands);
        }

        setContentView(scroll);
    }

    private void addPowerStrip(LinearLayout root) {
        TextView title = new TextView(this);
        title.setText("Power");
        title.setTextColor(Color.WHITE);
        title.setTextSize(18);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(-1, -2);
        titleParams.setMargins(0, dp(12), 0, dp(6));
        root.addView(title, titleParams);

        HorizontalScrollView scroller = new HorizontalScrollView(this);
        scroller.setHorizontalScrollBarEnabled(false);
        scroller.setFillViewport(false);
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(dp(2), dp(4), dp(2), dp(8));
        scroller.addView(row, new HorizontalScrollView.LayoutParams(-2, -2));
        root.addView(scroller, new LinearLayout.LayoutParams(-1, -2));

        for (Command command : powerCommands) {
            LinearLayout item = new LinearLayout(this);
            item.setOrientation(LinearLayout.VERTICAL);
            item.setGravity(Gravity.CENTER);

            Button button = new Button(this);
            button.setAllCaps(false);
            button.setText(shortPowerLabel(command.id));
            button.setContentDescription(command.label);
            button.setTextColor(Color.WHITE);
            button.setTextSize(9);
            button.setTypeface(Typeface.DEFAULT_BOLD);
            button.setGravity(Gravity.CENTER);
            button.setMinHeight(0);
            button.setMinWidth(0);
            button.setPadding(dp(4), 0, dp(4), 0);
            button.setElevation(dp(8));
            Drawable powerIconBg = getDrawable(command.iconRes);
            button.setBackground(powerIconBg != null ? powerIconBg : remoteButtonBg(command.color));
            button.setOnClickListener(v -> sendCommand(command));
            buttons.add(button);

            LinearLayout.LayoutParams buttonParams = new LinearLayout.LayoutParams(dp(50), dp(50));
            item.addView(button, buttonParams);

            TextView label = new TextView(this);
            label.setText(shortPowerCaption(command.id));
            label.setTextColor(Color.rgb(203, 213, 225));
            label.setTextSize(8);
            label.setGravity(Gravity.CENTER);
            label.setMaxLines(1);
            LinearLayout.LayoutParams labelParams = new LinearLayout.LayoutParams(dp(56), -2);
            labelParams.setMargins(0, dp(4), 0, 0);
            item.addView(label, labelParams);

            LinearLayout.LayoutParams itemParams = new LinearLayout.LayoutParams(dp(58), -2);
            itemParams.setMargins(0, 0, dp(1), 0);
            row.addView(item, itemParams);
        }
    }

    private void addSection(LinearLayout root, String heading, String subheading, Command[] sectionCommands) {
        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.VERTICAL);
        header.setPadding(dp(12), dp(10), dp(12), dp(8));
        header.setBackground(sectionBg());
        LinearLayout.LayoutParams headerParams = new LinearLayout.LayoutParams(-1, -2);
        headerParams.setMargins(0, dp(8), 0, dp(8));
        root.addView(header, headerParams);

        TextView title = new TextView(this);
        title.setText(heading);
        title.setTextColor(Color.WHITE);
        title.setTextSize(18);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        header.addView(title, new LinearLayout.LayoutParams(-1, -2));

        TextView subtitle = new TextView(this);
        subtitle.setText(subheading);
        subtitle.setTextColor(Color.rgb(148, 163, 184));
        subtitle.setTextSize(12);
        LinearLayout.LayoutParams subtitleParams = new LinearLayout.LayoutParams(-1, -2);
        subtitleParams.setMargins(0, dp(2), 0, 0);
        header.addView(subtitle, subtitleParams);

        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(2);
        root.addView(grid, new LinearLayout.LayoutParams(-1, -2));

        for (Command command : sectionCommands) {
            LinearLayout item = new LinearLayout(this);
            item.setGravity(Gravity.CENTER);
            item.setOrientation(LinearLayout.VERTICAL);

            RoundIconTextView button = new RoundIconTextView(this, command.iconRes, command.color);
            button.setClickable(true);
            button.setFocusable(true);
            button.setAllCaps(false);
            button.setText(command.label);
            button.setContentDescription(command.label);
            button.setTextSize(command.label.length() > 16 ? 10 : 11);
            button.setTextColor(Color.WHITE);
            button.setTypeface(Typeface.DEFAULT_BOLD);
            button.setGravity(Gravity.CENTER);
            button.setMaxLines(3);
            button.setMinHeight(0);
            button.setMinWidth(0);
            button.setPadding(dp(8), dp(6), dp(8), dp(6));
            button.setShadowLayer(dp(4), 0, dp(2), Color.argb(225, 0, 0, 0));
            button.setElevation(dp(8));
            if (android.os.Build.VERSION.SDK_INT >= 23) {
                button.setForeground(getDrawable(android.R.drawable.list_selector_background));
            }
            button.setOnClickListener(v -> sendCommand(command));
            buttons.add(button);
            item.addView(button, new LinearLayout.LayoutParams(dp(92), dp(92)));

            GridLayout.LayoutParams params = new GridLayout.LayoutParams();
            params.width = 0;
            params.height = dp(108);
            params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
            params.setMargins(dp(5), dp(5), dp(5), dp(5));
            grid.addView(item, params);
        }
    }

    private void addTvSection(LinearLayout root) {
        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.VERTICAL);
        header.setPadding(dp(12), dp(10), dp(12), dp(8));
        header.setBackground(sectionBg());
        LinearLayout.LayoutParams headerParams = new LinearLayout.LayoutParams(-1, -2);
        headerParams.setMargins(0, dp(8), 0, dp(8));
        root.addView(header, headerParams);

        TextView title = new TextView(this);
        title.setText("TV");
        title.setTextColor(Color.WHITE);
        title.setTextSize(18);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        header.addView(title, new LinearLayout.LayoutParams(-1, -2));

        TextView subtitle = new TextView(this);
        subtitle.setText("Streaming controls for the Samsung TV");
        subtitle.setTextColor(Color.rgb(148, 163, 184));
        subtitle.setTextSize(12);
        LinearLayout.LayoutParams subtitleParams = new LinearLayout.LayoutParams(-1, -2);
        subtitleParams.setMargins(0, dp(2), 0, 0);
        header.addView(subtitle, subtitleParams);

        LinearLayout controlsRow = new LinearLayout(this);
        controlsRow.setOrientation(LinearLayout.HORIZONTAL);
        controlsRow.setGravity(Gravity.CENTER);
        controlsRow.setPadding(dp(2), dp(1), dp(2), dp(5));
        root.addView(controlsRow, new LinearLayout.LayoutParams(-1, -2));

        addTvControlRow(controlsRow);

        LinearLayout appRow = new LinearLayout(this);
        appRow.setOrientation(LinearLayout.HORIZONTAL);
        appRow.setGravity(Gravity.CENTER);
        root.addView(appRow, new LinearLayout.LayoutParams(-1, -2));

        for (Command command : tvCommands) {
            LinearLayout item = new LinearLayout(this);
            item.setGravity(Gravity.CENTER);
            item.setOrientation(LinearLayout.VERTICAL);

            RoundIconTextView button = new RoundIconTextView(this, command.iconRes, command.color);
            button.setClickable(true);
            button.setFocusable(true);
            button.setAllCaps(false);
            button.setText(command.label);
            button.setContentDescription(command.label);
            button.setTextSize(command.label.length() > 16 ? 10 : 11);
            button.setTextColor(Color.WHITE);
            button.setTypeface(Typeface.DEFAULT_BOLD);
            button.setGravity(Gravity.CENTER);
            button.setMaxLines(3);
            button.setMinHeight(0);
            button.setMinWidth(0);
            button.setPadding(dp(6), dp(6), dp(6), dp(6));
            button.setShadowLayer(dp(4), 0, dp(2), Color.argb(225, 0, 0, 0));
            button.setElevation(dp(8));
            if (android.os.Build.VERSION.SDK_INT >= 23) {
                button.setForeground(getDrawable(android.R.drawable.list_selector_background));
            }
            button.setOnClickListener(v -> sendCommand(command));
            buttons.add(button);
            item.addView(button, new LinearLayout.LayoutParams(dp(82), dp(82)));

            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, dp(98), 1f);
            params.setMargins(dp(2), dp(4), dp(2), dp(4));
            appRow.addView(item, params);
        }
    }

    private void addTvControlRow(LinearLayout controlsRow) {
        for (Command command : tvControlCommands) {
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(0, dp(64), 1f);
            params.setMargins(dp(3), 0, dp(3), 0);
            controlsRow.addView(makeSmallTvButton(command), params);
        }
    }

    private Button makeSmallTvButton(Command command) {
        Button button = new Button(this);
        button.setAllCaps(false);
        button.setText(command.label);
        button.setContentDescription(command.label);
        button.setTextColor(Color.WHITE);
        button.setTextSize(command.label.length() > 6 ? 9 : 10);
        button.setTypeface(Typeface.DEFAULT_BOLD);
        button.setGravity(Gravity.CENTER);
        button.setMinHeight(0);
        button.setMinWidth(0);
        button.setPadding(dp(2), 0, dp(2), 0);
        button.setBackground(buttonBg(command.color));
        if ("tv_set_volume".equals(command.id)) {
            button.setOnClickListener(v -> showTvVolumeDialog());
        } else {
            button.setOnClickListener(v -> sendCommand(command));
        }
        buttons.add(button);
        return button;
    }

    private void addTerminalPanel(LinearLayout root) {
        LinearLayout panel = new LinearLayout(this);
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setPadding(dp(12), dp(10), dp(12), dp(12));
        panel.setBackground(sectionBg());
        LinearLayout.LayoutParams panelParams = new LinearLayout.LayoutParams(-1, -2);
        panelParams.setMargins(0, dp(8), 0, dp(8));
        root.addView(panel, panelParams);

        TextView title = new TextView(this);
        title.setText("PC Terminal");
        title.setTextColor(Color.WHITE);
        title.setTextSize(18);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        panel.addView(title, new LinearLayout.LayoutParams(-1, -2));

        terminalInput = new EditText(this);
        terminalInput.setSingleLine(true);
        terminalInput.setHint("Type a PowerShell line for the PC");
        terminalInput.setHintTextColor(Color.rgb(148, 163, 184));
        terminalInput.setTextColor(Color.WHITE);
        terminalInput.setTextSize(16);
        terminalInput.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS | InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD);
        terminalInput.setImeOptions(EditorInfo.IME_ACTION_SEND);
        terminalInput.setOnEditorActionListener((view, actionId, event) -> {
            boolean send = actionId == EditorInfo.IME_ACTION_SEND ||
                    (event != null && event.getKeyCode() == KeyEvent.KEYCODE_ENTER && event.getAction() == KeyEvent.ACTION_UP);
            if (send) {
                sendTerminalLine();
                return true;
            }
            return false;
        });
        LinearLayout.LayoutParams inputParams = new LinearLayout.LayoutParams(-1, dp(52));
        inputParams.setMargins(0, dp(8), 0, 0);
        panel.addView(terminalInput, inputParams);

        Button send = new Button(this);
        send.setAllCaps(false);
        send.setText("Send to PC Terminal");
        send.setTextColor(Color.WHITE);
        send.setTextSize(15);
        send.setTypeface(Typeface.DEFAULT_BOLD);
        Drawable sendBg = getDrawable(R.drawable.ic_terminal_send_bg);
        send.setBackground(sendBg != null ? sendBg : buttonBg(Color.rgb(22, 163, 74)));
        send.setOnClickListener(v -> sendTerminalLine());
        LinearLayout.LayoutParams sendParams = new LinearLayout.LayoutParams(-1, dp(52));
        sendParams.setMargins(0, dp(8), 0, 0);
        panel.addView(send, sendParams);
    }

    private GradientDrawable buttonBg(int color) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(dp(8));
        drawable.setStroke(dp(1), Color.argb(100, 255, 255, 255));
        return drawable;
    }

    private GradientDrawable remoteButtonBg(int color) {
        GradientDrawable drawable = new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,
                new int[] { Color.argb(255, Math.min(255, Color.red(color) + 36), Math.min(255, Color.green(color) + 36), Math.min(255, Color.blue(color) + 36)), color });
        drawable.setShape(GradientDrawable.OVAL);
        drawable.setStroke(dp(3), Color.argb(210, 255, 255, 255));
        return drawable;
    }

    private String shortPowerLabel(String id) {
        if ("sleep_pc".equals(id)) return "Sleep";
        if ("wake_pc".equals(id)) return "Wake";
        if ("force_reboot_now".equals(id)) return "Reboot";
        if ("shutdown_pc".equals(id)) return "Power";
        if ("reboot_to_bios".equals(id)) return "BIOS";
        if ("refresh2_logoff".equals(id)) return "Login";
        return "Go";
    }

    private String shortPowerCaption(String id) {
        if ("sleep_pc".equals(id)) return "sleep";
        if ("wake_pc".equals(id)) return "wake";
        if ("force_reboot_now".equals(id)) return "reboot";
        if ("shutdown_pc".equals(id)) return "shutdown";
        if ("reboot_to_bios".equals(id)) return "BIOS";
        if ("refresh2_logoff".equals(id)) return "re-login";
        return "power";
    }

    private GradientDrawable sectionBg() {
        GradientDrawable drawable = new GradientDrawable(GradientDrawable.Orientation.LEFT_RIGHT,
                new int[] { Color.rgb(15, 23, 42), Color.rgb(30, 41, 59) });
        drawable.setCornerRadius(dp(8));
        drawable.setStroke(dp(1), Color.argb(100, 148, 163, 184));
        return drawable;
    }

    private JSONObject loadConfig() {
        try (InputStream in = getResources().openRawResource(getResources().getIdentifier("rescue_config", "raw", getPackageName()))) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buffer = new byte[4096];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
            return new JSONObject(out.toString("UTF-8"));
        } catch (Exception e) {
            throw new IllegalStateException("Unable to load config", e);
        }
    }

    private void sendCommand(Command command) {
        if ("wake_pc".equals(command.id)) {
            if (!wakeSendInFlight.compareAndSet(false, true)) {
                setStatusText("Wake is already running...");
                return;
            }
            startWakeSend("Sending Wake...");
            return;
        }
        if ("tv_set_volume".equals(command.id)) {
            showTvVolumeDialog();
            return;
        }
        if ("youtube_tizen".equals(command.id)) {
            sendYoutubeTizen(command);
            return;
        }
        if (isDirectTvRemoteCommand(command.id)) {
            sendDirectTvRemoteCommand(command);
            return;
        }
        AtomicBoolean actionFlight = actionSendInFlight.computeIfAbsent(command.id, ignored -> new AtomicBoolean(false));
        if (!actionFlight.compareAndSet(false, true)) {
            setStatusText("Already sending " + command.label + "...");
            return;
        }
        setStatusText("Sending " + command.label + "...");
        new Thread(() -> {
            try {
                if (command.local) {
                    String result = runLocalCommand(command.id);
                    runOnUiThread(() -> {
                        setStatusText(result);
                        Toast.makeText(this, result, Toast.LENGTH_SHORT).show();
                    });
                    return;
                }

                String nonce = sendCommandViaReceiver(command.id);
                rememberExpectedStateAfterAccepted(command.id);
                checkPcStatusAsync();
                String completion = waitForActionCompletion(nonce, command.label, command.id);
                runOnUiThread(() -> {
                    setStatusText(completion + " (" + nonce.substring(0, 8) + ")");
                    Toast.makeText(this, completion, Toast.LENGTH_SHORT).show();
                });
            } catch (Exception e) {
                runOnUiThread(() -> setStatusText("Failed: " + e.getMessage()));
            } finally {
                actionFlight.set(false);
            }
        }, "rcc-send").start();
    }

    private void sendYoutubeTizen(Command command) {
        AtomicBoolean actionFlight = actionSendInFlight.computeIfAbsent(command.id, ignored -> new AtomicBoolean(false));
        if (!actionFlight.compareAndSet(false, true)) {
            setStatusText("Already launching YouTube...");
            return;
        }
        setStatusText("Launching TizenTube...");
        new Thread(() -> {
            try {
                // Samsung authorizes remote clients by originating device. Opening
                // a socket from Android causes a TV-side approval dialog, so the
                // paired PC controller is the only TV transport for YouTube.
                Log.i(TAG, "TIZENTUBE_RECEIVER_ONLY_DISPATCH");
                String nonce = sendCommandViaReceiver(command.id);
                String completion = waitForActionCompletion(nonce, command.label, command.id);
                runOnUiThread(() -> {
                    setStatusText(completion + " (" + nonce.substring(0, 8) + ")");
                    Toast.makeText(this, completion, Toast.LENGTH_SHORT).show();
                });
            } catch (Exception e) {
                runOnUiThread(() -> setStatusText("TizenTube failed: " + e.getMessage()));
            } finally {
                actionFlight.set(false);
            }
        }, "rcc-youtube-tizen").start();
    }

    private boolean launchTizenBrewDirect() {
        String appId = config.optString("tizenBrewAppId", "xvvl3S1bvH.TizenBrewStandalone");
        try {
            sendSamsungTvAppLaunch(appId);
            Log.i(TAG, "TIZENBREW_DIRECT_LAUNCH sent=true transport=websocket");
            return true;
        } catch (Exception websocketError) {
            String host = config.optString("tvHost", "192.168.1.173");
            String target = "http://" + host + ":8001/api/v2/applications/" + appId;
            boolean sent = postEmpty(target, 900);
            Log.i(TAG, "TIZENBREW_DIRECT_LAUNCH sent=" + sent
                    + " transport=rest websocketError=" + websocketError.getMessage());
            return sent;
        }
    }

    private boolean isTizenBrewVisible() {
        String host = config.optString("tvHost", "192.168.1.173");
        String appId = config.optString("tizenBrewAppId", "xvvl3S1bvH.TizenBrewStandalone");
        JSONObject status = getJson("http://" + host + ":8001/api/v2/applications/" + appId, 650);
        return status != null && status.optBoolean("running", false) && status.optBoolean("visible", false);
    }

    private boolean isTizenTubeConfirmed() {
        if (!isTizenBrewVisible()) return false;
        String host = config.optString("tvHost", "192.168.1.173");
        String body = getText("http://" + host + ":8085/dial/apps/YouTube", 650);
        return body != null && body.contains("<name>YouTube</name>") && body.contains("<state>running</state>");
    }

    private String sendCommandViaReceiver(String action) throws Exception {
        String nonce = nonce();
        long createdAt = System.currentTimeMillis() / 1000L;
        boolean dryRun = false;
        String canonical = "rcc|" + createdAt + "|" + nonce + "|" + dryRun + "|" + action + "|" + CONFIRM;
        String signature = hmac(canonical, config.getString("sharedKey"));

        JSONObject body = new JSONObject();
        body.put("type", "rcc");
        body.put("createdAt", createdAt);
        body.put("nonce", nonce);
        body.put("dryRun", dryRun);
        body.put("action", action);
        body.put("confirm", CONFIRM);
        body.put("signature", signature);

        postCommand(body.toString());
        return nonce;
    }

    private String waitForActionCompletion(String nonce, String label, String action) throws Exception {
        long timeoutMs = "youtube_tizen".equals(action) ? 120000L
                : "moonlight_toggle".equals(action) ? 90000L
                : 45000L;
        long deadline = System.currentTimeMillis() + timeoutMs;
        boolean observed = false;
        while (System.currentTimeMillis() < deadline) {
            JSONArray bases = config.getJSONArray("localBases");
            for (int i = 0; i < bases.length(); i++) {
                JSONObject statusBody = getJson(bases.getString(i) + "/status?nonce="
                        + URLEncoder.encode(nonce, "UTF-8"), 700);
                if (statusBody == null) continue;
                JSONObject actionStatus = statusBody.optJSONObject("actionStatus");
                if (actionStatus == null) continue;
                observed = true;
                String state = actionStatus.optString("state", "");
                if ("completed".equals(state)) return "Completed: " + label;
                if ("skipped".equals(state)) return "Already running: " + label;
                if ("failed".equals(state)) {
                    throw new IllegalStateException(label + " failed: "
                            + actionStatus.optString("message", "unknown error"));
                }
            }
            try {
                Thread.sleep(observed ? 150 : 300);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
                break;
            }
        }
        throw new IllegalStateException("Timed out waiting for " + label + " completion.");
    }

    private boolean isDirectTvRemoteCommand(String id) {
        return "tv_power_toggle".equals(id)
                || "tv_mute".equals(id)
                || "tv_volume_up".equals(id)
                || "tv_volume_down".equals(id)
                || "tv_home".equals(id);
    }

    private String tvKeyForCommand(String id) {
        if ("tv_power_toggle".equals(id) || "tv_force_reboot".equals(id)) return "KEY_POWER";
        if ("tv_mute".equals(id)) return "KEY_MUTE";
        if ("tv_volume_up".equals(id)) return "KEY_VOLUP";
        if ("tv_volume_down".equals(id)) return "KEY_VOLDOWN";
        if ("tv_home".equals(id)) return "KEY_HOME";
        return "KEY_HOME";
    }

    private void showTvVolumeDialog() {
        NumberPicker picker = new NumberPicker(this);
        picker.setMinValue(0);
        picker.setMaxValue(100);
        picker.setWrapSelectorWheel(false);
        picker.setValue(getSharedPreferences(PREFS, MODE_PRIVATE).getInt(KEY_TV_VOLUME, 20));
        final int[] selectedVolume = new int[] { picker.getValue() };
        final int[] lastSentVolume = new int[] { -1 };
        final Runnable[] applyVolume = new Runnable[1];
        applyVolume[0] = () -> {
            int volume = selectedVolume[0];
            if (lastSentVolume[0] == volume) return;
            lastSentVolume[0] = volume;
            sendTvVolumeNumber(volume);
        };
        picker.setOnValueChangedListener((p, oldVal, newVal) -> {
            selectedVolume[0] = newVal;
            statusHandler.removeCallbacks(applyVolume[0]);
            statusHandler.postDelayed(applyVolume[0], 250);
        });

        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("Pick TV volume")
                .setView(picker)
                .setPositiveButton("Set now", null)
                .setNegativeButton("Close", null)
                .create();
        dialog.setOnShowListener(d -> {
            Button positive = dialog.getButton(AlertDialog.BUTTON_POSITIVE);
            positive.setOnClickListener(v -> {
                int volume = picker.getValue();
                selectedVolume[0] = volume;
                statusHandler.removeCallbacks(applyVolume[0]);
                dialog.dismiss();
                applyVolume[0].run();
            });
        });
        dialog.show();
    }

    private void sendTvVolumeNumber(int volume) {
        getSharedPreferences(PREFS, MODE_PRIVATE).edit().putInt(KEY_TV_VOLUME, volume).apply();
        setStatusText("TV volume: " + volume + "...");
        new Thread(() -> {
            try {
                sendCommandViaReceiver("tv_set_volume:" + volume);
                Log.i(TAG, "TV_SET_VOLUME_RECEIVER_ONLY_SENT volume=" + volume);
                runOnUiThread(() -> {
                    setStatusText("TV volume set to " + volume);
                    Toast.makeText(this, "TV volume set to " + volume, Toast.LENGTH_SHORT).show();
                });
            } catch (Exception e) {
                runOnUiThread(() -> setStatusText("TV volume failed: " + e.getMessage()));
            }
        }, "rcc-tv-set-volume").start();
    }

    private void sendDirectTvRemoteCommand(Command command) {
        AtomicBoolean actionFlight = actionSendInFlight.computeIfAbsent(command.id, ignored -> new AtomicBoolean(false));
        if (!actionFlight.compareAndSet(false, true)) {
            setStatusText("Already sending " + command.label + "...");
            return;
        }
        setStatusText("TV: " + command.label + "...");
        new Thread(() -> {
            try {
                if (canTryDirectTv()) {
                    try {
                        String key = tvKeyForCommand(command.id);
                        if ("tv_force_reboot".equals(command.id)) {
                            sendSamsungTvHeldKey(key, 6500);
                        } else {
                            sendSamsungTvKey(key, "Click");
                        }
                        Log.i(TAG, "TV_DIRECT_SENT action=" + command.id + " key=" + key);
                        runOnUiThread(() -> setStatusText("TV sent direct: " + command.label));
                        return;
                    } catch (Exception directError) {
                        markDirectTvFailed();
                        Log.i(TAG, "TV_DIRECT_FAILED action=" + command.id + " error=" + directError.getMessage());
                    }
                }
                String nonce = sendCommandViaReceiver(command.id);
                Log.i(TAG, "TV_RECEIVER_SENT action=" + command.id + " nonce=" + nonce);
                runOnUiThread(() -> setStatusText("TV accepted via PC: " + command.label));
            } catch (Exception e) {
                runOnUiThread(() -> setStatusText("TV failed: " + e.getMessage()));
            } finally {
                actionFlight.set(false);
            }
        }, "rcc-tv-receiver").start();
    }

    private void startTvVolumeHold(Command command) {
        if (!volumeHeld.compareAndSet(false, true)) return;
        setStatusText("TV hold: " + command.label);
        new Thread(() -> {
            try {
                while (volumeHeld.get()) {
                    if (canTryDirectTv()) {
                        try {
                            String key = tvKeyForCommand(command.id);
                            sendSamsungTvKey(key, "Click");
                            Log.i(TAG, "TV_HOLD_DIRECT_SENT action=" + command.id + " key=" + key);
                            Thread.sleep(230);
                            continue;
                        } catch (Exception directError) {
                            markDirectTvFailed();
                            Log.i(TAG, "TV_HOLD_DIRECT_FAILED action=" + command.id + " error=" + directError.getMessage());
                        }
                    }
                    String nonce = sendCommandViaReceiver(command.id);
                    Log.i(TAG, "TV_HOLD_RECEIVER_SENT action=" + command.id + " nonce=" + nonce);
                    Thread.sleep(310);
                }
            } catch (Exception e) {
                runOnUiThread(() -> setStatusText("TV hold failed: " + e.getMessage()));
                volumeHeld.set(false);
            }
        }, "rcc-tv-volume-press").start();
    }

    private void stopTvVolumeHold(Command command) {
        if (!volumeHeld.getAndSet(false)) return;
        setStatusText("TV accepted: " + command.label);
    }

    private boolean canTryDirectTv() {
        // Never open a Samsung remote socket from Android. The TV treats the
        // phone as a distinct client and can show a permission dialog. Route
        // every TV command through the already-paired PC controller instead.
        return false;
    }

    private void markDirectTvFailed() {
        directTvRetryAfterMs.set(System.currentTimeMillis() + 30000);
    }

    private void sendSamsungTvKey(String key, String cmd) throws Exception {
        try (SSLSocket socket = openSamsungTvSocket()) {
            sendSamsungTvFrame(socket, key, cmd);
            Thread.sleep(600);
        }
    }

    private void sendSamsungTvKeySequence(String[] keys, long delayMs) throws Exception {
        try (SSLSocket socket = openSamsungTvSocket()) {
            for (int i = 0; i < keys.length; i++) {
                sendSamsungTvFrame(socket, keys[i], "Click");
                if (i + 1 < keys.length) Thread.sleep(Math.max(120L, delayMs));
            }
            Thread.sleep(750);
        }
    }

    private void sendSamsungTvAppLaunch(String appId) throws Exception {
        try (SSLSocket socket = openSamsungTvSocket()) {
            JSONObject data = new JSONObject();
            data.put("appId", appId);
            data.put("action_type", "NATIVE_LAUNCH");
            JSONObject params = new JSONObject();
            params.put("event", "ed.apps.launch");
            params.put("to", "host");
            params.put("data", data);
            JSONObject body = new JSONObject();
            body.put("method", "ms.channel.emit");
            body.put("params", params);
            writeWebSocketTextFrame(socket.getOutputStream(), body.toString());
            Thread.sleep(1000);
        }
    }

    private void sendSamsungTvHeldKey(String key, long holdMs) throws Exception {
        try (SSLSocket socket = openSamsungTvSocket()) {
            sendSamsungTvFrame(socket, key, "Press");
            Thread.sleep(Math.max(500, holdMs));
            sendSamsungTvFrame(socket, key, "Release");
            Thread.sleep(80);
        }
    }

    private SSLSocket openSamsungTvSocket() throws Exception {
        String host = config.optString("tvHost", "192.168.1.173");
        String clientName = config.optString("tvClientName", "Codex Samsung Remote");
        String token = config.optString("tvToken", "");
        String encodedName = URLEncoder.encode(Base64.getEncoder().encodeToString(clientName.getBytes(StandardCharsets.UTF_8)), "UTF-8");
        String path = "/api/v2/channels/samsung.remote.control?name=" + encodedName;
        if (token.length() > 0) {
            path += "&token=" + URLEncoder.encode(token, "UTF-8");
        }

        SSLContext context = SSLContext.getInstance("TLS");
        context.init(null, new TrustManager[] { new X509TrustManager() {
            @Override public void checkClientTrusted(X509Certificate[] chain, String authType) {}
            @Override public void checkServerTrusted(X509Certificate[] chain, String authType) {}
            @Override public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[0]; }
        }}, new java.security.SecureRandom());
        SSLSocketFactory factory = context.getSocketFactory();
        SSLSocket socket = (SSLSocket) factory.createSocket(host, 8002);
        socket.setSoTimeout(700);
        socket.startHandshake();

        String webSocketKey = Base64.getEncoder().encodeToString(randomBytes(16));
        String request = "GET " + path + " HTTP/1.1\r\n" +
                "Host: " + host + ":8002\r\n" +
                "Upgrade: websocket\r\n" +
                "Connection: Upgrade\r\n" +
                "Sec-WebSocket-Key: " + webSocketKey + "\r\n" +
                "Sec-WebSocket-Version: 13\r\n\r\n";
        OutputStream out = socket.getOutputStream();
        out.write(request.getBytes(StandardCharsets.UTF_8));
        out.flush();

        InputStream in = socket.getInputStream();
        String headers = readHttpHeaders(in);
        String statusLine = headers.split("\\r\\n", 2)[0];
        if (!statusLine.contains("101")) throw new IllegalStateException(statusLine);

        socket.setSoTimeout(1800);
        boolean connected = false;
        long deadline = System.currentTimeMillis() + 1800L;
        while (System.currentTimeMillis() < deadline) {
            String frame = readWebSocketTextFrame(in);
            if (frame != null && frame.contains("\"event\":\"ms.channel.connect\"")) {
                connected = true;
                break;
            }
        }
        if (!connected) throw new IllegalStateException("TV websocket did not confirm ms.channel.connect");
        return socket;
    }

    private String readHttpHeaders(InputStream in) throws Exception {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        int matched = 0;
        while (bytes.size() < 16384) {
            int value = in.read();
            if (value < 0) throw new IllegalStateException("TV closed during websocket handshake");
            bytes.write(value);
            if ((matched == 0 && value == '\r')
                    || (matched == 1 && value == '\n')
                    || (matched == 2 && value == '\r')
                    || (matched == 3 && value == '\n')) {
                matched++;
                if (matched == 4) return bytes.toString("UTF-8");
            } else {
                matched = value == '\r' ? 1 : 0;
            }
        }
        throw new IllegalStateException("TV websocket headers exceeded limit");
    }

    private String readWebSocketTextFrame(InputStream in) throws Exception {
        int first = in.read();
        if (first < 0) throw new IllegalStateException("TV websocket closed before connect");
        int second = in.read();
        if (second < 0) throw new IllegalStateException("Incomplete TV websocket frame");
        int opcode = first & 0x0f;
        long length = second & 0x7f;
        if (length == 126) {
            length = ((long) in.read() << 8) | in.read();
        } else if (length == 127) {
            length = 0;
            for (int i = 0; i < 8; i++) length = (length << 8) | (in.read() & 0xffL);
        }
        byte[] mask = null;
        if ((second & 0x80) != 0) {
            mask = new byte[4];
            readFully(in, mask);
        }
        if (length > 1048576L) throw new IllegalStateException("TV websocket frame too large");
        byte[] payload = new byte[(int) length];
        readFully(in, payload);
        if (mask != null) {
            for (int i = 0; i < payload.length; i++) payload[i] ^= mask[i % 4];
        }
        return opcode == 1 ? new String(payload, StandardCharsets.UTF_8) : null;
    }

    private void readFully(InputStream in, byte[] buffer) throws Exception {
        int offset = 0;
        while (offset < buffer.length) {
            int count = in.read(buffer, offset, buffer.length - offset);
            if (count < 0) throw new IllegalStateException("Incomplete TV websocket payload");
            offset += count;
        }
    }

    private byte[] randomBytes(int count) {
        byte[] bytes = new byte[count];
        random.nextBytes(bytes);
        return bytes;
    }

    private void sendSamsungTvFrame(SSLSocket socket, String key, String cmd) throws Exception {
        JSONObject params = new JSONObject();
        params.put("Cmd", cmd);
        params.put("DataOfCmd", key);
        params.put("Option", "false");
        params.put("TypeOfRemote", "SendRemoteKey");
        JSONObject body = new JSONObject();
        body.put("method", "ms.remote.control");
        body.put("params", params);
        writeWebSocketTextFrame(socket.getOutputStream(), body.toString());
    }

    private void writeWebSocketTextFrame(OutputStream out, String text) throws Exception {
        byte[] payload = text.getBytes(StandardCharsets.UTF_8);
        byte[] mask = randomBytes(4);
        ByteArrayOutputStream frame = new ByteArrayOutputStream();
        frame.write(0x81);
        if (payload.length < 126) {
            frame.write(0x80 | payload.length);
        } else {
            frame.write(0x80 | 126);
            frame.write((payload.length >> 8) & 0xff);
            frame.write(payload.length & 0xff);
        }
        frame.write(mask);
        for (int i = 0; i < payload.length; i++) {
            frame.write(payload[i] ^ mask[i % 4]);
        }
        out.write(frame.toByteArray());
        out.flush();
    }

    private void sendTerminalLine() {
        if (terminalInput == null) return;
        String line = terminalInput.getText().toString();
        if (line.length() == 0) {
            Toast.makeText(this, "Type a PowerShell line first.", Toast.LENGTH_SHORT).show();
            return;
        }
        String encoded = Base64.getUrlEncoder().withoutPadding().encodeToString(line.getBytes(StandardCharsets.UTF_8));
        String action = "terminal_line:" + encoded;
        setBusy(true, "Sending terminal line...");
        new Thread(() -> {
            try {
                String nonce = nonce();
                long createdAt = System.currentTimeMillis() / 1000L;
                boolean dryRun = false;
                String canonical = "rcc|" + createdAt + "|" + nonce + "|" + dryRun + "|" + action + "|" + CONFIRM;
                String signature = hmac(canonical, config.getString("sharedKey"));

                JSONObject body = new JSONObject();
                body.put("type", "rcc");
                body.put("createdAt", createdAt);
                body.put("nonce", nonce);
                body.put("dryRun", dryRun);
                body.put("action", action);
                body.put("confirm", CONFIRM);
                body.put("signature", signature);

                postCommand(body.toString());
                checkPcStatusAsync();
                runOnUiThread(() -> {
                    terminalInput.setText("");
                    setBusy(false, "Sent to PC terminal (" + nonce.substring(0, 8) + ")");
                    Toast.makeText(this, "Sent to PC terminal", Toast.LENGTH_SHORT).show();
                });
            } catch (Exception e) {
                runOnUiThread(() -> setBusy(false, "Terminal send failed: " + e.getMessage()));
            }
        }, "rcc-terminal-send").start();
    }

    private void handleIntent(Intent intent) {
        if (intent == null) return;
        int wakeDelayMs = intent.getIntExtra("wake_delay_ms", -1);
        if (wakeDelayMs >= 0) {
            scheduleWakeBurst(wakeDelayMs);
            return;
        }
        if (!intent.getBooleanExtra("wake_now", false)) return;
        startWakeSend("Sending Wake...");
    }

    private void scheduleWakeBurst(int delayMs) {
        int boundedDelay = Math.max(0, Math.min(delayMs, 300000));
        setStatusText("Wake scheduled in " + boundedDelay + " ms...");
        PowerManager power = (PowerManager) getSystemService(Context.POWER_SERVICE);
        PowerManager.WakeLock delayLock = null;
        if (power != null) {
            delayLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "RemoteCommandCenter:DelayedWake");
            delayLock.acquire(boundedDelay + 180000L);
        }
        PowerManager.WakeLock finalDelayLock = delayLock;
        statusHandler.postDelayed(() -> new Thread(() -> {
            try {
                sendWakeNowAndContinue("Delayed Wake");
            } finally {
                if (finalDelayLock != null && finalDelayLock.isHeld()) finalDelayLock.release();
            }
        }, "rcc-delayed-wake").start(), boundedDelay);
    }

    private String runLocalCommand(String id) throws Exception {
        if ("wireless_debug_toggle".equals(id)) {
            return toggleWirelessDebugging();
        }
        throw new IllegalStateException("Unknown local command: " + id);
    }

    private String toggleWirelessDebugging() {
        try {
            int current = Settings.Global.getInt(getContentResolver(), "adb_wifi_enabled", 0);
            int next = current == 1 ? 0 : 1;
            boolean ok = Settings.Global.putInt(getContentResolver(), "adb_wifi_enabled", next);
            if (!ok) throw new SecurityException("write failed");
            return next == 1 ? "Wireless debugging enabled." : "Wireless debugging disabled.";
        } catch (SecurityException security) {
            openDeveloperOptions();
            return "Wireless debug grant missing; opened Developer Options.";
        } catch (Exception e) {
            openDeveloperOptions();
            return "Wireless debug toggle unavailable; opened Developer Options.";
        }
    }

    private void openDeveloperOptions() {
        try {
            launchFirstPackage(new String[] {
                    "com.michaelovsky.wirelessdebugtoggle",
                    "com.mich.wirelessdebugtoggle"
            }, "Wireless Debug Toggle");
            return;
        } catch (Exception ignored) {
        }
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }

    private void launchFirstPackage(String[] packages, String label) throws Exception {
        PackageManager pm = getPackageManager();
        for (String packageName : packages) {
            Intent intent = pm.getLaunchIntentForPackage(packageName);
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
                startActivity(intent);
                return;
            }
        }
        throw new IllegalStateException(label + " app is not installed.");
    }

    private void setBusy(boolean busy, String text) {
        for (TextView button : buttons) {
            button.setEnabled(!busy);
        }
        status.setText(text);
    }

    private void setStatusText(String text) {
        status.setText(text);
    }

    private void startStatusPolling() {
        statusHandler.removeCallbacks(statusPoller);
        statusHandler.post(statusPoller);
    }

    private void checkPcStatusAsync() {
        new Thread(() -> {
            boolean ready = canReachPcStatus();
            runOnUiThread(() -> updatePcIndicator(ready));
        }, "rcc-status").start();
    }

    private boolean canReachPcStatus() {
        try {
            JSONArray bases = config.getJSONArray("localBases");
            for (int i = 0; i < bases.length(); i++) {
                String error = postJson(bases.getString(i) + "/status", "{}", 380);
                if (error == null) return true;
            }
        } catch (Exception ignored) {
        }
        return false;
    }

    private void rememberExpectedStateAfterAccepted(String commandId) {
        if ("shutdown_pc".equals(commandId) || "force_reboot_now".equals(commandId) || "reboot_to_bios".equals(commandId)) {
            setExpectedPcState(STATE_OFF_OR_UNKNOWN);
        } else if ("sleep_pc".equals(commandId) || "sleep_toggle".equals(commandId) || "hibernate_pc".equals(commandId) || "hibernate_toggle".equals(commandId)) {
            setExpectedPcState(STATE_SLEEPING);
        } else {
            setExpectedPcState(STATE_READY);
        }
    }

    private void setExpectedPcState(String state) {
        getSharedPreferences(PREFS, MODE_PRIVATE).edit().putString(KEY_EXPECTED_PC_STATE, state).apply();
    }

    private String getExpectedPcState() {
        SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        return prefs.getString(KEY_EXPECTED_PC_STATE, STATE_OFF_OR_UNKNOWN);
    }

    private void updatePcIndicator(boolean ready) {
        if (pcStatusDot == null || pcStatusLabel == null) return;
        int color;
        String label;
        String description;
        if (ready) {
            setExpectedPcState(STATE_READY);
            color = Color.rgb(34, 197, 94);
            label = "PC ready";
            description = "PC status: ready";
        } else if (STATE_SLEEPING.equals(getExpectedPcState())) {
            color = Color.rgb(250, 204, 21);
            label = "PC sleep";
            description = "PC status: sleep or hibernate";
        } else {
            color = Color.rgb(239, 68, 68);
            label = "PC off";
            description = "PC status: off or unreachable";
        }
        pcStatusDot.setBackground(statusDot(color));
        pcStatusDot.setContentDescription(description);
        pcStatusLabel.setText(label);
    }

    private GradientDrawable statusDot(int color) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setShape(GradientDrawable.OVAL);
        drawable.setColor(color);
        drawable.setStroke(dp(1), Color.argb(180, 255, 255, 255));
        return drawable;
    }

    private void postCommand(String json) throws Exception {
        String localError = postToAnyLocal(json);
        if (localError == null) return;
        String relayError = postToAnyRelay(json);
        if (relayError == null) return;
        throw new IllegalStateException(localError + "; " + relayError);
    }

    private String postToAnyLocal(String json) {
        try {
            JSONArray bases = config.getJSONArray("localBases");
            List<String> failures = new ArrayList<>();
            for (int i = 0; i < bases.length(); i++) {
                String base = bases.getString(i);
                String error = postJson(base + "/action", json, 620);
                if (error == null) return null;
                failures.add(base + ": " + error);
            }
            return "Local failed: " + failures;
        } catch (Exception e) {
            return "Local failed: " + e.getMessage();
        }
    }

    private String postToAnyRelay(String json) {
        try {
            long now = System.currentTimeMillis();
            long retryAfter = relayRetryAfterMs.get();
            if (now < retryAfter) {
                return "Relay skipped: cooldown " + Math.max(1, (retryAfter - now) / 1000) + "s";
            }
            JSONArray bases = config.getJSONArray("relayBases");
            List<String> failures = new ArrayList<>();
            String topic = config.getString("commandTopic");
            for (int i = 0; i < bases.length(); i++) {
                String url = bases.getString(i) + "/" + topic;
                String error = postJson(url, json, 900);
                if (error == null) return null;
                failures.add(url + ": " + error);
            }
            relayRetryAfterMs.set(System.currentTimeMillis() + 60000);
            return "Relay failed: " + failures;
        } catch (Exception e) {
            return "Relay failed: " + e.getMessage();
        }
    }

    private String postJson(String target, String json, int timeoutMs) {
        HttpURLConnection connection = null;
        try {
            URL url = new URL(target);
            connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("POST");
            connection.setConnectTimeout(timeoutMs);
            connection.setReadTimeout(timeoutMs);
            connection.setDoOutput(true);
            connection.setRequestProperty("Content-Type", "application/json");
            byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
            connection.setFixedLengthStreamingMode(bytes.length);
            try (OutputStream out = connection.getOutputStream()) {
                out.write(bytes);
            }
            int code = connection.getResponseCode();
            if (code >= 200 && code < 300) return null;
            return "HTTP " + code;
        } catch (Exception e) {
            return e.getMessage();
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    private boolean postEmpty(String target, int timeoutMs) {
        HttpURLConnection connection = null;
        try {
            connection = (HttpURLConnection) new URL(target).openConnection();
            connection.setRequestMethod("POST");
            connection.setConnectTimeout(timeoutMs);
            connection.setReadTimeout(timeoutMs);
            connection.setDoOutput(true);
            connection.setRequestProperty("Content-Type", "application/json");
            byte[] bytes = "{}".getBytes(StandardCharsets.UTF_8);
            connection.setFixedLengthStreamingMode(bytes.length);
            try (OutputStream out = connection.getOutputStream()) {
                out.write(bytes);
            }
            int code = connection.getResponseCode();
            return code >= 200 && code < 300;
        } catch (Exception e) {
            Log.i(TAG, "HTTP_POST_EMPTY_FAILED target=" + target + " error=" + e.getMessage());
            return false;
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    private String getText(String target, int timeoutMs) {
        HttpURLConnection connection = null;
        try {
            connection = (HttpURLConnection) new URL(target).openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(timeoutMs);
            connection.setReadTimeout(timeoutMs);
            int code = connection.getResponseCode();
            if (code < 200 || code >= 300) return null;
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(connection.getInputStream(), StandardCharsets.UTF_8))) {
                StringBuilder body = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) body.append(line);
                return body.toString();
            }
        } catch (Exception ignored) {
            return null;
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    private JSONObject getJson(String target, int timeoutMs) {
        HttpURLConnection connection = null;
        try {
            connection = (HttpURLConnection) new URL(target).openConnection();
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(timeoutMs);
            connection.setReadTimeout(timeoutMs);
            int code = connection.getResponseCode();
            if (code < 200 || code >= 300) return null;
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(connection.getInputStream(), StandardCharsets.UTF_8))) {
                StringBuilder body = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) body.append(line);
                return new JSONObject(body.toString());
            }
        } catch (Exception ignored) {
            return null;
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    private int sendWakePackets() {
        int sent = 0;
        try {
            JSONArray macs = config.optJSONArray("wakeMacs");
            JSONArray broadcasts = config.optJSONArray("wakeBroadcasts");
            JSONArray hosts = config.optJSONArray("wakeHosts");
            JSONArray ports = config.optJSONArray("wakePorts");
            if (macs == null) return 0;
            for (int i = 0; i < macs.length(); i++) {
                byte[] packet = wolPacket(macs.getString(i));
                sent += sendWakePacketTargets(packet, broadcasts, ports, true);
                sent += sendWakePacketTargets(packet, hosts, ports, false);
            }
        } catch (Exception ignored) {
        }
        return sent;
    }

    private int sendWakePacketTargets(byte[] packet, JSONArray targets, JSONArray ports, boolean broadcast) {
        int sent = 0;
        if (targets == null) return 0;
        try (DatagramSocket socket = new DatagramSocket()) {
            socket.setBroadcast(broadcast);
            for (int j = 0; j < targets.length(); j++) {
                if (ports == null) {
                    sendWakeDatagram(socket, packet, targets.getString(j), 9);
                    sent++;
                } else {
                    for (int k = 0; k < ports.length(); k++) {
                        sendWakeDatagram(socket, packet, targets.getString(j), ports.getInt(k));
                        sent++;
                    }
                }
            }
        } catch (Exception ignored) {
        }
        return sent;
    }

    private void sendWakeDatagram(DatagramSocket socket, byte[] packet, String host, int port) throws Exception {
        DatagramPacket datagram = new DatagramPacket(packet, packet.length, InetAddress.getByName(host), port);
        socket.send(datagram);
    }

    private void startWakeSend(String text) {
        setStatusText(text);
        new Thread(() -> {
            try {
                sendWakeNowAndContinue("Immediate Wake");
            } finally {
                wakeSendInFlight.set(false);
            }
        }, "rcc-wake").start();
    }

    private void sendWakeNowAndContinue(String label) {
        int packets = sendWakePacketsBurst(3, 0, 0);
        String controlledWake = signalControlledWake();
        boolean ready = false;
        for (int attempt = 0; attempt < 40; attempt++) {
            if (canReachPcStatus()) {
                ready = true;
                break;
            }
            packets += sendWakePacketsBurst(1, 0, 0);
            try {
                Thread.sleep(500);
            } catch (InterruptedException ignored) {
                Thread.currentThread().interrupt();
                break;
            }
        }
        final boolean pcReady = ready;
        final int packetsSent = packets;
        runOnUiThread(() -> updatePcIndicator(pcReady));
        String message = label + " sent: " + packetsSent + " WOL packets; " + controlledWake
                + (pcReady ? "; PC ready." : "; receiver not yet reachable.");
        runOnUiThread(() -> {
            setStatusText(message);
            Toast.makeText(this, label + " sent", Toast.LENGTH_SHORT).show();
        });
    }

    private String signalControlledWake() {
        try {
            String json = signedCommandJson("wake_pc");
            postCommand(json);
            rememberExpectedStateAfterAccepted("wake_pc");
            return "controlled wake signaled";
        } catch (Exception e) {
            return "WOL-only fallback";
        }
    }

    private String signedCommandJson(String action) throws Exception {
        String nonce = nonce();
        long createdAt = System.currentTimeMillis() / 1000L;
        boolean dryRun = false;
        String canonical = "rcc|" + createdAt + "|" + nonce + "|" + dryRun + "|" + action + "|" + CONFIRM;
        String signature = hmac(canonical, config.getString("sharedKey"));

        JSONObject body = new JSONObject();
        body.put("type", "rcc");
        body.put("createdAt", createdAt);
        body.put("nonce", nonce);
        body.put("dryRun", dryRun);
        body.put("action", action);
        body.put("confirm", CONFIRM);
        body.put("signature", signature);
        return body.toString();
    }

    private int sendWakePacketsBurst(int denseLoops, int pacedLoops, int pacedDelayMs) {
        WifiManager.MulticastLock multicastLock = null;
        WifiManager.WifiLock wifiLock = null;
        PowerManager.WakeLock wakeLock = null;
        int sent = 0;
        try {
            WifiManager wifi = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wifi != null) {
                wifiLock = wifi.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "RemoteCommandCenterWakeWifi");
                wifiLock.setReferenceCounted(false);
                wifiLock.acquire();
                multicastLock = wifi.createMulticastLock("RemoteCommandCenterWake");
                multicastLock.setReferenceCounted(false);
                multicastLock.acquire();
            }
            PowerManager power = (PowerManager) getSystemService(Context.POWER_SERVICE);
            if (power != null) {
                wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "RemoteCommandCenter:Wake");
                wakeLock.acquire(120000);
            }

            for (int i = 0; i < denseLoops; i++) {
                sent += sendWakePackets();
            }
            for (int i = 0; i < pacedLoops; i++) {
                sent += sendWakePackets();
                try {
                    Thread.sleep(pacedDelayMs);
                } catch (InterruptedException ignored) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        } finally {
            if (multicastLock != null && multicastLock.isHeld()) multicastLock.release();
            if (wifiLock != null && wifiLock.isHeld()) wifiLock.release();
            if (wakeLock != null && wakeLock.isHeld()) wakeLock.release();
        }
        return sent;
    }

    private byte[] wolPacket(String mac) {
        String clean = mac.replace(":", "").replace("-", "");
        byte[] macBytes = new byte[6];
        for (int i = 0; i < 6; i++) {
            macBytes[i] = (byte) Integer.parseInt(clean.substring(i * 2, i * 2 + 2), 16);
        }
        byte[] packet = new byte[102];
        for (int i = 0; i < 6; i++) packet[i] = (byte) 0xFF;
        for (int i = 1; i <= 16; i++) {
            System.arraycopy(macBytes, 0, packet, i * 6, 6);
        }
        return packet;
    }

    private String nonce() {
        byte[] bytes = new byte[18];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hmac(String text, String key) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        return Base64.getUrlEncoder().withoutPadding().encodeToString(mac.doFinal(text.getBytes(StandardCharsets.UTF_8)));
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }
}
