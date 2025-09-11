from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from drf_spectacular.utils import extend_schema, extend_schema_view

from checks.models import Check
from checks.permissions import ChecksPerms
from beta.v1.checks.filter import CheckFilter
from beta.v1.pagination import StandardResultsSetPagination
from ..serializers import CheckSerializer


@extend_schema_view(
    list=extend_schema(
        tags=["Beta API v1 - Checks"],
        description="List all checks with filtering and pagination",
        summary="List Checks"
    ),
    retrieve=extend_schema(
        tags=["Beta API v1 - Checks"],
        description="Retrieve a specific check by ID",
        summary="Get Check"
    ),
    update=extend_schema(
        tags=["Beta API v1 - Checks"],
        description="Update a specific check",
        summary="Update Check"
    ),
    partial_update=extend_schema(
        tags=["Beta API v1 - Checks"],
        description="Partially update a specific check",
        summary="Patch Check"
    ),
)
class CheckViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, ChecksPerms]
    queryset = Check.objects.all()
    serializer_class = CheckSerializer
    pagination_class = StandardResultsSetPagination
    http_method_names = ["get", "put"]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = CheckFilter
    search_fields = ["name", "check_type"]
    ordering_fields = ["id", "name", "check_type"]
    ordering = ["id"]
