c.ServerProxy.servers = {
    "render": {
        "command": ["tail", "-f", "/dev/null"],
        "port": 4200,
        "absolute_url": False,
        "timeout": 60,
    }
}
