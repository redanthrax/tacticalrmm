from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from drf_spectacular.utils import extend_schema, extend_schema_view

from autotasks.models import AutomatedTask
from autotasks.permissions import AutoTaskPerms
from beta.v1.pagination import StandardResultsSetPagination
from ..serializers import TaskSerializer


@extend_schema_view(
    list=extend_schema(
        tags=["Beta API v1 - Tasks"],
        description="List all automated tasks with filtering and pagination",
        summary="List Tasks"
    ),
    retrieve=extend_schema(
        tags=["Beta API v1 - Tasks"],
        description="Retrieve a specific task by ID",
        summary="Get Task"
    ),
    update=extend_schema(
        tags=["Beta API v1 - Tasks"],
        description="Update a specific task",
        summary="Update Task"
    ),
    partial_update=extend_schema(
        tags=["Beta API v1 - Tasks"],
        description="Partially update a specific task",
        summary="Patch Task"
    ),
)
class TaskViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, AutoTaskPerms]
    queryset = AutomatedTask.objects.all()
    serializer_class = TaskSerializer
    pagination_class = StandardResultsSetPagination
    http_method_names = ["get", "put"]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    search_fields = ["name", "task_type"]
    ordering_fields = ["id", "name", "task_type", "enabled"]
    ordering = ["id"]
