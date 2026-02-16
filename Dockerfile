FROM mcr.microsoft.com/playwright:v1.39.0-jammy
# Install global CLI tools once (faster than using npx every time)
RUN npm install -g \
    netlify-cli@latest \
    node-jq@latest \
    serve@latest \
    wait-on@latest

RUN apt update && \
    apt install -y jq && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*