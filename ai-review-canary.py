def cap_count(count, limit):
    """Return count capped at limit."""
    return max(count, limit)
