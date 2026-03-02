package com.sar.service;

import com.sar.model.Alert;
import com.sar.model.Customer;
import com.sar.model.Transaction;
import com.sar.repository.AlertRepository;
import com.sar.repository.CustomerRepository;
import com.sar.repository.TransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class AlertService {

    private final AlertRepository alertRepo;
    private final CustomerRepository customerRepo;
    private final TransactionRepository transactionRepo;

    public AlertService(AlertRepository alertRepo,
                        CustomerRepository customerRepo,
                        TransactionRepository transactionRepo) {
        this.alertRepo = alertRepo;
        this.customerRepo = customerRepo;
        this.transactionRepo = transactionRepo;
    }

    public List<Alert> getAllAlerts(String status, String severity) {
        List<Alert> alerts;

        if (status != null || severity != null) {
            alerts = alertRepo.findFiltered(status, severity);
        } else {
            alerts = alertRepo.findAllByOrderByDetectionDateDesc();
        }

        for (Alert alert : alerts) {
            enrichAlert(alert);
        }

        return alerts;
    }

    public Optional<Alert> getAlertById(UUID alertId) {
        Optional<Alert> alertOpt = alertRepo.findById(alertId);
        alertOpt.ifPresent(this::enrichAlertWithTransactions);
        return alertOpt;
    }

    @Transactional
    public Optional<Alert> updateAlertStatus(UUID alertId, String newStatus) {
        Optional<Alert> alertOpt = alertRepo.findById(alertId);
        if (alertOpt.isPresent()) {
            Alert alert = alertOpt.get();
            alert.setStatus(newStatus);
            alertRepo.save(alert);
            enrichAlertWithTransactions(alert);
            return Optional.of(alert);
        }
        return Optional.empty();
    }

    public List<Alert> getAlertsByCustomer(UUID customerId) {
        List<Alert> alerts = alertRepo.findByCustomerIdOrderByDetectionDateDesc(customerId);
        for (Alert alert : alerts) {
            enrichAlert(alert);
        }
        return alerts;
    }

    private void enrichAlert(Alert alert) {
        customerRepo.findById(alert.getCustomerId()).ifPresent(alert::setCustomer);
    }

    private void enrichAlertWithTransactions(Alert alert) {
        customerRepo.findById(alert.getCustomerId()).ifPresent(alert::setCustomer);

        String txnIdsRaw = alertRepo.getFlaggedTransactionIds(alert.getId());
        if (txnIdsRaw != null) {
            List<UUID> txnIds = parseTxnIds(txnIdsRaw);
            if (!txnIds.isEmpty()) {
                List<Transaction> txns = transactionRepo.findByIdIn(txnIds);
                alert.setFlaggedTransactions(txns);
            } else {
                alert.setFlaggedTransactions(Collections.emptyList());
            }
        } else {
            alert.setFlaggedTransactions(Collections.emptyList());
        }
    }

    private List<UUID> parseTxnIds(String raw) {
        if (raw == null || raw.isEmpty()) return Collections.emptyList();

        String cleaned = raw.replace("{", "").replace("}", "").trim();
        if (cleaned.isEmpty()) return Collections.emptyList();

        return Arrays.stream(cleaned.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(UUID::fromString)
                .collect(Collectors.toList());
    }
}