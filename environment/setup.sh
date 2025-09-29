# !/bin/bash
sudo pip3 uninstall -y jupyterhub jupyterlab jupyter-server jupyterlab_server notebook nbgitpuller jupyter-resource-usage || true
sudo /opt/tljh/user/bin/python -m pip install --upgrade jupyterlab notebook nbgitpuller jupyter-resource-usage
sudo /opt/tljh/user/bin/python -m pip install --upgrade jupyterhub
sudo systemctl restart jupyterhub traefik