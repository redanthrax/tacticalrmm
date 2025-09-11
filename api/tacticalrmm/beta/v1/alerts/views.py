from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from drf_spectacular.utils import extend_schema, extend_schema_view

from alerts.models import Alert
from alerts.permissions import AlertPerms
from beta.v1.alerts.filter import AlertFilter
from beta.v1.pagination import StandardResultsSetPagination
from ..serializers import AlertSerializer


@extend_schema_view(
    list=extend_schema(
        tags=["Beta API v1 - Alerts"],
        description="List all alerts with filtering and pagination",
        summary="List Alerts"
    ),
    retrieve=extend_schema(
        tags=["Beta API v1 - Alerts"],
        description="Retrieve a specific alert by ID",
        summary="Get Alert"
    ),
    update=extend_schema(
        tags=["Beta API v1 - Alerts"],
        description="Update a specific alert",
        summary="Update Alert"
    ),
    partial_update=extend_schema(
        tags=["Beta API v1 - Alerts"],
        description="Partially update a specific alert",
        summary="Patch Alert"
    ),
)
class AlertViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, AlertPerms]
    queryset = Alert.objects.all()
    serializer_class = AlertSerializer
    pagination_class = StandardResultsSetPagination
    http_method_names = ["get", "put"]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = AlertFilter
    search_fields = ["message", "alert_type", "severity"]
    ordering_fields = ["id", "alert_time", "resolved"]
    ordering = ["-alert_time"]
