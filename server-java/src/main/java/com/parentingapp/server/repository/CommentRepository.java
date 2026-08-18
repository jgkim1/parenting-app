package com.parentingapp.server.repository;

import com.parentingapp.server.domain.Comment;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CommentRepository extends JpaRepository<Comment, String> {
    List<Comment> findByPost_IdOrderByCreatedAtAsc(String postId, Pageable pageable);

    long countByPost_Id(String postId);
}
