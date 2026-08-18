package com.parentingapp.server.common;

import com.parentingapp.server.common.security.JwtAuthenticationFilter;
import com.parentingapp.server.common.security.RestAccessDeniedHandler;
import com.parentingapp.server.common.security.RestAuthEntryPoint;
import java.util.List;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

// 각 규칙은 server/src/modules/*/*.routes.ts의 requireAuth·requireRole·optionalAuth
// 조합을 경로+HTTP 메서드 단위로 그대로 옮긴 것이다.
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final RestAuthEntryPoint authEntryPoint;
    private final RestAccessDeniedHandler accessDeniedHandler;

    public SecurityConfig(
            JwtAuthenticationFilter jwtAuthenticationFilter,
            RestAuthEntryPoint authEntryPoint,
            RestAccessDeniedHandler accessDeniedHandler) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.authEntryPoint = authEntryPoint;
        this.accessDeniedHandler = accessDeniedHandler;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.csrf(csrf -> csrf.disable())
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(ex -> ex.authenticationEntryPoint(authEntryPoint).accessDeniedHandler(accessDeniedHandler))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, "/health", "/uploads/**").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/**").permitAll()
                        .requestMatchers(
                                HttpMethod.GET,
                                "/api/categories",
                                "/api/products",
                                "/api/products/*",
                                "/api/article-categories",
                                "/api/articles",
                                "/api/articles/*",
                                "/api/ads",
                                "/api/posts",
                                "/api/posts/*")
                        .permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/products").hasAnyRole("SELLER", "ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/products/*").hasAnyRole("SELLER", "ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/products/*/reviews").authenticated()
                        .requestMatchers(HttpMethod.PATCH, "/api/reviews/*").authenticated()
                        .requestMatchers(HttpMethod.DELETE, "/api/reviews/*").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/articles").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/articles/*").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/articles/*").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.POST, "/api/ads").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.PATCH, "/api/ads/*").hasRole("ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/ads/*").hasRole("ADMIN")
                        .requestMatchers("/api/cart/**").authenticated()
                        .requestMatchers("/api/orders/**").authenticated()
                        .requestMatchers("/api/children/**").authenticated()
                        .requestMatchers(HttpMethod.GET, "/api/users/me").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/uploads").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/posts").authenticated()
                        .requestMatchers(HttpMethod.PATCH, "/api/posts/*").authenticated()
                        .requestMatchers(HttpMethod.DELETE, "/api/posts/*").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/posts/*/comments").authenticated()
                        .requestMatchers(HttpMethod.POST, "/api/posts/*/like").authenticated()
                        .requestMatchers(HttpMethod.DELETE, "/api/comments/*").authenticated()
                        .anyRequest().authenticated())
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of("*"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }
}
