from config import get_settings
from notify.my_celery import app
from notify.xray import HealthCheck

# Load settings
settings = get_settings()


@app.task
def push():
    hc = HealthCheck()
    hc.report()
