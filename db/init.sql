CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    risk_rating VARCHAR(20) NOT NULL DEFAULT 'low',
    country VARCHAR(3) NOT NULL DEFAULT 'USA',
    opened_date DATE NOT NULL,
    occupation VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);


CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id),
    type VARCHAR(30) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    direction VARCHAR(10) NOT NULL,
    counterparty_name VARCHAR(200),
    counterparty_country VARCHAR(3),
    description TEXT,
    branch VARCHAR(100),
    transaction_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_txn_customer ON transactions(customer_id);
CREATE INDEX idx_txn_date ON transactions(transaction_date);
CREATE INDEX idx_txn_amount ON transactions(amount);


CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id),
    rule_triggered VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'new',
    flagged_transaction_ids UUID[] NOT NULL,
    total_flagged_amount DECIMAL(15,2) NOT NULL,
    detection_date TIMESTAMP NOT NULL DEFAULT NOW(),
    assigned_to VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_customer ON alerts(customer_id);


CREATE TABLE sar_narratives (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_id UUID NOT NULL REFERENCES alerts(id),
    narrative_text TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    generated_by VARCHAR(20) NOT NULL DEFAULT 'ai',
    approved_by VARCHAR(100),
    llm_model VARCHAR(50),
    prompt_tokens INTEGER,
    completion_tokens INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_narratives_alert ON sar_narratives(alert_id);


CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL,
    performed_by VARCHAR(100) NOT NULL DEFAULT 'system',
    details JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_entity ON audit_log(entity_type, entity_id);


INSERT INTO customers (id, name, account_number, account_type, risk_rating, country, opened_date, occupation) VALUES
('a0000001-0000-0000-0000-000000000001', 'Sarah Mitchell', 'ACC-10001', 'checking', 'low', 'USA', '2020-03-15', 'Software Engineer'),
('a0000001-0000-0000-0000-000000000002', 'James Rodriguez', 'ACC-10002', 'savings', 'low', 'USA', '2019-06-22', 'Teacher'),
('a0000001-0000-0000-0000-000000000003', 'Emily Chen', 'ACC-10003', 'checking', 'low', 'USA', '2021-01-10', 'Nurse'),
('a0000001-0000-0000-0000-000000000004', 'Michael Brown', 'ACC-10004', 'business', 'low', 'USA', '2018-09-05', 'Restaurant Owner'),
('a0000001-0000-0000-0000-000000000005', 'Lisa Thompson', 'ACC-10005', 'checking', 'low', 'USA', '2022-04-18', 'Accountant'),
('a0000001-0000-0000-0000-000000000006', 'David Kim', 'ACC-10006', 'savings', 'low', 'USA', '2020-11-30', 'Marketing Manager'),
('a0000001-0000-0000-0000-000000000007', 'Jennifer Garcia', 'ACC-10007', 'checking', 'low', 'USA', '2017-07-14', 'Lawyer'),
('a0000001-0000-0000-0000-000000000008', 'Robert Wilson', 'ACC-10008', 'business', 'low', 'USA', '2019-02-28', 'Contractor'),
('a0000001-0000-0000-0000-000000000009', 'Amanda Davis', 'ACC-10009', 'checking', 'low', 'USA', '2021-08-09', 'Data Analyst'),
('a0000001-0000-0000-0000-000000000010', 'Christopher Lee', 'ACC-10010', 'savings', 'low', 'USA', '2020-05-20', 'Dentist'),
('a0000001-0000-0000-0000-000000000011', 'Maria Santos', 'ACC-10011', 'checking', 'low', 'USA', '2018-12-01', 'Pharmacist'),
('a0000001-0000-0000-0000-000000000012', 'Kevin OBrien', 'ACC-10012', 'business', 'low', 'USA', '2019-10-15', 'Auto Dealer'),
('a0000001-0000-0000-0000-000000000013', 'Rachel Green', 'ACC-10013', 'checking', 'low', 'USA', '2022-06-30', 'Interior Designer'),
('a0000001-0000-0000-0000-000000000014', 'Steven Park', 'ACC-10014', 'savings', 'low', 'USA', '2020-01-25', 'Financial Analyst'),
('a0000001-0000-0000-0000-000000000015', 'Nicole Wright', 'ACC-10015', 'checking', 'low', 'USA', '2021-03-12', 'Graphic Designer'),
('a0000001-0000-0000-0000-000000000016', 'Daniel Martinez', 'ACC-10016', 'business', 'medium', 'USA', '2017-04-08', 'Import/Export Trader'),
('a0000001-0000-0000-0000-000000000017', 'Laura Anderson', 'ACC-10017', 'checking', 'low', 'USA', '2022-09-14', 'Professor'),
('a0000001-0000-0000-0000-000000000018', 'Mark Taylor', 'ACC-10018', 'savings', 'low', 'USA', '2019-07-21', 'Sales Manager'),
('a0000001-0000-0000-0000-000000000019', 'Samantha Hill', 'ACC-10019', 'checking', 'low', 'USA', '2020-08-03', 'HR Specialist'),
('a0000001-0000-0000-0000-000000000020', 'Brian Clark', 'ACC-10020', 'business', 'low', 'USA', '2018-05-17', 'Plumber'),
('a0000001-0000-0000-0000-000000000021', 'Tina Patel', 'ACC-10021', 'checking', 'low', 'USA', '2021-11-22', 'Physician'),
('a0000001-0000-0000-0000-000000000022', 'George Walker', 'ACC-10022', 'savings', 'low', 'USA', '2019-03-08', 'Retired'),
('a0000001-0000-0000-0000-000000000023', 'Heather Scott', 'ACC-10023', 'checking', 'low', 'USA', '2022-02-14', 'Web Developer'),
('a0000001-0000-0000-0000-000000000024', 'Andrew Young', 'ACC-10024', 'business', 'low', 'USA', '2020-06-19', 'Electrician'),
('a0000001-0000-0000-0000-000000000025', 'Olivia Adams', 'ACC-10025', 'checking', 'low', 'USA', '2017-10-30', 'Architect'),
('a0000001-0000-0000-0000-000000000026', 'Jason Campbell', 'ACC-10026', 'savings', 'low', 'USA', '2021-05-11', 'Real Estate Agent'),
('a0000001-0000-0000-0000-000000000027', 'Stephanie Rivera', 'ACC-10027', 'checking', 'low', 'USA', '2019-12-07', 'Social Worker'),
('a0000001-0000-0000-0000-000000000028', 'Eric Johnson', 'ACC-10028', 'business', 'low', 'USA', '2018-08-23', 'Mechanic'),
('a0000001-0000-0000-0000-000000000029', 'Diana Cruz', 'ACC-10029', 'checking', 'low', 'USA', '2022-01-16', 'Veterinarian'),
('a0000001-0000-0000-0000-000000000030', 'Paul Hughes', 'ACC-10030', 'savings', 'low', 'USA', '2020-04-02', 'Insurance Agent'),
('a0000001-0000-0000-0000-000000000031', 'Angela Morris', 'ACC-10031', 'checking', 'low', 'USA', '2021-07-28', 'Chef'),
('a0000001-0000-0000-0000-000000000032', 'Ryan Cooper', 'ACC-10032', 'business', 'low', 'USA', '2019-09-13', 'Fitness Trainer'),
('a0000001-0000-0000-0000-000000000033', 'Michelle Barnes', 'ACC-10033', 'checking', 'low', 'USA', '2020-02-06', 'Paralegal'),
('a0000001-0000-0000-0000-000000000034', 'Tyler Reed', 'ACC-10034', 'savings', 'low', 'USA', '2022-08-20', 'Pilot'),
('a0000001-0000-0000-0000-000000000035', 'Karen Foster', 'ACC-10035', 'checking', 'low', 'USA', '2018-01-11', 'Librarian'),
('b0000001-0000-0000-0000-000000000001', 'Viktor Petrov', 'ACC-20001', 'checking', 'medium', 'USA', '2023-06-10', 'Used Car Dealer'),
('b0000001-0000-0000-0000-000000000002', 'Tony Marchetti', 'ACC-20002', 'business', 'medium', 'USA', '2022-11-05', 'Laundromat Owner'),
('b0000001-0000-0000-0000-000000000003', 'Linda Zhao', 'ACC-20003', 'checking', 'low', 'USA', '2023-09-20', 'Convenience Store Owner'),
('c0000001-0000-0000-0000-000000000001', 'Reza Ahmadi', 'ACC-30001', 'business', 'high', 'USA', '2021-04-15', 'Import/Export'),
('c0000001-0000-0000-0000-000000000002', 'Nadia Khin', 'ACC-30002', 'checking', 'medium', 'USA', '2022-08-22', 'Freelance Consultant'),
('c0000001-0000-0000-0000-000000000003', 'Yuri Volkov', 'ACC-30003', 'business', 'high', 'USA', '2023-01-30', 'Technology Reseller'),
('d0000001-0000-0000-0000-000000000001', 'Marco Bianchi', 'ACC-40001', 'business', 'medium', 'USA', '2022-03-18', 'Consulting LLC'),
('d0000001-0000-0000-0000-000000000002', 'Alexei Sorokin', 'ACC-40002', 'checking', 'medium', 'USA', '2023-05-12', 'Freelance Developer'),
('d0000001-0000-0000-0000-000000000003', 'Patricia Dumont', 'ACC-40003', 'business', 'low', 'USA', '2021-10-07', 'Art Dealer'),
('e0000001-0000-0000-0000-000000000001', 'Frank Castellano', 'ACC-50001', 'business', 'medium', 'USA', '2019-06-25', 'Construction Contractor'),
('e0000001-0000-0000-0000-000000000002', 'Diane Nakamura', 'ACC-50002', 'checking', 'low', 'USA', '2020-12-14', 'Jewelry Dealer'),
('e0000001-0000-0000-0000-000000000003', 'Omar Hassan', 'ACC-50003', 'business', 'medium', 'USA', '2022-07-03', 'Money Service Business');


INSERT INTO transactions (customer_id, type, amount, direction, counterparty_name, counterparty_country, description, branch, transaction_date) VALUES

('a0000001-0000-0000-0000-000000000001', 'ach', 4500.00, 'inbound', 'TechCorp Inc', 'USA', 'Payroll deposit', 'Chicago Main', '2025-10-01 09:00:00'),
('a0000001-0000-0000-0000-000000000001', 'ach', 1800.00, 'outbound', 'Lakeside Apartments', 'USA', 'Rent payment', 'Chicago Main', '2025-10-03 10:30:00'),
('a0000001-0000-0000-0000-000000000001', 'ach', 4500.00, 'inbound', 'TechCorp Inc', 'USA', 'Payroll deposit', 'Chicago Main', '2025-10-15 09:00:00'),
('a0000001-0000-0000-0000-000000000001', 'check', 350.00, 'outbound', 'ComEd', 'USA', 'Utilities', 'Chicago Main', '2025-10-18 14:00:00'),
('a0000001-0000-0000-0000-000000000001', 'ach', 4500.00, 'inbound', 'TechCorp Inc', 'USA', 'Payroll deposit', 'Chicago Main', '2025-11-01 09:00:00'),
('a0000001-0000-0000-0000-000000000001', 'ach', 1800.00, 'outbound', 'Lakeside Apartments', 'USA', 'Rent payment', 'Chicago Main', '2025-11-03 10:30:00'),

('a0000001-0000-0000-0000-000000000002', 'ach', 3200.00, 'inbound', 'Chicago Public Schools', 'USA', 'Salary', 'Lincoln Park', '2025-10-01 09:00:00'),
('a0000001-0000-0000-0000-000000000002', 'ach', 3200.00, 'inbound', 'Chicago Public Schools', 'USA', 'Salary', 'Lincoln Park', '2025-10-15 09:00:00'),
('a0000001-0000-0000-0000-000000000002', 'check', 200.00, 'outbound', 'Amazon', 'USA', 'Online purchase', 'Lincoln Park', '2025-10-20 11:00:00'),
('a0000001-0000-0000-0000-000000000002', 'ach', 3200.00, 'inbound', 'Chicago Public Schools', 'USA', 'Salary', 'Lincoln Park', '2025-11-01 09:00:00'),

('a0000001-0000-0000-0000-000000000003', 'ach', 3800.00, 'inbound', 'Northwestern Memorial', 'USA', 'Payroll', 'Evanston Branch', '2025-10-01 09:00:00'),
('a0000001-0000-0000-0000-000000000003', 'ach', 1500.00, 'outbound', 'State Farm Insurance', 'USA', 'Insurance premium', 'Evanston Branch', '2025-10-10 14:00:00'),
('a0000001-0000-0000-0000-000000000003', 'ach', 3800.00, 'inbound', 'Northwestern Memorial', 'USA', 'Payroll', 'Evanston Branch', '2025-10-15 09:00:00'),

('a0000001-0000-0000-0000-000000000004', 'cash_deposit', 4200.00, 'inbound', NULL, 'USA', 'Weekend revenue', 'Little Italy Branch', '2025-10-07 10:00:00'),
('a0000001-0000-0000-0000-000000000004', 'ach', 2800.00, 'outbound', 'Sysco Foods', 'USA', 'Food supplies', 'Little Italy Branch', '2025-10-09 11:00:00'),
('a0000001-0000-0000-0000-000000000004', 'cash_deposit', 3900.00, 'inbound', NULL, 'USA', 'Weekend revenue', 'Little Italy Branch', '2025-10-14 10:00:00'),
('a0000001-0000-0000-0000-000000000004', 'cash_deposit', 4100.00, 'inbound', NULL, 'USA', 'Weekend revenue', 'Little Italy Branch', '2025-10-21 10:00:00'),
('a0000001-0000-0000-0000-000000000004', 'ach', 3100.00, 'outbound', 'Sysco Foods', 'USA', 'Food supplies', 'Little Italy Branch', '2025-10-23 11:00:00'),

('a0000001-0000-0000-0000-000000000005', 'ach', 5200.00, 'inbound', 'Deloitte', 'USA', 'Salary', 'Loop Branch', '2025-10-01 09:00:00'),
('a0000001-0000-0000-0000-000000000005', 'ach', 2200.00, 'outbound', 'Chase Mortgage', 'USA', 'Mortgage payment', 'Loop Branch', '2025-10-05 10:00:00'),
('a0000001-0000-0000-0000-000000000005', 'ach', 5200.00, 'inbound', 'Deloitte', 'USA', 'Salary', 'Loop Branch', '2025-10-15 09:00:00'),

('a0000001-0000-0000-0000-000000000006', 'ach', 4800.00, 'inbound', 'McCann Worldwide', 'USA', 'Salary', 'Wicker Park', '2025-10-01 09:00:00'),
('a0000001-0000-0000-0000-000000000006', 'check', 600.00, 'outbound', 'Verizon', 'USA', 'Phone bill', 'Wicker Park', '2025-10-12 15:00:00'),

('a0000001-0000-0000-0000-000000000007', 'ach', 8500.00, 'inbound', 'Baker McKenzie', 'USA', 'Salary', 'Loop Branch', '2025-10-01 09:00:00'),
('a0000001-0000-0000-0000-000000000007', 'wire_transfer', 3500.00, 'outbound', 'Fidelity Investments', 'USA', 'Investment transfer', 'Loop Branch', '2025-10-08 14:00:00'),
('a0000001-0000-0000-0000-000000000007', 'ach', 8500.00, 'inbound', 'Baker McKenzie', 'USA', 'Salary', 'Loop Branch', '2025-10-15 09:00:00'),

('a0000001-0000-0000-0000-000000000008', 'cash_deposit', 3500.00, 'inbound', NULL, 'USA', 'Job payment', 'Schaumburg Branch', '2025-10-04 10:00:00'),
('a0000001-0000-0000-0000-000000000008', 'check', 1800.00, 'outbound', 'Home Depot', 'USA', 'Materials', 'Schaumburg Branch', '2025-10-07 11:00:00'),
('a0000001-0000-0000-0000-000000000008', 'cash_deposit', 4200.00, 'inbound', NULL, 'USA', 'Job payment', 'Schaumburg Branch', '2025-10-18 10:00:00'),

('a0000001-0000-0000-0000-000000000009', 'ach', 4100.00, 'inbound', 'Nielsen Holdings', 'USA', 'Salary', 'River North', '2025-10-01 09:00:00'),
('a0000001-0000-0000-0000-000000000009', 'ach', 4100.00, 'inbound', 'Nielsen Holdings', 'USA', 'Salary', 'River North', '2025-10-15 09:00:00'),

('a0000001-0000-0000-0000-000000000010', 'ach', 7200.00, 'inbound', 'Dental Associates PC', 'USA', 'Practice income', 'Lakeview Branch', '2025-10-01 09:00:00'),
('a0000001-0000-0000-0000-000000000010', 'ach', 2500.00, 'outbound', 'Henry Schein Dental', 'USA', 'Dental supplies', 'Lakeview Branch', '2025-10-10 11:00:00'),
('a0000001-0000-0000-0000-000000000010', 'ach', 7200.00, 'inbound', 'Dental Associates PC', 'USA', 'Practice income', 'Lakeview Branch', '2025-10-15 09:00:00'),

('b0000001-0000-0000-0000-000000000001', 'ach', 2500.00, 'inbound', 'Petrov Auto Sales', 'USA', 'Business income', 'Chicago Main', '2025-09-01 09:00:00'),
('b0000001-0000-0000-0000-000000000001', 'check', 1200.00, 'outbound', 'Auto Parts Supplier', 'USA', 'Inventory', 'Chicago Main', '2025-09-10 11:00:00'),
('b0000001-0000-0000-0000-000000000001', 'ach', 2500.00, 'inbound', 'Petrov Auto Sales', 'USA', 'Business income', 'Chicago Main', '2025-09-15 09:00:00'),
('b0000001-0000-0000-0000-000000000001', 'check', 800.00, 'outbound', 'State of Illinois', 'USA', 'Dealer license renewal', 'Chicago Main', '2025-09-22 14:00:00'),
('b0000001-0000-0000-0000-000000000001', 'ach', 2500.00, 'inbound', 'Petrov Auto Sales', 'USA', 'Business income', 'Chicago Main', '2025-10-01 09:00:00'),
('b0000001-0000-0000-0000-000000000001', 'ach', 2500.00, 'inbound', 'Petrov Auto Sales', 'USA', 'Business income', 'Chicago Main', '2025-10-15 09:00:00'),
('b0000001-0000-0000-0000-000000000001', 'cash_deposit', 9800.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Chicago Main', '2025-11-10 09:15:00'),
('b0000001-0000-0000-0000-000000000001', 'cash_deposit', 9700.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Naperville Branch', '2025-11-10 14:30:00'),
('b0000001-0000-0000-0000-000000000001', 'cash_deposit', 9500.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Oak Brook Branch', '2025-11-11 10:00:00'),
('b0000001-0000-0000-0000-000000000001', 'cash_deposit', 9900.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Chicago Main', '2025-11-11 15:45:00'),

('b0000001-0000-0000-0000-000000000002', 'cash_deposit', 3500.00, 'inbound', NULL, 'USA', 'Weekly business revenue', 'Cicero Branch', '2025-09-08 10:00:00'),
('b0000001-0000-0000-0000-000000000002', 'cash_deposit', 3200.00, 'inbound', NULL, 'USA', 'Weekly business revenue', 'Cicero Branch', '2025-09-15 10:00:00'),
('b0000001-0000-0000-0000-000000000002', 'ach', 2800.00, 'outbound', 'Midwest Laundry Supply', 'USA', 'Supplies', 'Cicero Branch', '2025-09-22 14:00:00'),
('b0000001-0000-0000-0000-000000000002', 'cash_deposit', 3400.00, 'inbound', NULL, 'USA', 'Weekly business revenue', 'Cicero Branch', '2025-10-06 10:00:00'),
('b0000001-0000-0000-0000-000000000002', 'cash_deposit', 3100.00, 'inbound', NULL, 'USA', 'Weekly business revenue', 'Cicero Branch', '2025-10-13 10:00:00'),
('b0000001-0000-0000-0000-000000000002', 'cash_deposit', 9200.00, 'inbound', NULL, 'USA', 'Business cash deposit', 'Cicero Branch', '2025-11-15 09:30:00'),
('b0000001-0000-0000-0000-000000000002', 'cash_deposit', 8800.00, 'inbound', NULL, 'USA', 'Business cash deposit', 'Cicero Branch', '2025-11-15 16:00:00'),
('b0000001-0000-0000-0000-000000000002', 'cash_deposit', 9600.00, 'inbound', NULL, 'USA', 'Business cash deposit', 'Berwyn Branch', '2025-11-16 10:15:00'),

('b0000001-0000-0000-0000-000000000003', 'cash_deposit', 2200.00, 'inbound', NULL, 'USA', 'Store revenue', 'Chinatown Branch', '2025-09-10 10:00:00'),
('b0000001-0000-0000-0000-000000000003', 'cash_deposit', 2100.00, 'inbound', NULL, 'USA', 'Store revenue', 'Chinatown Branch', '2025-09-17 10:00:00'),
('b0000001-0000-0000-0000-000000000003', 'ach', 1500.00, 'outbound', 'Wholesale Distributors', 'USA', 'Inventory', 'Chinatown Branch', '2025-09-25 14:00:00'),
('b0000001-0000-0000-0000-000000000003', 'cash_deposit', 2300.00, 'inbound', NULL, 'USA', 'Store revenue', 'Chinatown Branch', '2025-10-01 10:00:00'),
('b0000001-0000-0000-0000-000000000003', 'cash_deposit', 9400.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Chinatown Branch', '2025-11-20 09:00:00'),
('b0000001-0000-0000-0000-000000000003', 'cash_deposit', 9300.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Chinatown Branch', '2025-11-20 15:30:00'),
('b0000001-0000-0000-0000-000000000003', 'cash_deposit', 9100.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Bridgeport Branch', '2025-11-21 11:00:00'),
('b0000001-0000-0000-0000-000000000003', 'cash_deposit', 9600.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Chinatown Branch', '2025-11-21 16:45:00'),
('b0000001-0000-0000-0000-000000000003', 'cash_deposit', 9800.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Loop Branch', '2025-11-22 09:30:00'),

('c0000001-0000-0000-0000-000000000001', 'ach', 5000.00, 'inbound', 'Ahmadi Trading LLC', 'USA', 'Business income', 'Chicago Main', '2025-09-01 09:00:00'),
('c0000001-0000-0000-0000-000000000001', 'ach', 3200.00, 'outbound', 'Commercial Lease Corp', 'USA', 'Office rent', 'Chicago Main', '2025-09-05 10:00:00'),
('c0000001-0000-0000-0000-000000000001', 'ach', 5000.00, 'inbound', 'Ahmadi Trading LLC', 'USA', 'Business income', 'Chicago Main', '2025-10-01 09:00:00'),
('c0000001-0000-0000-0000-000000000001', 'wire_transfer', 45000.00, 'outbound', 'Shahab Trading Co', 'IRN', 'Payment for goods', 'Chicago Main', '2025-11-05 10:30:00'),
('c0000001-0000-0000-0000-000000000001', 'wire_transfer', 28000.00, 'inbound', 'Persian Gulf Exports', 'IRN', 'Receivable collection', 'Chicago Main', '2025-11-12 14:00:00'),
('c0000001-0000-0000-0000-000000000001', 'wire_transfer', 32000.00, 'outbound', 'Tehran Industrial Supply', 'IRN', 'Equipment purchase', 'Chicago Main', '2025-11-18 11:00:00'),

('c0000001-0000-0000-0000-000000000002', 'ach', 4200.00, 'inbound', 'Global Consulting Partners', 'USA', 'Consulting fee', 'Uptown Branch', '2025-09-15 09:00:00'),
('c0000001-0000-0000-0000-000000000002', 'ach', 4200.00, 'inbound', 'Global Consulting Partners', 'USA', 'Consulting fee', 'Uptown Branch', '2025-10-15 09:00:00'),
('c0000001-0000-0000-0000-000000000002', 'wire_transfer', 18500.00, 'outbound', 'Khin Family Trust', 'MMR', 'Family remittance', 'Uptown Branch', '2025-11-08 09:45:00'),
('c0000001-0000-0000-0000-000000000002', 'wire_transfer', 22000.00, 'outbound', 'Yangon Development Corp', 'MMR', 'Investment transfer', 'Uptown Branch', '2025-11-22 10:30:00'),

('c0000001-0000-0000-0000-000000000003', 'ach', 8000.00, 'inbound', 'Volkov Tech Solutions', 'USA', 'Business income', 'Skokie Branch', '2025-09-01 09:00:00'),
('c0000001-0000-0000-0000-000000000003', 'ach', 8000.00, 'inbound', 'Volkov Tech Solutions', 'USA', 'Business income', 'Skokie Branch', '2025-10-01 09:00:00'),
('c0000001-0000-0000-0000-000000000003', 'wire_transfer', 55000.00, 'outbound', 'Pyongyang Electronics Ltd', 'PRK', 'Component purchase', 'Skokie Branch', '2025-11-03 11:00:00'),
('c0000001-0000-0000-0000-000000000003', 'wire_transfer', 38000.00, 'outbound', 'DPRK Tech Manufacturing', 'PRK', 'Equipment order', 'Skokie Branch', '2025-11-14 14:30:00'),

('d0000001-0000-0000-0000-000000000001', 'ach', 6000.00, 'inbound', 'Bianchi Consulting LLC', 'USA', 'Monthly retainer', 'River North', '2025-09-01 09:00:00'),
('d0000001-0000-0000-0000-000000000001', 'ach', 6000.00, 'inbound', 'Bianchi Consulting LLC', 'USA', 'Monthly retainer', 'River North', '2025-10-01 09:00:00'),
('d0000001-0000-0000-0000-000000000001', 'wire_transfer', 85000.00, 'inbound', 'Cayman Holdings Ltd', 'CYM', 'Consulting payment', 'River North', '2025-11-12 08:30:00'),
('d0000001-0000-0000-0000-000000000001', 'wire_transfer', 82000.00, 'outbound', 'Bermuda Ventures Inc', 'BMU', 'Investment transfer', 'River North', '2025-11-12 15:45:00'),

('d0000001-0000-0000-0000-000000000002', 'ach', 3500.00, 'inbound', 'Freelance Payments LLC', 'USA', 'Contract payment', 'Logan Square', '2025-09-15 09:00:00'),
('d0000001-0000-0000-0000-000000000002', 'ach', 3500.00, 'inbound', 'Freelance Payments LLC', 'USA', 'Contract payment', 'Logan Square', '2025-10-15 09:00:00'),
('d0000001-0000-0000-0000-000000000002', 'wire_transfer', 62000.00, 'inbound', 'Swiss Digital AG', 'CHE', 'Project payment', 'Logan Square', '2025-11-18 09:00:00'),
('d0000001-0000-0000-0000-000000000002', 'wire_transfer', 60500.00, 'outbound', 'Dubai Tech FZ-LLC', 'ARE', 'Outsourcing payment', 'Logan Square', '2025-11-18 16:30:00'),

('d0000001-0000-0000-0000-000000000003', 'ach', 4500.00, 'inbound', 'Dumont Gallery LLC', 'USA', 'Gallery sales', 'Gold Coast Branch', '2025-09-01 09:00:00'),
('d0000001-0000-0000-0000-000000000003', 'ach', 4500.00, 'inbound', 'Dumont Gallery LLC', 'USA', 'Gallery sales', 'Gold Coast Branch', '2025-10-01 09:00:00'),
('d0000001-0000-0000-0000-000000000003', 'wire_transfer', 120000.00, 'inbound', 'Luxembourg Art Fund SA', 'LUX', 'Art acquisition payment', 'Gold Coast Branch', '2025-11-20 10:00:00'),
('d0000001-0000-0000-0000-000000000003', 'wire_transfer', 115000.00, 'outbound', 'Panama City Art Storage', 'PAN', 'Art purchase and shipping', 'Gold Coast Branch', '2025-11-20 16:00:00'),

('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 5000.00, 'inbound', NULL, 'USA', 'Job payment', 'Bridgeview Branch', '2025-09-05 10:00:00'),
('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 4800.00, 'inbound', NULL, 'USA', 'Job payment', 'Bridgeview Branch', '2025-09-12 10:00:00'),
('e0000001-0000-0000-0000-000000000001', 'check', 3200.00, 'outbound', 'Midwest Concrete Supply', 'USA', 'Materials', 'Bridgeview Branch', '2025-09-15 11:00:00'),
('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 5200.00, 'inbound', NULL, 'USA', 'Job payment', 'Bridgeview Branch', '2025-09-19 10:00:00'),
('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 4500.00, 'inbound', NULL, 'USA', 'Job payment', 'Bridgeview Branch', '2025-09-26 10:00:00'),
('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 5100.00, 'inbound', NULL, 'USA', 'Job payment', 'Bridgeview Branch', '2025-10-03 10:00:00'),
('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 4900.00, 'inbound', NULL, 'USA', 'Job payment', 'Bridgeview Branch', '2025-10-10 10:00:00'),
('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 25000.00, 'inbound', NULL, 'USA', 'Large cash deposit', 'Bridgeview Branch', '2025-11-03 09:00:00'),
('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 22000.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Bridgeview Branch', '2025-11-04 10:00:00'),
('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 28000.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Oak Lawn Branch', '2025-11-05 09:30:00'),
('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 19000.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Bridgeview Branch', '2025-11-06 11:00:00'),
('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 31000.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Bridgeview Branch', '2025-11-07 09:00:00'),
('e0000001-0000-0000-0000-000000000001', 'wire_transfer', 18000.00, 'outbound', 'Castellano Materials Inc', 'USA', 'Supplier payment', 'Bridgeview Branch', '2025-11-07 14:00:00'),
('e0000001-0000-0000-0000-000000000001', 'cash_deposit', 24000.00, 'inbound', NULL, 'USA', 'Cash deposit', 'Bridgeview Branch', '2025-11-08 10:00:00'),

('e0000001-0000-0000-0000-000000000002', 'ach', 3000.00, 'inbound', 'Nakamura Jewelers LLC', 'USA', 'Business income', 'Wicker Park', '2025-09-01 09:00:00'),
('e0000001-0000-0000-0000-000000000002', 'ach', 2800.00, 'inbound', 'Nakamura Jewelers LLC', 'USA', 'Business income', 'Wicker Park', '2025-09-15 09:00:00'),
('e0000001-0000-0000-0000-000000000002', 'ach', 3100.00, 'inbound', 'Nakamura Jewelers LLC', 'USA', 'Business income', 'Wicker Park', '2025-10-01 09:00:00'),
('e0000001-0000-0000-0000-000000000002', 'ach', 2900.00, 'inbound', 'Nakamura Jewelers LLC', 'USA', 'Business income', 'Wicker Park', '2025-10-15 09:00:00'),
('e0000001-0000-0000-0000-000000000002', 'cash_deposit', 42000.00, 'inbound', NULL, 'USA', 'Estate jewelry purchase', 'Wicker Park', '2025-11-10 09:00:00'),
('e0000001-0000-0000-0000-000000000002', 'cash_deposit', 38000.00, 'inbound', NULL, 'USA', 'Bulk purchase cash', 'Wicker Park', '2025-11-11 10:00:00'),
('e0000001-0000-0000-0000-000000000002', 'wire_transfer', 55000.00, 'outbound', 'Hong Kong Gem Exchange', 'HKG', 'Gem purchase', 'Wicker Park', '2025-11-12 11:30:00'),
('e0000001-0000-0000-0000-000000000002', 'cash_deposit', 35000.00, 'inbound', NULL, 'USA', 'Cash sale', 'Wicker Park', '2025-11-13 09:30:00'),
('e0000001-0000-0000-0000-000000000002', 'cash_deposit', 29000.00, 'inbound', NULL, 'USA', 'Cash sale', 'Wicker Park', '2025-11-14 10:00:00'),

('e0000001-0000-0000-0000-000000000003', 'cash_deposit', 8000.00, 'inbound', NULL, 'USA', 'Business revenue', 'Devon Ave Branch', '2025-09-01 09:00:00'),
('e0000001-0000-0000-0000-000000000003', 'wire_transfer', 6000.00, 'outbound', 'Various Recipients', 'USA', 'Customer transfers', 'Devon Ave Branch', '2025-09-05 14:00:00'),
('e0000001-0000-0000-0000-000000000003', 'cash_deposit', 7500.00, 'inbound', NULL, 'USA', 'Business revenue', 'Devon Ave Branch', '2025-09-15 09:00:00'),
('e0000001-0000-0000-0000-000000000003', 'cash_deposit', 8200.00, 'inbound', NULL, 'USA', 'Business revenue', 'Devon Ave Branch', '2025-10-01 09:00:00'),
('e0000001-0000-0000-0000-000000000003', 'cash_deposit', 7800.00, 'inbound', NULL, 'USA', 'Business revenue', 'Devon Ave Branch', '2025-10-15 09:00:00'),
('e0000001-0000-0000-0000-000000000003', 'cash_deposit', 45000.00, 'inbound', NULL, 'USA', 'Large business deposit', 'Devon Ave Branch', '2025-11-01 09:00:00'),
('e0000001-0000-0000-0000-000000000003', 'wire_transfer', 40000.00, 'outbound', 'Various International', 'ARE', 'Bulk transfers', 'Devon Ave Branch', '2025-11-01 15:00:00'),
('e0000001-0000-0000-0000-000000000003', 'cash_deposit', 52000.00, 'inbound', NULL, 'USA', 'Business deposit', 'Devon Ave Branch', '2025-11-03 09:00:00'),
('e0000001-0000-0000-0000-000000000003', 'wire_transfer', 48000.00, 'outbound', 'Gulf Exchange House', 'ARE', 'Customer remittances', 'Devon Ave Branch', '2025-11-03 14:00:00'),
('e0000001-0000-0000-0000-000000000003', 'cash_deposit', 38000.00, 'inbound', NULL, 'USA', 'Business deposit', 'Devon Ave Branch', '2025-11-05 09:00:00'),
('e0000001-0000-0000-0000-000000000003', 'wire_transfer', 35000.00, 'outbound', 'Riyadh Money Exchange', 'SAU', 'Customer remittances', 'Devon Ave Branch', '2025-11-05 15:30:00'),
('e0000001-0000-0000-0000-000000000003', 'cash_deposit', 41000.00, 'inbound', NULL, 'USA', 'Business deposit', 'Devon Ave Branch', '2025-11-07 09:00:00');