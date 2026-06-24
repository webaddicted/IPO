package com.ipotracker.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/** Request/response shapes for the allotment-status checker. */
public final class AllotmentDtos {

    private AllotmentDtos() {}

    /** A PAN (e.g. ABCDE1234F) is the universal lookup key across registrars. */
    public record AllotmentRequest(
            @NotBlank String ipoId,
            @Pattern(regexp = "^[A-Za-z]{5}[0-9]{4}[A-Za-z]$", message = "Invalid PAN format")
            String pan,
            String applicationNumber
    ) {}

    public enum Outcome { ALLOTTED, NOT_ALLOTTED, NOT_FOUND, MANUAL_CHECK_REQUIRED, ERROR }

    public record AllotmentResult(
            Outcome outcome,
            String companyName,
            String registrar,
            String manualCheckUrl,
            Long sharesApplied,
            Long sharesAllotted,
            String message
    ) {
        public static AllotmentResult manual(String company, String registrar, String url) {
            return new AllotmentResult(Outcome.MANUAL_CHECK_REQUIRED, company, registrar, url,
                    null, null,
                    "Automated check is unavailable for this registrar (captcha-protected). "
                            + "Tap to verify on the official portal.");
        }
    }
}
