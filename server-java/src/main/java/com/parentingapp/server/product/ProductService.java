package com.parentingapp.server.product;

import com.parentingapp.server.common.dto.PageResponse;
import com.parentingapp.server.common.exception.ConflictException;
import com.parentingapp.server.common.exception.ForbiddenException;
import com.parentingapp.server.common.exception.NotFoundException;
import com.parentingapp.server.domain.Category;
import com.parentingapp.server.domain.Product;
import com.parentingapp.server.domain.ProductImage;
import com.parentingapp.server.domain.Review;
import com.parentingapp.server.domain.User;
import com.parentingapp.server.domain.UserRole;
import com.parentingapp.server.product.dto.CategoryResponse;
import com.parentingapp.server.product.dto.CreateProductRequest;
import com.parentingapp.server.product.dto.CreateReviewRequest;
import com.parentingapp.server.product.dto.ProductDetailResponse;
import com.parentingapp.server.product.dto.ProductReviewResponse;
import com.parentingapp.server.product.dto.ProductSummaryResponse;
import com.parentingapp.server.product.dto.ReviewStatsResponse;
import com.parentingapp.server.product.dto.UpdateProductRequest;
import com.parentingapp.server.repository.CategoryRepository;
import com.parentingapp.server.repository.ProductImageRepository;
import com.parentingapp.server.repository.ProductRepository;
import com.parentingapp.server.repository.ReviewRepository;
import com.parentingapp.server.repository.UserRepository;
import java.util.ArrayList;
import java.util.List;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ProductImageRepository productImageRepository;
    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;

    public ProductService(
            ProductRepository productRepository,
            CategoryRepository categoryRepository,
            ProductImageRepository productImageRepository,
            ReviewRepository reviewRepository,
            UserRepository userRepository) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
        this.productImageRepository = productImageRepository;
        this.reviewRepository = reviewRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> listCategories() {
        return categoryRepository.findAllByOrderByNameAsc().stream().map(CategoryResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public PageResponse<ProductSummaryResponse> listProducts(
            int page, int pageSize, String categoryId, String q, boolean includeInactive) {
        Boolean activeFilter = includeInactive ? null : Boolean.TRUE;
        String query = (q == null || q.isBlank()) ? null : q;
        Page<Product> result = productRepository.search(
                activeFilter, categoryId, query, PageRequest.of(page - 1, pageSize, Sort.by(Sort.Direction.DESC, "createdAt")));
        return PageResponse.of(result.map(ProductSummaryResponse::from), page, pageSize);
    }

    @Transactional(readOnly = true)
    public ProductDetailResponse getProductById(String id, boolean includeInactive) {
        Product product = productRepository.findById(id).orElseThrow(() -> new NotFoundException("상품을 찾을 수 없습니다."));
        if (!product.isActive() && !includeInactive) {
            throw new NotFoundException("상품을 찾을 수 없습니다.");
        }

        List<Review> reviews = reviewRepository.findByProduct_IdOrderByCreatedAtDesc(id);
        double average = reviewRepository.averageRatingByProductId(id);
        long count = reviewRepository.countByProduct_Id(id);

        return ProductDetailResponse.from(product, reviews, new ReviewStatsResponse(average, count));
    }

    @Transactional
    public ProductSummaryResponse createProduct(String sellerId, CreateProductRequest input) {
        Category category = categoryRepository
                .findById(input.categoryId())
                .orElseThrow(() -> new NotFoundException("카테고리를 찾을 수 없습니다."));
        User seller = userRepository.findById(sellerId).orElseThrow(NotFoundException::new);

        Product product = new Product();
        product.setSeller(seller);
        product.setCategory(category);
        product.setName(input.name());
        product.setDescription(input.description());
        product.setPrice(input.price());
        product.setStock(input.stock());
        productRepository.saveAndFlush(product);

        attachImages(product, input.imageUrls());
        productRepository.saveAndFlush(product);

        return ProductSummaryResponse.from(product);
    }

    // ADMIN은 모든 상품을, SELLER는 본인이 등록한 상품만 수정할 수 있다.
    @Transactional
    public ProductSummaryResponse updateProduct(
            String requesterId, UserRole requesterRole, String productId, UpdateProductRequest input) {
        Product product = productRepository
                .findById(productId)
                .orElseThrow(() -> new NotFoundException("상품을 찾을 수 없습니다."));
        if (requesterRole != UserRole.ADMIN && !product.getSeller().getId().equals(requesterId)) {
            throw new ForbiddenException("본인이 등록한 상품만 수정할 수 있습니다.");
        }

        if (input.categoryId() != null) {
            Category category = categoryRepository
                    .findById(input.categoryId())
                    .orElseThrow(() -> new NotFoundException("카테고리를 찾을 수 없습니다."));
            product.setCategory(category);
        }
        if (input.name() != null) product.setName(input.name());
        if (input.description() != null) product.setDescription(input.description());
        if (input.price() != null) product.setPrice(input.price());
        if (input.stock() != null) product.setStock(input.stock());
        if (input.isActive() != null) product.setActive(input.isActive());
        if (input.imageUrls() != null) {
            productImageRepository.deleteByProduct_Id(product.getId());
            product.getImages().clear();
            attachImages(product, input.imageUrls());
        }

        productRepository.saveAndFlush(product);
        return ProductSummaryResponse.from(product);
    }

    private void attachImages(Product product, List<String> imageUrls) {
        List<ProductImage> images = new ArrayList<>();
        for (int i = 0; i < imageUrls.size(); i++) {
            ProductImage image = new ProductImage();
            image.setProduct(product);
            image.setUrl(imageUrls.get(i));
            image.setSortOrder(i);
            images.add(image);
        }
        product.getImages().addAll(images);
    }

    @Transactional
    public ProductReviewResponse createReview(String userId, String productId, CreateReviewRequest input) {
        Product product = productRepository.findById(productId).orElse(null);
        if (product == null || !product.isActive()) {
            throw new NotFoundException("상품을 찾을 수 없습니다.");
        }
        User user = userRepository.findById(userId).orElseThrow(NotFoundException::new);

        Review review = new Review();
        review.setProduct(product);
        review.setUser(user);
        review.setRating(input.rating());
        review.setContent(input.content());
        try {
            reviewRepository.saveAndFlush(review);
        } catch (DataIntegrityViolationException e) {
            throw new ConflictException("이미 이 상품에 리뷰를 작성하셨습니다.");
        }
        return ProductReviewResponse.from(review);
    }

    @Transactional
    public ProductReviewResponse updateReview(String userId, String reviewId, CreateReviewRequest input) {
        Review review = reviewRepository.findById(reviewId).orElseThrow(() -> new NotFoundException("리뷰를 찾을 수 없습니다."));
        if (!review.getUser().getId().equals(userId)) {
            throw new ForbiddenException("본인 리뷰만 수정할 수 있습니다.");
        }
        review.setRating(input.rating());
        review.setContent(input.content());
        reviewRepository.saveAndFlush(review);
        return ProductReviewResponse.from(review);
    }

    @Transactional
    public void deleteReview(String userId, String reviewId) {
        Review review = reviewRepository.findById(reviewId).orElseThrow(() -> new NotFoundException("리뷰를 찾을 수 없습니다."));
        if (!review.getUser().getId().equals(userId)) {
            throw new ForbiddenException("본인 리뷰만 삭제할 수 있습니다.");
        }
        reviewRepository.delete(review);
    }
}
