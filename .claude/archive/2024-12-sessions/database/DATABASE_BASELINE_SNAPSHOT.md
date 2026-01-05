# TovPlay Database Baseline Snapshot
**Date**: December 1, 2025, 3:27:06 PM
**Source**: http://193.181.213.220:7777/database-viewer

## Summary Statistics
- **Total Tables**: 13
- **Total Rows**: 543
- **Status**: Production database snapshot

## Table Inventory with Row Counts

| Table Name | Row Count | Status |
|---|---|---|
| User | 21 | ✓ Present |
| UserProfile | 11 | ✓ Present |
| Game | 12 | ✓ Present |
| GameRequest | 182 | ✓ Present |
| ScheduledSession | 16 | ✓ Present |
| UserAvailability | 154 | ✓ Present |
| UserNotifications | 111 | ✓ Present |
| UserGamePreference | 31 | ✓ Present |
| UserFriends | 2 | ✓ Present |
| UserSession | 0 | ✓ Empty (expected) |
| EmailVerification | 0 | ✓ Empty (expected) |
| password_reset_tokens | 2 | ✓ Present |
| alembic_version | 1 | ✓ Present (schema tracking) |

## User Table Details (21 rows)
Key users documented:
- kerenwedel (verified, in_community)
- TovPlay (official account, verified, in_community)
- lilach0492 (verified, in_community)
- Multiple test accounts (testing infrastructure)
- Admin role account (test@test.com)

## Critical Data
- **Total GameRequests**: 182 (core business data)
- **Total UserAvailability**: 154 (scheduling data)
- **Total Notifications**: 111 (notification history)
- **Total Preferences**: 31 (user preferences)
- **Total Sessions**: 16 scheduled (active sessions)

## Dependencies & Relationships
All tables have foreign key relationships and constraints in place.

---

## Protection Implementation Progress
- [ ] Database-level triggers and TRUNCATE blocking
- [ ] DELETE audit logging
- [ ] Access control restrictions
- [ ] Automated backup system
- [ ] Point-in-time recovery
- [ ] Replication & off-site backup
- [ ] Testing of all mechanisms
- [ ] Final verification against baseline

**VERIFICATION TARGET**: All 13 tables must exist with all row counts >= current values
