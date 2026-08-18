package com.parentingapp.server.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

// 관리자가 등록하는 광고 배너. 삭제는 하드 삭제, 노출 중지는 isActive로 한다.
@Entity
@Table(
        name = "ads",
        indexes = {@Index(name = "idx_ad_placement", columnList = "placement")})
@Getter
@Setter
@NoArgsConstructor
public class Ad {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "CHAR(36)")
    private String id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AdPlacement placement;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(name = "image_url", nullable = false, length = 1000)
    private String imageUrl;

    @Column(name = "link_url", length = 1000)
    private String linkUrl;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder = 0;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
