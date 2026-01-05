# TovPlay Backend

**Parent Docs:** See `/CLAUDE.md` for full architecture, credentials, and rules.

---

## LOCAL SETUP

**Requirements:** Python 3.11, PostgreSQL client
```bash
cd F:\tovplay\tovplay-backend
python -m venv venv
.\venv\Scripts\activate  # Windows
pip install -r requirements.txt
cp .env.template .env  # Edit with credentials from /CLAUDE.md
flask run --host=0.0.0.0 --port=5001 --debug
```

**Docker Setup:**
```bash
# External DB (default)
docker-compose up backend

# Local PostgreSQL
docker-compose --profile local-db up
```

**Test:** `http://localhost:5001/health` should return 200 OK

---

## STRUCTURE

```
tovplay-backend/
├─ src/                  # Core application
│  ├─ api/              # API endpoints
│  ├─ app/              # Flask app & routes
│  │  └─ routes/        # Route blueprints
│  ├─ config/           # Configuration
│  ├─ database/         # DB models & migrations
│  ├─ services/         # Business logic
│  └─ utils/            # Helpers
├─ scripts/             # Deployment scripts
├─ tests/               # Test suite
├─ requirements.txt     # Python deps
├─ wsgi.py              # Production entry
├─ Dockerfile           # Multi-stage build
└─ .env                 # Environment vars
```

---

## KEY FILES

**Entry Points:**
- `wsgi.py` - Production Gunicorn entry
- `src/app/__init__.py` - Flask app factory

**Models:** `src/database/models/`
- `user.py` - User, UserProfile, UserSession
- `game.py` - Game, GameRequest
- `scheduled_session.py` - ScheduledSession
- `user_availability.py` - UserAvailability
- `user_friends.py` - UserFriends
- `user_game_preference.py` - UserGamePreference
- `user_notifications.py` - UserNotifications
- `email_verification.py` - EmailVerification

**Routes:** `src/app/routes/`
- `signup_signin.py` - Auth endpoints
- `user_routes.py` - User management
- `game_request_routes.py` - Game requests
- `notifications_routes.py` - Notifications
- `discord_auth.py` - Discord integration

---

## DOCKER

**Unified docker-compose.yml** supports local/staging/production via .env configuration

**Multi-stage build:** development, staging, production
```bash
# Build
docker build --target production -t tovtech/tovplaybackend:latest .

# Run locally with external DB
docker-compose up backend

# Run locally with local PostgreSQL
docker-compose --profile local-db up

# Deploy production
ssh admin@193.181.213.220
cd /home/admin/tovplay
docker pull tovtech/tovplaybackend:latest
docker-compose up -d --force-recreate backend
```

**Health Check:** `curl http://localhost:5001/health`

---

## DATABASE

**Connection:** See `/CLAUDE.md` for credentials

**Migrations:**
```bash
# Create migration
flask db migrate -m "description"

# Apply migrations
flask db upgrade

# Rollback
flask db downgrade
```

**Direct access:**
```bash
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay
```

---

## TESTING

```bash
# Run all tests
pytest

# With coverage
pytest --cov=src tests/

# Specific test file
pytest tests/test_routes.py
```

---

## DEPLOYMENT

**GitHub Actions:** `.github/workflows/tests.yml`
- Runs on push to main
- Builds Docker image
- Pushes to Docker Hub (tovtech/tovplaybackend:latest)
- Triggers server deployment

**Manual Deploy:**
```bash
# SSH to production
wsl -d ubuntu bash -c "sshpass -p 'EbTyNkfJG6LM' ssh admin@193.181.213.220"

# Pull latest
cd /home/admin/tovplay
docker-compose pull tovplay-backend
docker-compose up -d tovplay-backend

# Check logs
docker logs tovplay-backend -f
```
