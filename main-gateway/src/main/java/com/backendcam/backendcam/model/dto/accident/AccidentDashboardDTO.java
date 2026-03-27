package com.backendcam.backendcam.model.dto.accident;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AccidentDashboardDTO {

    @JsonProperty("latest_accident")
    private AccidentBody latestAccident;

    @JsonProperty("top_cameras")
    private List<CameraAccidentCount> topCameras;

    @JsonProperty("top_categories")
    private List<CategoryAccidentCount> topCategories;

    // ── Latest accident snapshot ──────────────────────────────────────────────
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AccidentBody {
        private String id;
        private String timestamp;

        @JsonProperty("image_url")
        private String imageUrl;

        @JsonProperty("camera_id")
        private String cameraId;

        @JsonProperty("camera_name")
        private String cameraName;

        @JsonProperty("camera_address")
        private String cameraAddress;
    }

    // ── Camera ranked by accident count (last 1 month) ───────────────────────
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CameraAccidentCount {
        @JsonProperty("camera_id")
        private String cameraId;

        @JsonProperty("camera_name")
        private String cameraName;

        @JsonProperty("camera_address")
        private String cameraAddress;

        @JsonProperty("accident_count")
        private long accidentCount;
    }

    // ── Category ranked by accident count (last 1 month) ─────────────────────
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CategoryAccidentCount {
        private String category;

        @JsonProperty("accident_count")
        private long accidentCount;
    }
}