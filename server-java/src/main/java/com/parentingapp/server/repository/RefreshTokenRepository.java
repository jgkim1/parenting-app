package com.parentingapp.server.repository;

import com.parentingapp.server.domain.RefreshToken;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, String> {
    Optional<RefreshToken> findFirstByUser_IdAndTokenHashAndRevokedFalse(String userId, String tokenHash);

    @Modifying
    @Query("update RefreshToken r set r.revoked = true where r.tokenHash = :tokenHash and r.revoked = false")
    int revokeByTokenHash(@Param("tokenHash") String tokenHash);
}
