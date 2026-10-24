package com.gympay.api.core.multitenancy;

import jakarta.persistence.Column;
import org.hibernate.annotations.TenantId;

import java.util.UUID;

public abstract class TenantOwnedEntity {

    @TenantId
    @Column(name = "tenant_id", nullable = false, updatable = false)
    private UUID tenantId;
}
