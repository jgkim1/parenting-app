package com.parentingapp.server.article;

import com.parentingapp.server.article.dto.ArticleCategoryResponse;
import com.parentingapp.server.article.dto.ArticleDetailResponse;
import com.parentingapp.server.article.dto.ArticleSummaryResponse;
import com.parentingapp.server.article.dto.CreateArticleRequest;
import com.parentingapp.server.article.dto.UpdateArticleRequest;
import com.parentingapp.server.common.dto.PageResponse;
import com.parentingapp.server.common.exception.NotFoundException;
import com.parentingapp.server.domain.Article;
import com.parentingapp.server.domain.ArticleCategory;
import com.parentingapp.server.domain.User;
import com.parentingapp.server.repository.ArticleCategoryRepository;
import com.parentingapp.server.repository.ArticleRepository;
import com.parentingapp.server.repository.UserRepository;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ArticleService {

    private final ArticleRepository articleRepository;
    private final ArticleCategoryRepository articleCategoryRepository;
    private final UserRepository userRepository;

    public ArticleService(
            ArticleRepository articleRepository,
            ArticleCategoryRepository articleCategoryRepository,
            UserRepository userRepository) {
        this.articleRepository = articleRepository;
        this.articleCategoryRepository = articleCategoryRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<ArticleCategoryResponse> listCategories() {
        return articleCategoryRepository.findAllByOrderByNameAsc().stream()
                .map(ArticleCategoryResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public PageResponse<ArticleSummaryResponse> listArticles(
            int page, int pageSize, String categoryId, boolean includeInactive) {
        Boolean activeFilter = includeInactive ? null : Boolean.TRUE;
        Page<Article> result = articleRepository.search(
                activeFilter, categoryId, PageRequest.of(page - 1, pageSize, Sort.by(Sort.Direction.DESC, "createdAt")));
        return PageResponse.of(result.map(ArticleSummaryResponse::from), page, pageSize);
    }

    @Transactional
    public ArticleDetailResponse getArticleById(String id, boolean includeInactive) {
        Article article = articleRepository.findById(id).orElseThrow(() -> new NotFoundException("아티클을 찾을 수 없습니다."));
        if (!article.isActive() && !includeInactive) {
            throw new NotFoundException("아티클을 찾을 수 없습니다.");
        }
        // 관리자가 관리 화면에서 미리보기하는 경우(비공개 글 포함 조회)는 조회수를 올리지 않는다.
        if (!includeInactive) {
            article.setViewCount(article.getViewCount() + 1);
            articleRepository.saveAndFlush(article);
        }
        return ArticleDetailResponse.from(article);
    }

    @Transactional
    public ArticleDetailResponse createArticle(String authorId, CreateArticleRequest input) {
        ArticleCategory category = articleCategoryRepository
                .findById(input.categoryId())
                .orElseThrow(() -> new NotFoundException("카테고리를 찾을 수 없습니다."));
        User author = userRepository.findById(authorId).orElseThrow(NotFoundException::new);

        Article article = new Article();
        article.setAuthor(author);
        article.setCategory(category);
        article.setTitle(input.title());
        article.setContent(input.content());
        article.setThumbnailUrl(input.thumbnailUrl());
        articleRepository.saveAndFlush(article);

        return ArticleDetailResponse.from(article);
    }

    @Transactional
    public ArticleDetailResponse updateArticle(String id, UpdateArticleRequest input) {
        Article article = articleRepository.findById(id).orElseThrow(() -> new NotFoundException("아티클을 찾을 수 없습니다."));

        if (input.categoryId() != null) {
            ArticleCategory category = articleCategoryRepository
                    .findById(input.categoryId())
                    .orElseThrow(() -> new NotFoundException("카테고리를 찾을 수 없습니다."));
            article.setCategory(category);
        }
        if (input.title() != null) article.setTitle(input.title());
        if (input.content() != null) article.setContent(input.content());
        if (input.thumbnailUrl() != null) article.setThumbnailUrl(input.thumbnailUrl());
        if (input.isActive() != null) article.setActive(input.isActive());

        articleRepository.saveAndFlush(article);
        return ArticleDetailResponse.from(article);
    }

    // 아티클은 주문/리뷰처럼 이력 보존이 필요한 다른 데이터가 참조하지 않아 하드 삭제한다.
    @Transactional
    public void deleteArticle(String id) {
        if (!articleRepository.existsById(id)) {
            throw new NotFoundException("아티클을 찾을 수 없습니다.");
        }
        articleRepository.deleteById(id);
    }
}
