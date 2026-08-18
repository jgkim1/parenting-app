package com.parentingapp.server.article;

import com.parentingapp.server.article.dto.ArticleDetailResponse;
import com.parentingapp.server.article.dto.ArticleSummaryResponse;
import com.parentingapp.server.article.dto.CreateArticleRequest;
import com.parentingapp.server.article.dto.UpdateArticleRequest;
import com.parentingapp.server.common.dto.PageResponse;
import com.parentingapp.server.common.security.AuthenticatedUser;
import com.parentingapp.server.domain.UserRole;
import jakarta.validation.Valid;
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
@RequestMapping("/api/articles")
public class ArticleController {

    private final ArticleService articleService;

    public ArticleController(ArticleService articleService) {
        this.articleService = articleService;
    }

    @GetMapping
    public PageResponse<ArticleSummaryResponse> list(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String categoryId,
            @RequestParam(required = false, defaultValue = "false") boolean includeInactive) {
        boolean effective = includeInactive && currentUser != null && currentUser.role() == UserRole.ADMIN;
        return articleService.listArticles(page, pageSize, categoryId, effective);
    }

    @GetMapping("/{id}")
    public ArticleDetailResponse get(
            @AuthenticationPrincipal AuthenticatedUser currentUser,
            @PathVariable String id,
            @RequestParam(required = false, defaultValue = "false") boolean includeInactive) {
        boolean effective = currentUser != null && currentUser.role() == UserRole.ADMIN;
        return articleService.getArticleById(id, effective);
    }

    @PostMapping
    public ResponseEntity<ArticleDetailResponse> create(
            @AuthenticationPrincipal AuthenticatedUser currentUser, @Valid @RequestBody CreateArticleRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(articleService.createArticle(currentUser.id(), request));
    }

    @PatchMapping("/{id}")
    public ArticleDetailResponse update(@PathVariable String id, @Valid @RequestBody UpdateArticleRequest request) {
        return articleService.updateArticle(id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        articleService.deleteArticle(id);
        return ResponseEntity.noContent().build();
    }
}
