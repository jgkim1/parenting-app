package com.parentingapp.server.child;

import com.parentingapp.server.child.dto.ChildResponse;
import com.parentingapp.server.child.dto.CreateChildRequest;
import com.parentingapp.server.common.exception.ForbiddenException;
import com.parentingapp.server.common.exception.NotFoundException;
import com.parentingapp.server.domain.Child;
import com.parentingapp.server.domain.User;
import com.parentingapp.server.repository.ChildRepository;
import com.parentingapp.server.repository.UserRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ChildService {

    private final ChildRepository childRepository;
    private final UserRepository userRepository;

    public ChildService(ChildRepository childRepository, UserRepository userRepository) {
        this.childRepository = childRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<ChildResponse> listChildren(String userId) {
        return childRepository.findByUser_IdOrderByBirthDateDesc(userId).stream().map(ChildResponse::from).toList();
    }

    @Transactional
    public ChildResponse createChild(String userId, CreateChildRequest input) {
        User user = userRepository.findById(userId).orElseThrow(NotFoundException::new);
        Child child = new Child();
        child.setUser(user);
        child.setNickname(input.nickname());
        child.setGender(input.gender());
        child.setBirthDate(input.birthDate());
        childRepository.saveAndFlush(child);
        return ChildResponse.from(child);
    }

    @Transactional
    public ChildResponse updateChild(String userId, String childId, CreateChildRequest input) {
        Child child = childRepository.findById(childId).orElseThrow(() -> new NotFoundException("자녀 정보를 찾을 수 없습니다."));
        if (!child.getUser().getId().equals(userId)) {
            throw new ForbiddenException("본인 자녀 정보만 수정할 수 있습니다.");
        }
        child.setNickname(input.nickname());
        child.setGender(input.gender());
        child.setBirthDate(input.birthDate());
        childRepository.saveAndFlush(child);
        return ChildResponse.from(child);
    }

    @Transactional
    public void deleteChild(String userId, String childId) {
        Child child = childRepository.findById(childId).orElseThrow(() -> new NotFoundException("자녀 정보를 찾을 수 없습니다."));
        if (!child.getUser().getId().equals(userId)) {
            throw new ForbiddenException("본인 자녀 정보만 삭제할 수 있습니다.");
        }
        childRepository.delete(child);
    }
}
