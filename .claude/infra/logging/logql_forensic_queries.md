# LogQL Forensic Query Templates - TovPlay Production

Complete collection of LogQL queries for instant root cause analysis and forensic investigation.

## Table of Contents
1. [WHO Queries](#who-queries) - Find user actions
2. [WHEN Queries](#when-queries) - Time-based analysis
3. [WHAT Queries](#what-queries) - Action analysis
4. [WHY Queries](#why-queries) - Error and failure analysis
5. [HOW Queries](#how-queries) - Trace execution flow
6. [Emergency Queries](#emergency-queries) - Incident response

---

## WHO Queries

### Find all actions by a specific user
```logql
{job="tovplay-backend"} |= "user_id" | json | user_id="123"
```

### Find who deleted a specific resource
```logql
{job="tovplay-backend"}
  |= "DELETE"
  | json
  | action="DELETE"
  | resource_id="456"
```

### Find all admin actions
```logql
{job="tovplay-backend"}
  | json
  | roles =~ ".*admin.*"
```

### Find all actions from a specific IP address
```logql
{job="tovplay-backend"}
  |= "ip"
  | json
  | ip="192.168.1.100"
```

### Find who accessed sensitive data
```logql
{job="tovplay-backend"}
  |= "action"
  | json
  | action =~ "EXPORT|DOWNLOAD"
  | resource_type="User"
```

---

## WHEN Queries

### Find all errors in the last hour
```logql
{job="tovplay-backend"}
  | json
  | level="ERROR"
  | __timestamp__ > now() - 1h
```

### Find actions during a specific time window (incident investigation)
```logql
{job="tovplay-backend"}
  | json
  | __timestamp__ >= 1702644000
  | __timestamp__ <= 1702647600
```

### Find slow requests (>1 second)
```logql
{job="tovplay-backend"}
  | json
  | duration_ms > 1000
```

### Count errors per minute
```logql
sum by (level) (
  count_over_time(
    {job="tovplay-backend"}
    | json
    | level="ERROR" [1m]
  )
)
```

### Find peak traffic times
```logql
sum(
  count_over_time(
    {job="tovplay-backend"}
    | json
    | method="GET" [5m]
  )
)
```

---

## WHAT Queries

### Find all database operations
```logql
{job="tovplay-backend"}
  |= "action"
  | json
  | action =~ "CREATE|UPDATE|DELETE"
```

### Find all game deletions
```logql
{job="tovplay-backend"}
  | json
  | action="DELETE"
  | resource_type="Game"
```

### Find all login attempts
```logql
{job="tovplay-backend"}
  |= "LOGIN"
  | json
  | action="LOGIN"
```

### Find failed login attempts
```logql
{job="tovplay-backend"}
  | json
  | action="LOGIN"
  | success="false"
```

### Find all password reset requests
```logql
{job="tovplay-backend"}
  | json
  | action="PASSWORD_RESET"
```

### Find all API calls to a specific endpoint
```logql
{job="tovplay-backend"}
  | json
  | path="/api/games"
```

### Find all 5xx errors
```logql
{job="tovplay-backend"}
  | json
  | status_code >= 500
```

### Find all 4xx errors (client errors)
```logql
{job="tovplay-backend"}
  | json
  | status_code >= 400
  | status_code < 500
```

---

## WHY Queries

### Find the cause of a specific error
```logql
{job="tovplay-backend"}
  |= "too many clients"
  | json
```

### Find all database connection errors
```logql
{job="tovplay-backend"}
  | json
  | error =~ ".*connection.*"
  | level="ERROR"
```

### Find all exceptions with stack traces
```logql
{job="tovplay-backend"}
  | json
  | exception != ""
```

### Find all timeout errors
```logql
{job="tovplay-backend"}
  | json
  | error =~ ".*timeout.*"
```

### Find root cause of cascading failures
```logql
{job="tovplay-backend"}
  | json
  | correlation_id="550e8400-e29b-41d4-a716-446655440000"
```

### Find why a request failed
```logql
{job="tovplay-backend"}
  | json
  | correlation_id="550e8400-e29b-41d4-a716-446655440000"
  | level =~ "ERROR|CRITICAL"
```

---

## HOW Queries

### Trace a complete request (correlation ID)
```logql
{job="tovplay-backend"}
  | json
  | correlation_id="550e8400-e29b-41d4-a716-446655440000"
```

### Trace all database queries for a request
```logql
{job="postgresql"}
  |= "550e8400-e29b-41d4-a716-446655440000"
```

### Trace user journey (all requests by user)
```logql
{job="tovplay-backend"}
  | json
  | user_id="123"
  | __timestamp__ > now() - 1h
```

### Trace function execution flow
```logql
{job="tovplay-backend"}
  | json
  | function =~ ".*game.*"
  | correlation_id="550e8400-e29b-41d4-a716-446655440000"
```

### Trace API endpoint performance
```logql
avg by (path) (
  avg_over_time(
    {job="tovplay-backend"}
    | json
    | unwrap duration_ms [5m]
  )
)
```

---

## Emergency Queries

### EMERGENCY: Database wipe detection
```logql
{job="tovplay-backend"}
  | json
  | action="DELETE"
  | __timestamp__ > now() - 5m
```

Count of deletes per user in last 5 minutes:
```logql
sum by (user_id, username) (
  count_over_time(
    {job="tovplay-backend"}
    | json
    | action="DELETE" [5m]
  )
)
```

### EMERGENCY: Find who did mass delete
```logql
{job="tovplay-backend"}
  | json
  | action="DELETE"
  | __timestamp__ > now() - 10m
```

### EMERGENCY: Find all critical severity events
```logql
{job="tovplay-backend"}
  | json
  | severity="CRITICAL"
```

### EMERGENCY: Find all unauthorized access attempts
```logql
{job="tovplay-backend"}
  | json
  | error =~ ".*unauthorized|forbidden|permission denied.*"
```

### EMERGENCY: Find all security events
```logql
{job="tovplay-backend"}
  | json
  | action =~ "PERMISSION_CHANGE|API_KEY_CREATE|API_KEY_REVOKE|TWO_FACTOR_DISABLE"
```

### EMERGENCY: Detect DDoS or brute force
```logql
sum by (ip) (
  count_over_time(
    {job="tovplay-backend"}
    | json
    | action="LOGIN"
    | success="false" [1m]
  )
) > 10
```

### EMERGENCY: Find memory/disk issues
```logql
{job="syslog"}
  |~ "out of memory|disk full|no space"
```

### EMERGENCY: Find database deadlocks
```logql
{job="postgresql"}
  |~ "deadlock detected"
```

---

## Advanced Forensic Patterns

### Pattern 1: Find who changed what when
```logql
{job="tovplay-backend"}
  | json
  | resource_type="User"
  | resource_id="456"
  | action="UPDATE"
```

### Pattern 2: Compare before/after values
```logql
{job="tovplay-backend"}
  | json
  | action="UPDATE"
  | changed_fields != ""
```

### Pattern 3: Find the sequence of events leading to error
```logql
{job="tovplay-backend"}
  | json
  | correlation_id="<ID_FROM_ERROR>"
  | __timestamp__ <= <ERROR_TIMESTAMP>
```

### Pattern 4: Find users affected by an issue
```logql
sum by (user_id) (
  count_over_time(
    {job="tovplay-backend"}
    | json
    | error =~ ".*<ERROR_PATTERN>.*" [1h]
  )
)
```

### Pattern 5: Calculate error rate
```logql
sum(rate(
  {job="tovplay-backend"}
  | json
  | level="ERROR" [5m]
))
/
sum(rate(
  {job="tovplay-backend"}
  | json [5m]
))
```

### Pattern 6: Find slowest endpoints
```logql
topk(10,
  avg by (path) (
    avg_over_time(
      {job="tovplay-backend"}
      | json
      | unwrap duration_ms [5m]
    )
  )
)
```

### Pattern 7: Find most active users
```logql
topk(10,
  sum by (username) (
    count_over_time(
      {job="tovplay-backend"}
      | json
      | user_id != "" [1h]
    )
  )
)
```

### Pattern 8: Audit trail for compliance
```logql
{job="tovplay-backend"}
  | json
  | user_id="<USER_ID>"
  | __timestamp__ >= <START_DATE>
  | __timestamp__ <= <END_DATE>
```

---

## Real-World Scenarios

### Scenario 1: "Boss says DB got wiped! Who did it?"
```logql
# Step 1: Find all deletes in suspicious timeframe
{job="tovplay-backend"}
  | json
  | action="DELETE"
  | __timestamp__ >= 1702644000
  | __timestamp__ <= 1702647600

# Step 2: Count deletes per user
sum by (user_id, username, ip) (
  count_over_time(
    {job="tovplay-backend"}
    | json
    | action="DELETE"
    | __timestamp__ >= 1702644000
    | __timestamp__ <= 1702647600 [1m]
  )
)

# Step 3: Get detailed audit trail
{job="tovplay-backend"}
  | json
  | user_id="<SUSPECT_USER_ID>"
  | action="DELETE"
```

### Scenario 2: "User says their account was hacked"
```logql
# Step 1: Find all login attempts
{job="tovplay-backend"}
  | json
  | action="LOGIN"
  | user_id="<USER_ID>"

# Step 2: Find logins from unusual IPs
{job="tovplay-backend"}
  | json
  | action="LOGIN"
  | user_id="<USER_ID>"
  | ip != "<USUAL_IP>"

# Step 3: Find all actions after suspicious login
{job="tovplay-backend"}
  | json
  | user_id="<USER_ID>"
  | __timestamp__ >= <SUSPICIOUS_LOGIN_TIME>
```

### Scenario 3: "API is slow, what's causing it?"
```logql
# Step 1: Find slow requests
{job="tovplay-backend"}
  | json
  | duration_ms > 1000

# Step 2: Group by endpoint
avg by (path) (
  avg_over_time(
    {job="tovplay-backend"}
    | json
    | unwrap duration_ms [5m]
  )
)

# Step 3: Find slow database queries
{job="postgresql"}
  | duration_ms > 500
```

### Scenario 4: "Users reporting errors, what's broken?"
```logql
# Step 1: Count errors by type
sum by (error) (
  count_over_time(
    {job="tovplay-backend"}
    | json
    | level="ERROR" [5m]
  )
)

# Step 2: Find first occurrence
{job="tovplay-backend"}
  | json
  | error =~ ".*<ERROR_PATTERN>.*"
  | level="ERROR"

# Step 3: Trace back to root cause
{job="tovplay-backend"}
  | json
  | correlation_id="<ID_FROM_FIRST_ERROR>"
```

---

## Grafana Dashboard Queries

### Panel 1: Request Rate
```logql
sum(rate({job="tovplay-backend"} | json [1m]))
```

### Panel 2: Error Rate
```logql
sum(rate({job="tovplay-backend"} | json | level="ERROR" [1m]))
```

### Panel 3: P95 Latency
```logql
quantile_over_time(0.95,
  {job="tovplay-backend"}
  | json
  | unwrap duration_ms [5m]
)
```

### Panel 4: Top Errors
```logql
topk(5,
  sum by (error) (
    count_over_time(
      {job="tovplay-backend"}
      | json
      | level="ERROR" [5m]
    )
  )
)
```

### Panel 5: Active Users
```logql
count(
  count by (user_id) (
    {job="tovplay-backend"}
    | json
    | user_id != ""
    | __timestamp__ > now() - 5m
  )
)
```

### Panel 6: Endpoint Performance
```logql
avg by (path) (
  avg_over_time(
    {job="tovplay-backend"}
    | json
    | unwrap duration_ms [5m]
  )
)
```

---

## Access from Grafana

1. Open Grafana: http://193.181.213.220:3002
2. Go to Explore
3. Select "Loki" as data source
4. Paste any query above
5. Adjust time range as needed
6. Click "Run query"

## Access via CLI (logcli)

```bash
# Install logcli
curl -O -L "https://github.com/grafana/loki/releases/download/v2.9.3/logcli-linux-amd64.zip"
unzip "logcli-linux-amd64.zip"
chmod a+x "logcli-linux-amd64"

# Query logs
./logcli-linux-amd64 --addr=http://193.181.213.220:3100 query '{job="tovplay-backend"} | json | user_id="123"'

# Stream live logs
./logcli-linux-amd64 --addr=http://193.181.213.220:3100 query --tail '{job="tovplay-backend"} | json'
```

---

## Performance Tips

1. **Use label filters first**: `{job="tovplay-backend"}` before parsing
2. **Use `|=` for string matching**: Faster than regex
3. **Use `| json` once**: Parse JSON once, then filter
4. **Use time ranges**: Always specify `[5m]` or similar
5. **Use aggregations**: `sum`, `count`, `avg` for metrics
6. **Avoid `.*` regex**: Be specific with patterns
7. **Cache results**: Use Grafana variables for repeated queries

---

**Generated**: 2025-12-15 10:30:00 UTC
**For**: TovPlay Logging & Auditing Platform
**Use**: Instant forensic analysis and incident response
