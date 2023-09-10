import redis

from config import get_settings

settings = get_settings()


def create_redis_connection_sync():
    return redis.Redis(
        host=settings.REDIS_IP,
        password=settings.REDIS_PASSWORD,
        port=settings.REDIS_PORT,
        db=settings.REDIS_DB,
        decode_responses=True,
    )
