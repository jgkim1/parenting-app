package com.parentingapp.server.user;

import com.parentingapp.server.auth.dto.UserResponse;
import com.parentingapp.server.common.exception.NotFoundException;
import com.parentingapp.server.common.security.AuthenticatedUser;
import com.parentingapp.server.repository.UserRepository;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal AuthenticatedUser currentUser) {
        var user = userRepository
                .findById(currentUser.id())
                .orElseThrow(() -> new NotFoundException("사용자를 찾을 수 없습니다."));
        return UserResponse.from(user);
    }
}
