package com.sar.repository;

import com.sar.model.Alert;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface AlertRepository extends JpaRepository<Alert, UUID> {

    List<Alert> findByStatusOrderByDetectionDateDesc(String status);

    List<Alert> findByCustomerIdOrderByDetectionDateDesc(UUID customerId);

    List<Alert> findAllByOrderByDetectionDateDesc();

    @Query("SELECT a FROM Alert a WHERE " +
           "(:status IS NULL OR a.status = :status) AND " +
           "(:severity IS NULL OR a.severity = :severity) " +
           "ORDER BY a.detectionDate DESC")
    List<Alert> findFiltered(
            @Param("status") String status,
            @Param("severity") String severity);

    @Modifying
    @Query(value = "INSERT INTO alerts (customer_id, rule_triggered, severity, status, " +
                   "flagged_transaction_ids, total_flagged_amount, detection_date) " +
                   "VALUES (:customerId, :rule, :severity, 'new', " +
                   ":txnIds\\:\\:uuid[], :amount, :detectionDate)",
           nativeQuery = true)
    void insertAlert(
            @Param("customerId") UUID customerId,
            @Param("rule") String rule,
            @Param("severity") String severity,
            @Param("txnIds") String txnIds,
            @Param("amount") BigDecimal amount,
            @Param("detectionDate") LocalDateTime detectionDate);

    @Query(value = "SELECT flagged_transaction_ids FROM alerts WHERE id = :alertId",
           nativeQuery = true)
    String getFlaggedTransactionIds(@Param("alertId") UUID alertId);

    long countByStatus(String status);

    long countBySeverity(String severity);

    long countByRuleTriggered(String ruleTriggered);

    @Query("SELECT COUNT(a) FROM Alert a WHERE a.detectionDate >= :since")
    long countSince(@Param("since") LocalDateTime since);
}