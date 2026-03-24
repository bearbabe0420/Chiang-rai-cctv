package com.motion_detect.motion_detect.service.motion;

import com.motion_detect.motion_detect.model.dto.MotionEvent;
import com.motion_detect.motion_detect.firestore.FirebaseAdminBootstrap;
import com.motion_detect.motion_detect.service.kafka.MotionEventProducer;

import com.google.cloud.storage.Bucket;
import com.google.cloud.storage.Blob;
import com.google.firebase.cloud.StorageClient;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.bytedeco.javacv.Frame;
import org.bytedeco.javacv.Java2DFrameConverter;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;

@Slf4j
@Service
@RequiredArgsConstructor
public class SaveMotionFrameService {

    private final FirebaseAdminBootstrap bootstrap;
    private final MotionEventProducer motionEventProducer;

    /**
     * Deep copy a frame to BufferedImage.
     * Creates and immediately closes a converter to avoid native memory leak.
     */
    private BufferedImage deepCopyFrameToImage(Frame frame) {
        if (frame == null || frame.image == null) {
            return null;
        }
        
        Java2DFrameConverter converter = new Java2DFrameConverter();
        try {
            BufferedImage original = converter.convert(frame);
            if (original == null) {
                return null;
            }
            
            BufferedImage copy = new BufferedImage(
                original.getWidth(), 
                original.getHeight(), 
                BufferedImage.TYPE_3BYTE_BGR
            );
            
            java.awt.Graphics g = copy.getGraphics();
            try {
                g.drawImage(original, 0, 0, null);
            } finally {
                g.dispose();
            }
            
            return copy;
        } finally {
            try { converter.close(); } catch (Exception e) { /* ignore */ }
        }
    }

    /**
     * Upload a Frame to Firebase Storage
     */
    public void uploadMotionFrame(Frame frame, String cameraId) {
        if (!bootstrap.isInitialized()) return;

        BufferedImage image = deepCopyFrameToImage(frame);
        if (image == null) return;
        uploadBufferedImage(image, cameraId);
    }

    /**
     * Upload a BufferedImage directly to Firebase Storage
     * Used when we've already selected the best frame
     */
    public void uploadMotionFrame(BufferedImage image, String cameraId) {
        if (!bootstrap.isInitialized()) return;
        if (image == null) return;

        uploadBufferedImage(image, cameraId);
    }

    /**
     * Common upload logic for BufferedImage.
     * After a successful upload, fires a MotionEvent to Kafka so downstream
     * consumers (accident-ai, license-plate, etc.) are notified automatically.
     */
   private void uploadBufferedImage(BufferedImage image, String cameraId) {
    byte[] bytes;
    try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
        ImageIO.write(image, "jpg", baos);
        bytes = baos.toByteArray();
    } catch (Exception e) {
        log.error("Failed to encode image: {}", e.getMessage());
        return;
    }

    String path = "motion/" + cameraId + "/" + System.currentTimeMillis() + ".jpg";
    String url;

    try {
        Bucket bucket = StorageClient.getInstance().bucket();
        
        // ✅ ADD: generate a download token
        String downloadToken = java.util.UUID.randomUUID().toString();
        java.util.Map<String, String> metadata = new java.util.HashMap<>();
        metadata.put("firebaseStorageDownloadTokens", downloadToken);

        com.google.cloud.storage.BlobInfo blobInfo = com.google.cloud.storage.BlobInfo
            .newBuilder(bucket.getName(), path)
            .setContentType("image/jpeg")
            .setMetadata(metadata)   // ✅ attach token as metadata
            .build();

        com.google.cloud.storage.Blob blob = bucket.getStorage().create(blobInfo, bytes);

        // ✅ Build proper Firebase Storage URL with token
        String encodedPath = java.net.URLEncoder
            .encode(blob.getName(), java.nio.charset.StandardCharsets.UTF_8)
            .replace("+", "%20");

        url = "https://firebasestorage.googleapis.com/v0/b/"
            + bucket.getName()
            + "/o/"
            + encodedPath
            + "?alt=media&token="
            + downloadToken;   // ✅ token attached!

        log.info("Motion frame uploaded for camera {}", cameraId);

    } catch (Exception e) {
        log.error("Firebase upload failed for camera {}: {}", cameraId, e.getMessage());
        return;
    }

    try {
        motionEventProducer.send(MotionEvent.builder()
                .cameraId(cameraId)
                .timestamp(System.currentTimeMillis())
                .imageUrl(url)   // ✅ now saves proper URL with token
                .build());
        log.info("Kafka event sent for camera {}", cameraId);
    } catch (Exception e) {
        log.error("Kafka send failed for camera {}: {}", cameraId, e.getMessage(), e);
    }
}
}
