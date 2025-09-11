from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from drf_spectacular.utils import extend_schema, extend_schema_view

from software.models import InstalledSoftware
from software.permissions import SoftwarePerms
from beta.v1.pagination import StandardResultsSetPagination
from ..serializers import SoftwareSerializer


@extend_schema_view(
    list=extend_schema(
        tags=["Beta API v1 - Software"],
        description="List all installed software with filtering and pagination",
        summary="List Software"
    ),
    retrieve=extend_schema(
        tags=["Beta API v1 - Software"],
        description="Retrieve specific software by ID",
        summary="Get Software"
    ),
    update=extend_schema(
        tags=["Beta API v1 - Software"],
        description="Update specific software",
        summary="Update Software"
    ),
    partial_update=extend_schema(
        tags=["Beta API v1 - Software"],
        description="Partially update specific software",
        summary="Patch Software"
    ),
)
class SoftwareViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, SoftwarePerms]
    queryset = InstalledSoftware.objects.all()
    serializer_class = SoftwareSerializer
    pagination_class = StandardResultsSetPagination
    http_method_names = ["get", "put"]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ["agent__hostname"]
    ordering_fields = ["id", "agent__hostname"]
    ordering = ["id"]
