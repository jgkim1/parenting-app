package com.parentingapp.server.product;

import com.parentingapp.server.common.dto.PageResponse;
import com.parentingapp.server.common.security.AuthenticatedUser;
import com.parentingapp.server.domain.UserRole;
import com.parentingapp.server.product.dto.CreateProductRequest;
import com.parentingapp.server.product.dto.CreateReviewRequest;
import com.parentingapp.server.product.dto.ProductDetailResponse;
import com.parentingapp.server.product.dto.ProductReviewResponse;
import com.parentingapp.server.product.dto.ProductSummaryResponse;
import com.parentingapp.server.product.dto.UpdateProductRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final ProductService productService;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping
    public PageResponse<ProductSummaryResponse> list(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String categoryId,
            @RequestParam(required = false) String q,
            @RequestParam(required = false, defaultValue = "false") boolean includeInactive) {
        boolean effectiveIncludeInactive = includeInactive && currentUser != null && currentUser.role() == UserRole.ADMIN;
        return productService.listProducts(page, pageSize, categoryId, q, effectiveIncludeInactive);
    }

    @GetMapping("/{id}")
    public ProductDetailResponse get(
            @AuthenticationPrincipal AuthenticatedUser currentUser, @PathVariable String id) {
        boolean includeInactive = currentUser != null && currentUser.role() == UserRole.ADMIN;
        return productService.getProductById(id, includeInactive);
    }

    @PostMapping
    public ResponseEntity<ProductSummaryResponse> create(
            @AuthenticationPrincipal AuthenticatedUser currentUser, @Valid @RequestBody CreateProductRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(productService.createProduct(currentUser.id(), request));
    }

    @PatchMapping("/{id}")
    public ProductSummaryResponse update(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @PathVariable String id,
            @Valid @RequestBody UpdateProductRequest request) {
        return productService.updateProduct(currentUser.id(), currentUser.role(), id, request);
    }

    @PostMapping("/{id}/reviews")
    public ResponseEntity<ProductReviewResponse> createReview(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @PathVariable String id,
            @Valid @RequestBody CreateReviewRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(productService.createReview(currentUser.id(), id, request));
    }
}
