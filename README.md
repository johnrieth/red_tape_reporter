# Red Tape Reporter

A web application for collecting, verifying, and publicly sharing reports of bureaucratic inefficiencies in Los Angeles government. Residents can submit reports anonymously or with attribution, and approved reports are published as stories that the public can browse, vote on, and comment on.

## Features

- **Report submission** — Public form with email verification
- **Admin review** — Approve, export (PDF), or delete incoming reports
- **Public stories** — Browse and filter approved reports
- **Engagement** — Token-based anonymous voting and commenting on stories
- **Issues** — Curated issues with community support and threaded comments
- **Audit logging** — Admin actions are logged with IP and metadata
- **Rate limiting** — Per-IP and per-email limits on submissions and password resets
- **Email notifications** — Verification, approval, and admin alerts via Resend
- **Sitemap** — Auto-generated for SEO

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Ruby 3.4.6 |
| Framework | Rails 8.0.3 |
| Database | PostgreSQL (SQLite in development) |
| Frontend | Hotwire (Turbo + Stimulus), Propshaft |
| Background jobs | Solid Queue |
| Caching | Solid Cache |
| WebSockets | Solid Cable |
| Web server | Puma + Thruster |
| Email | Resend |
| PDF generation | Prawn |
| Security | Rack::Attack, Brakeman |
| Deployment | Kamal |
| Error tracking | Sentry |

## Getting Started

### Prerequisites

- Ruby 3.4.6
- PostgreSQL (or SQLite for local development)
- Node.js (for importmap auditing)

### Setup

```bash
git clone <repo-url>
cd red_tape_reporter

bundle install
bin/rails db:setup
bin/rails server
```

The app will be available at `http://localhost:3000`.

### Environment Variables

| Variable | Description |
|---|---|
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` |
| `DATABASE_URL` | Database connection string (production) |
| `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASSWORD` | Individual DB config (alternative to `DATABASE_URL`) |
| `RAILS_ENV` | `development`, `test`, or `production` |
| `RAILS_LOG_LEVEL` | Log verbosity |
| `RAILS_MAX_THREADS` | Puma thread count |

## Running Tests

```bash
bin/rails test
bin/rails test:system   # Capybara + Chrome system tests
```

## Linting & Security

```bash
bundle exec rubocop          # Style checks
bundle exec brakeman         # Security vulnerability scan
bin/rails importmap:audit    # JS dependency audit
```

## CI/CD

GitHub Actions runs on every push:

1. Brakeman security scan
2. ImportMap JS audit
3. RuboCop
4. Full test suite (including system tests)

## Deployment

The app is deployed with [Kamal](https://kamal-deploy.org). See `config/deploy.yml` for configuration.

```bash
kamal deploy
```

## Key Routes

| Route | Description |
|---|---|
| `GET /` | Landing page |
| `POST /reports` | Submit a report |
| `GET /verify/:token` | Email verification |
| `GET /stories` | Browse approved reports |
| `GET /stories/:id` | Individual story |
| `POST /stories/:id/vote` | Vote on a story |
| `POST /stories/:id/comments` | Comment on a story |
| `GET /issues` | Browse curated issues |
| `GET /admin/reports` | Admin dashboard |

## Admin Access

Admin accounts are managed via the `User` model with `has_secure_password`. There is no public registration — admin users must be created via the Rails console.

```ruby
User.create!(email: "admin@example.com", password: "...", password_confirmation: "...")
```

## Rate Limits

- 30 report submissions per hour per IP
- 30 report submissions per day per email address
- 5 password reset requests per hour per IP

## License

See [LICENSE](LICENSE) for details.
