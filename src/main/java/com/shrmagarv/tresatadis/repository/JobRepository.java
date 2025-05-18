package com.shrmagarv.tresatadis.repository;

import com.shrmagarv.tresatadis.model.Job;
import com.shrmagarv.tresatadis.model.JobStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface JobRepository extends JpaRepository<Job, Long> {
    List<Job> findByStatus(JobStatus status);
    List<Job> findBySourceType(String sourceType);
}
