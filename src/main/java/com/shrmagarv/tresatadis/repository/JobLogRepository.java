package com.shrmagarv.tresatadis.repository;

import com.shrmagarv.tresatadis.model.JobLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface JobLogRepository extends JpaRepository<JobLog, Long> {
    List<JobLog> findByJobId(Long jobId);
}
