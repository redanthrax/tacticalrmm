import django_filters
from checks.models import Check


class CheckFilter(django_filters.FilterSet):
    error_threshold_range = django_filters.NumericRangeFilter(field_name="error_threshold")
    warning_threshold_range = django_filters.NumericRangeFilter(field_name="warning_threshold")
    run_interval_range = django_filters.NumericRangeFilter(field_name="run_interval")
    
    class Meta:
        model = Check
        fields = [
            "id",
            "check_type",
            "name",
            "email_alert", 
            "text_alert",
            "dashboard_alert",
            "agent",
            "policy",
            "overridden_by_policy",
            "alert_severity",
            "error_threshold_range",
            "warning_threshold_range",
            "run_interval_range",
        ]
