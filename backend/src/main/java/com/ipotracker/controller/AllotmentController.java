package com.ipotracker.controller;

import com.ipotracker.dto.AllotmentDtos.AllotmentRequest;
import com.ipotracker.dto.AllotmentDtos.AllotmentResult;
import com.ipotracker.service.AllotmentService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class AllotmentController {

    private final AllotmentService allotmentService;

    public AllotmentController(AllotmentService allotmentService) {
        this.allotmentService = allotmentService;
    }

    @PostMapping("/allotment")
    public AllotmentResult check(@Valid @RequestBody AllotmentRequest request) {
        return allotmentService.check(request);
    }
}
