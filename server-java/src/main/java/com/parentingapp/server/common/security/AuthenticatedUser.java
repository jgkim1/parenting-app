package com.parentingapp.server.common.security;

import com.parentingapp.server.domain.UserRole;

public record AuthenticatedUser(String id, UserRole role) {}
