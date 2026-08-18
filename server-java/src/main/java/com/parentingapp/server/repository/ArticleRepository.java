package com.parentingapp.server.repository;

import com.parentingapp.server.domain.Article;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ArticleRepository extends JpaRepository<Article, String> {

    @Query(
            "select a from Article a where"
                    + " (:active is null or a.active = :active)"
                    + " and (:categoryId is null or a.category.id = :categoryId)")
    Page<Article> search(@Param("active") Boolean active, @Param("categoryId") String categoryId, Pageable pageable);
}
