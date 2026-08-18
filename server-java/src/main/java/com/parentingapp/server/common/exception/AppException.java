package com.parentingapp.server.common.exception;

import org.springframework.http.HttpStatus;

// 예상 가능한 도메인 에러를 표현하는 베이스 클래스. GlobalExceptionHandler가 status와
// message를 그대로 응답으로 변환한다.
public class AppException extends RuntimeException {
    private final HttpStatus status;

    public AppException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
