import json
import logging
import os

import redis

log = logging.getLogger("cache")

CACHE_ENABLED = os.getenv("CACHE_ENABLED", "false").lower() == "true"
CACHE_TTL = int(os.getenv("CACHE_TTL", "30"))

_client = None
if CACHE_ENABLED:
    _client = redis.Redis.from_url(
        os.environ["REDIS_URL"],
        decode_responses=True,
        socket_connect_timeout=0.5,
        socket_timeout=0.5,
    )


def cache_get(key: str):
    if _client is None:
        return None
    try:
        value = _client.get(key)
        return json.loads(value) if value else None
    except Exception as e:
        log.warning("cache get failed: %s", e)
        return None


def cache_set(key: str, data) -> None:
    if _client is None:
        return
    try:
        _client.setex(key, CACHE_TTL, json.dumps(data))
    except Exception as e:
        log.warning("cache set failed: %s", e)


def cache_delete(*keys: str) -> None:
    if _client is None:
        return
    try:
        _client.delete(*keys)
    except Exception as e:
        log.warning("cache delete failed: %s", e)