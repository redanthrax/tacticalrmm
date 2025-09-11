import django_filters
from alerts.models import Alert


class AlertFilter(django_filters.FilterSet):
    alert_time_range = django_filters.DateTimeFromToRangeFilter(field_name="alert_time")
    resolved_on_range = django_filters.DateTimeFromToRangeFilter(field_name="resolved_on")
    snooze_until_range = django_filters.DateTimeFromToRangeFilter(field_name="snooze_until")
    
    class Meta:
        model = Alert
        fields = [
            "id",
            "alert_type",
            "severity",
            "resolved",
            "snoozed",
            "hidden",
            "agent",
            "assigned_check",
            "assigned_task",
            "alert_time_range",
            "resolved_on_range",
            "snooze_until_range",
        ]
