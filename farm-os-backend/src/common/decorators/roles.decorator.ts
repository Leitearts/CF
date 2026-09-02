import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';

/**
 * Usage: @Roles('farmer', 'admin')
 * Enforced by RolesGuard, which reads this metadata against the caller's
 * farm-scoped role (set by FarmAccessGuard on the request).
 */
export const Roles = (...roles: string[]) => SetMetadata(ROLES_KEY, roles);
