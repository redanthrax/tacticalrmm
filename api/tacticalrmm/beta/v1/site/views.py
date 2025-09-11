from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from drf_spectacular.utils import extend_schema, extend_schema_view

from clients.models import Site
from clients.permissions import SitesPerms
from beta.v1.pagination import StandardResultsSetPagination
from ..serializers import SiteSerializer


@extend_schema_view(
    list=extend_schema(
        tags=["Beta API v1 - Sites"],
        description="List all sites",
        summary="List Sites"
    ),
    retrieve=extend_schema(
        tags=["Beta API v1 - Sites"],
        description="Retrieve a specific site by ID",
        summary="Get Site"
    ),
    update=extend_schema(
        tags=["Beta API v1 - Sites"],
        description="Update a specific site",
        summary="Update Site"
    ),
    partial_update=extend_schema(
        tags=["Beta API v1 - Sites"],
        description="Partially update a specific site",
        summary="Patch Site"
    ),
)
class SiteViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, SitesPerms]
    queryset = Site.objects.all()
    serializer_class = SiteSerializer
    pagination_class = StandardResultsSetPagination
    http_method_names = ["get", "put"]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ["name"]
    ordering_fields = ["id"]
    ordering = ["id"]
