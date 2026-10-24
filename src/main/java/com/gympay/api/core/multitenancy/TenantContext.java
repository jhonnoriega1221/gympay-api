package com.gympay.api.core.multitenancy;

import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Supplier;

public final class TenantContext {
    public static final UUID NO_TENANT = new UUID(0L, 0L);
    private static final ThreadLocal<UUID> CURRENT = new ThreadLocal<>();

    private TenantContext() {

    }

    public static void set(UUID tenantId) {
        CURRENT.set(Objects.requireNonNull(tenantId, "tenantId"));
    }

    public static Optional<UUID> get() {
        return Optional.ofNullable(CURRENT.get());
    }

    public static UUID require() {
        return get().orElseThrow(() -> new IllegalStateException(("No tenant in the current context")));
    }

    public static void clear() {
        CURRENT.remove();
    }

    public static <T> T callAs(UUID tenantId, Supplier<T> action) {
        UUID previous = CURRENT.get();
        set(tenantId);
        try {
            return action.get();
        } finally {
            if (previous == null) {
                clear();
            } else {
                CURRENT.set(previous);
            }
        }
    }

    public static void runAs(UUID tenantId, Runnable action) {
        callAs(tenantId, () -> {
            action.run();
            return null;
        });
    }

}
