# REMAINING SCRIPTS ENHANCEMENT PLAN

## Status: 2/6 Complete (security_report, nginx_report DONE)

## Remaining 4 Scripts to Enhance:

### 3. production_report.sh (285s, 95/100) - NEXT
- 23 SSH calls → 2 MEGA BATCH
- Add: Container health details, resource trends, network stats, process monitoring
- Target: <150s, 100/100 score

### 4. staging_report.sh (296s, 100/100)
- Similar to production_report
- 20+ SSH calls → 2 MEGA BATCH
- Target: <150s, maintain 100/100

### 5. database_report.sh (18s, 81/100)
- Already fast, needs score improvement
- Add: Query performance, index health, connection pool stats
- Target: <25s, 100/100 score

### 6. backend_report.sh (238s, 100/100)
- 25+ SSH calls → 2-3 MEGA BATCH
- Add: API endpoint health, error rates, response times, dependencies
- Target: <120s, maintain 100/100

## Final Steps:
- Update ansall.sh aggregation logic
- Full 'ans' test in WSL to verify <60 min total

**Priority**: Complete these 4 quickly to reach Phase 3 (ansall.sh update) and Phase 4 (full test)
