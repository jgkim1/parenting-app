package com.parentingapp.server.auth;

import com.parentingapp.server.auth.dto.AuthResponse;
import com.parentingapp.server.auth.dto.GoogleLoginRequest;
import com.parentingapp.server.auth.dto.GoogleTokenInfo;
import com.parentingapp.server.auth.dto.KakaoLoginRequest;
import com.parentingapp.server.auth.dto.KakaoUserMeResponse;
import com.parentingapp.server.auth.dto.LoginRequest;
import com.parentingapp.server.auth.dto.RefreshRequest;
import com.parentingapp.server.auth.dto.SignupRequest;
import com.parentingapp.server.auth.dto.UserResponse;
import com.parentingapp.server.common.exception.ConflictException;
import com.parentingapp.server.common.exception.ServiceUnavailableException;
import com.parentingapp.server.common.exception.UnauthorizedException;
import com.parentingapp.server.common.security.AuthenticatedUser;
import com.parentingapp.server.common.security.JwtService;
import com.parentingapp.server.common.security.TokenHasher;
import com.parentingapp.server.domain.AuthProvider;
import com.parentingapp.server.domain.RefreshToken;
import com.parentingapp.server.domain.User;
import com.parentingapp.server.domain.UserRole;
import com.parentingapp.server.repository.RefreshTokenRepository;
import com.parentingapp.server.repository.UserRepository;
import io.jsonwebtoken.JwtException;
import java.time.LocalDateTime;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtService jwtService;
    private final TokenHasher tokenHasher;
    private final PasswordEncoder passwordEncoder;
    private final String googleClientId;
    private final RestClient restClient = RestClient.create();

    public AuthService(
            UserRepository userRepository,
            RefreshTokenRepository refreshTokenRepository,
            JwtService jwtService,
            TokenHasher tokenHasher,
            PasswordEncoder passwordEncoder,
            @Value("${app.google.client-id:}") String googleClientId) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.jwtService = jwtService;
        this.tokenHasher = tokenHasher;
        this.passwordEncoder = passwordEncoder;
        this.googleClientId = googleClientId;
    }

    @Transactional
    public AuthResponse signup(SignupRequest input) {
        if (userRepository.findByEmail(input.email()).isPresent()) {
            throw new ConflictException("이미 가입된 이메일입니다.");
        }

        User user = new User();
        user.setEmail(input.email());
        user.setPasswordHash(passwordEncoder.encode(input.password()));
        user.setNickname(input.nickname());
        userRepository.saveAndFlush(user);

        return issueAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest input) {
        User user = userRepository.findByEmail(input.email()).orElse(null);
        // 소셜 로그인으로만 가입한 계정은 passwordHash가 없어 비밀번호 로그인이 애초에 불가능하다.
        boolean matches = user != null
                && user.getPasswordHash() != null
                && passwordEncoder.matches(input.password(), user.getPasswordHash());

        if (!matches) {
            // 이메일 존재 여부가 드러나지 않도록 동일한 메시지를 사용한다.
            throw new UnauthorizedException("이메일 또는 비밀번호가 올바르지 않습니다.");
        }

        return issueAuthResponse(user);
    }

    @Transactional
    public AuthResponse refresh(RefreshRequest input) {
        AuthenticatedUser payload;
        try {
            payload = jwtService.verifyRefreshToken(input.refreshToken());
        } catch (JwtException | IllegalArgumentException e) {
            throw new UnauthorizedException("리프레시 토큰이 유효하지 않거나 만료되었습니다.");
        }

        String tokenHash = tokenHasher.hash(input.refreshToken());
        RefreshToken stored = refreshTokenRepository
                .findFirstByUser_IdAndTokenHashAndRevokedFalse(payload.id(), tokenHash)
                .orElse(null);

        if (stored == null || stored.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new UnauthorizedException("리프레시 토큰이 유효하지 않거나 만료되었습니다.");
        }

        // 재사용 공격을 막기 위해 사용한 리프레시 토큰은 즉시 무효화하고(rotate) 새로 발급한다.
        stored.setRevoked(true);
        refreshTokenRepository.save(stored);

        User user = userRepository.findById(payload.id()).orElseThrow(UnauthorizedException::new);
        return issueAuthResponse(user);
    }

    @Transactional
    public void logout(RefreshRequest input) {
        refreshTokenRepository.revokeByTokenHash(tokenHasher.hash(input.refreshToken()));
    }

    // 클라이언트(Flutter)가 카카오 SDK로 이미 로그인해서 받은 사용자 액세스 토큰을 그대로 받아
    // 카카오 서버에 프로필을 조회하는 방식이라, 서버는 별도의 카카오 앱 키가 필요 없다.
    @Transactional
    public AuthResponse loginWithKakao(KakaoLoginRequest input) {
        KakaoUserMeResponse profile;
        try {
            profile = restClient
                    .get()
                    .uri("https://kapi.kakao.com/v2/user/me")
                    .header("Authorization", "Bearer " + input.accessToken())
                    .retrieve()
                    .body(KakaoUserMeResponse.class);
        } catch (RestClientException e) {
            throw new UnauthorizedException("카카오 인증에 실패했습니다.");
        }

        if (profile == null || profile.id() == null) {
            throw new UnauthorizedException("카카오 인증에 실패했습니다.");
        }

        String email = profile.kakaoAccount() != null ? profile.kakaoAccount().email() : null;
        String nickname = profile.kakaoAccount() != null && profile.kakaoAccount().profile() != null
                ? profile.kakaoAccount().profile().nickname()
                : null;

        return findOrCreateSocialUser(
                AuthProvider.KAKAO,
                String.valueOf(profile.id()),
                email,
                nickname != null ? nickname : "카카오사용자" + profile.id());
    }

    // 구글은 클라이언트가 받은 ID 토큰(JWT) 자체를 서명 검증해야 하는데, 별도 클라이언트
    // 라이브러리를 추가하는 대신 구글이 직접 서명을 검증해주는 tokeninfo 엔드포인트를 쓴다.
    // 우리 앱의 클라이언트 ID(발급 대상)와 aud가 일치하는지는 우리가 한 번 더 확인한다.
    @Transactional
    public AuthResponse loginWithGoogle(GoogleLoginRequest input) {
        if (googleClientId == null || googleClientId.isBlank()) {
            throw new ServiceUnavailableException("구글 로그인이 아직 설정되지 않았습니다.");
        }

        GoogleTokenInfo tokenInfo;
        try {
            tokenInfo = restClient
                    .get()
                    .uri("https://oauth2.googleapis.com/tokeninfo?id_token={idToken}", input.idToken())
                    .retrieve()
                    .body(GoogleTokenInfo.class);
        } catch (RestClientException e) {
            throw new UnauthorizedException("구글 인증에 실패했습니다.");
        }

        if (tokenInfo == null || !googleClientId.equals(tokenInfo.aud()) || tokenInfo.sub() == null) {
            throw new UnauthorizedException("구글 인증에 실패했습니다.");
        }

        String nickname = tokenInfo.name() != null
                ? tokenInfo.name()
                : "구글사용자" + tokenInfo.sub().substring(0, Math.min(6, tokenInfo.sub().length()));

        return findOrCreateSocialUser(AuthProvider.GOOGLE, tokenInfo.sub(), tokenInfo.email(), nickname);
    }

    // 프로바이더별 프로필로 기존 계정을 찾거나 새로 만든다. 이미 이메일/비밀번호로 가입된
    // 계정과 같은 이메일이 들어오면 계정을 몰래 합치지 않고 명시적으로 거부한다(계정 탈취 방지).
    private AuthResponse findOrCreateSocialUser(AuthProvider provider, String providerId, String email, String nickname) {
        User user = userRepository.findByProviderAndProviderId(provider, providerId).orElse(null);

        if (user == null) {
            if (email != null) {
                userRepository.findByEmail(email).ifPresent(existing -> {
                    throw new ConflictException(
                            existing.getProvider() == AuthProvider.LOCAL
                                    ? "이미 이메일/비밀번호로 가입된 이메일입니다. 해당 방식으로 로그인해주세요."
                                    : "이미 다른 방식으로 가입된 이메일입니다.");
                });
            }

            user = new User();
            // 카카오는 이메일 제공에 사용자 동의가 필요해 없을 수 있으므로, 없으면 계정 식별용
            // 더미 이메일을 만든다. 실제 알림/찾기 용도로는 쓰이지 않는다.
            user.setEmail(email != null ? email : provider.name().toLowerCase() + "_" + providerId + "@social.local");
            user.setNickname(nickname);
            user.setProvider(provider);
            user.setProviderId(providerId);
            user.setPasswordHash(null);
            userRepository.saveAndFlush(user);
        }

        return issueAuthResponse(user);
    }

    private AuthResponse issueAuthResponse(User user) {
        String accessToken = jwtService.signAccessToken(user.getId(), user.getRole());
        String refreshToken = jwtService.signRefreshToken(user.getId(), user.getRole());

        RefreshToken entity = new RefreshToken();
        entity.setUser(user);
        entity.setTokenHash(tokenHasher.hash(refreshToken));
        entity.setExpiresAt(jwtService.getExpiry(refreshToken, true));
        refreshTokenRepository.save(entity);

        return new AuthResponse(UserResponse.from(user), accessToken, refreshToken);
    }
}
