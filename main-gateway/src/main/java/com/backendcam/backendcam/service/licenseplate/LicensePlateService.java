package com.backendcam.backendcam.service.licenseplate;

import java.time.Instant;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ExecutionException;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.backendcam.backendcam.model.dto.PageResponse;
import com.backendcam.backendcam.model.dto.licenseplate.LicensePlateDTO;
import com.backendcam.backendcam.model.dto.licenseplate.LicensePlateDashbordDTO;
import com.backendcam.backendcam.model.entity.Camera;
import com.backendcam.backendcam.model.entity.LicensePlate;
import com.backendcam.backendcam.repository.CameraRepository;
import com.backendcam.backendcam.repository.LicensePlateRepository;
import com.backendcam.backendcam.util.PaginationUtil;
import com.google.cloud.Timestamp;

import lombok.RequiredArgsConstructor;
import me.xdrop.fuzzywuzzy.FuzzySearch;

@Service
@RequiredArgsConstructor
public class LicensePlateService {

    private final LicensePlateRepository licensePlateRepository;
    private final CameraRepository cameraRepository;

    private static final int FUZZY_THRESHOLD = 60;

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
    public PageResponse<List<LicensePlateDTO>> search(
            String fullPlate,
            String cameraId,
            String text,
            String number,
            String province,
            String start,
            String end,
            int page,
            int limit) {
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
                        .collect(Collectors.toList());
            } else {
                results = results.stream()
                        .sorted(Comparator.comparing(LicensePlate::getTimestamp,
                                Comparator.nullsLast(Comparator.reverseOrder())))
                        .collect(Collectors.toList());
            }

            // --- Step 4: Paginate ---
            long totalItems = results.size();
            int fromIndex = Math.min((page - 1) * limit, results.size());
            int toIndex = Math.min(fromIndex + limit, results.size());
            List<LicensePlate> pageItems = results.subList(fromIndex, toIndex);

            // --- Step 5: Populate camera documents and map to DTOs ---
            List<LicensePlateDTO> dtos = populateCameras(pageItems);

            return PaginationUtil.createPaginationResponse(dtos, totalItems, page, limit, Function.identity());
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
            dto.setTimestamp(p.getTimestamp() != null
                    ? p.getTimestamp().toDate().toInstant().toString()
                    : null);
            dto.setImageUrl(p.getImageUrl());

            if (p.getLicensePlate() != null) {
                dto.setLicensePlate(new LicensePlateDTO.LicensePlateBody(
                        p.getLicensePlate().getFullPlate(),
                        p.getLicensePlate().getText(),
                        p.getLicensePlate().getNumber(),
                        p.getLicensePlate().getProvince()
                ));
            }

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


public LicensePlateDashbordDTO getLatest() {
    try {
        List<LicensePlate> all = licensePlateRepository.getAll();

        if (all.isEmpty()) {
            return null;
        }

        // Timestamp is com.google.cloud.Timestamp — convert to Instant for date comparison
        java.time.LocalDate today = java.time.LocalDate.now(java.time.ZoneOffset.UTC);

        long totalLicenseToday = all.stream()
                .filter(p -> p.getTimestamp() != null)
                .filter(p -> {
                    // Convert Firestore Timestamp → Instant → LocalDate for comparison
                    java.time.LocalDate plateDate = p.getTimestamp()
                            .toDate()
                            .toInstant()
                            .atZone(java.time.ZoneOffset.UTC)
                            .toLocalDate();
                    return plateDate.equals(today);
                })
                .count();

        LicensePlate latest = all.stream()
                .filter(p -> p.getTimestamp() != null)
                .max(Comparator.comparing(LicensePlate::getTimestamp))
                .orElse(all.get(0));

        return toDashboardDTO(latest, totalLicenseToday);

    } catch (Exception e) {
        throw new RuntimeException("Failed to fetch latest license plate", e);
    }
}

private LicensePlateDashbordDTO toDashboardDTO(LicensePlate entity, long totalLicenseToday) {
    LicensePlateDashbordDTO dto = new LicensePlateDashbordDTO();

    // Convert Firestore Timestamp → ISO-8601 String
    dto.setTimestamp(entity.getTimestamp() != null
            ? entity.getTimestamp().toDate().toInstant().toString()
            : null);
    dto.setImageUrl(entity.getImageUrl());
    dto.setTotalLicenseToday(totalLicenseToday);

    if (entity.getLicensePlate() != null) {
        LicensePlateDashbordDTO.LicensePlateBody plateBody = new LicensePlateDashbordDTO.LicensePlateBody(
                entity.getLicensePlate().getFullPlate(),
                entity.getLicensePlate().getText(),
                entity.getLicensePlate().getNumber(),
                entity.getLicensePlate().getProvince()
        );
        dto.setLicensePlate(plateBody);
    }

    // Entity uses getCamera() not getCameraId()
    String camId = entity.getCamera();
    if (camId != null) {
        Camera cam = null;
        try {
            cam = cameraRepository.getCameraById(camId).orElse(null);
        } catch (Exception ignored) {}

        LicensePlateDashbordDTO.CameraBody cameraBody = new LicensePlateDashbordDTO.CameraBody(
                camId,
                cam != null ? cam.getName() : null
        );
        dto.setCamera(cameraBody);
    }

    return dto;
}
}
