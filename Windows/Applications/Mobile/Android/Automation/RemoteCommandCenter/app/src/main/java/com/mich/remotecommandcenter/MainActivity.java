package com.mich.remotecommandcenter;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.provider.Settings;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public class MainActivity extends Activity {
    private static final String CONFIRM = "REMOTE_COMMAND_CENTER_EXECUTE";
    private static final String PREFS = "remote_command_center_state";
    private static final String KEY_EXPECTED_PC_STATE = "expected_pc_state";
    private static final String STATE_READY = "ready";
    private static final String STATE_SLEEPING = "sleeping";
    private static final String STATE_OFF_OR_UNKNOWN = "off_or_unknown";

    private final SecureRandom random = new SecureRandom();
    private JSONObject config;
    private View pcStatusDot;
    private TextView pcStatusLabel;
    private TextView status;
    private final ArrayList<Button> buttons = new ArrayList<>();
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

        Command(String id, int iconRes, String label, int color) {
            this(id, iconRes, label, color, false);
        }

        Command(String id, int iconRes, String label, int color, boolean local) {
            this.id = id;
            this.iconRes = iconRes;
            this.label = label;
            this.color = color;
            this.local = local;
        }
    }

    private final Command[] systemCommands = new Command[] {
            new Command("force_reboot_now", R.drawable.img_force_reboot, "Force reboot now", Color.rgb(239, 68, 68)),
            new Command("sleep_pc", R.drawable.img_sleep_wake, "Sleep", Color.rgb(99, 102, 241)),
            new Command("hibernate_pc", R.drawable.img_hibernate, "Hibernate", Color.rgb(79, 70, 229)),
            new Command("wake_pc", R.drawable.img_wake, "Wake", Color.rgb(20, 184, 166)),
            new Command("shutdown_pc", R.drawable.img_shutdown, "Shut down PC", Color.rgb(220, 38, 38)),
            new Command("restart_explorer", R.drawable.img_explorer, "Restart Explorer", Color.rgb(34, 197, 94)),
            new Command("reboot_to_bios", R.drawable.img_reboot_bios, "Reboot to BIOS", Color.rgb(190, 18, 60)),
            new Command("night_mode_toggle", R.drawable.img_night_mode, "Night mode on/off", Color.rgb(59, 130, 246)),
            new Command("wireless_debug_toggle", R.drawable.img_wireless_debug, "Wireless Debug", Color.rgb(45, 212, 191), true)
    };

    private final Command[] applicationCommands = new Command[] {
            new Command("restart_codex", R.drawable.img_codex, "Restart Codex", Color.rgb(245, 158, 11)),
            new Command("open_wand_wemod", R.drawable.img_wand_wemod, "Open Wand / WeMod", Color.rgb(217, 119, 6)),
            new Command("toggle_openspeedy", R.drawable.img_openspeedy, "OpenSpeedy", Color.rgb(14, 165, 233)),
            new Command("toggle_qbittorrent", R.drawable.img_qbittorrent, "qBittorrent", Color.rgb(37, 99, 235))
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
        root.setPadding(dp(14), dp(18), dp(14), dp(18));
        root.setBackgroundColor(Color.rgb(8, 17, 31));
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

        status = new TextView(this);
        status.setText("Ready.");
        status.setTextColor(Color.rgb(203, 213, 225));
        status.setTextSize(14);
        status.setGravity(Gravity.CENTER);
        LinearLayout.LayoutParams statusParams = new LinearLayout.LayoutParams(-1, -2);
        statusParams.setMargins(0, dp(8), 0, dp(14));
        root.addView(status, statusParams);

        addSection(root, "System", "Power, wake, recovery, Windows controls", systemCommands);
        addSection(root, "Applications", "Bring tools forward or send them back to tray", applicationCommands);

        setContentView(scroll);
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
            Button button = new Button(this);
            button.setAllCaps(false);
            button.setText("");
            button.setContentDescription(command.label);
            button.setTextSize(15);
            button.setTextColor(Color.WHITE);
            button.setTypeface(Typeface.DEFAULT_BOLD);
            button.setGravity(Gravity.CENTER);
            button.setMinHeight(0);
            button.setMinWidth(0);
            button.setPadding(0, 0, 0, 0);
            button.setElevation(dp(3));
            if (android.os.Build.VERSION.SDK_INT >= 23) {
                button.setForeground(getDrawable(android.R.drawable.list_selector_background));
            }
            Drawable icon = getDrawable(command.iconRes);
            if (icon != null) {
                button.setBackground(icon);
            } else {
                button.setBackground(buttonBg(command.color));
            }
            button.setOnClickListener(v -> sendCommand(command));
            buttons.add(button);

            GridLayout.LayoutParams params = new GridLayout.LayoutParams();
            params.width = 0;
            params.height = dp(86);
            params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
            params.setMargins(dp(5), dp(5), dp(5), dp(5));
            grid.addView(button, params);
        }
    }

    private GradientDrawable buttonBg(int color) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(dp(8));
        drawable.setStroke(dp(1), Color.argb(100, 255, 255, 255));
        return drawable;
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
        setBusy(true, "Sending " + command.label + "...");
        new Thread(() -> {
            try {
                if ("wake_pc".equals(command.id)) {
                    setExpectedPcState(STATE_SLEEPING);
                    int packets = sendWakePacketsBurst();
                    checkPcStatusAsync();
                    runOnUiThread(() -> {
                        setBusy(false, "Immediate Wake sent: " + packets + " packets.");
                        Toast.makeText(this, "Immediate Wake sent", Toast.LENGTH_SHORT).show();
                    });
                    return;
                }
                if (command.local) {
                    String result = runLocalCommand(command.id);
                    runOnUiThread(() -> {
                        setBusy(false, result);
                        Toast.makeText(this, result, Toast.LENGTH_SHORT).show();
                    });
                    return;
                }

                String nonce = nonce();
                long createdAt = System.currentTimeMillis() / 1000L;
                boolean dryRun = false;
                String canonical = "rcc|" + createdAt + "|" + nonce + "|" + dryRun + "|" + command.id + "|" + CONFIRM;
                String signature = hmac(canonical, config.getString("sharedKey"));

                JSONObject body = new JSONObject();
                body.put("type", "rcc");
                body.put("createdAt", createdAt);
                body.put("nonce", nonce);
                body.put("dryRun", dryRun);
                body.put("action", command.id);
                body.put("confirm", CONFIRM);
                body.put("signature", signature);

                postCommand(body.toString());
                rememberExpectedStateAfterAccepted(command.id);
                checkPcStatusAsync();
                runOnUiThread(() -> {
                    setBusy(false, "Accepted: " + command.label + " (" + nonce.substring(0, 8) + ")");
                    Toast.makeText(this, "Accepted: " + command.label, Toast.LENGTH_SHORT).show();
                });
            } catch (Exception e) {
                runOnUiThread(() -> setBusy(false, "Failed: " + e.getMessage()));
            }
        }, "rcc-send").start();
    }

    private void handleIntent(Intent intent) {
        if (intent == null || !intent.getBooleanExtra("wake_now", false)) return;
        setBusy(true, "Sending Wake...");
        new Thread(() -> {
            int packets = sendWakePacketsBurst();
            checkPcStatusAsync();
            runOnUiThread(() -> {
                setBusy(false, "Immediate Wake sent: " + packets + " packets.");
                Toast.makeText(this, "Immediate Wake sent", Toast.LENGTH_SHORT).show();
            });
        }, "rcc-intent-wake").start();
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
        for (Button button : buttons) {
            button.setEnabled(!busy);
        }
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
                String error = postJson(bases.getString(i) + "/status", "{}", 520);
                if (error == null) return true;
            }
        } catch (Exception ignored) {
        }
        return false;
    }

    private void rememberExpectedStateAfterAccepted(String commandId) {
        if ("sleep_pc".equals(commandId) || "hibernate_pc".equals(commandId)) {
            setExpectedPcState(STATE_SLEEPING);
        } else if ("shutdown_pc".equals(commandId) || "force_reboot_now".equals(commandId) || "reboot_to_bios".equals(commandId)) {
            setExpectedPcState(STATE_OFF_OR_UNKNOWN);
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
        AtomicBoolean accepted = new AtomicBoolean(false);
        CountDownLatch done = new CountDownLatch(2);
        ConcurrentLinkedQueue<String> errors = new ConcurrentLinkedQueue<>();

        new Thread(() -> {
            try {
                String error = postToAnyLocal(json);
                if (error == null) accepted.set(true); else errors.add(error);
            } finally {
                done.countDown();
            }
        }, "rcc-local").start();

        new Thread(() -> {
            try {
                String error = postToAnyRelay(json);
                if (error == null) accepted.set(true); else errors.add(error);
            } finally {
                done.countDown();
            }
        }, "rcc-relay").start();

        long deadline = System.currentTimeMillis() + 5500;
        while (System.currentTimeMillis() < deadline) {
            if (accepted.get()) return;
            if (done.await(120, TimeUnit.MILLISECONDS) && accepted.get()) return;
        }
        if (!accepted.get()) {
            throw new IllegalStateException(errors.isEmpty() ? "No route accepted command" : errors.peek());
        }
    }

    private String postToAnyLocal(String json) {
        try {
            JSONArray bases = config.getJSONArray("localBases");
            List<String> failures = new ArrayList<>();
            for (int i = 0; i < bases.length(); i++) {
                String base = bases.getString(i);
                String error = postJson(base + "/action", json, 1800);
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
            JSONArray bases = config.getJSONArray("relayBases");
            List<String> failures = new ArrayList<>();
            String topic = config.getString("commandTopic");
            for (int i = 0; i < bases.length(); i++) {
                String url = bases.getString(i) + "/" + topic;
                String error = postJson(url, json, 2200);
                if (error == null) return null;
                failures.add(url + ": " + error);
            }
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

    private int sendWakePacketsBurst() {
        WifiManager.MulticastLock multicastLock = null;
        PowerManager.WakeLock wakeLock = null;
        int sent = 0;
        try {
            WifiManager wifi = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
            if (wifi != null) {
                multicastLock = wifi.createMulticastLock("RemoteCommandCenterWake");
                multicastLock.setReferenceCounted(false);
                multicastLock.acquire();
            }
            PowerManager power = (PowerManager) getSystemService(Context.POWER_SERVICE);
            if (power != null) {
                wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "RemoteCommandCenter:Wake");
                wakeLock.acquire(120000);
            }

            // Front-load a dense burst so the first packets leave immediately,
            // then keep retrying long enough for WAN/NAT paths and NIC wake timing.
            for (int i = 0; i < 180; i++) {
                sent += sendWakePackets();
            }
            for (int i = 0; i < 720; i++) {
                sent += sendWakePackets();
                try {
                    Thread.sleep(85);
                } catch (InterruptedException ignored) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        } finally {
            if (multicastLock != null && multicastLock.isHeld()) multicastLock.release();
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
