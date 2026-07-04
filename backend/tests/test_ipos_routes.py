"""IPO list route contract — ensures ?type= filters mainline vs SME."""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_current_respects_type_query_param():
    mainline = client.get("/api/v1/ipos/current", params={"type": "mainline"})
    sme = client.get("/api/v1/ipos/current", params={"type": "sme"})
    assert mainline.status_code == 200
    assert sme.status_code == 200

    ml = mainline.json()
    sm = sme.json()
    assert all(row["ipoType"] == "mainline" for row in ml)
    assert all(row["ipoType"] == "sme" for row in sm)


def test_listed_respects_type_query_param():
    mainline = client.get("/api/v1/ipos/listed", params={"type": "mainline"})
    sme = client.get("/api/v1/ipos/listed", params={"type": "sme"})
    assert mainline.status_code == 200
    assert sme.status_code == 200

    ml = mainline.json()
    sm = sme.json()
    assert all(row["ipoType"] == "mainline" for row in ml)
    assert all(row["ipoType"] == "sme" for row in sm)
