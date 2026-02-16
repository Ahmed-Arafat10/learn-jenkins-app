FROM mcr.microsoft.com/playwright:v1.41.2-jammy

# Install global CLI tools once (faster than using npx every time)
RUN npm install -g \
    netlify-cli@latest \
    node-jq@latest \
    serve@latest \
    wait-on@latest

# Avoid npm update notifier (small speed gain)
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
