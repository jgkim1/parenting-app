package com.parentingapp.server.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

@Entity
@Table(
        name = "posts",
        indexes = {
            @Index(name = "idx_post_author_id", columnList = "author_id"),
            @Index(name = "idx_post_created_at", columnList = "created_at")
        })
@Getter
@Setter
@NoArgsConstructor
public class Post {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "CHAR(36)")
    private String id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false)
    private User author;

    @Column(nullable = false)
    private String title;

    // 검색 시 lower()/like를 써야 해서 CLOB(@Lob) 대신 TEXT로 매핑한다 - Hibernate가
    // CLOB에는 lower() 같은 문자열 함수 적용을 허용하지 않는다.
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    // 자유 텍스트 카테고리(상품 카테고리와 무관)
    @Column(length = 50)
    private String category;

    @Column(name = "image_url", length = 1000)
    private String imageUrl;

    @Column(name = "view_count", nullable = false)
    private Integer viewCount = 0;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
