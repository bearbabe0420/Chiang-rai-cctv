package com.backendcam.backendcam.service.hls;

import java.io.File;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicReference;

import org.bytedeco.javacv.FFmpegFrameGrabber;
import org.bytedeco.javacv.FFmpegFrameRecorder;
import org.bytedeco.javacv.Frame;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.backendcam.backendcam.model.entity.Camera;
import com.backendcam.backendcam.repository.CameraRepository;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;

@Service
public class HLSStreamService {

    private static final Logger logger = LoggerFactory.getLogger(HLSStreamService.class);
    private static final int MAX_RECONNECT_ATTEMPTS  = 10;
    private static final int RECONNECT_DELAY_MS      = 3000;
    private static final int MAX_FULL_RESTARTS       = 5;
    private static final long FULL_RESTART_DELAY_MS  = 5000;

    // Time-based reconnect: if no frame arrives within this window → reconnect.
    // Set below the camera's firmware idle-drop threshold (~8400ms observed).
    private static final long FRAME_TIMEOUT_MS = 6000;

    // Fixed poll interval — simple, predictable, works for any framerate.
    // 10ms = checks 100x/sec, fast enough for 25fps cameras (frame every 40ms).
    private static final long POLL_SLEEP_MS = 10;

    private final Map<String, Thread>        streamThreads  = new ConcurrentHashMap<>();
    private final Map<String, StreamContext> streamContexts = new ConcurrentHashMap<>();

    @Autowired private CameraRepository      cameraRepository;
    @Autowired private FFmpegGrabberConfig   grabberConfig;
    @Autowired private FFmpegRecorderConfig  recorderConfig;
    @Autowired private StreamResourceManager resourceManager;

    @PostConstruct
    public void init() {
        resourceManager.cleanupAllStreams();
    }

    @PreDestroy
    public void shutdown() {
        logger.info("Shutting down HLSStreamService - stopping all streams...");
        for (String name : streamThreads.keySet().toArray(new String[0])) {
            try { stopHLSStream(name); }
            catch (Exception e) { logger.error("Error stopping stream {} during shutdown: {}", name, e.getMessage()); }
        }
        logger.info("HLSStreamService shutdown complete");
    }

    // ─── Main entry point ─────────────────────────────────────────────────────

