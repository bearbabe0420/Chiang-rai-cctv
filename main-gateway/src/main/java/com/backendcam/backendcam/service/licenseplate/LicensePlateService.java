package com.backendcam.backendcam.service.licenseplate;

import java.time.Instant;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.backendcam.backendcam.model.dto.licenseplate.LicensePlateDTO;
import com.backendcam.backendcam.model.entity.Camera;
import com.backendcam.backendcam.model.entity.LicensePlate;
import com.backendcam.backendcam.repository.CameraRepository;
import com.backendcam.backendcam.repository.LicensePlateRepository;
import com.google.cloud.Timestamp;

import lombok.RequiredArgsConstructor;
import me.xdrop.fuzzywuzzy.FuzzySearch;

@Service
@RequiredArgsConstructor
public class LicensePlateService {

    private final LicensePlateRepository licensePlateRepository;
    private final CameraRepository cameraRepository;

    private static final int FUZZY_THRESHOLD = 60;
    private static final int MAX_RESULTS = 10;

    /**
     * Unified search: all params optional and combinable.
     *
     * Strategy:
     * 1. Pick the most specific Firestore filter available (exact field filters).
     * Priority: fullPlate (via query exact) > text > number > province > cameraId >
     * timestamp range > all.
     * 2. Post-filter in Java for any remaining params that weren't used as the
     * Firestore filter.
     * 3. If `query` provided and no exact fullPlate match, fall back to fuzzy on
     * fullPlate.
     */
    public List<LicensePlateDTO> search(
            String fullPlate,
            String cameraId,
            String text,
            String number,
            String province,
            String start,
            String end) {
        try {
            List<LicensePlate> results;
            boolean fuzzyFallback = false;

            // --- Step 1: Choose primary Firestore fetch ---
            if (fullPlate != null && !fullPlate.isBlank()) {
                // Try exact fullPlate first
                results = licensePlateRepository.findByFullPlate(fullPlate);
                if (results.isEmpty()) {
                    // Exact missed — fetch all for fuzzy
                    results = licensePlateRepository.getAll();
                    fuzzyFallback = true;
                }
            } else if (text != null && !text.isBlank()) {
                results = licensePlateRepository.findByText(text);
            } else if (number != null && !number.isBlank()) {
                results = licensePlateRepository.findByNumber(number);
            } else if (province != null && !province.isBlank()) {
                results = licensePlateRepository.findByProvince(province);
            } else if (cameraId != null && !cameraId.isBlank() && start != null && end != null) {
                results = licensePlateRepository.findByCameraIdAndTimestampRange(cameraId, start, end);
            } else if (start != null && end != null) {
                results = licensePlateRepository.findByTimestampRange(start, end);
            } else if (cameraId != null && !cameraId.isBlank()) {
                results = licensePlateRepository.findByCameraId(cameraId);
            } else {
                results = licensePlateRepository.getAll();
            }

            // --- Step 2: Post-filter for remaining params not used as primary filter ---
            if (cameraId != null && !cameraId.isBlank()) {
                final String cam = cameraId;
                results = results.stream()
                        .filter(p -> cam.equals(p.getCamera()))
                        .collect(Collectors.toList());
            }
            if (text != null && !text.isBlank() && fullPlate == null) {
                final String t = text;
                results = results.stream()
                        .filter(p -> p.getLicensePlate() != null && t.equals(p.getLicensePlate().getText()))
                        .collect(Collectors.toList());
            }
            if (number != null && !number.isBlank() && fullPlate == null) {
                final String n = number;
                results = results.stream()
                        .filter(p -> p.getLicensePlate() != null && n.equals(p.getLicensePlate().getNumber()))
                        .collect(Collectors.toList());
            }
            if (province != null && !province.isBlank() && fullPlate == null) {
                final String prov = province;
                results = results.stream()
                        .filter(p -> p.getLicensePlate() != null && prov.equals(p.getLicensePlate().getProvince()))
                        .collect(Collectors.toList());
            }
            if (start != null && end != null) {
                Instant startInstant = Instant.parse(start); // expects ISO-8601
                Instant endInstant = Instant.parse(end);
                Timestamp tsStart = Timestamp.ofTimeSecondsAndNanos(startInstant.getEpochSecond(),
                        startInstant.getNano());
                Timestamp tsEnd = Timestamp.ofTimeSecondsAndNanos(endInstant.getEpochSecond(), endInstant.getNano());

                results = results.stream()
                        .filter(p -> p.getTimestamp() != null
                                && p.getTimestamp().compareTo(tsStart) >= 0
                                && p.getTimestamp().compareTo(tsEnd) <= 0)
                        .collect(Collectors.toList());

            }

            // --- Step 3: Fuzzy scoring if needed ---
            if (fuzzyFallback) {
                String normalizedQuery = normalize(fullPlate);
                results = results.stream()
                        .filter(p -> p.getLicensePlate() != null && p.getLicensePlate().getFullPlate() != null)
                        .filter(p -> fuzzyScore(normalizedQuery,
                                normalize(p.getLicensePlate().getFullPlate())) >= FUZZY_THRESHOLD)
                        .sorted(Comparator
                                .comparingInt((LicensePlate p) ->
                                fuzzyScore(normalizedQuery, normalize(p.getLicensePlate().getFullPlate())))
                                .reversed()
                                .thenComparing(LicensePlate::getTimestamp,
                                        Comparator.nullsLast(Comparator.reverseOrder())))
                        .limit(MAX_RESULTS)
                        .collect(Collectors.toList());
            } else {
                results = results.stream()
                        .sorted(Comparator.comparing(LicensePlate::getTimestamp,
                                Comparator.nullsLast(Comparator.reverseOrder())))
                        .limit(MAX_RESULTS)
                        .collect(Collectors.toList());
            }

            // --- Step 4: Populate camera documents based on cameraId ---
        

            return populateCameras(results);
        } catch (Exception e) {
            throw new RuntimeException("Failed to search license plates", e);
        }
    }

