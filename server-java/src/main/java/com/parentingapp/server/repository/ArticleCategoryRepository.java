package com.parentingapp.server.repository;

import com.parentingapp.server.domain.ArticleCategory;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ArticleCategoryRepository extends JpaRepository<ArticleCategory, String> {
    List<ArticleCategory> findAllByOrderByNameAsc();
}
