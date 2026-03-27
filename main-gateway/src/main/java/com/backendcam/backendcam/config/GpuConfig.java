package com.backendcam.backendcam.config;

import org.bytedeco.ffmpeg.global.avcodec;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import jakarta.annotation.PostConstruct;

@Component
public class GpuConfig {

    private static final Logger logger = LoggerFactory.getLogger(GpuConfig.class);

    @PostConstruct
    public void checkGpuCapabilities() {
        logger.info("=== GPU Capability Check ===");
        logger.info("CUDA hevc_cuvid available: {}",
            avcodec.avcodec_find_decoder_by_name("hevc_cuvid") != null);
        logger.info("CUDA h264_nvenc available: {}",
            avcodec.avcodec_find_encoder_by_name("h264_nvenc") != null);
        logger.info("CUDA h264_cuvid available: {}",
            avcodec.avcodec_find_decoder_by_name("h264_cuvid") != null);
        logger.info("============================");
    }
}