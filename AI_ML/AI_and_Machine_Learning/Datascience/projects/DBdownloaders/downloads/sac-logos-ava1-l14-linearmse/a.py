import kagglehub

# Download latest version
path = kagglehub.model_download("jiazhuang/YOUR_CLIENT_SECRET_HERErmse/transformers/default")

print("Path to model files:", path)
