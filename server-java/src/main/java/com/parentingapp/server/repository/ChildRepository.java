package com.parentingapp.server.repository;

import com.parentingapp.server.domain.Child;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ChildRepository extends JpaRepository<Child, String> {
    List<Child> findByUser_IdOrderByBirthDateDesc(String userId);
}
