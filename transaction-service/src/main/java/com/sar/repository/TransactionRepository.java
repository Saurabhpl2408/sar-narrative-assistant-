package com.sar.repository;

import com.sar.model.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    List<Transaction> findByCustomerIdOrderByTransactionDateDesc(UUID customerId);

    List<Transaction> findByCustomerIdAndTransactionDateBetweenOrderByTransactionDateAsc(
            UUID customerId, LocalDateTime start, LocalDateTime end);

    @Query("SELECT t FROM Transaction t WHERE t.type = 'cash_deposit' " +
           "AND t.amount >= :minAmount AND t.amount < :maxAmount " +
           "AND t.transactionDate BETWEEN :start AND :end " +
           "ORDER BY t.customerId, t.transactionDate")
    List<Transaction> findCashDepositsInRange(
            @Param("minAmount") java.math.BigDecimal minAmount,
            @Param("maxAmount") java.math.BigDecimal maxAmount,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

    @Query("SELECT t FROM Transaction t WHERE t.type = 'wire_transfer' " +
           "AND t.counterpartyCountry IN :countries " +
           "AND t.transactionDate BETWEEN :start AND :end")
    List<Transaction> findWiresToHighRiskCountries(
            @Param("countries") List<String> countries,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

    @Query("SELECT t FROM Transaction t WHERE t.transactionDate BETWEEN :start AND :end " +
           "ORDER BY t.customerId, t.transactionDate")
    List<Transaction> findAllInDateRange(
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

    List<Transaction> findByIdIn(List<UUID> ids);
}