package com.parentingapp.server.common.security;

import com.parentingapp.server.domain.UserRole;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.security.Key;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Date;
import java.util.UUID;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class JwtService {

    private final Key accessKey;
    private final Key refreshKey;
    private final long accessExpiresMinutes;
    private final long refreshExpiresDays;

    public JwtService(
            @Value("${app.jwt.access-secret}") String accessSecret,
            @Value("${app.jwt.refresh-secret}") String refreshSecret,
            @Value("${app.jwt.access-expires-minutes}") long accessExpiresMinutes,
            @Value("${app.jwt.refresh-expires-days}") long refreshExpiresDays) {
        // HMAC-SHA 키는 최소 길이 요구사항이 있어, 짧은 시크릿도 안전하게 패딩한다.
        this.accessKey = toKey(accessSecret);
        this.refreshKey = toKey(refreshSecret);
        this.accessExpiresMinutes = accessExpiresMinutes;
        this.refreshExpiresDays = refreshExpiresDays;
    }

    private static Key toKey(String secret) {
        byte[] bytes = secret.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        if (bytes.length < 32) {
            byte[] padded = new byte[32];
            System.arraycopy(bytes, 0, padded, 0, bytes.length);
            bytes = padded;
        }
        return new SecretKeySpec(bytes, "HmacSHA256");
    }

    public String signAccessToken(String userId, UserRole role) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userId)
                .claim("role", role.name())
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(accessExpiresMinutes * 60)))
                .signWith(accessKey)
                .compact();
    }

    // jti(토큰 고유 id)를 매번 랜덤으로 넣는다. 같은 payload+같은 초에 서명하면 바이트 단위로
    // 동일한 문자열이 나올 수 있는데, 리프레시 토큰은 해시로 재사용 여부를 판별하므로
    // (AuthService) 동일 문자열이 나오면 회전된 새 토큰과 폐기된 토큰이 같은 해시를 가져
    // 재사용 탐지가 무력화된다.
    public String signRefreshToken(String userId, UserRole role) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(userId)
                .claim("role", role.name())
                .id(UUID.randomUUID().toString())
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(refreshExpiresDays * 24 * 60 * 60)))
                .signWith(refreshKey)
                .compact();
    }

    public AuthenticatedUser verifyAccessToken(String token) {
        Claims claims = Jwts.parser().verifyWith((javax.crypto.SecretKey) accessKey).build()
                .parseSignedClaims(token)
                .getPayload();
        return toAuthenticatedUser(claims);
    }

    public AuthenticatedUser verifyRefreshToken(String token) {
        Claims claims = Jwts.parser().verifyWith((javax.crypto.SecretKey) refreshKey).build()
                .parseSignedClaims(token)
                .getPayload();
        return toAuthenticatedUser(claims);
    }

    private AuthenticatedUser toAuthenticatedUser(Claims claims) {
        return new AuthenticatedUser(claims.getSubject(), UserRole.valueOf(claims.get("role", String.class)));
    }

    public LocalDateTime getExpiry(String token, boolean isRefreshToken) {
        try {
            Key key = isRefreshToken ? refreshKey : accessKey;
            Claims claims = Jwts.parser().verifyWith((javax.crypto.SecretKey) key).build()
                    .parseSignedClaims(token)
                    .getPayload();
            return LocalDateTime.ofInstant(claims.getExpiration().toInstant(), ZoneId.systemDefault());
        } catch (JwtException e) {
            throw new IllegalStateException("토큰에서 만료 정보를 읽을 수 없습니다.", e);
        }
    }
}
