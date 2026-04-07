# PostgreSQL with Unix socket helper
{
  pkgs,
  version ? "16",
  package ? null,
}: let
  major = builtins.head (builtins.splitVersion version);
  postgresPackage =
    if package != null
    then package
    else pkgs."postgresql_${major}";
in {
  packages = [postgresPackage];

  shellHook = ''
        # PostgreSQL configuration (Unix socket) - paths derived from PWD
        export PGDATA="$PWD/.postgres/data"
        export PGHOST="$PWD/.postgres/sockets"
        export DATABASE_URL="postgresql:///postgres?host=$PGHOST"

        # Initialize PostgreSQL if needed
        if [ ! -d "$PGDATA" ]; then
          mkdir -p "$PGDATA" "$PGHOST"
          initdb --no-locale --encoding=UTF8 -D "$PGDATA"
          # Configure to use Unix socket only (no TCP)
          cat >> "$PGDATA/postgresql.conf" <<PGCONF
    listen_addresses = '''
    unix_socket_directories = '$PGHOST'
    PGCONF
        fi

        # Ensure socket directory exists
        mkdir -p "$PGHOST"

        # Helper functions
        pg_start() {
          if ! pg_isready -q; then
            echo "Starting PostgreSQL..."
            pg_ctl -D "$PGDATA" -l "$PGDATA/postgresql.log" start
          else
            echo "PostgreSQL is already running"
          fi
        }

        pg_stop() {
          if pg_isready -q; then
            echo "Stopping PostgreSQL..."
            pg_ctl -D "$PGDATA" stop
          else
            echo "PostgreSQL is not running"
          fi
        }

        pg_status() {
          pg_isready
        }

        export -f pg_start pg_stop pg_status
  '';
}
