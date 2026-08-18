package com.parentingapp.server.common;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

// 업로드된 이미지를 정적으로 서빙한다(Express의 app.use("/uploads", express.static(...))와 동일).
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${uploads.dir}")
    private String uploadsDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String location = java.nio.file.Paths.get(uploadsDir).toAbsolutePath().toUri().toString();
        registry.addResourceHandler("/uploads/**").addResourceLocations(location);
    }
}
