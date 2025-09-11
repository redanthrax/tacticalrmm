from rest_framework import routers
from .agent import views as agent
from .client import views as client
from .site import views as site
from .alerts import views as alerts
from .checks import views as checks
from .tasks import views as tasks
from .software import views as software

router = routers.DefaultRouter()

router.register("agent", agent.AgentViewSet, basename="agent")
router.register("client", client.ClientViewSet, basename="client")
router.register("site", site.SiteViewSet, basename="site")
router.register("alerts", alerts.AlertViewSet, basename="alerts")
router.register("checks", checks.CheckViewSet, basename="checks")
router.register("tasks", tasks.TaskViewSet, basename="tasks")
router.register("software", software.SoftwareViewSet, basename="software")

urlpatterns = router.urls