    public synchronized String startHLSStream(String RTSPUrl, String streamName) {

        if (streamThreads.containsKey(streamName)) {
            return "/api/hls/" + streamName + "/stream.m3u8";
        }

        File outputDir = new File(resourceManager.getHlsRoot(), streamName);
        if (!outputDir.exists() && !outputDir.mkdirs()) {
            throw new RuntimeException("Failed to create output directory: " + outputDir.getAbsolutePath());
        }

        StreamContext context = new StreamContext();
        AtomicReference<String> currentRtspUrl = new AtomicReference<>(RTSPUrl);

        Thread thread = new Thread(() -> {
            String hlsOutput     = outputDir.getAbsolutePath().replace('\\', '/') + "/stream.m3u8";
            int fullRestartCount = 0;

            // ── Outer loop: full pipeline restart on fatal errors ──────────────
            while (!Thread.currentThread().isInterrupted()
                    && !context.shouldStop
                    && fullRestartCount <= MAX_FULL_RESTARTS) {

                FFmpegFrameGrabber  grabber  = null;
                FFmpegFrameRecorder recorder = null;

                try {
                    // ── Phase 1: grabber ──────────────────────────────────────
                    grabber = grabberConfig.startGrabberWithRetryHD(
                            currentRtspUrl.get(), streamName, context);

                    int width     = grabber.getImageWidth();
                    int height    = grabber.getImageHeight();
                    int cameraFps = (int) grabber.getFrameRate();
                    if (cameraFps <= 0) cameraFps = 15;

                    // ── Phase 2: recorder ─────────────────────────────────────
                    recorder = recorderConfig.startRecorderWithRetryHD(
                            hlsOutput, outputDir, width, height, cameraFps, streamName, context);

                    // ── Phase 2.5: flush stale buffer ─────────────────────────
                    // Grabber accumulates frames during its own init/probe phase.
                    // Discard them so the live loop starts on a fresh frame.
                    logger.info("Stream {} - Flushing stale grabber buffer...", streamName);
                    int flushed = 0;
                    for (int i = 0; i < 45; i++) {
                        if (Thread.currentThread().isInterrupted() || context.shouldStop) break;
                        Frame stale = grabber.grabImage();
                        if (stale == null) break;
                        stale.close();
                        flushed++;
                    }
                    logger.info("Stream {} - Flushed {} stale frames", streamName, flushed);

                    if (flushed == 0) {
                        throw new RuntimeException("Camera connected but sent 0 frames during flush");
                    }

                    // ── Phase 3: live loop (time-based reconnect) ─────────────
                    //
                    // Reconnect is driven purely by elapsed wall-clock time since
                    // the last good frame — not by counting null returns.
                    //
                    // Why time instead of null counting:
                    //   grabImage() returns null both for normal inter-frame gaps
                    //   AND for a dead stream — counting nulls conflates the two.
                    //   Time doesn't lie: if no frame arrives in FRAME_TIMEOUT_MS
                    //   the camera is genuinely silent and needs a reconnect.
                    //
                    // Sleep strategy:
                    //   POLL_SLEEP_MS (10ms) after every iteration, frame or null.
                    //   Simple, predictable, no adaptive math required.
                    // ──────────────────────────────────────────────────────────

                    int  reportedFps       = (int) grabber.getFrameRate();
                    if (reportedFps <= 0) reportedFps = 15;

                    long lastFrameTime     = System.currentTimeMillis();
                    long frameCount        = 0;
                    long lastLogTime       = System.currentTimeMillis();
                    int  reconnectAttempts = 0;

                    logger.info("Stream {} - Live loop started | {}fps | timeout {}ms | poll {}ms",
                            streamName, reportedFps, FRAME_TIMEOUT_MS, POLL_SLEEP_MS);

                    while (!Thread.currentThread().isInterrupted() && !context.shouldStop) {
                        try {
                            Frame frame = grabber.grabImage();
                            long  now   = System.currentTimeMillis();

                            // ── Good frame ────────────────────────────────────
                            if (frame != null) {
                                lastFrameTime = now;
                                frameCount++;

                                if (frameCount == 1) {
                                    logger.info("Stream {} - First live frame received", streamName);
                                }

                                long recordStart = System.currentTimeMillis();
                                recorder.record(frame);
                                long recordMs = System.currentTimeMillis() - recordStart;
                                if (recordMs > 100) {
                                    logger.warn("Stream {} - recorder.record() took {}ms — encoder falling behind",
                                            streamName, recordMs);
                                }

                                if (now - lastLogTime >= 30_000) {
                                    logger.info("[{}] ✓ Live | Frames encoded: {}", streamName, frameCount);
                                    lastLogTime = now;
                                }

                                frame.close();
                            }

                            // ── Time-based reconnect check ────────────────────
                            // Runs every iteration regardless of null or good frame.
                            long idleSince = now - lastFrameTime;
                            if (idleSince > FRAME_TIMEOUT_MS) {
                                logger.warn("Stream {} - No frame for {}ms (timeout {}ms), reconnecting...",
                                        streamName, idleSince, FRAME_TIMEOUT_MS);

                                if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
                                    reconnectAttempts++;
                                    logger.info("Stream {} - Reconnect attempt {}/{}",
                                            streamName, reconnectAttempts, MAX_RECONNECT_ATTEMPTS);
                                    try {
                                        // Tear down
                                        context.grabber = null;
                                        grabberConfig.safeClose(grabber);
                                        grabber = null;

                                        context.recorder = null;
                                        recorderConfig.safeClose(recorder);
                                        recorder = null;

                                        resourceManager.cleanStreamFiles(streamName);

                                        String freshUrl = fetchRtspUrlFromFirebase(
                                                streamName, currentRtspUrl.get());
                                        currentRtspUrl.set(freshUrl);
                                        Thread.sleep(RECONNECT_DELAY_MS);

                                        // Rebuild
                                        grabber = grabberConfig.startGrabberWithRetryHD(
                                                currentRtspUrl.get(), streamName, context);
                                        int newWidth     = grabber.getImageWidth();
                                        int newHeight    = grabber.getImageHeight();
                                        int newCameraFps = (int) grabber.getFrameRate();
                                        if (newCameraFps <= 0) newCameraFps = 15;

                                        recorder = recorderConfig.startRecorderWithRetryHD(
                                                hlsOutput, outputDir, newWidth, newHeight,
                                                newCameraFps, streamName, context);

                                        // Flush buffer accumulated during RECONNECT_DELAY_MS
                                        int postFlush = 0;
                                        for (int i = 0; i < 45; i++) {
                                            Frame stale = grabber.grabImage();
                                            if (stale == null) break;
                                            stale.close();
                                            postFlush++;
                                        }
                                        logger.info("Stream {} - Post-reconnect flush: {} frames cleared",
                                                streamName, postFlush);

                                        // Reset timer — fresh session starts now
                                        lastFrameTime = System.currentTimeMillis();
                                        reportedFps   = (int) grabber.getFrameRate();
                                        if (reportedFps <= 0) reportedFps = 15;

                                        logger.info("Stream {} - Reconnected | {}fps", streamName, reportedFps);

                                    } catch (Exception reconnectEx) {
                                        logger.error("Stream {} - Reconnect failed: {}",
                                                streamName, reconnectEx.getMessage());
                                        grabber  = null;
                                        recorder = null;
                                        break; // → finally → full restart
                                    }
                                } else {
                                    logger.error("Stream {} - Max reconnects reached, triggering full restart",
                                            streamName);
                                    break; // → finally → full restart
                                }
                            }

                            // Fixed poll sleep
                            Thread.sleep(POLL_SLEEP_MS);

                        } catch (org.bytedeco.javacv.FFmpegFrameRecorder.Exception recEx) {
                            logger.error("Stream {} - Recorder error, full restart: {}",
                                    streamName, recEx.getMessage());
                            break;
                        } catch (InterruptedException ie) {
                            Thread.currentThread().interrupt();
                            break;
                        } catch (Exception frameEx) {
                            String msg = frameEx.getMessage() != null ? frameEx.getMessage() : "";
                            if (msg.contains("AVFormatContext") || msg.contains("Could not grab")) {
                                logger.error("Stream {} - Grabber lost context, full restart", streamName);
                                break;
                            }
                            // Non-fatal frame error — log and let time-based check decide
                            logger.warn("Stream {} - Frame error (continuing): {}", streamName, msg);
                        }
                    }

                } catch (InterruptedException ie) {
                    logger.info("Stream {} interrupted, stopping", streamName);
                    Thread.currentThread().interrupt();
                    break;
                } catch (Exception e) {
                    logger.error("Stream {} - Pipeline init failed: {}", streamName, e.getMessage(), e);
                } finally {
                    recorderConfig.safeClose(recorder);
                    context.recorder = null;
                    grabberConfig.safeClose(grabber);
                    context.grabber  = null;
                }

                // ── Full restart decision ─────────────────────────────────────
                if (!context.shouldStop && !Thread.currentThread().isInterrupted()) {
                    fullRestartCount++;
                    if (fullRestartCount <= MAX_FULL_RESTARTS) {
                        logger.info("Stream {} - Full pipeline restart {}/{}, waiting {}ms...",
                                streamName, fullRestartCount, MAX_FULL_RESTARTS, FULL_RESTART_DELAY_MS);
                        String freshUrl = fetchRtspUrlFromFirebase(streamName, currentRtspUrl.get());
                        currentRtspUrl.set(freshUrl);
                        resourceManager.cleanStreamFiles(streamName);
                        try { Thread.sleep(FULL_RESTART_DELAY_MS); }
                        catch (InterruptedException ie) { Thread.currentThread().interrupt(); break; }
                    } else {
                        logger.error("Stream {} - All {} full restart attempts exhausted, giving up",
                                streamName, MAX_FULL_RESTARTS);
                    }
                }
            }

            logger.info("Stream {} thread exiting", streamName);
            resourceManager.cleanupResources(context);
            streamContexts.remove(streamName);
            streamThreads.remove(streamName);
        });

