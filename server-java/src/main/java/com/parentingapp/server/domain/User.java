package com.parentingapp.server.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.UuidGenerator;

@Entity
@Table(
        name = "users",
        indexes = {@Index(name = "idx_user_email", columnList = "email")},
        uniqueConstraints = {
            @UniqueConstraint(name = "uk_user_provider_provider_id", columnNames = {"provider", "provider_id"})
        })
@Getter
@Setter
@NoArgsConstructor
public class User {

    @Id
    @UuidGenerator
    @Column(columnDefinition = "CHAR(36)")
    private String id;

    @Column(nullable = false, unique = true)
    private String email;

    // 소셜 로그인 계정은 비밀번호가 없으므로 nullable. LOCAL 계정만 필수로 채운다.
    @Column(name = "password_hash")
    private String passwordHash;

    @Column(nullable = false)
    private String nickname;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role = UserRole.CUSTOMER;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AuthProvider provider = AuthProvider.LOCAL;

    // 프로바이더가 내려주는 사용자 고유 id(카카오 id, 구글 sub). LOCAL 계정은 null.
    @Column(name = "provider_id")
    private String providerId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
