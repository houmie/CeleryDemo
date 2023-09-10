from app.notify.xray import HealthCheck
from config import get_settings
from app.notify.celery import app


# Load settings
settings = get_settings()


class VpnTypeMissingError(Exception):
    pass


@app.task
def push():
    hc = HealthCheck()
    hc.report()
