"""IPO domain enums matching Postgres CHECK constraints."""

from enum import Enum


class IpoKind(str, Enum):
    mainline = "mainline"
    sme = "sme"


class IpoStatus(str, Enum):
    upcoming = "upcoming"
    open = "open"
    closed = "closed"
    listed = "listed"
