# get the config object
c = get_config()
# JupyterHub listen address
c.JupyterHub.hub_ip = '0.0.0.0'
# JupyterHub connect hostname.
# In our case it's 'jupyterhub' by the name of the service from docker-compose.yaml
c.JupyterHub.hub_connect_ip = 'jupyterhub'
# Location for users notebooks
c.Spawner.notebook_dir = '~/'
