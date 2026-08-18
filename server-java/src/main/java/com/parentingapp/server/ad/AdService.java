package com.parentingapp.server.ad;

import com.parentingapp.server.ad.dto.AdResponse;
import com.parentingapp.server.ad.dto.CreateAdRequest;
import com.parentingapp.server.ad.dto.UpdateAdRequest;
import com.parentingapp.server.common.exception.NotFoundException;
import com.parentingapp.server.domain.Ad;
import com.parentingapp.server.domain.AdPlacement;
import com.parentingapp.server.repository.AdRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdService {

    private final AdRepository adRepository;

    public AdService(AdRepository adRepository) {
        this.adRepository = adRepository;
    }

    @Transactional(readOnly = true)
    public List<AdResponse> listAds(AdPlacement placement, boolean includeInactive) {
        Boolean activeFilter = includeInactive ? null : Boolean.TRUE;
        return adRepository.search(activeFilter, placement).stream().map(AdResponse::from).toList();
    }

    @Transactional
    public AdResponse createAd(CreateAdRequest input) {
        Ad ad = new Ad();
        ad.setPlacement(input.placement());
        ad.setTitle(input.title());
        ad.setImageUrl(input.imageUrl());
        ad.setLinkUrl(input.linkUrl());
        ad.setSortOrder(input.sortOrder());
        adRepository.saveAndFlush(ad);
        return AdResponse.from(ad);
    }

    @Transactional
    public AdResponse updateAd(String id, UpdateAdRequest input) {
        Ad ad = adRepository.findById(id).orElseThrow(() -> new NotFoundException("광고를 찾을 수 없습니다."));
        if (input.placement() != null) ad.setPlacement(input.placement());
        if (input.title() != null) ad.setTitle(input.title());
        if (input.imageUrl() != null) ad.setImageUrl(input.imageUrl());
        if (input.linkUrl() != null) ad.setLinkUrl(input.linkUrl());
        if (input.sortOrder() != null) ad.setSortOrder(input.sortOrder());
        if (input.isActive() != null) ad.setActive(input.isActive());
        adRepository.saveAndFlush(ad);
        return AdResponse.from(ad);
    }

    // 광고는 다른 데이터가 참조하지 않아 하드 삭제한다.
    @Transactional
    public void deleteAd(String id) {
        if (!adRepository.existsById(id)) {
            throw new NotFoundException("광고를 찾을 수 없습니다.");
        }
        adRepository.deleteById(id);
    }
}
