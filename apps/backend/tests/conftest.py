import pytest

import ratelimit


@pytest.fixture(autouse=True)
def _reset_limiters():
    ratelimit.report_limiter.clear()
    ratelimit.admin_limiter.clear()
    yield
    ratelimit.report_limiter.clear()
    ratelimit.admin_limiter.clear()
