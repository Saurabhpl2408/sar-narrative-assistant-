package com.sar.controller;

import com.sar.repository.AlertRepository;
import com.sar.repository.CustomerRepository;
import com.sar.repository.TransactionRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final AlertRepository alertRepo;
    private final CustomerRepository customerRepo;
    private final TransactionRepository transactionRepo;

    public DashboardController(AlertRepository alertRepo,
                               CustomerRepository customerRepo,
                               TransactionRepository transactionRepo) {
        this.alertRepo = alertRepo;
        this.customerRepo = customerRepo;
        this.transactionRepo = transactionRepo;
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> getStats() {
        long totalAlerts = alertRepo.count();
        long newAlerts = alertRepo.countByStatus("new");
        long underReview = alertRepo.countByStatus("under_review");
        long sarFiled = alertRepo.countByStatus("sar_filed");
        long dismissed = alertRepo.countByStatus("dismissed");

        long highSeverity = alertRepo.countBySeverity("high");
        long mediumSeverity = alertRepo.countBySeverity("medium");
        long lowSeverity = alertRepo.countBySeverity("low");

        long structuring = alertRepo.countByRuleTriggered("STRUCTURING");
        long highRiskJurisdiction = alertRepo.countByRuleTriggered("HIGH_RISK_JURISDICTION");
        long rapidFundMovement = alertRepo.countByRuleTriggered("RAPID_FUND_MOVEMENT");
        long volumeSpike = alertRepo.countByRuleTriggered("VOLUME_SPIKE");
        long largeCash = alertRepo.countByRuleTriggered("LARGE_CASH");

        long alertsThisWeek = alertRepo.countSince(LocalDateTime.now().minusDays(7));
        long totalCustomers = customerRepo.count();
        long totalTransactions = transactionRepo.count();

        Map<String, Object> stats = Map.ofEntries(
                Map.entry("totalAlerts", totalAlerts),
                Map.entry("byStatus", Map.of(
                        "new", newAlerts,
                        "under_review", underReview,
                        "sar_filed", sarFiled,
                        "dismissed", dismissed
                )),
                Map.entry("bySeverity", Map.of(
                        "high", highSeverity,
                        "medium", mediumSeverity,
                        "low", lowSeverity
                )),
                Map.entry("byRule", Map.of(
                        "STRUCTURING", structuring,
                        "HIGH_RISK_JURISDICTION", highRiskJurisdiction,
                        "RAPID_FUND_MOVEMENT", rapidFundMovement,
                        "VOLUME_SPIKE", volumeSpike,
                        "LARGE_CASH", largeCash
                )),
                Map.entry("alertsThisWeek", alertsThisWeek),
                Map.entry("totalCustomers", totalCustomers),
                Map.entry("totalTransactions", totalTransactions)
        );

        return ResponseEntity.ok(stats);
    }
}