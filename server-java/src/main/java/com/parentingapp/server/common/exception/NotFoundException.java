package com.parentingapp.server.common.exception;

import org.springframework.http.HttpStatus;

public class NotFoundException extends AppException {
    public NotFoundException(String message) {
        super(HttpStatus.NOT_FOUND, message);
    }

    public NotFoundException() {
        this("리소스를 찾을 수 없습니다.");
    }
}