        thread.setName("HLS-" + streamName);
        thread.setDaemon(false);

        StreamContext existingContext = streamContexts.putIfAbsent(streamName, context);
        Thread        existingThread  = streamThreads.putIfAbsent(streamName, thread);

        if (existingContext != null || existingThread != null) {
            streamContexts.remove(streamName, context);
            streamThreads.remove(streamName, thread);
            return "/api/hls/" + streamName + "/stream.m3u8";
        }

        thread.start();
        logger.info("Started stream thread for {}", streamName);
        return "/api/hls/" + streamName + "/stream.m3u8";
    }

    // ─── Firebase URL refresh ─────────────────────────────────────────────────

    private String fetchRtspUrlFromFirebase(String streamName, String fallbackUrl) {
        try {
            if (streamName != null && streamName.startsWith("stream-")) {
                String cameraId = streamName.substring("stream-".length());
                Optional<Camera> cameraOpt = cameraRepository.getCameraById(cameraId);
                if (cameraOpt.isPresent()) {
                    String freshUrl = cameraOpt.get().getRtspUrl();
                    if (freshUrl != null && !freshUrl.isBlank()) {
                        if (!freshUrl.equals(fallbackUrl)) {
                            logger.info("Stream {} - RTSP URL refreshed from Firebase", streamName);
                        } else {
                            logger.debug("Stream {} - RTSP URL unchanged after Firebase lookup", streamName);
                        }
                        return freshUrl;
                    }
                }
                logger.warn("Stream {} - Camera not found or no RTSP URL in Firebase, keeping cached URL",
                        streamName);
            }
        } catch (Exception e) {
            logger.warn("Stream {} - Firebase lookup failed ({}), keeping cached URL",
                    streamName, e.getMessage());
        }
        return fallbackUrl;
    }

    // ─── Stop ─────────────────────────────────────────────────────────────────

    public String stopHLSStream(String streamName) {
        Thread        thread  = streamThreads.remove(streamName);
        StreamContext context = streamContexts.remove(streamName);

        if (thread == null && context == null) {
            return "Stream not found or already stopped.";
        }

        if (context != null) context.shouldStop = true;

        if (thread != null) {
            thread.interrupt();
            try {
                thread.join(5000);
                if (thread.isAlive()) {
                    if (context != null) resourceManager.cleanupResources(context);
                    thread.join(2000);
                    if (thread.isAlive()) {
                        logger.error("Thread {} still alive after forced cleanup. It will be abandoned.", streamName);
                    }
                } else {
                    logger.info("Thread {} stopped gracefully", streamName);
                }
            } catch (InterruptedException e) {
                logger.warn("Interrupted while waiting for thread {} to stop", streamName);
                Thread.currentThread().interrupt();
            }
        }

        if (!streamContexts.containsKey(streamName)) {
            try { Thread.sleep(500); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
            resourceManager.deleteStreamDirectory(streamName);
            logger.info("Stream {} stopped and files deleted", streamName);
        } else {
            logger.info("Stream {} stopped — new instance already running, files preserved", streamName);
        }
        return "Stream stopped and files deleted.";
    }
}