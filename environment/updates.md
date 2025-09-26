# Instructions: Update the Environment

```bash
# Verify environments
sudo -E /opt/tljh/user/bin/conda env list

# Update environment
sudo -E /opt/tljh/user/bin/conda env update -f ~/extreme-python/environment/environment.yml

# Activate updates
sudo systemctl restart jupyterhub
/opt/tljh/user/bin/conda init
source ~/.bashrc
```
