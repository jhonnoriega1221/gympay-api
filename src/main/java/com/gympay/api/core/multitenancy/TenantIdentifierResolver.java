package com.gympay.api.core.multitenancy;

import org.hibernate.context.spi.CurrentTenantIdentifierResolver;

import java.util.UUID;

public class TenantIdentifierResolver implements CurrentTenantIdentifierResolver<UUID> {
    @Override
    public UUID resolveCurrentTenantIdentifier() {
        return TenantContext.get().orElse(TenantContext.NO_TENANT);
    }

    @Override
    public boolean validateExistingCurrentSessions() {
        return true;
    }
}
