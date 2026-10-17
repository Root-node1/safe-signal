from typing import Literal

from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel

IncidentType = Literal[
    "harassment", "threats", "touching", "followed", "dangerous-driving", "unsure"
]
Timing = Literal["now", "after"]
NextStep = Literal["private", "trusted-contact", "check-in", "support"]
Status = Literal[
    "Received", "Reviewing", "Assigned", "Contacted", "Referred", "Action taken", "Closed"
]
Urgency = Literal["high", "medium", "low"]


class CamelModel(BaseModel):
    # JSON uses camelCase to match the frontend types.
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class ReportIn(CamelModel):
    incident: IncidentType
    timing: Timing = "now"
    route: str = Field("", max_length=120)
    area: str = Field("", max_length=120)
    vehicle: str = Field("", max_length=20)
    sacco: str = Field("", max_length=80)
    support: NextStep
    # Whether she gave a phone number. The number itself is never stored here.
    contact_provided: bool = False
    consent_to_share: bool = False


class ReportOut(CamelModel):
    id: str
    code: str
    incident: IncidentType
    urgency: Urgency
    route: str
    area: str
    vehicle: str
    sacco: str
    support: NextStep
    consent_to_share: bool
    status: Status
    created_at: int
    acknowledged_at: int | None = None


class StatusIn(CamelModel):
    status: Status
