package com.backendcam.backendcam.model.dto.licenseplate;

import com.google.cloud.Timestamp;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class LicensePlateDTO {
    private Timestamp timestamp;
    private String imageUrl;

    private LicensePlateBody licensePlate;
    private CameraBody camera;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LicensePlateBody {
        private String fullPlate;   // e.g. "8กผ 8167"
        private String text;        // e.g. "8กผ"
        private String number;      // e.g. "8167"
        private String province;    // e.g. "กรุงเทพมหานคร"
    }

    
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CameraBody {
        private String cameraId;   
        private String cameraName;        
    }

}
