-- Analytics DB initialization script
-- Raw transactions tables

CREATE TABLE IF NOT EXISTS kino_ticket_transactions (
    transaction_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,

    purchase_datetime TIMESTAMP NOT NULL,
    event_datetime TIMESTAMP,

    event_id BIGINT,
    event_name VARCHAR(255),

    class_code VARCHAR(50),        -- movie, concert, theatre, tour, sport, family, entertainment
    subclass_code VARCHAR(100),    -- action_movie, electric_bike_tour, rock_concert, kids_show

    genre_code VARCHAR(100),       -- action, comedy, anime, drama; null для не-кино
    city VARCHAR(100),
    venue_name VARCHAR(255),

    tickets_count INT,
    ticket_price NUMERIC(12, 2),
    total_amount NUMERIC(12, 2),

    payment_method VARCHAR(50),    -- halyk_card, bonus, apple_pay, etc.
    bonus_used NUMERIC(12, 2),
    cashback_amount NUMERIC(12, 2),

    source_platform VARCHAR(50),   -- kino_kz_app, kino_kz_web, halyk_app
    status VARCHAR(50),            -- paid, cancelled, refunded

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS account_transactions (
    transaction_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,

    account_id BIGINT NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    -- card, deposit, savings, current_account

    transaction_datetime TIMESTAMP NOT NULL,

    transaction_type VARCHAR(50) NOT NULL,
    -- top_up, withdrawal, transfer_in, transfer_out, deposit_open,
    -- deposit_top_up, deposit_withdrawal, interest_accrual,
    -- card_payment, cashback, fee

    direction VARCHAR(10) NOT NULL,
    -- income, expense

    amount NUMERIC(14, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'KZT',

    balance_before NUMERIC(14, 2),
    balance_after NUMERIC(14, 2),

    counterparty_name VARCHAR(255),
    counterparty_account VARCHAR(100),

    category_code VARCHAR(100),
    category_name VARCHAR(150),

    channel VARCHAR(50),
    -- mobile_app, atm, bank_branch, pos_terminal, online_payment

    description TEXT,

    status VARCHAR(50),
    -- success, pending, failed, reversed

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_kino_tx_user ON kino_ticket_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_kino_tx_purchase_datetime ON kino_ticket_transactions(purchase_datetime);
CREATE INDEX IF NOT EXISTS idx_kino_tx_event_datetime ON kino_ticket_transactions(event_datetime);
CREATE INDEX IF NOT EXISTS idx_kino_tx_class ON kino_ticket_transactions(class_code);
CREATE INDEX IF NOT EXISTS idx_kino_tx_genre ON kino_ticket_transactions(genre_code);
CREATE INDEX IF NOT EXISTS idx_kino_tx_city ON kino_ticket_transactions(city);
CREATE INDEX IF NOT EXISTS idx_kino_tx_status ON kino_ticket_transactions(status);

CREATE INDEX IF NOT EXISTS idx_acc_tx_user ON account_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_acc_tx_account ON account_transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_acc_tx_datetime ON account_transactions(transaction_datetime);
CREATE INDEX IF NOT EXISTS idx_acc_tx_type ON account_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_acc_tx_direction ON account_transactions(direction);
CREATE INDEX IF NOT EXISTS idx_acc_tx_category ON account_transactions(category_code);
CREATE INDEX IF NOT EXISTS idx_acc_tx_status ON account_transactions(status);
