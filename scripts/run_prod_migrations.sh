#!/usr/bin/env bash
set -euo pipefail

# Run production migrations/seeds inside the Kamal-managed app container.
# Usage: ./scripts/run_prod_migrations.sh

echo "Running migrations in production via Kamal..."
bin/kamal app exec --interactive --reuse "bin/rails db:migrate RAILS_ENV=production"
echo "Running seeds (if any)..."
bin/kamal app exec --interactive --reuse "bin/rails db:seed RAILS_ENV=production"
echo "Done. Check logs if there were errors: bin/kamal app logs -f"
