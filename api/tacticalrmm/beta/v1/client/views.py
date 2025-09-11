from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from drf_spectacular.utils import extend_schema, extend_schema_view

from clients.models import Client
from clients.permissions import ClientsPerms
from ..serializers import ClientSerializer


@extend_schema_view(
    list=extend_schema(
        tags=["Beta API v1 - Clients"],
        description="List all clients",
        summary="List Clients"
    ),
    retrieve=extend_schema(
        tags=["Beta API v1 - Clients"],
        description="Retrieve a specific client by ID",
        summary="Get Client"
    ),
    update=extend_schema(
        tags=["Beta API v1 - Clients"],
        description="Update a specific client",
        summary="Update Client"
    ),
    partial_update=extend_schema(
        tags=["Beta API v1 - Clients"],
        description="Partially update a specific client",
        summary="Patch Client"
    ),
)
class ClientViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, ClientsPerms]
    queryset = Client.objects.all()
    serializer_class = ClientSerializer
    http_method_names = ["get", "put"]
