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

        # Initialize PostgreSQL if needed
        if [ ! -d "$PGDATA" ]; then
          mkdir -p "$PGDATA" "$PGHOST"
          initdb --no-locale --encoding=UTF8 -D "$PGDATA"
          # Configure to use Unix socket only (no TCP)
          cat >> "$PGDATA/postgresql.conf" <<PGCONF
    listen_addresses = '''
    unix_socket_directories = '$PGHOST'
    PGCONF
          # Create a default database for the current user
          echo "CREATE DATABASE $USER;" | postgres --single -E postgres
        fi

        # Ensure socket directory exists
        mkdir -p "$PGHOST"

        # Helper scripts (shell-agnostic, works in bash and zsh)
        export _PG_BIN="$PWD/.postgres/bin"
        mkdir -p "$_PG_BIN"

        cat > "$_PG_BIN/pg_start" <<'PGSCRIPT'
    #!/usr/bin/env bash
    if ! pg_isready -h "$PGHOST" -q; then
      echo "Starting PostgreSQL..."
      pg_ctl -D "$PGDATA" -l "$PGDATA/postgresql.log" start
    else
      echo "PostgreSQL is already running"
    fi
    PGSCRIPT

        cat > "$_PG_BIN/pg_stop" <<'PGSCRIPT'
    #!/usr/bin/env bash
    if pg_isready -h "$PGHOST" -q; then
      echo "Stopping PostgreSQL..."
      pg_ctl -D "$PGDATA" stop
    else
      echo "PostgreSQL is not running"
    fi
    PGSCRIPT

        cat > "$_PG_BIN/pg_status" <<'PGSCRIPT'
    #!/usr/bin/env bash
    pg_isready -h "$PGHOST"
    PGSCRIPT

        chmod +x "$_PG_BIN"/{pg_start,pg_stop,pg_status}
        export PATH="$_PG_BIN:$PATH"
  '';
}
