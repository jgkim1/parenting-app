package com.parentingapp.server.auth.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

// https://oauth2.googleapis.com/tokeninfo?id_token=... 응답. 구글이 서명을 자체 검증해준
// 결과이므로, 우리는 aud(발급 대상)만 우리 앱 클라이언트 ID와 일치하는지 확인하면 된다.
@JsonIgnoreProperties(ignoreUnknown = true)
public record GoogleTokenInfo(String aud, String sub, String email, String name) {}
