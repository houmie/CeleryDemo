from datetime import datetime

from config import get_settings
from notify.redis_client_sync import create_redis_connection_sync

settings = get_settings()


class HealthCheck:
    def report(self) -> None:
        info = {"timestamp": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")}
        redys = create_redis_connection_sync()
        redys.hset("CLIENT-1", mapping=info)
        redys.close()
