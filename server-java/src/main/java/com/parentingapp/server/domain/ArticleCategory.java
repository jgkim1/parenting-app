package com.parentingapp.server.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.UuidGenerator;

// 육아 정보 아티클(매거진) 카테고리 - 예방접종, 이유식, 수면교육 등 주제별 분류
@Entity
@Table(name = "article_categories")
@Getter
@Setter
@NoArgsConstructor
public class ArticleCategory {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "CHAR(36)")
    private String id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(nullable = false, unique = true)
    private String slug;
}
