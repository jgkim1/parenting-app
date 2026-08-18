package com.parentingapp.server.article;

import com.parentingapp.server.article.dto.ArticleCategoryResponse;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/article-categories")
public class ArticleCategoryController {

    private final ArticleService articleService;

    public ArticleCategoryController(ArticleService articleService) {
        this.articleService = articleService;
    }

    @GetMapping
    public List<ArticleCategoryResponse> list() {
        return articleService.listCategories();
    }
}
