package com.parentingapp.server.repository;

import com.parentingapp.server.domain.Like;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

public interface LikeRepository extends JpaRepository<Like, String> {
    Optional<Like> findByPost_IdAndUser_Id(String postId, String userId);

    long countByPost_Id(String postId);

    @Transactional
    void deleteByPost_IdAndUser_Id(String postId, String userId);
}
