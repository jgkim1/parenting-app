package com.parentingapp.server.ad;

import com.parentingapp.server.ad.dto.AdResponse;
import com.parentingapp.server.ad.dto.CreateAdRequest;
import com.parentingapp.server.ad.dto.UpdateAdRequest;
import com.parentingapp.server.common.security.AuthenticatedUser;
import com.parentingapp.server.domain.AdPlacement;
import com.parentingapp.server.domain.UserRole;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ads")
public class AdController {

    private final AdService adService;

    public AdController(AdService adService) {
        this.adService = adService;
    }

    @GetMapping
    public List<AdResponse> list(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @RequestParam(required = false) AdPlacement placement,
            @RequestParam(required = false, defaultValue = "false") boolean includeInactive) {
        boolean effective = includeInactive && currentUser != null && currentUser.role() == UserRole.ADMIN;
        return adService.listAds(placement, effective);
    }

    @PostMapping
    public ResponseEntity<AdResponse> create(@Valid @RequestBody CreateAdRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(adService.createAd(request));
    }

    @PatchMapping("/{id}")
    public AdResponse update(@PathVariable String id, @Valid @RequestBody UpdateAdRequest request) {
        return adService.updateAd(id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        adService.deleteAd(id);
        return ResponseEntity.noContent().build();
    }
}
