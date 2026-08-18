package com.parentingapp.server.common.security;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import org.springframework.stereotype.Component;

// 리프레시 토큰은 자체 엔트로피가 충분한 JWT이므로, bcrypt 대신 빠른 sha256으로 해시하여
// DB에 저장한다(탈취되어도 원문 토큰 없이는 재사용 불가).
@Component
public class TokenHasher {

    public String hash(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] bytes = digest.digest(token.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : bytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
