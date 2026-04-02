import pytest
import json
from app import app


@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


class TestHomeRoute:
    def test_home_status_code(self, client):
        """GET / should return HTTP 200."""
        response = client.get("/")
        assert response.status_code == 200

    def test_home_returns_json(self, client):
        """GET / should return valid JSON."""
        response = client.get("/")
        assert response.content_type == "application/json"

    def test_home_message_key(self, client):
        """GET / response should contain 'message' key."""
        response = client.get("/")
        data = json.loads(response.data)
        assert "message" in data

    def test_home_version_key(self, client):
        """GET / response should contain 'version' key."""
        response = client.get("/")
        data = json.loads(response.data)
        assert "version" in data


class TestHealthRoute:
    def test_health_status_code(self, client):
        """GET /health should return HTTP 200."""
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_returns_json(self, client):
        """GET /health should return valid JSON."""
        response = client.get("/health")
        assert response.content_type == "application/json"

    def test_health_status_ok(self, client):
        """GET /health should return {'status': 'ok'}."""
        response = client.get("/health")
        data = json.loads(response.data)
        assert data["status"] == "ok"


class TestInfoRoute:
    def test_info_status_code(self, client):
        """GET /info should return HTTP 200."""
        response = client.get("/info")
        assert response.status_code == 200

    def test_info_returns_json(self, client):
        """GET /info should return valid JSON."""
        response = client.get("/info")
        assert response.content_type == "application/json"

    def test_info_version_key(self, client):
        """GET /info response should contain 'version' key."""
        response = client.get("/info")
        data = json.loads(response.data)
        assert "version" in data

    def test_info_hostname_key(self, client):
        """GET /info response should contain 'hostname' key."""
        response = client.get("/info")
        data = json.loads(response.data)
        assert "hostname" in data

    def test_info_environment_key(self, client):
        """GET /info response should contain 'environment' key."""
        response = client.get("/info")
        data = json.loads(response.data)
        assert "environment" in data
