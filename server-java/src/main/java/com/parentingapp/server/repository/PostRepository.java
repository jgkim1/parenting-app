package com.parentingapp.server.repository;

import com.parentingapp.server.domain.Post;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PostRepository extends JpaRepository<Post, String> {

    @Query(
            "select p from Post p where"
                    + " (:category is null or p.category = :category)"
                    + " and (:q is null or lower(p.title) like lower(concat('%', :q, '%'))"
                    + "      or lower(p.content) like lower(concat('%', :q, '%')))")
    Page<Post> search(@Param("category") String category, @Param("q") String q, Pageable pageable);
}
