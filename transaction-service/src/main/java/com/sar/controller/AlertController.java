package com.sar.controller;

import com.sar.model.Alert;
import com.sar.model.Customer;
import com.sar.model.Transaction;
import com.sar.repository.CustomerRepository;
import com.sar.repository.TransactionRepository;
import com.sar.service.AlertService;
import com.sar.service.DetectionRuleEngine;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api")
public class AlertController {

    private final AlertService alertService;
    private final DetectionRuleEngine detectionEngine;
    private final CustomerRepository customerRepo;
    private final TransactionRepository transactionRepo;

    public AlertController(AlertService alertService,
                           DetectionRuleEngine detectionEngine,
                           CustomerRepository customerRepo,
                           TransactionRepository transactionRepo) {
        this.alertService = alertService;
        this.detectionEngine = detectionEngine;
        this.customerRepo = customerRepo;
        this.transactionRepo = transactionRepo;
    }

    @GetMapping("/alerts")
    public ResponseEntity<List<Alert>> getAlerts(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String severity) {
        return ResponseEntity.ok(alertService.getAllAlerts(status, severity));
    }

    @GetMapping("/alerts/{id}")
    public ResponseEntity<Alert> getAlertById(@PathVariable UUID id) {
        Optional<Alert> alert = alertService.getAlertById(id);
        return alert.map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/alerts/{id}/status")
    public ResponseEntity<Alert> updateAlertStatus(
            @PathVariable UUID id,
            @RequestBody Map<String, String> body) {
        String newStatus = body.get("status");
        if (newStatus == null) {
            return ResponseEntity.badRequest().build();
        }
        Optional<Alert> alert = alertService.updateAlertStatus(id, newStatus);
        return alert.map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/transactions/scan")
    public ResponseEntity<Map<String, Object>> runScan(
            @RequestBody(required = false) Map<String, String> body) {
        LocalDateTime scanFrom;
        LocalDateTime scanTo;

        if (body != null && body.containsKey("from") && body.containsKey("to")) {
            scanFrom = LocalDateTime.parse(body.get("from"));
            scanTo = LocalDateTime.parse(body.get("to"));
        } else {
            scanTo = LocalDateTime.now();
            scanFrom = scanTo.minusDays(30);
        }

        Map<String, Integer> results = detectionEngine.runAllRules(scanFrom, scanTo);

        int totalAlerts = results.values().stream().mapToInt(Integer::intValue).sum();

        Map<String, Object> response = Map.of(
                "scanFrom", scanFrom.toString(),
                "scanTo", scanTo.toString(),
                "alertsCreated", totalAlerts,
                "breakdown", results
        );

        return ResponseEntity.ok(response);
    }

    @GetMapping("/customers/{id}")
    public ResponseEntity<Customer> getCustomer(@PathVariable UUID id) {
        Optional<Customer> customer = customerRepo.findById(id);
        return customer.map(ResponseEntity::ok)
                       .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/customers/{id}/transactions")
    public ResponseEntity<List<Transaction>> getCustomerTransactions(@PathVariable UUID id) {
        List<Transaction> txns = transactionRepo.findByCustomerIdOrderByTransactionDateDesc(id);
        return ResponseEntity.ok(txns);
    }
}