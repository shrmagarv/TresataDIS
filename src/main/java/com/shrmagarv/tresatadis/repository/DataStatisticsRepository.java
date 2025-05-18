package com.shrmagarv.tresatadis.repository;

import com.shrmagarv.tresatadis.model.DataStatistics;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DataStatisticsRepository extends JpaRepository<DataStatistics, Long> {
    List<DataStatistics> findByJobId(Long jobId);
}
