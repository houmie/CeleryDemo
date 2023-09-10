from celery import Celery

app = Celery("notify", include=["notify.tasks"])
app.config_from_object("notify.celery_config")


app.conf.beat_schedule = {
    "run-push-every-40-seconds": {"task": "notify.tasks.push", "schedule": 40.0},
}
