CREATE TABLE tenants
(
    id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(50)  NOT NULL UNIQUE
        CHECK (slug ~ '^[a-z0-9-]{3,50}$'
) ,
    timezone         VARCHAR(50)  NOT NULL DEFAULT 'America/Bogota',
    logo_url         VARCHAR(500),
    primary_color    CHAR(7)      NOT NULL DEFAULT '#2563EB'
                     CHECK (primary_color ~ '^#[0-9A-Fa-f]{6}$'),
    secondary_color  CHAR(7)
                     CHECK (secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users
(
    id            UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    tenant_id     UUID         NOT NULL REFERENCES tenants (id),
    email         VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name     VARCHAR(100) NOT NULL,
    role          VARCHAR(20)  NOT NULL CHECK (role IN ('ADMIN', 'RECEPTIONIST')),
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX uq_users_tenant_email ON users (tenant_id, lower(email));

CREATE TABLE members
(
    id              UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES tenants (id),
    document_number VARCHAR(20) NOT NULL,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    phone           VARCHAR(20),
    created_by      UUID REFERENCES users (id),
    archived_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, id),
    UNIQUE (tenant_id, document_number)
);

CREATE TABLE plans
(
    id            UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    tenant_id     UUID        NOT NULL REFERENCES tenants (id),
    name          VARCHAR(50) NOT NULL,
    price         BIGINT      NOT NULL CHECK (price >= 0),
    duration_days INT         NOT NULL CHECK (duration_days > 0),
    is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
    UNIQUE (tenant_id, id)
);

CREATE TABLE subscriptions
(
    id         UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    tenant_id  UUID        NOT NULL REFERENCES tenants (id),
    member_id  UUID,
    plan_id    UUID        NOT NULL,
    price      BIGINT      NOT NULL CHECK (price >= 0),
    start_date DATE        NOT NULL,
    end_date   DATE        NOT NULL,
    status     VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'CANCELLED')),
    created_by UUID REFERENCES users (id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (end_date >= start_date),
    UNIQUE (tenant_id, id),
    FOREIGN KEY (tenant_id, member_id) REFERENCES members (tenant_id, id),
    FOREIGN KEY (tenant_id, plan_id) REFERENCES plans (tenant_id, id)
);

CREATE TABLE payments
(
    id              UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES tenants (id),
    subscription_id UUID        NOT NULL,
    amount          BIGINT      NOT NULL CHECK (amount > 0),
    payment_method  VARCHAR(20) NOT NULL
        CHECK (payment_method IN (
                                  'CASH', 'TRANSFER', 'NEQUI', 'DAVIPLATA',
                                  'BREB', 'PSE', 'MERCADO_PAGO', 'CARD')),
    reference       VARCHAR(100),
    notes           VARCHAR(255),
    created_by      UUID REFERENCES users (id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (tenant_id, subscription_id) REFERENCES subscriptions (tenant_id, id)
);

CREATE INDEX idx_payments_tenant_date ON payments (tenant_id, created_at);
CREATE INDEX idx_payments_subscription ON payments (subscription_id);
CREATE INDEX idx_subs_tenant_end ON subscriptions (tenant_id, end_date);
CREATE INDEX idx_subs_member ON subscriptions (tenant_id, member_id);
CREATE INDEX idx_members_name ON members (tenant_id, last_name, first_name);