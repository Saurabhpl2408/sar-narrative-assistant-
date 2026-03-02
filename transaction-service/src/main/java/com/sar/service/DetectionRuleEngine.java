package com.sar.service;

import com.sar.model.Transaction;
import com.sar.repository.AlertRepository;
import com.sar.repository.TransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class DetectionRuleEngine {

    private final TransactionRepository transactionRepo;
    private final AlertRepository alertRepo;

    private static final BigDecimal CTR_THRESHOLD = new BigDecimal("10000");
    private static final BigDecimal STRUCTURING_MIN = new BigDecimal("5000");
    private static final BigDecimal STRUCTURING_MAX = new BigDecimal("10000");
    private static final int STRUCTURING_WINDOW_HOURS = 48;
    private static final int RAPID_MOVEMENT_WINDOW_HOURS = 24;
    private static final BigDecimal RAPID_MOVEMENT_MIN = new BigDecimal("20000");
    private static final double VOLUME_SPIKE_MULTIPLIER = 3.0;

    private static final List<String> HIGH_RISK_COUNTRIES = Arrays.asList(
            "IRN", "PRK", "MMR", "SYR", "YEM", "AFG", "LBY", "SOM", "SDN", "VEN"
    );

    public DetectionRuleEngine(TransactionRepository transactionRepo, AlertRepository alertRepo) {
        this.transactionRepo = transactionRepo;
        this.alertRepo = alertRepo;
    }

    @Transactional
    public Map<String, Integer> runAllRules(LocalDateTime scanFrom, LocalDateTime scanTo) {
        Map<String, Integer> results = new HashMap<>();
        results.put("STRUCTURING", detectStructuring(scanFrom, scanTo));
        results.put("HIGH_RISK_JURISDICTION", detectHighRiskJurisdiction(scanFrom, scanTo));
        results.put("RAPID_FUND_MOVEMENT", detectRapidFundMovement(scanFrom, scanTo));
        results.put("VOLUME_SPIKE", detectVolumeSpike(scanFrom, scanTo));
        results.put("LARGE_CASH", detectLargeCash(scanFrom, scanTo));
        return results;
    }

    private int detectStructuring(LocalDateTime scanFrom, LocalDateTime scanTo) {
        List<Transaction> cashDeposits = transactionRepo.findCashDepositsInRange(
                STRUCTURING_MIN, STRUCTURING_MAX, scanFrom, scanTo);

        Map<UUID, List<Transaction>> byCustomer = cashDeposits.stream()
                .collect(Collectors.groupingBy(Transaction::getCustomerId));

        int alertCount = 0;

        for (Map.Entry<UUID, List<Transaction>> entry : byCustomer.entrySet()) {
            List<Transaction> txns = entry.getValue();
            if (txns.size() < 3) continue;

            List<Transaction> window = new ArrayList<>();
            for (int i = 0; i < txns.size(); i++) {
                window.clear();
                LocalDateTime windowEnd = txns.get(i).getTransactionDate()
                        .plusHours(STRUCTURING_WINDOW_HOURS);

                for (int j = i; j < txns.size(); j++) {
                    if (txns.get(j).getTransactionDate().isBefore(windowEnd)) {
                        window.add(txns.get(j));
                    }
                }

                if (window.size() >= 3) {
                    BigDecimal total = window.stream()
                            .map(Transaction::getAmount)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);

                    if (total.compareTo(CTR_THRESHOLD) >= 0) {
                        String txnIds = formatTxnIds(window);
                        alertRepo.insertAlert(
                                entry.getKey(),
                                "STRUCTURING",
                                "high",
                                txnIds,
                                total,
                                LocalDateTime.now()
                        );
                        alertCount++;
                        break;
                    }
                }
            }
        }

        return alertCount;
    }

    private int detectHighRiskJurisdiction(LocalDateTime scanFrom, LocalDateTime scanTo) {
        List<Transaction> wires = transactionRepo.findWiresToHighRiskCountries(
                HIGH_RISK_COUNTRIES, scanFrom, scanTo);

        Map<UUID, List<Transaction>> byCustomer = wires.stream()
                .collect(Collectors.groupingBy(Transaction::getCustomerId));

        int alertCount = 0;

        for (Map.Entry<UUID, List<Transaction>> entry : byCustomer.entrySet()) {
            List<Transaction> txns = entry.getValue();
            BigDecimal total = txns.stream()
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            String txnIds = formatTxnIds(txns);
            alertRepo.insertAlert(
                    entry.getKey(),
                    "HIGH_RISK_JURISDICTION",
                    "high",
                    txnIds,
                    total,
                    LocalDateTime.now()
            );
            alertCount++;
        }

        return alertCount;
    }

    private int detectRapidFundMovement(LocalDateTime scanFrom, LocalDateTime scanTo) {
        List<Transaction> allTxns = transactionRepo.findAllInDateRange(scanFrom, scanTo);

        Map<UUID, List<Transaction>> byCustomer = allTxns.stream()
                .collect(Collectors.groupingBy(Transaction::getCustomerId));

        int alertCount = 0;

        for (Map.Entry<UUID, List<Transaction>> entry : byCustomer.entrySet()) {
            List<Transaction> txns = entry.getValue();

            List<Transaction> inbound = txns.stream()
                    .filter(t -> "inbound".equals(t.getDirection()))
                    .filter(t -> t.getAmount().compareTo(RAPID_MOVEMENT_MIN) >= 0)
                    .collect(Collectors.toList());

            List<Transaction> outbound = txns.stream()
                    .filter(t -> "outbound".equals(t.getDirection()))
                    .filter(t -> t.getAmount().compareTo(RAPID_MOVEMENT_MIN) >= 0)
                    .collect(Collectors.toList());

            for (Transaction in : inbound) {
                for (Transaction out : outbound) {
                    long hoursBetween = java.time.Duration.between(
                            in.getTransactionDate(), out.getTransactionDate()).toHours();

                    if (hoursBetween > 0 && hoursBetween <= RAPID_MOVEMENT_WINDOW_HOURS) {
                        List<Transaction> pair = Arrays.asList(in, out);
                        BigDecimal total = in.getAmount().add(out.getAmount());
                        String txnIds = formatTxnIds(pair);

                        alertRepo.insertAlert(
                                entry.getKey(),
                                "RAPID_FUND_MOVEMENT",
                                "high",
                                txnIds,
                                total,
                                LocalDateTime.now()
                        );
                        alertCount++;
                        break;
                    }
                }
                if (alertCount > 0) break;
            }
        }

        return alertCount;
    }

    private int detectVolumeSpike(LocalDateTime scanFrom, LocalDateTime scanTo) {
        LocalDateTime baselineStart = scanFrom.minusDays(90);
        LocalDateTime baselineEnd = scanFrom;

        List<Transaction> recentTxns = transactionRepo.findAllInDateRange(scanFrom, scanTo);
        List<Transaction> baselineTxns = transactionRepo.findAllInDateRange(baselineStart, baselineEnd);

        Map<UUID, List<Transaction>> recentByCustomer = recentTxns.stream()
                .collect(Collectors.groupingBy(Transaction::getCustomerId));
        Map<UUID, List<Transaction>> baselineByCustomer = baselineTxns.stream()
                .collect(Collectors.groupingBy(Transaction::getCustomerId));

        long recentDays = java.time.Duration.between(scanFrom, scanTo).toDays();
        if (recentDays <= 0) recentDays = 1;

        int alertCount = 0;

        for (Map.Entry<UUID, List<Transaction>> entry : recentByCustomer.entrySet()) {
            UUID customerId = entry.getKey();
            List<Transaction> recent = entry.getValue();

            List<Transaction> baseline = baselineByCustomer.getOrDefault(customerId, List.of());
            if (baseline.isEmpty()) continue;

            BigDecimal recentTotal = recent.stream()
                    .filter(t -> "inbound".equals(t.getDirection()))
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            BigDecimal baselineTotal = baseline.stream()
                    .filter(t -> "inbound".equals(t.getDirection()))
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            long baselineDays = java.time.Duration.between(baselineStart, baselineEnd).toDays();
            if (baselineDays <= 0) baselineDays = 1;

            double dailyBaseline = baselineTotal.doubleValue() / baselineDays;
            double dailyRecent = recentTotal.doubleValue() / recentDays;

            if (dailyBaseline > 0 && dailyRecent >= dailyBaseline * VOLUME_SPIKE_MULTIPLIER) {
                String txnIds = formatTxnIds(recent);
                alertRepo.insertAlert(
                        customerId,
                        "VOLUME_SPIKE",
                        "medium",
                        txnIds,
                        recentTotal,
                        LocalDateTime.now()
                );
                alertCount++;
            }
        }

        return alertCount;
    }

    private int detectLargeCash(LocalDateTime scanFrom, LocalDateTime scanTo) {
        List<Transaction> allTxns = transactionRepo.findAllInDateRange(scanFrom, scanTo);

        List<Transaction> largeCash = allTxns.stream()
                .filter(t -> "cash_deposit".equals(t.getType()) || "cash_withdrawal".equals(t.getType()))
                .filter(t -> t.getAmount().compareTo(CTR_THRESHOLD) >= 0)
                .collect(Collectors.toList());

        Map<UUID, List<Transaction>> byCustomer = largeCash.stream()
                .collect(Collectors.groupingBy(Transaction::getCustomerId));

        int alertCount = 0;

        for (Map.Entry<UUID, List<Transaction>> entry : byCustomer.entrySet()) {
            List<Transaction> txns = entry.getValue();
            BigDecimal total = txns.stream()
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            String txnIds = formatTxnIds(txns);
            alertRepo.insertAlert(
                    entry.getKey(),
                    "LARGE_CASH",
                    "medium",
                    txnIds,
                    total,
                    LocalDateTime.now()
            );
            alertCount++;
        }

        return alertCount;
    }

    private String formatTxnIds(List<Transaction> txns) {
        return "{" + txns.stream()
                .map(t -> t.getId().toString())
                .collect(Collectors.joining(",")) + "}";
    }
}