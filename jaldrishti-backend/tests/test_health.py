import sys
import os
import pytest

# Ensure backend root is in Python path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_healthy_endpoints():
    endpoints = ["/healthy", "/health", "/api/v1/healthy", "/api/v1/health"]
    for path in endpoints:
        response = client.get(path)
        assert response.status_code == 200, f"Failed for path {path}: {response.json()}"
        data = response.json()
        assert data["status"] == "healthy"
