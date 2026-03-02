package com.sar.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "alerts")
public class Alert {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Column(name = "rule_triggered", nullable = false)
    private String ruleTriggered;

    @Column(nullable = false)
    private String severity;

    @Column(nullable = false)
    private String status;

    @Column(name = "total_flagged_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal totalFlaggedAmount;

    @Column(name = "detection_date", nullable = false)
    private LocalDateTime detectionDate;

    @Column(name = "assigned_to")
    private String assignedTo;

    private String notes;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Transient
    private Customer customer;

    @Transient
    private List<Transaction> flaggedTransactions;

    public Alert() {}

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getCustomerId() {
        return customerId;
    }

    public void setCustomerId(UUID customerId) {
        this.customerId = customerId;
    }

    public String getRuleTriggered() {
        return ruleTriggered;
    }

    public void setRuleTriggered(String ruleTriggered) {
        this.ruleTriggered = ruleTriggered;
    }

    public String getSeverity() {
        return severity;
    }

    public void setSeverity(String severity) {
        this.severity = severity;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public BigDecimal getTotalFlaggedAmount() {
        return totalFlaggedAmount;
    }

    public void setTotalFlaggedAmount(BigDecimal totalFlaggedAmount) {
        this.totalFlaggedAmount = totalFlaggedAmount;
    }

    public LocalDateTime getDetectionDate() {
        return detectionDate;
    }

    public void setDetectionDate(LocalDateTime detectionDate) {
        this.detectionDate = detectionDate;
    }

    public String getAssignedTo() {
        return assignedTo;
    }

    public void setAssignedTo(String assignedTo) {
        this.assignedTo = assignedTo;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Customer getCustomer() {
        return customer;
    }

    public void setCustomer(Customer customer) {
        this.customer = customer;
    }

    public List<Transaction> getFlaggedTransactions() {
        return flaggedTransactions;
    }

    public void setFlaggedTransactions(List<Transaction> flaggedTransactions) {
        this.flaggedTransactions = flaggedTransactions;
    }
}