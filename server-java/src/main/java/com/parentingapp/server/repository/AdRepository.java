package com.parentingapp.server.repository;

import com.parentingapp.server.domain.Ad;
import com.parentingapp.server.domain.AdPlacement;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AdRepository extends JpaRepository<Ad, String> {

    @Query(
            "select a from Ad a where"
                    + " (:active is null or a.active = :active)"
                    + " and (:placement is null or a.placement = :placement)"
                    + " order by a.sortOrder asc, a.createdAt desc")
    List<Ad> search(@Param("active") Boolean active, @Param("placement") AdPlacement placement);
}
