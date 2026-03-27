package com.backendcam.backendcam.service.accident;

import com.backendcam.backendcam.model.dto.PageResponse;
import com.backendcam.backendcam.model.dto.accident.AccidentResponseDto;
import com.backendcam.backendcam.model.dto.accident.CreateAccidentDto;
import com.backendcam.backendcam.model.entity.Accident;
import com.backendcam.backendcam.repository.AccidentRepository;
import com.backendcam.backendcam.model.entity.Camera; 
import com.backendcam.backendcam.repository.CameraRepository; 
import com.backendcam.backendcam.util.PaginationUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import com.backendcam.backendcam.model.dto.accident.AccidentDashboardDTO;
import com.backendcam.backendcam.model.entity.Accident;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.function.Function;
import java.util.stream.Stream;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors; 
import java.util.*;       

@Service
@RequiredArgsConstructor
public class AccidentService {

    private final AccidentRepository accidentRepository;
    private final CameraRepository cameraRepository; 

    public AccidentResponseDto createAccident(CreateAccidentDto createDto) {
        try {
            Accident accident = new Accident();
            accident.setCameraId(createDto.getCameraId());
            accident.setImageUrl(createDto.getImageUrl());
            accident.setTimestamp(createDto.getTimestamp());

            String id = accidentRepository.save(accident);
            accident.setId(id);
            return toDto(accident);
        } catch (Exception e) {
            throw new RuntimeException("Failed to create accident", e);
        }
    }

    public Optional<AccidentResponseDto> getAccidentById(String id) {
        try {
            return accidentRepository.findById(id).map(this::toDto);
        } catch (Exception e) {
            throw new RuntimeException("Failed to get accident by id", e);
        }
    }

    public PageResponse<List<AccidentResponseDto>> getAccidentsByPage(int page, int limit) {
        try {
            List<Accident> accidents = accidentRepository.findByPage(page, limit);
            long totalItems = accidentRepository.getTotalCount();
            return PaginationUtil.createPaginationResponse(accidents, totalItems, page, limit, this::toDto);
        } catch (Exception e) {
            throw new RuntimeException("Failed to get accidents by page", e);
        }
    }

    public List<AccidentResponseDto> getAccidentsByCameraId(String cameraId) {
        try {
            return accidentRepository.findByCameraId(cameraId).stream()
                    .map(this::toDto)
                    .toList();
        } catch (Exception e) {
            throw new RuntimeException("Failed to get accidents by cameraId", e);
        }
    }

    public void deleteAccident(String id) {
        try {
            accidentRepository.findById(id)
                    .orElseThrow(() -> new java.util.NoSuchElementException("Accident not found: " + id));
            accidentRepository.delete(id);
        } catch (java.util.NoSuchElementException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete accident", e);
        }
    }

    private AccidentResponseDto toDto(Accident accident) {
        return new AccidentResponseDto(
                accident.getId(),
                accident.getCameraId(),
                accident.getImageUrl(),
                accident.getTimestamp());
    }

    public AccidentDashboardDTO getAccidentDashboard() {
        try {
            // Step 1: Get all accidents (needed for latest across all time)
            List<Accident> all = accidentRepository.findAll();
            if (all.isEmpty())
                return new AccidentDashboardDTO(null, List.of(), List.of());

            // Step 2: Filter to 30 days EARLY — smaller list for camera ID collection
            String thirtyDaysAgo = Instant.now()
                    .atZone(ZoneOffset.UTC)
                    .minusDays(30)
                    .toInstant()
                    .toString();

            List<Accident> lastMonth = all.stream()
                    .filter(a -> a.getTimestamp() != null && a.getTimestamp().compareTo(thirtyDaysAgo) >= 0)
                    .collect(Collectors.toList());

            // Step 3: Collect unique camera IDs from BOTH lists (latest might be outside 30
            // days)
            Accident latest = all.stream()
                    .filter(a -> a.getTimestamp() != null)
                    .max(Comparator.comparing(Accident::getTimestamp))
                    .orElse(all.get(0));

            Set<String> cameraIds = lastMonth.stream()
                    .map(Accident::getCameraId)
                    .filter(Objects::nonNull)
                    .collect(Collectors.toSet());
            if (latest.getCameraId() != null) {
                cameraIds.add(latest.getCameraId()); // ensure latest camera is also resolved
            }

            // Step 4: Build camera cache (only cameras we actually need)
            Map<String, Camera> cameraCache = new HashMap<>();
            for (String id : cameraIds) {
                try {
                    cameraRepository.getCameraById(id)
                            .ifPresent(cam -> cameraCache.put(id, cam));
                } catch (Exception ignored) {
                }
            }

            // Step 5: Build latest accident body
            Camera latestCam = cameraCache.get(latest.getCameraId());
            AccidentDashboardDTO.AccidentBody latestBody = new AccidentDashboardDTO.AccidentBody(
                    latest.getId(),
                    latest.getTimestamp(),
                    latest.getImageUrl(),
                    latest.getCameraId(),
                    latestCam != null ? latestCam.getName() : null,
                    latestCam != null ? latestCam.getAddress() : null);

            // Step 6: Top cameras (from lastMonth — already filtered)
            List<AccidentDashboardDTO.CameraAccidentCount> topCameras = lastMonth.stream()
                    .filter(a -> a.getCameraId() != null)
                    .collect(Collectors.groupingBy(Accident::getCameraId, Collectors.counting()))
                    .entrySet().stream()
                    .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                    .map(e -> {
                        Camera cam = cameraCache.get(e.getKey());
                        return new AccidentDashboardDTO.CameraAccidentCount(
                                e.getKey(),
                                cam != null ? cam.getName() : null,
                                cam != null ? cam.getAddress() : null,
                                e.getValue());
                    })
                    .collect(Collectors.toList());

            // Step 7: Top categories (from lastMonth — already filtered)
            List<AccidentDashboardDTO.CategoryAccidentCount> topCategories = lastMonth.stream()
                    .filter(a -> a.getCameraId() != null)
                    .flatMap(a -> {
                        Camera cam = cameraCache.get(a.getCameraId());
                        if (cam == null || cam.getCategories() == null)
                            return Stream.empty();
                        return cam.getCategories().stream();
                    })
                    .collect(Collectors.groupingBy(Function.identity(), Collectors.counting()))
                    .entrySet().stream()
                    .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                    .map(e -> new AccidentDashboardDTO.CategoryAccidentCount(e.getKey(), e.getValue()))
                    .collect(Collectors.toList());

            return new AccidentDashboardDTO(latestBody, topCameras, topCategories);

        } catch (Exception e) {
            throw new RuntimeException("Failed to fetch accident dashboard", e);
        }
    }
}
