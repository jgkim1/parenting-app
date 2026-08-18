package com.parentingapp.server.common.security;

import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

// Authorization: Bearer <accessToken> 헤더를 검증해 SecurityContext를 채운다. 토큰이
// 없거나 유효하지 않으면 그냥 통과시킨다(비로그인 상태) — requireAuth에 해당하는 강제는
// SecurityConfig의 경로별 authorizeHttpRequests 규칙이 담당한다(Express의 requireAuth와
// optionalAuth 미들웨어를 이 필터 하나 + 경로 규칙으로 합친 구조).
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    public JwtAuthenticationFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring("Bearer ".length());
            try {
                AuthenticatedUser user = jwtService.verifyAccessToken(token);
                var authorities = List.of(new SimpleGrantedAuthority("ROLE_" + user.role().name()));
                var authentication = new UsernamePasswordAuthenticationToken(user, null, authorities);
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } catch (JwtException | IllegalArgumentException ignored) {
                // 무효한 토큰은 비로그인 상태로 취급한다(익명 요청과 동일하게 흘러가게 둔다).
            }
        }
        filterChain.doFilter(request, response);
    }
}
