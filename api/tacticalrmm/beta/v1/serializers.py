from rest_framework import serializers

from agents.models import Agent
from clients.models import Client, Site
from alerts.models import Alert
from checks.models import Check
from autotasks.models import AutomatedTask
from software.models import InstalledSoftware


class ListAgentSerializer(serializers.ModelSerializer[Agent]):
    class Meta:
        model = Agent
        fields = "__all__"


class DetailAgentSerializer(serializers.ModelSerializer[Agent]):
    status = serializers.ReadOnlyField()
    hex_mesh_node_id = serializers.ReadOnlyField()

    class Meta:
        model = Agent
        fields = (
            "version",
            "operating_system",
            "plat",
            "goarch",
            "hostname",
            "agent_id",
            "last_seen",
            "services",
            "public_ip",
            "total_ram",
            "disks",
            "boot_time",
            "logged_in_username",
            "last_logged_in_user",
            "monitoring_type",
            "description",
            "mesh_node_id",
            "hex_mesh_node_id",
            "overdue_email_alert",
            "overdue_text_alert",
            "overdue_dashboard_alert",
            "offline_time",
            "overdue_time",
            "check_interval",
            "needs_reboot",
            "choco_installed",
            "wmi_detail",
            "patches_last_installed",
            "time_zone",
            "maintenance_mode",
            "block_policy_inheritance",
            "alert_template",
            "site",
            "policy",
            "status",
            "checks",
            "pending_actions_count",
            "cpu_model",
            "graphics",
            "local_ips",
            "make_model",
            "physical_disks",
            "serial_number",
        )


class ClientSerializer(serializers.ModelSerializer[Client]):
    class Meta:
        model = Client
        fields = "__all__"


class SiteSerializer(serializers.ModelSerializer[Site]):
    class Meta:
        model = Site
        fields = "__all__"


class AlertSerializer(serializers.ModelSerializer[Alert]):
    class Meta:
        model = Alert
        fields = "__all__"


class CheckSerializer(serializers.ModelSerializer[Check]):
    class Meta:
        model = Check
        fields = "__all__"


class TaskSerializer(serializers.ModelSerializer[AutomatedTask]):
    class Meta:
        model = AutomatedTask
        fields = "__all__"


class SoftwareSerializer(serializers.ModelSerializer[InstalledSoftware]):
    class Meta:
        model = InstalledSoftware
        fields = "__all__"