   private List<LicensePlateDTO> populateCameras(List<LicensePlate> plates) throws ExecutionException, InterruptedException {
    List<String> ids = plates.stream()
            .map(LicensePlate::getCamera)
            .filter(Objects::nonNull)
            .distinct()
            .collect(Collectors.toList());

    Map<String, Camera> cache = new HashMap<>();
    for (String id : ids) {
        try {
            cameraRepository.getCameraById(id).ifPresent(cam -> cache.put(id, cam));
        } catch (Exception ignored) {}
    }

    return plates.stream().map(p -> {
        LicensePlateDTO dto = new LicensePlateDTO();
        dto.setTimestamp(p.getTimestamp());
        dto.setImageUrl(p.getImageUrl());

        // Map licensePlate body
        if (p.getLicensePlate() != null) {
            dto.setLicensePlate(new LicensePlateDTO.LicensePlateBody(
                p.getLicensePlate().getFullPlate(),
                p.getLicensePlate().getText(),
                p.getLicensePlate().getNumber(),
                p.getLicensePlate().getProvince()
            ));
        }

        // Map camera
        String camId = p.getCamera();
        if (camId != null) {
            Camera cam = cache.get(camId);
            LicensePlateDTO.CameraBody camBody = new LicensePlateDTO.CameraBody();
            camBody.setCameraId(camId);
            camBody.setCameraName(cam != null ? cam.getName() : null);
            dto.setCamera(camBody);
        }

        return dto;
    }).collect(Collectors.toList());
}

    private String normalize(String input) {
        if (input == null)
            return "";
        return input.toUpperCase().replaceAll("[\\s\\-.]", "");
    }

    private int fuzzyScore(String s1, String s2) {
        return Math.max(FuzzySearch.ratio(s1, s2), FuzzySearch.partialRatio(s1, s2));
    }
}
