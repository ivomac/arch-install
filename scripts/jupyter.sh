## Jupyter

python -m jupyter_server.auth password $(pass show localhost:8888/jupyter)
systemctl --user enable jupyter_server.service
