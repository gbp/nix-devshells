# Redis development environment helper
{
  pkgs,
  version ? "latest",
  package ? null,
}: let
  redisPackage =
    if package != null
    then package
    else if version == "latest"
    then pkgs.redis
    else pkgs."redis_${builtins.replaceStrings ["."] ["_"] version}";
in {
  packages = [redisPackage];

  shellHook = ''
    # Redis configuration - uses $PWD for per-project data isolation
    export REDIS_DATA="$PWD/.redis"
    export REDIS_CONF="$REDIS_DATA/redis.conf"
    export REDIS_LOG="$REDIS_DATA/redis.log"
    export REDIS_SOCKET="$REDIS_DATA/redis.sock"
    export REDIS_URL="unix://$REDIS_SOCKET"

    # Initialize Redis if needed
    if [ ! -d "$REDIS_DATA" ]; then
      mkdir -p "$REDIS_DATA"
      cat > "$REDIS_CONF" <<REDISCONF
    dir $REDIS_DATA
    port 0
    daemonize no
    logfile $REDIS_LOG
    unixsocket $REDIS_DATA/redis.sock
    unixsocketperm 700
    REDISCONF
    fi

    # Helper scripts (shell-agnostic, works in bash and zsh)
    export _REDIS_BIN="$PWD/.redis/bin"
    mkdir -p "$_REDIS_BIN"

    cat > "$_REDIS_BIN/redis_start" <<'REDISSCRIPT'
    #!/usr/bin/env bash
    if redis-cli -s "$REDIS_DATA/redis.sock" ping > /dev/null 2>&1; then
      echo "Redis is already running"
    else
      echo "Starting Redis..."
      redis-server "$REDIS_CONF" --daemonize yes
    fi
    REDISSCRIPT

    cat > "$_REDIS_BIN/redis_stop" <<'REDISSCRIPT'
    #!/usr/bin/env bash
    if redis-cli -s "$REDIS_DATA/redis.sock" ping > /dev/null 2>&1; then
      echo "Stopping Redis..."
      redis-cli -s "$REDIS_DATA/redis.sock" shutdown
    else
      echo "Redis is not running"
    fi
    REDISSCRIPT

    cat > "$_REDIS_BIN/redis_status" <<'REDISSCRIPT'
    #!/usr/bin/env bash
    if redis-cli -s "$REDIS_DATA/redis.sock" ping > /dev/null 2>&1; then
      echo "Redis is running"
    else
      echo "Redis is not running"
    fi
    REDISSCRIPT

    chmod +x "$_REDIS_BIN"/{redis_start,redis_stop,redis_status}
    export PATH="$_REDIS_BIN:$PATH"
  '';

  # Expose for consumers
  redis = redisPackage;
}
