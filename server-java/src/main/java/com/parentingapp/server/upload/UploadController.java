package com.parentingapp.server.upload;

import com.parentingapp.server.common.exception.BadRequestException;
import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/uploads")
public class UploadController {

    private static final Set<String> ALLOWED_MIME_TYPES =
            Set.of("image/jpeg", "image/png", "image/webp", "image/gif");

    @Value("${uploads.dir}")
    private String uploadsDir;

    @PostMapping
    public ResponseEntity<Map<String, String>> upload(
            @RequestParam("file") MultipartFile file, HttpServletRequest request) throws IOException {
        if (file.isEmpty()) {
            throw new BadRequestException("업로드할 파일이 없습니다.");
        }
        if (!ALLOWED_MIME_TYPES.contains(file.getContentType())) {
            throw new BadRequestException("이미지 파일(jpg, png, webp, gif)만 업로드할 수 있습니다.");
        }

        Path dir = Paths.get(uploadsDir).toAbsolutePath();
        Files.createDirectories(dir);

        String originalName = file.getOriginalFilename() != null ? file.getOriginalFilename() : "";
        String ext = originalName.contains(".") ? originalName.substring(originalName.lastIndexOf('.')) : "";
        String filename = UUID.randomUUID() + ext;
        Path target = dir.resolve(filename);
        file.transferTo(target);

        String url = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort()
                + "/uploads/" + filename;
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("url", url));
    }
}
