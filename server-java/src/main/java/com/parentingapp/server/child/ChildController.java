package com.parentingapp.server.child;

import com.parentingapp.server.child.dto.ChildResponse;
import com.parentingapp.server.child.dto.CreateChildRequest;
import com.parentingapp.server.common.security.AuthenticatedUser;
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
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/children")
public class ChildController {

    private final ChildService childService;

    public ChildController(ChildService childService) {
        this.childService = childService;
    }

    @GetMapping
    public List<ChildResponse> list(@AuthenticationPrincipal AuthenticatedUser currentUser) {
        return childService.listChildren(currentUser.id());
    }

    @PostMapping
    public ResponseEntity<ChildResponse> create(
            @AuthenticationPrincipal AuthenticatedUser currentUser, @Valid @RequestBody CreateChildRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(childService.createChild(currentUser.id(), request));
    }

    @PatchMapping("/{id}")
    public ChildResponse update(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @PathVariable String id,
            @Valid @RequestBody CreateChildRequest request) {
        return childService.updateChild(currentUser.id(), id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal AuthenticatedUser currentUser, @PathVariable String id) {
        childService.deleteChild(currentUser.id(), id);
        return ResponseEntity.noContent().build();
    }
}
