package com.parentingapp.server.product;

import com.parentingapp.server.common.security.AuthenticatedUser;
import com.parentingapp.server.product.dto.CreateReviewRequest;
import com.parentingapp.server.product.dto.ProductReviewResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reviews")
public class ReviewController {

    private final ProductService productService;

    public ReviewController(ProductService productService) {
        this.productService = productService;
    }

    @PatchMapping("/{id}")
    public ProductReviewResponse update(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @PathVariable String id,
            @Valid @RequestBody CreateReviewRequest request) {
        return productService.updateReview(currentUser.id(), id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal AuthenticatedUser currentUser, @PathVariable String id) {
        productService.deleteReview(currentUser.id(), id);
        return ResponseEntity.noContent().build();
    }
}
