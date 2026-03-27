package com.backendcam.backendcam.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;


import com.backendcam.backendcam.model.dto.PageResponse;
import com.backendcam.backendcam.model.dto.licenseplate.LicensePlateDTO;
import com.backendcam.backendcam.model.dto.licenseplate.LicensePlateDashbordDTO;
import com.backendcam.backendcam.service.licenseplate.LicensePlateService;

import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/license-plates")
public class LicensePlateController {

    private final LicensePlateService licensePlateService;

    /**
     * GET /api/license-plates/search
     *
     * All params are optional and combinable:
     *   ?fullPlate=8กผ 8167  → fuzzy search on fullPlate (exact first, fuzzy fallback)
     *   ?cameraId=camera123 → filter by camera
     *   ?text=8กผ           → filter by plate text
     *   ?number=8167        → filter by plate number
     *   ?province=กรุงเทพมหานคร → filter by province
     *   ?start=20260215_000000&end=20260225_235959 → timestamp range
     *
     * Params can be combined: ?cameraId=camera123&number=8167
     * If nothing is provided → returns all records.
     */
    @GetMapping("/search")
    public ResponseEntity<PageResponse<List<LicensePlateDTO>>> search(
            @RequestParam(required = false) String fullPlate,
            @RequestParam(required = false) String cameraId,
            @RequestParam(required = false) String text,
            @RequestParam(required = false) String number,
            @RequestParam(required = false) String province,
            @RequestParam(required = false) String start,
            @RequestParam(required = false) String end,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int limit) {

        PageResponse<List<LicensePlateDTO>> results = licensePlateService.search(
                fullPlate, cameraId, text, number, province, start, end, page, limit);

        return ResponseEntity.ok(results);
    }

    @GetMapping("/stats")
    public ResponseEntity<LicensePlateDashbordDTO> getStats() {

        LicensePlateDashbordDTO stats = licensePlateService.getLatest();
        return ResponseEntity.ok(stats);

    }
}
